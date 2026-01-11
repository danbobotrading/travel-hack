# Travel Hack - System Diagnosis
Write-Host "Travel Hack - System Diagnosis" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""

# 1. Check module loading
Write-Host "1. Module Loading Status:" -ForegroundColor Yellow
try {
    Import-Module .\modules\config-manager.psm1 -Force
    Write-Host "   ✅ config-manager loaded" -ForegroundColor Green
} catch {
    Write-Host "   ❌ config-manager failed: $_" -ForegroundColor Red
}

try {
    Import-Module .\modules\airport-codes.psm1 -Force
    Write-Host "   ✅ airport-codes loaded" -ForegroundColor Green
    
    # Check what functions are exported
    Write-Host "   Exported functions:" -ForegroundColor White
    Get-Module airport-codes | Select-Object -ExpandProperty ExportedFunctions | Format-Table
    
} catch {
    Write-Host "   ❌ airport-codes failed: $_" -ForegroundColor Red
}

try {
    Import-Module .\modules\nlp-processor.psm1 -Force
    Write-Host "   ✅ nlp-processor loaded" -ForegroundColor Green
} catch {
    Write-Host "   ❌ nlp-processor failed: $_" -ForegroundColor Red
}

Write-Host "`n2. Checking Airport Data Cache:" -ForegroundColor Yellow

# Check if cache file exists
if (Test-Path ".\data\airports.json") {
    $cacheSize = (Get-Item ".\data\airports.json").Length
    Write-Host "   Cache file exists: $cacheSize bytes" -ForegroundColor White
    
    try {
        $cacheContent = Get-Content ".\data\airports.json" -Raw
        $parsedCache = $cacheContent | ConvertFrom-Json
        
        Write-Host "   Cache parsed successfully" -ForegroundColor Green
        Write-Host "   Cache structure:" -ForegroundColor White
        
        $parsedCache.PSObject.Properties | ForEach-Object {
            if ($_.Value -is [System.Collections.IDictionary]) {
                Write-Host "     $($_.Name): Dictionary with $($_.Value.Count) items" -ForegroundColor White
            } elseif ($_.Value -is [Array]) {
                Write-Host "     $($_.Name): Array with $($_.Value.Count) items" -ForegroundColor White
            } else {
                Write-Host "     $($_.Name): $($_.Value)" -ForegroundColor White
            }
        }
        
        # Check specific properties
        if ($parsedCache.ByCode) {
            Write-Host "   ByCode dictionary type: $($parsedCache.ByCode.GetType().Name)" -ForegroundColor White
            Write-Host "   ByCode count (if Hashtable): $($parsedCache.ByCode.Count)" -ForegroundColor White
        }
        
    } catch {
        Write-Host "   ❌ Failed to parse cache: $_" -ForegroundColor Red
    }
} else {
    Write-Host "   ❌ Cache file not found" -ForegroundColor Red
}

Write-Host "`n3. Testing API Fetch Directly:" -ForegroundColor Yellow

try {
    $apiUrl = "http://api.travelpayouts.com/data/en/airports.json"
    Write-Host "   Fetching from API: $apiUrl" -ForegroundColor White
    
    $response = Invoke-RestMethod -Uri $apiUrl -Method Get -TimeoutSec 10
    
    Write-Host "   ✅ API call successful" -ForegroundColor Green
    Write-Host "   Received $($response.Count) items" -ForegroundColor White
    
    # Check first item structure
    if ($response.Count -gt 0) {
        $firstItem = $response[0]
        Write-Host "   First item structure:" -ForegroundColor White
        $firstItem.PSObject.Properties | Select-Object -First 5 Name, Value | Format-Table
        
        # Check for iata_type filter issue
        Write-Host "   Checking iata_type values:" -ForegroundColor White
        $iataTypes = $response | Group-Object iata_type | Select-Object Name, Count
        $iataTypes | Format-Table
        
        # Count how many are actual airports
        $airportCount = ($response | Where-Object { $_.iata_type -eq 'airport' }).Count
        Write-Host "   Actual airports (iata_type='airport'): $airportCount" -ForegroundColor White
    }
    
} catch {
    Write-Host "   ❌ API call failed: $_" -ForegroundColor Red
}

Write-Host "`n4. Testing Current Airport Module Functions:" -ForegroundColor Yellow

# First, let's manually initialize the data to see what happens
Write-Host "   Testing Initialize-AirportData function..." -ForegroundColor White

try {
    # Call the function directly
    Initialize-AirportData
    
    # Check global variable
    if ($global:AirportData) {
        Write-Host "   ✅ AirportData initialized" -ForegroundColor Green
        Write-Host "   AirportData type: $($global:AirportData.GetType().Name)" -ForegroundColor White
        
        # Check structure
        Write-Host "   AirportData properties:" -ForegroundColor White
        $global:AirportData.PSObject.Properties | ForEach-Object {
            if ($_.Value -is [System.Collections.IDictionary]) {
                Write-Host "     $($_.Name): $($_.Value.Count) items" -ForegroundColor White
            } elseif ($_.Value -is [Array]) {
                Write-Host "     $($_.Name): $($_.Value.Count) items" -ForegroundColor White
            } else {
                Write-Host "     $($_.Name): $($_.Value)" -ForegroundColor White
            }
        }
        
        # Test ContainsKey method
        Write-Host "`n   Testing ContainsKey method on ByCode..." -ForegroundColor White
        if ($global:AirportData.ByCode) {
            Write-Host "   ByCode is not null" -ForegroundColor White
            Write-Host "   ByCode type: $($global:AirportData.ByCode.GetType().Name)" -ForegroundColor White
            
            # Try different ways to check keys
            Write-Host "   Testing key access methods:" -ForegroundColor White
            try {
                # Method 1: ContainsKey
                $test1 = $global:AirportData.ByCode.ContainsKey('JFK')
                Write-Host "     ContainsKey('JFK'): $test1" -ForegroundColor White
            } catch {
                Write-Host "     ❌ ContainsKey failed: $_" -ForegroundColor Red
            }
            
            try {
                # Method 2: Try get value
                $test2 = $global:AirportData.ByCode['JFK']
                Write-Host "     ByCode['JFK']: $($test2 -ne $null)" -ForegroundColor White
            } catch {
                Write-Host "     ❌ ByCode['JFK'] failed: $_" -ForegroundColor Red
            }
            
            try {
                # Method 3: PSObject properties
                $test3 = $global:AirportData.ByCode.PSObject.Properties['JFK']
                Write-Host "     PSObject.Properties['JFK']: $($test3 -ne $null)" -ForegroundColor White
            } catch {
                Write-Host "     ❌ PSObject.Properties failed: $_" -ForegroundColor Red
            }
        }
        
    } else {
        Write-Host "   ❌ AirportData is null" -ForegroundColor Red
    }
    
} catch {
    Write-Host "   ❌ Initialize-AirportData failed: $_" -ForegroundColor Red
}

Write-Host "`n5. Testing Search-Airports Function:" -ForegroundColor Yellow

try {
    # Check if function exists
    $functionExists = Get-Command Search-Airports -ErrorAction SilentlyContinue
    if ($functionExists) {
        Write-Host "   ✅ Search-Airports function exists" -ForegroundColor Green
        
        # Test it
        $results = Search-Airports -SearchTerm "new" -Limit 3
        Write-Host "   Search results for 'new': $($results.Count)" -ForegroundColor White
        
    } else {
        Write-Host "   ❌ Search-Airports function not found" -ForegroundColor Red
        Write-Host "   Available functions from airport-codes:" -ForegroundColor White
        Get-Command -Module airport-codes | Format-Table Name
    }
} catch {
    Write-Host "   ❌ Search-Airports test failed: $_" -ForegroundColor Red
}

Write-Host "`n6. Examining Module Export Issues:" -ForegroundColor Yellow

# Check the airport-codes module file
Write-Host "   Checking airport-codes.psm1 export statements..." -ForegroundColor White
$moduleContent = Get-Content ".\modules\airport-codes.psm1" -Raw
if ($moduleContent -match "Export-ModuleMember.*") {
    Write-Host "   Found Export-ModuleMember statement" -ForegroundColor White
    $matchInfo = $matches[0]
    Write-Host "   Export statement: $matchInfo" -ForegroundColor White
} else {
    Write-Host "   ❌ No Export-ModuleMember found!" -ForegroundColor Red
}

Write-Host "`n🎉 Diagnosis complete!" -ForegroundColor Green
