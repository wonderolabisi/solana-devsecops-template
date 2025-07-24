# 🎯 Code4rena Contest Bug Hunter Setup Script
# Add professional bug hunting pipeline to any Code4rena contest repository

Write-Host "🎯 Code4rena Contest Bug Hunter Setup" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# Your template repository (update this!)
$TEMPLATE_REPO = "wonderolabisi/solana-devsecops-template"

Write-Host "🔍 Setting up bug hunting pipeline for Code4rena contest..." -ForegroundColor Blue

# Create necessary directories
Write-Host "📁 Creating directory structure..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path ".github\workflows"
New-Item -ItemType Directory -Force -Path "security-config"
New-Item -ItemType Directory -Force -Path "docs\security"
New-Item -ItemType Directory -Force -Path "reports"

# Download core pipeline files
Write-Host "📦 Downloading security analysis tools..." -ForegroundColor Yellow

# Main workflows
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$TEMPLATE_REPO/main/.github/workflows/devsecops.yml" -OutFile ".github\workflows\devsecops.yml"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$TEMPLATE_REPO/main/.github/workflows/code4rena-hunter.yml" -OutFile ".github\workflows\code4rena-hunter.yml"

# Security configuration files
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$TEMPLATE_REPO/main/requirements.txt" -OutFile "requirements.txt"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$TEMPLATE_REPO/main/slither.config.json" -OutFile "slither.config.json"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$TEMPLATE_REPO/main/hardhat.config.js" -OutFile "hardhat.config.js"

# Analysis scripts
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$TEMPLATE_REPO/main/analyze-multi-contracts.sh" -OutFile "analyze-multi-contracts.sh"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$TEMPLATE_REPO/main/analyze-multi-contracts.ps1" -OutFile "analyze-multi-contracts.ps1"

# Documentation
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$TEMPLATE_REPO/main/CODE4RENA_SETUP.md" -OutFile "docs\security\CODE4RENA_SETUP.md"

Write-Host "✅ Core files downloaded successfully!" -ForegroundColor Green

# Create contest-specific configuration
Write-Host "⚙️ Creating contest-specific configuration..." -ForegroundColor Yellow

$REPO_NAME = (git remote get-url origin).Split('/')[-1] -replace '\.git$', ''
$CONTEST_NAME = $REPO_NAME -replace '.*code-423n4[_-]', ''
$CURRENT_DATE = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$GIT_USER = try { git config user.name } catch { "Anonymous Hunter" }

$contestConfig = @"
{
  "contest": {
    "name": "$CONTEST_NAME",
    "repository": "$(git remote get-url origin)",
    "setup_date": "$CURRENT_DATE",
    "hunter": "$GIT_USER"
  },
  "analysis_config": {
    "slither_enabled": true,
    "mythril_enabled": true,
    "semgrep_enabled": true,
    "focus_severity": "all",
    "target_categories": [
      "access_control",
      "reentrancy", 
      "oracle_manipulation",
      "logic_errors",
      "gas_optimization"
    ]
  },
  "reporting": {
    "generate_poc": true,
    "format": "code4rena",
    "include_mitigation": true
  }
}
"@

$contestConfig | Out-File -FilePath "security-config\contest-config.json" -Encoding UTF8

# Create Code4rena submission template
$submissionTemplate = @'
# [SEVERITY] Bug Title

## Summary
Brief description of the vulnerability found in the Code4rena contest.

## Vulnerability Details
Detailed technical explanation of the issue.

## Impact
- **Severity**: Critical/High/Medium/Low
- **Likelihood**: High/Medium/Low
- **Impact**: High/Medium/Low

Explain potential damage, financial loss, or system compromise.

## Proof of Concept
```solidity
// Demonstration code or exploit
```

## Tools Used
- Slither Static Analysis
- Mythril Symbolic Execution
- Semgrep Pattern Matching
- Manual Code Review

## Recommended Mitigation
Specific, actionable steps to fix the vulnerability.

## Additional Notes
Any other relevant information for the Code4rena judges.
'@

$submissionTemplate | Out-File -FilePath "docs\security\SUBMISSION_TEMPLATE.md" -Encoding UTF8

# Detect project type and create appropriate analysis commands
Write-Host "🔍 Detecting project structure..." -ForegroundColor Yellow

if (Test-Path "foundry.toml") {
    Write-Host "📋 Foundry project detected" -ForegroundColor Blue
    "forge build" | Out-File -FilePath "quick-analysis.ps1" -Encoding UTF8
} elseif ((Test-Path "hardhat.config.js") -or (Test-Path "hardhat.config.ts")) {
    Write-Host "📋 Hardhat project detected" -ForegroundColor Blue
    "npx hardhat compile" | Out-File -FilePath "quick-analysis.ps1" -Encoding UTF8
} elseif (Test-Path "truffle-config.js") {
    Write-Host "📋 Truffle project detected" -ForegroundColor Blue
    "truffle compile" | Out-File -FilePath "quick-analysis.ps1" -Encoding UTF8
} else {
    Write-Host "📋 Generic Solidity project detected" -ForegroundColor Blue
    "Write-Host 'Run .\analyze-multi-contracts.ps1 for analysis'" | Out-File -FilePath "quick-analysis.ps1" -Encoding UTF8
}

".\analyze-multi-contracts.ps1" | Add-Content -Path "quick-analysis.ps1"

# Create README for the contest
$REPO_URL = git remote get-url origin
$bugHuntingReadme = @"
# 🎯 Code4rena Contest: $CONTEST_NAME

## 🚀 Bug Hunting Pipeline Setup Complete!

This repository now includes professional security analysis tools for finding vulnerabilities in the **$CONTEST_NAME** Code4rena contest.

### 🔍 Quick Analysis

**Option 1: GitHub Actions (Recommended)**
1. Go to **Actions** tab
2. Run **"🏆 Code4rena Contest Bug Hunter"** workflow
3. Download analysis reports from artifacts

**Option 2: Local Analysis (Windows)**
``````powershell
# Install dependencies
pip install -r requirements.txt

# Run analysis
.\analyze-multi-contracts.ps1

# Check results  
Get-ChildItem reports\
``````

**Option 3: Local Analysis (Linux/Mac)**
``````bash
# Install dependencies
pip install -r requirements.txt

# Run analysis
./analyze-multi-contracts.sh

# Check results  
ls reports/
``````

### 💰 Expected Rewards

- **Critical**: `$10,000 - `$100,000+
- **High**: `$5,000 - `$50,000  
- **Medium**: `$1,000 - `$10,000
- **Low/Gas**: `$100 - `$1,000

### 🎯 Focus Areas

1. **Access Control** - Missing modifiers, privilege escalation
2. **Reentrancy** - Cross-function and cross-contract attacks
3. **Oracle Issues** - Price manipulation, flash loan attacks
4. **Logic Errors** - Edge cases, calculation bugs
5. **Gas Optimization** - Inefficient patterns

### 📊 Analysis Tools

- ✅ **Slither** - Static analysis with 30+ detectors
- ✅ **Mythril** - Symbolic execution for deep bugs  
- ✅ **Semgrep** - Pattern-based vulnerability detection
- ✅ **Manual Review** - Human expertise and creativity

### 🏆 Ready to Hunt!

Your professional bug bounty hunting environment is ready. Good luck finding high-value vulnerabilities! 🎯💰

---

*Setup completed on: $(Get-Date)*
*Contest: $CONTEST_NAME*
*Repository: $REPO_URL*
"@

$bugHuntingReadme | Out-File -FilePath "BUG_HUNTING_README.md" -Encoding UTF8

Write-Host "🎉 Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Summary:" -ForegroundColor Blue
Write-Host "   Contest: $CONTEST_NAME" -ForegroundColor Yellow
Write-Host "   Repository: $REPO_NAME" -ForegroundColor Yellow
Write-Host "   Analysis Tools: ✅ Ready" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 Next Steps:" -ForegroundColor Blue
Write-Host "   1. git add ." -ForegroundColor Yellow
Write-Host "   2. git commit -m '🎯 Add Code4rena bug hunting pipeline'" -ForegroundColor Yellow
Write-Host "   3. git push" -ForegroundColor Yellow
Write-Host "   4. Go to GitHub Actions and run analysis" -ForegroundColor Yellow
Write-Host ""
Write-Host "🏆 Happy bug hunting! May your findings be high-severity! 💰" -ForegroundColor Green
