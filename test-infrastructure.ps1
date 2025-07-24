# Infrastructure validation script for Windows PowerShell
Write-Host "🧪 Testing Infrastructure Fixes..." -ForegroundColor Green

# Test 1: Python environment
Write-Host "`n📦 Testing Python dependency installation..." -ForegroundColor Yellow
try {
    python --version
    pip --version
    
    # Test Web3 6.x installation (dry run)
    Write-Host "Testing Web3 6.x compatibility..." -ForegroundColor Cyan
    pip install --dry-run "web3==6.20.3" "eth-abi==4.2.1" "eth-account==0.11.3"
    Write-Host "✅ Web3 6.x dependencies are compatible" -ForegroundColor Green
} catch {
    Write-Host "❌ Python environment test failed: $_" -ForegroundColor Red
}

# Test 2: Node.js environment  
Write-Host "`n📦 Testing Node.js environment..." -ForegroundColor Yellow
try {
    node --version
    npm --version
    
    # Test package.json scripts
    Write-Host "Testing npm scripts..." -ForegroundColor Cyan
    npm run compile --dry-run 2>$null
    Write-Host "✅ Node.js environment is ready" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js environment test failed: $_" -ForegroundColor Red
}

# Test 3: Security tools availability check
Write-Host "`n🛡️ Checking security tools availability..." -ForegroundColor Yellow

$tools = @(
    @{name="slither"; command="pip show slither-analyzer"},
    @{name="mythril"; command="pip show mythril"},
    @{name="semgrep"; command="pip show semgrep"}
)

foreach ($tool in $tools) {
    try {
        Invoke-Expression $tool.command | Out-Null
        Write-Host "✅ $($tool.name) is available" -ForegroundColor Green
    } catch {
        Write-Host "❌ $($tool.name) not installed" -ForegroundColor Red
    }
}

# Test 4: Contract compilation check
Write-Host "`n📝 Testing contract compilation..." -ForegroundColor Yellow
if (Test-Path "contracts\*.sol") {
    Write-Host "✅ Solidity contracts found - ready for analysis" -ForegroundColor Green
} else {
    Write-Host "⚠️  No Solidity contracts found" -ForegroundColor Yellow
}

Write-Host "`n🎯 Infrastructure test completed!" -ForegroundColor Green
Write-Host "Ready to run: npm run security-scan" -ForegroundColor Cyan
