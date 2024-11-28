---
layout: post
title: Fixing Git Clone Errors
date: 2024-11-28
categories: server
---

Just before the holiday, I was working on a Yocto-based distribution for a
Raspberry Pi. I've been using the gadget to stream music to my stereo over
Bluetooth. I'd just finished pulling a bunch of junk out of the image when, to
my disappointment, the `do_fetch` task for `linux-raspberrypi` failed. So, I
tried again, and it failed again. I had been able to fetch successfully not
twenty minutes earlier. Inspecting the log, it looks like `git index-pack`
generated an invalid index file for one of the received pack archives:

```
...
Receiving objects: 100% (74709/74709), 26.56 MiB | 7.52 MiB/s, done.
fatal: local object e0a447351623bfa2df5a7e7429e1479826bc9a7a is corrupt
fatal: fetch-pack: invalid index-pack output
```

I'm not fluent in git internals, so at the time, this meant nothing to me. My
immediate suspicion was a network error. I've seen repeatable problems with
git clone magically disappear after Europe goes to sleep in the past, so I
assumed this was another such fluke. It was already late by this time, so I
went to bed.

As you might imagine, it _did not_ resolve itself in the morning. I tried
setting `BB_SHALLOW_CLONE` and `BB_SHALLOW_CLONE_DEPTH` in my kas file to see
if I could work around the issue by trying to minimize data transfer. No such
luck. Strangely, I had not seen this with any other repository in my distro.

I tried the clone manually--the same branch, from the same GitHub repository.
Here, I was able to get through a shallow clone, but trying to deepen the clone
with `git fetch --unshallow` produced the same errors as were in the BitBake
log.

So, I scripted an interaction to incrementally deepen the clone, to see how far
I could get:

```
$ while true; do git fetch --deepen=1; done
```

This worked for a little while, until I got to a region of the history that
retrying wouldn't seem to get through. It wasn't a terribly large transaction,
only about 50 MiB. It gets more interesting, though--the error message isn't
consistent. There are a few patterns that I could pull out, in addition to the
one shown above:

```
Receiving objects: 100% (130810/130810), 48.85 MiB | 7.40 MiB/s, done.
fatal: SHA1 COLLISION FOUND WITH c8fdd0d03907f9d11d2080ec77d94add9f144916 !
fatal: fetch-pack: invalid index-pack output
```

```
Receiving objects: 100% (130810/130810), 48.85 MiB | 8.33 MiB/s, done.
error: inflate: data stream error (incorrect data check)
```

In a situation like this, it often helps me to view the system from a high
level and work on ranking failure modes for each component. In this scenario,
I'm cloning the repository on my AMD machine running Debian testing. This
operation goes out to the network, and copies a bunch of data from a server to
disk. So, these are the major components:

1. The Git remote (GitHub)
2. The network
3. My installation of Git
4. My server's RAM
5. My SSD

Let's move down the list. GitHub wasn't reporting an outage, and since I hadn't
had any other network troubles, it seemed unlikely to be something outside of
my box. A bad DIMM might fit the bill, but I would expect to see other kinds of
system instability--processes crashing and unrecoverable kernel panics at
runtime, etc. I ran memtest86+ and didn't see any errors.

Next is the installation of git. The reported version is 2.45.2, and that
matches the version of the installed package from `dpkg -l`. When I looked to
see if there was an upgrade available, `apt` took the liberty of reminding me
about an issue I've been ignoring for a month:

```
  WARNING: Device /dev/sdb5 has size of 911755265 sectors which is smaller than corresponding PV size of 911757312 sectors. Was device resized?
  WARNING: One or more devices used as PVs in VG edtwardy-vg have changed sizes.
```

The partition `/dev/sdb5` is the only physical volume in the LVM2 volume group
that contains my home directory and root filesystem. This error is telling us
that the LVM2 physical volume is configured for a size exactly 1023.5 KiB
larger than the partition that actually contains it. I'm not exactly sure how
that happened. Recently, I was setting up a btrfs filesystem on a neighboring
partition. It's likely that I made an arithmetic error when I was resizing
everything.

I procrastinate fixing things like this because my partitioning solution is
extremely complicated in its current state, _and_ I never have a Debian Live CD
around when I need it. After booting into a live image, I fixed the issue by
freeing up 1 logical extent (about 4 MiB) from the volume containing my `/var`
partition and reallocating a couple of extents to make free space at the end of
the physical volume. This allowed me to reduce the size of the PV to the size
of the partition.

Apt no longer reports the above error, and a test shows that I can clone the
linux kernel. Even better, it still works _the second time_. It bothers me that
I'm not sure why this may have been the cause of the problem. I know that git
makes some temporary files in `/var/tmp`, perhaps the invalid logical extent
lived somewhere in that partition. I don't exactly know what writing to that
region would do, but I'm not surprised that it wouldn't work. I suppose I'm
more surprised that I didn't see something about this in `dmesg` first.
