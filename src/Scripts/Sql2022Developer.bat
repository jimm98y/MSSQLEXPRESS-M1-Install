<# :
::::::::::::::::::::::::::::::::::::::::::::
:: Elevate.cmd - Version 4
:: Automatically check & get admin rights
:: see "https://stackoverflow.com/a/12264592/1016343" for description
::::::::::::::::::::::::::::::::::::::::::::
 @echo off
 CLS
 ECHO.
 ECHO =============================
 ECHO Running Admin shell
 ECHO =============================

:init
 setlocal DisableDelayedExpansion
 set cmdInvoke=1
 set winSysFolder=System32
 set "batchPath=%~dpnx0"
 rem this works also from cmd shell, other than %~0
 for %%k in (%0) do set batchName=%%~nk
 set "vbsGetPrivileges=%temp%\OEgetPriv_%batchName%.vbs"
 setlocal EnableDelayedExpansion

:checkPrivileges
  NET FILE 1>NUL 2>NUL
  if '%errorlevel%' == '0' ( goto gotPrivileges ) else ( goto getPrivileges )

:getPrivileges
  if '%1'=='ELEV' (echo ELEV & shift /1 & goto gotPrivileges)
  ECHO.
  ECHO **************************************
  ECHO Invoking UAC for Privilege Escalation
  ECHO **************************************

  ECHO Set UAC = CreateObject^("Shell.Application"^) > "%vbsGetPrivileges%"
  ECHO args = "ELEV " >> "%vbsGetPrivileges%"
  ECHO For Each strArg in WScript.Arguments >> "%vbsGetPrivileges%"
  ECHO args = args ^& strArg ^& " "  >> "%vbsGetPrivileges%"
  ECHO Next >> "%vbsGetPrivileges%"
  
  if '%cmdInvoke%'=='1' goto InvokeCmd 

  ECHO UAC.ShellExecute "!batchPath!", args, "", "runas", 1 >> "%vbsGetPrivileges%"
  goto ExecElevation

:InvokeCmd
  ECHO args = "/c """ + "!batchPath!" + """ " + args >> "%vbsGetPrivileges%"
  ECHO UAC.ShellExecute "%SystemRoot%\%winSysFolder%\cmd.exe", args, "", "runas", 1 >> "%vbsGetPrivileges%"

:ExecElevation
 "%SystemRoot%\%winSysFolder%\WScript.exe" "%vbsGetPrivileges%" %*
 exit /B

:gotPrivileges
 setlocal & cd /d %~dp0
 if '%1'=='ELEV' (del "%vbsGetPrivileges%" 1>nul 2>nul  &  shift /1)

 ::::::::::::::::::::::::::::
 ::START
 ::::::::::::::::::::::::::::
 powershell /nologo /noprofile /command ^
  "&{[ScriptBlock]::Create((cat """%~f0""") -join [Char[]]10).Invoke(@(&{$args}%*))}"
 exit /b
#>

$SqlInstance = "SQLDEVELOPER"
$SqlFeatures = "SQLENGINE"
$sqlInstallArgs = "/qs /ACTION=Install /FEATURES=${SqlFeatures} /INSTANCENAME=${SqlInstance} /SQLSYSADMINACCOUNTS=BUILTIN\Administrators /IACCEPTSQLSERVERLICENSETERMS=true /UPDATEENABLED=false /USEMICROSOFTUPDATE=false /ENU"
$sqlInstallerPath = "./SQLServer2022-DEV-x64-ENU.exe"
$sqlBoxInstallerPath = "./SQLServer2022-DEV-x64-ENU.box"
$sqlDownloadUrl = "https://download.microsoft.com/download/3/8/d/38de7036-2433-4207-8eae-06e247e17b25/SQLServer2022-DEV-x64-ENU.exe"
$sqlBoxDownloadUrl = "https://download.microsoft.com/download/3/8/d/38de7036-2433-4207-8eae-06e247e17b25/SQLServer2022-DEV-x64-ENU.box"

If(-not(Test-Path "$sqlInstallerPath" -PathType Leaf)) {
  $ProgressPreference = 'SilentlyContinue'
  Invoke-WebRequest -Uri "$sqlDownloadUrl" -OutFile "$sqlInstallerPath"
  $ProgressPreference = 'Continue'
}
If(-not(Test-Path "$sqlBoxInstallerPath" -PathType Leaf)) {
  $ProgressPreference = 'SilentlyContinue'
  Invoke-WebRequest -Uri "$sqlBoxDownloadUrl" -OutFile "$sqlBoxInstallerPath"
  $ProgressPreference = 'Continue'
}
Start-Process -FilePath "sc.exe" -ArgumentList "delete RsFx0600"
Start-Process -FilePath "sc.exe" -ArgumentList "delete RsFx0700"
Start-Process -FilePath "$sqlInstallerPath" -ArgumentList "$sqlInstallArgs" -Wait
Start-Process -FilePath "sc.exe" -ArgumentList "create RsFx0700 binPath= $Env:WinDir\System32\Drivers\RsFx0700.sys"

# Reg2CI (c) 2022 by Roger Zander
if((Test-Path -LiteralPath "HKLM:\SYSTEM\ControlSet001\Services\RsFx0700") -ne $true) {  New-Item "HKLM:\SYSTEM\ControlSet001\Services\RsFx0700" -force -ea SilentlyContinue };
if((Test-Path -LiteralPath "HKLM:\SYSTEM\ControlSet001\Services\RsFx0700\DeviceSecurity") -ne $true) {  New-Item "HKLM:\SYSTEM\ControlSet001\Services\RsFx0700\DeviceSecurity" -force -ea SilentlyContinue };
if((Test-Path -LiteralPath "HKLM:\SYSTEM\ControlSet001\Services\RsFx0700\Instances") -ne $true) {  New-Item "HKLM:\SYSTEM\ControlSet001\Services\RsFx0700\Instances" -force -ea SilentlyContinue };
if((Test-Path -LiteralPath "HKLM:\SYSTEM\ControlSet001\Services\RsFx0700\Instances\RsFx0700 MiniFilter Instance") -ne $true) {  New-Item "HKLM:\SYSTEM\ControlSet001\Services\RsFx0700\Instances\RsFx0700 MiniFilter Instance" -force -ea SilentlyContinue };
if((Test-Path -LiteralPath "HKLM:\SYSTEM\ControlSet001\Services\RsFx0700\InstancesShares") -ne $true) {  New-Item "HKLM:\SYSTEM\ControlSet001\Services\RsFx0700\InstancesShares" -force -ea SilentlyContinue };
if((Test-Path -LiteralPath "HKLM:\SYSTEM\ControlSet001\Services\RsFx0700\NetworkProvider") -ne $true) {  New-Item "HKLM:\SYSTEM\ControlSet001\Services\RsFx0700\NetworkProvider" -force -ea SilentlyContinue };
if((Test-Path -LiteralPath "HKLM:\SYSTEM\ControlSet001\Services\RsFx0700\Parameters") -ne $true) {  New-Item "HKLM:\SYSTEM\ControlSet001\Services\RsFx0700\Parameters" -force -ea SilentlyContinue };
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0700' -Name 'Type' -Value 2 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0700' -Name 'Start' -Value 1 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0700' -Name 'ErrorControl' -Value 1 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0700' -Name 'Tag' -Value 2 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0700' -Name 'ImagePath' -Value 'system32\DRIVERS\RsFx0700.sys' -PropertyType ExpandString -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0700' -Name 'DisplayName' -Value 'RsFx0700 Driver' -PropertyType String -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0700' -Name 'Group' -Value 'FsFilter Bottom' -PropertyType String -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0700' -Name 'DependOnService' -Value @("FltMgr") -PropertyType MultiString -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0700' -Name 'Description' -Value 'RsFx 0700 driver allows Win32 user-mode applications/services to own and manage Win32 namespaces of the UNC format. If this service is stopped, these functions will not be available. If this service is disabled, any services that explicitly depend on it will fail to start.' -PropertyType String -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0700\DeviceSecurity' -Name 'Security' -Value ([byte[]](0x01,0x00,0x14,0x80,0x8c,0x00,0x00,0x00,0x98,0x00,0x00,0x00,0x14,0x00,0x00,0x00,0x30,0x00,0x00,0x00,0x02,0x00,0x1c,0x00,0x01,0x00,0x00,0x00,0x02,0x80,0x14,0x00,0xff,0x01,0x1f,0x00,0x01,0x01,0x00,0x00,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x00,0x02,0x00,0x5c,0x00,0x02,0x00,0x00,0x00,0x00,0x00,0x14,0x00,0xff,0x01,0x1f,0x00,0x01,0x01,0x00,0x00,0x00,0x00,0x00,0x05,0x12,0x00,0x00,0x00,0x00,0x00,0x18,0x00,0xff,0x01,0x1f,0x00,0x01,0x02,0x00,0x00,0x00,0x00,0x00,0x05,0x20,0x00,0x00,0x00,0x20,0x02,0x00,0x00,0x46,0x00,0x78,0x00,0x5c,0x00,0x52,0x00,0x73,0x00,0x46,0x00,0x78,0x00,0x43,0x00,0x6f,0x00,0x6e,0x00,0x66,0x00,0x69,0x00,0x67,0x00,0x4d,0x00,0x75,0x00,0x74,0x00,0x65,0x00,0x78,0x00,0x30,0x00,0x37,0x00,0x01,0x01,0x00,0x00,0x00,0x00,0x00,0x05,0x12,0x00,0x00,0x00,0x01,0x01,0x00,0x00,0x00,0x00,0x00,0x05,0x12,0x00,0x00,0x00)) -PropertyType Binary -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0700\Instances' -Name 'DefaultInstance' -Value 'RsFx0700 MiniFilter Instance' -PropertyType String -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0700\Instances\RsFx0700 MiniFilter Instance' -Name 'Altitude' -Value '41007.00' -PropertyType String -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0700\Instances\RsFx0700 MiniFilter Instance' -Name 'Flags' -Value 0 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0700\InstancesShares' -Name '(default)' -Value '' -PropertyType String -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0700\NetworkProvider' -Name 'Name' -Value 'RsFx0700 Client Network' -PropertyType String -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0700\NetworkProvider' -Name 'DeviceName' -Value '\Device\RsFx0700' -PropertyType String -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0700\Parameters' -Name 'TraceFlag' -Value 3 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0700\Parameters' -Name 'TraceBuffers' -Value 5 -PropertyType DWord -Force -ea SilentlyContinue;

Start-Process -FilePath "$sqlInstallerPath" -ArgumentList "$sqlInstallArgs" -Wait
Start-Process -FilePath "sc.exe" -ArgumentList "delete RsFx0700"