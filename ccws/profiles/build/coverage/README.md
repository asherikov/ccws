Coverage mixin
==============

Adds `gcov` based code coverage instrumentation, has to be mixed with another
build profile:

    make <pkg> BUILD_PROFILE=coverage,reldebug
    make wstest BUILD_PROFILE=coverage,reldebug

Test targets print a textual coverage summary and write machine readable
results to artifacts:

- `<pkg>.info` -- lcov format, e.g. codecov, coveralls
- `<pkg>.cobertura.xml` -- cobertura format, e.g. gitlab

Workspace-wide results are generated automatically by `test_results` target
(no `PKG` specified) and can also be requested manually with
`bp_coverage_process_ws` target after tests.
Reports can be adjusted with `CCWS_COVERAGE_EXCLUDE` variable, which contains
a space separated list of excluded path patterns (3rdparty code by default); it
is defined in the profile setup script and can be overridden in the
environment.

Notes:

- Build type is inherited from the base profile. Optimization degrades line
  attribution in reports (inlining), which is usually acceptable; use a
  debug base profile if precise line coverage is required.
- `-ffile-prefix-map` included by default prevents path resolution during
  coverage results processing, this flag overriden in the toolchain.
- `--coverage` is applied only to ccws aware packages (via `CCWS_CXX_FLAGS`
  and `CCWS_LINKER_FLAGS`); packages that do not include ccws cmake modules
  are not instrumented and are missing from reports.
- Repeated test runs accumulate coverage counters (`.gcda` files are kept);
  rebuild from scratch (`wsclean`) to reset them.
