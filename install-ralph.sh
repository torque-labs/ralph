#!/bin/bash
# Install Ralph globally
# Usage: ./install-ralph.sh

set -e

RALPH_DIR="$HOME/.ralph"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing Ralph to $RALPH_DIR..."

mkdir -p "$RALPH_DIR"

# Copy scripts
cp "$SCRIPT_DIR/ralph.sh" "$RALPH_DIR/"
cp "$SCRIPT_DIR/ralph-turbo.sh" "$RALPH_DIR/" 2>/dev/null || true

chmod +x "$RALPH_DIR"/*.sh

# Add to PATH if not already there
SHELL_RC=""
if [ -f "$HOME/.zshrc" ]; then
  SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
  SHELL_RC="$HOME/.bashrc"
fi

if [ -n "$SHELL_RC" ]; then
  if ! grep -q 'export PATH="$HOME/.ralph:$PATH"' "$SHELL_RC" 2>/dev/null; then
    echo '' >> "$SHELL_RC"
    echo '# Ralph - Autonomous Coding Agent' >> "$SHELL_RC"
    echo 'export PATH="$HOME/.ralph:$PATH"' >> "$SHELL_RC"
    echo "Added Ralph to PATH in $SHELL_RC"
  else
    echo "Ralph already in PATH"
  fi
fi

echo ""
echo "✓ Ralph installed successfully!"
echo ""
echo "Usage (from any directory with a project):"
echo "  ralph.sh              # Interactive mode - creates or uses PRD"
echo "  ralph.sh 20           # Run with 20 max iterations"
echo "  ralph-turbo.sh 10     # Direct execution mode (requires existing PRD)"
echo ""
echo "Restart your terminal or run:"
echo "  source $SHELL_RC"
