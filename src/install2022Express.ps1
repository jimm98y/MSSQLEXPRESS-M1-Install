# set the current path to the same directory as the script
Set-Location -LiteralPath $PSScriptRoot

$sqlExpressDownloadUrl = "https://download.microsoft.com/download/5/1/4/5145fe04-4d30-4b85-b0d1-39533663a2f1/SQL2022-SSEI-Expr.exe"
$sqlManagementStudioDownloadUrl = "https://aka.ms/ssmsfullsetup?clcid=0x409"
$sqlYear = 2022
$sqlVersion = 16
$instanceName = "SQLEXPRESS"
$user = whoami

$expressInstallerPath = "./Temp/SQL$sqlYear-SSEI-Expr.exe"
$fullInstallerPath = "./Temp/SQLEXPR_x64_ENU.exe"
$setupFolderPath = "./Temp/SQLEXPR_x64_ENU"
$ssmsInstallerPath = "./Temp/SSMS-Setup-ENU.exe"
$sqlInstallArgs = "/qs /ACTION=Install /FEATURES=SQLEngine /INSTANCENAME=$instanceName /ENU /IACCEPTSQLSERVERLICENSETERMS /UPDATEENABLED=false /USEMICROSOFTUPDATE=false"

$maxDownloadRepeatCount = 5
$actualInstanceName = $instanceName
If ($instanceName -eq "MSSQLSERVER") {
   $serviceName = $instanceName
} else {
   $serviceName = "MSSQL`$$instanceName"
}
$installedPath = "$Env:Programfiles\Microsoft SQL Server\MSSQL$sqlVersion.$actualInstanceName\MSSQL"
$registryPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL$sqlVersion.$actualInstanceName\MSSQLServer\Parameters"

Function Send-ToRecycleBin
{
    Param(
    [Parameter(Mandatory = $true,
    ValueFromPipeline = $true)]
    [alias('FullName')]
    [string]$FilePath
    )
    Begin{$shell = New-Object -ComObject 'Shell.Application'}
    Process{
        $Item = Get-Item $FilePath
        $shell.namespace(0).ParseName($item.FullName).InvokeVerb('delete')
    }
}

# create temporary work folder
If(-not(Test-Path "./Temp")) {
    New-Item -Path "Temp" -ItemType Directory
}

# download and install SQL Server
If(-not(Test-Path $expressInstallerPath -PathType Leaf)) {
    Write-Host "Downloading SQL Installer..."

    $counter = $maxDownloadRepeatCount;
    While ($counter -gt 0) {
       try {
          Invoke-WebRequest -Uri $sqlExpressDownloadUrl -OutFile $expressInstallerPath
          $counter = 0
       } catch {
          $counter -= 1
       }
    }
}

If(-not(Test-Path $fullInstallerPath -PathType Leaf)) {
    Write-Host "Downloading Full SQL Installer..."
    $absoluteInstallerPath = (Resolve-Path "./Temp").Path

    # use the "express installer" to download the full installer
    Start-Process -FilePath $expressInstallerPath -ArgumentList "/QUIET /ACTION=Download /ENU /MEDIAPATH=$absoluteInstallerPath" -Wait
}

If(-not(Test-Path $setupFolderPath)) {
    # extract the full installer
    Start-Process -FilePath $fullInstallerPath -ArgumentList "/q" -Wait -WorkingDirectory "./Temp"
}

# Running the setup in GUI will fail before the installation even starts because of Windows Updates, so it has to be executed from the command line.
# The installation will fail on M1 in the final steps of the installation.

# run the setup - the first time it fails to install SQL Server Windows service
Start-Process -FilePath "$setupFolderPath/SETUP.EXE" -ArgumentList $sqlInstallArgs -Wait

# running the setup for the second time installs the SQL Server Windows service
Start-Process -FilePath "$setupFolderPath/SETUP.EXE" -ArgumentList $sqlInstallArgs -Wait

# now we are in the state when SQL is installed, but SQL Service cannot be started because there are missing registry entries and there is no master database

# fix the SQL installation:
$logDir = "$installedPath\Log"
New-Item -Path $logDir -ItemType Directory

$dataDir = "$installedPath\DATA"
New-Item -Path $dataDir -ItemType Directory

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

# set the ACL for the current user
$user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

$acl = Get-Acl $logDir
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($user,"FullControl","ContainerInherit,ObjectInherit","None","Allow")
$acl.SetAccessRule($accessRule)
$acl | Set-Acl $logDir

$acl = Get-Acl $dataDir
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($user,"FullControl","ContainerInherit,ObjectInherit","None","Allow")
$acl.SetAccessRule($accessRule)
$acl | Set-Acl $dataDir

# copy missing databases from the Templates folder - without these in place the SQL Database Rebuild won't work
Copy-Item -Path "$installedPath\Binn\Templates\master.mdf" -Destination "$installedPath\DATA" -Force -Verbose
Copy-Item -Path "$installedPath\Binn\Templates\mastlog.ldf" -Destination "$installedPath\DATA" -Force -Verbose

# create missing registry entries to point the SQL Server to the right master database
$name = "SQLArg0"
$value = "-d$installedPath\DATA\master.mdf"
New-ItemProperty -Path $registryPath -Name $name -Value $value -Force
$name = "SQLArg1"
$value = "-e$installedPath\Log\ERRORLOG"
New-ItemProperty -Path $registryPath -Name $name -Value $value -Force
$name = "SQLArg2"
$value = "-l$installedPath\DATA\mastlog.ldf"
New-ItemProperty -Path $registryPath -Name $name -Value $value -Force

# rebuild databases
$user = whoami
Start-Process -FilePath "$setupFolderPath/SETUP.EXE" -ArgumentList "/QUIET /ACTION=REBUILDDATABASE /INSTANCENAME=$actualInstanceName /ENU /SQLSYSADMINACCOUNTS=$user" -Wait

# run the service - it should start now
net start $serviceName

# download and install SSMS
If(-not(Test-Path $ssmsInstallerPath -PathType Leaf)) {
    Write-Host "Downloading SQL Server Management Studio..."
        
    $counter = $maxDownloadRepeatCount;
    While ($counter -gt 0) {
       try {
          Invoke-WebRequest -Uri $sqlManagementStudioDownloadUrl -OutFile $ssmsInstallerPath
          $counter = 0
       } catch {
          $counter -= 1
       }
    }
}

# install SSMS
Start-Process -FilePath $ssmsInstallerPath -ArgumentList "/Install /Passive" -Wait

# delete temp files
"./Temp" | Send-ToRecycleBin

echo "SQL Installation completed, press any key to exit"
[Console]::ReadKey()
