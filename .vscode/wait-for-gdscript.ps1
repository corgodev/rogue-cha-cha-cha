param(
    [int]$Port = 6008,
    [int]$TimeoutSeconds = 30
)

$ErrorActionPreference = 'Stop'
$timer = [System.Diagnostics.Stopwatch]::StartNew()

# Inspect listeners without connecting: a probe connection would be mistaken
# for the game by the Godot Tools debug adapter.
do {
    $listeners = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners()
    if ($listeners | Where-Object { $_.Port -eq $Port -and $_.Address.ToString() -eq '127.0.0.1' }) {
        Write-Output "GDScript debugger is listening on port $Port."
        exit 0
    }
    Start-Sleep -Milliseconds 100
} while ($timer.Elapsed.TotalSeconds -lt $TimeoutSeconds)

Write-Error "GDScript debugger did not start on port $Port. Start a combined C# + GDScript launch configuration and check the Godot Tools output."
exit 1
