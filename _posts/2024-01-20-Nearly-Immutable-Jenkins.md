---
layout: post
title: (Nearly) Immutable Jenkins Deployments
date: 2024-01-20
categories: server
---

# In Search of Immutable Deployments

This blog, and the rest of my applications, are served from a single computer
running Debian in my closet. Among my deployments is an instance of Jenkins,
which I use to continuously build and deploy my two static websites--this blog,
and my [quick-reference documentation][1]. The setup was inspired by GitHub
Pages, and I could do this same thing much more easily if I full embraced the
GitHub solutions, but that doesn't align with my romance for self-hosting. Git
is the only thing I'm too afraid to self-host for the moment (the right
combination of drive failures and my life's work is gone forever), so that
significantly narrows the landscape of CI solutions that are available to me.

I originally introduced Jenkins in August of 2021 ([commit][2]), where I was
running my Jenkins controller and a single agent in Podman containers. Very
quickly, the setup became unwieldy--there was no way to track what had been
changed, and it was difficult to remember what to do when I wanted to recreate
my agent or add a job. Additionally, the limitations of the configuration began
to conflict with the design goals of my other deployments:

1. Every application or site should be split into its own Debian package.
2. Installing a package should bring a site up, and removing the package should
   remove all site data and bring the site down gracefully.

This is difficult to do when adding a site means I have to log in to my Jenkins
instance, click around on the GUI and chant some incantations in order to setup
a job for a new application. Thus spawned the need for configuration as code,
and the creation of an *immutable* deployment for Jenkins.

*Immutability* in the context of application deployments means that the
application and all its associated data can be destroyed and programmatically
recreated anew--at will. Obviously, **configuration as code** is a big part of
immutable deployments. After that problem is solved, there is **data
management**--minimizing the data that needs to be persisted between
deployments, and maximizing the data that can be destroyed and recreated
deterministically at will. Finally, there is **configuration discovery**--how
can dependent applications configure the Jenkins instance programmatically,
e.g. by adding jobs?

Jenkins is simultaneously very slow moving and very fast moving. Certain
defects and critical feature requests go ignored for years, but plugins
introduce breaking changes constantly. Additionally, there aren't a lot of
great resources on the management of Jenkins deployments. The world, it seems,
is moving away from Jenkins, towards CI solutions that are highly integrated
with source control solutions--Gitlab CI, Bamboo, GitHub CI, etc. Most of this
process was achieved by reading issues on GitHub and Jira created by people who
had encountered the same problems as I, and crafting the ultimate solution from
the breadcrumbs.

# Configuration as Code

Thankfully, there is a plugin for this--and it works quite well. The Jenkins
configuration as code plugin can even export the configuration of a running
instance into YAML, to provide a starting point. I installed the plugin, and
navigated to __Manage Jenkins > Configuration as Code > View Configuration__.

The exported configuration was quite long, and there were many options that I
didn't understand, but I decided that minimizing the configuration could wait
until after I had a running setup.

To inject this configuration into my container, I decided to do something very
similar to what I had recently implemented for my Nginx configuration--I would
install the configuration file to somewhere in my root filesystem, then have a
[dpkg trigger][3] that would produce a squashfs image at installation time, and
finally a [Quadlet volume configuration][4] file that would mount the squashfs
image into the container. This would provide the mechanism for other packages
(applications) to install configuration fragments later that could be picked up
by the dpkg trigger. Configuring Jenkins to use this configuration file is as
easy as following the [README for the plugin][5].

At first, the Jenkins instance was failing to read the mounted configuration
file from the squashfs image. Thankfully, the container entrypoint remains
running after this failure, so it's easy to `exec` into the container to poke
around. Obviously, it was a permissions issue with the mountpoint. Since the
Jenkins instance runs as a non-root user in the container, I had to change the
volume configuration to mount the volume as owned by the `jenkins` user:

```
[Volume]
# Other options...
Options=allow_other
User=1000
Group=1000
```

The `allow_other` option is surprisingly required. Without it, the image is
mounted as owned by UID 1000, but non-root users cannot access *the mountpoint
itself*. It took me a while to figure this out.

## Bootstrapping Plugins

The official Jenkins instance comes with no plugins installed, so we have to
create a derived container image that comes with all the plugins we need. The
Jenkins configuration as code documentation points us to [a page in the
official Jenkins docs][6] that describes how to do this using the Jenkins
plugin CLI:

```
FROM jenkins/jenkins:lts-jdk17
COPY --chown=jenkins:jenkins plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt
```

That same page gives us a mechanism to getting the list of currently installed
plugins with a cURL command:

```
JENKINS_HOST=username:password@myhost.com:port
curl -sSL "http://$JENKINS_HOST/pluginManager/api/xml?depth=1&xpath=/*/*/shortName|/*/*/version&wrapper=plugins" | perl -pe 's/.*?<shortName>([\w-]+).*?<version>([^<]+)()(<\/\w+>)+/\1 \2\n/g'|sed 's/ /:/'
```

# Data management

Since we're going for immutability, I want to persist as little as possible. In
the old configuration, there was a Jenkins "config" volume that persisted
everything under `/var/jenkins_home`. This ended up being pretty much
everything--secrets, plugin binaries, and of course, the configuration itself.

The ideal scenario is that no volumes are required--the container creates all
the data needed for the running instance of Jenkins, and all of that data is
destroyed when the instance stops. When I tried removing this volume, however,
the Jenkins agent failed to connect. After some poking around, it became clear
that this is because the Jenkins JNLP secrets used to connect agents to
controllers are not deterministically generated. If I were running my agents in
a k8s cluster, I could configure the controller to dynamically spin up agents
for job processing as necessary. However, single-node k8s is still not an
option in 2024 without virtual machines, and I just don't care to introduce a
new heavy-handed virtualization mechanism on my poor Ryzen 3 CPU.

Planning for a future where k8s is an option, the current best option is to
create agents through the GUI, and then persist their secrets into a volume.
After some googling, I stumbled upon [this GitHub issue][7], which recommends
provisioning the contents of `/var/jenkins_home/secrets` before starting the
container. This is a flat directory, containing only a few small files, so I'll
choose to persist this with a btrfs volume:

```
[Volume]
PodmanArgs=--driver=local
Type=btrfs
Options=subvol=@jenkins_controller-secrets
Device=/dev/disk/by-uuid/05599193-00bc-4a81-9550-54623b2ec8c4
```

This also demonstrates the new strategy I've taken for all of my container
volumes recently, which is to persist the actual data in a btrfs subvolume,
which I then create a Quadlet volume unit for. This creates a named volume that
mounts the subvolume into the container at runtime, so I can safely run `podman
volume prune` without worrying about a loss of data!

# Configuration Discovery

The penultimate issue that needs solving is the discovery of configuration. How
do dependent applications programmatically create jobs in the controller? We
can use the Jenkins `job-dsl` plugin for this. The mechanism we'll implement
allows packages to install individual Groovy files to a known location, which
will be picked up by our dpkg trigger and used to regenerate the configuration
for the Jenkins controller. The configuration fragment we need to generate from
the Groovy files will look something like [this demo][8] from the
configuration-as-code project.

This requires some changes to our dpkg hook to generate a single configuration
fragment file, called `jobs.yaml`, containing the `job-dsl` scripts from the
individual Groovy files:

```patch
diff --git a/debian/twardyece-jenkins.postinst b/debian/twardyece-jenkins.postinst
index ce18fbb..0cb3675 100644
--- a/debian/twardyece-jenkins.postinst
+++ b/debian/twardyece-jenkins.postinst
@@ -10,8 +10,23 @@ update_config() {
     rm -rf $LOCAL_STATE_DIR/casc
     mkdir -p $LOCAL_STATE_DIR/casc
 
+    # Copy all YAML files directly to the config directory
+    cp $DATA_DIR/*.yaml $LOCAL_STATE_DIR/casc
+
+    # Emit all groovy files into a YAML fragment as job-dsl scripts
+    local IFS_SAVE=$IFS
+    IFS=$'\n'
+    printf '%s\n' "jobs:" > $LOCAL_STATE_DIR/casc/jobs.yaml
+    for f in $DATA_DIR/*.groovy; do
+           printf '  - script: >\n' >> $LOCAL_STATE_DIR/casc/jobs.yaml
+           for line in $(cat $f); do
+                   printf '      %s\n' "$line" >> $LOCAL_STATE_DIR/casc/jobs.yaml
+           done
+    done
+    IFS=$IFS_SAVE
+
     # Create a volume image from the configuration files
-    mksquashfs $DATA_DIR $LOCAL_STATE_DIR/$IMAGE -noappend
+    mksquashfs $LOCAL_STATE_DIR/casc $LOCAL_STATE_DIR/$IMAGE -noappend
 }
 
 case "$1" in
```

Now, we can create the job that builds this blog as its own Groovy file and
install it to `/usr/share/twardyece-jenkins` to be automatically picked up at
package installation time:

```
multibranchPipelineJob('Blog') {
  branchSources {
    git {
      id('blog-trunk')
      remote('https://github.com/AmateurECE/twardyece-blog.git')
      includes('trunk')
    }
  }
}
```

# Agent Dependency Management

In the old way, I had all the dependencies necessary to build my Jenkins jobs
installed in the image that the agent was running. However, this creates
another point of tight coupling between my jobs and my agents. At the company
where I work, our agents launch Docker containers that contain our build
environments when a new job is triggered. I tried multiple scenarios to achieve
a similar kind of thing:

1. The Jenkins Kubernetes plugin can dynamically launch agents, but for reasons
   already stated, this wasn't an option for me.
2. The docker-workflow plugin allows the Jenkinsfile to specify a container
   image in which the build should be run. However, this doesn't work when
   using docker-in-docker with Podman.
3. The docker-plugin allows the Jenkins controller to spin up agents from
   container images dynamically as jobs are run, but it seems to struggle when
   using docker-in-docker when the controller is running in a container.
   Additionally, it uses docker-java, which requires the Docker socket to be
   mounted, and the controller container to be run with `--privileged`, and
   since this controller is open to the wide internet, that's not something I
   was willing to consider.

In the end, I decided that all Jenkins jobs would need to use Nix flakes to
manage their dependencies. I created an agent image that had Nix installed for
the `jenkins` user, and a wrapper that allows executing a bash script within a
devShell derived from a Nix flake. [The wrapper][9] needed to include some
annoying workarounds, because apparently Jenkins does not set the `USER`
environment variable for a job (well, it sets the `user` environment variable,
which is obviously not the same). From a Jenkinsfile, I can conveniently use
this wrapper in the shebang:

```
pipeline {
  # ...
  stages {
    stage('Build') {
      steps {
        # ...
        sh '''#!/usr/bin/flake-run
        bundle install
        bundle exec jekyll build
        '''
      }
    }
  }
}
```

# Conclusion

That's about as close as we can get to a fully immutable Jenkins deployment
without moving to Kubernetes. Now, there's only two volumes that store actual
data: One to store the secrets for the controller, and one to store the secrets
for the inbound agent. In reality, this took me about a week to accomplish in
my free time--spending a few moments here and there. Hopefully this will be
helpful for someone else who decides to traverse a similar path!

[1]: https://twardyece.com/repository/
[2]: https://github.com/AmateurECE/twardyece-services/commit/1ee4d6cc657e7258adb06bbdad50d016a8be1c80
[3]: https://github.com/AmateurECE/twardyece-services/blob/77d95e9670864aefba1c89de13d5474874aa3bbb/debian/twardyece-jenkins.postinst
[4]: https://github.com/AmateurECE/twardyece-services/blob/77d95e9670864aefba1c89de13d5474874aa3bbb/jenkins/jenkins-controller-config.volume
[5]: https://github.com/jenkinsci/configuration-as-code-plugin
[6]: https://github.com/jenkinsci/docker/#preinstalling-plugins
[7]: https://github.com/jenkinsci/configuration-as-code-plugin/issues/2250
[8]: https://github.com/jenkinsci/configuration-as-code-plugin/blob/master/demos/jobs/multibranch-github.yaml
[9]: https://github.com/AmateurECE/twardyece-services/blob/77d95e9670864aefba1c89de13d5474874aa3bbb/jenkins/flake-run.sh
