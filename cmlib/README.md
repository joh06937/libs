# CMLib

This is a library that is intended to provide the bulk of the tools needed to
build a C/C++ project using CMake and Kconfig. It's largely based off of the
Zephyr RTOS (well, circa the early 2020s).

## Root `CMakeLists.txt`

All users of CMLib -- at least, the CMake and Kconfig portions -- should prefer
to use CMLib like a package in their root `CMakeLists.txt` file:

```cmake
cmake_minimum_required(VERSION x.y.z)

set(APP_NAME foo)

find_package(cmlib REQUIRED HINTS "${CMAKE_CURRENT_LIST_DIR}/cmlib")

project(${APP_NAME})
add_executable(${APP_NAME})
```

The important line in the above example is the invocation of `find_package()`.
This is a built-in CMake function that will instruct CMake to look for a package
named "cmlib" inside of the directory `cmlib/`, which itself is in the current
directory of the `CMakeLists.txt` file being run. Note that the "hint" is
necessary in most circumstances, as CMLib is not installable for the system-wide
repository of CMake packages. Also note that the `cmlib/` sub-directory name is
not mandatory; CMLib and all of its sources will use CMake variables to get the
names of necessary directories.

CMake will itself look for a file called `cmlib-config.cmake` in the `cmlib/`
sub-directory (and will automatically also look in a `cmake/` sub-directory in
`cmlib/`; this is where CMLib actually has the CMake file). That file will then
be executed as if it were pulled into the `CMakeLists.txt` file using
`include()`. (Why not just have some file in `cmlib/` that is pulled in using
`include()`? To make things a bit more compatible with projects using both the
Zephyr RTOS and potentially other RTOSes.)

The only CMake-specific minimum requirement that CMLib has is that `APP_NAME` is
defined prior to finding the package. In addition to that, CMLib relies on use
of Kconfig, and thus will have at least one additional required file that the
project must provide, as well as some optional files that can be used. These are
discussed in the (following) Kconfig sections.

## Kconfig

The CMLib Kconfig implementation has three basic components:

1. The input Kconfig declaration files

2. The input Kconfig selection files

3. Elevating the Kconfig selections to CMake and C/C++ source code

### Declaration Files

CMLib's Kconfig process allows users to manually specify a root Kconfig
configuration option declaration file using a `KCONFIG_FILE` variable, which
must be set prior to the package's inclusion:

```cmake
set(KCONFIG_FILE "${CMAKE_CURRENT_LIST_DIR}/Kconfig")

find_package(...)
```

Alternatively, the variable can be specified as part of configuring CMake:

```bash
$ cmake -B build -G Ninja -D KCONFIG_FILE=Kconfig
```

The file's name is not required to be `Kconfig`, but that is typically the
convention.

If `KCONFIG_FILE` is not set, CMLib will default to a file named `Kconfig` in
the root directory (i.e. the calling `CMakeLists.txt` directory).

If the `KCONFIG_FILE` variable is set but the file doesn't exist, CMLib will
issue a "fatal error" message (thus requiring the file exist). If the
`KCONFIG_FILE` variable isn't set and the default file doesn't exist, CMLib will
simply result in no Kconfig options being available (thus allowing the file to
not exist).

### Selection Files

CMLib's Kconfig process allows users to manually specify root Kconfiguration
option selection files using a `PROJECT_FILES` variable, with paths separated by
a comma. The variable must be set prior to the package's inclusion:

```cmake
set(PROJECT_FILES "${CMAKE_CURRENT_LIST_DIR}/prj.conf,"${CMAKE_CURRENT_LIST_DIR}/prj-extra.conf")

find_package(...)
```

Alternatively, the variable can be specified as part of configuring CMake:

```bash
$ cmake -B build -G Ninja -D PROJECT_FILES=prj.conf,prj-extra.conf
```

The file's name is not required to be `prj.conf`, but that is typically the
convention.

If `PROJECT_FILES` is not set, CMLib will default to a file named `prj.conf` in
the root directory (i.e. the calling `CMakeLists.txt` directory).

If any of the `PROJECT_FILES` files -- manually specified or defaulted -- don't
exist, CMLib will issue a "fatal error" message (thus requiring all files
exist).

#### User Selection File

In addition to the list of project files containing Kconfig configuration
selections, CMLib allows a user to have their own `prj-user.conf` file in the
root directory. This file's path and name cannot be overridden. However, its use
can be restricted by setting a variable named `IGNORE_USER_FILE` prior to the
package's inclusion. If the file exists and isn't restricted, it will be
automatically appended to the _end_ of the list of files in `PROJECT_FILES`. The
appending to the end is significant for Kconfig, as that means its options will
take precedence over any previous option selections.

This can be useful for developers that might have a local setup that differs
from the common one or a preconfigured CI/CD one. In either case, it's good
practice to always use `IGNORE_USER_FILE` when building from CI/CD to avoid any
ability for uncontrolled configuration selections to occur on the CI/CD machine.

Note that the build system will not pick up a newly-created `prj-user.conf` file
automatically without rerunning configuration again. That is, you cannot create
the file for the first and only rebuild; you must reconfigure, either manually
or by triggering it, such as `touch prj.conf` and running the build again.

### Elevating to CMake and C/C++ Source Code

TODO
