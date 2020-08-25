# 注意:以下的部分脚本会有参数,所有参数会以**{参数}**标注,请勿直接复制粘贴

### 虚拟机初始化脚本

```powershell
Set-ExecutionPolicy Bypass -Scope CurrentUser -Force;
# 载入自定义profile
# 创建profile目录
mkdir $PROFILE
del $PROFILE
@"
###########################################################
#
# custom profile
#
###########################################################
chcp 65001
Set-PSReadlineOption -EditMode Emacs

# inline functions, aliases and variables
function which(`$name) { Get-Command `$name | Select-Object Definition }
function rmrf(`$item) { Remove-Item `$item -Recurse -Force }
function mkfile(`$file) { "" | Out-File `$file -Encoding ASCII }

mkdir "`$env:UserProfile\bin" -ErrorAction SilentlyContinue
`$bin = "`$env:UserProfile\bin"
"@>$PROFILE

# 安装iis
Add-WindowsFeature web-server
# 安装iis承载核心
Install-WindowsFeature web-whc,web-common-http,web-mgmt-console,Web-Asp-Net45,Web-websockets
# 安装iis的web sokcet支持
Install-WindowsFeature Web-websockets
# 安装web管理服务,配置允许远程访问并自动启动服务
Add-WindowsFeature Web-Mgmt-Service
Set-Service wmsvc -startuptype "auto"
Set-ItemProperty -Path  HKLM:\SOFTWARE\Microsoft\WebManagement\Server -Name EnableRemoteManagement  -Value 1
Start-Service wmsvc
# 允许远程执行shell脚本
Enable-PSRemoting -force
# 配置远程管理
winrm quickconfig
y
# 配置允许所有host访问(可能有安全隐患,建议统一配置到跳板机上)
winrm s winrm/config/client '@{TrustedHosts="*"}'
# 导入iis相关命令及iis虚拟驱动器
Import-Module WebAdministration
# 我想大家应该不需要Default Web Site
Remove-Website -Name "Default Web Site"
# 允许网络访问并安装choco
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
# choco静默安装
choco feature enable -n allowGlobalConfirmation
# 安装git, 很多东西托管在github上, 需要git安装
choco install git
# choco安装.net core运行时
choco install dotnetcore-windowshosting
# choco安装webdeploy
choco install webdeploy
# choco安装shadowsocks以备不时之需
choco install shadowsocks
# choco安装listary,搜文件还是很有用的
choco install listary
# choco安装vscode,notepad的编码问题可以搞死你
choco install visualstudiocode
# choco安装dependencywalker,服务器出现兼容性问题的时候可以用来检查dll
choco install dependencywalker
# 重启服务器,血泪教训
Restart-Computer
# over
```

### 短期运维脚本

```powershell
# 以下部分脚本可复用

# 导入iis相关命令及iis虚拟驱动器
Import-Module WebAdministration
# 新建web站点"xxxxxx",虚拟路径为"yyyyyy",删除默认配置的绑定
mkdir **{yyyyyy}** -ErrorAction SilentlyContinue
New-Website -Name **{xxxxx}** -PhysicalPath **{yyyyyy}**
Remove-WebBinding -HostHeader ""
# 新建对"xxxxxx"站点的绑定,绑定域名为"yyy.com",可通过[-Port <UInt32> ]进一步指定端口号
New-WebBinding -Name **{xxxxxx}** -HostHeader **{yyy.com}**
# 至此服务器基本部署完毕, 之后就可以直接用web deploy进行发布了
```

```powershell
# 跳转iis驱动器以进行运维
cd IIS:
```

```powershell
# 以yyy的身份远程登录xxx的ps管理
Enter-PSSession **{xxx}** -Credential **{yyy}**
```


# 可选初始化功能

## 搭建shadowsocks server

### windows
```powershell
# 安装python
choco install python
# 切换新的运行环境使用pips安装shadowsocks(刷新系统环境变量)
start powershell -ArgumentList "pip install shadowsocks"
# clone openssl必须的dll
git clone https://github.com/snys98/CloudFolder.git
cd .\CloudFolder\ 
# 注册openssl必须的dll并移除临时目录
copy libeay32.dll $env:windir\System32\libeay32.dll
regsvr32.exe /s $env:windir\System32\libeay32.dll
cd ..
del .\CloudFolder\ -Force -Recurse
mkdir C:\ShadowsocksServer\ -ErrorAction SilentlyContinue
cd C:\ShadowsocksServer\

# 生成配置文件,处理编码问题
'{"server": "0.0.0.0","server_port": 8888,"password": "**{your_password}**","timeout": 1000,"method": "aes-256-cfb","dast_open": false}'|Out-File "config.json" -Encoding ascii
# 添加启动项
mkdir C:\Windows\System32\GroupPolicy\Machine\Scripts\Startup -ErrorAction SilentlyContinue
"ssserver -c C:\ShadowsocksServer\config.json">C:\Windows\System32\GroupPolicy\Machine\Scripts\Startup\shadowsocks.ps1
# 本次启动
start powershell -ArgumentList "ssserver -c C:\ShadowsocksServer\config.json"
```

### linux
```shell
apt upgrade
# 安装python
apt install python-pip -y
# 没有setuptools会导致ss安装失败
pip install setuptools
# 安装最新版本的ss, 旧版和1.02以后版本的openssl存在兼容性问题
pip install -U git+https://github.com/shadowsocks/shadowsocks.git@master
# 启动ssserver到3389端口
nohup ssserver -p 3389 -k **{password}** -m aes-256-cfb --user nobody -d start &
# 安装flask, 挂载一个用于检测ip是否可以正常访问的测试站点(同时也是防止cc防火墙检测)
pip install flask
cat>~/hello.py<<EOF
from flask import Flask, redirect
app = Flask(__name__)
@app.route('/')
def index():
    return redirect("http://www.baidu.com")
if __name__ == '__main__':
    app.run(host="0.0.0.0", port=80)
EOF
# 自启动ssserver和测试站点
cat>/etc/profile.d/startup.sh<<EOF
nohup ssserver -p 3389 -k **{password}** -m aes-256-cfb --user nobody -d start &
nohup python ~/hello.py &
EOF
# 运行测试站点
nohup python ~/hello.py &

```

## 安装sql express

**收费版本sqlserver安装时需要额外键入license信息,这里不涉及,不处理**
```powershell
# 安装包下载地址
$InstallerUrl = 'https://download.microsoft.com/download/E/F/2/EF23C21D-7860-4F05-88CE-39AA114B014B/SQLEXPR_x64_ENU.exe'
# 下载临时目录
$Destination = "$env:temp\SQLEXPR_x64_ENU.exe"
# 执行下载
Invoke-WebRequest -Uri $InstallerUrl -OutFile $Destination -UseBasicParsing
# 执行安装 /q:静默 /action=Install:操作为安装 /FEATURES=SQLEngine:安装数据库引擎 /INSTANCENAME=MSSQLSERVER:数据库实例名称为'MSSQLSERVER' /TCPENABLED=1:允许tcp远程连接 /IACCEPTSQLSERVERLICENSETERMS:同意安装前须知 /SECURITYMODE=SQL:安全认证模式为'sql用户认证' /SAPWD=xxxxxx:sa用户密码为'xxxxxx'
&$Destination /q /ACTION=Install /FEATURES=SQLEngine /INSTANCENAME=MSSQLSERVER /TCPENABLED=1 /IACCEPTSQLSERVERLICENSETERMS  /SECURITYMODE=SQL /SAPWD=**{xxxxxx}**
```

## 安装linux子系统

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu-1604 -OutFile ~/Ubuntu.zip -UseBasicParsing
Expand-Archive ~/Ubuntu.zip ~/Ubuntu
cd ~/Ubuntu
.\ubuntu.exe
```

## 安装ElasticSearch with Kibana

```powershell
# 默认安装到~目录
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
nssm start kibana
nssm set kibana start SERVICE_AUTO_START
nssm start elasticsearch
nssm set elasticsearch start SERVICE_AUTO_START
# 安装es,完成后可通过访问http://localhost:9200/?pretty以检测es运行状态
```

## 安装Consul

```powershell
# 安装consul,安装后的consul默认以client模式运行,如果是需要以server模式运行,需要编辑consul的nssm服务
choco install consul
```

## 配置git alias
```powershell
git config --global alias.cm commit
git config --global alias.co checkout
git config --global alias.ac '!git add -A && git commit'
git config --global alias.st 'status -sb'
git config --global alias.tags 'tag -l'
git config --global alias.branches 'branch -a'
git config --global alias.remotes 'remote -v'
git config --global alias.logcolor "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --"
```
