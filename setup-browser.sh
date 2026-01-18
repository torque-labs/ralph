#!/bin/bash
# Setup browser automation in Ralph sandbox
# Usage: ./setup-browser.sh

set -e

SANDBOX_NAME="ralph-sandbox"

echo "============================================"
echo "  Setting up Playwright in Ralph sandbox"
echo "============================================"
echo ""

# Check if sandbox exists
if ! docker sandbox ls 2>/dev/null | grep -q "$SANDBOX_NAME"; then
  echo "Creating sandbox '$SANDBOX_NAME'..."
  docker sandbox run --name "$SANDBOX_NAME" claude --version || {
    echo ""
    echo "Sandbox needs authentication. Please run:"
    echo "  docker sandbox run --name $SANDBOX_NAME claude"
    echo "Then authenticate, /exit, and run this script again."
    exit 1
  }
fi

echo "Installing Playwright and Chromium..."
echo ""

docker sandbox run --name "$SANDBOX_NAME" bash -c "
  echo 'Installing Playwright...'
  npm install -g playwright @playwright/test

  echo ''
  echo 'Installing Chromium browser...'
  npx playwright install chromium --with-deps

  echo ''
  echo 'Verifying installation...'
  npx playwright --version
"

echo ""
echo "============================================"
echo "  Browser setup complete!"
echo "============================================"
echo ""
echo "Ralph can now use Playwright for browser automation:"
echo ""
echo "  # Run Playwright tests"
echo "  npx playwright test"
echo ""
echo "  # Interactive scripting"
echo "  node -e \"const { chromium } = require('playwright'); ...\""
echo ""
echo "  # Generate tests"
echo "  npx playwright codegen https://example.com"
echo ""
