# Configuration Manager Module
# Handles loading and managing configuration settings

function Get-Config {
    param(
        [string]$ConfigPath = ".\config\config.json"
    )
    
    # Create config directory if it doesn't exist
    if (-not (Test-Path ".\config")) {
        New-Item -ItemType Directory -Path ".\config" -Force | Out-Null
    }
    
    # If config file doesn't exist, create a template
    if (-not (Test-Path $ConfigPath)) {
        Write-Host "Configuration file not found. Creating template..." -ForegroundColor Yellow
        
        $defaultConfig = @{
            TelegramBotToken = "YOUR_TELEGRAM_BOT_TOKEN_HERE"
            TravelPayoutsAPIKey = "YOUR_TRAVELPAYOUTS_API_KEY_HERE"
            AffiliateMarker = "694136"
            DefaultCurrency = "USD"
            LogLevel = "INFO"
            MaxResults = 10
            CacheTTL = 3600
            AllowedChatIds = @()
            AdminChatIds = @()
        }
        
        $defaultConfig | ConvertTo-Json | Out-File -FilePath $ConfigPath -Encoding UTF8
        Write-Host "Please edit $ConfigPath with your actual API keys" -ForegroundColor Red
        return $null
    }
    
    try {
        $configContent = Get-Content $ConfigPath -Raw
        $config = $configContent | ConvertFrom-Json
        Write-Log -Message "Configuration loaded successfully" -Level "INFO"
        return $config
    }
    catch {
        Write-Log -Message "Error loading configuration: $_" -Level "ERROR"
        return $null
    }
}

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$LogFile = ".\logs\travel-bot.log"
    )
    
    # Create logs directory if it doesn't exist
    if (-not (Test-Path ".\logs")) {
        New-Item -ItemType Directory -Path ".\logs" -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to log file
    Add-Content -Path $LogFile -Value $logEntry -Encoding UTF8
    
    # Display with colors based on level
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARN" { Write-Host $logEntry -ForegroundColor Yellow }
        "INFO" { Write-Host $logEntry -ForegroundColor Green }
        "DEBUG" { Write-Host $logEntry -ForegroundColor Gray }
        default { Write-Host $logEntry }
    }
}

function Test-Config {
    param(
        [object]$Config
    )
    
    if (-not $Config) {
        Write-Log -Message "Configuration is null" -Level "ERROR"
        return $false
    }
    
    $errors = @()
    
    if ([string]::IsNullOrWhiteSpace($Config.TelegramBotToken) -or 
        $Config.TelegramBotToken -eq "YOUR_TELEGRAM_BOT_TOKEN_HERE") {
        $errors += "TelegramBotToken is not set"
    }
    
    if ([string]::IsNullOrWhiteSpace($Config.TravelPayoutsAPIKey) -or 
        $Config.TravelPayoutsAPIKey -eq "YOUR_TRAVELPAYOUTS_API_KEY_HERE") {
        $errors += "TravelPayoutsAPIKey is not set"
    }
    
    if ([string]::IsNullOrWhiteSpace($Config.AffiliateMarker)) {
        $errors += "AffiliateMarker is not set"
    }
    
    if ($errors.Count -gt 0) {
        foreach ($error in $errors) {
            Write-Log -Message "Config error: $error" -Level "ERROR"
        }
        return $false
    }
    
    Write-Log -Message "Configuration test passed" -Level "INFO"
    return $true
}

Export-ModuleMember -Function Get-Config, Write-Log, Test-Config
