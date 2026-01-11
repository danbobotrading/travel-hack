# Dynamic Airport System Test
# Tests the API-based airport lookup system

Write-Host "Travel Hack - Dynamic Airport System Test" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""

# Import modules
try {
    Import-Module .\modules\config-manager.psm1 -Force
    Write-Host "✅ Config manager loaded" -ForegroundColor Green
} catch {
    Write-Host "❌ Config manager failed: $_" -ForegroundColor Red
    exit 1
}

try {
    Import-Module .\modules\airport-codes.psm1 -Force
    Write-Host "✅ Airport codes module loaded" -ForegroundColor Green
    
    # Initialize the cache (will fetch from API if needed)
    Initialize-AirportCache
    Write-Host "✅ Airport cache initialized" -ForegroundColor Green
} catch {
    Write-Host "❌ Airport codes failed: $_" -ForegroundColor Red
    exit 1
}

try {
    Import-Module .\modules\nlp-processor.psm1 -Force
    Write-Host "✅ NLP processor loaded" -ForegroundColor Green
} catch {
    Write-Host "❌ NLP processor failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n--- Test 1: Direct Airport Lookups ---" -ForegroundColor Yellow

$airportTests = @(
    "JFK",          # Exact airport code
    "London",       # Exact city name
    "Londn",        # Misspelled London
    "Newyork",      # Misspelled New York
    "Sin",          # Airport code for Singapore
    "Chcago",       # Misspelled Chicago
    "Dubay",        # Misspelled Dubai
    "Toky",         # Misspelled Tokyo
    "SFO",          # San Francisco code
    "Heathrow",     # Airport name
    "Charles de Gaulle",  # Full airport name
    "xyz123"        # Invalid input
)

foreach ($test in $airportTests) {
    Write-Host "`nLooking up: '$test'" -ForegroundColor Cyan
    $result = Test-AirportLookup -Input $test -MaxResults 3
    
    if ($result -and $result.Found -eq $false -and $result.Alternatives) {
        Write-Host "  Please select the correct option:" -ForegroundColor Yellow
        $i = 1
        foreach ($alt in $result.Alternatives) {
            Write-Host "  $i. $($alt.DisplayName)" -ForegroundColor White
            $i++
        }
    }
}

Write-Host "`n--- Test 2: Complete NLP Queries with Misspellings ---" -ForegroundColor Yellow

$nlpTests = @(
    "Newyork to Dubln on 20 Jan 2024",
    "Londn to Paris on 15 March 2024",
    "LA to Chcago on 12/15/2024 for 2 people",
    "business class from Dubay to Singapor on 10-08-2024",
    "Miami to Tornto on July 4 2024 returning July 10",
    "NYC to Lon on 2024-09-01",
    "Sin to Tok on 2024-10-15",
    "San Fran to HKG on 2024-11-20"
)

foreach ($test in $nlpTests) {
    Write-Host "`n📝 Query: '$test'" -ForegroundColor Cyan
    
    # Parse with interactive mode to get alternatives
    $nlpResult = ConvertFrom-NaturalLanguage -Query $test -Interactive:$true
    
    if ($nlpResult.Success) {
        Write-Host "✅ NLP parsing successful" -ForegroundColor Green
        
        # Try to resolve airports
        if ($nlpResult.RequiresConfirmation) {
            Write-Host "⚠️  Some locations need confirmation:" -ForegroundColor Yellow
            
            $resolvedAirports = @{}
            
            foreach ($alternative in $nlpResult.Alternatives) {
                Write-Host "  $($alternative.Type) '$($alternative.Input)' options:" -ForegroundColor White
                $i = 1
                foreach ($option in $alternative.Options) {
                    Write-Host "    $i. $($option.DisplayName)" -ForegroundColor Gray
                    $i++
                }
                
                # For testing, auto-select the first option
                if ($alternative.Options.Count -gt 0) {
                    $selected = $alternative.Options[0]
                    $resolvedAirports[$alternative.Type] = $selected
                    Write-Host "  Selected: $($selected.DisplayName)" -ForegroundColor Green
                }
            }
            
            # Show final resolved parameters
            if ($resolvedAirports.ContainsKey("Origin") -and $resolvedAirports.ContainsKey("Destination")) {
                Write-Host "`n🎯 Final resolved search:" -ForegroundColor Green
                Write-Host "  ✈️  $($resolvedAirports["Origin"].City) ($($resolvedAirports["Origin"].Code)) → $($resolvedAirports["Destination"].City) ($($resolvedAirports["Destination"].Code))" -ForegroundColor White
                Write-Host "  📅 Depart: $($nlpResult.DepartureDate)" -ForegroundColor White
                if ($nlpResult.ReturnDate) {
                    Write-Host "  📅 Return: $($nlpResult.ReturnDate)" -ForegroundColor White
                }
                Write-Host "  👥 Travelers: $($nlpResult.Travelers)" -ForegroundColor White
                Write-Host "  🎫 Class: $($nlpResult.Class)" -ForegroundColor White
                if ($nlpResult.Direct) {
                    Write-Host "  ⚡ Direct flight" -ForegroundColor White
                }
            }
        } else {
            Write-Host "✅ All locations resolved automatically" -ForegroundColor Green
        }
    } else {
        Write-Host "❌ NLP parsing failed: $($nlpResult.Error)" -ForegroundColor Red
    }
}

Write-Host "`n--- Test 3: Airport Search Examples ---" -ForegroundColor Yellow

$searchTests = @(
    "new",
    "lon",
    "fran",
    "inter",
    "airport"
)

foreach ($search in $searchTests) {
    Write-Host "`nSearching airports for: '$search'" -ForegroundColor Cyan
    $results = Search-Airports -SearchTerm $search -MaxResults 3
    
    if ($results.Count -gt 0) {
        Write-Host "Found $($results.Count) results:" -ForegroundColor Green
        foreach ($result in $results) {
            Write-Host "  • $($result.DisplayName)" -ForegroundColor White
        }
    } else {
        Write-Host "No results found" -ForegroundColor Yellow
    }
}

Write-Host "`n🎉 Dynamic airport system test complete!" -ForegroundColor Green
Write-Host "The system can now:" -ForegroundColor White
Write-Host "  • Fetch airport data from TravelPayouts API" -ForegroundColor White
Write-Host "  • Cache data locally for 24 hours" -ForegroundColor White
Write-Host "  • Handle misspellings with fuzzy matching" -ForegroundColor White
Write-Host "  • Suggest alternatives when unsure" -ForegroundColor White
Write-Host "  • Search by city name, airport code, or airport name" -ForegroundColor White
