param (
    [string]$Command = "whoami"  # Default to whoami if no command is specified
)

$domainControllers = Get-ADDomainController -Filter *
Write-Host " "
foreach ($dc in $domainControllers) {
    $dcName = $dc.HostName
    Write-Host "Running command on $dcName ..."
    try {
        $output = Invoke-Command -ComputerName $dcName -ScriptBlock { Invoke-Expression $args[0] } -ArgumentList $Command
        Write-Host "Command output on $dcName : $output "
    } catch {
        Write-Host "Error running command on $dcName : $_ "
    }
}
