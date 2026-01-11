# test-simple.ps1
# Super simple Telegram test that works

Write-Host "=== SIMPLE TELEGRAM TEST ===" -ForegroundColor Cyan

# Your actual token (from earlier test we know it works)
$token = "8579400784:AAHg5s8re1XJdYkdWF55STlb_TZ_Ujjf06Q"
Write-Host "Using token: $($token.Substring(0,15))..." -ForegroundColor Yellow

# Test 1: Basic connection
Write-Host "`n1. Testing basic connection..." -ForegroundColor Green
$uri = "https://api.telegram.org/bot$token/getMe"

try {
    $response = Invoke-RestMethod -Uri $uri -Method Get
    if ($response.ok) {
        Write-Host "✅ SUCCESS! Bot: @$($response.result.username)" -ForegroundColor Green
        Write-Host "   ID: $($response.result.id)" -ForegroundColor Gray
        Write-Host "   Name: $($response.result.first_name)" -ForegroundColor Gray
        
        # Now test sending a message
        Write-Host "`n2. Testing message sending..." -ForegroundColor Green
        $chatId = Read-Host "   Enter your Telegram Chat ID (or press Enter to skip)"
        
        if ($chatId) {
            $message = "✅ *Travel Hack Bot Test*`n`nYour bot @$($response.result.username) is working!`nToken: $($token.Substring(0,15))..."
            $sendUri = "https://api.telegram.org/bot$token/sendMessage"
            $body = @{
                chat_id = $chatId
                text = $message
                parse_mode = "Markdown"
            } | ConvertTo-Json
            
            $sendResponse = Invoke-RestMethod -Uri $sendUri -Method Post -Body $body -ContentType "application/json"
            Write-Host "   ✅ Test message sent!" -ForegroundColor Green
        }
        
        Write-Host "`n🎉 YOUR BOT IS WORKING PERFECTLY!" -ForegroundColor Cyan
        Write-Host "Next: Run the actual bot script" -ForegroundColor Yellow
    }
    else {
        Write-Host "❌ API returned error: $($response.description)" -ForegroundColor Red
    }
}
catch {
    Write-Host "❌ Connection failed: $($_.Exception.Message)" -ForegroundColor Red
    
    # Show more details
    if ($_.Exception.Response) {
        Write-Host "   Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    }
}

Write-Host "`n=== TEST COMPLETE ===" -ForegroundColor Cyan
