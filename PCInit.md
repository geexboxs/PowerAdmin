# 这是一些个人配置命令行界面的初始化配置

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco feature enable -n allowGlobalConfirmation
choco install ConEmu
Install-Module posh-git
Install-Module oh-my-posh
Install-Module -Name PSReadLine -Force -SkipPublisherCheck
if (!(Test-Path -Path $PROFILE )) { New-Item -Type File -Path $PROFILE -Force }
""> $PROFILE
@"
chcp 65001
Set-PSReadlineOption -EditMode Emacs
function which(`$name) { Get-Command `$name | Select-Object Definition }
function rmrf(`$item) { Remove-Item `$item -Recurse -Force }
function mkfile(`$file) { "" | Out-File `$file -Encoding ASCII }
Import-Module posh-git
Import-Module oh-my-posh
Set-Theme Paradox
"@ > $PROFILE
Import-Module posh-git
Import-Module oh-my-posh
Set-Theme paradox
git clone https://github.com/powerline/fonts.git
cd .\fonts\
.\install.ps1
cd ..
del .\fonts\

```