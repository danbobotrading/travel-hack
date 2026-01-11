# test-modules.ps1
# Test each module individually

Write-Host "=== Testing Individual Modules ===" -ForegroundColor Cyan

# Test 1: Config Manager
Write-Host "`n1. Testing Config Manager..." -ForegroundColor Yellow
try {
    . .\modules\config-manager.psm1
    $config = Get-Configuration
    Write-Host "   ✅ Loaded config:" -ForegroundColor Green
    Write-Host "   • Bot Token: $($config.TelegramBotToken.Substring(0,15))..." -ForegroundColor Gray
    Write-Host "   • TravelPayouts Key: $($config.TravelPayoutsAPIKey.Substring(0,10))..." -ForegroundColor Gray
}
catch {
    Write-Host "   ❌ Error: $_" -ForegroundColor Red
}

# Test 2: Airport Codes
Write-Host "`n2. Testing Airport Codes..." -ForegroundColor Yellow
try {
    . .\modules\airport-codes.psm1
    $airport = Find-Airport -Input "newyork"
    Write-Host "   ✅ Found airport:" -ForegroundColor Green
    Write-Host "   • Name: $($airport.name)" -ForegroundColor Gray
    Write-Host "   • Code: $($airport.code)" -ForegroundColor Gray
    Write-Host "   • City: $($airport.city)" -ForegroundColor Gray
}
catch {
    Write-Host "   ❌ Error: $_" -ForegroundColor Red
}

# Test 3: NLP Processor
Write-Host "`n3. Testing NLP Processor..." -ForegroundColor Yellow
try {
    . .\modules\nlp-processor.psm1
    $result = Parse-FlightQuery -Query "Newyork to Dubln on 20 Jan 2024 for 2 people business class"
    Write-Host "   ✅ Parsed query:" -ForegroundColor Green
    Write-Host "   • Success: $($result.Success)" -ForegroundColor Gray
    Write-Host "   • Origin: $($result.Origin) ($($result.OriginCode))" -ForegroundColor Gray
    Write-Host "   • Destination: $($result.Destination) ($($result.DestinationCode))" -ForegroundColor Gray
    Write-Host "   • Date: $($result.DepartureDate)" -ForegroundColor Gray
    Write-Host "   • Travelers: $($result.Travelers)" -ForegroundColor Gray
    Write-Host "   • Class: $($result.Class)" -ForegroundColor Gray
}
catch {
    Write-Host "   ❌ Error: $_" -ForegroundColor Red
}

# Test 4: Telegram API
Write-Host "`n4. Testing Telegram API..." -ForegroundColor Yellow
try {
    . .\modules\telegram-api.psm1
    $connected = Initialize-TelegramBot
    Write-Host "   ✅ Telegram connected: $connected" -ForegroundColor Green
    if ($connected) {
        Write-Host "   • Bot Name: @$($Script:BotName)" -ForegroundColor Gray
    }
}
catch {
    Write-Host "   ❌ Error: $_" -ForegroundColor Red
}

Write-Host "`n=== Tests Complete ===" -ForegroundColor Cyan
