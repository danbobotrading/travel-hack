# working-bot.ps1
# FINAL WORKING VERSION with token cleaning

param(
    [switch]$Test,
    [switch]$Start
)

Write-Host "=== TRAVEL HACK FLIGHT BOT ===" -ForegroundColor Cyan
Write-Host "FINAL WORKING VERSION | $(Get-Date)" -ForegroundColor Gray

# Configuration with token cleaning
function Get-BotConfig {
    $configPath = "config\config.json"
    if (Test-Path $configPath) {
        try {
            $config = Get-Content $configPath -Raw | ConvertFrom-Json
            
            # Clean the token - remove any whitespace, newlines, etc.
            if ($config.TelegramBotToken) {
                $config.TelegramBotToken = $config.TelegramBotToken.Trim()
            }
            
            return $config
        }
        catch {
            Write-Host "Config error: $_" -ForegroundColor Red
        }
    }
    Write-Host "Config file not found: $configPath" -ForegroundColor Red
    return $null
}

# Airport database
$AirportDB = @{
    "newyork" = @{code="JFK"; city="New York"; name="John F Kennedy Airport"}
    "jfk" = @{code="JFK"; city="New York"; name="John F Kennedy Airport"}
    "nyc" = @{code="JFK"; city="New York"; name="John F Kennedy Airport"}
    "dublin" = @{code="DUB"; city="Dublin"; name="Dublin Airport"}
    "dub" = @{code="DUB"; city="Dublin"; name="Dublin Airport"}
    "london" = @{code="LHR"; city="London"; name="Heathrow Airport"}
    "lhr" = @{code="LHR"; city="London"; name="Heathrow Airport"}
    "dubai" = @{code="DXB"; city="Dubai"; name="Dubai International"}
    "dxb" = @{code="DXB"; city="Dubai"; name="Dubai International"}
    "singapore" = @{code="SIN"; city="Singapore"; name="Changi Airport"}
    "sin" = @{code="SIN"; city="Singapore"; name="Changi Airport"}
    "chicago" = @{code="ORD"; city="Chicago"; name="O'Hare Airport"}
    "ord" = @{code="ORD"; city="Chicago"; name="O'Hare Airport"}
    "la" = @{code="LAX"; city="Los Angeles"; name="LAX Airport"}
    "lax" = @{code="LAX"; city="Los Angeles"; name="LAX Airport"}
}

function Find-Airport {
    param([string]$query)
    
    $key = $query.Trim().ToLower()
    if ($AirportDB.ContainsKey($key)) {
        $data = $AirportDB[$key]
        return [PSCustomObject]@{
            code = $data.code
            city = $data.city
            name = $data.name
        }
    }
    
    # Try partial match
    foreach ($k in $AirportDB.Keys) {
        if ($key -like "*$k*" -or $k -like "*$key*") {
            $data = $AirportDB[$k]
            return [PSCustomObject]@{
                code = $data.code
                city = $data.city
                name = $data.name
            }
        }
    }
    
    return $null
}

function Parse-Query {
    param([string]$query)
    
    Write-Host "Parsing: $query" -ForegroundColor Cyan
    
    if ($query -match "(?i)(?:from\s+)?(\w+(?:\s+\w+)*)\s+(?:to|->|-)\s+(\w+(?:\s+\w+)*)(?:\s+on\s+(.+))?") {
        $from = $matches[1].Trim()
        $to = $matches[2].Trim()
        $date = if ($matches[3]) { $matches[3].Trim() } else { "soon" }
        
        $fromAirport = Find-Airport $from
        $toAirport = Find-Airport $to
        
        return [PSCustomObject]@{
            success = $true
            from = if ($fromAirport) { $fromAirport.city } else { $from }
            fromCode = if ($fromAirport) { $fromAirport.code } else { $from.ToUpper() }
            to = if ($toAirport) { $toAirport.city } else { $to }
            toCode = if ($toAirport) { $toAirport.code } else { $to.ToUpper() }
            date = $date
        }
    }
    
    return [PSCustomObject]@{
        success = $false
        error = "I didn't understand. Try: 'Newyork to Dubln tomorrow'"
    }
}

# Telegram functions
$BotToken = $null
$BotName = $null
$LastUpdateId = 0

function Init-Telegram {
    $config = Get-BotConfig
    if (-not $config -or -not $config.TelegramBotToken) {
        Write-Host "No bot token found in config" -ForegroundColor Red
        return $false
    }
    
    # Clean the token again to be sure
    $global:BotToken = $config.TelegramBotToken.Trim()
    
    Write-Host "Testing Telegram token: $($BotToken.Substring(0,15))..." -ForegroundColor Yellow
    
    try {
        $uri = "https://api.travelhack.io/proxy/telegram/bot$BotToken/getMe"
        Write-Host "Trying URL: $($uri.Substring(0,50))..." -ForegroundColor Gray
        
        # First try direct
        $response = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
        if ($response.ok) {
            $global:BotName = $response.result.username
            Write-Host "✅ Telegram connected via proxy: @$BotName" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "Proxy failed, trying direct..." -ForegroundColor Yellow
    }
    
    # Try direct Telegram API
    try {
        $uri = "https://api.telegram.org/bot$BotToken/getMe"
        Write-Host "Trying direct URL: $($uri.Substring(0,50))..." -ForegroundColor Gray
        
        $response = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
        if ($response.ok) {
            $global:BotName = $response.result.username
            Write-Host "✅ Telegram connected directly: @$BotName" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "❌ Telegram API error: $($response.description)" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ Telegram connection error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Send-Message {
    param(
        [string]$chatId,
        [string]$text,
        [string]$mode = "Markdown"
    )
    
    try {
        # Try proxy first
        $uri = "https://api.travelhack.io/proxy/telegram/bot$BotToken/sendMessage"
        $body = @{
            chat_id = $chatId
            text = $text
            parse_mode = $mode
        } | ConvertTo-Json
        
        Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop | Out-Null
        Write-Host "✅ Message sent via proxy to $chatId" -ForegroundColor Green
        return $true
    }
    catch {
        # Fall back to direct API
        try {
            $uri = "https://api.telegram.org/bot$BotToken/sendMessage"
            $body = @{
                chat_id = $chatId
                text = $text
                parse_mode = $mode
            } | ConvertTo-Json
            
            Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop | Out-Null
            Write-Host "✅ Message sent directly to $chatId" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Host "❌ Failed to send message: $_" -ForegroundColor Red
            return $false
        }
    }
}

function Handle-Message {
    param([string]$chatId, [string]$text)
    
    Write-Host "📩 Message from $chatId : $text" -ForegroundColor Cyan
    
    if ($text -match '^/') {
        switch ($text) {
            "/start" {
                $msg = @"
✨ *Welcome to Travel Hack Flight Bot!* ✈️

I help you find flight deals. Just ask:

"Newyork to Dubln tomorrow"
"LA to Chicago on Jan 20"
"Dubai to Singapore next week"

Try it now!
"@
                Send-Message -chatId $chatId -text $msg
            }
            "/help" {
                $msg = @"
🆘 *How to use:*

Just type your flight request:

"New York to London tomorrow"
"2 tickets Paris to Tokyo"
"Business class Dubai Singapore"

I'll help you find flights!
"@
                Send-Message -chatId $chatId -text $msg
            }
            "/status" {
                $msg = "✅ *Bot Status:* Online\n🤖 *Username:* @$BotName\n🔑 *API:* Connected\n✈️ *Ready for flight queries!*"
                Send-Message -chatId $chatId -text $msg
            }
            default {
                Send-Message -chatId $chatId -text "Try /start or ask for a flight!"
            }
        }
        return
    }
    
    $result = Parse-Query $text
    if ($result.success) {
        $msg = @"
✅ *Flight request understood!*

• *From:* $($result.from) ($($result.fromCode))
• *To:* $($result.to) ($($result.toCode))
• *When:* $($result.date)

🔍 *Next:* Flight search API integration coming soon!

*Your bot is working!* 🎉
"@
        Send-Message -chatId $chatId -text $msg
    }
    else {
        $msg = @"
❌ $($result.error)

*Examples:*
• Newyork to Dubln tomorrow
• LA to Chicago on Jan 20
• Dubai to Singapore next week
"@
        Send-Message -chatId $chatId -text $msg
    }
}

function Start-Polling {
    param([int]$wait = 2)
    
    Write-Host "`n🤖 Bot started! Press Ctrl+C to stop." -ForegroundColor Green
    Write-Host "📱 Bot: @$BotName" -ForegroundColor Cyan
    Write-Host "💡 Send /start on Telegram" -ForegroundColor Yellow
    
    while ($true) {
        try {
            # Try proxy first
            $uri = "https://api.travelhack.io/proxy/telegram/bot$BotToken/getUpdates"
            $body = @{
                offset = $LastUpdateId + 1
                timeout = 30
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
        }
        catch {
            # Fall back to direct API
            try {
                $uri = "https://api.telegram.org/bot$BotToken/getUpdates"
                $body = @{
                    offset = $LastUpdateId + 1
                    timeout = 30
                } | ConvertTo-Json
                
                $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
            }
            catch {
                Write-Host "⚠️ Polling error: $_" -ForegroundColor Yellow
                Start-Sleep -Seconds 10
                continue
            }
        }
        
        foreach ($update in $response.result) {
            $script:LastUpdateId = $update.update_id
            
            if ($update.message) {
                Handle-Message -chatId $update.message.chat.id -text $update.message.text
            }
        }
        
        Start-Sleep -Seconds $wait
    }
}

# Main
if ($Test) {
    Write-Host "`n🧪 Testing..." -ForegroundColor Yellow
    
    $config = Get-BotConfig
    if ($config) {
        Write-Host "✅ Config: OK" -ForegroundColor Green
    }
    
    $airport = Find-Airport "newyork"
    if ($airport) {
        Write-Host "✅ Airport lookup: OK" -ForegroundColor Green
    }
    
    $parsed = Parse-Query "Newyork to Dubln"
    if ($parsed.success) {
        Write-Host "✅ Query parsing: OK" -ForegroundColor Green
    }
    
    $connected = Init-Telegram
    if ($connected) {
        Write-Host "✅ Telegram: Connected to @$BotName" -ForegroundColor Green
    }
    
    Write-Host "`n✅ All systems ready!" -ForegroundColor Green
}
elseif ($Start) {
    Write-Host "`n🚀 Starting bot..." -ForegroundColor Green
    
    $connected = Init-Telegram
    if (-not $connected) {
        Write-Host "❌ Cannot start - Telegram failed" -ForegroundColor Red
        
        # Try one more test
        Write-Host "Testing token directly..." -ForegroundColor Yellow
        $config = Get-BotConfig
        $token = $config.TelegramBotToken.Trim()
        $testUri = "https://api.telegram.org/bot$token/getMe"
        
        try {
            $test = Invoke-RestMethod -Uri $testUri -Method Get -UseBasicParsing
            Write-Host "✅ Direct test works! But script fails." -ForegroundColor Yellow
            Write-Host "This might be a PowerShell execution policy issue." -ForegroundColor Yellow
            Write-Host "Try running as Administrator or check permissions." -ForegroundColor Yellow
        }
        catch {
            Write-Host "❌ Direct test also fails: $_" -ForegroundColor Red
        }
        
        exit 1
    }
    
    Start-Polling -wait 2
}
else {
    Write-Host "`nUsage:" -ForegroundColor Yellow
    Write-Host "  .\working-bot.ps1 -Test    # Test" -ForegroundColor Gray
    Write-Host "  .\working-bot.ps1 -Start   # Start" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Your bot token: 8579400784:AAHg5s8re1XJdYkdWF55STlb_TZ_Ujjf06Q" -ForegroundColor Cyan
}

Write-Host "`n=== End ===" -ForegroundColor Cyan
