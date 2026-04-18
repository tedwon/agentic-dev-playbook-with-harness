@AGENTS.md

# Harness Engineering Rules

All rules are enforced automatically by pre-commit hooks — see [CHECKLIST.md](CHECKLIST.md).

## Self-Correction Protocol

When a commit is blocked by the harness:

1. Read the HARNESS error message carefully — it lists ALL failures with rule IDs
2. Fix ALL listed violations (not just the first one)
3. If BUILD-03 (formatting) fails: run `./mvnw spotless:apply`
4. Stage all changes with `git add`
5. Retry the commit with the same or corrected commit message
6. Repeat until all 7 checks pass

## Protected Files

Do NOT modify these files — they define the harness rules:

- `CLAUDE.md`
- `CHECKLIST.md`
- `.claude/settings.json`
- `.claude/hooks/*`

## Additional Build Commands

See the Development section in [AGENTS.md](AGENTS.md) for all available commands.
