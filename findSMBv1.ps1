$domainControllers = Get-ADDomainController -Filter * -ErrorAction SilentlyContinue
foreach ($dc in $domainControllers) {
    Write-Host "*** Checking: $($dc.Name) ..."

    try {
        $eventLogEntries = Get-WinEvent -ComputerName $dc.HostName -LogName "Microsoft-Windows-SMBServer/Audit" -FilterXPath "*[System[EventID=3000]]" -ErrorAction SilentlyContinue
        if ($eventLogEntries.Count -eq 0) {
            Write-Host "*** No SMBv1 events found on $($dc.Name)"
        } else {
            $ipAddresses = $eventLogEntries | ForEach-Object {
                $_.Properties[0].Value
            }

            Write-Host "*** IP Addresses using SMBv1 on $($dc.Name):"
            $ipAddresses | ForEach-Object {
                Write-Host "  $_"
            }
        }
    } catch {
        Write-Host "*** Error retrieving Event Log on $($dc.Name): $_"
    }

    Write-Host ""
}
