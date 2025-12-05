#!/usr/bin/env bash

set -euo pipefail

echo "=== Testing mayaflux-dev formula ==="
echo ""

echo "1. Syntax check..."
ruby -c Formula/mayaflux-dev.rb
echo "✅ Syntax is valid"

echo ""
echo "2. Required fields check..."
required_fields=("class MayafluxDev" "desc" "homepage" "url" "sha256")
for field in "${required_fields[@]}"; do
    if grep -q "$field" Formula/mayaflux-dev.rb; then
        echo "✅ Found: $field"
    else
        echo "❌ Missing: $field"
        exit 1
    fi
done

echo ""
echo "3. Dependencies check..."
dep_count=$(grep -c "depends_on" Formula/mayaflux-dev.rb)
echo "Found $dep_count dependencies"

echo ""
echo "4. Install method check..."
if grep -q "def install" Formula/mayaflux-dev.rb; then
    echo "✅ Install method found"
else
    echo "❌ Install method missing"
    exit 1
fi

echo ""
echo "=== All checks passed! ==="
