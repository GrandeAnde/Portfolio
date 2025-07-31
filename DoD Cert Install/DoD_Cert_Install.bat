@echo off
setlocal

rem Define log file path and executable path, add date to log file
set "TIMESTAMP=%DATE% %TIME%"
set "LOG_FILE=C:\ProgramData\DoD-PKE\_%date:~-4,4%%date:~-7,2%%date:~-10,2%_InstallRoot_Update.log"
set "INSTALL_ROOT_DIR=C:\Program Files\DoD-PKE\InstallRoot"
set "INSTALL_ROOT_EXE=installroot.exe"


rem Create log directory if it doesn't exist (using PowerShell for this, as batch is clunky).  If it does exist, remove all files older than 30 days.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "if (-not (Test-Path 'C:\ProgramData\DoD-PKE')) { New-Item -ItemType Directory -Path 'C:\ProgramData\DoD-PKE' -Force | Out-Null } else { get-childitem -path "C:\ProgramData\DoD-PKE" -recurse -force | where-object {$_.creationetime -lt (get-date).adddays(30)} | remove-item -force } 

rem Start logging
echo %TIMESTAMP% - ---------------------------------------------------- >> "%LOG_FILE%"
echo %TIMESTAMP% - Starting DoD Certificate Update via Update-DoDCerts.bat >> "%LOG_FILE%"
echo %TIMESTAMP% - Running as user: %USERNAME% >> "%LOG_FILE%"

rem Change current directory to where installroot.exe is located
echo %TIMESTAMP% - Changing current directory to: %INSTALL_ROOT_DIR% >> "%LOG_FILE%"
cd "%INSTALL_ROOT_DIR%" 2>> "%LOG_FILE%"
if %ERRORLEVEL% NEQ 0 (
    echo %TIMESTAMP% - ERROR: Failed to change directory to %INSTALL_ROOT_DIR%. Exiting. >> "%LOG_FILE%"
    exit /b 1
)

rem Define URIs
set "URI1=\\somepath\InstallRoot\file1.ir4"
set "URI2=\\somepath\InstallRoot\file2.ir4"

rem --- Perform --update commands ---
echo %TIMESTAMP% - Executing: %INSTALL_ROOT_EXE% --update --uri "%URI1%" >> "%LOG_FILE%"
"%INSTALL_ROOT_EXE%" --update --uri "%URI1%" 2>> "%LOG_FILE%"
if %ERRORLEVEL% NEQ 0 (
    echo %TIMESTAMP% - WARNING: Update command for %URI1% completed with exit code %ERRORLEVEL%. >> "%LOG_FILE%"
) else (
    echo %TIMESTAMP% - SUCCESS: Update command for %URI1% completed with exit code 0. >> "%LOG_FILE%"
)

echo %TIMESTAMP% - Executing: %INSTALL_ROOT_EXE% --update --uri "%URI2%" >> "%LOG_FILE%"
"%INSTALL_ROOT_EXE%" --update --uri "%URI2%" 2>> "%LOG_FILE%"
if %ERRORLEVEL% NEQ 0 (
    echo %TIMESTAMP% - WARNING: Update command for %URI2% completed with exit code %ERRORLEVEL%. >> "%LOG_FILE%"
) else (
    echo %TIMESTAMP% - SUCCESS: Update command for %URI2% completed with exit code 0. >> "%LOG_FILE%"
)

rem --- Perform --insert commands ---
echo %TIMESTAMP% - Executing: %INSTALL_ROOT_EXE% --insert --uri "%URI1%" >> "%LOG_FILE%"
"%INSTALL_ROOT_EXE%" --insert --uri "%URI1%" 2>> "%LOG_FILE%"
if %ERRORLEVEL% NEQ 0 (
    echo %TIMESTAMP% - WARNING: Insert command for %URI1% completed with exit code %ERRORLEVEL%. >> "%LOG_FILE%"
) else (
    echo %TIMESTAMP% - SUCCESS: Insert command for %URI1% completed with exit code 0. >> "%LOG_FILE%"
)

echo %TIMESTAMP% - Executing: %INSTALL_ROOT_EXE% --insert --uri "%URI2%" >> "%LOG_FILE%"
"%INSTALL_ROOT_EXE%" --insert --uri "%URI2%" 2>> "%LOG_FILE%"
if %ERRORLEVEL% NEQ 0 (
    echo %TIMESTAMP% - WARNING: Insert command for %URI2% completed with exit code %ERRORLEVEL%. >> "%LOG_FILE%"
) else (
    echo %TIMESTAMP% - SUCCESS: Insert command for %URI2% completed with exit code 0. >> "%LOG_FILE%"
)

echo %TIMESTAMP% - DoD Certificate Update via Update-DoDCerts.bat finished. >> "%LOG_FILE%"
echo %TIMESTAMP% - ----------------------------------------------------^n >> "%LOG_FILE%"

endlocal
exit /b 0
