# Debug script for airport data issues
Write-Host "Travel Hack - Airport Data Debug" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Import modules
Import-Module .\modules\config-manager.psm1 -Force
Import-Module .\modules\airport-codes.psm1 -Force

Write-Host "`n--- Step 1: Test API Call Directly ---" -ForegroundColor Yellow

try {
    $apiUrl = "http://api.travelpayouts.com/data/en/airports.json"
    Write-Host "Fetching from API: $apiUrl" -ForegroundColor White
    
    # Try direct API call
    $response = Invoke-RestMethod -Uri $apiUrl -Method Get -TimeoutSec 30
    
    Write-Host "✅ API call successful!" -ForegroundColor Green
    Write-Host "Response type: $($response.GetType().Name)" -ForegroundColor White
    Write-Host "Response count: $($response.Count)" -ForegroundColor White
    
    if ($response.Count -gt 0) {
        Write-Host "`nFirst few airports:" -ForegroundColor Yellow
        $response | Select-Object -First 5 | Format-Table code, name, city_name, country_code
        
        Write-Host "`nSample airport structure:" -ForegroundColor Yellow
        $sample = $response[0]
        $sample | Get-Member | Where-Object {$_.MemberType -eq "NoteProperty"} | Select-Object -First 10 Name, Definition
    }
    
} catch {
    Write-Host "❌ API call failed: $_" -ForegroundColor Red
}

Write-Host "`n--- Step 2: Test Cache Initialization ---" -ForegroundColor Yellow

# Initialize cache
Initialize-AirportCache

if ($global:AirportCache) {
    Write-Host "✅ Cache initialized" -ForegroundColor Green
    Write-Host "Cache source: $($global:AirportCache.Source)" -ForegroundColor White
    Write-Host "Last updated: $($global:AirportCache.LastUpdated)" -ForegroundColor White
    Write-Host "Airports count: $($global:AirportCache.Airports.Count)" -ForegroundColor White
    Write-Host "Cities count: $($global:AirportCache.Cities.Count)" -ForegroundColor White
    
    if ($global:AirportCache.Airports.Count -gt 0) {
        Write-Host "`nFirst few cached airports:" -ForegroundColor Yellow
        $global:AirportCache.Airports.Keys | Select-Object -First 5 | ForEach-Object {
            $code = $_
            $data = $global:AirportCache.Airports[$code]
            Write-Host "  $code -> $($data.City) - $($data.Name)" -ForegroundColor White
        }
    } else {
        Write-Host "❌ Cache has 0 airports!" -ForegroundColor Red
        
        # Check the cache file
        if (Test-Path ".\data\airports_cache.json") {
            Write-Host "`nChecking cache file..." -ForegroundColor Yellow
            $cacheContent = Get-Content ".\data\airports_cache.json" -Raw
            Write-Host "Cache file size: $($cacheContent.Length) characters" -ForegroundColor White
            
            # Try to parse it
            try {
                $parsed = $cacheContent | ConvertFrom-Json
                Write-Host "Cache file parsed successfully" -ForegroundColor Green
                Write-Host "Parsed airports count: $($parsed.Airports.Count)" -ForegroundColor White
                
                # Show structure
                $parsed | Get-Member | Where-Object {$_.MemberType -eq "NoteProperty"} | Format-Table Name
            } catch {
                Write-Host "❌ Failed to parse cache file: $_" -ForegroundColor Red
            }
        }
    }
} else {
    Write-Host "❌ Cache not initialized!" -ForegroundColor Red
}

Write-Host "`n--- Step 3: Test Airport Lookup Functions ---" -ForegroundColor Yellow

# Test functions
Write-Host "Testing Find-AirportByCode with 'JFK':" -ForegroundColor White
$result = Find-AirportByCode -AirportCode "JFK"
if ($result) {
    Write-Host "✅ Found: $($result.Code) - $($result.City)" -ForegroundColor Green
} else {
    Write-Host "❌ Not found" -ForegroundColor Red
}

Write-Host "`nTesting Find-AirportByCity with 'New York':" -ForegroundColor White
$result = Find-AirportByCity -CityName "New York"
if ($result) {
    Write-Host "✅ Found: $($result.Code) - $($result.City)" -ForegroundColor Green
} else {
    Write-Host "❌ Not found" -ForegroundColor Red
}

Write-Host "`n--- Step 4: Manual Data Check ---" -ForegroundColor Yellow

# Manually check if we can find specific airports
Write-Host "Looking for known airports in cache..." -ForegroundColor White

$testCodes = @("JFK", "LAX", "LHR", "CDG", "DXB")
foreach ($code in $testCodes) {
    if ($global:AirportCache.Airports.ContainsKey($code)) {
        $data = $global:AirportCache.Airports[$code]
        Write-Host "✅ $code found: $($data.City) - $($data.Name)" -ForegroundColor Green
    } else {
        Write-Host "❌ $code not found in cache" -ForegroundColor Red
    }
}

Write-Host "`n🎉 Debug complete!" -ForegroundColor Green
