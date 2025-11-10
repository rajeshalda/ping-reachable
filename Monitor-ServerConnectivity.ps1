# Server Connectivity Monitor
# Continuously pings a server and logs results for proof of connectivity

param(
    [string]$ServerAddress = "8.8.8.8",  # Default to Google DNS, change to your server
    [int]$IntervalSeconds = 5,            # Time between pings
    [string]$LogPath = ".\connectivity-log.txt",
    [string]$TranscriptPath = ".\transcript-log.txt"
)

# Start PowerShell transcript to capture all console output
Start-Transcript -Path $TranscriptPath -Append -Force

# Display configuration
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Server Connectivity Monitor Started" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Target Server: $ServerAddress" -ForegroundColor Yellow
Write-Host "Ping Interval: $IntervalSeconds seconds" -ForegroundColor Yellow
Write-Host "Log File: $LogPath" -ForegroundColor Yellow
Write-Host "Transcript File: $TranscriptPath" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

# Initialize log file with header
$logHeader = @"
========================================
Server Connectivity Monitoring Log
========================================
Target Server: $ServerAddress
Monitoring Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
========================================

"@
# Write header immediately with force flag
$logHeader | Out-File -FilePath $LogPath -Append -Force -Encoding UTF8

# Statistics counters
$totalPings = 0
$successfulPings = 0
$failedPings = 0
$startTime = Get-Date

# Uptime/Downtime tracking
$lastPingTime = Get-Date
$isCurrentlyUp = $true
$uptimeSeconds = 0
$downtimeSeconds = 0
$dailyStats = @{}

# Main monitoring loop
try {
    while ($true) {
        $currentTime = Get-Date
        $timestamp = $currentTime.ToString('yyyy-MM-dd HH:mm:ss')
        $dateKey = $currentTime.ToString('yyyy-MM-dd')
        $totalPings++

        # Initialize daily stats if not exists
        if (-not $dailyStats.ContainsKey($dateKey)) {
            $dailyStats[$dateKey] = @{
                TotalPings = 0
                SuccessfulPings = 0
                FailedPings = 0
                UptimeSeconds = 0
                DowntimeSeconds = 0
            }
        }

        # Calculate time elapsed since last ping
        $elapsedSeconds = ($currentTime - $lastPingTime).TotalSeconds

        # Perform ping test
        $pingResult = Test-Connection -ComputerName $ServerAddress -Count 1 -Quiet -ErrorAction SilentlyContinue

        if ($pingResult) {
            $successfulPings++
            $dailyStats[$dateKey].SuccessfulPings++
            $status = "SUCCESS"
            $color = "Green"
            $responseTime = (Test-Connection -ComputerName $ServerAddress -Count 1 -ErrorAction SilentlyContinue).ResponseTime
            $logEntry = "[$timestamp] $status - Ping to $ServerAddress successful (Response: ${responseTime}ms)"

            # Track uptime - add elapsed time to uptime
            $uptimeSeconds += $elapsedSeconds
            $dailyStats[$dateKey].UptimeSeconds += $elapsedSeconds
            $isCurrentlyUp = $true
        }
        else {
            $failedPings++
            $dailyStats[$dateKey].FailedPings++
            $status = "FAILED"
            $color = "Red"
            $logEntry = "[$timestamp] $status - Ping to $ServerAddress FAILED"

            # Track downtime - add elapsed time to downtime
            $downtimeSeconds += $elapsedSeconds
            $dailyStats[$dateKey].DowntimeSeconds += $elapsedSeconds
            $isCurrentlyUp = $false
        }

        $dailyStats[$dateKey].TotalPings++
        $lastPingTime = $currentTime

        # Write to console with color
        Write-Host $logEntry -ForegroundColor $color

        # Write to log file immediately (force flush to disk)
        $logEntry | Out-File -FilePath $LogPath -Append -Force -Encoding UTF8

        # Display running statistics every 10 pings
        if ($totalPings % 10 -eq 0) {
            $uptime = (Get-Date) - $startTime
            $successRate = [math]::Round(($successfulPings / $totalPings) * 100, 2)
            $totalUptimeHours = [math]::Round($uptimeSeconds / 3600, 2)
            $totalDowntimeHours = [math]::Round($downtimeSeconds / 3600, 2)
            $uptimePercentage = if (($uptimeSeconds + $downtimeSeconds) -gt 0) {
                [math]::Round(($uptimeSeconds / ($uptimeSeconds + $downtimeSeconds)) * 100, 2)
            } else { 100 }

            Write-Host "`n--- Statistics ---" -ForegroundColor Cyan
            Write-Host "Total Pings: $totalPings | Success: $successfulPings | Failed: $failedPings | Success Rate: $successRate%" -ForegroundColor Cyan
            Write-Host "Uptime: $totalUptimeHours hours | Downtime: $totalDowntimeHours hours | Availability: $uptimePercentage%" -ForegroundColor Cyan
            Write-Host "Running Time: $($uptime.Hours)h $($uptime.Minutes)m $($uptime.Seconds)s`n" -ForegroundColor Cyan
        }

        # Wait before next ping
        Start-Sleep -Seconds $IntervalSeconds
    }
}
finally {
    # Log session end and final statistics when script is stopped
    $endTime = Get-Date
    $duration = $endTime - $startTime
    $successRate = if ($totalPings -gt 0) { [math]::Round(($successfulPings / $totalPings) * 100, 2) } else { 0 }

    # Calculate final uptime/downtime
    $totalUptimeHours = [math]::Round($uptimeSeconds / 3600, 2)
    $totalDowntimeHours = [math]::Round($downtimeSeconds / 3600, 2)
    $totalUptimeDays = [math]::Round($uptimeSeconds / 86400, 2)
    $totalDowntimeDays = [math]::Round($downtimeSeconds / 86400, 2)
    $uptimePercentage = if (($uptimeSeconds + $downtimeSeconds) -gt 0) {
        [math]::Round(($uptimeSeconds / ($uptimeSeconds + $downtimeSeconds)) * 100, 2)
    } else { 100 }

    # Build daily breakdown report
    $dailyBreakdown = ""
    foreach ($day in ($dailyStats.Keys | Sort-Object)) {
        $dayData = $dailyStats[$day]
        $dayUptimeHours = [math]::Round($dayData.UptimeSeconds / 3600, 2)
        $dayDowntimeHours = [math]::Round($dayData.DowntimeSeconds / 3600, 2)
        $daySuccessRate = if ($dayData.TotalPings -gt 0) {
            [math]::Round(($dayData.SuccessfulPings / $dayData.TotalPings) * 100, 2)
        } else { 0 }
        $dayAvailability = if (($dayData.UptimeSeconds + $dayData.DowntimeSeconds) -gt 0) {
            [math]::Round(($dayData.UptimeSeconds / ($dayData.UptimeSeconds + $dayData.DowntimeSeconds)) * 100, 2)
        } else { 100 }

        $dailyBreakdown += @"
  $day
    Total Pings: $($dayData.TotalPings)
    Successful: $($dayData.SuccessfulPings) | Failed: $($dayData.FailedPings)
    Success Rate: $daySuccessRate%
    Uptime: $dayUptimeHours hours | Downtime: $dayDowntimeHours hours
    Availability: $dayAvailability%

"@
    }

    $finalStats = @"

========================================
Monitoring Session Ended: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
========================================
Total Duration: $($duration.Days) days, $($duration.Hours)h $($duration.Minutes)m $($duration.Seconds)s
Total Pings: $totalPings
Successful: $successfulPings
Failed: $failedPings
Success Rate: $successRate%

========================================
UPTIME/DOWNTIME SUMMARY
========================================
Total Uptime: $totalUptimeHours hours ($totalUptimeDays days)
Total Downtime: $totalDowntimeHours hours ($totalDowntimeDays days)
Availability: $uptimePercentage%

========================================
DAILY BREAKDOWN
========================================
$dailyBreakdown
========================================

"@

    # Write final statistics to log file immediately
    $finalStats | Out-File -FilePath $LogPath -Append -Force -Encoding UTF8

    # Generate manager report
    $reportPath = ".\Weekly-Report-$ServerAddress-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    $managerReport = @"
========================================
WEEKLY SERVER CONNECTIVITY REPORT
========================================
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Report Period: $(Get-Date $startTime -Format 'yyyy-MM-dd HH:mm:ss') to $(Get-Date $endTime -Format 'yyyy-MM-dd HH:mm:ss')
Server Address: $ServerAddress

========================================
EXECUTIVE SUMMARY
========================================
Monitoring Duration: $($duration.Days) days, $($duration.Hours) hours, $($duration.Minutes) minutes
Total Uptime: $totalUptimeHours hours ($totalUptimeDays days)
Total Downtime: $totalDowntimeHours hours ($totalDowntimeDays days)
Overall Availability: $uptimePercentage%

========================================
CONNECTIVITY METRICS
========================================
Total Connection Tests: $totalPings
Successful Connections: $successfulPings
Failed Connections: $failedPings
Success Rate: $successRate%

========================================
DAILY BREAKDOWN
========================================
$dailyBreakdown
========================================
END OF REPORT
========================================
"@

    $managerReport | Out-File -FilePath $reportPath -Force -Encoding UTF8

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Monitoring Stopped" -ForegroundColor Cyan
    Write-Host $finalStats -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Weekly Report Generated: $reportPath" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green

    # Stop transcript recording
    Stop-Transcript
}
