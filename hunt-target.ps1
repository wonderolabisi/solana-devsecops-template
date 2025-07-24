# 🎯 Bug Bounty Target Hunter Script (PowerShell)
# Usage: .\hunt-target.ps1 <github-repo-url> [contract-address]

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetRepo,
    
    [Parameter(Mandatory=$false)]
    [string]$ContractAddress
)

if (-not $TargetRepo) {
    Write-Host "❌ Usage: .\hunt-target.ps1 <github-repo-url> [contract-address]" -ForegroundColor Red
    Write-Host "📝 Example: .\hunt-target.ps1 https://github.com/compound-finance/compound-protocol" -ForegroundColor Yellow
    Write-Host "🎯 Example with address: .\hunt-target.ps1 https://github.com/uniswap/v3-core 0x1F98431c8aD98523631AE4a59f267346ea31F984" -ForegroundColor Yellow
    exit 1
}

Write-Host "🎯 Starting Bug Bounty Hunt on: $TargetRepo" -ForegroundColor Green

# Create target directory
$TargetDir = "target-$(Split-Path $TargetRepo -Leaf)"
if (Test-Path $TargetDir) {
    Remove-Item $TargetDir -Recurse -Force
}

# Clone target repository
Write-Host "📥 Cloning target repository..." -ForegroundColor Blue
git clone $TargetRepo $TargetDir
Set-Location $TargetDir

# Copy our security pipeline and multi-contract analysis tools
Write-Host "🔧 Setting up security pipeline..." -ForegroundColor Blue
Copy-Item ..\requirements.txt .
Copy-Item ..\.github . -Recurse -Force
Copy-Item ..\slither.config.json . -ErrorAction SilentlyContinue
Copy-Item ..\hardhat.config.js . -ErrorAction SilentlyContinue  
Copy-Item ..\analyze-multi-contracts.ps1 . -ErrorAction SilentlyContinue

# Set environment variables
$env:TARGET_CONTRACT_ADDRESS = $ContractAddress
$env:GITHUB_REPOSITORY = (Split-Path $TargetRepo -Leaf)

Write-Host "🚀 Running comprehensive security analysis..." -ForegroundColor Green

# Create reports directory
New-Item -ItemType Directory -Force -Path reports | Out-Null

# Python security tools setup
Write-Host "🐍 Setting up Python security tools..." -ForegroundColor Yellow
python -m pip install --upgrade pip setuptools wheel
pip install -r requirements.txt

# Ethereum/Solidity Analysis
if ((Test-Path "contracts") -and (Get-ChildItem contracts -Filter "*.sol")) {
    Write-Host "📝 Found Solidity contracts, running comprehensive multi-contract analysis..." -ForegroundColor Green
    
    # Run multi-contract analysis if available
    if (Test-Path "analyze-multi-contracts.ps1") {
        Write-Host "🔍 Running comprehensive multi-contract analysis..." -ForegroundColor Magenta
        .\analyze-multi-contracts.ps1 -QuickScan
    }
    
    # Enhanced Slither analysis with cross-contract detection
    Write-Host "🐍 Running enhanced Slither analysis..." -ForegroundColor Blue
    if (Test-Path "slither.config.json") {
        slither . --config-file slither.config.json --json reports/slither-report.json --print call-graph,contract-summary,data-dependency,human-summary
    } else {
        slither . --json reports/slither-report.json --print call-graph,contract-summary,data-dependency,human-summary
    }
    slither . --print human-summary > reports/slither-summary.txt 2>&1
    
    # Mythril analysis on source code
    Get-ChildItem contracts -Filter "*.sol" | Select-Object -First 10 | ForEach-Object {
        $contract = $_.FullName
        $basename = $_.BaseName
        Write-Host "🧙 Analyzing $contract with Mythril..." -ForegroundColor Magenta
        & myth analyze $contract --solv 0.8.19 --json > "reports/mythril-$basename.json" 2>$null
    }
    
    # Enhanced: Mythril on deployed contract (if address provided)
    if ($ContractAddress) {
        Write-Host "🎯 Analyzing deployed contract at $ContractAddress" -ForegroundColor Red
        & myth analyze --rpc https://mainnet.infura.io/v3/b2469e3d2a4f453ba98803ff0a58f2dd --address $ContractAddress --json > reports/mythril-deployed.json 2>$null
    }
}

# Rust/Solana Analysis
if ((Test-Path "Cargo.toml") -or (Test-Path "Anchor.toml")) {
    Write-Host "🦀 Found Rust project, running Solana analysis..." -ForegroundColor Green
    
    # Cargo audit
    cargo audit --json > reports/cargo-audit.json 2>&1
    
    # Clippy analysis  
    cargo clippy --all-targets --all-features -- -D warnings > reports/clippy-analysis.txt 2>&1
}

# Generate findings summary
Write-Host "📋 Generating findings summary..." -ForegroundColor Blue
$reportContent = @"
# 🛡️ Bug Bounty Security Analysis Report

**Target**: $TargetRepo
**Contract Address**: $(if ($ContractAddress) { $ContractAddress } else { "Source code analysis only" })
**Analysis Date**: $(Get-Date)

## 🚨 Critical Findings

### High-Severity Issues:
Check detailed reports for findings - grep for HIGH/CRITICAL/SEVERE patterns

### Potential Exploits:
- Reentrancy vulnerabilities  
- Integer overflow/underflow
- Access control issues
- Unchecked external calls
- Gas limit vulnerabilities

## 📁 Generated Reports:
- ``slither-report.json`` - Comprehensive static analysis
- ``mythril-*.json`` - Symbolic execution analysis
- ``cargo-audit.json`` - Rust dependency vulnerabilities (if applicable)

## 🎯 Bug Bounty Submission Checklist:
1. ✅ Vulnerability identified and confirmed
2. ⏳ Proof-of-concept exploit developed  
3. ⏳ Impact assessment completed
4. ⏳ Submitted to appropriate bug bounty platform

## 💰 Recommended Bounty Platforms:
- **Immunefi** (DeFi protocols)
- **HackerOne** (Web3 projects) 
- **Code4rena** (Contest-based audits)
- **Sherlock** (DeFi insurance protocols)

"@

$reportContent | Out-File -FilePath "reports/BUG_BOUNTY_FINDINGS.md" -Encoding UTF8

Write-Host ""
Write-Host "🎉 Analysis Complete! Check the reports/ directory for findings." -ForegroundColor Green
Write-Host "📄 Bug bounty summary: reports/BUG_BOUNTY_FINDINGS.md" -ForegroundColor Yellow
Write-Host ""
Write-Host "🎯 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Review all findings in reports/ directory"
Write-Host "2. Develop proof-of-concept exploits for high-severity issues"
Write-Host "3. Submit to appropriate bug bounty platform"
Write-Host "4. 💰 Collect bounty rewards!"
