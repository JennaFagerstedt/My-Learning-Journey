# svcmon.ps1 - checks critical services on nkdc01, restarts them if stopped and logs the status
# Scheduled in Task Scheduler every 15 minutes, runs as SYSTEM

$monitoredsvc = 'DNS', 'LanmanServer'
$Log     = 'C:\Scripts\svcmon.log'

foreach ($name in $monitoredsvc) {
    $status = (Get-Service -Name $name).Status
    if ($status -ne 'Running') { Start-Service -Name $name }
    "{0:yyyy-MM-dd HH:mm}  {1}  {2}" -f (Get-Date), $name, $status | Add-Content $Log
}
