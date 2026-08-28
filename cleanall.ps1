Write-Host "Cleaning..." -ForegroundColor Yellow

# Directories
$directories = @(
    "build",
    "dist"
)

foreach ($dir in $directories) {
    if (Test-Path $dir) {
        Remove-Item -Recurse -Force $dir
        Write-Host "Removed: $dir" -ForegroundColor Gray
    }
}

# Files
$filePatterns = @(
    "*.log"
)

foreach ($pattern in $filePatterns) {
    Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | Remove-Item -Force
}

Get-ChildItem -Path . -Directory -Recurse -Filter "__pycache__" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Cleanup complete." -ForegroundColor Green
