---
layout: post
title: Running LineageOS for the First Time
date: 2025-02-17 20:00:00
---

Lately, I've been consuming a lot of literature that comes exclusively in
digital form. Academic papers, PhD theses, blogs, journals, and creative
commons digital books. I find it to be really uncomfortable to spend long hours
reading material on my laptop, so I decided to buy my first tablet.

I poked around on eBay to see what I could find cheaply available. The iPads
were enticing, but I decided I would look for one with LineageOS support. If I
only spent a few dollars, I wouldn't mind if I brick the thing. I _have_ been a
professional Android engineer in my very short career, but I've never engaged
with the LineageOS ecosystem, so this felt like a good opportunity.

I selected the Samsung Galaxy Tab S2 9.7 (Wi-Fi), which is about 9 years old at
the time of this writing. I spent $60, shipping included (I probably overpaid),
and when it arrived a week later I dubiously factory reset the thing. It was
pretty speedy, and the battery life is not terrible, considering the device's
age. Additionally, it was very comfortable to read with for extended periods of
time, and the screen is roomy.

The LineageOS team stopped supporting this device after LineageOS 16 (which
seems to have been around 2019?), but the [instructions][1] are still easily
found on Google. I was able to enable the "OEM Unlock" switch in the Developer
Settings without any trouble at all, which can not be said for my Samsung
Galaxy A11. The instructions are fairly simple, from a high-level. Install
Heimdall, download a TWRP recovery image (another product I had no previous
familiarity with), and sideload the Lineage image using ADB. The linked version
of Heimdall didn't provide a release bundle for arm64 Linux (which I'm not
surprised by), but it seemed to run perfectly under `box64`.

I had almost no trouble at all after that, until step 4: _Build a LineageOS
installation package._ I was not prepared to build. Thankfully, again, the
[build instructions][2] are also linked nearby. One thing that can definitely
be said for LineageOS is that their instructions are _very_ clear, almost
without exception.

The build instructions seem stock-standard for Android, with a couple of cute
oddities (the `lunch` command replaced by `brunch`, etc.). The standard build
dependencies are mostly the same, but Lineage 16 was the last version to
require Python 2, which is no longer available in the Debian testing
repositories. It _is_ still available in `nixpkgs`, although `nix-env` refuses
to install until this fragment is added to `~/.config/nixpkgs/config.nix`:

```
{
  permittedInsecurePackages = [
    "python-2.7.18.8"
  ];
}
```

From there, I was able to set up a Python 2 `virtualenv`:

```
nix-env -iA nixpkgs.python2
python2.7 -m ensurepip --user --default-pip
python2.7 -m pip install --user virtualenv
virtualenv --python=python2.7 .lineage_venv
```

Which I can activate in every shell with `. ./.lineage_venv/bin/activate`.

The build instructions then ask the user to run the `extract-files.sh` script
within the build tree, which seems to extract proprietary blobs from the
running device using ADB. The script worked great--however, my device is
apparently missing some of the proprietary blobs that are necessary, because
the build system bailed out _immediately_ when I tried to run it. Luckily, I
was able to find an old [prebuilt image for my device][3] on the unofficial
LineageOS archive, and the LineageOS wiki contains [instructions for extracting
files from prebuilt images][4], so I was able to supplement my losses.

That got me a little further, but the build was now failing on the first
compilation step, because the prebuilt clang that came from the repo manifest
links to two libraries, `libtinfo.so.5` and `libncurses.so.5` which aren't
installed on my machine. Naturally, _these_ aren't available in the Debian
testing repositories either, but the build instructions indicated I might be
able to install them if I downloaded them from an older release's repositories.
These versions were still being updated as of `buster`, so I clicked around
until I found the download link, and the manual install worked!

```
curl -LO http://ftp.us.debian.org/debian/pool/main/n/ncurses/libtinfo5_6.4-4_amd64.deb
curl -LO http://ftp.us.debian.org/debian/pool/main/n/ncurses/libncurses5_6.4-4_amd64.deb
dpkg -i ./libtinfo5_6.4-4_amd64.deb
dpkg -i ./libncurses5_6.4-4_amd64.deb
```

Now a little bit further, and onto a `make` error:

```
Makefile:791: *** multiple target patterns. Stop.
```

This one stumped me. I've never seen this error from GNUMake before, and it's
not an immediately googleable problem. A little bit of poking around, and I did
find one person who reported an error like this when trying to build Ubuntu
touch for their Xperia Z5 Compact. Apparently, setting `USE_HOST_LEX=yes` in
the environment fixed it. To my shock and horror, it worked for me as well. In
the future, I might like to look into that a little further to see what was
actually causing it and why that would fix it.

At this point, I got about 25 build steps into the process, when I got an
obscure error about `cannot exec .../prebuilts/clang: File not found`. I'd seen
this enough to know it was either a dynamic linker error or a shebang error,
and the file turned out to be a Python script with a `#!/usr/bin/python`
shebang at the top. These pesky developers apparently never planned for me to
want to use a Python other than the system Python to build the image.
Unfortunately, the fix for this was to symlink `/usr/bin/python` to the Python2
installation in the virtual environment:

```
sudo ln -s /home/edtwardy/Git/lineageos/.lineage_venv/bin/python /usr/bin/python
```

Luckily, Python never returned to using that path for Python 3 installations
after the Python 2 end-of-life, so this was a (relatively) non-intrusive
change.

Now, after a long 45 minute wait, it looked like the build was going to
succeed. At the _last_ step, however, I got a Python exception trace that ended
with:

```
AssertionError: compression of system.new.dat failed.
```

Nice. That was frustrating. The next day, I took a look at
`build/make/tools/releasetools/common.py`, the path mentioned in the stack
trace. It looks like they were trying to perform a `brotli` compression, which
should have been obvious from my earlier experience extracting files from the
prebuilt brotli-compressed ext2 system image.

I made a small code change to try to get more information:

```diff
diff --git a/tools/releasetools/common.py b/tools/releasetools/common.py
index f7ab11cd8..c9ba9fc45 100644
--- a/tools/releasetools/common.py
+++ b/tools/releasetools/common.py
@@ -1755,10 +1755,10 @@ class BlockDifference(object):
                     '--output={}.new.dat.br'.format(self.path),
                     '{}.new.dat'.format(self.path)]
       print("Compressing {}.new.dat with brotli".format(self.partition))
-      p = Run(brotli_cmd, stdout=subprocess.PIPE)
-      p.communicate()
+      p = Run(brotli_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
+      _, err = p.communicate()
       assert p.returncode == 0,\
-          'compression of {}.new.dat failed'.format(self.partition)
+            'compression of {}.new.dat failed: {}'.format(self.partition, err.strip())
 
       new_data_name = '{}.new.dat.br'.format(self.partition)
       ZipWrite(output_zip,
```

This change prints the output of `stderr` from the child process in the stack
trace, which gave me all I needed to know:

```
Compressing system.new.dat with brotli
  running:  brotli --quality=6 --output=/tmp/tmpz4Bykj/system.new.dat.br /tmp/tmpz4Bykj/system.new.dat
Traceback (most recent call last):
  File "build/make/tools/releasetools/ota_from_target_files", line 2051, in <module>
    main(sys.argv[1:])
  File "build/make/tools/releasetools/ota_from_target_files", line 2025, in main
    output_file=args[1])
  File "build/make/tools/releasetools/ota_from_target_files", line 858, in WriteFullOTAPackage
    system_diff.WriteScript(script, output_zip)
  File "/home/edtwardy/Git/lineageos/android/lineage/build/make/tools/releasetools/common.py", line 1606, in WriteScript
    self._WriteUpdate(script, output_zip)
  File "/home/edtwardy/Git/lineageos/android/lineage/build/make/tools/releasetools/common.py", line 1761, in _WriteUpdate
    'compression of {}.new.dat failed: {}'.format(self.partition, err.strip())
AssertionError: compression of system.new.dat failed: failed to write output [/tmp/tmpz4Bykj/system.new.dat.br]: No space left on device
ninja: build stopped: subcommand failed.
06:29:59 ninja failed with: exit status 1
```

No Android development effort is complete without failing builds caused by a
disk space shortage! It's unclear why the developers would choose to use `/tmp`
for this, when there's a long history of system administrators putting `/tmp`
on a different (and smaller) device. I'm embarrassed to say that I am (was) one
of those admins. Luckily, it was an easy fix to mount a `tmpfs` over top of
`/tmp`:

```
sudo mount -t tmpfs -o size=16g tmpfs /tmp
```

Let me tell you, it was such an adrenaline rush to see the build finally
succeed:

```

#### build completed successfully (05:03 (mm:ss)) ####

```

I know that LineageOS 16 is getting up there in age now, but I've been
impressed with the look and feel of it. I get nostalgia back to my first-ever
Android program as a professional developer, which was also based on Android 9.
Unfortunately, the camera doesn't work. But I can live with that.

[1]: https://wiki.lineageos.org/devices/gts210vewifi/install/#
[2]: https://wiki.lineageos.org/devices/gts210vewifi/build/
[3]: https://lineage-archive.timschumi.net/#
[4]: https://wiki.lineageos.org/extracting_blobs_from_zips
