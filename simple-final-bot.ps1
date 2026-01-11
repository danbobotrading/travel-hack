# simple-final-bot.ps1
# SIMPLE GUARANTEED WORKING VERSION

param(
    [switch]$Test,
    [switch]$Start
)

Write-Host "=== TRAVEL HACK BOT ===" -ForegroundColor Cyan
Write-Host "Bot: @trav_hackbot" -ForegroundColor Green

# Your working token
$token = "8579400784:AAHg5s8re1XJdYkdWF55STlb_TZ_Ujjf06Q"
$botName = "trav_hackbot"
$lastId = 0

# Simple airport lookup
function Find-City {
    param([string]$name)
    
    $cities = @{
        "newyork" = "New York (JFK)"
        "jfk" = "New York (JFK)"
        "dublin" = "Dublin (DUB)"
        "dub" = "Dublin (DUB)"
        "london" = "London (LHR)"
        "lhr" = "London (LHR)"
        "dubai" = "Dubai (DXB)"
        "dxb" = "Dubai (DXB)"
        "singapore" = "Singapore (SIN)"
        "sin" = "Singapore (SIN)"
        "chicago" = "Chicago (ORD)"
        "ord" = "Chicago (ORD)"
        "la" = "Los Angeles (LAX)"
        "lax" = "Los Angeles (LAX)"
        "los angeles" = "Los Angeles (LAX)"
    }
    
    $key = $name.ToLower()
    if ($cities.ContainsKey($key)) {
        return $cities[$key]
    }
    
    foreach ($k in $cities.Keys) {
        if ($key -like "*$k*") {
            return $cities[$k]
        }
    }
    
    return "$name"
}

# Simple parser
function Parse-Text {
    param([string]$text)
    
    if ($text -match "(?i)(\w+)\s+to\s+(\w+)") {
        $from = $matches[1]
        $to = $matches[2]
        
        return @{
            success = $true
            from = Find-City $from
            to = Find-City $to
        }
    }
    
    return @{success = $false; error = "Try: 'newyork to dublin'"}
}

# Telegram functions
function Send-Msg {
    param([string]$chat, [string]$msg)
    
    try {
        $uri = "https://api.telegram.org/bot$token/sendMessage"
        $body = @{
            chat_id = $chat
            text = $msg
            parse_mode = "Markdown"
        } | ConvertTo-Json
        
        Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType "application/json" | Out-Null
        Write-Host "Sent to $chat" -ForegroundColor Green
    }
    catch {
        Write-Host "Send error: $_" -ForegroundColor Red
    }
}

function Handle-Msg {
    param([string]$chat, [string]$text)
    
    Write-Host "[$chat]: $text" -ForegroundColor Cyan
    
    if ($text -eq "/start") {
        $msg = @"
✨ *Welcome to Travel Hack Bot!* ✈️

Ask for flights like:
• Newyork to Dubln
• LA to Chicago
• Dubai to Singapore

Try it now!
"@
        Send-Msg $chat $msg
    }
    elseif ($text -eq "/help") {
        Send-Msg $chat "Just type your flight request. Example: 'newyork to dublin'"
    }
    elseif ($text -eq "/status") {
        Send-Msg $chat "✅ Bot is working! @$botName"
    }
    else {
        $result = Parse-Text $text
        if ($result.success) {
            $msg = @"
✅ *Understood!*

From: $($result.from)
To: $($result.to)

*Next:* Flight search coming soon!
"@
            Send-Msg $chat $msg
        }
        else {
            Send-Msg $chat "❌ $($result.error)"
        }
    }
}

# Main bot loop
function Run-Bot {
    Write-Host "`n🚀 Starting bot..." -ForegroundColor Green
    Write-Host "🤖 Bot: @$botName" -ForegroundColor Cyan
    Write-Host "💡 Send /start on Telegram" -ForegroundColor Yellow
    Write-Host "🛑 Ctrl+C to stop" -ForegroundColor Red
    
    while ($true) {
        try {
            $uri = "https://api.telegram.org/bot$token/getUpdates"
            $body = @{
                offset = $lastId + 1
                timeout = 30
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType "application/json"
            
            foreach ($update in $response.result) {
                $script:lastId = $update.update_id
                
                if ($update.message) {
                    Handle-Msg $update.message.chat.id $update.message.text
                }
            }
        }
        catch {
            Write-Host "Poll error: $_" -ForegroundColor Yellow
            Start-Sleep -Seconds 10
        }
        
        Start-Sleep -Seconds 2
    }
}

# Test function
function Test-All {
    Write-Host "`nTesting..." -ForegroundColor Yellow
    
    Write-Host "1. Telegram: " -NoNewline
    try {
        $uri = "https://api.telegram.org/bot$token/getMe"
        $res = Invoke-RestMethod -Uri $uri -Method Get
        Write-Host "✅ @$($res.result.username)" -ForegroundColor Green
    }
    catch {
        Write-Host "❌" -ForegroundColor Red
    }
    
    Write-Host "2. Parser: " -NoNewline
    $parsed = Parse-Text "newyork to dublin"
    if ($parsed.success) {
        Write-Host "✅ $($parsed.from) → $($parsed.to)" -ForegroundColor Green
    }
    else {
        Write-Host "❌" -ForegroundColor Red
    }
    
    Write-Host "`n✅ Ready to start!" -ForegroundColor Green
}

# Execute
if ($Test) {
    Test-All
}
elseif ($Start) {
    Run-Bot
}
else {
    Write-Host "`nUsage:" -ForegroundColor Yellow
    Write-Host "  .\simple-final-bot.ps1 -Test" -ForegroundColor Gray
    Write-Host "  .\simple-final-bot.ps1 -Start" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Your bot is ready: @trav_hackbot" -ForegroundColor Cyan
}

Write-Host "`n=== Done ===" -ForegroundColor Cyan
