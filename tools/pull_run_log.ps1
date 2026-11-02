<#
.SYNOPSIS
Pulls the run log (one line per finished round, written by RunLog) from a connected Quest and
prints actual against expected minutes per mission and difficulty.

.DESCRIPTION
The game appends to user://run_log.csv in its private storage and, on Android, keeps a copy in
its external files directory (Android/data/<package>/files/run_log.csv).
  - A debug build is readable with `adb exec-out run-as`, which reads the private file.
  - A release build refuses run-as, so the copy is pulled with `adb pull` instead. No root needed.
-Source auto tries the private file first and falls back to the copy.

The pulled file is saved under reports/run_log/ (gitignored). With -CsvPath it reads a file you
already have and needs no headset.

Only victories count toward the times: a defeat ends whenever life force runs out, so it says
nothing about how long a seal takes. A mission is flagged when its median victory falls outside
the card range the game showed for it. See development/Difficulty_Tuning.md for what to do next.

.EXAMPLE
powershell -ExecutionPolicy Bypass -File tools/pull_run_log.ps1
.EXAMPLE
powershell -ExecutionPolicy Bypass -File tools/pull_run_log.ps1 -CsvPath reports/run_log/run_log-20261102-210500.csv -SinceVersion 4
#>
param(
    [ValidateSet('auto', 'private', 'external')]
    [string]$Source = 'auto',
    [string]$CsvPath = '',
    [int]$SinceVersion = 0,
    [string]$Package = 'com.phantomfury.resonancerising'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot

function Get-Adb {
    $candidates = @("$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe")
    if ($env:ANDROID_HOME) { $candidates += (Join-Path $env:ANDROID_HOME 'platform-tools\adb.exe') }
    if ($env:ANDROID_SDK_ROOT) { $candidates += (Join-Path $env:ANDROID_SDK_ROOT 'platform-tools\adb.exe') }
    foreach ($candidate in $candidates) { if (Test-Path $candidate) { return $candidate } }
    $onPath = Get-Command adb -ErrorAction SilentlyContinue
    if ($onPath) { return $onPath.Source }
    throw 'adb not found. Install Android platform-tools or set ANDROID_HOME.'
}

# Runs adb and returns its output lines and exit code without letting stderr stop the script.
function Invoke-Adb([string]$adb, [string[]]$arguments) {
    $strict = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { $output = & $adb @arguments 2>&1 } finally { $ErrorActionPreference = $strict }
    return @{ Lines = @($output | ForEach-Object { "$_" }); Code = $LASTEXITCODE }
}

function Save-Lines([string[]]$lines, [string]$path) {
    $text = ($lines -join "`n").TrimEnd() + "`n"
    [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))
}

function Pull-RunLog {
    $adb = Get-Adb
    $devices = (Invoke-Adb $adb @('devices')).Lines
    if (-not ($devices -match "\sdevice$")) {
        throw 'No authorized Quest found. Plug it in, put it on, and approve USB debugging.'
    }
    $outDir = Join-Path $projectRoot 'reports\run_log'
    New-Item $outDir -ItemType Directory -Force | Out-Null
    $outFile = Join-Path $outDir ("run_log-{0}.csv" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))

    if ($Source -ne 'external') {
        $read = Invoke-Adb $adb @('exec-out', 'run-as', $Package, 'cat', 'files/run_log.csv')
        if ($read.Code -eq 0 -and $read.Lines.Count -gt 0 -and $read.Lines[0] -like 'date,mission_id,*') {
            Save-Lines $read.Lines $outFile
            Write-Host "Pulled the private log with run-as (debug build): $outFile"
            return $outFile
        }
        if ($Source -eq 'private') {
            throw "run-as could not read the private log: $($read.Lines -join ' ') (a release build refuses run-as; try -Source external)"
        }
        Write-Host 'run-as could not read the private log (release build, or no rounds yet); trying the external copy.'
    }
    $remote = "/sdcard/Android/data/$Package/files/run_log.csv"
    $pull = Invoke-Adb $adb @('pull', $remote, $outFile)
    if ($pull.Code -ne 0 -or -not (Test-Path $outFile)) {
        throw "No run log on the headset at $remote. Finish at least one round first. adb said: $($pull.Lines -join ' ')"
    }
    Write-Host "Pulled the external copy: $outFile"
    return $outFile
}

function Get-Median([double[]]$values) {
    $sorted = @($values | Sort-Object)
    $count = $sorted.Count
    if ($count -eq 0) { return $null }
    if ($count % 2 -eq 1) { return $sorted[($count - 1) / 2] }
    return ($sorted[$count / 2 - 1] + $sorted[$count / 2]) / 2.0
}

function Get-MissionKey($row) {
    if ($row.kind -and $row.kind -ne 'operation') { return "world:$($row.kind)" }
    return $row.mission_id
}

if ($CsvPath) {
    if (-not (Test-Path $CsvPath)) { throw "No file at $CsvPath" }
    $file = (Resolve-Path $CsvPath).Path
} else {
    $file = Pull-RunLog
}

$rows = @(Import-Csv $file | Where-Object { [int]$_.version_code -ge $SinceVersion })
if ($rows.Count -eq 0) {
    Write-Host 'The log has no rounds to read (or none at or after -SinceVersion).'
    return
}
$tierOrder = @{ 'assist' = 0; 'standard' = 1; 'operator' = 2; 'full_resonance' = 3 }
$groups = $rows | Group-Object { "{0}|{1}" -f (Get-MissionKey $_), $_.tier }
$table = foreach ($group in $groups) {
    $key, $tier = $group.Name -split '\|'
    $wins = @($group.Group | Where-Object { $_.outcome -eq 'victory' })
    $losses = @($group.Group | Where-Object { $_.outcome -ne 'victory' }).Count
    # The card the game showed most recently for this mission and tier.
    $latest = $group.Group | Sort-Object { [int]$_.version_code }, date | Select-Object -Last 1
    $low = $null; $high = $null
    if ($latest.expected_min -ne '') { $low = [int]$latest.expected_min; $high = [int]$latest.expected_max }
    $minutes = @($wins | ForEach-Object { [double]$_.elapsed_seconds / 60.0 })
    $median = Get-Median $minutes
    $flag = ''
    if ($null -ne $median -and $null -ne $low) {
        # The card speaks whole minutes, as the audit does.
        $whole = [math]::Round($median, [System.MidpointRounding]::AwayFromZero)
        if ($whole -lt $low) { $flag = 'UNDER CARD' } elseif ($whole -gt $high) { $flag = 'OVER CARD' }
    }
    $breaks = @($wins | Where-Object { $_.boss -eq 'breaks' }).Count
    # Rift damage per kill and seconds per kill, the estimator's two constants (WorldMap.KILL_DAMAGE,
    # and KILL_CADENCE_SECONDS where the feed outruns the player). A hold's team and a boss's anchor
    # take health no kill paid for, so those rows leave them out.
    $calibrate = @($wins | Where-Object { $_.kind -ne 'hold' -and $_.boss -ne 'breaks' -and [int]$_.phantoms_resolved -gt 0 -and $_.rift_health })
    $damage = Get-Median @($calibrate | ForEach-Object { [double]$_.rift_health / [int]$_.phantoms_resolved })
    $pace = Get-Median @($calibrate | ForEach-Object { [double]$_.elapsed_seconds / [int]$_.phantoms_resolved })
    [pscustomobject]@{
        Mission  = $key
        Tier     = $tier
        Wins     = $wins.Count
        Losses   = $losses
        Median   = if ($null -ne $median) { '{0:N1}' -f $median } else { '-' }
        Fastest  = if ($minutes.Count) { '{0:N1}' -f ($minutes | Measure-Object -Minimum).Minimum } else { '-' }
        Slowest  = if ($minutes.Count) { '{0:N1}' -f ($minutes | Measure-Object -Maximum).Maximum } else { '-' }
        Card     = if ($null -ne $low) { "$low-$high" } else { '-' }
        Flag     = $flag
        Boss     = if ($breaks) { "$breaks broke" } else { '' }
        'Dmg/kill' = if ($null -ne $damage) { '{0:N1}' -f $damage } else { '-' }
        's/kill'   = if ($null -ne $pace) { '{0:N2}' -f $pace } else { '-' }
        _Order   = $tierOrder[$tier]
        _Median  = $median
    }
}
$table = @($table | Sort-Object Mission, _Order)
Write-Host ''
Write-Host "Actual against expected minutes, victories only ($($rows.Count) rounds in $file)"
$table | Format-Table Mission, Tier, Wins, Losses, Median, Fastest, Slowest, Card, Flag, Boss, 'Dmg/kill', 's/kill' -AutoSize | Out-Host

# Each tier's median against Standard's, per mission: Assist and Operator should sit within a few
# percent, Full Resonance about a tenth longer (Tests/difficulty_audit.gd holds the paper version).
$ratios = foreach ($mission in ($table | Group-Object Mission)) {
    $standard = $mission.Group | Where-Object { $_.Tier -eq 'standard' -and $null -ne $_._Median }
    if (-not $standard) { continue }
    foreach ($entry in $mission.Group) {
        if ($entry.Tier -eq 'standard' -or $null -eq $entry._Median) { continue }
        $target = if ($entry.Tier -eq 'full_resonance') { 0.10 } else { 0.0 }
        $drift = $entry._Median / $standard._Median - 1.0
        [pscustomobject]@{
            Mission  = $entry.Mission
            Tier     = $entry.Tier
            'vs Std' = '{0:+0;-0;0}%' -f ($drift * 100)
            Target   = '{0:+0;-0;0}%' -f ($target * 100)
            Note     = if ([math]::Abs($drift - $target) -gt 0.05) { 'OFF TARGET' } else { '' }
        }
    }
}
if ($ratios) {
    Write-Host 'Each tier against Standard (medians; needs victories at Standard and the tier)'
    $ratios | Format-Table -AutoSize | Out-Host
}
$flagged = @($table | Where-Object { $_.Flag })
if ($flagged.Count) {
    Write-Host ("{0} mission and tier pairs ran outside their card. See development/Difficulty_Tuning.md." -f $flagged.Count)
} else {
    Write-Host 'Every median victory is on its card.'
}
