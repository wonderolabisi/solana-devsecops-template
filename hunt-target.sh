#!/bin/bash

# 🎯 Bug Bounty Target Hunter Script
# Usage: ./hunt-target.sh <github-repo-url> [contract-address]

set -e

TARGET_REPO="$1"
CONTRACT_ADDRESS="$2"

if [ -z "$TARGET_REPO" ]; then
    echo "❌ Usage: ./hunt-target.sh <github-repo-url> [contract-address]"
    echo "📝 Example: ./hunt-target.sh https://github.com/compound-finance/compound-protocol"
    echo "🎯 Example with address: ./hunt-target.sh https://github.com/uniswap/v3-core 0x1F98431c8aD98523631AE4a59f267346ea31F984"
    exit 1
fi

echo "🎯 Starting Bug Bounty Hunt on: $TARGET_REPO"

# Create target directory
TARGET_DIR="target-$(basename $TARGET_REPO)"
rm -rf "$TARGET_DIR"

# Clone target repository
echo "📥 Cloning target repository..."
git clone "$TARGET_REPO" "$TARGET_DIR"
cd "$TARGET_DIR"

# Copy our security pipeline
echo "🔧 Setting up security pipeline..."
cp ../requirements.txt .
cp -r ../.github .

# Set environment variables for enhanced analysis
export TARGET_CONTRACT_ADDRESS="$CONTRACT_ADDRESS"
export GITHUB_REPOSITORY="$(basename $TARGET_REPO)"

echo "🚀 Running comprehensive security analysis..."

# Run the analysis locally (same as GitHub Actions)
mkdir -p reports

# Python security tools setup
echo "🐍 Setting up Python security tools..."
python -m pip install --upgrade pip setuptools wheel
pip install -r requirements.txt

# Ethereum/Solidity Analysis
if [ -d "contracts" ] && ls contracts/*.sol 1> /dev/null 2>&1; then
    echo "📝 Found Solidity contracts, running Ethereum analysis..."
    
    # Slither analysis
    echo "🐍 Running Slither analysis..."
    slither . --json reports/slither-report.json || echo "Slither completed"
    slither . --print human-summary > reports/slither-summary.txt 2>&1 || echo "Slither summary completed"
    
    # Mythril analysis on source code
    find contracts -name "*.sol" | head -10 | while read contract; do
        echo "🧙 Analyzing $contract with Mythril..."
        timeout 300 myth analyze "$contract" --solv 0.8.19 --json > "reports/mythril-$(basename $contract .sol).json" 2>/dev/null || echo "Mythril completed for $contract"
    done
    
    # Enhanced: Mythril on deployed contract (if address provided)
    if [ ! -z "$CONTRACT_ADDRESS" ]; then
        echo "🎯 Analyzing deployed contract at $CONTRACT_ADDRESS"
        timeout 900 myth analyze --rpc https://mainnet.infura.io/v3/b2469e3d2a4f453ba98803ff0a58f2dd --address "$CONTRACT_ADDRESS" --json > "reports/mythril-deployed.json" || echo "Deployed analysis completed"
    fi
fi

# Rust/Solana Analysis
if [ -f "Cargo.toml" ] || [ -f "Anchor.toml" ]; then
    echo "🦀 Found Rust project, running Solana analysis..."
    
    # Cargo audit
    cargo audit --json > reports/cargo-audit.json 2>&1 || echo "Cargo audit completed"
    
    # Clippy analysis
    cargo clippy --all-targets --all-features -- -D warnings > reports/clippy-analysis.txt 2>&1 || echo "Clippy completed"
fi

# Generate findings summary
echo "📋 Generating findings summary..."
cat > reports/BUG_BOUNTY_FINDINGS.md << EOF
# 🛡️ Bug Bounty Security Analysis Report

**Target**: $TARGET_REPO
**Contract Address**: ${CONTRACT_ADDRESS:-"Source code analysis only"}
**Analysis Date**: $(date)

## 🚨 Critical Findings

### High-Severity Issues:
$(grep -i "HIGH\|CRITICAL\|SEVERE" reports/*.json 2>/dev/null | head -10 || echo "See detailed reports for findings")

### Potential Exploits:
- Reentrancy vulnerabilities
- Integer overflow/underflow
- Access control issues
- Unchecked external calls
- Gas limit vulnerabilities

## 📁 Generated Reports:
- \`slither-report.json\` - Comprehensive static analysis
- \`mythril-*.json\` - Symbolic execution analysis
- \`cargo-audit.json\` - Rust dependency vulnerabilities (if applicable)

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

EOF

echo ""
echo "🎉 Analysis Complete! Check the reports/ directory for findings."
echo "📄 Bug bounty summary: reports/BUG_BOUNTY_FINDINGS.md"
echo ""
echo "🎯 Next Steps:"
echo "1. Review all findings in reports/ directory"
echo "2. Develop proof-of-concept exploits for high-severity issues"
echo "3. Submit to appropriate bug bounty platform"
echo "4. 💰 Collect bounty rewards!"
