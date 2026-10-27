$wingetBinary = (Get-Command winget -All -CommandType Application -ErrorAction SilentlyContinue |
    Select-Object -First 1).Source

if ($null -eq $wingetBinary) {
    Write-Error "winget.exe was not found. Aborting."
    return
}

$ExcludedPackages = @(
    "SampleAppHere"
)

$upgradeOutput = & $wingetBinary upgrade --include-unknown

$header = $upgradeOutput | Where-Object { $_ -match '^\s*Name\s+Id\s+Version' } |
Select-Object -First 1

if (-not $header) {
    throw "Could not locate the Id column in winget output."
}

$idStart = $header.IndexOf('Id')
$versionStart = $header.IndexOf('Version', $idStart)

$packages = foreach ($line in $upgradeOutput) {
    if ($line.Length -le $versionStart -or
        $line -match '^\s*-{3,}' -or
        $line -eq $header) {
        continue
    }

    $id = $line.Substring($idStart, [Math]::Min(
            $versionStart - $idStart,
            $line.Length - $idStart
        )).Trim()

    if ($id -and $id -ne 'Id') {
        [PSCustomObject]@{ Id = $id }
    }
}

# Upgrade packages that are not excluded
foreach ($package in $packages) {
    if ($ExcludedPackages -contains $package.Id) {
        Write-Host "Skipping excluded package: $($package.Id)"
        continue
    }

    Write-Host "Upgrading: $($package.Id)"

    & $wingetBinary upgrade $package.Id --accept-package-agreements --accept-source-agreements --include-unknown --nowarn --silent
}
