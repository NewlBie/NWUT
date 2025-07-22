:: Windows Update Troubleshooter
:: Author: Neal Biju
:: Created: July 2025

@echo off
setlocal EnableDelayedExpansion

:: Check if running with admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrative privileges.
    echo Please run the Command Prompt as an Administrator and try again.
    pause
    exit /b 1
)

:: Set timestamp for backup naming
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "TIMESTAMP=%dt:~0,8%"

:: Modern ASCII art header for "Newlbie"
echo.
echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo      _   _          _ _          
echo     ^| \ ^| ^|__ _ ___^| ^| ^| ___  _ __
echo     ^|  \^| / _` / __^| ^| ^|/ _ \^| '__^|
echo     ^| ^|\  ^| (_^| \__ \ ^|_^| (_) ^| ^|   
echo     ^|_^| \_^|__,_^|___/\__^|\___/^|_^|
echo.
echo        Windows Update Troubleshooter
echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo.
echo This script will attempt to fix Windows Update issues by stopping services,
echo cleaning up files, resetting configurations, and re-registering components.
echo It supports both older (qmgr*.dat) and newer (qmgr*.db) systems.
echo Backups will be created, and changes can be reverted to ensure system safety.
echo If steps fail, it will guide you to download and run a Windows ISO for repair.
echo.
echo WARNING: Ensure you have a stable internet connection and backup important data before proceeding.
echo.

:: Prompt user for confirmation
set /p confirm="Do you want to proceed with troubleshooting Windows Update? (Y/N): "
if /i "!confirm!" neq "Y" (
    echo Operation cancelled by user.
    pause
    exit /b 0
)

:: Ask user about specific issues
echo.
echo Please answer the following to help tailor the troubleshooting process:
set /p update_issue="Is the update stuck at a specific percentage (e.g., 8%)? If yes, specify the percentage; otherwise, type 'No': "
set /p driver_issue="Are you experiencing driver-related issues (e.g., devices not working)? (Y/N): "
set /p boot_issue="Is your system failing to start normally (requiring Safe Mode)? (Y/N): "

:: Log file setup
set LOGFILE=%TEMP%\windows_update_fix_log_%TIMESTAMP%.txt
echo Windows Update Troubleshooter Log > %LOGFILE%
echo Started at %DATE% %TIME% >> %LOGFILE%
echo. >> %LOGFILE%

:: Backup file for service security descriptors
set BACKUP_SDS=%TEMP%\service_sds_backup_%TIMESTAMP%.txt
echo Backing up service security descriptors... >> %LOGFILE%

:: Backup current BITS and Windows Update security descriptors
echo Backing up BITS security descriptor... >> %LOGFILE%
sc.exe sdshow bits > "%BACKUP_SDS%" 2>> %LOGFILE%
echo Backing up Windows Update security descriptor... >> %LOGFILE%
sc.exe sdshow wuauserv >> "%BACKUP_SDS%" 2>> %LOGFILE%
echo Security descriptors backed up to %BACKUP_SDS%. >> %LOGFILE%
echo.

:: Step 1: Stop relevant services
echo Stopping BITS, Windows Update, AppID, and Cryptographic services...
echo Stopping services... >> %LOGFILE%
for %%s in (bits wuauserv appidsvc cryptsvc) do (
    net stop %%s >> %LOGFILE% 2>&1
    if !errorlevel! equ 0 (
        echo Successfully stopped %%s. >> %LOGFILE%
    ) else (
        echo Failed to stop %%s or already stopped. >> %LOGFILE%
    )
)
echo.

:: Step 2: Delete qmgr* files (both old and new locations for compatibility)
echo Deleting BITS queue files (qmgr*.dat and qmgr*.db) from old and new locations...
echo Deleting qmgr* files... >> %LOGFILE%
if exist "%ALLUSERSPROFILE%\Application Data\Microsoft\Network\Downloader\qmgr*.dat" (
    del "%ALLUSERSPROFILE%\Application Data\Microsoft\Network\Downloader\qmgr*.dat" /Q >> %LOGFILE% 2>&1
    echo Deleted qmgr*.dat from old location. >> %LOGFILE%
) else (
    echo No qmgr*.dat files found in old location. >> %LOGFILE%
)
if exist "%ALLUSERSPROFILE%\Application Data\Microsoft\Network\Downloader\qmgr*.db" (
    del "%ALLUSERSPROFILE%\Application Data\Microsoft\Network\Downloader\qmgr*.db" /Q >> %LOGFILE% 2>&1
    echo Deleted qmgr*.db from old location. >> %LOGFILE%
) else (
    echo No qmgr*.db files found in old location. >> %LOGFILE%
)
if exist "C:\ProgramData\Microsoft\Network\Downloader\qmgr*.dat" (
    del "C:\ProgramData\Microsoft\Network\Downloader\qmgr*.dat" /Q >> %LOGFILE% 2>&1
    echo Deleted qmgr*.dat from new location. >> %LOGFILE%
) else (
    echo No qmgr*.dat files found in new location. >> %LOGFILE%
)
if exist "C:\ProgramData\Microsoft\Network\Downloader\qmgr*.db" (
    del "C:\ProgramData\Microsoft\Network\Downloader\qmgr*.db" /Q >> %LOGFILE% 2>&1
    echo Deleted qmgr*.db from new location. >> %LOGFILE%
) else (
    echo No qmgr*.db files found in new location. >> %LOGFILE%
)
echo.

:: Step 3: Backup and rename SoftwareDistribution and catroot2 folders
echo Backing up and renaming SoftwareDistribution and catroot2 folders...
echo Backing up and renaming folders... >> %LOGFILE%
if exist "%systemroot%\SoftwareDistribution" (
    xcopy "%systemroot%\SoftwareDistribution" "%systemroot%\SoftwareDistribution_%TIMESTAMP%.bak" /E /I /Q >> %LOGFILE% 2>&1
    ren "%systemroot%\SoftwareDistribution" SoftwareDistribution.bak >> %LOGFILE% 2>&1
    if !errorlevel! equ 0 (
        echo Successfully backed up and renamed SoftwareDistribution. >> %LOGFILE%
    ) else (
        echo Failed to rename SoftwareDistribution. Check if files are in use. >> %LOGFILE%
    )
) else (
    echo SoftwareDistribution folder not found. >> %LOGFILE%
)
if exist "%systemroot%\system32\catroot2" (
    xcopy "%systemroot%\system32\catroot2" "%systemroot%\system32\catroot2_%TIMESTAMP%.bak" /E /I /Q >> %LOGFILE% 2>&1
    ren "%systemroot%\system32\catroot2" catroot2.bak >> %LOGFILE% 2>&1
    if !errorlevel! equ 0 (
        echo Successfully backed up and renamed catroot2. >> %LOGFILE%
    ) else (
        echo Failed to rename catroot2. Check if files are in use. >> %LOGFILE%
    )
) else (
    echo catroot2 folder not found. >> %LOGFILE%
)
echo.

:: Step 4: Reset BITS and Windows Update service security descriptors
echo Resetting BITS and Windows Update service security descriptors...
echo Resetting security descriptors... >> %LOGFILE%
sc.exe sdset bits D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU) >> %LOGFILE% 2>&1
sc.exe sdset wuauserv D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU) >> %LOGFILE% 2>&1
if %errorlevel% equ 0 (
    echo Successfully reset security descriptors. >> %LOGFILE%
) else (
    echo Failed to reset security descriptors. >> %LOGFILE%
)
echo.

:: Step 5: Navigate to system32 directory
cd /d %windir%\system32
if %errorlevel% neq 0 (
    echo Failed to navigate to system32 directory. >> %LOGFILE%
    echo Failed to navigate to system32. Aborting.
    pause
    exit /b 1
)
echo Navigated to system32 directory. >> %LOGFILE%
echo.

:: Step 6: Re-register DLLs
echo Re-registering BITS and Windows Update DLLs...
echo Re-registering DLLs... >> %LOGFILE%
for %%i in (
    atl.dll urlmon.dll mshtml.dll shdocvw.dll browseui.dll jscript.dll vbscript.dll
    scrrun.dll msxml.dll msxml3.dll msxml6.dll actxprxy.dll softpub.dll wintrust.dll
    dssenh.dll rsaenh.dll gpkcsp.dll sccbase.dll slbcsp.dll cryptdlg.dll oleaut32.dll
    ole32.dll shell32.dll initpki.dll wuapi.dll wuaueng.dll wuaueng1.dll wucltui.dll
    wups.dll wups2.dll wuweb.dll qmgr.dll qmgrprxy.dll wucltux.dll muweb.dll wuwebv.dll
) do (
    regsvr32.exe /s %%i >> %LOGFILE% 2>&1
    if !errorlevel! equ 0 (
        echo Successfully registered %%i. >> %LOGFILE%
    ) else (
        echo Failed to register %%i. >> %LOGFILE%
    )
)
echo DLL registration complete. >> %LOGFILE%
echo.

:: Step 7: Reset Winsock and WinHTTP proxy
echo Resetting Winsock and WinHTTP proxy...
echo Resetting Winsock and WinHTTP proxy... >> %LOGFILE%
netsh winsock reset >> %LOGFILE% 2>&1
netsh winhttp reset proxy >> %LOGFILE% 2>&1
if %errorlevel% equ 0 (
    echo Successfully reset Winsock and WinHTTP proxy. >> %LOGFILE%
) else (
    echo Failed to reset Winsock or WinHTTP proxy. >> %LOGFILE%
)
echo.

:: Step 8: Clear BITS queue
echo Clearing BITS queue...
echo Clearing BITS queue... >> %LOGFILE%
bitsadmin.exe /reset /allusers >> %LOGFILE% 2>&1
if %errorlevel% equ 0 (
    echo Successfully cleared BITS queue. >> %LOGFILE%
) else (
    echo Failed to clear BITS queue. >> %LOGFILE%
)
echo.

:: Step 9: Restart services
echo Restarting BITS, Windows Update, AppID, and Cryptographic services...
echo Restarting services... >> %LOGFILE%
for %%s in (bits wuauserv appidsvc cryptsvc) do (
    net start %%s >> %LOGFILE% 2>&1
    if !errorlevel! equ 0 (
        echo Successfully started %%s. >> %LOGFILE%
    ) else (
        echo Failed to start %%s. >> %LOGFILE%
    )
)
echo.

:: Step 10: Run System File Checker and DISM
echo Running System File Checker and DISM to repair system files...
echo Running SFC and DISM... >> %LOGFILE%
sfc /scannow >> %LOGFILE% 2>&1
if %errorlevel% equ 0 (
    echo System File Checker completed successfully. >> %LOGFILE%
) else (
    echo System File Checker encountered an error. >> %LOGFILE%
)
echo Running DISM to restore system health...
DISM /Online /Cleanup-Image /RestoreHealth >> %LOGFILE% 2>&1
if %errorlevel% equ 0 (
    echo DISM completed successfully. >> %LOGFILE%
) else (
    echo DISM encountered an error. >> %LOGFILE%
)
echo.

:: Step 11: Check if issues persist
echo Troubleshooting steps completed. Checking if issues are resolved...
echo.
set /p test_update="Please try running Windows Update again. Is the issue resolved? (Y/N): "
if /i "!test_update!" equ "Y" (
    echo Windows Update issue resolved successfully! >> %LOGFILE%
    echo The issue appears to be resolved.
) else (
    echo Windows Update issue not resolved. You may need to perform a repair installation using a Windows ISO.
    echo.
    set /p iso_confirm="Would you like to download a Windows ISO for a repair installation? (Y/N): "
    if /i "!iso_confirm!" equ "Y" (
        :: Step 12: Detect Windows version
        echo Detecting Windows version...
        for /f "tokens=3" %%i in ('systeminfo ^| findstr /B /C:"OS Name"') do set OS_NAME=%%i
        for /f "tokens=3" %%i in ('systeminfo ^| findstr /B /C:"OS Version"') do set OS_VERSION=%%i
        echo Detected OS: %OS_NAME% %OS_VERSION% >> %LOGFILE%
        echo.

        :: Step 13: Open browser to Microsoft download page
        echo Opening browser to Microsoft Windows ISO download page...
        echo Opening browser for ISO download... >> %LOGFILE%
        start "" "https://www.microsoft.com/en-us/software-download/windows10"
        echo Please follow the instructions on the Microsoft website to download the Windows ISO.
        echo After downloading, mount the ISO by double-clicking it, then run 'setup.exe' to perform a repair installation.
        echo Select 'Keep personal files and apps' during the setup to preserve your data.
        echo.
    ) else (
        echo Skipped ISO download. >> %LOGFILE%
    )
)

:: Step 14: Prompt to revert changes
echo.
set /p revert_changes="Would you like to revert changes made by this script to restore the original state? (Y/N): "
if /i "!revert_changes!" equ "Y" (
    echo Reverting changes... >> %LOGFILE%
    
    :: Stop services again for safety
    echo Stopping services for reversion... >> %LOGFILE%
    for %%s in (bits wuauserv appidsvc cryptsvc) do (
        net stop %%s >> %LOGFILE% 2>&1
    )
    
    :: Restore SoftwareDistribution and catroot2 from backups
    if exist "%systemroot%\SoftwareDistribution_%TIMESTAMP%.bak" (
        rd /s /q "%systemroot%\SoftwareDistribution" >> %LOGFILE% 2>&1
        ren "%systemroot%\SoftwareDistribution_%TIMESTAMP%.bak" SoftwareDistribution >> %LOGFILE% 2>&1
        if !errorlevel! equ 0 (
            echo Successfully restored SoftwareDistribution. >> %LOGFILE%
        ) else (
            echo Failed to restore SoftwareDistribution. >> %LOGFILE%
        )
    ) else (
        echo SoftwareDistribution backup not found. >> %LOGFILE%
    )
    if exist "%systemroot%\system32\catroot2_%TIMESTAMP%.bak" (
        rd /s /q "%systemroot%\system32\catroot2" >> %LOGFILE% 2>&1
        ren "%systemroot%\system32\catroot2_%TIMESTAMP%.bak" catroot2 >> %LOGFILE% 2>&1
        if !errorlevel! equ 0 (
            echo Successfully restored catroot2. >> %LOGFILE%
        ) else (
            echo Failed to restore catroot2. >> %LOGFILE%
        )
    ) else (
        echo catroot2 backup not found. >> %LOGFILE%
    )
    
    :: Restore service security descriptors
    if exist "%BACKUP_SDS%" (
        echo Restoring service security descriptors... >> %LOGFILE%
        for /f "tokens=*" %%i in ('type "%BACKUP_SDS%"') do (
            sc.exe sdset %%i >> %LOGFILE% 2>&1
            if !errorlevel! equ 0 (
                echo Successfully restored security descriptor for %%i. >> %LOGFILE%
            ) else (
                echo Failed to restore security descriptor for %%i. >> %LOGFILE%
            )
        )
    ) else (
        echo Security descriptor backup not found. >> %LOGFILE%
    )
    
    :: Restart services after reversion
    echo Restarting services after reversion... >> %LOGFILE%
    for %%s in (bits wuauserv appidsvc cryptsvc) do (
        net start %%s >> %LOGFILE% 2>&1
        if !errorlevel! equ 0 (
            echo Successfully started %%s. >> %LOGFILE%
        ) else (
            echo Failed to start %%s. >> %LOGFILE%
        )
    )
    echo Changes reverted successfully. >> %LOGFILE%
) else (
    echo Changes not reverted. Backups are retained at %systemroot%\SoftwareDistribution_%TIMESTAMP%.bak and %systemroot%\system32\catroot2_%TIMESTAMP%.bak. >> %LOGFILE%
)

:: Final message
echo.
echo Script execution completed. If you need further assistance, contact Microsoft Support.
echo Log file saved at: %LOGFILE%
echo Backup files (if any) are located at: %systemroot%\SoftwareDistribution_%TIMESTAMP%.bak and %systemroot%\system32\catroot2_%TIMESTAMP%.bak
echo Security descriptor backup (if any) is located at: %BACKUP_SDS%
pause
exit /b 0