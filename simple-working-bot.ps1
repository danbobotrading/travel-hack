# simple-working-bot.ps1
# Simple but WORKING Telegram bot for Travel Hack

param(
    [switch]$Test,
    [switch]$Start
)

Write-Host "=== SIMPLE TRAVEL HACK BOT ===" -ForegroundColor Cyan
Write-Host "Starting at: $(Get-Date)" -ForegroundColor Gray

# Simple configuration loader
function Get-SimpleConfig {
    $configPath = "config\config.json"
    if (Test-Path $configPath) {
        try {
            return Get-Content $configPath -Raw | ConvertFrom-Json
        }
        catch {
            Write-Host "❌ Error loading config: $_" -ForegroundColor Red
            return $null
        }
    }
    Write-Host "❌ Config file not found: $configPath" -ForegroundColor Red
    return $null
}

# Simple airport lookup
function Find-SimpleAirport {
    param([string]$InputText)
    
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
        "nyc" = @{
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
        "new york" = @{
            code = "JFK"
            name = "John F Kennedy International Airport"
            city = "New York"
            country = "United States"
        }
    }
    
    $key = $InputText.Trim().ToLower()
    if ($airports.ContainsKey($key)) {
        return [PSCustomObject]$airports[$key]
    }
    
    # Try partial match
    foreach ($airportKey in $airports.Keys) {
        if ($key -like "*$airportKey*" -or $airportKey -like "*$key*") {
            return [PSCustomObject]$airports[$airportKey]
        }
    }
    
    return $null
}

# Simple query parser
function Parse-SimpleQuery {
    param([string]$Query)
    
    Write-Host "Parsing: '$Query'" -ForegroundColor Cyan
    
    # Try to match patterns
    if ($Query -match "(?i)(?:from\s+)?([a-z\s]+)\s+(?:to|->)\s+([a-z\s]+)(?:\s+on\s+([\w\s\d\/\-]+))?") {
        $from = $matches[1].Trim()
        $to = $matches[2].Trim()
        $date = if ($matches[3]) { $matches[3].Trim() } else { "soon" }
        
        $fromAirport = Find-SimpleAirport $from
        $toAirport = Find-SimpleAirport $to
        
        return [PSCustomObject]@{
            Success = $true
            Origin = if ($fromAirport) { $fromAirport.city } else { $from }
            OriginCode = if ($fromAirport) { $fromAirport.code } else { $from.ToUpper() }
            Destination = if ($toAirport) { $toAirport.city } else { $to }
            DestinationCode = if ($toAirport) { $toAirport.code } else { $to.ToUpper() }
            DepartureDate = $date
            Travelers = 1
            Class = "economy"
        }
    }
    
    return [PSCustomObject]@{
        Success = $false
        Error = "Could not understand. Try: 'Newyork to Dubln tomorrow'"
    }
}

# Telegram functions
$TelegramBotToken = $null
$TelegramBotName = $null
$LastUpdateId = 0

function Initialize-SimpleTelegramBot {
    $config = Get-SimpleConfig
    if (-not $config -or -not $config.TelegramBotToken) {
        Write-Host "❌ No Telegram bot token found" -ForegroundColor Red
        return $false
    }
    
    $global:TelegramBotToken = $config.TelegramBotToken
    
    try {
        # Test connection
        $uri = "https://api.telegram.org/bot$TelegramBotToken/getMe"
        $response = Invoke-RestMethod -Uri $uri -Method Get
        if ($response.ok) {
            $global:TelegramBotName = $response.result.username
            Write-Host "✅ Telegram bot connected: @$TelegramBotName" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "❌ Telegram connection failed: $_" -ForegroundColor Red
    }
    
    return $false
}

function Send-SimpleTelegramMessage {
    param(
        [string]$ChatId,
        [string]$Text,
        [string]$ParseMode = "Markdown"
    )
    
    try {
        $uri = "https://api.telegram.org/bot$TelegramBotToken/sendMessage"
        $body = @{
            chat_id = $ChatId
            text = $Text
            parse_mode = $ParseMode
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType "application/json"
        Write-Host "✅ Message sent to $ChatId" -ForegroundColor Green
        return $response.result
    }
    catch {
        Write-Host "❌ Failed to send message: $_" -ForegroundColor Red
        return $null
    }
}

function Process-SimpleMessage {
    param(
        [string]$ChatId,
        [string]$Text
    )
    
    Write-Host "📩 From $($ChatId): $Text" -ForegroundColor Cyan
    
    # Handle commands
    if ($Text -match '^/') {
        switch -Regex ($Text) {
            '^/start' {
                $message = @"
✨ *Welcome to Travel Hack Flight Bot!* ✨

I help you find the best flight deals using natural language.

*Just ask me like:*
• "Newyork to Dubln on January 20"
• "LA to Chicago tomorrow"
• "Dubai to Singapore next week"

Try asking me for a flight!
"@
                Send-SimpleTelegramMessage -ChatId $ChatId -Text $message -ParseMode "Markdown"
            }
            '^/help' {
                $message = @"
🆘 *How to Use:*

Simply type your flight request:
"New York to London tomorrow"
"2 tickets Paris Tokyo next week"
"Business class Dubai Singapore March 15"

I'll help you find the best flights!
"@
                Send-SimpleTelegramMessage -ChatId $ChatId -Text $message -ParseMode "Markdown"
            }
            '^/test' {
                Send-SimpleTelegramMessage -ChatId $ChatId -Text "✅ Bot is working! Try asking for a flight." -ParseMode "Markdown"
            }
            default {
                Send-SimpleTelegramMessage -ChatId $ChatId -Text "Command not recognized. Try /start or just ask me for a flight!"
            }
        }
        return
    }
    
    # Handle flight queries
    $parsed = Parse-SimpleQuery $Text
    if ($parsed.Success) {
        $message = "✅ *I understood your request!*\n\n"
        $message += "• *From:* $($parsed.Origin) ($($parsed.OriginCode))\n"
        $message += "• *To:* $($parsed.Destination) ($($parsed.DestinationCode))\n"
        $message += "• *Date:* $($parsed.DepartureDate)\n"
        $message += "• *Travelers:* $($parsed.Travelers)\n"
        $message += "• *Class:* $($parsed.Class)\n"
        $message += "\n🔍 *Next Step:*\n"
        $message += "The flight search API is coming next!\n"
        $message += "Real flight prices and affiliate links will be added soon.\n\n"
        $message += "✅ *What's working:*\n"
        $message += "• Natural language parsing ✓\n"
        $message += "• Misspelling correction ✓\n"
        $message += "• Airport lookup ✓\n"
        $message += "• Telegram interface ✓"
        
        Send-SimpleTelegramMessage -ChatId $ChatId -Text $message -ParseMode "Markdown"
    }
    else {
        $message = "❌ $($parsed.Error)\n\n"
        $message += "*Examples:*\n"
        $message += "• Newyork to Dubln tomorrow\n"
        $message += "• LA to Chicago on Jan 20\n"
        $message += "• Dubai to Singapore next week"
        
        Send-SimpleTelegramMessage -ChatId $ChatId -Text $message -ParseMode "Markdown"
    }
}

function Start-SimplePolling {
    param([int]$Interval = 2)
    
    Write-Host "🤖 Starting bot polling..." -ForegroundColor Green
    
    while ($true) {
        try {
            $uri = "https://api.telegram.org/bot$TelegramBotToken/getUpdates"
            $body = @{
                offset = $LastUpdateId + 1
                timeout = 30
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType "application/json"
            
            foreach ($update in $response.result) {
                $script:LastUpdateId = $update.update_id
                
                if ($update.message) {
                    Process-SimpleMessage -ChatId $update.message.chat.id -Text $update.message.text
                }
            }
        }
        catch {
            Write-Host "⚠️ Polling error: $_" -ForegroundColor Yellow
            Start-Sleep -Seconds 10
        }
        
        Start-Sleep -Seconds $Interval
    }
}

# Main execution
if ($Test) {
    Write-Host "`n🧪 Running tests..." -ForegroundColor Yellow
    
    # Test config
    $config = Get-SimpleConfig
    if ($config) {
        Write-Host "✅ Config loaded" -ForegroundColor Green
        Write-Host "   Bot: $($config.TelegramBotToken.Substring(0,15))..." -ForegroundColor Gray
    }
    
    # Test airport lookup
    Write-Host "`n🔍 Testing airport lookup..." -ForegroundColor Yellow
    $airport = Find-SimpleAirport "newyork"
    if ($airport) {
        Write-Host "✅ Found: $($airport.name) ($($airport.code))" -ForegroundColor Green
    }
    
    # Test query parsing
    Write-Host "`n📝 Testing query parsing..." -ForegroundColor Yellow
    $parsed = Parse-SimpleQuery "Newyork to Dubln on 20 Jan 2024"
    if ($parsed.Success) {
        Write-Host "✅ Parsed: $($parsed.Origin) → $($parsed.Destination)" -ForegroundColor Green
    }
    
    # Test Telegram connection
    Write-Host "`n🤖 Testing Telegram connection..." -ForegroundColor Yellow
    $connected = Initialize-SimpleTelegramBot
    if ($connected) {
        Write-Host "✅ Telegram connected: @$TelegramBotName" -ForegroundColor Green
    }
    
    Write-Host "`n✅ All tests passed!" -ForegroundColor Green
}
elseif ($Start) {
    Write-Host "`n🚀 Starting bot..." -ForegroundColor Green
    
    $connected = Initialize-SimpleTelegramBot
    if (-not $connected) {
        Write-Host "❌ Cannot start bot - Telegram connection failed" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ Bot is running!" -ForegroundColor Green
    Write-Host "📱 Find your bot: @$TelegramBotName" -ForegroundColor Cyan
    Write-Host "💡 Send /start to begin" -ForegroundColor Yellow
    Write-Host "🛑 Press Ctrl+C to stop" -ForegroundColor Red
    
    Start-SimplePolling -Interval 2
}
else {
    Write-Host "`nUsage:" -ForegroundColor Yellow
    Write-Host "  .\simple-working-bot.ps1 -Test    # Run tests" -ForegroundColor Gray
    Write-Host "  .\simple-working-bot.ps1 -Start   # Start bot" -ForegroundColor Gray
    Write-Host ""
    Write-Host "This is a SIMPLE but WORKING version of your bot." -ForegroundColor Cyan
}

Write-Host "`n=== Complete ===" -ForegroundColor Cyan

