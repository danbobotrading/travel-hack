# Travel Hack - Dynamic Airport System Test
Write-Host "Travel Hack - Dynamic Airport System" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host "Testing API-based airport lookup with fuzzy matching"
Write-Host ""

# Import modules
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
    
    # Initialize data (will fetch from API)
    Initialize-AirportData
    Write-Host "✅ Airport data initialized" -ForegroundColor Green
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

$lookupTests = @(
    "JFK",
    "lax",
    "Londn",      # Misspelled
    "newyork",    # No space
    "dubln",      # Misspelled
    "chcago",     # Misspelled
    "Sin",        # Singapore code
    "hkg",
    "sydny",      # Misspelled Sydney
    "paris",
    "toky",       # Misspelled
    "dubay",      # Misspelled
    "xyz123"      # Invalid
)

foreach ($test in $lookupTests) {
    Test-AirportLookup $test
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
    Test-FlightQuery $query
}

Write-Host "`n--- Test 3: Airport Search Examples ---" -ForegroundColor Yellow

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
        Write-Host "Found $($results.Count) results:" -ForegroundColor Green
        foreach ($result in $results) {
            Write-Host "  • $($result.Display)" -ForegroundColor White
        }
    } else {
        Write-Host "No results found" -ForegroundColor Yellow
    }
}

Write-Host "`n🎉 Test Complete!" -ForegroundColor Green
Write-Host "System features:" -ForegroundColor White
Write-Host "• Dynamic airport data from TravelPayouts API" -ForegroundColor White
Write-Host "• Fuzzy matching for misspelled city names" -ForegroundColor White
Write-Host "• Handles airport codes, city names, and airport names" -ForegroundColor White
Write-Host "• Suggests alternatives when input is ambiguous" -ForegroundColor White
Write-Host "• Caches data locally for 24 hours" -ForegroundColor White
