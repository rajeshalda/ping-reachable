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

# Main monitoring loop
try {
    while ($true) {
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $totalPings++

        # Perform ping test
        $pingResult = Test-Connection -ComputerName $ServerAddress -Count 1 -Quiet -ErrorAction SilentlyContinue

        if ($pingResult) {
            $successfulPings++
            $status = "SUCCESS"
            $color = "Green"
            $responseTime = (Test-Connection -ComputerName $ServerAddress -Count 1 -ErrorAction SilentlyContinue).ResponseTime
            $logEntry = "[$timestamp] $status - Ping to $ServerAddress successful (Response: ${responseTime}ms)"
        }
        else {
            $failedPings++
            $status = "FAILED"
            $color = "Red"
            $logEntry = "[$timestamp] $status - Ping to $ServerAddress FAILED"
        }

        # Write to console with color
        Write-Host $logEntry -ForegroundColor $color

        # Write to log file immediately (force flush to disk)
        $logEntry | Out-File -FilePath $LogPath -Append -Force -Encoding UTF8

        # Display running statistics every 10 pings
        if ($totalPings % 10 -eq 0) {
            $uptime = (Get-Date) - $startTime
            $successRate = [math]::Round(($successfulPings / $totalPings) * 100, 2)
            Write-Host "`n--- Statistics ---" -ForegroundColor Cyan
            Write-Host "Total Pings: $totalPings | Success: $successfulPings | Failed: $failedPings | Success Rate: $successRate%" -ForegroundColor Cyan
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

    $finalStats = @"

========================================
Monitoring Session Ended: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
========================================
Total Duration: $($duration.Hours)h $($duration.Minutes)m $($duration.Seconds)s
Total Pings: $totalPings
Successful: $successfulPings
Failed: $failedPings
Success Rate: $successRate%
========================================

"@

    # Write final statistics to log file immediately
    $finalStats | Out-File -FilePath $LogPath -Append -Force -Encoding UTF8

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Monitoring Stopped" -ForegroundColor Cyan
    Write-Host $finalStats -ForegroundColor Yellow

    # Stop transcript recording
    Stop-Transcript
}
