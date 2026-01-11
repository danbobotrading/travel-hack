# travel-bot.ps1
# Main script for Travel Hack Flight Bot

param(
    [switch]$TestMode
)

# Set working directory to script location
if ($MyInvocation.MyCommand.Path) {
    Set-Location (Split-Path -Parent $MyInvocation.MyCommand.Path)
}

Write-Host "=== Travel Hack Flight Bot ===" -ForegroundColor Cyan
Write-Host "Starting at: $(Get-Date)" -ForegroundColor Gray

function Test-System {
    <#
    .SYNOPSIS
    Tests all system components
    #>
    Write-Host "`n🧪 Running system tests..." -ForegroundColor Yellow
    
    # Test Config Manager
    try {
        Write-Host "Testing Config Manager..." -NoNewline
        . .\modules\config-manager.psm1
        $config = Get-Configuration
        if ($config) {
            Write-Host " ✅" -ForegroundColor Green
            Write-Host "   Bot Token: $($config.TelegramBotToken.Substring(0,10))..." -ForegroundColor Gray
        }
    }
    catch {
        Write-Host " ❌" -ForegroundColor Red
        Write-Host "   Error: $_" -ForegroundColor Red
    }
    
    # Test Airport System
    try {
        Write-Host "Testing Airport System..." -NoNewline
        . .\modules\airport-codes.psm1
        $airport = Find-Airport -Input "newyork"
        if ($airport) {
            Write-Host " ✅" -ForegroundColor Green
            Write-Host "   Found: $($airport.name) ($($airport.code))" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host " ❌" -ForegroundColor Red
        Write-Host "   Error: $_" -ForegroundColor Red
    }
    
    # Test NLP Processor
    try {
        Write-Host "Testing NLP Processor..." -NoNewline
        . .\modules\nlp-processor.psm1
        $result = Parse-FlightQuery -Query "Newyork to Dubln on 20 Jan 2024"
        if ($result.Success) {
            Write-Host " ✅" -ForegroundColor Green
            Write-Host "   Parsed: $($result.Origin) → $($result.Destination)" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host " ❌" -ForegroundColor Red
        Write-Host "   Error: $_" -ForegroundColor Red
    }
    
    # Test Telegram Connection
    try {
        Write-Host "Testing Telegram Connection..." -NoNewline
        . .\modules\telegram-api.psm1
        $connected = Initialize-TelegramBot
        if ($connected) {
            Write-Host " ✅" -ForegroundColor Green
            Write-Host "   Bot: @$($Script:BotName)" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host " ❌" -ForegroundColor Red
        Write-Host "   Error: $_" -ForegroundColor Red
    }
    
    Write-Host "`n✅ System tests complete!" -ForegroundColor Green
}

function Start-Bot {
    <#
    .SYNOPSIS
    Starts the Telegram bot
    #>
    Write-Host "`n🤖 Starting Travel Hack Bot..." -ForegroundColor Yellow
    
    # Load modules
    . .\modules\config-manager.psm1
    . .\modules\airport-codes.psm1
    . .\modules\nlp-processor.psm1
    . .\modules\telegram-api.psm1
    
    # Initialize bot
    $initialized = Initialize-TelegramBot
    if (-not $initialized) {
        Write-Host "❌ Failed to initialize bot. Exiting." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ Bot is running! Press Ctrl+C to stop." -ForegroundColor Green
    Write-Host "📱 Find your bot on Telegram: @$($Script:BotName)" -ForegroundColor Cyan
    
    # Start polling
    try {
        Start-TelegramPolling -PollingInterval 2
    }
    catch {
        Write-Host "❌ Bot stopped with error: $_" -ForegroundColor Red
    }
}

# Main execution
if ($TestMode) {
    Test-System
}
else {
    Start-Bot
}

Write-Host "`n=== Bot Stopped ===" -ForegroundColor Cyan
