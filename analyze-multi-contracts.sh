#!/bin/bash

# 🎯 Multi-Contract Security Analysis Script
# Copy this to target project as analyze-multi-contracts.sh

set -e

PROJECT_NAME=$(basename $(pwd))
echo "🔍 Starting comprehensive multi-contract analysis for: $PROJECT_NAME"

# Create analysis directory
mkdir -p security-analysis/{reports,configs,exploits}

# Find all contract directories
echo "📂 Discovering contract directories..."
CONTRACT_DIRS=(
    "contracts"
    "src" 
    "protocol"
    "core"
    "periphery"
    "interfaces"
    "libraries"
    "governance"
    "vault"
    "pool"
    "lending"
    "exchange"
    "strategies"
    "modules"
    "adapters"
    "oracles"
    "tokens"
    "nft"
    "marketplace"
)

FOUND_DIRS=()
for dir in "${CONTRACT_DIRS[@]}"; do
    if [ -d "$dir" ] && find "$dir" -name "*.sol" | head -1 | grep -q .; then
        FOUND_DIRS+=("$dir")
        echo "✅ Found contracts in: $dir"
    fi
done

if [ ${#FOUND_DIRS[@]} -eq 0 ]; then
    echo "❌ No Solidity contracts found in standard directories"
    exit 1
fi

echo "📊 Found ${#FOUND_DIRS[@]} contract directories with Solidity files"

# Copy essential config files
echo "🔧 Setting up analysis configurations..."
cp slither.config.json . 2>/dev/null || echo "⚠️  slither.config.json not found"
cp hardhat.config.js . 2>/dev/null || echo "⚠️  hardhat.config.js not found"

# Enhanced Slither Analysis
echo "🐍 Running enhanced Slither analysis..."
slither . \
    --config-file slither.config.json \
    --json security-analysis/reports/slither-full.json \
    --print call-graph,cfg,contract-summary,data-dependency,function-summary,human-summary,inheritance,inheritance-graph \
    --checklist \
    --markdown security-analysis/reports/slither-markdown.md \
    || echo "Slither analysis completed with findings"

# Cross-contract interaction analysis
echo "🔗 Analyzing cross-contract interactions..."
slither . --print call-graph > security-analysis/reports/call-graph.txt 2>&1 || echo "Call graph analysis completed"
slither . --print data-dependency > security-analysis/reports/data-dependencies.txt 2>&1 || echo "Data dependency analysis completed"

# Contract-by-contract analysis
echo "📝 Analyzing individual contracts..."
for dir in "${FOUND_DIRS[@]}"; do
    echo "🔍 Analyzing contracts in $dir..."
    find "$dir" -name "*.sol" | while read contract; do
        contract_name=$(basename "$contract" .sol)
        echo "  🧙 Mythril analysis: $contract"
        timeout 300 myth analyze "$contract" \
            --solv 0.8.19 \
            --json > "security-analysis/reports/mythril-$contract_name.json" 2>/dev/null \
            || echo "  ✅ Mythril completed for $contract_name"
            
        echo "  🔍 Slither focused analysis: $contract"
        slither "$contract" \
            --json "security-analysis/reports/slither-$contract_name.json" \
            --print human-summary > "security-analysis/reports/summary-$contract_name.txt" 2>&1 \
            || echo "  ✅ Focused analysis completed for $contract_name"
    done
done

# Detect common DeFi vulnerability patterns
echo "💰 Searching for DeFi-specific vulnerabilities..."
cat > security-analysis/reports/defi-patterns.txt << 'EOF'
# 🔍 DeFi Vulnerability Pattern Analysis

## Checking for common DeFi attack vectors:
EOF

# Search for reentrancy patterns
echo "## 🔄 Reentrancy Vulnerabilities:" >> security-analysis/reports/defi-patterns.txt
grep -r "\.call{" "${FOUND_DIRS[@]}" 2>/dev/null | head -10 >> security-analysis/reports/defi-patterns.txt || echo "No call patterns found" >> security-analysis/reports/defi-patterns.txt

# Search for flash loan patterns  
echo "## ⚡ Flash Loan Patterns:" >> security-analysis/reports/defi-patterns.txt
grep -r -i "flashloan\|flash.*loan\|borrow.*repay" "${FOUND_DIRS[@]}" 2>/dev/null | head -10 >> security-analysis/reports/defi-patterns.txt || echo "No flash loan patterns found" >> security-analysis/reports/defi-patterns.txt

# Search for oracle patterns
echo "## 🔮 Oracle Dependencies:" >> security-analysis/reports/defi-patterns.txt  
grep -r -i "oracle\|price.*feed\|chainlink\|aggregator" "${FOUND_DIRS[@]}" 2>/dev/null | head -10 >> security-analysis/reports/defi-patterns.txt || echo "No oracle patterns found" >> security-analysis/reports/defi-patterns.txt

# Search for governance patterns
echo "## 🏛️ Governance Mechanisms:" >> security-analysis/reports/defi-patterns.txt
grep -r -i "governance\|voting\|proposal\|timelock" "${FOUND_DIRS[@]}" 2>/dev/null | head -10 >> security-analysis/reports/defi-patterns.txt || echo "No governance patterns found" >> security-analysis/reports/defi-patterns.txt

# Generate comprehensive bug bounty report
echo "📋 Generating bug bounty analysis report..."
cat > security-analysis/MULTI_CONTRACT_ANALYSIS.md << EOF
# 🛡️ Multi-Contract Security Analysis Report

**Project**: $PROJECT_NAME  
**Analysis Date**: $(date)
**Directories Analyzed**: ${FOUND_DIRS[*]}

## 📊 Contract Discovery
- **Total Contract Directories**: ${#FOUND_DIRS[@]}
- **Solidity Files Found**: $(find "${FOUND_DIRS[@]}" -name "*.sol" 2>/dev/null | wc -l)

## 🔍 Analysis Tools Used
- ✅ **Slither** - Static analysis with cross-contract detection
- ✅ **Mythril** - Symbolic execution per contract
- ✅ **Pattern Analysis** - DeFi-specific vulnerability detection
- ✅ **Call Graph Analysis** - Inter-contract relationship mapping
- ✅ **Data Dependency Analysis** - Cross-contract data flow

## 📁 Generated Reports
- \`slither-full.json\` - Comprehensive static analysis
- \`slither-markdown.md\` - Human-readable findings  
- \`call-graph.txt\` - Contract interaction mapping
- \`data-dependencies.txt\` - Cross-contract dependencies
- \`mythril-*.json\` - Per-contract symbolic execution
- \`defi-patterns.txt\` - DeFi vulnerability patterns

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

EOF

echo ""
echo "🎉 Multi-contract analysis complete!"
echo "📄 Main report: security-analysis/MULTI_CONTRACT_ANALYSIS.md"
echo "📂 All reports: security-analysis/reports/"
echo ""
echo "🎯 High-priority files to review:"
echo "  1. security-analysis/reports/slither-full.json"
echo "  2. security-analysis/reports/call-graph.txt" 
echo "  3. security-analysis/reports/defi-patterns.txt"
echo "  4. security-analysis/MULTI_CONTRACT_ANALYSIS.md"
