# Travel Hack - Telegram Flight Search Bot

A conversational Telegram bot for searching flights using natural language queries.

## Features
- Natural language flight search (e.g., "New York to Dublin on 20 Jan and back on 18 March")
- Real-time flight prices from multiple airlines
- Sort by price (cheapest to most expensive)
- Affiliate link integration
- Scalable architecture for future travel services

## Setup

1. Clone the repository
2. Install required modules: Install-Module -Name PSScriptAnalyzer -Force
3. Configure API keys in config/config.json
4. Run the bot: .\travel-bot.ps1

## Configuration

Copy config/config.example.json to config/config.json and fill in your API keys:
- Telegram Bot Token
- TravelPayouts API Key
- Affiliate Marker ID

## Project Structure
- 	ravel-bot.ps1 - Main bot script
- modules/ - PowerShell modules
- data/ - Data files and cache
- logs/ - Application logs
- config/ - Configuration files
- 	ests/ - Test scripts

## License
MIT
