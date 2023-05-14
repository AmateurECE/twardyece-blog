---
layout: post
title: "Getting the Asahi OpenGL Driver to Work on Gentoo Linux"
date: 2023-05-13 17:06:00 -0500
categories: asahi
---

I currently own an Apple M1 MacBook Pro, because I was excited to try Linux on
ARM as my daily driver. When the Asahi Linux project announced that it would be
moving away from Arch Linux ARM as its base distribution, I decided not to
follow the community to Fedora, but instead to switch to Gentoo.

This was my first brush with Gentoo, so there were some issues coming out of
the gate. The issue I decided to tackle today is the use of the new Apple
OpenGL driver.

Asahi Linux provides two kernel configurations for downstream distributions--a
"stable" version, and an "edge" version. As of today, the only difference
between these two versions is a small amount of kernel configuration. This can
be seen in the [`PKGBUILD` for `linux-asahi`][1], which builds the two binary
packages from the same revision of the sources.

Well, here's the issue. I thought I was _already running_ the edge kernel. I
applied the kernel configuration changes just as they were in that repository,
but the Sway Window Manager felt incredibly slow and laggy, and I kept seeing
messages like these in my journal:

```
May 13 18:28:27 hackbook wayland[675]: MESA-LOADER: failed to open apple: /usr/lib64/dri/apple_dri.so: cannot open shared object file: No such file or directory (search paths /usr/lib64/dri, suffix _dri)
May 13 18:28:27 hackbook wayland[675]: MESA-LOADER: failed to open zink: /usr/lib64/dri/zink_dri.so: cannot open shared object file: No such file or directory (search paths /usr/lib64/dri, suffix _dri)
May 13 18:28:27 hackbook wayland[675]: 00:00:00.103 [ERROR] [wlr] [render/egl.c:312] Software rendering detected, please use the WLR_RENDERER_ALLOW_SOFTWARE environment variable to proceed
May 13 18:28:27 hackbook wayland[675]: 00:00:00.104 [ERROR] [wlr] [render/egl.c:554] Failed to initialize EGL context
May 13 18:28:27 hackbook wayland[675]: 00:00:00.104 [ERROR] [wlr] [render/gles2/renderer.c:679] Could not initialize EGL
```

What gives? To start, I decided to take a look at the kernel configuration
changes that specifically [enable the Asahi DRM driver][2]:

```
CONFIG_DRM_SIMPLEDRM_BACKLIGHT=n
CONFIG_BACKLIGHT_GPIO=n
CONFIG_DRM_APPLE=m
CONFIG_APPLE_SMC=m
CONFIG_APPLE_SMC_RTKIT=m
CONFIG_APPLE_RTKIT=m
CONFIG_APPLE_MBOX=m
CONFIG_GPIO_MACSMC=m
CONFIG_LOCALVERSION="-edge-ARCH"
CONFIG_DRM_VGEM=n
CONFIG_DRM_SCHED=y
CONFIG_DRM_GEM_SHMEM_HELPER=y
CONFIG_DRM_ASAHI=m
CONFIG_SUSPEND=y
```

There's not a lot there, so I double-checked that all of that was set in my
running kernel by grep-ing `/proc/config.gz`. This activity showed that
`CONFIG_DRM_ASAHI` wasn't set. Interesting! Taking a look in `menuconfig`, we
see:

```
Symbol: DRM_ASAHI [=n]
    Type  : tristate
    Defined at drivers/gpu/drm/asahi/Kconfig:16
      Prompt: Asahi (DRM support for Apple AGX GPUs)
      Depends on: HAS_IOMEM [=y] && RUST [=n] && DRM [=y] && (ARM64 [=y] && ARCH_APPLE [=y] || COMPILE_TEST [=n] && !GENERIC_ATOMIC64 [=n]) && MMU [=y]
      Location:
        -> Device Drivers
    (1)   -> Graphics support
            -> Asahi (DRM support for Apple AGX GPUs) (DRM_ASAHI [=n])
    Selects: RUST_DRM_SCHED [=n] && IOMMU_SUPPORT [=y] && IOMMU_IO_PGTABLE_LPAE [=y] && RUST_DRM_GEM_SHMEM_HELPER [=n] && RUST_APPLE_RTKIT [=n]
```

`CONFIG_RUST` is unset! Why would that be? I have rust installed, and I have
the Rust USE flag set on the `sys-kernel/asahi-sources`. What gives? Looking a
little further, `CONFIG_RUST` depends on `CONFIG_RUST_IS_AVAILABLE`, a variable
that is unset and has no description in `menuconfig`. As you might imagine,
it's not possible to set this variable in your `.config`. I tried. So, I
decided to go back to the
[instructions to build the kernel with Rust support][3].

```
[edtwardy@hackbook test-kernel]$ make -C /usr/src/linux-6.2.0_p12-asahi O=$PWD LLVM=1 rustavailable
make: Entering directory '/usr/src/linux-6.2.0_p12-asahi'
***
*** Rust bindings generator 'bindgen' could not be found.
***
make[1]: *** [/usr/src/linux-6.2.0_p12-asahi/Makefile:1829: rustavailable] Error 1
make: *** [Makefile:242: __sub-make] Error 2
make: Leaving directory '/usr/src/linux-6.2.0_p12-asahi'
```

This is how it started. This first one is
obvious--`cargo install --version 0.56.0 bindgen`. But then I get this one:

```
[edtwardy@hackbook test-kernel]$ make -C /usr/src/linux-6.2.0_p12-asahi O=$PWD LLVM=1 rustavailable
make: Entering directory '/usr/src/linux-6.2.0_p12-asahi'
***
*** libclang (used by the Rust bindings generator 'bindgen') is too old.
***   Your version:    6.2.0
***   Minimum version: 11.0.0
***
make[1]: *** [/usr/src/linux-6.2.0_p12-asahi/Makefile:1829: rustavailable] Error 1
make: *** [Makefile:242: __sub-make] Error 2
make: Leaving directory '/usr/src/linux-6.2.0_p12-asahi'
```

Something is suspicious about this one. I'm running `clang` version 16.0.0,
according to `equery`. I get the impression that something is wrong here. Clang
version 6.2.0 is not even available in the Gentoo repository, and installing
older versions also doesn't seem to resolve the issue.

So, I opened the failing Makefile, and chased the failure down to these lines
in `scripts/rust_is_available.sh`:

```bash
# Check that the `libclang` used by the Rust bindings generator is suitable.
bindgen_libclang_version=$( \
	LC_ALL=C "$BINDGEN" $(dirname $0)/rust_is_available_bindgen_libclang.h 2>&1 >/dev/null \
		| grep -F 'clang version ' \
		| grep -oE '[0-9]+\.[0-9]+\.[0-9]+' \
		| head -n 1 \
```

Running each command here and iteratively adding the piped expressions reveals
what's going on. This is the input to the `grep -oE '[0-9]+\.[0-9]+\.[0-9]+'`
command:

```
/usr/src/linux-6.2.0_p12-asahi/scripts/rust_is_available_bindgen_libclang.h:2:9: warning: clang version 16.0.3  [-W#pragma-messages], err: false
```

Do you see it? My filepath has a version string in it, and that `grep` command
stops after the first match, so the result of this expression is `6.2.0`. This
is a pretty simple issue to fix, and it became
[my _very first_ kernel patch][4].

With that patch applied to my kernel tree, and after resolving a couple of
additonal issues uncovered by the `rustavailable` target, however, it got
worse:

```
[edtwardy@hackbook test-kernel]$ cat ../PKGBUILDs/linux-asahi/config{,.edge} > .config
[edtwardy@hackbook test-kernel]$ make -C /usr/src/linux-6.2.0_p12-asahi O=$PWD LLVM=1 olddefconfig prepare
 [...omitted...]
  BINDGEN rust/bindings/bindings_generated.rs
thread 'main' panicked at '"ftrace_branch_data_union_(anonymous_at_/home/edtwardy/Git/linux/include/linux/compiler_types_h_121_2)" is not a valid Ident', /home/edtwardy/.cargo/registry/src/github.com-1ecc6299db9ec823/proc-macro2-1.0.56/src/fallback.rs:811:9
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
make[3]: *** [/home/edtwardy/Git/linux/rust/Makefile:298: rust/bindings/bindings_generated.rs] Error 1
```

About an hour of scraping Linux kernel mailing lists, StackOverflow, and GitHub
finally caused me to stumble upon
[this issue in the `rust-bindgen` repository][5], where one of the maintainers
suggests that maybe there was a change in name mangling in clang 16. Another
maintainer comments that the issue cannot be reproduced at `rust-bindgen`
version `0.62`, where the changelog ambiguously states: "Various issues with
upcoming clang/libclang versions have been fixed." So, I install that version,
and my kernel build is off to the races!

```
[edtwardy@hackbook test-kernel]$ make -C /usr/src/linux-6.2.0_p12-asahi O=$PWD LLVM=1 -j10 KCFLAGS="-O3 -march=native -pipe"
[edtwardy@hackbook test-kernel]$ sudo make -C /usr/src/linux-6.2.0_p12-asahi O=$PWD LLVM=1 modules_install
[edtwardy@hackbook test-kernel]$ sudo make -C /usr/src/linux-6.2.0_p12-asahi O=$PWD LLVM=1 install
[edtwardy@hackbook test-kernel]$ sudo dracut --hostonly --kver 6.2.0-asahi-12-edge-ARCH --force
```

Almost there! This doesn't fix the error message from wlroots, though, if you
remember. It's complaining about not being able to find `apple_dri.so`. Pulling
down the Arch Linux package for `mesa` from the Asahi Linux mirror shows the
Apple OpenGL driver should definitely be there. Examining the USE flags for the
`media-libs/mesa::asahi` package shows that there's a flag `VIDEO_CARDS: asahi`
which is currently unset. Enabling this causes the compilation of Mesa to take
a lot longer than I remember.

A clean reboot, and wlroots sings the praises of OpenGL acceleration--the error
message disappears! Just to verify my sanity, let's check `glxinfo`:

```
[edtwardy@hackbook test-kernel]$ glxinfo
 [...omitted...]
Extended renderer info (GLX_MESA_query_renderer):
    Vendor: Mesa (0xffffffff)
    Device: Apple M1 Pro (G13S C0) (0xffffffff)
    Version: 23.1.0
    Accelerated: yes
    Video memory: 15455MB
    Unified memory: yes
    Preferred profile: compat (0x2)
    Max core profile version: 0.0
    Max compat profile version: 2.1
    Max GLES1 profile version: 1.1
    Max GLES[23] profile version: 2.0
OpenGL vendor string: Mesa
OpenGL renderer string: Apple M1 Pro (G13S C0)
OpenGL version string: 2.1 Mesa 23.1.0-devel
 [...omitted...]
```

Success! The machine feels so much snappier, and I can now even the `alpha` to
less than 1.0 in my `foot` config without causing hair-pulling performance
issues. Hopefully my kernel patch will merge soon, so others who are trying to
build kernels with Rust support on Gentoo won't have to follow in my debugging
steps.

[1]: https://github.com/asahilinux/PKGBUILDs/blob/master/linux-asahi/PKGBUILD/
[1]: https://github.com/asahilinux/PKGBUILDs/blob/master/linux-asahi/config.edge/
[3]: https://www.kernel.org/doc/html/latest/rust/quick-start.html
[4]: https://lore.kernel.org/llvm/20230513193238.28208-1-ethan.twardy@gmail.com/
[5]: https://github.com/rust-lang/rust-bindgen/issues/2488
