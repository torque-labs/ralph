#!/bin/bash
# Setup browser automation in Ralph sandbox
# Usage: ./setup-browser.sh

set -e

SANDBOX_NAME="ralph-sandbox"

echo "============================================"
echo "  Setting up Playwright in Ralph sandbox"
echo "============================================"
echo ""

# Check if sandbox exists, create if not
if ! docker sandbox ls 2>/dev/null | grep -q "$SANDBOX_NAME"; then
  echo "Creating sandbox '$SANDBOX_NAME'..."
  docker sandbox create --name "$SANDBOX_NAME" || {
    echo ""
    echo "Failed to create sandbox. Please run:"
    echo "  docker sandbox create --name $SANDBOX_NAME"
    echo "Then run this script again."
    exit 1
  }
else
  echo "Using existing sandbox '$SANDBOX_NAME'"
fi

echo "Installing Playwright and Chromium..."
echo ""

# Install directly using docker exec on the sandbox container
echo "Running installation in sandbox..."
docker exec -it "$SANDBOX_NAME" bash -c "
  echo 'Installing Playwright...'
  npm install -g playwright @playwright/test

  echo ''
  echo 'Installing Chromium browser (this may take a few minutes)...'
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
