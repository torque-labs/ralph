#!/bin/bash
# Ralph - Autonomous Coding Agent
# Designs PRDs from objectives, then executes them
#
# Usage: ./ralph.sh [iterations]
# Example: ./ralph.sh 10

set -e

cd "$(dirname "$0")"

ITERATIONS=${1:-10}
SANDBOX_NAME="ralph-sandbox"
OUTPUT_FILE=".ralph-output-$$.txt"
PROMPT_FILE=".ralph-prompt-$$.md"

echo "============================================"
echo "  Ralph - Autonomous Coding Agent"
echo "============================================"
echo ""

cleanup() {
  rm -f "$OUTPUT_FILE"
  rm -f "$PROMPT_FILE"
}
trap cleanup EXIT

# Check/create sandbox
ensure_sandbox() {
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
}

# Generate PRD from objective
generate_prd() {
  local objective="$1"

  echo ""
  echo "Generating PRD from objective..."
  echo ""

  cat > "$PROMPT_FILE" << PROMPT_EOF
You are Ralph, an autonomous coding agent. Generate a structured PRD.json for the following objective.

## OBJECTIVE
$objective

## INSTRUCTIONS
1. Analyze the objective and break it into concrete, actionable tasks
2. Create a PRD.json with this structure:
\`\`\`json
{
  "title": "Project title",
  "description": "Brief description",
  "status": "in_progress",
  "createdAt": "ISO timestamp",
  "phases": [
    {
      "id": 1,
      "name": "Phase name",
      "status": "pending",
      "tasks": [
        {
          "id": 1,
          "title": "Task title",
          "description": "What needs to be done",
          "status": "pending",
          "priority": "high|medium|low"
        }
      ]
    }
  ]
}
\`\`\`
3. Tasks should be specific and completable (not vague)
4. Group related tasks into phases
5. Order tasks by dependency (what needs to happen first)
6. Include 10-30 tasks depending on complexity
7. Write the PRD.json file to the current directory
8. Create progress.json with this structure:
\`\`\`json
{
  "startedAt": "ISO timestamp",
  "iterations": []
}
\`\`\`

Write the PRD.json and progress.json now. Be thorough but practical.
PROMPT_EOF

  docker sandbox run --name "$SANDBOX_NAME" claude \
    --permission-mode acceptEdits \
    -p "@$PROMPT_FILE" \
    2>&1 | tee "$OUTPUT_FILE"

  if [ -f "PRD.json" ]; then
    echo ""
    echo "✓ PRD.json generated successfully"
    return 0
  else
    echo ""
    echo "✗ Failed to generate PRD.json"
    return 1
  fi
}

# Execute PRD tasks
execute_prd() {
  local prd_file="$1"

  cat > "$PROMPT_FILE" << 'PROMPT_EOF'
You are Ralph TURBO, an aggressive autonomous coding agent that uses sub-agents for speed.

## YOUR CAPABILITIES
You have access to the Task tool to spawn sub-agents:
- **Explore agent**: For codebase exploration, finding files, understanding patterns
- **Bash agent**: For running builds, tests, commands
- **Plan agent**: For designing implementation approaches

## WORKFLOW
1. Read PRD.json and progress.json to understand current state
2. Identify ALL tasks with `"status": "pending"`
3. Use sub-agents IN PARALLEL to gather information and execute:
   - Spawn Explore agent to find relevant files
   - Spawn Bash agent to run tests/builds
   - Spawn multiple agents simultaneously when tasks are independent
4. Implement the work yourself using the information gathered
5. Bundle MULTIPLE related tasks into ONE iteration
6. **Mark completed tasks by editing PRD.json**: Change `"status": "pending"` to `"status": "completed"`
7. **Update progress.json**: Add an iteration entry to the `iterations` array:
   ```json
   {
     "iteration": 1,
     "timestamp": "ISO timestamp",
     "tasksCompleted": ["task ids or titles"],
     "summary": "What was accomplished",
     "filesChanged": ["list of files modified"],
     "issues": ["any problems encountered"]
   }
   ```
8. Use git pull before committing to avoid conflicts
9. Commit with clear message

## AGGRESSIVE RULES
- BUNDLE 2-5 related tasks per iteration when possible
- Use Task tool with Explore agent instead of manual file searching
- Run Bash agents in parallel for independent commands
- Fix ALL issues found in testing within same iteration
- Don't stop at first error - investigate and fix
- Aim to complete 20-40% of remaining work per iteration
- Always git pull before committing to avoid merge conflicts

## GIT WORKFLOW
1. Run: git pull --rebase origin main (or current branch)
2. Make your changes
3. Run: git add -A && git commit -m 'feat: description'
4. If conflicts occur, resolve them before continuing

## COMPLETION
When ALL tasks in PRD.json have `"status": "completed"`, output: <promise>COMPLETE</promise>

BEGIN by reading PRD.json and progress.json, then aggressively tackle remaining work using sub-agents.
PROMPT_EOF

  for ((i=1; i<=$ITERATIONS; i++)); do
    echo ""
    echo "=========================================="
    echo "  Iteration $i of $ITERATIONS"
    echo "  $(date '+%Y-%m-%d %H:%M:%S')"
    echo "=========================================="

    docker sandbox run --name "$SANDBOX_NAME" claude \
      --permission-mode acceptEdits \
      -p "@PRD.json @progress.json @$PROMPT_FILE" \
      2>&1 | tee "$OUTPUT_FILE"

    if grep -q "<promise>COMPLETE</promise>" "$OUTPUT_FILE" 2>/dev/null; then
      echo ""
      echo "=========================================="
      echo "  PRD COMPLETE!"
      echo "  Finished after $i iterations"
      echo "=========================================="
      return 0
    fi

    sleep 2
  done

  echo ""
  echo "=========================================="
  echo "  Reached max iterations ($ITERATIONS)"
  echo "  Run again: ./ralph.sh $ITERATIONS"
  echo "=========================================="
}

# Main flow
main() {
  ensure_sandbox

  # Check if PRD exists
  if [ -f "PRD.json" ]; then
    echo "Found existing PRD.json"
    echo ""
    echo "Options:"
    echo "  1) Continue with existing PRD"
    echo "  2) Create new PRD (will backup existing)"
    echo "  3) Exit"
    echo ""
    read -p "Choice [1]: " choice
    choice=${choice:-1}

    case $choice in
      1)
        echo "Continuing with existing PRD..."
        ;;
      2)
        mv PRD.json "PRD.json.backup.$(date +%s)"
        echo ""
        read -p "Enter your objective: " objective
        if [ -z "$objective" ]; then
          echo "No objective provided. Exiting."
          exit 1
        fi
        generate_prd "$objective"
        ;;
      3)
        echo "Exiting."
        exit 0
        ;;
      *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
    esac
  elif [ -f "PRD.md" ]; then
    echo "Found existing PRD.md"
    echo ""
    echo "Options:"
    echo "  1) Continue with existing PRD.md"
    echo "  2) Convert to PRD.json and continue"
    echo "  3) Create new PRD.json (will keep PRD.md)"
    echo "  4) Exit"
    echo ""
    read -p "Choice [1]: " choice
    choice=${choice:-1}

    case $choice in
      1)
        echo "Continuing with PRD.md..."
        ;;
      2)
        echo "Converting PRD.md to PRD.json..."
        cat > "$PROMPT_FILE" << 'CONVERT_EOF'
Read PRD.md and convert it to PRD.json format:
```json
{
  "title": "...",
  "description": "...",
  "status": "in_progress",
  "phases": [
    {
      "id": 1,
      "name": "...",
      "status": "pending",
      "tasks": [
        { "id": 1, "title": "...", "description": "...", "status": "pending|completed", "priority": "high|medium|low" }
      ]
    }
  ]
}
```
Preserve the completion status of tasks (checked boxes = completed).
Write PRD.json to the current directory.
CONVERT_EOF
        docker sandbox run --name "$SANDBOX_NAME" claude \
          --permission-mode acceptEdits \
          -p "@PRD.md @$PROMPT_FILE" \
          2>&1 | tee "$OUTPUT_FILE"
        ;;
      3)
        echo ""
        read -p "Enter your objective: " objective
        if [ -z "$objective" ]; then
          echo "No objective provided. Exiting."
          exit 1
        fi
        generate_prd "$objective"
        ;;
      4)
        echo "Exiting."
        exit 0
        ;;
      *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
    esac
  else
    echo "No PRD found in $(pwd)"
    echo ""
    read -p "Enter your objective (or 'exit' to quit): " objective
    if [ -z "$objective" ] || [ "$objective" = "exit" ]; then
      echo "Exiting."
      exit 0
    fi
    generate_prd "$objective"
  fi

  # Ensure progress.json exists
  if [ ! -f "progress.json" ]; then
    echo '{"startedAt": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'", "iterations": []}' > progress.json
  fi

  # Execute
  echo ""
  echo "Starting execution with $ITERATIONS max iterations..."
  echo "Press Ctrl+C to stop early"
  echo ""
  sleep 2

  execute_prd
}

main
