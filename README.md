# Ralph - Autonomous Coding Agent

Ralph is an autonomous coding agent that designs PRDs from objectives and
executes them using Claude Code with sub-agents.

## Installation

```bash
./install-ralph.sh
source ~/.zshrc
```

## Usage

From any project directory:

```bash
# Interactive mode - creates PRD or uses existing
ralph.sh

# With max iterations
ralph.sh 20

# Direct execution (requires existing PRD)
ralph-turbo.sh 10
```

## How it works

1. **PRD Generation**: Describe your objective, Ralph generates a structured PRD.json
2. **Execution**: Ralph iterates through tasks using sub-agents (Explore, Bash, Plan)
3. **Progress Tracking**: Each iteration logged to progress.json with structured data
4. **Completion**: Tasks marked complete in PRD.json

## File Structure

- `PRD.json` - Structured task list with phases and status
- `progress.json` - Iteration history with timestamps, changes, and summaries

## Browser Automation (Optional)

Enable Ralph to test UI features autonomously with Playwright:

```bash
./setup-browser.sh
```

This installs Playwright and Chromium in the sandbox. Ralph can then:
- Run Playwright tests: `npx playwright test`
- Generate tests interactively: `npx playwright codegen https://example.com`
- Script browser interactions directly

## Requirements

- Claude Code CLI
- Docker (for sandboxed execution)
