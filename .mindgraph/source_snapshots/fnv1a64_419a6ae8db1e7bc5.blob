param([Parameter(Mandatory)][string]$Run)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$maxTimeError = 0.0
foreach ($variant in @('primary', 'replay')) {
    $metadata = Get-Content "$Run/$variant/metadata.json" -Raw | ConvertFrom-Json
    $summary = Get-Content "$Run/$variant/summary.json" -Raw | ConvertFrom-Json
    $frames = @(Get-Content "$Run/$variant/frames.jsonl" | ForEach-Object { $_ | ConvertFrom-Json })
    if ($metadata.trace.format -ne 'full' -or $metadata.dt -ne 0.125 -or
        $metadata.frames_requested -ne 8 -or $metadata.selected_scene_ids.Count -ne 1 -or
        $metadata.selected_scene_ids[0] -ne 'substrate-0' -or $frames.Count -ne 8 -or
        -not $summary.ok -or $summary.processed_frames -ne 8 -or $summary.trace_frames -ne 8 -or
        $summary.dropped_objects -ne 0 -or $summary.snapshots_failed -ne 0) {
        throw "$variant configuration or completion mismatch"
    }
    for ($i = 0; $i -lt 8; ++$i) {
        $f = $frames[$i]
        $expectedTime = ($i + 1) * 0.125
        $error = [Math]::Abs($f.metrics.diagnostic_time_seconds - $expectedTime)
        $maxTimeError = [Math]::Max($maxTimeError, $error)
        if ($f.frame -ne $i -or $f.dt -ne 0.125 -or $f.time -ne $expectedTime -or
            $f.project -ne 'Substrate' -or $f.scene -ne 'substrate-0' -or
            $f.metrics.diagnostic_ticks -ne ($i + 1) -or $error -ne 0.0 -or
            $f.metrics.diagnostic_kind -ne 'lifecycle_only_no_physics' -or
            $f.objects.Count -ne 0 -or $f.events.Count -ne 0) {
            throw "$variant frame $i failed the exact lifecycle oracle"
        }
    }
}
$primaryHash = (Get-FileHash "$Run/primary/frames.jsonl" -Algorithm SHA256).Hash
$replayHash = (Get-FileHash "$Run/replay/frames.jsonl" -Algorithm SHA256).Hash
if ($primaryHash -ne $replayHash) { throw 'Replay traces differ' }
$snapshots = @(Get-Content "$Run/primary/snapshots.jsonl" | ForEach-Object { $_ | ConvertFrom-Json })
if ($snapshots.Count -ne 1) { throw 'Expected exactly one snapshot' }
$snapshot = $snapshots[0]
if (-not $snapshot.rendered -or $snapshot.error -ne '' -or $snapshot.frame -ne 7 -or
    $snapshot.time -ne 1.0 -or $snapshot.resolution.width -ne 800 -or $snapshot.resolution.height -ne 600 -or
    -not (Test-Path "$Run/primary/$($snapshot.filename)")) { throw 'Snapshot metadata or file missing' }
$scenes = Get-Content "$Run/scenes.json" -Raw | ConvertFrom-Json
if ($scenes.scenes.Count -ne 1 -or $scenes.scenes[0].id -ne 'substrate-0' -or
    -not $scenes.scenes[0].selectable) { throw 'Selectable scene catalogue mismatch' }
[ordered]@{
    passed = $true
    observations_checked = 16
    final_ticks = 8
    final_time_seconds = 1.0
    fixed_dt_seconds = 0.125
    max_time_error_seconds = $maxTimeError
    tolerance_seconds = 0.0
    tolerance_basis = 'Binary-exact 1/8-second lifecycle fixture, not a physical error budget'
    replay_sha256 = $primaryHash
    snapshot = "primary/$($snapshot.filename)"
    snapshot_visual_inspection = 'Separate human/agent inspection required; this script checks metadata only'
    physical_claim = 'INCONCLUSIVE: no physical model or physical oracle is exercised'
} | ConvertTo-Json
