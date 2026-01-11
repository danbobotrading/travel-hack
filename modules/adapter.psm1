# modules/adapter.psm1
# Adapter to bridge between your actual modules and expected interface

# Import your actual modules
. $PSScriptRoot\config-manager.psm1
. $PSScriptRoot\airport-codes.psm1
. $PSScriptRoot\nlp-processor.psm1

# Re-export with expected names using your actual functions
function Get-Configuration {
    <#
    .SYNOPSIS
    Wrapper for Get-Config from config-manager.psm1
    #>
    param()
    
    try {
        # Call your actual function
        return Get-Config
    }
    catch {
        Write-Host "Error in Get-Configuration: $_" -ForegroundColor Red
        
        # Fallback: direct file read
        $configPath = Join-Path (Split-Path -Parent $PSScriptRoot) "config\config.json"
        if (Test-Path $configPath) {
            $json = Get-Content $configPath -Raw
            return $json | ConvertFrom-Json
        }
        
        return $null
    }
}

function Find-Airport {
    <#
    .SYNOPSIS
    Wrapper for Search-Airports from airport-codes.psm1
    #>
    [CmdletBinding()]
    param(
        [string]$Input
    )
    
    try {
        Write-Host "Looking for airport: $Input" -ForegroundColor Cyan
        
        # Try your actual Search-Airports function
        $result = Search-Airports -Query $Input -ErrorAction SilentlyContinue
        
        if ($result) {
            Write-Host "✅ Found via Search-Airports" -ForegroundColor Green
            return $result
        }
        
        # Try Get-Airport-Info as fallback
        $result = Get-Airport-Info -Code $Input -ErrorAction SilentlyContinue
        if ($result) {
            Write-Host "✅ Found via Get-Airport-Info" -ForegroundColor Green
            return $result
        }
        
        # Final fallback: simple lookup
        return Find-Airport-Simple $Input
        
    }
    catch {
        Write-Host "Error in Find-Airport: $_" -ForegroundColor Red
        return Find-Airport-Simple $Input
    }
}

function Find-Airport-Simple {
    <#
    .SYNOPSIS
    Simple airport lookup as fallback
    #>
    param([string]$Input)
    
    $airports = @{
        "newyork" = @{
            code = "JFK"
            name = "John F Kennedy International Airport"
            city = "New York"
            country = "United States"
        }
        "jfk" = @{
            code = "JFK"
            name = "John F Kennedy International Airport"
            city = "New York"
            country = "United States"
        }
        "dublin" = @{
            code = "DUB"
            name = "Dublin Airport"
            city = "Dublin"
            country = "Ireland"
        }
        "dub" = @{
            code = "DUB"
            name = "Dublin Airport"
            city = "Dublin"
            country = "Ireland"
        }
        "london" = @{
            code = "LHR"
            name = "London Heathrow Airport"
            city = "London"
            country = "United Kingdom"
        }
        "lhr" = @{
            code = "LHR"
            name = "London Heathrow Airport"
            city = "London"
            country = "United Kingdom"
        }
        "dubai" = @{
            code = "DXB"
            name = "Dubai International Airport"
            city = "Dubai"
            country = "United Arab Emirates"
        }
        "dxb" = @{
            code = "DXB"
            name = "Dubai International Airport"
            city = "Dubai"
            country = "United Arab Emirates"
        }
        "singapore" = @{
            code = "SIN"
            name = "Singapore Changi Airport"
            city = "Singapore"
            country = "Singapore"
        }
        "sin" = @{
            code = "SIN"
            name = "Singapore Changi Airport"
            city = "Singapore"
            country = "Singapore"
        }
        "chicago" = @{
            code = "ORD"
            name = "O'Hare International Airport"
            city = "Chicago"
            country = "United States"
        }
        "ord" = @{
            code = "ORD"
            name = "O'Hare International Airport"
            city = "Chicago"
            country = "United States"
        }
        "la" = @{
            code = "LAX"
            name = "Los Angeles International Airport"
            city = "Los Angeles"
            country = "United States"
        }
        "lax" = @{
            code = "LAX"
            name = "Los Angeles International Airport"
            city = "Los Angeles"
            country = "United States"
        }
        "new york" = @{
            code = "JFK"
            name = "John F Kennedy International Airport"
            city = "New York"
            country = "United States"
        }
        "los angeles" = @{
            code = "LAX"
            name = "Los Angeles International Airport"
            city = "Los Angeles"
            country = "United States"
        }
    }
    
    $key = $Input.Trim().ToLower()
    if ($airports.ContainsKey($key)) {
        return [PSCustomObject]$airports[$key]
    }
    
    return $null
}

function Parse-FlightQuery {
    <#
    .SYNOPSIS
    Wrapper for Parse-Flight-Query from nlp-processor.psm1
    #>
    [CmdletBinding()]
    param(
        [string]$Query
    )
    
    try {
        Write-Host "Parsing query: $Query" -ForegroundColor Cyan
        
        # Call your actual function
        $result = Parse-Flight-Query -Query $Query -ErrorAction SilentlyContinue
        
        if ($result) {
            # Check the format of your result
            if ($result.Success -ne $null) {
                # Your function already returns Success property
                Write-Host "✅ Parsed via Parse-Flight-Query" -ForegroundColor Green
                return $result
            }
            
            # Convert to expected format if different
            return [PSCustomObject]@{
                Success = $true
                Origin = $result.From
                OriginCode = $result.FromCode
                Destination = $result.To
                DestinationCode = $result.ToCode
                DepartureDate = $result.Date
                ReturnDate = $null
                Travelers = if ($result.Passengers) { $result.Passengers } else { 1 }
                Class = if ($result.Class) { $result.Class } else { "economy" }
                Direct = $false
            }
        }
        
        # Fallback: simple parsing
        return Parse-FlightQuery-Simple $Query
        
    }
    catch {
        Write-Host "Error in Parse-FlightQuery: $_" -ForegroundColor Red
        return Parse-FlightQuery-Simple $Query
    }
}

function Parse-FlightQuery-Simple {
    <#
    .SYNOPSIS
    Simple flight query parser as fallback
    #>
    param([string]$Query)
    
    # Very simple regex-based parser
    $pattern = "(?i)(from\s+)?(?<from>[a-z\s]+)\s+(to|->|-\s*>)\s+(?<to>[a-z\s]+)(?:\s+on\s+(?<date>[\w\s\d\/\-]+))?"
    
    if ($Query -match $pattern) {
        $from = $matches['from'].Trim()
        $to = $matches['to'].Trim()
        $date = if ($matches['date']) { $matches['date'].Trim() } else { "soon" }
        
        # Simple airport lookup
        $fromAirport = Find-Airport-Simple $from
        $toAirport = Find-Airport-Simple $to
        
        return [PSCustomObject]@{
            Success = $true
            Origin = if ($fromAirport) { $fromAirport.city } else { $from }
            OriginCode = if ($fromAirport) { $fromAirport.code } else { $from.ToUpper() }
            Destination = if ($toAirport) { $toAirport.city } else { $to }
            DestinationCode = if ($toAirport) { $toAirport.code } else { $to.ToUpper() }
            DepartureDate = $date
            ReturnDate = $null
            Travelers = 1
            Class = "economy"
            Direct = $false
        }
    }
    
    return [PSCustomObject]@{
        Success = $false
        Error = "Could not parse query"
    }
}

function Test-All-Modules {
    <#
    .SYNOPSIS
    Tests all modules using your actual functions
    #>
    Write-Host "=== Testing All Modules ===" -ForegroundColor Cyan
    
    Write-Host "`n1. Testing Configuration:" -ForegroundColor Yellow
    $config = Get-Configuration
    if ($config) {
        Write-Host "   ✅ Config loaded" -ForegroundColor Green
        Write-Host "   • Bot Token: $($config.TelegramBotToken.Substring(0,15))..." -ForegroundColor Gray
        Write-Host "   • TravelPayouts Key: $($config.TravelPayoutsAPIKey.Substring(0,10))..." -ForegroundColor Gray
    } else {
        Write-Host "   ❌ Config failed" -ForegroundColor Red
    }
    
    Write-Host "`n2. Testing Airport Lookup:" -ForegroundColor Yellow
    Write-Host "   Trying 'newyork'..." -ForegroundColor Gray
    $airport = Find-Airport "newyork"
    if ($airport) {
        Write-Host "   ✅ Found: $($airport.name) ($($airport.code))" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Not found" -ForegroundColor Red
    }
    
    Write-Host "`n3. Testing NLP Parser:" -ForegroundColor Yellow
    Write-Host "   Parsing: 'Newyork to Dubln on 20 Jan 2024'" -ForegroundColor Gray
    $parsed = Parse-FlightQuery "Newyork to Dubln on 20 Jan 2024"
    if ($parsed.Success) {
        Write-Host "   ✅ Parsed successfully!" -ForegroundColor Green
        Write-Host "   • From: $($parsed.Origin) ($($parsed.OriginCode))" -ForegroundColor Gray
        Write-Host "   • To: $($parsed.Destination) ($($parsed.DestinationCode))" -ForegroundColor Gray
        Write-Host "   • Date: $($parsed.DepartureDate)" -ForegroundColor Gray
    } else {
        Write-Host "   ❌ Parse failed: $($parsed.Error)" -ForegroundColor Red
    }
    
    Write-Host "`n4. Testing Telegram Module:" -ForegroundColor Yellow
    Write-Host "   Testing telegram-api.psm1..." -ForegroundColor Gray
    try {
        . $PSScriptRoot\telegram-api.psm1
        Write-Host "   ✅ Telegram module loaded" -ForegroundColor Green
    }
    catch {
        Write-Host "   ❌ Telegram module error: $_" -ForegroundColor Red
    }
    
    Write-Host "`n✅ All tests complete!" -ForegroundColor Green
}

# Test individual functions from your modules
function Test-Original-Functions {
    <#
    .SYNOPSIS
    Tests your original module functions directly
    #>
    Write-Host "=== Testing Original Functions ===" -ForegroundColor Cyan
    
    Write-Host "`n1. Testing Get-Config:" -ForegroundColor Yellow
    $config = Get-Config
    if ($config) {
        Write-Host "   ✅ Get-Config works" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Get-Config failed" -ForegroundColor Red
    }
    
    Write-Host "`n2. Testing Search-Airports:" -ForegroundColor Yellow
    $airport = Search-Airports -Query "newyork"
    if ($airport) {
        Write-Host "   ✅ Search-Airports works" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Search-Airports failed" -ForegroundColor Red
    }
    
    Write-Host "`n3. Testing Parse-Flight-Query:" -ForegroundColor Yellow
    $parsed = Parse-Flight-Query -Query "Newyork to Dubln"
    if ($parsed) {
        Write-Host "   ✅ Parse-Flight-Query works" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Parse-Flight-Query failed" -ForegroundColor Red
    }
    
    Write-Host "`n✅ Original functions test complete!" -ForegroundColor Green
}

Export-ModuleMember -Function @(
    'Get-Configuration',
    'Find-Airport',
    'Parse-FlightQuery',
    'Test-All-Modules',
    'Test-Original-Functions'
)
