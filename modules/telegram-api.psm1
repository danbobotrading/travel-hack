# modules/telegram-api.psm1
# Telegram Bot Interface for Travel Hack Flight Bot

# Module metadata
$Script:ModuleVersion = "1.0.0"
$Script:BotToken = $null
$Script:BotName = $null
$Script:LastUpdateId = 0
$Script:UserSessions = @{}
$Script:BaseApiUrl = "https://api.telegram.org/bot"

function Initialize-TelegramBot {
    <#
    .SYNOPSIS
    Initializes the Telegram bot with configuration
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-Host "Initializing Telegram Bot..." -ForegroundColor Yellow
        
        # Import config manager using dot sourcing
        . "$PSScriptRoot\config-manager.psm1"
        
        # Load configuration
        $config = Get-Configuration
        
        if (-not $config.TelegramBotToken) {
            throw "Telegram Bot Token not found in configuration"
        }
        
        $Script:BotToken = $config.TelegramBotToken
        $Script:BaseApiUrl = "https://api.telegram.org/bot$($Script:BotToken)/"
        
        # Test bot connection
        $me = Invoke-TelegramMethod "getMe"
        $Script:BotName = $me.result.username
        
        Write-Host "✅ Telegram Bot initialized: @$Script:BotName" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Failed to initialize Telegram bot: $_" -ForegroundColor Red
        return $false
    }
}

function Invoke-TelegramMethod {
    <#
    .SYNOPSIS
    Invokes a Telegram Bot API method
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Method,
        
        [hashtable]$Body = @{}
    )
    
    try {
        $uri = "$($Script:BaseApiUrl)$Method"
        
        $params = @{
            Uri = $uri
            Method = 'Post'
            ContentType = 'application/json'
            Headers = @{'Accept' = 'application/json'}
        }
        
        if ($Body.Count -gt 0) {
            $jsonBody = $Body | ConvertTo-Json -Depth 10
            $params.Body = $jsonBody
        }
        
        Write-Host "📡 Telegram API: $Method" -ForegroundColor Cyan
        
        $response = Invoke-RestMethod @params -ErrorAction Stop
        
        if (-not $response.ok) {
            throw "Telegram API error: $($response.description)"
        }
        
        return $response
    }
    catch {
        Write-Host "❌ Telegram API call failed: $_" -ForegroundColor Red
        throw
    }
}

function Send-TelegramMessage {
    <#
    .SYNOPSIS
    Sends a message to a Telegram chat
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ChatId,
        
        [Parameter(Mandatory=$true)]
        [string]$Text,
        
        [string]$ParseMode = "Markdown"
    )
    
    try {
        $method = "sendMessage"
        $body = @{
            chat_id = $ChatId
            text = $Text
            parse_mode = $ParseMode
        }
        
        $result = Invoke-TelegramMethod $method $body
        
        Write-Host "✅ Message sent to chat $ChatId" -ForegroundColor Green
        return $result.result
    }
    catch {
        Write-Host "❌ Failed to send message: $_" -ForegroundColor Red
        return $null
    }
}

function Start-TelegramPolling {
    <#
    .SYNOPSIS
    Starts polling for Telegram messages
    #>
    [CmdletBinding()]
    param(
        [int]$PollingInterval = 2
    )
    
    Write-Host "🤖 Starting Telegram Bot polling..." -ForegroundColor Yellow
    
    if (-not $Script:BotToken) {
        $initialized = Initialize-TelegramBot
        if (-not $initialized) {
            throw "Failed to initialize bot"
        }
    }
    
    # Main polling loop
    while ($true) {
        try {
            $method = "getUpdates"
            $body = @{
                offset = $Script:LastUpdateId + 1
                timeout = 30
            }
            
            $updates = Invoke-TelegramMethod $method $body
            
            foreach ($update in $updates.result) {
                $Script:LastUpdateId = $update.update_id
                
                if ($update.message) {
                    Process-IncomingMessage $update.message
                }
            }
        }
        catch {
            Write-Host "⚠️ Error in polling: $_" -ForegroundColor Yellow
            Start-Sleep -Seconds 10
        }
        
        Start-Sleep -Seconds $PollingInterval
    }
}

function Process-IncomingMessage {
    <#
    .SYNOPSIS
    Processes incoming messages
    #>
    param(
        [Parameter(Mandatory=$true)]
        [psobject]$Message
    )
    
    $chatId = $Message.chat.id
    $text = $Message.text
    $messageId = $Message.message_id
    
    Write-Host "📩 Message from $chatId: $text" -ForegroundColor Cyan
    
    # Handle commands
    if ($text -match '^/') {
        Process-Command $chatId $text
        return
    }
    
    # Handle flight queries
    Process-FlightQuery $chatId $text
}

function Process-Command {
    <#
    .SYNOPSIS
    Processes bot commands
    #>
    param(
        [string]$ChatId,
        [string]$Command
    )
    
    switch -Regex ($Command) {
        '^/start' {
            $welcome = @"
✨ *Welcome to Travel Hack Flight Bot!* ✨

I help you find the best flight deals using natural language.

*Just ask me like:*
• "Newyork to Dubln on January 20"
• "2 tickets Paris Tokyo next week"
• "Business class Dubai Singapore March 15"

*I understand:*
✅ Natural language
✅ Misspellings (newyork → New York)
✅ Airport codes (JFK, LHR)
✅ Multiple date formats

Try asking me for a flight!
"@
            
            Send-TelegramMessage -ChatId $ChatId -Text $welcome -ParseMode "Markdown"
        }
        '^/help' {
            $help = @"
🆘 *How to Use:*

Simply type your flight request:
"New York to London tomorrow"
"2 tickets Paris Tokyo next week"
"Business class Dubai Singapore March 15"

*Examples:*
• "LA to Chcago on 12/15/2024"
• "Newyork to Dubln on 20 Jan 2024"
• "business class from Dubay to Singapor"

I'll find you the best flights!
"@
            
            Send-TelegramMessage -ChatId $ChatId -Text $help -ParseMode "Markdown"
        }
        default {
            Send-TelegramMessage -ChatId $ChatId -Text "Command not recognized. Try /start or just ask me for a flight!"
        }
    }
}

function Process-FlightQuery {
    <#
    .SYNOPSIS
    Processes flight queries
    #>
    param(
        [string]$ChatId,
        [string]$Query
    )
    
    try {
        Write-Host "🔍 Processing query: $Query" -ForegroundColor Yellow
        
        # Import NLP module
        . "$PSScriptRoot\nlp-processor.psm1"
        
        # Parse the query
        $flightParams = Parse-FlightQuery -Query $Query
        
        if (-not $flightParams.Success) {
            Send-TelegramMessage -ChatId $ChatId -Text "❌ I couldn't understand your request. Try something like: `New York to London on January 20`" -ParseMode "Markdown"
            return
        }
        
        # Format response
        $message = "✅ *I understood your request!*\n\n"
        $message += "• *From:* $($flightParams.Origin) ($($flightParams.OriginCode))\n"
        $message += "• *To:* $($flightParams.Destination) ($($flightParams.DestinationCode))\n"
        $message += "• *Date:* $($flightParams.DepartureDate)\n"
        
        if ($flightParams.ReturnDate) {
            $message += "• *Return:* $($flightParams.ReturnDate)\n"
        }
        
        if ($flightParams.Travelers -gt 1) {
            $message += "• *Travelers:* $($flightParams.Travelers)\n"
        }
        
        if ($flightParams.Class) {
            $message += "• *Class:* $($flightParams.Class)\n"
        }
        
        $message += "\n🔍 *Next Step:*\n"
        $message += "The flight search API integration is coming next!\n"
        $message += "This will connect to TravelPayouts and show real flights with prices.\n\n"
        $message += "✅ *What's working now:*\n"
        $message += "• NLP parsing ✓\n"
        $message += "• Airport lookup ✓\n"
        $message += "• Misspelling correction ✓\n"
        $message += "• Telegram interface ✓"
        
        Send-TelegramMessage -ChatId $ChatId -Text $message -ParseMode "Markdown"
        
    }
    catch {
        Write-Host "❌ Error processing query: $_" -ForegroundColor Red
        Send-TelegramMessage -ChatId $ChatId -Text "❌ Sorry, I encountered an error. Please try again with a simpler query."
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-TelegramBot',
    'Send-TelegramMessage',
    'Start-TelegramPolling'
)
