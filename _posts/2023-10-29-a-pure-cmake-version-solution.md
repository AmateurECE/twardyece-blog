---
layout: post
title: "A Version Capture Solution in Pure CMake"
date: 2023-10-29 15:00:00 -0500
categories: cpp
---

# Introduction

A teammate and I were recently discussing version solutions, because one of our
git templates uses the [smessmer/gitversion][1] tool. This tool has,
unfortunately, not received a commit since 2018, and we're now talking about
alternative solutions. I was pretty confident that a pure CMake solution
exists--one that would be only a few lines of CMake script, and would be easy
to understand and maintain--but I couldn't visualize the entire solution, which
made it difficult to communicate about to my teammates. This post is to explore
the nature of that solution, so that I can use it in the future.

# Requirements

We don't need much from a version tool. It needs to report a program version
string in the same format as reported by `git-describe(1)`, using annotated git
tags, run every time the build executes, and provide this version string as a
compile-time constant in a CMake library that can be added as a dependency to
any CMake dependency.

# The Solution

I'll start with a basic CMake project, that just compiles a basic
"Hello, world!" executable called `app`.

```
.
├── CMakeLists.txt
└── app
    ├── CMakeLists.txt
    └── main.cpp
```

And the contents of these files, to start:

```diff
diff --git a/CMakeLists.txt b/CMakeLists.txt
index e69de29..4a00125 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -0,0 +1,4 @@
+cmake_minimum_required(VERSION 3.26)
+project(CMakeVersion LANGUAGES CXX)
+
+add_subdirectory(app)
diff --git a/app/CMakeLists.txt b/app/CMakeLists.txt
index e69de29..e9dcf8a 100644
--- a/app/CMakeLists.txt
+++ b/app/CMakeLists.txt
@@ -0,0 +1,3 @@
+project(app LANGUAGES CXX)
+
+add_executable(app main.cpp)
diff --git a/app/main.cpp b/app/main.cpp
index e69de29..3f263c9 100644
--- a/app/main.cpp
+++ b/app/main.cpp
@@ -0,0 +1,5 @@
+#include <iostream>
+
+int main() {
+  std::cout << "Hello, world!\n";
+}
```

We know that we can send the output of a shell command to a CMake variable with
`execute_process`, but `execute_process` typically runs at configuration time.
Naturally, we want the version string to update at build time, and on _every_
build, so we need to find a mechanism to change when `execute_process` is run.
This feels like an appropriate use of CMake's _script mode_.

I'll additionally put all of the versioning logic in `version.cmake`, so it's
easier to relocate later.

```diff
diff --git a/version.cmake b/version.cmake
new file mode 100644
index 0000000..fd50d7b
--- /dev/null
+++ b/version.cmake
@@ -0,0 +1,22 @@
+if(CMAKE_SCRIPT_MODE_FILE)
+  # We are executing as a script
+  execute_process(COMMAND git describe --dirty
+    OUTPUT_VARIABLE GIT_REPO_VERSION
+    OUTPUT_STRIP_TRAILING_WHITESPACE)
+  configure_file(${INPUT_FILE} ${OUTPUT_FILE})
+else()
+  set(VERSION_HEADER "${CMAKE_CURRENT_BINARY_DIR}/version.h")
+  # We have been included at configure time
+  add_custom_target(version_header
+    COMMAND ${CMAKE_COMMAND}
+    -D INPUT_FILE="${CMAKE_CURRENT_SOURCE_DIR}/version.h.in"
+    -D OUTPUT_FILE=${VERSION_HEADER}
+    -P ${CMAKE_CURRENT_SOURCE_DIR}/version.cmake
+    BYPRODUCTS ${VERSION_HEADER})
+
+  add_library(gitversion INTERFACE)
+  target_include_directories(gitversion
+    INTERFACE ${CMAKE_CURRENT_BINARY_DIR})
+  add_dependencies(gitversion version_header)
+  add_library(gitversion::gitversion ALIAS gitversion)
+endif()
```

This has kind of a UNIX-fork "feel" to it. If we aren't executing in script
mode, it's configure time, so we set up an interface library target that
downstream targets can link to. The library is composed of the output of one
custom target, which executes this same file in script mode.

When we run in script mode, we execute `git describe --dirty` using the user's
default shell, and store the output in the variable `GIT_REPO_VERSION`. When
`configure_file` renders the template `version.h.in`, that file can reference
this variable to get the version string:

```diff
diff --git a/version.h.in b/version.h.in
new file mode 100644
index 0000000..814f981
--- /dev/null
+++ b/version.h.in
@@ -0,0 +1 @@
+#define GIT_REPO_VERSION "${GIT_REPO_VERSION}"
```

Obviously, we could change this template _not_ to use preprocessor macros, for
example if we wanted to generate a real library archive file instead. I'll
update `app/main.cpp` to print this version string, as well as
`app/CMakeLists.txt` to link the `app` executable to our interface library, and
the top level `CMakeLists.txt` to include our version script:

```diff
diff --git a/CMakeLists.txt b/CMakeLists.txt
index 4a00125..52f869f 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -1,4 +1,6 @@
 cmake_minimum_required(VERSION 3.26)
 project(CMakeVersion LANGUAGES CXX)
 
+include(version.cmake)
+
 add_subdirectory(app)
diff --git a/app/CMakeLists.txt b/app/CMakeLists.txt
index e9dcf8a..c9fc5d7 100644
--- a/app/CMakeLists.txt
+++ b/app/CMakeLists.txt
@@ -1,3 +1,4 @@
 project(app LANGUAGES CXX)
 
 add_executable(app main.cpp)
+target_link_libraries(app gitversion::gitversion)
diff --git a/app/main.cpp b/app/main.cpp
index 3f263c9..125e942 100644
--- a/app/main.cpp
+++ b/app/main.cpp
@@ -1,5 +1,6 @@
 #include <iostream>
+#include <version.h>
 
 int main() {
-  std::cout << "Hello, world!\n";
+  std::cout << GIT_REPO_VERSION << "\n";
 }
```

Testing it out, we see that everything works! If we rebuild, commit, then
rebuild again, we see that the commit action triggers a rebuild of `app`. If we
read the [CMake docs for `configure_file`][2], we see:

> The generated file is modified and its timestamp updated on subsequent cmake
> runs only if its content is changed.

Which is _very_ cool. So even if none of our source files have changed, if the
output of `git-describe` changes, the targets will be recompiled.

That's a version solution in 22 lines of CMake!

[1]: https://github.com/smessmer/gitversion
[2]: https://cmake.org/cmake/help/latest/command/configure_file.html
