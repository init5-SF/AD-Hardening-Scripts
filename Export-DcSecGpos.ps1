<#

.SYNOPSIS
    This PowerShell script identifies and archives GPOs linked to the Domain Controllers OU,
    logging the results to a CSV file in the same directory.

.DESCRIPTION
    The script first initializes any required PowerShell modules, which currently includes the 
    ActiveDirectory and GroupPolicy modules. Based on the -GpoPath parameter value (or the defualt
    value of 'C:\GPOTMP' all link enabled GPOs will be backed up to that path. For each GPO that
    is backed up, an entry is made to the CSV in the same path detailing the following information:

    DisplayName              Represents the Display ("Friendly") Name of the GPO
    GpoId                    Represents the directory value of the GPO as it is stored in the SYSVOL
    Id                       Represents the directory value of the GPO as it is stored in the GpoPath location
    BackupDirectory          GpoPath location used for GPO backup
    CreationTime             Timestamp for when the GPO was backed up
    DomainName               Domain from which the backed up GPO was sourced from
    Comment                  Same as DisplayName (currently)

.PARAMETER GpoPath
    GpoPath can be used to specify a directory other than the default value of C:\GPOTMP
    At this time, a directory with spaces in its name is not supported

.EXAMPLE
    <ScriptPath>.\Export-DcSecGpos.ps1

    Description
    -----------
    This command will backup the GPOs that are actively linked to the current domain's domain controllers with backup GPOs
    defaulting to a path of C:\GPOTMP The directory will be created if it does not already exist.

.EXAMPLE
    <ScriptPath>.\Export-DcSecGpos.ps1 -GpoPath C:\GpoBackups

    Description
    -----------
    This command will backup the GPOs that are actively linked to the current domain's domain controllers with backup GPOs
    going to a specified path of C:\GpoBackups. The directory specified will be created if it does not already exist. Directory
    names with spaces is not currently supported.
    

.NOTES
The result GPO directories can be used for both restoration as well as import in many other external tools, such as
PolicyAnalyzer.


#>


[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False)]
     [string]$GpoPath = "C:\GPOTMP"
)

Write-Host "*************************************************************************" -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "Loading Required PowerShell Modules                                      " -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "*************************************************************************" `n -ForegroundColor White -BackgroundColor DarkGreen

try
{
Write-Host "Adding Active Directory and Group Policy PowerShell Modules" -ForegroundColor Yellow
Import-Module ActiveDirectory,GroupPolicy
Write-Host "Active Directory and Group Policy PowerShell Modules loaded" `n -ForegroundColor Green
}
catch
{
Write-Host "Unable to load Active Directory or Group Policy modules. Please ensure that the proper modules have been installed and are available" -ForegroundColor DarkMagenta
}

Write-Host "*************************************************************************" -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "Completed Loading Required PowerShell Modules                            " -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "*************************************************************************" `n -ForegroundColor White -BackgroundColor DarkGreen

if (!(Test-Path -Path $($GpoPath))) {
    Write-Host "*************************************************************************" -ForegroundColor Yellow -BackgroundColor Black
    Write-Host "Creating a GPO Backup directory as the path $($GpoPath) was not found    " -ForegroundColor Yellow -BackgroundColor Black
    New-Item -ItemType directory -Path $GpoPath | Out-Null
    Write-Host "$($GpoPath) was created successfully                                     " -ForegroundColor Yellow -BackgroundColor Black
    Write-Host "*************************************************************************" `n -ForegroundColor Yellow -BackgroundColor Black
} else {
    Write-Host "*************************************************************************" -ForegroundColor White -BackgroundColor DarkGreen
    write-host "$($GpoPath) already exists                                               " -ForegroundColor White -BackgroundColor DarkGreen
    Write-Host "*************************************************************************" `n -ForegroundColor White -BackgroundColor DarkGreen
}

$dmDN = (get-addomain).distinguishedname
$dcPDC = Get-ADDomainController -Service PrimaryDC -Discover -DomainName (Get-ADDomain).DnsRoot
$dcDN = "ou=domain controllers," + $dmDN
$AppliedDNGpos = Get-GPInheritance -target $dmDN | select -ExpandProperty GpoLinks
$AppliedDCGpos = Get-GPInheritance -target $dcDN | select -ExpandProperty GpoLinks

Write-Host "*************************************************************************" -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "Starting GPO Backups to" $GpoPath -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "*************************************************************************" `n -ForegroundColor White -BackgroundColor DarkGreen

foreach ($Gpo in $AppliedDNGpos) {
    if ($Gpo.Enabled) {
        Write-Host "Backing up $($Gpo.DisplayName)" -ForegroundColor Yellow
        Backup-GPO -Guid $Gpo.GpoId -Path $GpoPath -Comment "$($Gpo.DisplayName)" | Export-Csv -NoTypeInformation -Path $GpoPath\Export-DomainGpos.csv -Append
        Write-Host "$($Gpo.DisplayName) successfully backed up" `n -ForegroundColor Green
    }
}

foreach ($Gpo in $AppliedDCGpos) {
    if ($Gpo.Enabled) {
        Write-Host "Backing up $($Gpo.DisplayName)" -ForegroundColor Yellow
        Backup-GPO -Guid $Gpo.GpoId -Path $GpoPath -Comment "$($Gpo.DisplayName)" | Export-Csv -NoTypeInformation -Path $GpoPath\Export-DCGpos.csv -Append
        Write-Host "$($Gpo.DisplayName) successfully backed up" `n -ForegroundColor Green
    }
}

Write-Host "*************************************************************************" -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "Completed GPO Backups to" $GpoPath -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "*************************************************************************" `n -ForegroundColor White -BackgroundColor DarkGreen

Write-Host "*************************************************************************" -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "GPO Backups are ready for PolicyAnalyzer import to perform analysis      " -ForegroundColor White -BackgroundColor DarkGreen
Get-GPResultantSetOfPolicy -Computer $dcPDC -ReportType html -Path $GpoPath\DC-RSoP.html | Out-Null
Write-Host "GPO RSoP has been saved to $($GpoPath)\DC-RSoP.html   " -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "*************************************************************************" -ForegroundColor White -BackgroundColor DarkGreen
