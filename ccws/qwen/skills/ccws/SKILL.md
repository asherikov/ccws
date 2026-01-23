---
name: ccws
description: CCWS (colcon workspace) development environment for colcon-compatible packages. Use when working with ROS packages, pure CMake packages, or other colcon-compatible projects. Provides cross-compilation, testing, linting, documentation generation, and binary package creation.
---

# CCWS

## Overview

CCWS (colcon workspace) is a development environment that integrates colcon workspaces to facilitate cross-compilation, testing, linting, documentation, and binary package generation. It serves as both a CI/CD backbone and a working environment for developers, compatible with ROS packages, pure CMake packages, and other colcon-compatible projects. CCWS is ROS-version agnostic and can be used for both ROS-specific and ROS-agnostic packages.

## When to Use This Skill

This skill should be used when:
- Setting up a new colcon-based workspace with integrated build and test capabilities
- Working with ROS packages, pure CMake packages, or other colcon-compatible projects
- Performing cross-compilation for different platforms (Raspberry Pi, ARM64, etc.)
- Running static analysis and linting on colcon-compatible packages using profiles like clang_tidy, scan_build, and static_checks
- Generating documentation for packages using Doxygen
- Creating Debian binary packages from colcon workspaces
- Managing multiple build profiles for different compilation scenarios
- Running tests for colcon-based projects
- Working with execution profiles for runtime environment modification
- Installing and managing dependencies for packages in the workspace

## Core Concepts

### Build Profiles
Sets of configurations for the build process, including cmake toolchain, colcon configuration, and environment variables. Profiles do not conflict with each other and can be used in parallel.

Common build profiles:
- `reldebug` - Default compiler, cmake build type RelWithDebInfo, selected by default
- `release` - Release build with tests disabled
- `scan_build` - Compile with clang using scan_build and clang-tidy for static checks
- `clang_tidy` - Simplified scan_build without clang and scan_build
- `thread_sanitizer` - Compilation with thread sanitizer
- `addr_undef_sanitizers` - Compilation with address and undefined behavior sanitizers
- `static_checks` - Static checkers and their configuration
- `doxygen` - Documentation generation with doxygen
- `cross_raspberry_pi` - Cross-compilation for Raspberry Pi
- `cross_arm64` - Cross-compilation for ARM64
- `clangd` - Generates clangd configuration file
- `deb` - Debian package generation

### Execution Profiles
Simple shell mixins that modify the runtime environment, such as executing nodes in valgrind or altering node crash handling.

Common execution profiles:
- `common` - Common parameters for colcon-compatible packages (automatically included)
- `test` - Sets nodes to required mode for testing
- `valgrind` - Sets CCWS_NODE_LAUNCH_PREFIX to valgrind
- `core_pattern` - Sets core pattern to save core files in artifacts
- `address_sanitizer` - Helper for addr_undef_sanitizers profile

## Common Workflows

### 1. Installing Workspace Dependencies

**Installing system dependencies for packages in the workspace:**
```bash
# Install workspace system dependencies (for all packages in the workspace)
make dep_install

# Install dependencies for a specific package (alternative command)
make dep_install PKG=package_name

# For ROS packages, install dependencies using rosdep
make rosdep PKG=package_name
```

**Advanced dependency management:**
```bash
# Generate and install dependencies for a specific package with all dependency types (build, run, test)
make dep_install PKG=package_name CCWS_DEP_TYPE=all

# Install only build dependencies for a package
make dep_install PKG=package_name CCWS_DEP_TYPE=build

# Install only run dependencies for a package
make dep_install PKG=package_name CCWS_DEP_TYPE=run

# Install only test dependencies for a package
make dep_install PKG=package_name CCWS_DEP_TYPE=test
```

**For cross-compilation scenarios:**
```bash
# Install system dependencies to the system image for cross-compilation
# For ROS packages, specify the ROS distribution (e.g., melodic, noetic, humble, etc.)
make cross_install PKG=my_package BUILD_PROFILE=cross_raspberry_pi [ROS_DISTRO=melodic]

# Alternative method for installing dependencies for cross-compilation
make cross_deps PKG=my_package BUILD_PROFILE=cross_raspberry_pi [ROS_DISTRO=melodic]
```

**Managing dependencies from external sources:**
```bash
# Add package dependencies to the workspace repolist (for ROS packages)
make dep_to_repolist PKG=package_name [ROS_DISTRO=distro_name]

# Add all dependencies of all packages in the workspace to the repolist (for ROS packages)
make dep_to_repolist [ROS_DISTRO=distro_name]
```

**Dependency resolution and management:**
```bash
# Update rosdep database
sudo rosdep update

# Manually trigger dependency resolution for a package
make private_dep_resolve PKG=package_name

# List dependencies for a package without installing them
make private_dep_list PKG=package_name
```

### 2. Package Compilation

**Building specific packages:**
```bash
# Build one or more colcon-compatible packages with default profile (reldebug)
make build PKG="package1 package2"

# Shortcut for building packages (substring matching)
make pkg_name

# Build with a specific profile
make build PKG="package1" BUILD_PROFILE=release

# Limit the number of build jobs
make build PKG="package1" JOBS=2
```

### 3. Testing

**Running tests:**
```bash
# Test specific colcon-compatible package with colcon
make test PKG=package1

# Test all packages
make wstest

# Run ctest directly
make ctest PKG=package1

# Run all tests with ctest
make wsctest
```

### 4. Cross-Compilation

**Cross-compiling for different platforms:**
```bash
# Install dependencies for cross-compilation
make bp_install_build BUILD_PROFILE=cross_raspberry_pi

# Install system dependencies to the system image
# For ROS packages, specify the ROS distribution (e.g., melodic, noetic, humble, etc.)
make cross_install PKG=my_package BUILD_PROFILE=cross_raspberry_pi [ROS_DISTRO=melodic]

# Mount sysroot
make cross_mount BUILD_PROFILE=cross_raspberry_pi

# Build packages for target platform
make my_package BUILD_PROFILE=cross_raspberry_pi

# Or build and generate deb package
make PKG=my_package BUILD_PROFILE=deb,cross_raspberry_pi

# Unmount sysroot when done
make cross_umount BUILD_PROFILE=cross_raspberry_pi
```

### 5. Documentation Generation

**Generating documentation:**
```bash
# Build with doxygen profile
make BUILD_PROFILE=doxygen

# Open generated documentation
firefox artifacts/doxygen/index.html
```

### 6. Debian Package Generation

**Creating binary packages:**
```bash
# Build colcon-compatible package with deb profile overlayed on reldebug
make my_package BUILD_PROFILE=deb,reldebug

# The resulting package will be in the artifacts directory
ls artifacts/packages/
```

### 7. Using Execution Profiles

**Running with execution profiles:**
```bash
# Source the setup script with build and execution profiles
source setup.bash reldebug valgrind

# Or use in test commands for colcon-compatible packages
make test PKG=my_package EXEC_PROFILE="valgrind core_pattern"
```

### 8. Static Analysis and Code Quality Checks

**Using static analysis build profiles:**
```bash
# Run clang-tidy static analysis on a specific package
make build PKG=my_package BUILD_PROFILE=clang_tidy

# Run scan_build with both clang static analyzer and clang-tidy
make build PKG=my_package BUILD_PROFILE=scan_build

# Run comprehensive static checks including cppcheck, catkin_lint, yamllint, shellcheck
make build PKG=my_package BUILD_PROFILE=static_checks
```

## Configuration

### Custom Configuration
Override developer and vendor specific parameters by adding them to `make/config.mk`:

```makefile
# Example custom configuration in make/config.mk
BUILD_PROFILE ?= reldebug
JOBS ?= $(shell nproc)
```

## Best Practices

### 1. Profile Management
- Use different build profiles for different purposes (debug, release, static analysis)
- Combine profiles when needed (e.g., `deb,reldebug` for package generation, `clangd,scan_build` for IDE support with static analysis)
- Keep profiles isolated to avoid conflicts

### 2. Dependency Management
- Install build profile dependencies using `make bp_install_build BUILD_PROFILE=<profile>`
- Install system dependencies for all packages using `make dep_install`.
- Install package-specific dependencies using `make dep_install PKG=<package_name>`
- For cross-compilation, ensure system dependencies are installed in the sysroot
- Use `make dep_to_repolist` to add dependencies to the workspace for colcon-compatible packages (for ROS packages: `make dep_to_repolist PKG=<pkg> ROS_DISTRO=<distro>`)
- Use dependency type filters (build, run, test) to install specific types of dependencies: `make dep_install PKG=<pkg> CCWS_DEP_TYPE=<type>`

### 3. Package Organization
- Organize colcon-compatible packages in the `src` subdirectory
- Use `make new PKG=<pkg_name>` to create new colcon-compatible packages from template
- Maintain clean separation between source, build, and install directories

### 4. Testing Strategy
- Use the `test` execution profile for automated testing of colcon-compatible packages
- Combine multiple execution profiles when needed
- Run tests regularly during development

### 5. Documentation
- Generate documentation regularly using the doxygen profile
- Keep colcon-compatible package documentation up to date
- Use the generated documentation for reference

## Troubleshooting

- If a build fails, consider two potential root causes: incorrect use of the framework or issues in the source space packages. ccws framework correctly handles execution of colcon and sourcing of necessary shell setup scripts.

## Additional Resources

- CCWS README: Located at `/ccws/README.md`
- Package template: Demonstrates usage of CCWS features for colcon-compatible packages
- Cross-compilation guide: `ccws/doc/cross-compilation.md`
