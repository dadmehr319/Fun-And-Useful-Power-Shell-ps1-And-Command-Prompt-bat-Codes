# Get-SystemInfo.ps1

<#
.SYNOPSIS
    Gathers basic system information.
.DESCRIPTION
    This script retrieves common system details such as operating system,
    CPU, RAM, and BIOS information.
.NOTES
    No administrative privileges are typically required for this script.
#>

Write-Host "--- Basic System Information ---" -ForegroundColor Green

# Get Operating System Information
Write-Host "`n-- Operating System --" -ForegroundColor Cyan
Get-CimInstance Win32_OperatingSystem | Select-Object Caption, OSArchitecture, @{Name="InstallDate"; Expression={$_.InstallDate.ToString("yyyy-MM-dd HH:mm:ss")}}, Version, BuildNumber | Format-List

# Get CPU Information
Write-Host "`n-- CPU Information --" -ForegroundColor Cyan
Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, CurrentClockSpeed | Format-List

# Get RAM Information
Write-Host "`n-- Memory (RAM) Information --" -ForegroundColor Cyan
$Memory = Get-CimInstance Win32_ComputerSystem
$TotalPhysicalMemoryGB = [math]::Round($Memory.TotalPhysicalMemory / 1GB, 2)
Write-Host "Total Physical Memory: $($TotalPhysicalMemoryGB) GB"
Get-CimInstance Win32_PhysicalMemory | Select-Object DeviceLocator, Capacity, Speed, Manufacturer | Format-List

# Get BIOS Information
Write-Host "`n-- BIOS Information --" -ForegroundColor Cyan
Get-CimInstance Win32_BIOS | Select-Object Manufacturer, SMBIOSBIOSVersion, ReleaseDate, Version | Format-List

# Get Disk Drive Information
Write-Host "`n-- Disk Drive Information --" -ForegroundColor Cyan
Get-CimInstance Win32_DiskDrive | Select-Object Model, Size, MediaType | Format-List

Write-Host "`n--- End of Basic System Information ---" -ForegroundColor Green
