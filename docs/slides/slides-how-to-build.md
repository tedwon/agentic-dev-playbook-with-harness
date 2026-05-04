# How to Generate Slides

## Slide File

`agentic-harness.md` — Marp-based presentation

## Quick Generate (HTML + PDF)

```bash
marp agentic-harness.md --html -o agentic-harness.html && marp agentic-harness.md --html --pdf -o agentic-harness.pdf

marp agentic-harness-en.md --html -o agentic-harness-en.html && marp agentic-harness-en.md --html --pdf -o agentic-harness-en.pdf
```

> `--html` flag is required for inline HTML elements (cards, diagrams).

## Individual Commands

```bash
# HTML
marp agentic-harness.md --html -o agentic-harness.html

# PDF
marp agentic-harness.md --html --pdf -o agentic-harness.pdf

# PPTX
marp agentic-harness.md --html --pptx -o agentic-harness.pptx

# Browser preview (live reload)
marp agentic-harness.md --html --preview
```

## Open in Browser

```bash
open agentic-harness.html
```

## Install Marp CLI

```bash
# Global install
npm install -g @marp-team/marp-cli

# Or use npx (no install needed)
npx @marp-team/marp-cli agentic-harness.md --html -o agentic-harness.html
```

## VS Code Preview

1. Install **Marp for VS Code** extension
2. Open `agentic-harness.md`
3. Click preview icon or `Cmd+Shift+V`

## Keyboard Shortcuts (Presentation)

| Key | Action |
|-----|--------|
| `→` / `←` | Next / Previous slide |
| `F` | Fullscreen |
| `Esc` / `O` | Slide overview |
