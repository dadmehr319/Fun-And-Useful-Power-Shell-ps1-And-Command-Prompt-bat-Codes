# =================================================================================================
#  Get-SystemInfo (Basic System Checker) - PowerShell
# =================================================================================================
<#
.SYNOPSIS
    Gathers basic system information.

.DESCRIPTION
    This script retrieves common system details:
      • Operating system details
      • CPU information
      • Memory (RAM) info
      • BIOS details
      • Disk drive information

    No administrative privileges are typically required.

.NOTES
    Author:   Your Name
    Version:  1.3 (With Read-Host pause)
    Script:   Get-SystemInfo (Basic System Checker)
#>
# =================================================================================================


# --------------------------- Helper Function ---------------------------
function Write-SectionHeader {
    param([string]$Title)
    Write-Host "`n================================================================================" -ForegroundColor DarkGreen
    Write-Host ("     {0}" -f $Title) -ForegroundColor Green
    Write-Host "================================================================================" -ForegroundColor DarkGreen
}


# --------------------------- Script Start ---------------------------
Write-Host "`n[Start] Running Basic System Information..." -ForegroundColor Yellow


# =================================================================================================
#  Section 1: Operating System Information
# =================================================================================================
Write-SectionHeader "Operating System Information"

Get-CimInstance Win32_OperatingSystem | 
    Select-Object Caption, OSArchitecture, 
        @{Name="InstallDate"; Expression={$_.InstallDate.ToString("yyyy-MM-dd HH:mm:ss")}}, 
        Version, BuildNumber | Format-List


# =================================================================================================
#  Section 2: CPU Information
# =================================================================================================
Write-SectionHeader "CPU Information"

Get-CimInstance Win32_Processor | 
    Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, CurrentClockSpeed | Format-List


# =================================================================================================
#  Section 3: Memory (RAM) Information
# =================================================================================================
Write-SectionHeader "Memory (RAM) Information"

$Memory = Get-CimInstance Win32_ComputerSystem
$TotalPhysicalMemoryGB = [math]::Round($Memory.TotalPhysicalMemory / 1GB, 2)
Write-Host "[RAM] Total Physical Memory: $($TotalPhysicalMemoryGB) GB" -ForegroundColor Green

Get-CimInstance Win32_PhysicalMemory | 
    Select-Object DeviceLocator, 
                  @{Name="CapacityGB"; Expression={[math]::Round($_.Capacity / 1GB, 2)}}, 
                  Speed, Manufacturer | Format-Table -AutoSize


# =================================================================================================
#  Section 4: BIOS Information
# =================================================================================================
Write-SectionHeader "BIOS Information"

Get-CimInstance Win32_BIOS | 
    Select-Object Manufacturer, SMBIOSBIOSVersion, ReleaseDate, Version | Format-List


# =================================================================================================
#  Section 5: Disk Drive Information
# =================================================================================================
Write-SectionHeader "Disk Drive Information"

Get-CimInstance Win32_DiskDrive | 
    Select-Object Model, 
                  @{Name="SizeGB"; Expression={[math]::Round($_.Size / 1GB, 2)}}, 
                  MediaType | Format-Table -AutoSize


# =================================================================================================
#  Script End
# =================================================================================================
Write-Host "`n[Done] Basic System Information Complete!" -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor DarkGreen

# --------------------------- Keep Window Open ---------------------------
Write-Host "`nPress Enter to close this window..." -ForegroundColor Yellow
Read-Host
