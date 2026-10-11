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

When CDash is configured (`CDASH_URL` / `CDASH_PROJECT`), per-package results
are also converted to CDash `Coverage.xml` (from the lcov data, by
`ccws_lcov2cdash.py`) and submitted together with test results by
`cdash_submit` / `wscdash_submit`, attaching coverage to the same CDash build;
workspace-wide reports are not submitted to CDash to avoid duplicate entries.

Notes:

- Build type is inherited from the base profile. Optimization degrades line
  attribution in reports (inlining), which is usually acceptable; use a
  debug base profile if precise line coverage is required.
- The base toolchain crops workspace paths with `-ffile-prefix-map`;
  instrumented packages get an identity mapping appended (gcc applies the
  last matching entry), which keeps paths recorded in `.gcno` files
  resolvable for `gcov` -- there is no way to remap them during result
  processing (verified with gcov 13.3 / gcovr 8.6); packages that are not
  instrumented keep path cropping.
- `--coverage` is applied only to ccws aware packages (via `CCWS_CXX_FLAGS`
  and `CCWS_LINKER_FLAGS`); packages that do not include ccws cmake modules
  are not instrumented and are missing from reports.
- Repeated test runs accumulate coverage counters (`.gcda` files are kept);
  rebuild from scratch (`wsclean`) to reset them.
