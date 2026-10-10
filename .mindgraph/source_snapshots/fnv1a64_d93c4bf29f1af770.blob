# F-pilot: reproducible Bitloop diagnostic pilot

Task: `T-pilot`. Capabilities used: `bitloop`, `traces`, `snapshots-checkpoints`.
This is a C-app lifecycle/wiring fixture, not a simulation or solver prototype.

## Fixture and oracle

`Substrate/Substrate.h` and `.cpp` keep development-only counters under
`BITLOOP_DEV_MODE`. `sceneStart()` resets them; `sceneProcess()` increments the
tick count and accumulates `frame_dt() * 0.001` seconds. The active framework's
`ProjectBase::processHeadlessFrame(dt)` supplies `frame_dt` in milliseconds.
Drawing and tracing only read the counters. Explicit scene IDs are
`substrate-0`, `substrate-1`, etc.; the default layout contains one scene.

Use eight updates at `dt = 0.125 s`. Post-process frame `f` must report
`ticks = f + 1` and `time = (f + 1) / 8 s`, matching the runner's time.
The threshold is exact equality (zero seconds error), justified by the short,
binary-exact fixture; it is **not** a physical tolerance. No RNG is used and no
seed, input replay, or scene configuration override is required.

The one-second horizon checks startup, repeated processing, unit conversion,
trace output and a final draw. It supplies no behavioral/endurance coverage for
physics. The retained fixture supports replay of this wiring check; remove or
replace its counters when real project telemetry supersedes it.

## Tested build context

- Project HEAD before pilot edits: `96c371f76ea9aac8a1306f49ab4aea81ea09668f`.
  Pre-existing dirty/untracked user files were preserved.
- Root CMake target: `Substrate`; executable: `build/msvc-release-codex/app/app.exe`.
- Ninja, Release, Windows x64, MSVC `19.51.36257.0`, `BITLOOP_DEV_MODE=ON`.
- Provider: local `../../bitloop`, manifest version `0.9.20`, HEAD
  `23ea316e8325519bca89c14c43bbe0df134455f4` **with existing modifications**.
  A commit alone does not reproduce that framework; retained hashes identify
  the actual source inputs.
- Existing third-party installation:
  `build/ninja-debug/vcpkg_installed/x64-windows`, used read-only.
  `VCPKG_MANIFEST_INSTALL=OFF`; no dependency or registry was changed.
- Compilation and execution establish compatibility with these local sources
  and installed libraries. Detached package-backed compatibility was not tested;
  no claim is made about registry availability of matching diagnostic APIs.

For this workspace, the ignored `CMakeUserPresets.json` contains the following
configure preset and a matching build preset targeting `Substrate`. Preserve
other entries when recreating it:

```json
{
  "version": 3,
  "configurePresets": [{
    "name": "msvc-release-codex",
    "inherits": "ninja-release",
    "binaryDir": "${sourceDir}/build/msvc-release-codex",
    "cacheVariables": {
      "BUILD_FLAVOR": "msvc-release-codex",
      "CMAKE_TOOLCHAIN_FILE": "${sourceDir}/../../.vcpkg/scripts/buildsystems/vcpkg.cmake",
      "VCPKG_INSTALLED_DIR": "${sourceDir}/build/ninja-debug/vcpkg_installed",
      "VCPKG_MANIFEST_INSTALL": "OFF",
      "BITLOOP_PROVIDER": "SOURCE",
      "BITLOOP_SOURCE_DIR": "${sourceDir}/../../bitloop",
      "BITLOOP_DEV_MODE": "ON",
      "BITLOOP_BUILD_TESTS": "OFF"
    }
  }],
  "buildPresets": [{
    "name": "msvc-release-codex",
    "configurePreset": "msvc-release-codex",
    "targets": ["Substrate"]
  }]
}
```

The source checkout, installed dependency tree, VS C++ tools and a working SDL3/
OpenGL rendering context are prerequisites. On another machine, first verify
the appropriate existing provider/dependencies; do not silently substitute or
upgrade them. The local override above is not a portable dependency lock.

Run from the project root in PowerShell, initializing the developer environment
in the same shell as CMake:

```powershell
$vsPath = & 'C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe' -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
Import-Module "$vsPath/Common7/Tools/Microsoft.VisualStudio.DevShell.dll"
Enter-VsDevShell -VsInstallPath $vsPath -SkipAutomaticLocation -DevCmdArguments '-arch=x64 -host_arch=x64'
cmake --preset msvc-release-codex
cmake --build --preset msvc-release-codex --parallel 8
```

## Launch and check

Create a new sequential `.codex/runs/runNNNN_YYYYMMDD_HHMMSS` folder, preserving
earlier runs. Assign its absolute path to `$run` below. The recorded run used
`run0003_20261009_130412`. Use `Start-Process -Wait -PassThru`: direct invocation
of this Windows GUI-subsystem executable can return without setting
`$LASTEXITCODE`.

```powershell
$exe = (Resolve-Path build/msvc-release-codex/app/app.exe).Path
$p = Start-Process $exe -ArgumentList '--headless --project Substrate --list-scenes' -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput "$run/scenes.json" -RedirectStandardError "$run/scenes.stderr.log"
if ($p.ExitCode -ne 0) { throw "Scene listing failed: $($p.ExitCode)" }
$common = '--headless --project Substrate --scene substrate-0 --frames 8 --dt 0.125 --surface 800x600 --trace-format full'
$p = Start-Process $exe -ArgumentList "$common --trace `"$run/primary`" --snapshots --snapshot-every-frames 8" -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput "$run/primary.log" -RedirectStandardError "$run/primary.stderr.log"
if ($p.ExitCode -ne 0) { throw "Primary run failed: $($p.ExitCode)" }
$p = Start-Process $exe -ArgumentList "$common --trace `"$run/replay`"" -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput "$run/replay.log" -RedirectStandardError "$run/replay.stderr.log"
if ($p.ExitCode -ne 0) { throw "Replay failed: $($p.ExitCode)" }
./tooling/check_pilot.ps1 -Run $run
```

The checker validates all 16 observations, configuration, completion, exact
times/ticks, empty physical objects/events, byte-identical replay traces, a
selectable scene, and snapshot metadata/file existence. Separately inspect the
image; the script does not judge pixels. Full traces need no delta reconstruction.

## Recorded result and artifact map

All paths below are relative to
`.codex/runs/run0003_20261009_130412/` unless stated otherwise.

| F-pilot part | Concrete reference and guarantee |
| --- | --- |
| Instructions and fixture | This document; `Substrate/Substrate.h`, `Substrate/Substrate.cpp`; project-owned lifecycle counters, no physics |
| Executable build | `configure.log`, `build-final.log`, `CMakeUserPresets.json`, `CMakeCache.txt`; actual successful local target/configuration |
| Input identity | `source-hashes.json`, `dependency-status.txt`, `project-status-before.txt`, `pilot-source.patch`; source and installed dependency identities, including dirty source context |
| Launch selection | `scenes.json`; `substrate-0` is default and selectable |
| Observations | `primary/frames.jsonl`, `replay/frames.jsonl`, corresponding `metadata.json` and `summary.json`; 8 processed/traced frames per run |
| Automated oracle | Project `tooling/check_pilot.ps1`, retained `checks.json`; 16 exact observations, zero maximum time error |
| Inspected image | `primary/snapshots/frame_00000007_0_periodic_frame.webp`, `primary/snapshots.jsonl`; 800x600, frame 7, time 1 s |
| Compact conclusion | `observations.json`; commands, visual observation, limitations and claim scope |

Both processes exited 0. Final ticks = **8**, accumulated time = **1.000 s**;
all intermediate values matched exactly. Trace SHA-256 for both runs:
`35C8CE2D9262F920C64A5F3ACB3F8138500FF6E762503F36C5A82AB61E7A4151`.
The primary run rendered one snapshot with zero failures; the replay disabled
snapshot rendering and still produced identical semantic observations.

The image was actually inspected: the upper-left text reads “Diagnostic pilot -
no physics”, “ticks = 8”, and “time (s) = 1.000000”, clearly visible over the
existing coordinate grid. It agrees with frame 7 telemetry.

The initial compile failed because pilot text coordinates used integers with
the framework's floating-point transform template. The project calls were
corrected to doubles; `build-initial-failure.log` retains that resolved failure.
An initial launch wrapper also stopped because direct invocation yielded no
exit code; explicit process waiting corrected it before the two recorded runs.
No framework repair or compatibility shim was added.

**INCONCLUSIVE physical claim:** passive coupled stability, conservation, fluid
transport and biological activity cannot be assessed. There are zero physical
objects and no solver, physical oracle, units contract or approved error budget
in this fixture. Workflow success must not release physical adoption gates.
Checkpoint hooks still return false; restart, scripted interactions, production
mode, cross-hardware determinism and performance/endurance qualification are
outside this pilot's checks. MindGraph saving, review and reload must be verified
by the coordinator; this worker's report is not evidence that those occurred.
