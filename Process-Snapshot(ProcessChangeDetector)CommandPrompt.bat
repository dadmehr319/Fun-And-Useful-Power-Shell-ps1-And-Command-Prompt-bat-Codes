@echo off
setlocal

:: Process-Snapshot.bat
:: Takes two snapshots of running processes and reports new or terminated processes.

set "SNAPSHOT_INTERVAL_SECONDS=5"
set "SNAPSHOT1_FILE=Process_Snapshot1.txt"
set "SNAPSHOT2_FILE=Process_Snapshot2.txt"
set "REPORT_FILE=Process_Changes_Report.txt"

echo.
echo =========================================
echo  Process Change Detector
echo =========================================
echo.
echo Taking first process snapshot...
tasklist /nh /fo csv | findstr /v "ImageName" > "%SNAPSHOT1_FILE%"
echo First snapshot complete. Waiting %SNAPSHOT_INTERVAL_SECONDS% seconds...

timeout /t %SNAPSHOT_INTERVAL_SECONDS% /nobreak > NUL

echo Taking second process snapshot...
tasklist /nh /fo csv | findstr /v "ImageName" > "%SNAPSHOT2_FILE%"
echo Second snapshot complete.

echo.
echo Analyzing changes...
echo Process Changes Report > "%REPORT_FILE%"
echo ----------------------- >> "%REPORT_FILE%"
echo. >> "%REPORT_FILE%"

echo Started Processes: >> "%REPORT_FILE%"
echo ------------------ >> "%REPORT_FILE%"
findstr /v /g:"%SNAPSHOT1_FILE%" "%SNAPSHOT2_FILE%" >> "%REPORT_FILE%"
echo. >> "%REPORT_FILE%"

echo Terminated Processes: >> "%REPORT_FILE%"
echo --------------------- >> "%REPORT_FILE%"
findstr /v /g:"%SNAPSHOT2_FILE%" "%SNAPSHOT1_FILE%" >> "%REPORT_FILE%"
echo. >> "%REPORT_FILE%"

echo.
echo Report generated on %DATE% at %TIME% >> "%REPORT_FILE%"
echo.
echo Process change analysis complete! Check "%REPORT_FILE%"
echo.

:: Clean up temporary files
del "%SNAPSHOT1_FILE%" "%SNAPSHOT2_FILE%" > NUL 2>&1

pause
endlocal