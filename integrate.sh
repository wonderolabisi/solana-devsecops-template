#!/bin/bash

# 🛡️ DevSecOps Integration Script
# This script copies the security pipeline to your existing project

echo "🛡️ DevSecOps Security Pipeline Integration"
echo "=========================================="

# Check if target directory is provided
if [ -z "$1" ]; then
    echo "❌ Usage: $0 <path-to-your-project>"
    echo "📋 Example: $0 /path/to/your-defi-project"
    exit 1
fi

TARGET_DIR="$1"
SOURCE_DIR="$(dirname "$0")"

# Verify target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ Target directory does not exist: $TARGET_DIR"
    exit 1
fi

echo "📁 Target project: $TARGET_DIR"
echo "📁 Source template: $SOURCE_DIR"
echo ""

# Create necessary directories
echo "📂 Creating directories..."
mkdir -p "$TARGET_DIR/.github/workflows"

# Copy essential files
echo "📋 Copying essential files..."

# 1. Copy main workflow
cp "$SOURCE_DIR/.github/workflows/devsecops.yml" "$TARGET_DIR/.github/workflows/"
echo "✅ Copied: .github/workflows/devsecops.yml"

# 2. Copy requirements.txt
cp "$SOURCE_DIR/requirements.txt" "$TARGET_DIR/"
echo "✅ Copied: requirements.txt"

# 3. Copy environment template
cp "$SOURCE_DIR/.env.example" "$TARGET_DIR/"
echo "✅ Copied: .env.example"

# 4. Copy integration guide
cp "$SOURCE_DIR/INTEGRATION_GUIDE.md" "$TARGET_DIR/"
echo "✅ Copied: INTEGRATION_GUIDE.md"

echo ""
echo "🎉 Integration Complete!"
echo ""
echo "📋 Next Steps:"
echo "1. cd $TARGET_DIR"
echo "2. git add ."
echo "3. git commit -m '🛡️ Add DevSecOps security pipeline'"
echo "4. git push"
echo ""
echo "🔍 The pipeline will automatically:"
echo "   • Scan all .sol files in your repository"
echo "   • Analyze all Rust/Cargo projects"
echo "   • Generate comprehensive security reports"
echo "   • Upload findings as GitHub Actions artifacts"
echo ""
echo "🚀 Check GitHub Actions tab after pushing for analysis results!"
