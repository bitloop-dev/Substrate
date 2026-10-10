param([switch]$Document)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Binary64 reference algebra only. This does not advance the Substrate world.
function Check([string]$Name, [double]$Actual, [double]$Expected, [double]$Tolerance = 1e-12) {
    $difference = [Math]::Abs($Actual - $Expected)
    if (-not [double]::IsFinite($Actual) -or $difference -gt $Tolerance) {
        throw "$Name failed: $Actual versus $Expected, error $difference > $Tolerance"
    }
    [pscustomobject]@{ name = $Name; value = $Actual; expected = $Expected; error = $difference; tolerance = $Tolerance }
}
function Law([double[]]$F) {
    $jacobian = $F[0] * $F[3] - $F[1] * $F[2]
    if ($jacobian -le 0) { throw 'Inverted material is undefined' }
    $logJ = [Math]::Log($jacobian)
    $traceC = 0.0
    foreach ($entry in $F) { $traceC += $entry * $entry }
    $inverseTranspose = @($F[3] / $jacobian; -$F[2] / $jacobian; -$F[1] / $jacobian; $F[0] / $jacobian)
    $stress = for ($component = 0; $component -lt 4; ++$component) {
        2 * ($F[$component] - $inverseTranspose[$component]) + 4 * $logJ * $inverseTranspose[$component]
    }
    [pscustomobject]@{ J = $jacobian; W = ($traceC - 2 - 2 * $logJ) + 2 * $logJ * $logJ; P = $stress }
}
function Triangle([double[]]$q) {
    $F = @($q[2] - $q[0]; $q[4] - $q[0]; $q[3] - $q[1]; $q[5] - $q[1])
    $law = Law $F
    $p = $law.P
    [pscustomobject]@{
        U = 0.5 * $law.W; J = $law.J; P = $p
        force = @(0.5 * ($p[0] + $p[1]); 0.5 * ($p[2] + $p[3]); -0.5 * $p[0]; -0.5 * $p[2]; -0.5 * $p[1]; -0.5 * $p[3])
    }
}
function Mass-Times([double[]]$v) {
    $result = [double[]]::new(6)
    for ($node = 0; $node -lt 3; ++$node) {
        for ($source = 0; $source -lt 3; ++$source) {
            $weight = 0.5 / 12
            if ($node -eq $source) { $weight *= 2 }
            for ($axis = 0; $axis -lt 2; ++$axis) { $result[2 * $node + $axis] += $weight * $v[2 * $source + $axis] }
        }
    }
    ,$result
}
function Dot([double[]]$a, [double[]]$b) {
    $sum = 0.0
    for ($index = 0; $index -lt $a.Count; ++$index) { $sum += $a[$index] * $b[$index] }
    $sum
}

$checks = @()
$reference = @(0.0,0.0,1.0,0.0,0.0,1.0)
$translation = @(0.2,-0.1,0.2,-0.1,0.2,-0.1)
$momentum = Mass-Times $translation
$checks += Check 'consistent mass translation momentum x, kg m/s' ($momentum[0]+$momentum[2]+$momentum[4]) 0.1
$checks += Check 'consistent mass translation energy, J' (0.5 * (Dot $translation $momentum)) 0.0125
$omega = 0.2
$spin = [double[]]::new(6)
for ($node = 0; $node -lt 3; ++$node) {
    $spin[2 * $node] = -$omega * ($reference[2 * $node + 1] - 1.0 / 3)
    $spin[2 * $node + 1] = $omega * ($reference[2 * $node] - 1.0 / 3)
}
$spinMomentum = Mass-Times $spin
$spinK = 0.5 * (Dot $spin $spinMomentum)
$quadratureK = 0.0
foreach ($bary in @(@((1.0/6),(1.0/6)), @((2.0/3),(1.0/6)), @((1.0/6),(2.0/3)))) {
    $quadratureK += 0.5 / 6 * $omega * $omega * ([Math]::Pow($bary[0] - 1.0/3, 2) + [Math]::Pow($bary[1] - 1.0/3, 2))
}
$angularMomentum = 0.0
for ($node = 0; $node -lt 3; ++$node) {
    $angularMomentum += ($reference[2*$node]-1.0/3)*$spinMomentum[2*$node+1] - ($reference[2*$node+1]-1.0/3)*$spinMomentum[2*$node]
}
$checks += Check 'triangle rotation energy versus area quadrature, J' $spinK $quadratureK
$checks += Check 'triangle polar inertia, kg m2' (2 * $spinK / ($omega * $omega)) (1.0/18)
$checks += Check 'triangle angular momentum, kg m2/s' $angularMomentum ($omega / 18)

$gamma = 0.2
$shearQ = @(0.0,0.0,1.0,0.0,$gamma,1.0)
$shear = Triangle $shearQ
$checks += Check 'simple shear energy, J' $shear.U 0.02
$expectedForce = @(0.2,0.2,0.0,-0.2,-0.2,0.0)
$maxForceDerivativeError = 0.0
$epsilon = 1e-6
for ($component = 0; $component -lt 6; ++$component) {
    $plus = [double[]]$shearQ.Clone(); $minus = [double[]]$shearQ.Clone()
    $plus[$component] += $epsilon; $minus[$component] -= $epsilon
    $finiteForce = -((Triangle $plus).U - (Triangle $minus).U) / (2 * $epsilon)
    $maxForceDerivativeError = [Math]::Max($maxForceDerivativeError, [Math]::Abs($finiteForce - $shear.force[$component]))
    $checks += Check "shear nodal force component $component, N" $shear.force[$component] $expectedForce[$component]
}
$checks += Check 'force versus independent energy differences max error, N' $maxForceDerivativeError 0 1e-8
$torque = 0.0
for ($node = 0; $node -lt 3; ++$node) { $torque += $shearQ[2*$node]*$shear.force[2*$node+1] - $shearQ[2*$node+1]*$shear.force[2*$node] }
$checks += Check 'shear internal torque, N m' $torque 0
$angle = 0.7; $cosine = [Math]::Cos($angle); $sine = [Math]::Sin($angle)
$rotatedQ = [double[]]::new(6)
for ($node = 0; $node -lt 3; ++$node) {
    $rotatedQ[2*$node] = $cosine*$shearQ[2*$node]-$sine*$shearQ[2*$node+1]+2
    $rotatedQ[2*$node+1] = $sine*$shearQ[2*$node]+$cosine*$shearQ[2*$node+1]-3
}
$rotated = Triangle $rotatedQ
$checks += Check 'strain energy invariant under rigid transform, J' $rotated.U $shear.U
$covarianceError = 0.0
for ($node = 0; $node -lt 3; ++$node) {
    $covarianceError = [Math]::Max($covarianceError, [Math]::Abs($rotated.force[2*$node]-($cosine*$shear.force[2*$node]-$sine*$shear.force[2*$node+1])))
    $covarianceError = [Math]::Max($covarianceError, [Math]::Abs($rotated.force[2*$node+1]-($sine*$shear.force[2*$node]+$cosine*$shear.force[2*$node+1])))
}
$checks += Check 'force covariance under rigid transform max error, N' $covarianceError 0
$restRotation = Law @($cosine; -$sine; $sine; $cosine)
$checks += Check 'stress-free rigid rotation energy density, J/m2' $restRotation.W 0

$alpha = 0.9
$compressed = Law @($alpha,0,0,$alpha)
$compressionWork = 0.0; $recoveryWork = 0.0
$panels = 10000; $deltaAlpha = ($alpha - 1) / $panels
for ($panel = 0; $panel -lt $panels; ++$panel) {
    $sample = 1 + ($panel + 0.5) * $deltaAlpha
    $compressionWork += (Law @($sample,0,0,$sample)).P[0] * $deltaAlpha
    $sampleReturn = $alpha - ($panel + 0.5) * $deltaAlpha
    $recoveryWork -= (Law @($sampleReturn,0,0,$sampleReturn)).P[0] * $deltaAlpha
}
$checks += Check 'compression work versus stored energy, J' $compressionWork (0.5 * $compressed.W) 1e-8
$checks += Check 'recovery work versus released energy, J' $recoveryWork (-0.5 * $compressed.W) 1e-8

$edgeLength = 2 * [Math]::Sin([Math]::PI / 128)
$ringMass = 0.1 * 128 * $edgeLength
$ringLineI = $ringMass * (2 + [Math]::Cos(2*[Math]::PI/128)) / 3
$checks += Check 'membrane lumped-minus-line inertia, kg m2' ($ringMass - $ringLineI) (128 * 0.1 * [Math]::Pow($edgeLength,3) / 6)
$ringTension = 0.1
$ringPressure = $ringTension / [Math]::Cos([Math]::PI/128)
$checks += Check 'Q5 nodal prestress force balance, N' ($ringPressure * [Math]::Sin(2*[Math]::PI/128) - 2*$ringTension*[Math]::Sin([Math]::PI/128)) 0
$checks += Check 'edge extension force, N' ((0.55-0.5)/0.5) 0.1
$checks += Check 'edge extension energy, J' ([Math]::Pow(0.55-0.5,2)/(2*0.5)) 0.0025

$effectiveMass = 0.025; $stiffness = 2.0; $dt = 0.00125
$y0 = 0.005; $v0 = 0.01
$omega2 = $stiffness / $effectiveMass; $factor = $omega2 * $dt * $dt / 4
$y1 = ((1-$factor)*$y0 + $dt*$v0)/(1+$factor)
$v1 = (-$omega2*$dt*$y0 + (1-$factor)*$v0)/(1+$factor)
$checks += Check 'midpoint linear mode energy change, J' (0.5*$effectiveMass*($v1*$v1-$v0*$v0)+0.5*$stiffness*($y1*$y1-$y0*$y0)) 0
$phaseCycles = 20 * ((2/($dt*[Math]::Sqrt($omega2)))*[Math]::Atan($dt*[Math]::Sqrt($omega2)/2)-1)
if ([Math]::Abs($phaseCycles) -gt 0.02) { throw 'Linear reference mode phase screen failed' }

# Dry contact references have one normal/tangent mode, each with effective mass 1 kg.
$normalImpulse = 0.1; $tangentImpulse = -0.05
$afterX = 0.2 + $tangentImpulse
$afterY = -0.1 + $normalImpulse
$impactLoss = -$normalImpulse*(-0.1+$afterY)/2 - $tangentImpulse*(0.2+$afterX)/2
$checks += Check 'inelastic impact outgoing normal speed, m/s' $afterY 0
$checks += Check 'Coulomb impact sliding impulse, kg m/s' $tangentImpulse (-0.5*$normalImpulse)
$checks += Check 'impact energy plus physical loss, J' (0.5*($afterX*$afterX+$afterY*$afterY-0.2*0.2-0.1*0.1)+$impactLoss) 0
$checks += Check 'impact paired angular impulse at x=0.4 m, kg m2/s' (0.4*$normalImpulse + 0.4*(-$normalImpulse)) 0
$slideFinal = 0.2 - 0.3*0.1
$slideDistance = 0.1*(0.2+$slideFinal)/2
$checks += Check 'stationary support sliding energy plus friction, J' (0.5*($slideFinal*$slideFinal-0.2*0.2)+0.3*$slideDistance) 0
$beltFinal = 0.2+0.3*0.1
$beltWork = 0.3*0.1*0.5
$beltLoss = 0.3*0.1*(0.5-(0.2+$beltFinal)/2)
$checks += Check 'moving support work minus kinetic gain and friction, J' (0.5*($beltFinal*$beltFinal-0.2*0.2)-$beltWork+$beltLoss) 0

$activeWork = -0.2*(0.45-0.5)
$fuelCost = $activeWork/(0.5*100)
$passiveChange = ([Math]::Pow(0.45-0.4,2)-[Math]::Pow(0.5-0.4,2))/(2*0.4)
$checks += Check 'active fiber mechanical work, J' $activeWork 0.01
$checks += Check 'active fuel energy split, J' (100*$fuelCost-$activeWork-(1-0.5)*100*$fuelCost) 0

# Endpoint-valid inversion is a negative case: F(s)=(1-2s)I collapses at s=1/2.
$midpointJ = [Math]::Pow(1-2*0.5,2)
if ($midpointJ -ge 0.25) { throw 'Swept inversion negative control missed' }
$checks += Check 'swept J hits proposed 0.25 bound at fraction 0.25' ([Math]::Pow(1-2*0.25,2)) 0.25
$inversionRejected = $false
try { $null = Law @(1,0,0,-1) } catch { $inversionRejected = $true }
if (-not $inversionRejected) { throw 'Negative determinant accepted' }
if ((0.49-0.5)/0.5 -ge 0) { throw 'Compressed membrane negative control missed' }

if ($Document) {
    $root = Split-Path $PSScriptRoot -Parent
    $path = Join-Path $root 'docs/MECHANICS_LAW.md'
    $doc = Get-Content -LiteralPath $path -Raw
    foreach ($term in @('F-mechanics-law','UNAPPROVED','C-mechanics','C-boundary','midpoint','Coulomb','inversion','prefix','fiber','mass','shear','compression','rotation','checkpoint','0.25 m')) {
        if (-not $doc.Contains($term)) { throw "Document missing $term" }
    }
    foreach ($link in [regex]::Matches($doc,'\]\(([^)#]+)(?:#[^)]*)?\)')) {
        $target = $link.Groups[1].Value
        if ($target -notmatch '^https?://' -and -not (Test-Path -LiteralPath (Join-Path (Split-Path $path -Parent) $target))) { throw "Broken local link $target" }
    }
    if ($doc -match '(?m)[\t ]+\r?$') { throw 'Trailing document whitespace' }
    'Document terms, local link targets and whitespace: PASS'
}
$checks | ConvertTo-Json -Depth 3
[pscustomobject]@{
    algebra_checks = $checks.Count; negative_controls = 3
    shear_force_difference_error_N = $maxForceDerivativeError
    compression_U_J = 0.5*$compressed.W; compression_P_N_m = $compressed.P[0]
    compression_work_error_J = $compressionWork-0.5*$compressed.W
    triangle_rotation_K_J = $spinK; membrane_lumped_I_kg_m2 = $ringMass
    membrane_line_I_kg_m2 = $ringLineI
    linear_mode_20_cycle_phase_error = $phaseCycles
    membrane_frequency_bound_rad_s = 2*[Math]::Sqrt(10)/$edgeLength
    impact_loss_J = $impactLoss; stationary_slide_loss_J = 0.3*$slideDistance
    moving_support_work_J = $beltWork; moving_support_friction_J = $beltLoss
    actuator_work_J = $activeWork; actuator_fuel_kg = $fuelCost; passive_fiber_U_change_J = $passiveChange
} | ConvertTo-Json
