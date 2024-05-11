# MSSQLEXPRESS-M1-Install
Unofficial installers for Microsoft SQL Server on Windows 11 ARM64.

## Installers
You can download the installers in Releases.

## Scripts
You can find the scripts in /src/Scripts. Choose the version/edition of the SQL Server you want to install, download the *.bat file, place it into some folder where you have write permissions (e.g. C:\Temp) and run it as Admin, or grant the UAC elevation when you execute it.

## Supported Editions
- Microsoft SQL 2019 Express
- Microsoft SQL 2019 Developer
- Microsoft SQL 2022 Express
- Microsoft SQL 2022 Developer

## Features not working on ARM64
- Filestream (requires a system driver which is not available on ARM64)
- Azure Attestation (AzureAttestService cannot be started on ARM64)
- 64-bit SQL Configuration Manager not working (mmc.exe is only avaialble as ARM64 (non-EC) process and it cannot load x64 DLLs, so configuration of some features must be done through registry)

## Requirements
- Windows 11 ARM64
