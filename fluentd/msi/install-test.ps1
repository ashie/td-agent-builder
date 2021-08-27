$ErrorActionPreference = 'Stop'

$msi = ((Get-Item "C:\\fluentd\\td-agent\\msi\\repositories\\td-agent-*.msi") | Sort-Object -Descending { $_.LastWriteTime } | Select-Object -First 1).FullName
Write-Host "Installing ${msi} ..."

Start-Process msiexec -ArgumentList "/i", $msi, "/quiet" -Wait -NoNewWindow

$ENV:PATH="C:\\opt\\td-agent\\bin;" + $ENV:PATH

td-agent --version

$msi -Match "td-agent-([0-9\.]+)-.+\.msi"
$name = "Td-agent v" + $matches[1]
Write-Host "Uninstalling ...${name}"
Get-CimInstance -Class Win32_Product -Filter "Name='${name}'" | Invoke-CimMethod -MethodName Uninstall
$exitcode = $LASTEXITCODE
if ($exitcode -ne 0) {
    [Environment]::Exit($exitcode)
}
Write-Host "Succeeded to uninstall ${name}"

# td-agent.conf should not be removed
$conf = (Get-ChildItem -Path "c:\\opt" -Filter "td-agent.conf" -Recurse -Name)
if ($conf -ne "td-agent\etc\td-agent\td-agent.conf") {
  Write-Host "Failed to find td-agent.conf: <${conf}>"
  [Environment]::Exit(1)
}
Write-Host "Succeeded to find td-agent.conf"

# td-agent.log should not be removed
$conf = (Get-ChildItem -Path "c:\\opt" -Filter "td-agent.log" -Recurse -Name)
if ($conf -ne "td-agent\td-agent.log") {
  Write-Host "Failed to find td-agent.log: <${conf}>"
  [Environment]::Exit(1)
}
Write-Host "Succeeded to find td-agent.log"
