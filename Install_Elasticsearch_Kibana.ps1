Set-Location ~
choco install 7zip -y
choco install nssm -y
function Test-Administrator {
    [OutputType([bool])]
    param()
    process {
        [Security.Principal.WindowsPrincipal]$user = [Security.Principal.WindowsIdentity]::GetCurrent();
        return $user.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator);
    }
}
if (-not (Test-Administrator)) {
    Write-Error "This script must be executed as Administrator."
    break
}
  
$ProgressPreference = 'SilentlyContinue'
Write-Output "Downloading ElasicSearch"
Invoke-WebRequest  -Uri https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.9.0-windows-x86_64.zip -OutFile Elasticsearch.zip
Write-Output "Downloading Kibana"
Invoke-WebRequest  -Uri https://artifacts.elastic.co/downloads/kibana/kibana-7.9.0-windows-x86_64.zip -OutFile Kibana.zip
  
Write-Output "#########################################################################"
Write-Output "Downloads completed, decompressing"
7z x Elasticsearch.zip -y -r -oElasticsearch
7z x Kibana.zip -y -r -oKibana
  
Write-Output "Cleaning up a bit"
Remove-Item .\Elasticsearch.zip
Remove-Item .\Kibana.zip
  
$CurrentDir = Get-Location
# Write-Output "Creating shortcuts on the Desktop.`n`n Happy Hunting!"
  
# $TargetFile = "$CurrentDir\Elasticsearch\elasticsearch-7.9.0\bin\elasticsearch.bat"
# $ShortcutFile = "$env:USERPROFILE\Desktop\Elasticsearch.lnk"
# $WScriptShell = New-Object -ComObject WScript.Shell
# $Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
# $Shortcut.TargetPath = $TargetFile
# $Shortcut.Save()
  
# $TargetFile = "$CurrentDir\Kibana\kibana-7.9.0-windows-x86_64\bin\kibana.bat"
# $ShortcutFile = "$env:USERPROFILE\Desktop\Kibana.lnk"
# $WScriptShell = New-Object -ComObject WScript.Shell
# $Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
# $Shortcut.TargetPath = $TargetFile
# $Shortcut.Save()
# Write-Output "`nNote: If you move the directory you will break the shortcuts"
  
$CurrentDir = Get-Location
Write-Output "######################################################`nDeployed`n######################################################"
Write-Output "######################################################`nStarting Stack`n######################################################"
  
nssm install elasticsearch $CurrentDir\Elasticsearch\elasticsearch-7.9.0\bin\elasticsearch.bat
nssm install kibana $CurrentDir\Kibana\kibana-7.9.0-windows-x86_64\bin\kibana.bat 
