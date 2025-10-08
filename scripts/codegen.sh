#!/bin/bash

set -e

echo "🔧 Running React Native Codegen..."

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Ensure output directory exists
mkdir -p "ios/build/generated/ios"

# Run codegen
npx react-native codegen --path . --platform ios --outputPath ios/build/generated/ios

echo "✅ Codegen completed successfully"