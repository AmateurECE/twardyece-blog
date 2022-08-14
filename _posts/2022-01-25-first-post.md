---
layout: post
title:  "First Post"
date:   2022-01-25 07:30:00 -0500
categories: server
---

## The Server

Over the weekend, I ripped up the entirety of the build system for [the
packages that serve this blog][webservices-git] and replaced it with a much
more modular system built on GNU Makefiles, of all things. It was a good
reminder of the power of `make`.

This was also a chance for me to begin testing my latest project in production,
[Volumetric][volumetric-git]. Volumetric is a tool I wrote to begin using
policy-driven control of persistent volumes in OCI runtimes (currently, I use
Docker). There are already so many solutions for container volumes, but there
wasn't yet one that targeted setups like mine.

While an enterprise with federated, distributed storage can make good use
of a COW filesystem such as btrfs or OpenZFS to maintain mirrors upon snapshots
ad infinitum, or even storage systems like S3, I don't quite have that luxury.
I have a short list of Docker volumes that power my webservices and provide
persistent storage for non-code data used in my applications, and only one
machine to manage them. Snapshot and incremental backup support (either via
OpenZFS or LVM) is on the feature plan for Volumetric, but until I have some
more hardware to play with, there's not a lot of value in them.

Additionally, creating Volumetric affords me a unified, policy-driven interface
for all of my volume backends, including even PostreSQL backup and restore
commands, and it removes the need to localize management of my volumes with my
container configurations.

## libhandlebars

libhandlebars appears to be going well since I replaced `peg(1)` with a
handwritten parser. It needs a few more features before it's ready for the 1.0
release.

[webservices-git]: https://github.com/AmateurECE/edtwardy-webservices/
[volumetric-git]: https://github.com/AmateurECE/Volumetric/
