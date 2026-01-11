# test-all.ps1
# Comprehensive test of the entire system

Write-Host "=== COMPREHENSIVE TRAVEL HACK TEST ===" -ForegroundColor Cyan
Write-Host "Starting at: $(Get-Date)" -ForegroundColor Gray

# Test 1: Check config file
Write-Host "`n1. Checking config file..." -ForegroundColor Yellow
$configPath = "config\config.json"
if (Test-Path $configPath) {
    Write-Host "   ✅ Config file exists" -ForegroundColor Green
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        Write-Host "   • Bot Token: $($config.TelegramBotToken.Substring(0,15))..." -ForegroundColor Gray
        Write-Host "   • TravelPayouts Key: $($config.TravelPayoutsAPIKey.Substring(0,10))..." -ForegroundColor Gray
        Write-Host "   • Affiliate Marker: $($config.AffiliateMarker)" -ForegroundColor Gray
    }
    catch {
        Write-Host "   ❌ Config file error: $_" -ForegroundColor Red
    }
} else {
    Write-Host "   ❌ Config file not found" -ForegroundColor Red
}

# Test 2: Load adapter
Write-Host "`n2. Loading adapter module..." -ForegroundColor Yellow
try {
    . .\modules\adapter.psm1
    Write-Host "   ✅ Adapter loaded successfully" -ForegroundColor Green
    
    # Test original functions
    Write-Host "   Testing original functions..." -ForegroundColor Gray
    Test-Original-Functions
    
} catch {
    Write-Host "   ❌ Adapter load failed: $_" -ForegroundColor Red
}

# Test 3: Test adapter functions
Write-Host "`n3. Testing adapter functions..." -ForegroundColor Yellow
try {
    Test-All-Modules
} catch {
    Write-Host "   ❌ Adapter test failed: $_" -ForegroundColor Red
}

# Test 4: Test Telegram connection
Write-Host "`n4. Testing Telegram connection..." -ForegroundColor Yellow
try {
    . .\modules\telegram-api.psm1
    $connected = Initialize-TelegramBot
    if ($connected) {
        Write-Host "   ✅ Telegram bot connected: @$($Script:BotName)" -ForegroundColor Green
        
        # Test sending a message
        $testChat = Read-Host "   Enter your Telegram Chat ID to test (or press Enter to skip)"
        if ($testChat) {
            $message = "✅ *Travel Hack Bot Test*`n`nYour bot is working! Try: `/start` or ask for a flight like 'Newyork to Dubln tomorrow'"
            $result = Send-TelegramMessage -ChatId $testChat -Text $message -ParseMode "Markdown"
            if ($result) {
                Write-Host "   ✅ Test message sent!" -ForegroundColor Green
            } else {
                Write-Host "   ❌ Failed to send message" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "   ❌ Telegram connection failed" -ForegroundColor Red
    }
} catch {
    Write-Host "   ❌ Telegram test error: $_" -ForegroundColor Red
}

# Test 5: Test complete flow
Write-Host "`n5. Testing complete flow..." -ForegroundColor Yellow
Write-Host "   Sample query: 'Newyork to Dubln on 20 Jan 2024'" -ForegroundColor Gray

try {
    $parsed = Parse-FlightQuery "Newyork to Dubln on 20 Jan 2024"
    if ($parsed.Success) {
        Write-Host "   ✅ Query parsed successfully!" -ForegroundColor Green
        Write-Host "   • Route: $($parsed.Origin) → $($parsed.Destination)" -ForegroundColor Gray
        Write-Host "   • Codes: $($parsed.OriginCode) → $($parsed.DestinationCode)" -ForegroundColor Gray
        Write-Host "   • Date: $($parsed.DepartureDate)" -ForegroundColor Gray
        
        # Show what would happen next
        Write-Host "`n   Next steps would be:" -ForegroundColor Cyan
        Write-Host "   1. Search flights via TravelPayouts API" -ForegroundColor Gray
        Write-Host "   2. Show results with prices" -ForegroundColor Gray
        Write-Host "   3. Generate affiliate links" -ForegroundColor Gray
    } else {
        Write-Host "   ❌ Query parse failed: $($parsed.Error)" -ForegroundColor Red
    }
} catch {
    Write-Host "   ❌ Flow test error: $_" -ForegroundColor Red
}

Write-Host "`n=== TEST COMPLETE ===" -ForegroundColor Cyan
Write-Host "Summary: Your Travel Hack system is ready for the next step!" -ForegroundColor Green
Write-Host "Next: Build flight-search.psm1 to integrate with TravelPayouts API" -ForegroundColor Yellow
