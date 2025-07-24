# Infrastructure validation script for Windows PowerShell
Write-Host "Testing Infrastructure Fixes..." -ForegroundColor Green

# Test 1: Python environment
Write-Host "Testing Python dependency installation..." -ForegroundColor Yellow
try {
    python --version
    pip --version
    Write-Host "Python environment is ready" -ForegroundColor Green
} catch {
    Write-Host "Python environment test failed" -ForegroundColor Red
}

# Test 2: Node.js environment  
Write-Host "Testing Node.js environment..." -ForegroundColor Yellow
try {
    node --version
    npm --version
    Write-Host "Node.js environment is ready" -ForegroundColor Green
} catch {
    Write-Host "Node.js environment test failed" -ForegroundColor Red
}

Write-Host "Infrastructure test completed!" -ForegroundColor Green
Write-Host "You can now run: npm run security-scan" -ForegroundColor Cyan
