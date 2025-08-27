# =================================================================================================
#  Get-AdvancedSystemInfo (Detailed System Checker) - PowerShell
# =================================================================================================
<#
.SYNOPSIS
    Gathers advanced system information including a
    tentative attempt at CPU temperature.

.DESCRIPTION
    This script retrieves detailed system information:
      • CPU temperature (tentative WMI-based attempt)
      • Network adapter details
      • Logical disk information
      • Installed programs (Top 10 by name)
      • Running processes (Top 10 by CPU usage)

    ⚠️ Administrative privileges are highly recommended for:
        - CPU temperature readings
        - Full hardware details

.NOTES
    CPU temperature via WMI (MSAcpi_ThermalZoneTemperature) is not
    universally supported or reliable across all hardware.
    For more accurate CPU temperature, consider vendor-specific tools
    or third-party utilities.

    Author:   Your Name
    Version:  1.0
    Script:   Get-AdvancedSystemInfo (Detailed System Checker)
#>
# =================================================================================================


# --------------------------- Helper Function ---------------------------
function Write-SectionHeader {
    param([string]$Title)
    Write-Host "`n================================================================================" -ForegroundColor DarkGreen
    Write-Host ("     {0}" -f $Title) -ForegroundColor Green
    Write-Host "================================================================================" -ForegroundColor DarkGreen
}

# --------------------------- Admin Check ---------------------------
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Write-Warning "[Warn] It is recommended to run this script as Administrator for complete results."
    Start-Sleep -Seconds 2
}

# --------------------------- Script Start ---------------------------
Write-Host "`n[Start] Running Advanced System Information..." -ForegroundColor Yellow


# =================================================================================================
#  Section 1: CPU Temperature (Tentative)
# =================================================================================================
Write-SectionHeader "CPU Temperature (Tentative)"
try {
    $tempSensor = Get-CimInstance -Namespace root\wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
    if ($tempSensor) {
        foreach ($sensor in $tempSensor) {
            $celsius = ($sensor.CurrentTemperature - 2732) / 10.0
            $fahrenheit = ($celsius * 9/5) + 32
            Write-Host "[Temp] Current Temperature: $($celsius.ToString("F2")) °C / $($fahrenheit.ToString("F2")) °F" -ForegroundColor Green
        }
    } else {
        Write-Warning "[Warn] CPU temperature data not found via WMI (common on many systems)."
    }
} catch {
    Write-Error "[Error] Could not retrieve CPU temperature: $($_.Exception.Message)"
    Write-Warning "[Warn] CPU temperature via WMI is not universally supported."
}


# =================================================================================================
#  Section 2: Network Adapter Information
# =================================================================================================
Write-SectionHeader "Network Adapter Information"

Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object {$_.IPAddress} |
    Select-Object Description, IPAddress, IPSubnet, DefaultIPGateway, DNSHostName | Format-List


# =================================================================================================
#  Section 3: Logical Disk Information
# =================================================================================================
Write-SectionHeader "Logical Disk Information"

Get-CimInstance Win32_LogicalDisk |
    Select-Object DeviceID, VolumeName, FileSystem, 
        @{Name="FreeSpaceGB"; Expression={[math]::Round($_.FreeSpace / 1GB, 2)}},
        @{Name="SizeGB"; Expression={[math]::Round($_.Size / 1GB, 2)}} |
    Format-Table -AutoSize


# =================================================================================================
#  Section 4: Installed Programs (Top 10)
# =================================================================================================
Write-SectionHeader "Installed Programs (Top 10 by Name)"

Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
    Sort-Object DisplayName |
    Select-Object -First 10 |
    Format-Table -AutoSize


# =================================================================================================
#  Section 5: Running Processes
# =================================================================================================
Write-SectionHeader "Top 10 Running Processes by CPU Usage"

Get-Process | Sort-Object CPU -Descending |
    Select-Object -First 10 Name, Id, CPU, 
        @{Name="MemoryMB"; Expression={[math]::Round($_.WorkingSet / 1MB, 2)}} |
    Format-Table -AutoSize


# =================================================================================================
#  Script End
# =================================================================================================
Write-Host "`n[Done] Advanced System Information Complete!" -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor DarkGreen

# === Keep window open until manually closed ===
Write-Host "`nPress Enter to close this window, or just click the X (top right)." -ForegroundColor Yellow
Read-Host
