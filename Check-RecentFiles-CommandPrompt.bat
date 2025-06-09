@echo off
setlocal

:: Check-RecentFiles.bat
:: Monitors recent file activity in a specified directory.
:: Displays files modified within the last N days (default: 7 days).

set "TARGET_DIR=%USERPROFILE%\Downloads"
set "DAYS_BACK=7"
set "OUTPUT_FILE=RecentFiles_Report.txt"

echo.
echo =========================================
echo  Recent File Activity Monitor
echo =========================================
echo.
echo Checking directory: %TARGET_DIR%
echo For files modified in the last %DAYS_BACK% days.
echo Output will be saved to: %OUTPUT_FILE%
echo.

if not exist "%TARGET_DIR%" (
    echo Error: Target directory "%TARGET_DIR%" does not exist.
    echo Please edit the script to set TARGET_DIR to a valid path.
    goto :eof
)

echo Generating report...
echo Recent Files Modified in "%TARGET_DIR%" (Last %DAYS_BACK% Days) > "%OUTPUT_FILE%"
echo ------------------------------------------------------------- >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"

for /f "tokens=*" %%a in ('powershell -command "& { (Get-Date).AddDays(-%DAYS_BACK%) }"') do set "CUTOFF_DATE=%%a"

:: Use PowerShell embedded in batch for advanced date filtering, as pure batch is hard for this.
:: This finds files in the target directory that were last written after the cutoff date.
powershell -command "& { Get-ChildItem -Path '%TARGET_DIR%' -Recurse -File | Where-Object { $_.LastWriteTime -ge (Get-Date '%CUTOFF_DATE%') } | Sort-Object LastWriteTime -Descending | Select-Object LastWriteTime, FullName | Format-Table -AutoSize }" >> "%OUTPUT_FILE%"

echo. >> "%OUTPUT_FILE%"
echo Report generated on %DATE% at %TIME% >> "%OUTPUT_FILE%"
echo.
echo Report complete! Check "%OUTPUT_FILE%"
echo.
pause
endlocal