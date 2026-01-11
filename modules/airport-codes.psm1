# Airport Codes Module - Better API Handling
# Dynamic airport data from TravelPayouts API

# Import configuration
Import-Module .\modules\config-manager.psm1 -Force -ErrorAction SilentlyContinue

# Global database
$global:AirportDB = $null
$global:AirportCacheFile = ".\data\airports_cache.json"

function Initialize-AirportDB {
    # Create data directory
    if (-not (Test-Path ".\data")) {
        New-Item -ItemType Directory -Path ".\data" -Force | Out-Null
    }
    
    # Try to load from cache
    if (Test-Path $global:AirportCacheFile) {
        try {
            $cacheContent = Get-Content $global:AirportCacheFile -Raw
            $cachedData = $cacheContent | ConvertFrom-Json
            Write-Log "Loaded airport database from cache" "INFO"
            
            # Reconstruct database from cache
            $global:AirportDB = Reconstruct-From-Cache $cachedData
            return
        }
        catch {
            Write-Log "Cache load failed, fetching fresh data" "WARN"
        }
    }
    
    # Fetch fresh data
    Write-Log "Fetching fresh airport data from API" "INFO"
    $global:AirportDB = Fetch-AirportData
    
    # Save to cache
    if ($global:AirportDB -and $global:AirportDB.Count -gt 0) {
        Save-To-Cache $global:AirportDB
        Write-Log ("Saved " + $global:AirportDB.Count + " airports to cache") "INFO"
    } else {
        Write-Log "Failed to fetch airport data, using fallback" "ERROR"
        $global:AirportDB = Get-Fallback-Data
    }
}

function Fetch-AirportData {
    try {
        $apiUrl = "http://api.travelpayouts.com/data/en/airports.json"
        Write-Log "Fetching airport data from TravelPayouts API" "INFO"
        
        $apiResponse = Invoke-RestMethod -Uri $apiUrl -Method Get -TimeoutSec 30
        
        if (-not $apiResponse -or $apiResponse.Count -eq 0) {
            Write-Log "API returned no data" "ERROR"
            return $null
        }
        
        Write-Log ("API returned " + $apiResponse.Count + " items") "INFO"
        
        # DEBUG: Show first few items to understand structure
        Write-Log "Sample API data (first 3 items):" "DEBUG"
        for ($i = 0; $i -lt [math]::Min(3, $apiResponse.Count); $i++) {
            $item = $apiResponse[$i]
            Write-Log ("Item $i - Code: " + $item.code + ", Name: " + $item.name + ", City: " + $item.city_name + ", Type: " + $item.iata_type) "DEBUG"
        }
        
        # Process airports - be more lenient with filtering
        $airportList = @()
        $byCode = @{}
        $byCity = @{}
        
        $airportCount = 0
        foreach ($item in $apiResponse) {
            # Skip items without code or city
            if (-not $item.code -or -not $item.city_name) {
                continue
            }
            
            $code = $item.code.Trim().ToUpper()
            $city = $item.city_name.Trim()
            $name = $item.name.Trim()
            $country = if ($item.country_code) { $item.country_code.Trim() } else { "" }
            
            # Skip if code is not valid (not 3 letters)
            if ($code.Length -ne 3 -or -not ($code -match "^[A-Z]{3}$")) {
                continue
            }
            
            # Create airport object
            $airportObj = [PSCustomObject]@{
                Code = $code
                City = $city
                Name = $name
                Country = $country
                DisplayName = "$city ($code)"
                FullDisplay = "$city ($code) - $name"
            }
            
            # Add to collections
            $airportList += $airportObj
            $byCode[$code] = $airportObj
            
            # City can have multiple airports
            if (-not $byCity.ContainsKey($city)) {
                $byCity[$city] = @()
            }
            $byCity[$city] += $airportObj
            
            $airportCount++
            
            # Stop if we have enough airports (for performance)
            if ($airportCount -ge 1000) {
                break
            }
        }
        
        Write-Log ("Processed " + $airportCount + " airports") "INFO"
        
        # Also add some well-known airports that might have been filtered out
        Add-Well-Known-Airports -AirportList $airportList -ByCode $byCode -ByCity $byCity
        
        return [PSCustomObject]@{
            Airports = $airportList
            ByCode = $byCode
            ByCity = $byCity
            Count = $airportCount
            LastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            Source = "API"
        }
    }
    catch {
        Write-Log ("API fetch failed: " + $_) "ERROR"
        return $null
    }
}

function Add-Well-Known-Airports {
    param(
        [array]$AirportList,
        [hashtable]$ByCode,
        [hashtable]$ByCity
    )
    
    # Add airports that are commonly searched for
    $wellKnownAirports = @(
        [PSCustomObject]@{ Code = "JFK"; City = "New York"; Name = "John F Kennedy International"; Country = "US" },
        [PSCustomObject]@{ Code = "LAX"; City = "Los Angeles"; Name = "Los Angeles International"; Country = "US" },
        [PSCustomObject]@{ Code = "LHR"; City = "London"; Name = "Heathrow Airport"; Country = "GB" },
        [PSCustomObject]@{ Code = "CDG"; City = "Paris"; Name = "Charles de Gaulle Airport"; Country = "FR" },
        [PSCustomObject]@{ Code = "DXB"; City = "Dubai"; Name = "Dubai International Airport"; Country = "AE" },
        [PSCustomObject]@{ Code = "SIN"; City = "Singapore"; Name = "Changi Airport"; Country = "SG" },
        [PSCustomObject]@{ Code = "HKG"; City = "Hong Kong"; Name = "Hong Kong International Airport"; Country = "HK" },
        [PSCustomObject]@{ Code = "SYD"; City = "Sydney"; Name = "Sydney Airport"; Country = "AU" },
        [PSCustomObject]@{ Code = "YYZ"; City = "Toronto"; Name = "Toronto Pearson International Airport"; Country = "CA" },
        [PSCustomObject]@{ Code = "ORD"; City = "Chicago"; Name = "O'Hare International Airport"; Country = "US" },
        [PSCustomObject]@{ Code = "DUB"; City = "Dublin"; Name = "Dublin Airport"; Country = "IE" },
        [PSCustomObject]@{ Code = "BER"; City = "Berlin"; Name = "Berlin Brandenburg Airport"; Country = "DE" },
        [PSCustomObject]@{ Code = "MAD"; City = "Madrid"; Name = "Adolfo Suarez Madrid-Barajas Airport"; Country = "ES" },
        [PSCustomObject]@{ Code = "FCO"; City = "Rome"; Name = "Leonardo da Vinci-Fiumicino Airport"; Country = "IT" },
        [PSCustomObject]@{ Code = "AMS"; City = "Amsterdam"; Name = "Amsterdam Airport Schiphol"; Country = "NL" },
        [PSCustomObject]@{ Code = "ATL"; City = "Atlanta"; Name = "Hartsfield-Jackson Atlanta International"; Country = "US" },
        [PSCustomObject]@{ Code = "PEK"; City = "Beijing"; Name = "Beijing Capital International Airport"; Country = "CN" },
        [PSCustomObject]@{ Code = "NRT"; City = "Tokyo"; Name = "Narita International Airport"; Country = "JP" }
    )
    
    foreach ($airport in $wellKnownAirports) {
        if (-not $ByCode.ContainsKey($airport.Code)) {
            $airportObj = [PSCustomObject]@{
                Code = $airport.Code
                City = $airport.City
                Name = $airport.Name
                Country = $airport.Country
                DisplayName = "$($airport.City) ($($airport.Code))"
                FullDisplay = "$($airport.City) ($($airport.Code)) - $($airport.Name)"
            }
            
            $AirportList += $airportObj
            $ByCode[$airport.Code] = $airportObj
            
            if (-not $ByCity.ContainsKey($airport.City)) {
                $ByCity[$airport.City] = @()
            }
            $ByCity[$airport.City] += $airportObj
        }
    }
}

function Get-Fallback-Data {
    Write-Log "Using fallback airport data" "WARN"
    
    # Create basic airport list
    $fallbackAirports = @(
        [PSCustomObject]@{ Code = "JFK"; City = "New York"; Name = "John F Kennedy International"; Country = "US" },
        [PSCustomObject]@{ Code = "LAX"; City = "Los Angeles"; Name = "Los Angeles International"; Country = "US" },
        [PSCustomObject]@{ Code = "LHR"; City = "London"; Name = "Heathrow Airport"; Country = "GB" },
        [PSCustomObject]@{ Code = "CDG"; City = "Paris"; Name = "Charles de Gaulle Airport"; Country = "FR" },
        [PSCustomObject]@{ Code = "DXB"; City = "Dubai"; Name = "Dubai International Airport"; Country = "AE" },
        [PSCustomObject]@{ Code = "SIN"; City = "Singapore"; Name = "Changi Airport"; Country = "SG" },
        [PSCustomObject]@{ Code = "HKG"; City = "Hong Kong"; Name = "Hong Kong International Airport"; Country = "HK" },
        [PSCustomObject]@{ Code = "SYD"; City = "Sydney"; Name = "Sydney Airport"; Country = "AU" },
        [PSCustomObject]@{ Code = "YYZ"; City = "Toronto"; Name = "Toronto Pearson International Airport"; Country = "CA" },
        [PSCustomObject]@{ Code = "ORD"; City = "Chicago"; Name = "O'Hare International Airport"; Country = "US" },
        [PSCustomObject]@{ Code = "DUB"; City = "Dublin"; Name = "Dublin Airport"; Country = "IE" },
        [PSCustomObject]@{ Code = "BER"; City = "Berlin"; Name = "Berlin Brandenburg Airport"; Country = "DE" },
        [PSCustomObject]@{ Code = "MAD"; City = "Madrid"; Name = "Adolfo Suarez Madrid-Barajas Airport"; Country = "ES" },
        [PSCustomObject]@{ Code = "FCO"; City = "Rome"; Name = "Leonardo da Vinci-Fiumicino Airport"; Country = "IT" },
        [PSCustomObject]@{ Code = "AMS"; City = "Amsterdam"; Name = "Amsterdam Airport Schiphol"; Country = "NL" }
    )
    
    # Create hashtables
    $byCode = @{}
    $byCity = @{}
    
    foreach ($airport in $fallbackAirports) {
        $airportObj = [PSCustomObject]@{
            Code = $airport.Code
            City = $airport.City
            Name = $airport.Name
            Country = $airport.Country
            DisplayName = "$($airport.City) ($($airport.Code))"
            FullDisplay = "$($airport.City) ($($airport.Code)) - $($airport.Name)"
        }
        
        $byCode[$airport.Code] = $airportObj
        
        if (-not $byCity.ContainsKey($airport.City)) {
            $byCity[$airport.City] = @()
        }
        $byCity[$airport.City] += $airportObj
    }
    
    return [PSCustomObject]@{
        Airports = $fallbackAirports
        ByCode = $byCode
        ByCity = $byCity
        Count = $fallbackAirports.Count
        LastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Source = "Fallback"
    }
}

function Save-To-Cache {
    param(
        [object]$AirportDB
    )
    
    # Convert hashtables to arrays for JSON serialization
    $byCodeArray = @()
    foreach ($key in $AirportDB.ByCode.Keys) {
        $byCodeArray += @{ Key = $key; Value = $AirportDB.ByCode[$key] }
    }
    
    $byCityArray = @()
    foreach ($key in $AirportDB.ByCity.Keys) {
        $byCityArray += @{ Key = $key; Value = $AirportDB.ByCity[$key] }
    }
    
    $cacheData = [PSCustomObject]@{
        Airports = $AirportDB.Airports
        ByCodeArray = $byCodeArray
        ByCityArray = $byCityArray
        Count = $AirportDB.Count
        LastUpdated = $AirportDB.LastUpdated
        Source = $AirportDB.Source
    }
    
    $cacheData | ConvertTo-Json -Depth 10 | Out-File $global:AirportCacheFile -Encoding UTF8
}

function Reconstruct-From-Cache {
    param(
        [object]$CachedData
    )
    
    # Recreate hashtables from arrays
    $byCode = @{}
    foreach ($item in $CachedData.ByCodeArray) {
        $byCode[$item.Key] = $item.Value
    }
    
    $byCity = @{}
    foreach ($item in $CachedData.ByCityArray) {
        $byCity[$item.Key] = $item.Value
    }
    
    return [PSCustomObject]@{
        Airports = $CachedData.Airports
        ByCode = $byCode
        ByCity = $byCity
        Count = $CachedData.Count
        LastUpdated = $CachedData.LastUpdated
        Source = $CachedData.Source
    }
}

function Ensure-AirportDB {
    if (-not $global:AirportDB) {
        Initialize-AirportDB
    }
}

function Find-Airport-By-Code {
    param(
        [string]$Code
    )
    
    Ensure-AirportDB
    
    $codeUpper = $Code.ToUpper()
    
    if ($global:AirportDB.ByCode.ContainsKey($codeUpper)) {
        return $global:AirportDB.ByCode[$codeUpper]
    }
    
    return $null
}

function Find-Airport-By-City {
    param(
        [string]$CityName
    )
    
    Ensure-AirportDB
    
    # Try exact city name match
    if ($global:AirportDB.ByCity.ContainsKey($CityName)) {
        $airports = $global:AirportDB.ByCity[$CityName]
        if ($airports.Count -gt 0) {
            return $airports[0]
        }
    }
    
    # Try fuzzy matching for common misspellings
    $cityLower = $CityName.ToLower()
    
    # Common misspellings mapping
    $misspellingMap = @{
        "newyork" = "New York"
        "londn" = "London"
        "dubln" = "Dublin"
        "chcago" = "Chicago"
        "dubay" = "Dubai"
        "singapor" = "Singapore"
        "tornto" = "Toronto"
        "berln" = "Berlin"
        "madrd" = "Madrid"
        "paris" = "Paris"
        "miami" = "Miami"
        "la" = "Los Angeles"
        "nyc" = "New York"
        "sin" = "Singapore"
        "hkg" = "Hong Kong"
        "syd" = "Sydney"
        "lon" = "London"
        "dub" = "Dubai"
        "tok" = "Tokyo"
        "sf" = "San Francisco"
        "san fran" = "San Francisco"
        "toronto" = "Toronto"
        "berlin" = "Berlin"
        "madrid" = "Madrid"
        "amsterdam" = "Amsterdam"
        "rome" = "Rome"
    }
    
    if ($misspellingMap.ContainsKey($cityLower)) {
        $correctCity = $misspellingMap[$cityLower]
        if ($global:AirportDB.ByCity.ContainsKey($correctCity)) {
            $airports = $global:AirportDB.ByCity[$correctCity]
            if ($airports.Count -gt 0) {
                return $airports[0]
            }
        }
    }
    
    # Try case-insensitive search
    foreach ($cityKey in $global:AirportDB.ByCity.Keys) {
        if ($cityKey.ToLower() -eq $cityLower) {
            $airports = $global:AirportDB.ByCity[$cityKey]
            if ($airports.Count -gt 0) {
                return $airports[0]
            }
        }
    }
    
    return $null
}

function Search-Airports {
    param(
        [string]$SearchTerm,
        [int]$Limit = 5
    )
    
    Ensure-AirportDB
    
    if ([string]::IsNullOrWhiteSpace($SearchTerm)) {
        return @()
    }
    
    $searchLower = $SearchTerm.ToLower().Trim()
    $results = @()
    
    # Search by airport code
    if ($searchLower -match "^[a-z]{2,4}$") {
        $codeUpper = $searchLower.ToUpper()
        $airport = Find-Airport-By-Code -Code $codeUpper
        if ($airport) {
            $results += $airport
        }
    }
    
    # Search by city name
    $airport = Find-Airport-By-City -CityName $SearchTerm
    if ($airport) {
        $results += $airport
    }
    
    # Search in all airports (simple text search)
    foreach ($airport in $global:AirportDB.Airports) {
        $searchText = "$($airport.City.ToLower()) $($airport.Name.ToLower()) $($airport.Code.ToLower())"
        if ($searchText -like "*$searchLower*") {
            $results += $airport
        }
    }
    
    # Remove duplicates and limit results
    $uniqueResults = @{}
    foreach ($result in $results) {
        if (-not $uniqueResults.ContainsKey($result.Code)) {
            $uniqueResults[$result.Code] = $result
        }
    }
    
    return $uniqueResults.Values | Select-Object -First $Limit
}

function Get-Airport-Info {
    param(
        [string]$InputText
    )
    
    if ([string]::IsNullOrWhiteSpace($InputText)) {
        return [PSCustomObject]@{
            Found = $false
            Message = "Input is empty"
        }
    }
    
    Write-Log ("Looking up airport: " + $InputText) "INFO"
    
    # Try as airport code first
    if ($InputText -match "^[A-Za-z]{2,4}$") {
        $airport = Find-Airport-By-Code -Code $InputText
        if ($airport) {
            return [PSCustomObject]@{
                Found = $true
                Code = $airport.Code
                City = $airport.City
                Name = $airport.Name
                Country = $airport.Country
                MatchType = "code"
                Confidence = "high"
                Display = $airport.DisplayName
                AirportObject = $airport
            }
        }
    }
    
    # Try as city name
    $airport = Find-Airport-By-City -CityName $InputText
    if ($airport) {
        return [PSCustomObject]@{
            Found = $true
            Code = $airport.Code
            City = $airport.City
            Name = $airport.Name
            Country = $airport.Country
            MatchType = "city"
            Confidence = if ($InputText.ToLower() -eq $airport.City.ToLower()) { "high" } else { "medium" }
            Display = $airport.DisplayName
            AirportObject = $airport
        }
    }
    
    # Search for alternatives
    $alternatives = Search-Airports -SearchTerm $InputText -Limit 3
    
    if ($alternatives.Count -gt 0) {
        return [PSCustomObject]@{
            Found = $true
            Code = $alternatives[0].Code
            City = $alternatives[0].City
            Name = $alternatives[0].Name
            Country = $alternatives[0].Country
            MatchType = "search"
            Confidence = "medium"
            Display = $alternatives[0].DisplayName
            AirportObject = $alternatives[0]
            Alternatives = $alternatives
        }
    }
    
    return [PSCustomObject]@{
        Found = $false
        Input = $InputText
        Message = "No airport found for: $InputText"
    }
}

function Test-Airport-Lookup {
    param(
        [string]$InputText
    )
    
    Write-Host "`nLooking up: '$InputText'" -ForegroundColor Cyan
    
    $result = Get-Airport-Info -InputText $InputText
    
    if ($result.Found) {
        Write-Host "✅ Found:" -ForegroundColor Green
        Write-Host "  Airport: $($result.Display)" -ForegroundColor White
        Write-Host "  Code: $($result.Code)" -ForegroundColor White
        Write-Host "  City: $($result.City)" -ForegroundColor White
        Write-Host "  Name: $($result.Name)" -ForegroundColor White
        Write-Host "  Match: $($result.MatchType)" -ForegroundColor White
        Write-Host "  Confidence: $($result.Confidence)" -ForegroundColor White
        
        if ($result.Alternatives -and $result.Alternatives.Count -gt 1) {
            Write-Host "`n  Other options:" -ForegroundColor Yellow
            for ($i = 1; $i -lt $result.Alternatives.Count; $i++) {
                $alt = $result.Alternatives[$i]
                Write-Host "  $($i+1). $($alt.FullDisplay)" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "❌ Not found: $($result.Message)" -ForegroundColor Red
        
        # Try searching
        $searchResults = Search-Airports -SearchTerm $InputText -Limit 3
        if ($searchResults.Count -gt 0) {
            Write-Host "`n  Did you mean:" -ForegroundColor Cyan
            for ($i = 0; $i -lt $searchResults.Count; $i++) {
                $res = $searchResults[$i]
                Write-Host "  $($i+1). $($res.FullDisplay)" -ForegroundColor White
            }
        }
    }
    
    return $result
}

# Export functions
Export-ModuleMember -Function Initialize-AirportDB, Search-Airports, Get-Airport-Info, Test-Airport-Lookup
