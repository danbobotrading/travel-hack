# API Debug Script
Write-Host "TravelPayouts API Debug" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Green
Write-Host ""

try {
    $apiUrl = "http://api.travelpayouts.com/data/en/airports.json"
    Write-Host "Fetching from: $apiUrl" -ForegroundColor White
    
    $response = Invoke-RestMethod -Uri $apiUrl -Method Get -TimeoutSec 30
    
    Write-Host "✅ API call successful!" -ForegroundColor Green
    Write-Host "Total items: $($response.Count)" -ForegroundColor White
    
    # Show first 10 items to understand structure
    Write-Host "`nFirst 10 items from API:" -ForegroundColor Yellow
    
    for ($i = 0; $i -lt [math]::Min(10, $response.Count); $i++) {
        $item = $response[$i]
        Write-Host "Item $i:" -ForegroundColor Cyan
        Write-Host "  Code: $($item.code)" -ForegroundColor White
        Write-Host "  Name: $($item.name)" -ForegroundColor White
        Write-Host "  City: $($item.city_name)" -ForegroundColor White
        Write-Host "  Country: $($item.country_code)" -ForegroundColor White
        Write-Host "  Type: $($item.iata_type)" -ForegroundColor White
        Write-Host ""
    }
    
    # Count by iata_type
    Write-Host "`nBreakdown by iata_type:" -ForegroundColor Yellow
    $typeGroups = $response | Group-Object iata_type | Sort-Object Count -Descending
    $typeGroups | Format-Table Name, Count
    
    # Find JFK, LAX, LHR in the data
    Write-Host "`nLooking for well-known airports:" -ForegroundColor Yellow
    
    $wellKnownCodes = @("JFK", "LAX", "LHR", "CDG", "DXB", "SIN", "HKG")
    foreach ($code in $wellKnownCodes) {
        $found = $response | Where-Object { $_.code -eq $code }
        if ($found) {
            Write-Host "✅ Found $code:" -ForegroundColor Green
            Write-Host "  Name: $($found.name)" -ForegroundColor White
            Write-Host "  City: $($found.city_name)" -ForegroundColor White
            Write-Host "  Type: $($found.iata_type)" -ForegroundColor White
        } else {
            Write-Host "❌ $code not found in API response" -ForegroundColor Red
        }
    }
    
    # Check if codes are 3 letters
    Write-Host "`nChecking code formats:" -ForegroundColor Yellow
    $validCodes = @()
    $invalidCodes = @()
    
    for ($i = 0; $i -lt [math]::Min(50, $response.Count); $i++) {
        $item = $response[$i]
        if ($item.code -and $item.code.Length -eq 3 -and $item.code -match "^[A-Z]{3}$") {
            $validCodes += $item.code
        } else {
            $invalidCodes += @{ Code = $item.code; Name = $item.name; Type = $item.iata_type }
        }
    }
    
    Write-Host "Valid 3-letter codes found: $($validCodes.Count)" -ForegroundColor White
    Write-Host "First 5 valid codes: $($validCodes[0..4] -join ', ')" -ForegroundColor White
    
    if ($invalidCodes.Count -gt 0) {
        Write-Host "`nInvalid codes (first 5):" -ForegroundColor Red
        for ($i = 0; $i -lt [math]::Min(5, $invalidCodes.Count); $i++) {
            $item = $invalidCodes[$i]
            Write-Host "  Code: '$($item.Code)' (Length: $($item.Code.Length)) - $($item.Name) - Type: $($item.Type)" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "❌ API call failed: $_" -ForegroundColor Red
}

Write-Host "`n🎉 Debug complete!" -ForegroundColor Green
