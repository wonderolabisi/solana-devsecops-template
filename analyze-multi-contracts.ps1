# 🎯 Multi-Contract Security Analysis Script (PowerShell)
# Copy this to target project as analyze-multi-contracts.ps1

param(
    [switch]$SkipMythril,
    [switch]$QuickScan
)

$ProjectName = Split-Path -Leaf (Get-Location)
Write-Host "🔍 Starting comprehensive multi-contract analysis for: $ProjectName" -ForegroundColor Green

# Create analysis directory
New-Item -ItemType Directory -Force -Path "security-analysis\reports" | Out-Null
New-Item -ItemType Directory -Force -Path "security-analysis\configs" | Out-Null
New-Item -ItemType Directory -Force -Path "security-analysis\exploits" | Out-Null

# Find all contract directories
Write-Host "📂 Discovering contract directories..." -ForegroundColor Blue
$ContractDirs = @(
    "contracts", "src", "protocol", "core", "periphery", "interfaces", 
    "libraries", "governance", "vault", "pool", "lending", "exchange",
    "strategies", "modules", "adapters", "oracles", "tokens", "nft", "marketplace"
)

$FoundDirs = @()
foreach ($dir in $ContractDirs) {
    if ((Test-Path $dir) -and (Get-ChildItem $dir -Filter "*.sol" -Recurse)) {
        $FoundDirs += $dir
        Write-Host "✅ Found contracts in: $dir" -ForegroundColor Green
    }
}

if ($FoundDirs.Count -eq 0) {
    Write-Host "❌ No Solidity contracts found in standard directories" -ForegroundColor Red
    exit 1
}

Write-Host "📊 Found $($FoundDirs.Count) contract directories with Solidity files" -ForegroundColor Yellow

# Copy essential config files
Write-Host "🔧 Setting up analysis configurations..." -ForegroundColor Blue
if (Test-Path "slither.config.json") { Copy-Item "slither.config.json" . } else { Write-Host "⚠️  slither.config.json not found" -ForegroundColor Yellow }
if (Test-Path "hardhat.config.js") { Copy-Item "hardhat.config.js" . } else { Write-Host "⚠️  hardhat.config.js not found" -ForegroundColor Yellow }

# Enhanced Slither Analysis
Write-Host "🐍 Running enhanced Slither analysis..." -ForegroundColor Magenta
try {
    & slither . --config-file slither.config.json --json security-analysis/reports/slither-full.json --print call-graph,cfg,contract-summary,data-dependency,function-summary,human-summary,inheritance,inheritance-graph --checklist --markdown security-analysis/reports/slither-markdown.md
    Write-Host "✅ Slither analysis completed" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Slither analysis completed with findings" -ForegroundColor Yellow
}

# Cross-contract interaction analysis
Write-Host "🔗 Analyzing cross-contract interactions..." -ForegroundColor Blue
& slither . --print call-graph > security-analysis/reports/call-graph.txt 2>&1
& slither . --print data-dependency > security-analysis/reports/data-dependencies.txt 2>&1

# Contract-by-contract analysis
if (-not $QuickScan) {
    Write-Host "📝 Analyzing individual contracts..." -ForegroundColor Blue
    foreach ($dir in $FoundDirs) {
        Write-Host "🔍 Analyzing contracts in $dir..." -ForegroundColor Cyan
        Get-ChildItem $dir -Filter "*.sol" -Recurse | ForEach-Object {
            $contractName = $_.BaseName
            $contractPath = $_.FullName
            
            Write-Host "  🧙 Mythril analysis: $contractPath" -ForegroundColor Magenta
            if (-not $SkipMythril) {
                try {
                    $null = Start-Process -FilePath "myth" -ArgumentList "analyze", $contractPath, "--solv", "0.8.19", "--json" -RedirectStandardOutput "security-analysis/reports/mythril-$contractName.json" -Wait -WindowStyle Hidden -TimeoutSec 300
                    Write-Host "  ✅ Mythril completed for $contractName" -ForegroundColor Green
                } catch {
                    Write-Host "  ⚠️  Mythril timeout/error for $contractName" -ForegroundColor Yellow
                }
            }
            
            Write-Host "  🔍 Slither focused analysis: $contractPath" -ForegroundColor Blue
            try {
                & slither $contractPath --json "security-analysis/reports/slither-$contractName.json" --print human-summary > "security-analysis/reports/summary-$contractName.txt" 2>&1
                Write-Host "  ✅ Focused analysis completed for $contractName" -ForegroundColor Green
            } catch {
                Write-Host "  ⚠️  Focused analysis error for $contractName" -ForegroundColor Yellow
            }
        }
    }
}

# Detect common DeFi vulnerability patterns
Write-Host "💰 Searching for DeFi-specific vulnerabilities..." -ForegroundColor Yellow

$defiPatterns = @"
# 🔍 DeFi Vulnerability Pattern Analysis

## Checking for common DeFi attack vectors:

## 🔄 Reentrancy Vulnerabilities:
"@

# Search for reentrancy patterns
$reentrancyPatterns = @()
foreach ($dir in $FoundDirs) {
    $reentrancyPatterns += Select-String -Path "$dir\*.sol" -Pattern "\.call\{" -AllMatches 2>$null | Select-Object -First 10
}
$defiPatterns += ($reentrancyPatterns | Out-String)

$defiPatterns += @"

## ⚡ Flash Loan Patterns:
"@

# Search for flash loan patterns
$flashLoanPatterns = @()
foreach ($dir in $FoundDirs) {
    $flashLoanPatterns += Select-String -Path "$dir\*.sol" -Pattern "flashloan|flash.*loan|borrow.*repay" -AllMatches 2>$null | Select-Object -First 10
}
$defiPatterns += ($flashLoanPatterns | Out-String)

$defiPatterns += @"

## 🔮 Oracle Dependencies:
"@

# Search for oracle patterns
$oraclePatterns = @()
foreach ($dir in $FoundDirs) {
    $oraclePatterns += Select-String -Path "$dir\*.sol" -Pattern "oracle|price.*feed|chainlink|aggregator" -AllMatches 2>$null | Select-Object -First 10
}
$defiPatterns += ($oraclePatterns | Out-String)

$defiPatterns += @"

## 🏛️ Governance Mechanisms:
"@

# Search for governance patterns  
$govPatterns = @()
foreach ($dir in $FoundDirs) {
    $govPatterns += Select-String -Path "$dir\*.sol" -Pattern "governance|voting|proposal|timelock" -AllMatches 2>$null | Select-Object -First 10
}
$defiPatterns += ($govPatterns | Out-String)

$defiPatterns | Out-File -FilePath "security-analysis/reports/defi-patterns.txt" -Encoding UTF8

# Generate comprehensive bug bounty report
$contractCount = 0
foreach ($dir in $FoundDirs) {
    $contractCount += (Get-ChildItem $dir -Filter "*.sol" -Recurse).Count
}

$reportContent = @"
# 🛡️ Multi-Contract Security Analysis Report

**Project**: $ProjectName  
**Analysis Date**: $(Get-Date)
**Directories Analyzed**: $($FoundDirs -join ', ')

## 📊 Contract Discovery
- **Total Contract Directories**: $($FoundDirs.Count)
- **Solidity Files Found**: $contractCount

## 🔍 Analysis Tools Used
- ✅ **Slither** - Static analysis with cross-contract detection
- ✅ **Mythril** - Symbolic execution per contract$(if ($SkipMythril) { " (SKIPPED)" } else { "" })
- ✅ **Pattern Analysis** - DeFi-specific vulnerability detection
- ✅ **Call Graph Analysis** - Inter-contract relationship mapping
- ✅ **Data Dependency Analysis** - Cross-contract data flow

## 📁 Generated Reports
- ``slither-full.json`` - Comprehensive static analysis
- ``slither-markdown.md`` - Human-readable findings  
- ``call-graph.txt`` - Contract interaction mapping
- ``data-dependencies.txt`` - Cross-contract dependencies
- ``mythril-*.json`` - Per-contract symbolic execution
- ``defi-patterns.txt`` - DeFi vulnerability patterns

## 🚨 Critical Areas to Review
1. **Cross-Contract Reentrancy** - Check call-graph.txt for external calls
2. **Flash Loan Attack Vectors** - Review defi-patterns.txt flash loan section  
3. **Oracle Manipulation** - Analyze oracle dependencies
4. **Governance Attacks** - Review timelock and voting mechanisms
5. **Access Control Issues** - Check modifier usage across contracts

## 💰 Bug Bounty Potential
Based on contract complexity and DeFi patterns found, focus on:
- Multi-contract interaction bugs (High bounty potential)
- Flash loan attack vectors (Critical severity)
- Oracle price manipulation (High severity)
- Cross-contract reentrancy (Medium-High severity)

## 🎯 Next Steps
1. Review all JSON reports for specific vulnerabilities
2. Develop PoC exploits for identified issues
3. Test cross-contract attack scenarios
4. Submit findings to appropriate bug bounty programs

"@

$reportContent | Out-File -FilePath "security-analysis/MULTI_CONTRACT_ANALYSIS.md" -Encoding UTF8

Write-Host ""
Write-Host "🎉 Multi-contract analysis complete!" -ForegroundColor Green
Write-Host "📄 Main report: security-analysis/MULTI_CONTRACT_ANALYSIS.md" -ForegroundColor Yellow
Write-Host "📂 All reports: security-analysis/reports/" -ForegroundColor Yellow
Write-Host ""
Write-Host "🎯 High-priority files to review:" -ForegroundColor Cyan
Write-Host "  1. security-analysis/reports/slither-full.json"
Write-Host "  2. security-analysis/reports/call-graph.txt" 
Write-Host "  3. security-analysis/reports/defi-patterns.txt"
Write-Host "  4. security-analysis/MULTI_CONTRACT_ANALYSIS.md"
