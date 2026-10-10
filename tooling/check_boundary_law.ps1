param([switch]$Document)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Independent arithmetic references; this script does not advance a Substrate world.
function Check([string]$Name, [double]$Actual, [double]$Expected, [double]$Tolerance = 1e-12) {
    $errorValue = [Math]::Abs($Actual - $Expected)
    if (-not [double]::IsFinite($Actual) -or $errorValue -gt $Tolerance) {
        throw "$Name failed: $Actual versus $Expected, error $errorValue > $Tolerance"
    }
    [pscustomobject]@{ name=$Name; actual=$Actual; expected=$Expected; error=$errorValue; tolerance=$Tolerance }
}
function Stored-Energy([double]$Area, [double]$Mass) {
    10 * ($Area - $Mass - $Mass * [Math]::Log($Area / $Mass))
}
function Polygon-Area([double[]]$Coordinates) {
    $sum = 0.0
    $count = $Coordinates.Count / 2
    for ($i = 0; $i -lt $count; ++$i) {
        $j = ($i + 1) % $count
        $sum += $Coordinates[2*$i]*$Coordinates[2*$j+1] - $Coordinates[2*$j]*$Coordinates[2*$i+1]
    }
    $sum / 2
}
function Eligible-Edge([string]$SideA, [string]$SideB, [double]$Aperture, [bool]$Barrier) {
    ($SideA -eq $SideB) -and ($Aperture -gt 0) -and (-not $Barrier)
}

$checks = @()
$h = 1.0/16
$delta = 0.00125
$rho = 1.0
$a0 = 0.5*$h; $b0 = 0.5*$h
$a1 = 0.51*$h; $b1 = 0.505*$h
$da = $a1-$a0; $db = $b1-$b0
$ux = $da/$delta; $uy = $db/$delta
$solidChange = $a1*$b1-$a0*$b0
$sweep = -(($b0+$b1)*$da + ($a0+$a1)*$db)/2
# Outer right/top full apertures, left/bottom blocked by b(t)/a(t).
$outerFlux = $delta*($ux*($b0+$b1)/2 + $uy*($a0+$a1)/2)
$massChange = -$rho*$outerFlux
$checks += Check 'B1 independent facet sweep versus endpoint area, m2' $sweep (-$solidChange)
$checks += Check 'B1 open aperture flux plus swept area, m2' ($outerFlux+$sweep) 0
$checks += Check 'B1 fluid area after motion, m2' ($h*$h-$a1*$b1) (0.74245*$h*$h)
$checks += Check 'B1 mass from finite flux, kg' $massChange (-2.94921875e-5)
$checks += Check 'B1 advected momentum x, kg m/s' ($ux*$massChange) (-1.474609375e-5)
$checks += Check 'B1 advected momentum y, kg m/s' ($uy*$massChange) (-7.373046875e-6)
$checks += Check 'B1 advected kinetic energy, J' (0.5*($ux*$ux+$uy*$uy)*$massChange) (-4.608154296875e-6)
$checks += Check 'B1 uniform pressure wall plus reservoir work, J' (2*$sweep+2*$outerFlux) 0
$wrongSweep = -($b0*$da+$a0*$db)
$cornerError = [Math]::Abs($wrongSweep-$sweep)
if ($cornerError -le 1e-7*$h*$h) { throw 'Frozen-facet negative control did not exceed the geometric budget' }
$checks += Check 'B1 missed corner cross term, m2' $cornerError 1.953125e-7

$areas0 = @(0.995,0.0,0.005,1.0)
$areas1 = @(1.0,0.005,0.0,0.995)
$faceFlux = @(-0.005,-0.005,0.005,0.005)
$newMass = [double[]]::new(4)
for ($i = 0; $i -lt 4; ++$i) {
    $newMass[$i] = $rho*($areas0[$i]-$faceFlux[$i])*$h*$h
    $checks += Check "B2 fragment $i local GCL, m2" (($areas1[$i]-$areas0[$i]+$faceFlux[$i])*$h*$h) 0
    $checks += Check "B2 fragment $i endpoint mass, kg" $newMass[$i] ($rho*$areas1[$i]*$h*$h)
}
$checks += Check 'B2 total patch mass, kg' (($newMass | Measure-Object -Sum).Sum) (2*$rho*$h*$h)
$checks += Check 'B2 side-resolved grid-face half-interval flux, m2' (0.5*$h*$delta/2) (0.005*$h*$h)
$wallForce = (2-0.5)*$h
$wallWork = $wallForce*0.01*$h
$checks += Check 'B2 membrane pressure force, N' $wallForce 0.09375
$checks += Check 'B2 membrane impulse, kg m/s' ($wallForce*$delta) 0.0001171875
$checks += Check 'B2 membrane work from displacement, J' $wallWork 5.859375e-5
$checks += Check 'B2 work from separate sided sweeps, J' ((2-0.5)*0.01*$h*$h) $wallWork
if (Eligible-Edge 'left' 'right' $h $true) { throw 'Opposite-side barrier edge was accepted' }
if (Eligible-Edge 'left' 'left' 0 $false) { throw 'Point-contact edge was accepted' }
if (-not (Eligible-Edge 'left' 'left' $h $false)) { throw 'Open same-side edge was rejected' }
# Pooling before motion conserves mass but deposits left tracer into right fluid.
$badTracerRight = 0.995 * 0.005 * $rho*$h*$h
if ($badTracerRight -le 0) { throw 'Forbidden tracer-pooling negative control missed' }
$isolatedArea = 0.005*$h*$h
$eligibleNeighbours = @()
if (-not ($isolatedArea -lt 0.25*$h*$h -and $eligibleNeighbours.Count -eq 0)) {
    throw 'Isolated-small-region negative control missed'
}

# Positive overlap remap: old cells each area 1; new partition areas 0.5 and 1.5.
$oldMass = @(2.0,2.0); $oldVelocity = @(1.0,-1.0)
$overlap = @(@(0.5,0.0), @(0.5,1.0))
$remapMass = [double[]]::new(2); $remapP = [double[]]::new(2)
for ($target = 0; $target -lt 2; ++$target) {
    for ($source = 0; $source -lt 2; ++$source) {
        $remapMass[$target] += $overlap[$target][$source]*$oldMass[$source]
        $remapP[$target] += $overlap[$target][$source]*$oldMass[$source]*$oldVelocity[$source]
    }
}
$remapK = 0.5*$remapP[0]*$remapP[0]/$remapMass[0] + 0.5*$remapP[1]*$remapP[1]/$remapMass[1]
$checks += Check 'positive overlap remap mass, kg' ($remapMass[0]+$remapMass[1]) 4
$checks += Check 'positive overlap remap momentum, kg m/s' ($remapP[0]+$remapP[1]) 0
$checks += Check 'positive overlap remap numerical kinetic loss, J' (2-$remapK) (4.0/3)

# One open cell: B=1 m, m=1 kg, p_boundary=0, moving wall sweep -0.04 m2.
$step = 0.1; $before = 0.2; $knownFlux = -0.4
$pressure = -($before+$knownFlux)/$step
$after = $before+$step*$pressure
$fluidWork = -$step*$pressure*$knownFlux
$projectionLoss = 0.5*($after-$before)*($after-$before)
$checks += Check 'moving-wall pressure solve velocity, m/s' $after 0.4
$checks += Check 'moving-wall pressure solve GCL, m2/s' ($after+$knownFlux) 0
$checks += Check 'projection energy/work identity, J' (0.5*($after*$after-$before*$before)-$fluidWork+$projectionLoss) 0
$checks += Check 'pressure wall/fluid work pairing, J' ($fluidWork+$pressure*$knownFlux*$step) 0
$closedSweep = -0.04
if ([Math]::Abs($closedSweep) -le 1e-12) { throw 'Incompatible closed-volume negative control missed' }

$gap = 0.25; $gradient = 0.1; $mu = 0.1; $length = 2
$exactQ = $gradient*[Math]::Pow($gap,3)/(12*$mu)
$channelQ = @()
foreach ($n in @(4,8,16)) {
    $spacing = $gap/$n
    $qDiscrete = $exactQ + $gradient*$gap*$spacing*$spacing/(6*$mu)
    $checks += Check "B3 channel $n-cell relative flow error" (($qDiscrete-$exactQ)/$exactQ) (2.0/($n*$n))
    $channelQ += $qDiscrete
}
$checks += Check 'B3 base discrete power, W' ($gradient*$length*$channelQ[0]) 0.00029296875

$nPolygon = 128; $r0 = 1.0; $r1 = 1.000125
$q0 = [double[]]::new(2*$nPolygon); $q1 = [double[]]::new(2*$nPolygon)
for ($i = 0; $i -lt $nPolygon; ++$i) {
    $angle = 2*[Math]::PI*$i/$nPolygon
    $q0[2*$i] = $r0*[Math]::Cos($angle); $q0[2*$i+1] = $r0*[Math]::Sin($angle)
    $q1[2*$i] = $r1*[Math]::Cos($angle); $q1[2*$i+1] = $r1*[Math]::Sin($angle)
}
$area0 = Polygon-Area $q0; $area1 = Polygon-Area $q1
$areaFormula = $nPolygon/2*[Math]::Sin(2*[Math]::PI/$nPolygon)
$sweepGradient = 0.0; $forceX = 0.0; $forceY = 0.0; $torque = 0.0
for ($i = 0; $i -lt $nPolygon; ++$i) {
    $previous = ($i+$nPolygon-1)%$nPolygon; $next = ($i+1)%$nPolygon
    $gx = ($q0[2*$next+1]+$q1[2*$next+1]-$q0[2*$previous+1]-$q1[2*$previous+1])/4
    $gy = ($q0[2*$previous]+$q1[2*$previous]-$q0[2*$next]-$q1[2*$next])/4
    $sweepGradient += $gx*($q1[2*$i]-$q0[2*$i])+$gy*($q1[2*$i+1]-$q0[2*$i+1])
    $forceX += $gx; $forceY += $gy
    $torque += ($q0[2*$i]+$q1[2*$i])*$gy/2-($q0[2*$i+1]+$q1[2*$i+1])*$gx/2
}
$areaDelta = $area1-$area0
$contentMass = 1.1*$area0
$energyDelta = (Stored-Energy $area1 $contentMass)-(Stored-Energy $area0 $contentMass)
$secantPressure = -$energyDelta/$areaDelta
$checks += Check 'B4 polygon area versus independent regular-polygon formula, m2' $area0 $areaFormula
$checks += Check 'B4 swept area from midpoint shape gradient, m2' $sweepGradient $areaDelta
$checks += Check 'B4 polygon mean-pressure force sum x at unit pressure, N' $forceX 0
$checks += Check 'B4 polygon mean-pressure force sum y at unit pressure, N' $forceY 0
$checks += Check 'B4 polygon mean-pressure torque at unit pressure, N m' $torque 0
$checks += Check 'B4 contents compression work plus stored change, J' ($secantPressure*$sweepGradient+$energyDelta) 0
$checks += Check 'B4 exterior mass change plus outer outflow, kg' (-$rho*$areaDelta+$rho*$sweepGradient) 0

# Independent continuous radial Q1 reference, including contents/exterior inertia.
$radius = 1.02; $speed = 0.1; $outerRadius = 4.0
$pi = [Math]::PI; $structureMass = 0.2*$pi; $circleMass = 1.1*$pi
$logRatio = [Math]::Log($outerRadius/$radius)
$chamberPressure = 10*(1.1/($radius*$radius)-1)
$acceleration = (2*$pi*$radius*($chamberPressure-$speed*$speed*($logRatio+0.5*($radius*$radius/($outerRadius*$outerRadius)-1)))-2*$pi*($radius-1))/($structureMass+$circleMass/2+2*$pi*$radius*$radius*$logRatio)
$kineticRate = ($structureMass+$circleMass/2)*$speed*$acceleration + $pi*((2*$radius*[Math]::Pow($speed,3)+2*$radius*$radius*$speed*$acceleration)*$logRatio-$radius*[Math]::Pow($speed,3))
$potentialRate = 2*$pi*($radius-1)*$speed - $chamberPressure*2*$pi*$radius*$speed
$outerEnergyFlux = $pi*[Math]::Pow($radius*$speed,3)/($outerRadius*$outerRadius)
$radialResidual = $kineticRate+$potentialRate+$outerEnergyFlux
$checks += Check 'B4 radial acceleration reference, m/s2' $acceleration 0.308980074751185
$checks += Check 'B4 radial total energy rate plus outer flux, W' $radialResidual 0

if ($Document) {
    $root = Split-Path $PSScriptRoot -Parent
    $docPath = Join-Path $root 'docs/BOUNDARY_LAW.md'
    $doc = Get-Content -LiteralPath $docPath -Raw
    foreach ($term in @('F-boundary-law','UNAPPROVED','C-boundary','C-fluid','C-contents','C-mechanics','agglomeration','space-time','swept','nullspace','checkpoint','B1.','B2.','B3.','B4.','0.25 m','prefix','pressure','unsupported','12.5%','0.817015358','Complete calculated')) {
        if (-not $doc.Contains($term)) { throw "Document missing $term" }
    }
    foreach ($link in [regex]::Matches($doc,'\]\(([^)#]+)(?:#[^)]*)?\)')) {
        $target = $link.Groups[1].Value
        if ($target -notmatch '^https?://' -and -not (Test-Path -LiteralPath (Join-Path (Split-Path $docPath -Parent) $target))) { throw "Broken local link $target" }
    }
    foreach ($file in @($docPath,$PSCommandPath)) {
        $body = Get-Content -LiteralPath $file -Raw
        if ($body -match '(?m)[\t ]+\r?$') { throw "Trailing whitespace: $file" }
    }
    $expectedHashes = @{
        'docs/PHYSICAL_CONTRACT.md'='48FF446850E0DD31A0AE5E20F803923DB9F6E22A384A9532E7144E04F4CFDC07'
        'docs/MECHANICS_LAW.md'='EE2C5000A81D357CDE5F706D98F43A45C52429E543EE80333DF7964A6DF8145A'
        'docs/COMPARTMENT_LAW.md'='C05278878AE4A3DA7FFB1035662F2A4002BF0C8D098BC19CF80E41014AAF96B3'
        'docs/STATIONARY_FLOW_LAW.md'='BC2BE2E0568DFAECBE167FD5AF4C79E57A3B3957E07E65DA1BD55CB56F5DE53A'
        'Substrate/Substrate.h'='FC24DB1F60D89A1955C5DFC24EB95A15DBA86A736C03134A17B43FEA34E4F6E5'
        'Substrate/Substrate.cpp'='F6CF93EB3AD740399016BD2AA4B4C0FB84E9C576F38338308CF69C6AA87A7FB6'
    }
    foreach ($entry in $expectedHashes.GetEnumerator()) {
        if ((Get-FileHash -LiteralPath (Join-Path $root $entry.Key) -Algorithm SHA256).Hash -ne $entry.Value) { throw "Input/source changed: $($entry.Key)" }
    }
    'Document terms, local links, whitespace, four input hashes and two source hashes: PASS'
}
$checks | ConvertTo-Json -Depth 3
[pscustomobject]@{
    algebra_checks=$checks.Count; negative_controls=5
    corner_sweep_m2=$sweep; wrong_corner_sweep_error_m2=$cornerError
    membrane_work_J=$wallWork; forbidden_pooling_tracer_kg=$badTracerRight
    remap_numerical_loss_J=2-$remapK; projection_numerical_loss_J=$projectionLoss
    channel_base_relative_flow_error=($channelQ[0]-$exactQ)/$exactQ
    polygon_expansion_area_m2=$areaDelta; polygon_secant_pressure_N_m=$secantPressure
    area_gradient_error_m2=$sweepGradient-$areaDelta
    radial_acceleration_m_s2=$acceleration; radial_energy_residual_W=$radialResidual
} | ConvertTo-Json
