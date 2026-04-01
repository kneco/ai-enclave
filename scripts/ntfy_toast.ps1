# ntfy_toast.ps1 - Windows Toast notification receiver for ntfy.sh
# Subscribes to ntfy.sh stream and displays Windows toast notifications
# Usage: powershell -ExecutionPolicy Bypass -File ntfy_toast.ps1
# Stop: Ctrl+C
# Requires: PowerShell 5.1+ / Windows 10+ (WinRT Toast API)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Read ntfy_topic from config/settings.yaml ---
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Split-Path -Parent $ScriptDir
$SettingsPath = Join-Path $RepoRoot "config\settings.yaml"

if (-not (Test-Path $SettingsPath)) {
    Write-Error "config/settings.yaml not found: $SettingsPath"
    exit 1
}

$SettingsContent = Get-Content $SettingsPath -Raw
$TopicMatch = [regex]::Match($SettingsContent, "ntfy_topic:\s*[`"']?([^`"'\r\n]+)[`"']?")
if (-not $TopicMatch.Success) {
    Write-Error "ntfy_topic is not set in config/settings.yaml`nExample: ntfy_topic: `"your-random-topic`""
    exit 1
}
$Topic = $TopicMatch.Groups[1].Value.Trim()

Write-Host "Shogun-fu Toast Receiver started" -ForegroundColor Cyan
Write-Host "ntfy topic: $Topic" -ForegroundColor Gray
Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host ""

# --- WinRT Toast API init ---
Add-Type -AssemblyName System.Runtime.WindowsRuntime

$null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
$null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType = WindowsRuntime]

function Show-ToastNotification {
    param(
        [string]$Title,
        [string]$Body
    )
    try {
        $AppId = "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"

        $XmlTemplate = @"
<toast>
  <visual>
    <binding template="ToastText02">
      <text id="1">$([System.Security.SecurityElement]::Escape($Title))</text>
      <text id="2">$([System.Security.SecurityElement]::Escape($Body))</text>
    </binding>
  </visual>
</toast>
"@
        $XmlDoc = New-Object Windows.Data.Xml.Dom.XmlDocument
        $XmlDoc.LoadXml($XmlTemplate)

        $Toast = [Windows.UI.Notifications.ToastNotification]::new($XmlDoc)
        $Notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppId)
        $Notifier.Show($Toast)
    }
    catch {
        Write-Warning "Failed to show toast: $_"
    }
}

# --- ntfy stream subscription loop ---
$StreamUrl = "https://ntfy.sh/$Topic/json"
$ReconnectDelaySec = 5

while ($true) {
    try {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Connecting: $StreamUrl" -ForegroundColor DarkGray

        $Request = [System.Net.HttpWebRequest]::Create($StreamUrl)
        $Request.Method = "GET"
        $Request.Timeout = -1
        $Request.ReadWriteTimeout = -1
        $Request.Accept = "application/x-ndjson"

        $Response = $Request.GetResponse()
        $Stream   = $Response.GetResponseStream()
        $Reader   = New-Object System.IO.StreamReader($Stream, [System.Text.Encoding]::UTF8)

        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Connected. Waiting for notifications..." -ForegroundColor Green

        while (-not $Reader.EndOfStream) {
            $Line = $Reader.ReadLine()
            if ([string]::IsNullOrWhiteSpace($Line)) { continue }

            try {
                $Msg = $Line | ConvertFrom-Json

                if ($Msg.event -ne "message") { continue }

                # outbound tags are not filtered - toast receives all messages

                $MsgTitle = if ($Msg.PSObject.Properties['title'] -and $Msg.title) { $Msg.title } else { "Shogun-fu" }
                $MsgBody  = if ($Msg.PSObject.Properties['message'] -and $Msg.message) { $Msg.message } else { "(no body)" }

                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Received: $MsgBody" -ForegroundColor Yellow
                Show-ToastNotification -Title $MsgTitle -Body $MsgBody
            }
            catch {
                Write-Warning "Failed to parse message: $_"
                Write-Warning "Raw line: $Line"
            }
        }

        $Reader.Close()
        $Response.Close()
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Connection closed. Reconnecting in ${ReconnectDelaySec}s..." -ForegroundColor DarkYellow
    }
    catch [System.Threading.ThreadAbortException] {
        Write-Host "`nStopping." -ForegroundColor Cyan
        break
    }
    catch {
        Write-Warning "[$(Get-Date -Format 'HH:mm:ss')] Error: $_"
        Write-Host "Reconnecting in ${ReconnectDelaySec}s..." -ForegroundColor DarkYellow
    }

    Start-Sleep -Seconds $ReconnectDelaySec
}
