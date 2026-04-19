#!/bin/bash
#
# Manual Recording Helper for Agentic Development Playbook Demo
# This script provides instructions for manual recording

set -e

OUTPUT_FILE="${1:-$HOME/agentic-playbook-demo.cast}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cat << 'EOF'

╔══════════════════════════════════════════════════════════════════════════════╗
║       AGENTIC DEVELOPMENT PLAYBOOK - ASCIINEMA RECORDING GUIDE              ║
║                        JBUG Korea Seminar Demo                               ║
╚══════════════════════════════════════════════════════════════════════════════╝

PREREQUISITES:
  • asciinema installed:  brew install asciinema
  • Claude Code CLI installed and authenticated
  • In the project directory: ~/github/tedwon/agentic-dev-playbook-with-harness

═══════════════════════════════════════════════════════════════════════════════
STEP 1: START RECORDING
═══════════════════════════════════════════════════════════════════════════════

  asciinema rec ~/agentic-playbook-demo.cast --overwrite

═══════════════════════════════════════════════════════════════════════════════
STEP 2: SETUP COMMANDS (type these)
═══════════════════════════════════════════════════════════════════════════════

  cd ~/github/tedwon/agentic-dev-playbook-with-harness
  clear
  claude

═══════════════════════════════════════════════════════════════════════════════
STEP 3: INITIAL PROMPT (copy-paste this)
═══════════════════════════════════════════════════════════════════════════════

  Lets add a new feature for AI chatbot to the project.

═══════════════════════════════════════════════════════════════════════════════
STEP 4: ANSWER QUESTIONS (type each answer when prompted)
═══════════════════════════════════════════════════════════════════════════════

  Claude will load skills and ask questions. Answer in order:

  ┌─────────────┬─────────────────────────────────────────────────────────────┐
  │ Question    │ Answer                                                      │
  ├─────────────┼─────────────────────────────────────────────────────────────┤
  │ Q1: Type?   │ b      (LLM-powered)                                       │
  │ Q2: Provider│ c      (Ollama)                                             │
  │ Q3: What?   │ a      (General chat)                                      │
  │ Q4: API?    │ a      (REST API endpoint)                                 │
  └─────────────┴─────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════════
STEP 5: SELECT APPROACH
═══════════════════════════════════════════════════════════════════════════════

  When Claude presents approaches, type:

  1      (Direct Ollama HTTP Integration - Recommended)

═══════════════════════════════════════════════════════════════════════════════
STEP 6: APPROVE DESIGN SECTIONS
═══════════════════════════════════════════════════════════════════════════════

  Claude will present design sections. Approve each with:

  lgtm

  Repeat for:
    • API Design
    • Architecture & Components
    • Error Handling, Configuration, Testing

═══════════════════════════════════════════════════════════════════════════════
STEP 7: SPEC COMPLETION
═══════════════════════════════════════════════════════════════════════════════

  Claude will write the spec to:
    docs/superpowers/specs/2025-04-19-ai-chatbot-design.md

  And commit it. Wait for the commit to complete.

═══════════════════════════════════════════════════════════════════════════════
STEP 8: END RECORDING
═══════════════════════════════════════════════════════════════════════════════

  Type this in your regular shell (not in Claude):

  exit

  Or press Ctrl+D to stop asciinema recording.

═══════════════════════════════════════════════════════════════════════════════
POST-RECORDING COMMANDS
═══════════════════════════════════════════════════════════════════════════════

  # Play back the recording
  asciinema play ~/agentic-playbook-demo.cast

  # Upload to asciinema.org (get shareable link)
  asciinema upload ~/agentic-playbook-demo.cast

  # Convert to GIF (requires agg: cargo install agg)
  agg ~/agentic-playbook-demo.cast demo.gif

═══════════════════════════════════════════════════════════════════════════════
TIPS FOR A CLEAN RECORDING
═══════════════════════════════════════════════════════════════════════════════

  ✓ Use a clean terminal window (no previous commands visible)
  ✓ Maximize terminal window for better visibility
  ✓ Type slowly and deliberately
  ✓ Wait for Claude to finish each response before continuing
  ✓ If you make a mistake, you can re-record:
      asciinema rec ~/agentic-playbook-demo.cast --overwrite

═══════════════════════════════════════════════════════════════════════════════

EOF

echo ""
echo "Ready to start recording?"
echo ""
echo "Option 1: Run the automated script (requires 'expect'):"
echo "  $SCRIPT_DIR/record-demo.sh"
echo ""
echo "Option 2: Follow the manual guide above and type commands yourself"
echo ""
echo "Press Enter to start asciinema recording now, or Ctrl+C to cancel..."
read

cd "$PROJECT_DIR"
clear
asciinema rec "$OUTPUT_FILE" --overwrite
