Param ([parameter(Mandatory=$false,Position=0)][String]$ComputerName = "localhost")

$Events = Get-WinEvent -ComputerName $ComputerName -FilterHashtable @{Logname='Security';Id=4768;}
$pattern = "\$"

foreach ($event in $Events) {   
    if (($event.Properties[0].Value -notmatch $pattern) -and ($event.Properties[7].Value -ne "17") -and ($event.Properties[7].Value -ne "18")) {
    $etype = $event.Properties[7].Value -replace "23", "RC4"
    $etype = $etype -replace "16", "3DES"
    $etype = $etype -replace "3", "DES"
    write-host "Username:" $event.Properties[0].Value
    write-host "E-Type:" $etype
    write-host "IP Address:" $event.Properties[9].Value.replace("::ffff:","")
    write-host ""
    Write-Host "------------------------------------------"
    write-host ""
    }
}