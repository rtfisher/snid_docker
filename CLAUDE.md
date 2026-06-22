# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

This repo is **packaging infrastructure**, not the SNID science code itself. SNID (SuperNova IDentification; Blondin & Tonry 2007) is a legacy Fortran 77 application built on the PGPLOT graphics library with an X11 interface. This repo wraps it in a Docker container so it runs reproducibly on any host, forwarding SNID's interactive X11 window to an X11 server running on the user's desktop.

The SNID source and template library are **not committed** — they are two gzipped tarballs (`snid-5.0.tar.gz`, `templates-2.0.tgz`) the user downloads from https://people.lam.fr/blondin.stephane/software/snid/ and places in the repo root. They are `COPY`ed into the image at build time. Most files here exist to build, launch, and test that image.

## Common commands

```bash
# Build + launch everything (auto-detects OS, starts Docker + X11, builds image, runs container)
./run_snid.sh
./run_snid.sh /path/to/local/data    # also bind-mounts a host dir into the container

# Build the image by hand
docker build -t snid-app --progress=plain -f snid_dockerfile .

# Run the full test suite (unit + docker build + integration; ~15-20 min)
./tests/run_all_tests.sh
./tests/run_all_tests.sh --quick      # unit tests only, no Docker (seconds)
./tests/run_all_tests.sh --verbose    # stream test output instead of only-on-failure

# Run a single test suite directly
./tests/test_run_snid.sh              # unit: static analysis of run_snid.sh (no Docker needed)
./tests/test_docker_build.sh          # builds image, inspects PGPLOT/SNID/templates inside it
./tests/test_integration.sh           # full container lifecycle, volume mounts, SNID execution
```

Inside the running container, SNID is verified with `./snid examples/sn2003jo.dat`.

## Architecture and key cross-file relationships

**Three-layer build.** Understanding any change requires knowing how these three files coordinate:

1. **`snid_dockerfile`** — Builds Ubuntu 20.04 → installs gfortran + X11 dev libs → downloads & compiles PGPLOT 5.2 from source (enabling the `/XWINDOW` driver via `sed` on `drivers.list`) → creates non-root `sniduser` → extracts the SNID and template tarballs → builds SNID. Critically, it **patches the SNID source in place** before building:
   - rewrites `tempdir` in `source/snidmore.f` to point at the extracted templates path
   - bumps `MAXPPT` and `MAXTEMP` parameters in `source/snid.inc`
   These `sed` edits are coupled to SNID's internal source layout; if SNID is upgraded, verify these patterns still match.

2. **`Makefile`** — This is SNID's *own* build Makefile (copied into the image over the tarball's version via `COPY --chown`). It is configured for `FC=g77` with Linux flags. The Dockerfile symlinks `gfortran` → `g77` so this Makefile works unmodified. Builds three binaries: `snid`, `logwave`, `plotlnw`. PGPLOT/X11 lib paths (`PGLIBS`, `XLIBS`) are baked in for the container's layout.

3. **`run_snid.sh`** — Host-side orchestration. Detects platform (`macOS` / `Linux` / `Windows` via WSL `/proc/version` check), starts Docker and the appropriate X11 server (XQuartz / VcXsrv / Xming / Cygwin-X), runs `xhost + 127.0.0.1` to authorize the container, builds and `docker run`s the image, and traps EXIT/INT to revoke X11 permissions on cleanup. The container always bind-mounts `~/Desktop/snid` ↔ `/home/sniduser/snid-5.0/desktop`; an optional `$1` argument mounts an extra dir at `localmount`.

**X11 is the fragile coupling.** The whole point is forwarding PGPLOT's X11 window from container to host. `DISPLAY`, the `/tmp/.X11-unix` mount, and `xhost` authorization must all line up. Platform-specific X11 setup is the main source of user-facing breakage (see README's X11 Configuration section).

## Testing architecture

- **`tests/test_utils.sh`** is a sourced library — color output, counters (`TESTS_RUN/PASSED/FAILED`), and assertions (`assert_equals`, `assert_success`, `assert_file_exists`, `assert_contains`, `skip_test`, etc.). Every test script sources it and ends with `print_summary`.
- **Unit tests do static analysis**, not execution: `test_run_snid.sh` greps `run_snid.sh` for expected code (OS-detection branches, `xhost` calls, cleanup trap, volume flags). It needs neither Docker nor the tarballs, so it always runs in CI.
- **Docker build / integration tests skip gracefully** when the tarballs are absent (they check `-f snid-5.0.tar.gz && -f templates-2.0.tgz`). This is why CI passes without the proprietary tarballs in the repo.
- Test scripts intentionally **do not use `set -e`** (commit a64ab3f) — they handle errors per-assertion so one failure doesn't abort the suite.

**CI** (`.github/workflows/ci.yml`) runs on push/PR to `master`/`main`/`develop`. Jobs: quick-tests (syntax + unit) → docker-build-tests → integration-tests, plus a multi-platform matrix (ubuntu + macos; Docker checks are best-effort on the macOS runner) and a summary report. Tarball-dependent jobs self-skip when the files aren't present.

When changing `run_snid.sh`, add/adjust the corresponding grep-based check in `tests/test_run_snid.sh`. When changing `snid_dockerfile`, the build/integration tests are what verify the result. `README_testing.md` documents the suite in depth.
