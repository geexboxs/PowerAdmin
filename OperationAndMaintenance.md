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
Set-PSReadlineOption -EditMode Emacs
Get-Module -ListAvailable | ? { `$_.ModuleType -eq "Script" } | Import-Module

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

## 安装sql express

**收费版本sqlserver安装时需要额外键入license信息,这里不涉及,不处理**
```powershell
# 安装包下载地址
$InstallerUrl = 'https://download.microsoft.com/download/6/4/A/64A05A0F-AB28-4583-BD7F-139D0495E473/SQLEXPR_x64_CHS.exe'
# 下载临时目录
$Destination = "$env:temp\SQLEXPR_x64_CHS.exe"
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
cd C:\Distros\Ubuntu
.\ubuntu.exe
```

