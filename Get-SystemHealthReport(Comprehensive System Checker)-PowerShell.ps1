# Get-SystemHealthReport.ps1

<#
.SYNOPSIS
    Generates a comprehensive system health and information report.
.DESCRIPTION
    This script gathers a wide array of system data, including
    OS details, hardware information (CPU, RAM, Disks), network status,
    running processes, service health, recent event log errors,
    and security software status. It attempts to get CPU temperature
    via WMI, though support for this varies by hardware.
.NOTES
    Running this script with Administrator privileges is strongly recommended
    for full access to all system information, especially for disk health,
    security software status, and detailed event log analysis.
#>

# Function to write section headers
function Write-SectionHeader {
    param(
        [string]$Title
    )
    Write-Host "`n=================================================" -ForegroundColor DarkGreen
    Write-Host "     $Title" -ForegroundColor Green
    Write-Host "=================================================" -ForegroundColor DarkGreen
}

# Check for Administrator Privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script recommends running with Administrator privileges for full functionality."
    Write-Host "Some information (e.g., detailed security software status, certain hardware details) may be limited."
    Start-Sleep -Seconds 2
}

# Clear the console for better readability

Write-Host "Starting System Health Report Generation..." -ForegroundColor Yellow

# --- Section 1: System Overview ---
Write-SectionHeader "System Overview"

Write-Host "`n-- Operating System --" -ForegroundColor Cyan
Get-CimInstance Win32_OperatingSystem | Select-Object Caption, OSArchitecture, @{Name="InstallDate"; Expression={$_.InstallDate.ToString("yyyy-MM-dd HH:mm:ss")}}, Version, BuildNumber | Format-List

Write-Host "`n-- Computer Information --" -ForegroundColor Cyan
Get-CimInstance Win32_ComputerSystem | Select-Object Name, Manufacturer, Model, Domain, UserName, TotalPhysicalMemory | Format-List

Write-Host "`n-- CPU Information --" -ForegroundColor Cyan
Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed | Format-List

Write-Host "`n-- BIOS Information --" -ForegroundColor Cyan
Get-CimInstance Win32_BIOS | Select-Object Manufacturer, SMBIOSBIOSVersion, ReleaseDate | Format-List

# --- Section 2: Memory (RAM) ---
Write-SectionHeader "Memory (RAM) Information"

Write-Host "`n-- Physical Memory Modules --" -ForegroundColor Cyan
Get-CimInstance Win32_PhysicalMemory | Select-Object DeviceLocator, Capacity, Speed, Manufacturer, PartNumber | Format-List

# --- Section 3: Disk Drive Information and Health ---
Write-SectionHeader "Disk Drives & Storage"

Write-Host "`n-- Logical Disk Usage --" -ForegroundColor Cyan
Get-CimInstance Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} | Select-Object DeviceID, VolumeName, FileSystem, @{Name="SizeGB"; Expression={[math]::Round($_.Size / 1GB, 2)}}, @{Name="FreeSpaceGB"; Expression={[math]::Round($_.FreeSpace / 1GB, 2)}}, @{Name="FreeSpace%"; Expression={[math]::Round(($_.FreeSpace / $_.Size) * 100, 2)}} | Format-Table -AutoSize

Write-Host "`n-- Physical Disk Drives --" -ForegroundColor Cyan
Get-CimInstance Win32_DiskDrive | Select-Object Model, MediaType, Size, Partitions, Status | Format-List

# Attempt to get SMART status (requires admin)
Write-Host "`n-- Disk Drive Health (SMART Status - if available) --" -ForegroundColor Cyan
try {
    Get-CimInstance -Namespace ROOT\WMI -ClassName MSStorageDriver_FailurePredictStatus | Select-Object InstanceName, PredictFailure, Reason | Format-Table -AutoSize
    if (-not $?) { Write-Warning "SMART status not available via WMI on this system or insufficient permissions." }
} catch {
    Write-Warning "Could not retrieve SMART status: $($_.Exception.Message)"
}

# --- Section 4: Network Information ---
Write-SectionHeader "Network Status"

Write-Host "`n-- Network Adapters --" -ForegroundColor Cyan
Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object {$_.IPAddress} | Select-Object Description, IPAddress, IPSubnet, DefaultIPGateway, DNSHostName, MACAddress | Format-List

Write-Host "`n-- Internet Connectivity Test --" -ForegroundColor Cyan
try {
    $pingResult = Test-Connection -ComputerName "google.com" -Count 1 -ErrorAction SilentlyContinue
    if ($pingResult) {
        Write-Host "Internet Connectivity: OK (Ping to google.com successful)" -ForegroundColor Green
    } else {
        Write-Warning "Internet Connectivity: Failed (Could not ping google.com)"
    }
} catch {
    Write-Warning "Could not perform internet connectivity test: $($_.Exception.Message)"
}

# --- Section 5: CPU Temperature (Tentative) ---
Write-SectionHeader "CPU Temperature (Attempt)"
Write-Host "`n-- Current CPU Temperature --" -ForegroundColor Cyan
try {
    # This WMI class is not universally supported or reliable for CPU temperatures
    $tempSensor = Get-CimInstance -Namespace root\wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
    if ($tempSensor) {
        foreach ($sensor in $tempSensor) {
            $celsius = ($sensor.CurrentTemperature - 2732) / 10.0
            $fahrenheit = ($celsius * 9/5) + 32
            Write-Host "Current Temperature: $($celsius.ToString("F2")) °C / $($fahrenheit.ToString("F2")) °F" -ForegroundColor Green
        }
    } else {
        Write-Warning "CPU temperature data not found via standard WMI thermal zone."
        Write-Warning "This is common on many modern systems. Consider specialized tools for accurate readings."
    }
} catch {
    Write-Error "Could not retrieve CPU temperature: $($_.Exception.Message)"
    Write-Warning "CPU temperature via WMI (MSAcpi_ThermalZoneTemperature) is not universally supported."
}

# --- Section 6: Running Processes & Services ---
Write-SectionHeader "Processes & Services"

Write-Host "`n-- Top 10 Processes by CPU Usage --" -ForegroundColor Cyan
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 Name, Id, CPU, WorkingSet | Format-Table -AutoSize

Write-Host "`n-- Top 10 Processes by Memory Usage (WorkingSet) --" -ForegroundColor Cyan
Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10 Name, Id, CPU, WorkingSet | Format-Table -AutoSize

Write-Host "`n-- Critical Services Status (Examples) --" -ForegroundColor Cyan
$criticalServices = @("wuauserv", "bits", "SvcHost", "Dnscache", "Dhcp") # Windows Update, BITS, Service Host, DNS Client, DHCP Client
foreach ($serviceName in $criticalServices) {
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($service) {
        Write-Host "Service '$($service.DisplayName)': $($service.Status)"
    } else {
        Write-Warning "Service '$serviceName' not found."
    }
}

# --- Section 7: Event Log Analysis (Recent Errors) ---
Write-SectionHeader "Recent Event Log Errors"

Write-Host "`n-- Last 20 Errors from System Log (Last 24 Hours) --" -ForegroundColor Cyan
try {
    Get-WinEvent -LogName System -MaxEvents 20 -ErrorAction SilentlyContinue | Where-Object {$_.LevelDisplayName -eq "Error" -and $_.TimeCreated -gt (Get-Date).AddHours(-24)} | Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, Message | Format-Table -AutoSize -Wrap
    if (-not $?) { Write-Host "No System log errors found in the last 24 hours or no access." }
} catch {
    Write-Warning "Could not retrieve System event log errors: $($_.Exception.Message)"
}

Write-Host "`n-- Last 20 Errors from Application Log (Last 24 Hours) --" -ForegroundColor Cyan
try {
    Get-WinEvent -LogName Application -MaxEvents 20 -ErrorAction SilentlyContinue | Where-Object {$_.LevelDisplayName -eq "Error" -and $_.TimeCreated -gt (Get-Date).AddHours(-24)} | Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, Message | Format-Table -AutoSize -Wrap
    if (-not $?) { Write-Host "No Application log errors found in the last 24 hours or no access." }
} catch {
    Write-Warning "Could not retrieve Application event log errors: $($_.Exception.Message)"
}

# --- Section 8: Security Software Status ---
Write-SectionHeader "Security Software Status"

Write-Host "`n-- Antivirus Status --" -ForegroundColor Cyan
try {
    $antivirus = Get-CimInstance -Namespace root\SecurityCenter2 -ClassName AntiVirusProduct -ErrorAction SilentlyContinue
    if ($antivirus) {
        foreach ($av in $antivirus) {
            Write-Host "Product: $($av.displayName)"
            Write-Host "Status: $(if ($av.productState -band 0x100000) {"Up To Date"} else {"Outdated"}), $(if ($av.productState -band 0x1000) {"Real-time Protection Enabled"} else {"Real-time Protection Disabled"})"
        }
    } else {
        Write-Warning "Antivirus product information not found via SecurityCenter2."
    }
} catch {
    Write-Warning "Could not retrieve Antivirus status: $($_.Exception.Message)"
}

Write-Host "`n-- Firewall Status --" -ForegroundColor Cyan
try {
    $firewall = Get-CimInstance -Namespace root\SecurityCenter2 -ClassName FirewallProduct -ErrorAction SilentlyContinue
    if ($firewall) {
        foreach ($fw in $firewall) {
            Write-Host "Product: $($fw.displayName)"
            Write-Host "Status: $(if ($fw.productState -band 0x100000) {"Enabled"} else {"Disabled"})"
        }
    } else {
        Write-Warning "Firewall product information not found via SecurityCenter2."
    }
} catch {
    Write-Warning "Could not retrieve Firewall status: $($_.Exception.Message)"
}

Write-Host "`nSystem Health Report Complete!" -ForegroundColor Yellow