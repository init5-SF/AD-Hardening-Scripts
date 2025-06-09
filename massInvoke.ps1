# Get the list of domain controllers in the current domain
$domainControllers = Get-ADDomainController -Filter *
Write-Host " "
foreach ($dc in $domainControllers) {
    $dcName = $dc.HostName
    Write-Host "Running command on $dcName"
    
    try {
        $output = Invoke-Command -ComputerName $dcName -ScriptBlock { whoami }
        Write-Host "Output of whoami on $dcName: $output "
    } catch {
        Write-Host "Error running whoami on $dcName: $_"
    }
}
