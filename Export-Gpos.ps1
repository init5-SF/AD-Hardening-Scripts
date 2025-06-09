<#

.SYNOPSIS
    This PowerShell script identifies and archives GPOs linked to the indicated OU,
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

.PARAMETER OU
    OU can be used to specify a OU other than the default value of OU=domain controllers.Use full DN minus the Domain DN.
 

.EXAMPLE
    <ScriptPath>.\Export-DcSecGpos.ps1

    Description
    -----------
    This command will backup the GPOs that are actively linked to the current domain's domain controllers with backup GPOs
    defaulting to a path of C:\GPOTMP The directory will be created if it does not already exist.

.EXAMPLE
    <ScriptPath>.\Export-DcSecGpos.ps1 -GpoPath C:\GpoBackups -OU "ou=test1,ou=test"

    Description
    -----------
    This command will backup the GPOs that are actively linked to the ou=test1,ou=test,dc=<domainame>,dc=<xxx> OU with backup GPOs
    going to a specified path of C:\GpoBackups. The directory specified will be created if it does not already exist. Directory
    names with spaces is not currently supported.
    

.NOTES
The result GPO directories can be used for both restoration as well as import in many other external tools, such as
PolicyAnalyzer.


#>


#function export-GPOs {
#[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False)]
     [string]$GpoPath = "C:\GPOTMP",
    [Parameter(Mandatory=$False)]
     [string]$OU = "OU=domain controllers"
)

Write-Host "*************************************************************************" -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "Loading Required PowerShell Modules                                      " -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "*************************************************************************" `n -ForegroundColor White -BackgroundColor DarkGreen

try
{
Write-Host "Adding Active Directory and Group Policy PowerShell Modules" -ForegroundColor Yellow
Import-Module ActiveDirectory
Import-Module GroupPolicy
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


$dcPDC = Get-ADDomainController -Service PrimaryDC -Discover -DomainName (Get-ADDomain).DnsRoot
$dmDN=(Get-ADDomain).DistinguishedName
$DN=$OU+","+$dmDN
$OUtochecklist=@()
$nextdn=$dn
do {
$dn=$nextdn
$OUtochecklist+=$DN
$nextdn=($DN.Split(",",2))[1]
}
while ($DN -ne $dmDN)


$totalistofGPOs=@()
foreach ($OUtocheck in $OUtochecklist){
    $AppliedGpos = Get-GPInheritance -target $OUtocheck | select -ExpandProperty GpoLinks
    $totalistofGPOs+= $AppliedGpos 
}
$totalistofGPOs =$totalistofGPOs | sort GPOID -Unique
Write-Host "*************************************************************************" -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "Starting GPO Backups to" $GpoPath -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "*************************************************************************" `n -ForegroundColor White -BackgroundColor DarkGreen

foreach ($Gpo in $totalistofGPOs) {
    if ($Gpo.Enabled) {
        Write-Host "Backing up $($Gpo.DisplayName)" -ForegroundColor Yellow
        Backup-GPO -Guid $Gpo.GpoId -Path $GpoPath -Comment "$($Gpo.DisplayName)" | Export-Csv -NoTypeInformation -Path $GpoPath\Export-DomainGpos.csv -Append
        Write-Host "$($Gpo.DisplayName) successfully backed up" `n -ForegroundColor Green
    }
}

Write-Host "*************************************************************************" -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "Completed GPO Backups to" $GpoPath -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "*************************************************************************" `n -ForegroundColor White -BackgroundColor DarkGreen

Write-Host "*************************************************************************" -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "GPO Backups are ready for PolicyAnalyzer import to perform analysis      " -ForegroundColor White -BackgroundColor DarkGreen
#}