# Test Fixed Airport Module
Write-Host "Testing Fixed Airport Module" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green

# Load modules
Import-Module .\modules\config-manager.psm1 -Force
Import-Module .\modules\airport-codes.psm1 -Force

# Initialize database
Write-Host "`nInitializing airport database..." -ForegroundColor Yellow
Initialize-AirportDB

Write-Host "`n--- Test 1: Basic Airport Code Lookups ---" -ForegroundColor Cyan

$codeTests = @("JFK", "LAX", "LHR", "DXB", "SIN", "HKG", "XYZ123")

foreach ($code in $codeTests) {
    Write-Host "`nTesting code: $code" -ForegroundColor White
    $result = Get-Airport-Info $code
    
    if ($result.Found) {
        Write-Host "✅ Found: $($result.Display)" -ForegroundColor Green
    } else {
        Write-Host "❌ Not found" -ForegroundColor Red
    }
}

Write-Host "`n--- Test 2: City Name Lookups ---" -ForegroundColor Cyan

$cityTests = @("New York", "London", "Paris", "Dubai", "Singapore", "Unknown City")

foreach ($city in $cityTests) {
    Write-Host "`nTesting city: $city" -ForegroundColor White
    $result = Get-Airport-Info $city
    
    if ($result.Found) {
        Write-Host "✅ Found: $($result.Display)" -ForegroundColor Green
        Write-Host "  Match type: $($result.MatchType)" -ForegroundColor Gray
    } else {
        Write-Host "❌ Not found" -ForegroundColor Red
    }
}

Write-Host "`n--- Test 3: Misspelled City Names ---" -ForegroundColor Cyan

$misspelledTests = @("newyork", "londn", "dubln", "chcago", "dubay", "singapor")

foreach ($test in $misspelledTests) {
    Write-Host "`nTesting: '$test'" -ForegroundColor White
    $result = Get-Airport-Info $test
    
    if ($result.Found) {
        Write-Host "✅ Found: $($result.Display)" -ForegroundColor Green
        Write-Host "  Confidence: $($result.Confidence)" -ForegroundColor Gray
    } else {
        Write-Host "❌ Not found" -ForegroundColor Red
    }
}

Write-Host "`n--- Test 4: Airport Code Abbreviations ---" -ForegroundColor Cyan

$abbrTests = @("NYC", "LA", "SF", "SIN", "HKG", "SYD", "LON")

foreach ($test in $abbrTests) {
    Write-Host "`nTesting: '$test'" -ForegroundColor White
    $result = Get-Airport-Info $test
    
    if ($result.Found) {
        Write-Host "✅ Found: $($result.Display)" -ForegroundColor Green
    } else {
        Write-Host "❌ Not found" -ForegroundColor Red
    }
}

Write-Host "`n--- Test 5: Search Function ---" -ForegroundColor Cyan

$searchTests = @("new", "lon", "fran", "airport")

foreach ($search in $searchTests) {
    Write-Host "`nSearching: '$search'" -ForegroundColor White
    $results = Search-Airports -SearchTerm $search -Limit 3
    
    if ($results.Count -gt 0) {
        Write-Host "✅ Found $($results.Count) results:" -ForegroundColor Green
        foreach ($result in $results) {
            Write-Host "  • $($result.FullDisplay)" -ForegroundColor Gray
        }
    } else {
        Write-Host "❌ No results" -ForegroundColor Yellow
    }
}

Write-Host "`n🎉 Test Complete!" -ForegroundColor Green
