#!/bin/bash

# 🎯 Code4rena Contest Bug Hunter Setup Script
# Add professional bug hunting pipeline to any Code4rena contest repository

echo "🎯 Code4rena Contest Bug Hunter Setup"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Your template repository (update this!)
TEMPLATE_REPO="wonderolabisi/solana-devsecops-template"

echo -e "${BLUE}🔍 Setting up bug hunting pipeline for Code4rena contest...${NC}"

# Create necessary directories
echo -e "${YELLOW}📁 Creating directory structure...${NC}"
mkdir -p .github/workflows
mkdir -p security-config
mkdir -p docs/security
mkdir -p reports

# Download core pipeline files
echo -e "${YELLOW}📦 Downloading security analysis tools...${NC}"

# Main workflows
curl -sSL "https://raw.githubusercontent.com/$TEMPLATE_REPO/main/.github/workflows/devsecops.yml" -o .github/workflows/devsecops.yml
curl -sSL "https://raw.githubusercontent.com/$TEMPLATE_REPO/main/.github/workflows/code4rena-hunter.yml" -o .github/workflows/code4rena-hunter.yml

# Security configuration files
curl -sSL "https://raw.githubusercontent.com/$TEMPLATE_REPO/main/requirements.txt" -o requirements.txt
curl -sSL "https://raw.githubusercontent.com/$TEMPLATE_REPO/main/slither.config.json" -o slither.config.json
curl -sSL "https://raw.githubusercontent.com/$TEMPLATE_REPO/main/hardhat.config.js" -o hardhat.config.js

# Analysis scripts
curl -sSL "https://raw.githubusercontent.com/$TEMPLATE_REPO/main/analyze-multi-contracts.sh" -o analyze-multi-contracts.sh
curl -sSL "https://raw.githubusercontent.com/$TEMPLATE_REPO/main/analyze-multi-contracts.ps1" -o analyze-multi-contracts.ps1

# Documentation
curl -sSL "https://raw.githubusercontent.com/$TEMPLATE_REPO/main/CODE4RENA_SETUP.md" -o docs/security/CODE4RENA_SETUP.md

# Make scripts executable
chmod +x analyze-multi-contracts.sh

echo -e "${GREEN}✅ Core files downloaded successfully!${NC}"

# Create contest-specific configuration
echo -e "${YELLOW}⚙️ Creating contest-specific configuration...${NC}"

REPO_NAME=$(basename "$(git remote get-url origin)" .git)
CONTEST_NAME=$(echo "$REPO_NAME" | sed 's/.*code-423n4[_-]//')

cat > security-config/contest-config.json << EOF
{
  "contest": {
    "name": "$CONTEST_NAME",
    "repository": "$(git remote get-url origin)",
    "setup_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "hunter": "$(git config user.name || echo 'Anonymous Hunter')"
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
EOF

# Create Code4rena submission template
cat > docs/security/SUBMISSION_TEMPLATE.md << 'EOF'
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
EOF

# Detect project type and create appropriate analysis commands
echo -e "${YELLOW}🔍 Detecting project structure...${NC}"

if [ -f "foundry.toml" ]; then
    echo -e "${BLUE}📋 Foundry project detected${NC}"
    echo "forge build" > quick-analysis.sh
elif [ -f "hardhat.config.js" ] || [ -f "hardhat.config.ts" ]; then
    echo -e "${BLUE}📋 Hardhat project detected${NC}"
    echo "npx hardhat compile" > quick-analysis.sh
elif [ -f "truffle-config.js" ]; then
    echo -e "${BLUE}📋 Truffle project detected${NC}"
    echo "truffle compile" > quick-analysis.sh
else
    echo -e "${BLUE}📋 Generic Solidity project detected${NC}"
    echo "echo 'Run ./analyze-multi-contracts.sh for analysis'" > quick-analysis.sh
fi

echo "./analyze-multi-contracts.sh" >> quick-analysis.sh
chmod +x quick-analysis.sh

# Create README for the contest
cat > BUG_HUNTING_README.md << EOF
# 🎯 Code4rena Contest: $CONTEST_NAME

## 🚀 Bug Hunting Pipeline Setup Complete!

This repository now includes professional security analysis tools for finding vulnerabilities in the **$CONTEST_NAME** Code4rena contest.

### 🔍 Quick Analysis

**Option 1: GitHub Actions (Recommended)**
1. Go to **Actions** tab
2. Run **"🏆 Code4rena Contest Bug Hunter"** workflow
3. Download analysis reports from artifacts

**Option 2: Local Analysis**
\`\`\`bash
# Install dependencies
pip install -r requirements.txt

# Run analysis
./analyze-multi-contracts.sh

# Check results  
ls reports/
\`\`\`

### 💰 Expected Rewards

- **Critical**: \$10,000 - \$100,000+
- **High**: \$5,000 - \$50,000  
- **Medium**: \$1,000 - \$10,000
- **Low/Gas**: \$100 - \$1,000

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

*Setup completed on: $(date)*
*Contest: $CONTEST_NAME*
*Repository: $(git remote get-url origin)*
EOF

echo -e "${GREEN}🎉 Setup Complete!${NC}"
echo ""
echo -e "${BLUE}📋 Summary:${NC}"
echo -e "   Contest: ${YELLOW}$CONTEST_NAME${NC}"
echo -e "   Repository: ${YELLOW}$REPO_NAME${NC}"
echo -e "   Analysis Tools: ${GREEN}✅ Ready${NC}"
echo ""
echo -e "${BLUE}🚀 Next Steps:${NC}"
echo -e "   1. ${YELLOW}git add .${NC}"
echo -e "   2. ${YELLOW}git commit -m '🎯 Add Code4rena bug hunting pipeline'${NC}"
echo -e "   3. ${YELLOW}git push${NC}"
echo -e "   4. Go to GitHub Actions and run analysis"
echo ""
echo -e "${GREEN}🏆 Happy bug hunting! May your findings be high-severity! 💰${NC}"
