# test-token.ps1
# Test Telegram bot token

Write-Host "=== TELEGRAM TOKEN TEST ===" -ForegroundColor Cyan

# Read token from config
$configPath = "config\config.json"
if (Test-Path $configPath) {
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    $token = $config.TelegramBotToken
    
    Write-Host "Token from config: $($token.Substring(0,15))..." -ForegroundColor Yellow
    
    # Test 1: Basic connection
    Write-Host "`n1. Testing basic connection..." -ForegroundColor Cyan
    $uri = "https://api.telegram.org/bot$token/getMe"
    
    try {
        $response = Invoke-WebRequest -Uri $uri -Method Get -ErrorAction Stop
        Write-Host "   ✅ HTTP Status: $($response.StatusCode)" -ForegroundColor Green
        
        $data = $response.Content | ConvertFrom-Json
        if ($data.ok) {
            Write-Host "   ✅ Bot Info:" -ForegroundColor Green
            Write-Host "   • ID: $($data.result.id)" -ForegroundColor Gray
            Write-Host "   • Username: @$($data.result.username)" -ForegroundColor Gray
            Write-Host "   • Name: $($data.result.first_name)" -ForegroundColor Gray
        } else {
            Write-Host "   ❌ API Error: $($data.description)" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "   ❌ Connection failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test 2: Try with different method
    Write-Host "`n2. Testing with Invoke-RestMethod..." -ForegroundColor Cyan
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
        if ($response.ok) {
            Write-Host "   ✅ Success! Bot: @$($response.result.username)" -ForegroundColor Green
        } else {
            Write-Host "   ❌ Failed: $($response.description)" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "   ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test 3: Check if bot exists on Telegram
    Write-Host "`n3. Manual check:" -ForegroundColor Cyan
    Write-Host "   • Open Telegram" -ForegroundColor Gray
    Write-Host "   • Search for: @botfather" -ForegroundColor Gray
    Write-Host "   • Send: /mybots" -ForegroundColor Gray
    Write-Host "   • Check if your bot is listed" -ForegroundColor Gray
    
} else {
    Write-Host "❌ Config file not found" -ForegroundColor Red
}

Write-Host "`n=== TEST COMPLETE ===" -ForegroundColor Cyan
