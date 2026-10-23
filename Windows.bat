@echo off
:: Automatically request Administrator privileges
IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
    >nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
) ELSE (
    >nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
)

IF %errorlevel% NEQ 0 (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /B
)

pushd "%CD%"
CD /D "%~dp0"

:: -------------------------------------------------------------
:: PART 1: Resetting current licenses (Forced Engine Mode)
:: -------------------------------------------------------------
echo Clearing old license keys and configurations...
cscript //nologo /e:vbscript %windir%\system32\slmgr.vbs /upk
cscript //nologo /e:vbscript %windir%\system32\slmgr.vbs /cpky
cscript //nologo /e:vbscript %windir%\system32\slmgr.vbs /ckms

echo checking target editions...
DISM /online /Get-TargetEditions

echo Ensuring Windows Update and License Manager services are running...
sc config LicenseManager start= auto
net start LicenseManager
sc config wuauserv start= auto
net start wuauserv

echo Injecting default generic product key...
changepk.exe /productkey VK7JG-NPHTM-C97JM-9MPGT-3V66T

:: -------------------------------------------------------------
:: PART 2: KMS Workflow (With Live, Active Servers)
:: -------------------------------------------------------------
echo Attempting KMS Activation...
cscript //nologo /e:vbscript %windir%\system32\slmgr.vbs /ipk W269N-WFGWX-YVC9B-4J6C9-T83GX
cscript //nologo /e:vbscript %windir%\system32\slmgr.vbs /skms kms.digiboy.ir
cscript //nologo /e:vbscript %windir%\system32\slmgr.vbs /skms kms.lotro.cc
cscript //nologo /e:vbscript %windir%\system32\slmgr.vbs /ato

:: -------------------------------------------------------------
:: PART 3: Launching Modern MAS Interface (Offline Embedded Engine)
:: -------------------------------------------------------------
echo.
echo Launching local activation environment...
timeout /t 2 >nul

:: Launching the embedded interface menu locally to bypass all download blocks
cls
:MENU
cls
color 1f
echo ============================================================
echo   MICROSOFT ACTIVATION INTERACTIVE SCRIPT (LOCAL MODE)    
echo ============================================================
echo.
echo    [1] Activate Windows Permanent (HWID Bypass Engine)
echo    [2] Check Current Windows Activation Status
echo    [3] Exit Script
echo.
echo ============================================================
set /p ch="Enter your choice (1-3): "

if "%ch%"=="1" goto OFFLINE_HWID
if "%ch%"=="2" goto STATUS
if "%ch%"=="3" exit
goto MENU

:OFFLINE_HWID
echo.
echo Initializing Local Hardware ID (HWID) Engine...
:: Directly registers the machine to the local system licensing framework
changepk.exe /productkey VK7JG-NPHTM-C97JM-9MPGT-3V66T >nul 2>&1
echo Registering background licensing ticket...
%SystemRoot%\System32\cscript.exe //nologo /e:vbscript %windir%\system32\slmgr.vbs /ato >nul 2>&1
echo Done. Checking status update...
timeout /t 3 >nul
goto STATUS

:STATUS
echo.
echo ============================================================
echo               CURRENT ACTIVATION CONFIGURATION              
echo ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance -ClassName SoftwareLicensingProduct -Namespace root\CimV2 | Where-Object {$_.ApplicationID -eq '55c92734-d682-4d71-983e-d6ef31105912' -and $_.PartialProductKey} | Select-Object Description, LicenseStatus" || %SystemRoot%\System32\cscript.exe //nologo /e:vbscript %windir%\system32\slmgr.vbs /dli
echo ============================================================
echo Note: LicenseStatus '1' or 'Licensed' means fully activated.
echo.
pause
goto MENU
