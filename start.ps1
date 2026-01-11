# Script to setup and start crypto tracker services
# Creates necessary directories and starts docker-compose

# Set error action preference
$ErrorActionPreference = "Stop"

# Color functions
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Yellow }
function Write-Error { Write-Host $args -ForegroundColor Red }

Write-Info "=== Crypto Tracker Setup ===`n"

# Create exports directory if it doesn't exist
if (-Not (Test-Path -Path "exports")) {
    Write-Info "Creating exports directory..."
    New-Item -ItemType Directory -Path "exports" | Out-Null
    Write-Success "✓ exports directory created`n"
} else {
    Write-Success "✓ exports directory already exists`n"
}

# Start docker-compose services
Write-Info "Starting Docker services..."
try {
    docker-compose up -d
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "`n✓ All services started successfully!"
        Write-Info "`nAvailable services:"
        Write-Host "  - PostgreSQL: " -NoNewline
        Write-Success "localhost:5432"
        Write-Host "  - pgAdmin: " -NoNewline
        Write-Success "http://localhost:5050"
        Write-Host "  - CSV exports: " -NoNewline
        Write-Success "./exports/"
        Write-Info "`nTo view logs: " -NoNewline
        Write-Host "docker-compose logs -f"
        Write-Info "To stop services: " -NoNewline
        Write-Host "docker-compose down"
    } else {
        throw "Docker-compose failed with exit code $LASTEXITCODE"
    }
} catch {
    Write-Error "`n✗ Error starting services: $_"
    exit 1
}