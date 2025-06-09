# Get-AdvancedSystemInfo.ps1

<#
.SYNOPSIS
    Gathers advanced system information including a
    tentative attempt at CPU temperature.
.DESCRIPTION
    This script retrieves detailed system information,
    including network adapter details, installed programs,
    and attempts to read CPU temperature via WMI.
    Administrative privileges are highly recommended for full access.
.NOTES
    CPU temperature via WMI (MSAcpi_ThermalZoneTemperature) is not
    universally supported or reliable across all hardware.
    For more accurate CPU temperature, consider vendor-specific tools
    or third-party utilities.
#>

# Check for Administrator Privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script recommends running with Administrator privileges for full functionality, especially for CPU temperature and detailed hardware info."
    Start-Sleep -Seconds 2
}

Write-Host "--- Advanced System Information ---" -ForegroundColor Green

# Get CPU Temperature (Attempt using WMI - may not work on all systems)
Write-Host "`n-- CPU Temperature (Tentative) --" -ForegroundColor Cyan
try {
    $tempSensor = Get-CimInstance -Namespace root\wmi -ClassName MSAcpi_ThermalZoneTemperature
    if ($tempSensor) {
        foreach ($sensor in $tempSensor) {
            # Convert Kelvin to Celsius and Fahrenheit
            $celsius = ($sensor.CurrentTemperature - 2732) / 10.0
            $fahrenheit = ($celsius * 9/5) + 32
            Write-Host "Current Temperature: $($celsius.ToString("F2")) °C / $($fahrenheit.ToString("F2")) °F"
        }
    } else {
        Write-Warning "CPU temperature data not found via standard WMI thermal zone. This is common on many systems."
    }
} catch {
    Write-Error "Could not retrieve CPU temperature: $($_.Exception.Message)"
    Write-Warning "CPU temperature via WMI (MSAcpi_ThermalZoneTemperature) is not universally supported."
}

# Get Detailed Network Adapter Information
Write-Host "`n-- Network Adapter Information --" -ForegroundColor Cyan
Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object {$_.IPAddress} | Select-Object Description, IPAddress, IPSubnet, DefaultIPGateway, DNSHostName | Format-List

# Get Logical Disk Information
Write-Host "`n-- Logical Disk Information --" -ForegroundColor Cyan
Get-CimInstance Win32_LogicalDisk | Select-Object DeviceID, VolumeName, FileSystem, FreeSpace, Size | Format-List

# Get Installed Programs (from Add/Remove Programs)
Write-Host "`n-- Installed Programs (Top 10) --" -ForegroundColor Cyan
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Sort-Object DisplayName | Select-Object -First 10 | Format-Table -AutoSize

# Get Running Processes
Write-Host "`n-- Top 10 Running Processes by CPU Usage --" -ForegroundColor Cyan
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 Name, Id, CPU, WorkingSet | Format-Table -AutoSize

Write-Host "`n--- End of Advanced System Information ---" -ForegroundColor Green
