param([switch]$Document, [switch]$RequireCompatible)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Reference compatibility audit only; no world advancement or fixture changes.
function Check([string]$Name, [double]$Actual, [double]$Expected, [double]$Tolerance = 1e-12) {
    $difference = [Math]::Abs($Actual-$Expected)
    if (-not [double]::IsFinite($Actual) -or $difference -gt $Tolerance) {
        throw "$Name failed: $Actual versus $Expected, difference $difference > $Tolerance"
    }
    [pscustomobject]@{name=$Name; actual=$Actual; expected=$Expected; tolerance=$Tolerance; error=$difference}
}
function Translation([double]$Time) { 0.5*[Math]::Pow([Math]::Sin([Math]::PI*$Time/2),2) }

$checks = @()
$piValue = [Math]::PI
$count = 128
$soundSquared = 10.0
$density = 1.0
$area = $count/2*[Math]::Sin(2*$piValue/$count)
$acceleration = $piValue*$piValue/4
$epsilon = 1e-4
$numericAcceleration = ((Translation $epsilon)-2*(Translation 0)+(Translation (-$epsilon)))/($epsilon*$epsilon)
$checks += Check 'Q3 analytic acceleration versus symmetric difference, m/s2' $numericAcceleration $acceleration 1e-7
$forceX = 0.0; $forceY = 0.0; $maxPressure = 0.0
for ($i = 0; $i -lt $count; ++$i) {
    $angle0 = 2*$piValue*$i/$count
    $angle1 = 2*$piValue*($i+1)/$count
    $x0 = [Math]::Cos($angle0); $y0 = [Math]::Sin($angle0)
    $x1 = [Math]::Cos($angle1); $y1 = [Math]::Sin($angle1)
    $edgePressure = -$density*$acceleration*($x0+$x1)/2
    $forceX += $edgePressure*($y1-$y0)
    $forceY -= $edgePressure*($x1-$x0)
    $maxPressure = [Math]::Max($maxPressure,[Math]::Abs(-$density*$acceleration*$x0))
}
$q3PressureRatio = $maxPressure/($density*$soundSquared)
$acousticRatio = (2/[Math]::Sqrt($soundSquared))/2
$checks += Check 'Q3 polygon pressure resultant x, N' $forceX (-$density*$area*$acceleration)
$checks += Check 'Q3 polygon pressure resultant y, N' $forceY 0
$checks += Check 'Q3 polygon maximum inertial pressure ratio' $q3PressureRatio 0.24674011002723395
$checks += Check 'Q2/Q3 acoustic crossing time over period' $acousticRatio 0.31622776601683794

$traceMoment = (2+[Math]::Cos(2*$piValue/$count))/6
$compressionAcceleration = -0.05*$piValue*$piValue
$q2PressureRatio = [Math]::Abs($compressionAcceleration)*(1-$traceMoment)/(2*$soundSquared)
$checks += Check 'Q2 actual-polygon startup inertial pressure ratio' $q2PressureRatio 0.0123419589891695
$ellipseSpeed = ($piValue*$piValue/2)*(1.25*1.25-0.8*0.8)/(1.25*1.25+0.8*0.8)*1.25
$ellipseMach = $ellipseSpeed/[Math]::Sqrt($soundSquared)
$checks += Check 'Q4 ellipse reference peak speed, m/s' $ellipseSpeed 2.5836294154384025
$checks += Check 'Q4 ellipse reference relative Mach' $ellipseMach 0.8170153582594749

$flowError = 2.0/(4*4); $velocityError = 1.0/(4*4)
$checks += Check 'four-cell passage relative flow error' $flowError 0.125
$checks += Check 'four-cell passage peak-normalized velocity error' $velocityError 0.0625
$checks += Check 'sixteen-cell passage relative flow error, not adopted' (2.0/(16*16)) 0.0078125
$checks += Check 'sixteen-cell passage peak-normalized velocity error, not adopted' (1.0/(16*16)) 0.00390625

$conditions = @(
    [pscustomobject]@{name='Q3 startup pressure variation'; actual=$q3PressureRatio; limit=0.01; compatible=($q3PressureRatio -le 0.01)}
    [pscustomobject]@{name='Q2 startup pressure variation'; actual=$q2PressureRatio; limit=0.01; compatible=($q2PressureRatio -le 0.01)}
    [pscustomobject]@{name='Q2/Q3 acoustic crossing time ratio'; actual=$acousticRatio; limit=0.1; compatible=($acousticRatio -le 0.1)}
    [pscustomobject]@{name='Q4 ellipse relative speed'; actual=$ellipseMach; limit=0.1; compatible=($ellipseMach -le 0.1)}
    [pscustomobject]@{name='base no-slip passage quality'; actual=@($flowError,$velocityError); limit=@(0.02,0.005); compatible=($flowError -le 0.02 -and $velocityError -le 0.005)}
)
$incompatibleCount = @($conditions | Where-Object { -not $_.compatible }).Count
if ($incompatibleCount -ne 5) { throw 'Reference incompatibility audit changed; review the source revisions and observations' }

if ($Document) {
    $root = Split-Path $PSScriptRoot -Parent
    $docPath = Join-Path $root 'docs/PASSIVE_SPEC.md'
    $doc = Get-Content -LiteralPath $docPath -Raw
    foreach ($term in @('F-passive-spec','Incomplete','T-reconcile','Q2','Q3','Q4','0.24674011002723395','0.0123419589891695','0.8170153582594749','12.5%','PROPOSED / UNAPPROVED','Required decision','Still unfinished','simulation-health')) {
        if (-not $doc.Contains($term)) { throw "Document missing $term" }
    }
    foreach ($link in [regex]::Matches($doc,'\]\(([^)#]+)(?:#[^)]*)?\)')) {
        $target = $link.Groups[1].Value
        if ($target -notmatch '^https?://' -and -not (Test-Path -LiteralPath (Join-Path (Split-Path $docPath -Parent) $target))) { throw "Broken local link $target" }
    }
    foreach ($file in @($docPath,$PSCommandPath)) {
        if ((Get-Content -LiteralPath $file -Raw) -match '(?m)[\t ]+\r?$') { throw "Trailing whitespace: $file" }
    }
    $expectedHashes = @{
        'docs/PHYSICAL_CONTRACT.md'='48FF446850E0DD31A0AE5E20F803923DB9F6E22A384A9532E7144E04F4CFDC07'
        'docs/MECHANICS_LAW.md'='EE2C5000A81D357CDE5F706D98F43A45C52429E543EE80333DF7964A6DF8145A'
        'docs/COMPARTMENT_LAW.md'='C05278878AE4A3DA7FFB1035662F2A4002BF0C8D098BC19CF80E41014AAF96B3'
        'docs/STATIONARY_FLOW_LAW.md'='BC2BE2E0568DFAECBE167FD5AF4C79E57A3B3957E07E65DA1BD55CB56F5DE53A'
        'docs/BOUNDARY_LAW.md'='55AF302183C77850586133D704BD0A6139B72CFD966C7853D13229A507E13EFF'
        'Substrate/Substrate.h'='FC24DB1F60D89A1955C5DFC24EB95A15DBA86A736C03134A17B43FEA34E4F6E5'
        'Substrate/Substrate.cpp'='F6CF93EB3AD740399016BD2AA4B4C0FB84E9C576F38338308CF69C6AA87A7FB6'
        'CMakeLists.txt'='39B2DFBA267E8F2CA1248896BCCD271B8A3987C81220C223762F4D558F8C4B73'
        'CMakePresets.json'='9A62F8904F286607B8018A288692116B022D90A5B4272DF80AF6D6ED07A2B053'
        'CMakeUserPresets.json'='028F0C6FC6FD14552E3ED52345E0563C5FB3286195FE4CA1BACE97E851AE2B15'
        'vcpkg.json'='8F525378EB575F2AE7F837C2B8795A36CC1369773B1644E52B6395673E8AF147'
    }
    foreach ($entry in $expectedHashes.GetEnumerator()) {
        if ((Get-FileHash -LiteralPath (Join-Path $root $entry.Key) -Algorithm SHA256).Hash -ne $entry.Value) { throw "Input/source/build changed: $($entry.Key)" }
    }
    'Document coverage, local links, whitespace and 11 preserved file identities: PASS'
}
$checks | ConvertTo-Json -Depth 4
[pscustomobject]@{
    arithmetic_checks=$checks.Count
    acceleration_difference_error_m_s2=$numericAcceleration-$acceleration
    polygon_force_error_N=$forceX+$density*$area*$acceleration
    conditions=$conditions
    freeze_ready=($incompatibleCount -eq 0)
    interpretation='Specification arithmetic only; configuration/model decision required before a compatible passive freeze.'
} | ConvertTo-Json -Depth 5
if ($RequireCompatible -and $incompatibleCount -gt 0) { exit 2 }
