#!/bin/bash
# Test flexible dependency resolution

echo "🧪 Testing Flexible Dependency Resolution..."

echo "📦 Testing Web3 ecosystem with flexible versions..."
python3 -c "
import subprocess
import sys

packages_to_test = [
    'web3>=7.0.0,<8.0.0',
    'slither-analyzer>=0.9.0,<1.0.0',
    'mythril>=0.23.0,<1.0.0',
    'requests>=2.28.0,<3.0.0'
]

print('Testing flexible dependency installation...')
for package in packages_to_test:
    try:
        result = subprocess.run([
            sys.executable, '-m', 'pip', 'install', '--dry-run', package
        ], capture_output=True, text=True, timeout=30)
        
        if result.returncode == 0:
            print(f'✅ {package} - dependency resolution OK')
        else:
            print(f'⚠️  {package} - may have conflicts')
            
    except subprocess.TimeoutExpired:
        print(f'⏰ {package} - timeout during dependency check')
    except Exception as e:
        print(f'❌ {package} - error: {e}')

print('\\n🎯 Flexible dependency test completed!')
"

echo "🔍 Testing requirements.txt validation..."
if [ -f "requirements.txt" ]; then
    echo "✅ requirements.txt found"
    echo "📋 Contents:"
    cat requirements.txt
else
    echo "❌ requirements.txt not found"
fi

echo "🚀 Dependency resolution test complete!"
