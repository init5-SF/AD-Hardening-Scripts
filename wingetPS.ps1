Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ForceBootstrap -Confirm:$false
}

if (-not (Get-Module -ListAvailable -Name Microsoft.WinGet.Client)) {
    Install-Module -Name Microsoft.WinGet.Client -Scope AllUsers -Force -AllowClobber -Confirm:$false
}

Import-Module Microsoft.WinGet.Client -Force

$ExcludedPackages = @(
    "SampleAppHere"
)

Get-WinGetPackage | Where-Object { $_.IsUpdateAvailable -and $_.Id -notin $ExcludedPackages } | Update-WinGetPackage -Force -IncludeUnknown -Mode Silent
 
