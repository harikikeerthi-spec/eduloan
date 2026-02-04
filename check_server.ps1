$maxRetries = 30
$retryCount = 0
$url = "http://localhost:3000/ai/convert-grades"

while ($retryCount -lt $maxRetries) {
    try {
        $response = Invoke-WebRequest -Uri $url -Method Post -Body '{"inputType":"percentage","inputValue":90,"outputType":"percentage"}' -ContentType "application/json" -ErrorAction Stop
        Write-Host "Server is UP! Code: $($response.StatusCode)"
        exit 0
    } catch {
        if ($_.Exception.Response.StatusCode -eq 400 -or $_.Exception.Response.StatusCode -eq 200 -or $_.Exception.Response.StatusCode -eq 201) {
             Write-Host "Server is UP! (Reached endpoint). Code: $($_.Exception.Response.StatusCode)"
             exit 0
        }
        Write-Host "Waiting for server... Attempt $($retryCount + 1)"
        Start-Sleep -Seconds 2
        $retryCount++
    }
}
Write-Host "Server failed to start."
exit 1
