# NLP Processor - Simple and Reliable
# Parses natural language flight queries

# Import configuration
Import-Module .\modules\config-manager.psm1 -Force -ErrorAction SilentlyContinue

function Parse-Flight-Query {
    param(
        [string]$Query
    )
    
    Write-Log ("Parsing flight query: " + $Query) "INFO"
    
    $result = [PSCustomObject]@{
        Success = $false
        Error = ""
        RawQuery = $Query
        Origin = ""
        Destination = ""
        DepartureDate = ""
        ReturnDate = ""
        Travelers = 1
        Class = "economy"
        Direct = $false
        ParsedOrigin = $null
        ParsedDestination = $null
    }
    
    try {
        $queryLower = $Query.ToLower()
        
        # Extract locations using simple pattern matching
        if ($queryLower -match "from\s+([^0-9]+?)\s+to\s+([^0-9]+?)(?:\s+|$)") {
            $result.Origin = ($matches[1].Trim() -replace "\s+", " ")
            $result.Destination = ($matches[2].Trim() -replace "\s+", " ")
        }
        elseif ($queryLower -match "([^0-9]+?)\s+to\s+([^0-9]+?)(?:\s+|$)") {
            $result.Origin = ($matches[1].Trim() -replace "\s+", " ")
            $result.Destination = ($matches[2].Trim() -replace "\s+", " ")
        }
        
        # Clean up location text
        $cleanWords = @(" on", " for", " with", " in", " at", " the", " a", " an", " and", " or")
        foreach ($word in $cleanWords) {
            if ($result.Origin.EndsWith($word)) {
                $result.Origin = $result.Origin.Substring(0, $result.Origin.Length - $word.Length).Trim()
            }
            if ($result.Destination.EndsWith($word)) {
                $result.Destination = $result.Destination.Substring(0, $result.Destination.Length - $word.Length).Trim()
            }
        }
        
        # Extract dates with simple patterns
        # Pattern: 20 Jan 2024
        if ($queryLower -match "(\d{1,2}\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+\d{4})") {
            $result.DepartureDate = Format-Date $matches[1]
        }
        
        # Pattern: 2024-01-20
        if ($queryLower -match "(\d{4}-\d{1,2}-\d{1,2})") {
            $result.DepartureDate = $matches[1]
        }
        
        # Pattern: 01/20/2024
        if ($queryLower -match "(\d{1,2}/\d{1,2}/\d{4})") {
            $result.DepartureDate = Format-Date $matches[1]
        }
        
        # Return dates
        if ($queryLower -match "(?:back|return|returning)\s+on\s+([a-z0-9\s\-/]+)") {
            $returnText = $matches[1].Trim()
            if ($returnText -match "\d") {
                $result.ReturnDate = Format-Date $returnText
            }
        }
        
        # Extract number of travelers
        if ($queryLower -match "(\d+)\s*(?:person|people|traveler|passenger|adult)s?") {
            $result.Travelers = [int]$matches[1]
        }
        elseif ($queryLower -match "for\s+(\d+)(?:\s+(?:person|people|traveler|passenger|adult))?") {
            $result.Travelers = [int]$matches[1]
        }
        
        # Extract flight class
        if ($queryLower -match "(business|first\s*class|first)") {
            $result.Class = "business"
        }
        elseif ($queryLower -match "(premium\s*economy|premium)") {
            $result.Class = "premium_economy"
        }
        
        # Direct flights
        if ($queryLower -match "(direct|nonstop|no\s*stop)") {
            $result.Direct = $true
        }
        
        # Validate we have the basics
        if ([string]::IsNullOrWhiteSpace($result.Origin) -or 
            [string]::IsNullOrWhiteSpace($result.Destination) -or 
            [string]::IsNullOrWhiteSpace($result.DepartureDate)) {
            
            $missing = @()
            if ([string]::IsNullOrWhiteSpace($result.Origin)) { $missing += "origin" }
            if ([string]::IsNullOrWhiteSpace($result.Destination)) { $missing += "destination" }
            if ([string]::IsNullOrWhiteSpace($result.DepartureDate)) { $missing += "departure date" }
            
            $result.Error = "Missing required information: " + ($missing -join ", ")
            $result.Success = $false
        } else {
            $result.Success = $true
        }
        
    }
    catch {
        $result.Error = "Parse error: " + $_
        $result.Success = $false
        Write-Log ("Parse error: " + $_) "ERROR"
    }
    
    return $result
}

function Format-Date {
    param(
        [string]$DateString
    )
    
    try {
        # Already in correct format?
        if ($DateString -match "^\d{4}-\d{2}-\d{2}$") {
            return $DateString
        }
        
        # Try to parse
        $parsedDate = $null
        if ([datetime]::TryParse($DateString, [ref]$parsedDate)) {
            return $parsedDate.ToString("yyyy-MM-dd")
        }
        
        # Try month names
        $monthMap = @{
            "jan" = 1; "january" = 1
            "feb" = 2; "february" = 2
            "mar" = 3; "march" = 3
            "apr" = 4; "april" = 4
            "may" = 5
            "jun" = 6; "june" = 6
            "jul" = 7; "july" = 7
            "aug" = 8; "august" = 8
            "sep" = 9; "september" = 9
            "oct" = 10; "october" = 10
            "nov" = 11; "november" = 11
            "dec" = 12; "december" = 12
        }
        
        # Try pattern: 20 Jan 2024
        if ($DateString -match "(\d{1,2})\s+([a-z]+)\s+(\d{4})") {
            $day = $matches[1].PadLeft(2, '0')
            $monthText = $matches[2].ToLower()
            $year = $matches[3]
            
            if ($monthMap.ContainsKey($monthText)) {
                $month = $monthMap[$monthText].ToString().PadLeft(2, '0')
                return "$year-$month-$day"
            }
        }
        
        return $DateString
    }
    catch {
        return $DateString
    }
}

function Test-Flight-Parser {
    param(
        [string]$Query
    )
    
    Write-Host "`nTesting query: '$Query'" -ForegroundColor Cyan
    
    $parsed = Parse-Flight-Query $Query
    
    if ($parsed.Success) {
        Write-Host "✅ Parsed successfully!" -ForegroundColor Green
        
        Write-Host "`n✈️  Flight Details:" -ForegroundColor Yellow
        Write-Host "  From: $($parsed.Origin)" -ForegroundColor White
        Write-Host "  To: $($parsed.Destination)" -ForegroundColor White
        Write-Host "  Depart: $($parsed.DepartureDate)" -ForegroundColor White
        
        if ($parsed.ReturnDate) {
            Write-Host "  Return: $($parsed.ReturnDate)" -ForegroundColor White
        }
        
        Write-Host "  Travelers: $($parsed.Travelers)" -ForegroundColor White
        Write-Host "  Class: $($parsed.Class)" -ForegroundColor White
        
        if ($parsed.Direct) {
            Write-Host "  Direct: Yes" -ForegroundColor White
        }
        
        # Now try to find airports
        Import-Module .\modules\airport-codes.psm1 -Force -ErrorAction SilentlyContinue
        
        $originAirport = Get-Airport-Info -InputText $parsed.Origin
        $destAirport = Get-Airport-Info -InputText $parsed.Destination
        
        if ($originAirport.Found -and $destAirport.Found) {
            Write-Host "`n📍 Airport Details:" -ForegroundColor Green
            Write-Host "  ✈️  $($originAirport.City) ($($originAirport.Code)) → $($destAirport.City) ($($destAirport.Code))" -ForegroundColor White
            Write-Host "  🎯 Match confidence: $($originAirport.Confidence)/$($destAirport.Confidence)" -ForegroundColor White
            
            # Show alternatives if any
            if ($originAirport.Alternatives -or $destAirport.Alternatives) {
                Write-Host "`n💡 Alternative airports available:" -ForegroundColor Cyan
                if ($originAirport.Alternatives) {
                    Write-Host "  Origin alternatives:" -ForegroundColor White
                    foreach ($alt in $originAirport.Alternatives) {
                        Write-Host "    • $($alt.FullDisplay)" -ForegroundColor Gray
                    }
                }
                if ($destAirport.Alternatives) {
                    Write-Host "  Destination alternatives:" -ForegroundColor White
                    foreach ($alt in $destAirport.Alternatives) {
                        Write-Host "    • $($alt.FullDisplay)" -ForegroundColor Gray
                    }
                }
            }
            
            # Return complete result
            $parsed.ParsedOrigin = $originAirport
            $parsed.ParsedDestination = $destAirport
            
        } else {
            Write-Host "`n❌ Airport lookup failed" -ForegroundColor Red
            if (-not $originAirport.Found) {
                Write-Host "  Could not find airport for: $($parsed.Origin)" -ForegroundColor Red
            }
            if (-not $destAirport.Found) {
                Write-Host "  Could not find airport for: $($parsed.Destination)" -ForegroundColor Red
            }
        }
        
    } else {
        Write-Host "❌ Parse failed: $($parsed.Error)" -ForegroundColor Red
    }
    
    return $parsed
}

Export-ModuleMember -Function Parse-Flight-Query, Test-Flight-Parser
