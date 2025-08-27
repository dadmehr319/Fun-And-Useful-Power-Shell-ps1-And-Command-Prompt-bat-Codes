@echo off
setlocal enabledelayedexpansion

:: ===============================================================
:: Check-RecentFiles-CommandPrompt.bat
:: Monitors recent file activity in a specified directory.
:: Asks the user how many days back to check (default: 7 days).
:: ===============================================================

:: -------------------- Configuration --------------------
set "TARGET_DIR=%USERPROFILE%\Downloads"
set "DEFAULT_DAYS_BACK=7"
set "OUTPUT_FILE=RecentFiles_Report.txt"

:: -------------------- Header --------------------
echo.
echo =========================================
echo      Recent File Activity Monitor
echo =========================================
echo.

:: -------------------- Ask user for days back --------------------
set /p DAYS_BACK="Enter number of days to look back (default %DEFAULT_DAYS_BACK%): "
if "%DAYS_BACK%"=="" set DAYS_BACK=%DEFAULT_DAYS_BACK%

echo Checking directory: %TARGET_DIR%
echo For files modified in the last %DAYS_BACK% days.
echo Output will be saved to: %OUTPUT_FILE%
echo.

:: -------------------- Check if directory exists --------------------
if not exist "%TARGET_DIR%" (
    echo Error: Target directory "%TARGET_DIR%" does not exist.
    echo Please edit the script to set TARGET_DIR to a valid path.
    pause
    goto :eof
)

:: -------------------- Generate cutoff date --------------------
for /f "tokens=*" %%a in ('powershell -command "& { (Get-Date).AddDays(-%DAYS_BACK%) }"') do set "CUTOFF_DATE=%%a"

:: -------------------- Generate report --------------------
echo Generating report...
(
    echo Recent Files Modified in "%TARGET_DIR%" (Last %DAYS_BACK% Days)
    echo -------------------------------------------------------------
    echo.

    powershell -command "& {
        Get-ChildItem -Path '%TARGET_DIR%' -Recurse -File |
        Where-Object { $_.LastWriteTime -ge (Get-Date '%CUTOFF_DATE%') } |
        Sort-Object LastWriteTime -Descending |
        Select-Object LastWriteTime, FullName |
        Format-Table -AutoSize
    }"

    echo.
    echo Report generated on %DATE% at %TIME%
) > "%OUTPUT_FILE%"

echo Report complete! Check "%OUTPUT_FILE%"
echo.

:: -------------------- Pause at the end --------------------
echo Press any key to exit...
pause > NUL

endlocal
