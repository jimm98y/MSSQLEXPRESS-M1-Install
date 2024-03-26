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

$SqlInstance = "SQLEXPRESS"
$SqlFeatures = "SQLENGINE"
$sqlInstallArgs = "/qs /ACTION=Install /FEATURES=${SqlFeatures} /INSTANCENAME=${SqlInstance} /IACCEPTSQLSERVERLICENSETERMS=true /UPDATEENABLED=false /USEMICROSOFTUPDATE=false /ENU"
$sqlInstallerPath = "./SQLEXPR_x64_ENU.exe"
$sqlDownloadUrl = "https://download.microsoft.com/download/8/4/c/84c6c430-e0f5-476d-bf43-eaaa222a72e0/SQLEXPR_x64_ENU.exe"

If(-not(Test-Path "$sqlInstallerPath" -PathType Leaf)) {
  $ProgressPreference = 'SilentlyContinue'
  Invoke-WebRequest -Uri "$sqlDownloadUrl" -OutFile "$sqlInstallerPath"
  $ProgressPreference = 'Continue'
}
Start-Process -FilePath "sc.exe" -ArgumentList "delete RsFx0600"
Start-Process -FilePath "sc.exe" -ArgumentList "delete RsFx0700"
Start-Process -FilePath "$sqlInstallerPath" -ArgumentList "$sqlInstallArgs" -Wait
Start-Process -FilePath "sc.exe" -ArgumentList "create RsFx0600 binPath= $Env:WinDir\System32\Drivers\RsFx0600.sys"

# Reg2CI (c) 2022 by Roger Zander
if((Test-Path -LiteralPath "HKLM:\SYSTEM\ControlSet001\Services\RsFx0600") -ne $true) {  New-Item "HKLM:\SYSTEM\ControlSet001\Services\RsFx0600" -force -ea SilentlyContinue };
if((Test-Path -LiteralPath "HKLM:\SYSTEM\ControlSet001\Services\RsFx0600\DeviceSecurity") -ne $true) {  New-Item "HKLM:\SYSTEM\ControlSet001\Services\RsFx0600\DeviceSecurity" -force -ea SilentlyContinue };
if((Test-Path -LiteralPath "HKLM:\SYSTEM\ControlSet001\Services\RsFx0600\Instances") -ne $true) {  New-Item "HKLM:\SYSTEM\ControlSet001\Services\RsFx0600\Instances" -force -ea SilentlyContinue };
if((Test-Path -LiteralPath "HKLM:\SYSTEM\ControlSet001\Services\RsFx0600\Instances\RsFx0600 MiniFilter Instance") -ne $true) {  New-Item "HKLM:\SYSTEM\ControlSet001\Services\RsFx0600\Instances\RsFx0600 MiniFilter Instance" -force -ea SilentlyContinue };
if((Test-Path -LiteralPath "HKLM:\SYSTEM\ControlSet001\Services\RsFx0600\InstancesShares") -ne $true) {  New-Item "HKLM:\SYSTEM\ControlSet001\Services\RsFx0600\InstancesShares" -force -ea SilentlyContinue };
if((Test-Path -LiteralPath "HKLM:\SYSTEM\ControlSet001\Services\RsFx0600\InstancesShares\{07a0a6c1-5765-435f-bc8c-5c8c16d29d0d}") -ne $true) {  New-Item "HKLM:\SYSTEM\ControlSet001\Services\RsFx0600\InstancesShares\{07a0a6c1-5765-435f-bc8c-5c8c16d29d0d}" -force -ea SilentlyContinue };
if((Test-Path -LiteralPath "HKLM:\SYSTEM\ControlSet001\Services\RsFx0600\NetworkProvider") -ne $true) {  New-Item "HKLM:\SYSTEM\ControlSet001\Services\RsFx0600\NetworkProvider" -force -ea SilentlyContinue };
if((Test-Path -LiteralPath "HKLM:\SYSTEM\ControlSet001\Services\RsFx0600\Parameters") -ne $true) {  New-Item "HKLM:\SYSTEM\ControlSet001\Services\RsFx0600\Parameters" -force -ea SilentlyContinue };
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0600' -Name 'Type' -Value 2 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0600' -Name 'Start' -Value 4 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0600' -Name 'ErrorControl' -Value 1 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0600' -Name 'Tag' -Value 3 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0600' -Name 'ImagePath' -Value 'system32\DRIVERS\RsFx0600.sys' -PropertyType ExpandString -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0600' -Name 'DisplayName' -Value 'RsFx0600 Driver' -PropertyType String -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0600' -Name 'Group' -Value 'FsFilter Bottom' -PropertyType String -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0600' -Name 'DependOnService' -Value @("FltMgr") -PropertyType MultiString -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0600' -Name 'Description' -Value 'RsFx 0600 driver allows Win32 user-mode applications/services to own and manage Win32 namespaces of the UNC format. If this service is stopped, these functions will not be available. If this service is disabled, any services that explicitly depend on it will fail to start.' -PropertyType String -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0600\DeviceSecurity' -Name 'Security' -Value ([byte[]](0x01,0x00,0x14,0x80,0x64,0x00,0x00,0x00,0x70,0x00,0x00,0x00,0x14,0x00,0x00,0x00,0x30,0x00,0x00,0x00,0x02,0x00,0x1c,0x00,0x01,0x00,0x00,0x00,0x02,0x80,0x14,0x00,0xff,0x01,0x1f,0x00,0x01,0x01,0x00,0x00,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x00,0x02,0x00,0x34,0x00,0x02,0x00,0x00,0x00,0x00,0x00,0x14,0x00,0xff,0x01,0x1f,0x00,0x01,0x01,0x00,0x00,0x00,0x00,0x00,0x05,0x12,0x00,0x00,0x00,0x00,0x00,0x18,0x00,0xff,0x01,0x1f,0x00,0x01,0x02,0x00,0x00,0x00,0x00,0x00,0x05,0x20,0x00,0x00,0x00,0x20,0x02,0x00,0x00,0x01,0x01,0x00,0x00,0x00,0x00,0x00,0x05,0x12,0x00,0x00,0x00,0x01,0x01,0x00,0x00,0x00,0x00,0x00,0x05,0x12,0x00,0x00,0x00)) -PropertyType Binary -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0600\Instances' -Name 'DefaultInstance' -Value 'RsFx0600 MiniFilter Instance' -PropertyType String -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0600\Instances\RsFx0600 MiniFilter Instance' -Name 'Altitude' -Value '41006.00' -PropertyType String -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0600\Instances\RsFx0600 MiniFilter Instance' -Name 'Flags' -Value 0 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0600\InstancesShares' -Name '(default)' -Value '' -PropertyType String -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0600\NetworkProvider' -Name 'Name' -Value 'RsFx0600 Client Network' -PropertyType String -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0600\NetworkProvider' -Name 'DeviceName' -Value '\Device\RsFx0600' -PropertyType String -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0600\Parameters' -Name 'TraceFlag' -Value 3 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\ControlSet001\Services\RsFx0600\Parameters' -Name 'TraceBuffers' -Value 5 -PropertyType DWord -Force -ea SilentlyContinue;

Start-Process -FilePath "$sqlInstallerPath" -ArgumentList "$sqlInstallArgs" -Wait
Start-Process -FilePath "sc.exe" -ArgumentList "delete RsFx0600"