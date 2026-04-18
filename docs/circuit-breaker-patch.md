# Circuit Breaker Patch — Infinite Loop Prevention

Review feedback: add a circuit breaker to prevent agents from looping indefinitely
on fix-and-retry cycles when the harness blocks a commit.

Three files need changes. All three are protected by the harness,
so apply these manually.

---

## 1. `.claude/hooks/pre-commit-harness.sh` — enforcement

Insert **after** line 34 (`cd "$PROJECT_ROOT"`) and **before** the `ERRORS=""` line:

```bash
# --- Circuit Breaker: track consecutive failures ---
RETRY_FILE="/tmp/.harness-retry-count-$(echo "$PROJECT_ROOT" | md5sum 2>/dev/null | cut -d' ' -f1 || echo "$PROJECT_ROOT" | md5 2>/dev/null | cut -d' ' -f1)"
MAX_RETRIES=3

if [ -f "$RETRY_FILE" ]; then
    RETRY_COUNT=$(cat "$RETRY_FILE" 2>/dev/null || echo 0)
else
    RETRY_COUNT=0
fi

if [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
    cat >&2 <<CIRCUIT
========================================
HARNESS: CIRCUIT BREAKER ACTIVATED
${RETRY_COUNT} consecutive commit failures detected.
========================================

STOP: Do not attempt another fix-and-retry cycle.
The error may require human judgment, domain knowledge,
or an approach change that automated retries cannot resolve.

ACTION REQUIRED:
1. Summarize what you have tried so far
2. Show the remaining error(s) to the human
3. Wait for human guidance before proceeding

To reset the circuit breaker after human review:
  rm "$RETRY_FILE"
========================================
CIRCUIT
    exit 2
fi
```

Then at the **end of the REPORT section**, update the two exit paths:

**On success** (replace `exit 0` at line 192):

```bash
    # Reset circuit breaker on success
    rm -f "$RETRY_FILE"
    exit 0
```

**On failure** (replace `exit 2` at line 210):

```bash
    # Increment circuit breaker counter
    echo $((RETRY_COUNT + 1)) > "$RETRY_FILE"
    exit 2
```

---

## 2. `CLAUDE.md` — Self-Correction Protocol

Replace step 6:

```
6. Repeat until all 7 checks pass
```

With:

```
6. Repeat until all 7 checks pass — but **maximum 3 consecutive attempts**.
   If the harness blocks 3 times in a row, STOP: summarize what you tried,
   show the remaining errors, and ask the human for guidance.
   The circuit breaker resets automatically on a successful commit.
```

---

## 3. `agentic-development-playbook_v0.2.md` — Key Pitfalls table

Add this row to the Key Pitfalls table (after the last existing row, before `---`):

```
| Agent stuck in infinite fix-and-retry loop | Circuit breaker: after 3 consecutive harness failures, stop and escalate to the human; the pre-commit hook enforces this automatically |
```

---

## How the circuit breaker works

```
  Agent commits
      │
      ▼
  pre-commit-harness.sh
      │
      ├─ Check retry count file
      │   └─ count >= 3? ──YES──▶ CIRCUIT BREAKER: block + tell agent to stop
      │
      ├─ Run 7 checks
      │
      ├─ All pass? ──YES──▶ Reset counter to 0, exit 0 (commit proceeds)
      │
      └─ Any fail? ──────▶ Increment counter, exit 2 (commit blocked)
```

The counter is stored in `/tmp/.harness-retry-count-<project-hash>` and
resets on success or manual `rm`. The value of `MAX_RETRIES` (default 3)
can be tuned in the hook script.
