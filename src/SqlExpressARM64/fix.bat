<# :
  @echo off
    powershell /nologo /noprofile /command ^
        "&{[ScriptBlock]::Create((cat """%~f0""") -join [Char[]]10).Invoke(@(&{$args}%*))}"
  exit /b
#>

$sqlInstanceName = Get-Item "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL" | Select-Object -ExpandProperty Property | Select-Object -First 1
$sqlInstanceLongName = Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL" "$sqlInstanceName"
$sqlPath = Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$sqlInstanceLongName\Setup" "SQLPath"
$sqlProgramDir = Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$sqlInstanceLongName\Setup" "SQLProgramDir"

# fix the SQL installation:
$logDir = "$sqlPath\Log"
New-Item -Path $logDir -ItemType Directory

$dataDir = "$sqlPath\DATA"
New-Item -Path $dataDir -ItemType Directory

If ($sqlInstanceName -eq "MSSQLSERVER") {
   $serviceName = $sqlInstanceName
} else {
   $serviceName = "MSSQL`$$sqlInstanceName"
}

# set ACL for the SQL Server account
$user = "NT SERVICE\$serviceName"

$acl = Get-Acl $logDir
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($user,"FullControl","ContainerInherit,ObjectInherit","None","Allow")
$acl.SetAccessRule($accessRule)
$acl | Set-Acl $logDir

$acl = Get-Acl $dataDir
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($user,"FullControl","ContainerInherit,ObjectInherit","None","Allow")
$acl.SetAccessRule($accessRule)
$acl | Set-Acl $dataDir

# copy missing databases from the Templates folder - without these in place the SQL Database Rebuild won't work
Copy-Item -Path "$sqlPath\Binn\Templates\master.mdf" -Destination "$sqlPath\DATA" -Force -Verbose
Copy-Item -Path "$sqlPath\Binn\Templates\mastlog.ldf" -Destination "$sqlPath\DATA" -Force -Verbose

# create missing registry entries to point the SQL Server to the right master database
$registryPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$sqlInstanceLongName\MSSQLServer\Parameters"
$name = "SQLArg0"
$value = "-d$sqlPath\DATA\master.mdf"
New-ItemProperty -Path $registryPath -Name $name -Value $value -Force
$name = "SQLArg1"
$value = "-e$sqlPath\Log\ERRORLOG"
New-ItemProperty -Path $registryPath -Name $name -Value $value -Force
$name = "SQLArg2"
$value = "-l$sqlPath\DATA\mastlog.ldf"
New-ItemProperty -Path $registryPath -Name $name -Value $value -Force

# locate the setup.exe to rebuild the databases
$sqlVersionSpecificPath = (Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server" | Where-Object { $_.Property -match "VerSpecificRootDir" } | Select-Object -First 1 -ExpandProperty "Name").replace("HKEY_LOCAL_MACHINE","HKLM:")
$sqlVersionSpecificBootstrapPath = "$sqlVersionSpecificPath\Bootstrap"
$bootstrapDir = Get-ItemPropertyValue $sqlVersionSpecificBootstrapPath "BootstrapDir"
$sqlVersionSpecificFolder = (Get-ChildItem "$sqlVersionSpecificPath" | Where-Object { $_.Name.Split('\')[5].StartsWith("SQL") }).Name.Split('\')[5]
Start-Process "$bootstrapDir$sqlVersionSpecificFolder\setup.exe" -ArgumentList "/qs /ACTION=REBUILDDATABASE /INSTANCENAME=""$sqlInstanceName"" /ENU /SQLSYSADMINACCOUNTS=""BUILTIN\Administrators""" -PassThru -Wait

# run the service - it should start now
net start "$serviceName"