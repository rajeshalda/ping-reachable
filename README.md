# Server Connectivity Monitor

A PowerShell script that continuously monitors server connectivity by performing periodic ping tests and logging results. Ideal for tracking network uptime, documenting connectivity issues, or proving server reachability over time.

## Features

- **Continuous Monitoring**: Automatically pings a target server at configurable intervals
- **Detailed Logging**: Records all ping results with timestamps to a log file
- **Real-time Statistics**: Displays success rates and uptime metrics every 10 pings
- **Response Time Tracking**: Logs response times for successful pings
- **Session Transcripts**: Captures complete console output for audit purposes
- **Color-coded Output**: Visual feedback with green (success) and red (failed) indicators
- **Configurable Parameters**: Customize target server, ping interval, and log locations

## Requirements

- Windows PowerShell 5.1 or later
- Network connectivity to test target server
- Appropriate permissions to create log files

## Usage

### Basic Usage

Run with default settings (pings Google DNS 8.8.8.8 every 5 seconds):

```powershell
.\Monitor-ServerConnectivity.ps1
```

### Custom Configuration

Specify your own server and settings:

```powershell
.\Monitor-ServerConnectivity.ps1 -ServerAddress "192.168.1.1" -IntervalSeconds 10 -LogPath "C:\Logs\network-log.txt"
```

### Parameters

| Parameter | Description | Default Value |
|-----------|-------------|---------------|
| `-ServerAddress` | Target server IP or hostname to monitor | `8.8.8.8` |
| `-IntervalSeconds` | Time between ping attempts (in seconds) | `5` |
| `-LogPath` | Path to connectivity log file | `.\connectivity-log.txt` |
| `-TranscriptPath` | Path to PowerShell transcript log | `.\transcript-log.txt` |

### Examples

Monitor your internal server:
```powershell
.\Monitor-ServerConnectivity.ps1 -ServerAddress "mail.company.com" -IntervalSeconds 30
```

Quick monitoring with custom log location:
```powershell
.\Monitor-ServerConnectivity.ps1 -ServerAddress "10.0.0.1" -LogPath "D:\Monitoring\server-status.log"
```

## Output

### Console Output

The script displays real-time status updates with:
- Timestamp for each ping attempt
- Success/failure status with response time
- Running statistics every 10 pings (total pings, success rate, uptime)

### Log Files

**Connectivity Log** (`connectivity-log.txt`):
- Header with monitoring configuration
- Timestamped entries for each ping result
- Response times for successful pings
- Final session statistics upon exit

**Transcript Log** (`transcript-log.txt`):
- Complete console output capture
- Useful for audit trails and troubleshooting

## Stopping the Monitor

Press `Ctrl+C` to stop monitoring. The script will automatically:
- Display final statistics
- Write session summary to log file
- Close the transcript log cleanly

## Use Cases

- **Network Troubleshooting**: Document intermittent connectivity issues
- **SLA Compliance**: Prove service availability for service level agreements
- **Maintenance Windows**: Verify server reachability during maintenance
- **Network Testing**: Monitor stability of network connections
- **Documentation**: Create timestamped proof of connectivity for audits

## Sample Output

```
========================================
Server Connectivity Monitor Started
========================================
Target Server: 8.8.8.8
Ping Interval: 5 seconds
Log File: .\connectivity-log.txt
Transcript File: .\transcript-log.txt
Press Ctrl+C to stop monitoring
========================================

[2025-11-07 12:45:30] SUCCESS - Ping to 8.8.8.8 successful (Response: 15ms)
[2025-11-07 12:45:35] SUCCESS - Ping to 8.8.8.8 successful (Response: 14ms)
[2025-11-07 12:45:40] SUCCESS - Ping to 8.8.8.8 successful (Response: 16ms)

--- Statistics ---
Total Pings: 10 | Success: 10 | Failed: 0 | Success Rate: 100%
Running Time: 0h 0m 50s
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

rajeshalda

## Contributing

Contributions, issues, and feature requests are welcome. Feel free to check the issues page or submit a pull request.
