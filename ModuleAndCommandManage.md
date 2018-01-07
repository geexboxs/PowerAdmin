```powershell
# 获取<moduleName>下的所有command
Get-Module <moduleName> -ListAvailable | % { $_.ExportedCommands.Values }

# 获取<commandName>所在的module
Get-Command <commandName>

# 导入<moduleName>
Import-Module <moduleName>
```
