param([switch]$Document)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Independent binary64 algebra checks; this does not run a Substrate simulation.
function Assert-Near([string]$Name, [double]$Actual, [double]$Expected, [double]$Tolerance) {
    $errorValue = [Math]::Abs($Actual - $Expected)
    if (-not [double]::IsFinite($Actual) -or $errorValue -gt $Tolerance) {
        throw "$Name error $errorValue exceeds $Tolerance (actual $Actual, expected $Expected)"
    }
    [pscustomobject]@{ check = $Name; value = $Actual; expected = $Expected; error = $errorValue; tolerance = $Tolerance }
}
function Store([double]$Area, [double]$Mass) {
    10.0 * ($Area - $Mass - $Mass * [Math]::Log($Area / $Mass))
}
function Pressure([double]$Area, [double]$Mass) { 10.0 * ($Mass / $Area - 1.0) }
function Enthalpy([double]$Area, [double]$Mass) { 10.0 * [Math]::Log($Mass / $Area) }
function Head-Donor([double]$Transfer) { ((Store 1 1.1) - (Store 1 (1.1 - $Transfer))) / $Transfer }
function Head-Receiver([double]$Transfer) { ((Store 1 (0.9 + $Transfer)) - (Store 1 0.9)) / $Transfer }

$checks = @()
$area = 128 * [Math]::Sin(2 * [Math]::PI / 128) / 2
$meanR2 = (2 + [Math]::Cos(2 * [Math]::PI / 128)) / 6
$inertia = $area * $meanR2
$epsilon = 1e-5
$checks += Assert-Near 'p = -partial U/partial A, N/m' (-((Store ($area + $epsilon) (1.1 * $area)) - (Store ($area - $epsilon) (1.1 * $area))) / (2 * $epsilon)) (Pressure $area (1.1 * $area)) 1e-8
$checks += Assert-Near 'h = partial U/partial M, J/kg' (((Store $area (1.1 * $area + $epsilon)) - (Store $area (1.1 * $area - $epsilon))) / (2 * $epsilon)) (Enthalpy $area (1.1 * $area)) 1e-8
$checks += Assert-Near 'h = e + p/rho, J/kg' ((Store $area (1.1 * $area)) / (1.1 * $area) + (Pressure $area (1.1 * $area)) / 1.1) (Enthalpy $area (1.1 * $area)) 1e-12

# Independent edge quadrature of a regular polygon. Three-point Gauss is exact
# for the cubic pressure-work and angular-impulse polynomials used here.
$gaussX = @(-[Math]::Sqrt(3.0 / 5), 0.0, [Math]::Sqrt(3.0 / 5))
$gaussW = @((5.0 / 9), (8.0 / 9), (5.0 / 9))
$sumFx = 0.0; $sumFy = 0.0; $sumPower = 0.0; $sumTorque = 0.0
$spinPower = 0.0; $spinTorque = 0.0; $dilatePower = 0.0
$alpha = 0.1; $beta = 0.2
for ($edge = 0; $edge -lt 128; ++$edge) {
    $theta0 = 2 * [Math]::PI * $edge / 128
    $theta1 = 2 * [Math]::PI * ($edge + 1) / 128
    $x0 = [Math]::Cos($theta0); $y0 = [Math]::Sin($theta0)
    $dx = [Math]::Cos($theta1) - $x0; $dy = [Math]::Sin($theta1) - $y0
    for ($point = 0; $point -lt 3; ++$point) {
        $s = ($gaussX[$point] + 1) / 2
        $x = $x0 + $s * $dx; $y = $y0 + $s * $dy
        $weight = $gaussW[$point] / 2
        $piTranslate = -(0.03 * $x + 0.04 * $y)
        $fx = $piTranslate * $dy * $weight
        $fy = -$piTranslate * $dx * $weight
        $sumFx += $fx; $sumFy += $fy
        $sumPower += $fx * 0.2 + $fy * (-0.1)
        $sumTorque += $x * $fy - $y * $fx
        $piSpin = 0.5 * 0.1 * 0.1 * ($x * $x + $y * $y - $meanR2)
        $spinTorque += $piSpin * (-$x * $dx - $y * $dy) * $weight
        $spinPower += $piSpin * ((-0.1 * $y) * $dy - (0.1 * $x) * $dx) * $weight
        $piDilation = -0.5 * $beta * ($x * $x + $y * $y - $meanR2)
        $dilatePower += $piDilation * $alpha * ($x * $dy - $y * $dx) * $weight
    }
}
$checks += Assert-Near 'translation wall reaction Fx, N' $sumFx (-$area * 0.03) 1e-12
$checks += Assert-Near 'translation wall reaction Fy, N' $sumFy (-$area * 0.04) 1e-12
$checks += Assert-Near 'translation wall power, W' $sumPower (-$area * (0.2 * 0.03 - 0.1 * 0.04)) 1e-12
$checks += Assert-Near 'translation torque, N m' $sumTorque 0 1e-12
$checks += Assert-Near 'initialized rigid spin torque, N m' $spinTorque 0 1e-12
$checks += Assert-Near 'initialized rigid spin wall power, W' $spinPower 0 1e-12
$checks += Assert-Near 'affine dilation inertia power, W' $dilatePower (-$area * $meanR2 * $alpha * $beta) 1e-12

# Continuum Q1 point from the contract, including the exterior kinetic flux.
$radius = 1.02; $speed = 0.1; $outer = 4.0
$mass = 1.1 * [Math]::PI; $shell = 0.2 * [Math]::PI
$logRadius = [Math]::Log($outer / $radius)
$p = Pressure ([Math]::PI * $radius * $radius) $mass
$acceleration = (2 * [Math]::PI * $radius * ($p - $speed * $speed * ($logRadius + 0.5 * ($radius * $radius / ($outer * $outer) - 1))) - 2 * [Math]::PI * ($radius - 1)) / ($shell + $mass / 2 + 2 * [Math]::PI * $radius * $radius * $logRadius)
$contentKdot = $mass * $speed * $acceleration / 2
$contentUdot = -$p * 2 * [Math]::PI * $radius * $speed
$rho = $mass / ([Math]::PI * $radius * $radius)
$piWall = -$rho * $radius * $acceleration / 4
$wallPower = ($p + $piWall) * 2 * [Math]::PI * $radius * $speed
$checks += Assert-Near 'free expansion content energy plus wall work, W' ($contentKdot + $contentUdot + $wallPower) 0 1e-12
$exteriorKdot = [Math]::PI * ((2 * $radius * $speed * $speed * $speed + 2 * $radius * $radius * $speed * $acceleration) * $logRadius - $radius * $speed * $speed * $speed)
$shellKdot = $shell * $speed * $acceleration
$shellUdot = 2 * [Math]::PI * ($radius - 1) * $speed
$outerFlux = [Math]::PI * [Math]::Pow($radius * $speed, 3) / ($outer * $outer)
$checks += Assert-Near 'Q1 whole radial energy plus outer kinetic flux, W' ($contentKdot + $contentUdot + $exteriorKdot + $shellKdot + $shellUdot + $outerFlux) 0 1e-12

# Compression: independent midpoint integration of -p dA against state energy.
$compressionArea = 0.81 * $area
$compressionEnergy = Store $compressionArea $area
$integrationWork = 0.0
$recoveryWork = 0.0
$samples = 10000
$deltaArea = ($compressionArea - $area) / $samples
for ($sample = 0; $sample -lt $samples; ++$sample) {
    $integrationWork -= (Pressure ($area + ($sample + 0.5) * $deltaArea) $area) * $deltaArea
    $recoveryWork += (Pressure ($compressionArea - ($sample + 0.5) * $deltaArea) $area) * $deltaArea
}
$checks += Assert-Near 'compression integral -p dA, J' $integrationWork $compressionEnergy 1e-8
$checks += Assert-Near 'recovery integral -p dA, J' $recoveryWork (-$compressionEnergy) 1e-8

# Zero-storage resistive port thermodynamic step, not a channel-flow simulation.
$duration = 0.1; $conductance = 0.005
$left = 1e-8; $right = 0.01
for ($iteration = 0; $iteration -lt 60; ++$iteration) {
    $transfer = ($left + $right) / 2
    $equation = $transfer - $duration * $conductance * ((Head-Donor $transfer) - (Head-Receiver $transfer))
    if ($equation -gt 0) { $right = $transfer } else { $left = $transfer }
}
$transfer = ($left + $right) / 2
$headA = Head-Donor $transfer; $headB = Head-Receiver $transfer
$dHydraulic = $transfer * ($headA - $headB)
$rate = $transfer / $duration
$portLength = 0.25
$upwindSpeed = $rate / ((1.1 - $transfer / 2) * $portLength)
$receiverSpeed = -0.02
$receiverAfter = (0.9 * $receiverSpeed + $transfer * $upwindSpeed) / (0.9 + $transfer)
$beforeK = 0.5 * 1.1 * $upwindSpeed * $upwindSpeed + 0.5 * 0.9 * $receiverSpeed * $receiverSpeed
$afterK = 0.5 * (1.1 - $transfer) * $upwindSpeed * $upwindSpeed + 0.5 * (0.9 + $transfer) * $receiverAfter * $receiverAfter
$dMix = 0.5 * $transfer * 0.9 / (0.9 + $transfer) * [Math]::Pow($upwindSpeed - $receiverSpeed, 2)
$deltaU = (Store 1 (1.1 - $transfer)) + (Store 1 (0.9 + $transfer)) - (Store 1 1.1) - (Store 1 0.9)
$checks += Assert-Near 'finite rate constitutive residual, kg' ($transfer - $duration * $conductance * ($headA - $headB)) 0 1e-12
$checks += Assert-Near 'finite transfer mass, kg' ((1.1 - $transfer) + (0.9 + $transfer)) 2 1e-12
$checks += Assert-Near 'finite transfer momentum, kg m/s' ((1.1 - $transfer) * $upwindSpeed + (0.9 + $transfer) * $receiverAfter) (1.1 * $upwindSpeed + 0.9 * $receiverSpeed) 1e-12
$checks += Assert-Near 'finite transfer kinetic capture plus dissipation, J' ($afterK - $beforeK + $dMix) 0 1e-12
$checks += Assert-Near 'finite transfer total energy plus physical dissipation, J' ($deltaU + $afterK - $beforeK + $dHydraulic + $dMix) 0 1e-12
$checks += Assert-Near 'finite transfer global tracer, kg' ((1.1 - $transfer) * 0.2 + 0.9 * 0.1 + $transfer * 0.2) (1.1 * 0.2 + 0.9 * 0.1) 1e-12
if ($dHydraulic -lt 0 -or $dMix -lt 0 -or $transfer -ge 0.1) { throw 'Invalid finite exchange or dissipation' }

$ellipseA = 1.25; $ellipseB = 0.8
$ellipseRatio = ($ellipseA * $ellipseA - $ellipseB * $ellipseB) / ($ellipseA * $ellipseA + $ellipseB * $ellipseB)
$omegaPeak = [Math]::PI * [Math]::PI / 2
$mach = $ellipseRatio * $omegaPeak * $ellipseA / [Math]::Sqrt(10)
if ($mach -le 0.1) { throw 'Expected Q4 reduced-model validity mismatch not detected' }

if ($Document) {
    $root = Split-Path $PSScriptRoot -Parent
    $docPath = Join-Path $root 'docs/COMPARTMENT_LAW.md'
    $doc = Get-Content -LiteralPath $docPath -Raw
    foreach ($term in @('F-contents-law', 'UNAPPROVED', 'actual area', 'circulation', 'inertia', 'finite', 'checkpoint', 'resolved interior', 'prefix', 'C-contents', 'C-boundary', 'Q4', 'Q5', 'physical dissipation')) {
        if (-not $doc.Contains($term)) { throw "Document missing $term" }
    }
    foreach ($link in [regex]::Matches($doc, '\]\(([^)#]+)(?:#[^)]*)?\)')) {
        $target = $link.Groups[1].Value
        if ($target -notmatch '^https?://' -and -not (Test-Path -LiteralPath (Join-Path (Split-Path $docPath -Parent) $target))) { throw "Broken local link $target" }
    }
    if ($doc -match '(?m)[\t ]+\r?$') { throw 'Trailing document whitespace' }
    'Document terms, local link targets and whitespace: PASS'
}
$checks | ConvertTo-Json -Depth 3
[pscustomobject]@{
    algebra_checks = $checks.Count; area_m2 = $area; inertia_kg_m2 = $inertia
    translation_K_J = 0.025 * $area; spin_K_J = 0.005 * $inertia
    radial_acceleration_m_s2 = $acceleration; radial_inertia_pressure_N_m = $piWall
    radial_wall_power_W = $wallPower; compression_U_J = $compressionEnergy
    compression_p_N_m = Pressure $compressionArea $area
    transfer_kg = $transfer; rate_kg_s = $rate; donor_head_J_kg = $headA; receiver_head_J_kg = $headB
    donor_port_speed_m_s = $upwindSpeed; receiver_after_m_s = $receiverAfter
    hydraulic_dissipation_J = $dHydraulic; capture_dissipation_J = $dMix
    receiver_tracer_fraction = (0.09 + 0.2 * $transfer) / (0.9 + $transfer)
    Q4_potential_speed_m_s = $mach * [Math]::Sqrt(10); Q4_acoustic_ratio = $mach
    Q4_rigid_inertia_kg_m2 = [Math]::PI * ($ellipseA * $ellipseA + $ellipseB * $ellipseB) / 4
    Q4_irrotational_inertia_kg_m2 = [Math]::PI * [Math]::Pow($ellipseA * $ellipseA - $ellipseB * $ellipseB, 2) / (4 * ($ellipseA * $ellipseA + $ellipseB * $ellipseB))
} | ConvertTo-Json
