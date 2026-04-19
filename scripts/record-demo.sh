#!/bin/bash
#
# Asciinema Recording Script for Agentic Development Playbook Demo
# JBUG Korea Seminar - AI Chatbot Feature Development
#
# Usage: ./scripts/record-demo.sh [output.cast]
# Default output: ~/agentic-playbook-demo.cast

set -e

OUTPUT_FILE="${1:-$HOME/agentic-playbook-demo.cast}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Agentic Development Playbook Demo Recorder"
echo "=========================================="
echo ""
echo "Output file: $OUTPUT_FILE"
echo "Project dir: $PROJECT_DIR"
echo ""

# Check dependencies
if ! command -v asciinema &> /dev/null; then
    echo "ERROR: asciinema is not installed"
    echo "Install with: brew install asciinema"
    exit 1
fi

if ! command -v expect &> /dev/null; then
    echo "ERROR: expect is not installed"
    echo "Install with: brew install expect"
    exit 1
fi

if ! command -v claude &> /dev/null; then
    echo "ERROR: claude command not found"
    echo "Make sure Claude Code CLI is installed"
    exit 1
fi

echo "All dependencies found!"
echo ""

# Create expect script
EXPECT_SCRIPT=$(cat << 'EOF'
#!/usr/bin/expect -f

set timeout -1
set project_dir [lindex $argv 0]

spawn asciinema rec ~/agentic-playbook-demo.cast --overwrite

expect "$ "
send "cd $project_dir\r"

expect "$ "
send "clear\r"

expect "$ "
send "claude\r"

# Wait for Claude to start and show the prompt
expect {
    "> " {}
    "claude" {}
    timeout { exit 1 }
}

# Small delay for Claude to fully initialize
sleep 2

# Send the initial prompt
send "Lets add a new feature for AI chatbot to the project.\r"

# Wait for first question
expect {
    -re "Question 1" {}
    timeout { exit 1 }
}

# Answer Q1: LLM-powered
sleep 1
send "b\r"

# Wait for Q2
expect {
    -re "Question 2" {}
    timeout { exit 1 }
}

# Answer Q2: Ollama
sleep 1
send "c\r"

# Wait for Q3
expect {
    -re "Question 3" {}
    timeout { exit 1 }
}

# Answer Q3: General chat
sleep 1
send "a\r"

# Wait for Q4
expect {
    -re "Question 4" {}
    timeout { exit 1 }
}

# Answer Q4: REST API
sleep 1
send "a\r"

# Wait for approach selection
expect {
    -re "Approach 1" {}
    timeout { exit 1 }
}

# Choose Approach 1
sleep 1
send "1\r"

# Wait for API design section and approve
expect {
    -re "API structure look right" {}
    timeout { exit 1 }
}
sleep 1
send "lgtm\r"

# Wait for architecture section and approve
expect {
    -re "architecture look good" {}
    timeout { exit 1 }
}
sleep 1
send "lgtm\r"

# Wait for error handling section and approve
expect {
    -re "look good" {}
    timeout { exit 1 }
}
sleep 1
send "lgtm\r"

# Wait for spec written message
expect {
    -re "Spec written" {}
    -re "implementation plan" {}
    timeout { exit 1 }
}

# Wait a moment for final output
sleep 3

# Exit Claude
send "\r"
send "/quit\r"

expect "$ "
send "exit\r"

expect eof
EOF
)

# Save expect script to temp file
EXPECT_FILE="/tmp/agentic-demo-record-$$.exp"
echo "$EXPECT_SCRIPT" > "$EXPECT_FILE"
chmod +x "$EXPECT_FILE"

echo "Starting asciinema recording..."
echo "The script will automatically:"
echo "  1. Start asciinema"
echo "  2. Launch Claude Code"
echo "  3. Type the user prompts"
echo "  4. Answer all clarifying questions"
echo "  5. Complete the brainstorming phase"
echo ""
echo "Press ENTER to start recording (or Ctrl+C to cancel)..."
read

# Run the expect script
expect "$EXPECT_FILE" "$PROJECT_DIR"

# Clean up
rm -f "$EXPECT_FILE"

echo ""
echo "=========================================="
echo "Recording complete!"
echo "=========================================="
echo ""
echo "File saved to: $OUTPUT_FILE"
echo ""
echo "To view the recording:"
echo "  asciinema play $OUTPUT_FILE"
echo ""
echo "To upload to asciinema.org:"
echo "  asciinema upload $OUTPUT_FILE"
echo ""
echo "To convert to GIF (requires agg):"
echo "  agg $OUTPUT_FILE demo.gif"
