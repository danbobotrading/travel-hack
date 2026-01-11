# Quick Verification Test
Write-Host "Travel Hack - Quick Verification" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host ""

# Load modules
Import-Module .\modules\config-manager.psm1 -Force
Import-Module .\modules\airport-codes.psm1 -Force

# Initialize database
Write-Host "Initializing airport database..." -ForegroundColor Yellow
Initialize-AirportDB

Write-Host "`n--- Testing Basic Lookups ---" -ForegroundColor Yellow

# Test some basic lookups
$testCases = @(
    "JFK",
    "LAX",
    "LHR",
    "newyork",
    "londn",
    "dubln",
    "chcago"
)

foreach ($test in $testCases) {
    Write-Host "`nTesting: '$test'" -ForegroundColor Cyan
    $result = Get-Airport-Info $test
    
    if ($result.Found) {
        Write-Host "✅ Found: $($result.Display)" -ForegroundColor Green
        Write-Host "   Match type: $($result.MatchType)" -ForegroundColor White
        Write-Host "   Confidence: $($result.Confidence)" -ForegroundColor White
    } else {
        Write-Host "❌ Not found" -ForegroundColor Red
    }
}

Write-Host "`n--- Testing Search Function ---" -ForegroundColor Yellow

$searchTests = @(
    "new",
    "lon",
    "fran"
)

foreach ($search in $searchTests) {
    Write-Host "`nSearching for: '$search'" -ForegroundColor Cyan
    $results = Search-Airports -SearchTerm $search -Limit 3
    
    if ($results.Count -gt 0) {
        Write-Host "Found $($results.Count) results:" -ForegroundColor Green
        foreach ($result in $results) {
            Write-Host "  • $($result.FullDisplay)" -ForegroundColor White
        }
    } else {
        Write-Host "No results found" -ForegroundColor Yellow
    }
}

Write-Host "`n🎉 Quick test complete!" -ForegroundColor Green
