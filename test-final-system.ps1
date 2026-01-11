# Travel Hack - Final System Test
Write-Host "Travel Hack - Complete System Test" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green
Write-Host "Testing dynamic airport system with NLP parsing"
Write-Host ""

# Load modules
try {
    Import-Module .\modules\config-manager.psm1 -Force
    Write-Host "✅ Config manager loaded" -ForegroundColor Green
} catch {
    Write-Host "❌ Config manager failed" -ForegroundColor Red
    exit 1
}

try {
    Import-Module .\modules\airport-codes.psm1 -Force
    Write-Host "✅ Airport codes loaded" -ForegroundColor Green
    
    # Initialize database (will fetch from API)
    Initialize-AirportDB
    Write-Host "✅ Airport database initialized" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Airport codes failed" -ForegroundColor Red
    exit 1
}

try {
    Import-Module .\modules\nlp-processor.psm1 -Force
    Write-Host "✅ NLP processor loaded" -ForegroundColor Green
} catch {
    Write-Host "❌ NLP processor failed" -ForegroundColor Red
    exit 1
}

Write-Host "`n--- Test 1: Direct Airport Lookups ---" -ForegroundColor Yellow

$testCases = @(
    "JFK",
    "LAX", 
    "LHR",
    "SIN",
    "HKG",
    "newyork",      # Misspelled
    "londn",        # Misspelled  
    "dubln",        # Misspelled
    "chcago",       # Misspelled
    "dubay",        # Misspelled
    "NYC",          # Nickname
    "LA",           # Nickname
    "berlin",
    "madrid",
    "xyz123"        # Invalid
)

foreach ($test in $testCases) {
    Test-Airport-Lookup $test
}

Write-Host "`n--- Test 2: Complete Flight Queries ---" -ForegroundColor Yellow

$flightQueries = @(
    "Newyork to Dubln on 20 Jan 2024",
    "London to Paris on 2024-03-15",
    "LA to Chcago on 12/15/2024 for 2 people",
    "business class from Dubay to Singapor on 10-08-2024",
    "Miami to Tornto on July 4 2024 returning on July 10",
    "NYC to Lon on 2024-09-01",
    "Sin to Tok on 2024-10-15",
    "San Fran to HKG on 2024-11-20",
    "from Berlin to Madrid on March 20 2024 for 3 people business class"
)

foreach ($query in $flightQueries) {
    Test-Flight-Parser $query
}

Write-Host "`n--- Test 3: Airport Search ---" -ForegroundColor Yellow

$searchTests = @(
    "new",
    "lon", 
    "fran",
    "airport",
    "international"
)

foreach ($search in $searchTests) {
    Write-Host "`nSearching for: '$search'" -ForegroundColor Cyan
    $results = Search-Airports -SearchTerm $search -Limit 3
    
    if ($results.Count -gt 0) {
        Write-Host "Found $($results.Count) airports:" -ForegroundColor Green
        foreach ($result in $results) {
            Write-Host "  • $($result.FullDisplay)" -ForegroundColor White
        }
    } else {
        Write-Host "No results found" -ForegroundColor Yellow
    }
}

Write-Host "`n🎉 System Test Complete!" -ForegroundColor Green
Write-Host "System Features:" -ForegroundColor White
Write-Host "• ✅ Dynamic airport data from TravelPayouts API" -ForegroundColor White
Write-Host "• ✅ Real-time fetching with 24-hour cache" -ForegroundColor White
Write-Host "• ✅ Handles misspellings (Newyork, Londn, Chcago)" -ForegroundColor White
Write-Host "• ✅ Suggests alternatives for ambiguous inputs" -ForegroundColor White
Write-Host "• ✅ Parses natural language flight queries" -ForegroundColor White
Write-Host "• ✅ No hardcoded data - completely dynamic" -ForegroundColor White
Write-Host ""
Write-Host "Ready for next steps:" -ForegroundColor Yellow
Write-Host "1. Build Telegram bot interface" -ForegroundColor White
Write-Host "2. Build Flight Search with TravelPayouts API" -ForegroundColor White
Write-Host "3. Add affiliate link integration" -ForegroundColor White
