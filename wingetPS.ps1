[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$ConfirmPreference  = 'None'
$ProgressPreference = 'SilentlyContinue'

$NuGetMinimumVersion = [version]'2.8.5.201'

$NuGetProvider = Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue |
    Where-Object {
        try {
            [version]$_.Version -ge $NuGetMinimumVersion
        }
        catch {
            $false
        }
    } |
    Select-Object -First 1

if (-not $NuGetProvider) {
    Install-PackageProvider `
        -Name NuGet `
        -MinimumVersion $NuGetMinimumVersion `
        -Scope AllUsers `
        -Force `
        -ForceBootstrap `
        -Confirm:$false `
        -ErrorAction Stop | Out-Null
}

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted


if (-not (Get-Module -ListAvailable -Name Microsoft.WinGet.Client)) {
    Install-Module `
        -Name Microsoft.WinGet.Client `
        -Repository PSGallery `
        -Scope AllUsers `
        -Force `
        -AllowClobber `
        -Confirm:$false `
        -ErrorAction Stop
}

Import-Module Microsoft.WinGet.Client -Force -ErrorAction Stop

$ExcludedPackages = @(
    "SampleAppHere"
)

Get-WinGetPackage |
    Where-Object {
        $_.IsUpdateAvailable -and
        $_.Id -notin $ExcludedPackages
    } |
    Update-WinGetPackage -Force -IncludeUnknown -Mode Silent
