@echo off
setlocal enabledelayedexpansion

:: ===============================================================
:: Process-Snapshot(ProcessChangeDetector)CommandPrompt.bat
:: Takes two snapshots of running processes and reports new or terminated processes.
:: ===============================================================

:: Configuration
set "SNAPSHOT_INTERVAL_SECONDS=5"
set "SNAPSHOT1_FILE=Process_Snapshot1.txt"
set "SNAPSHOT2_FILE=Process_Snapshot2.txt"
set "REPORT_FILE=Process_Changes_Report.txt"

:: Display Header
echo.
echo =========================================
echo      Process Change Detector
echo =========================================
echo.

:: First Snapshot
echo Taking first process snapshot...
tasklist /nh /fo csv | findstr /v "ImageName" > "%SNAPSHOT1_FILE%"
if errorlevel 1 echo Warning: Could not take first snapshot.
echo First snapshot complete. Waiting %SNAPSHOT_INTERVAL_SECONDS% seconds...
timeout /t %SNAPSHOT_INTERVAL_SECONDS% /nobreak > NUL

:: Second Snapshot
echo Taking second process snapshot...
tasklist /nh /fo csv | findstr /v "ImageName" > "%SNAPSHOT2_FILE%"
if errorlevel 1 echo Warning: Could not take second snapshot.
echo Second snapshot complete.
echo.

:: Analyze Changes
echo Analyzing changes...
(
    echo Process Changes Report
    echo -----------------------
    echo.

    echo Started Processes:
    echo ------------------
    findstr /v /g:"%SNAPSHOT1_FILE%" "%SNAPSHOT2_FILE%"
    echo.

    echo Terminated Processes:
    echo ---------------------
    findstr /v /g:"%SNAPSHOT2_FILE%" "%SNAPSHOT1_FILE%"
    echo.

    echo Report generated on %DATE% at %TIME%
) > "%REPORT_FILE%"

echo Process change analysis complete! Check "%REPORT_FILE%"
echo.

:: Clean up temporary snapshot files
del "%SNAPSHOT1_FILE%" "%SNAPSHOT2_FILE%" > NUL 2>&1

:: Pause to keep window open
echo Press any key to exit...
pause > NUL

endlocal
