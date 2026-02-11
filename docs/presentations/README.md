# Presentations

Slide decks for introducing AI-first development practices.

## Available Presentations

| Presentation | Audience | Description |
|--------------|----------|-------------|
| [intro.md](intro.md) | All technical staff | What AI-first development is, why it matters, the 5-phase workflow |
| [getting-started.md](getting-started.md) | Engineers ready to adopt | Hands-on setup guide: tools, CLAUDE.md, MCP configuration |

## Viewing Presentations

### Local Development Server (Recommended)

From the repository root:

```bash
# First time setup
make install

# Start local server
make serve
```

Then open http://127.0.0.1:8000/presentations/ in your browser.

### Build HTML Only

```bash
make presentations
# Output: site/presentations/*.html
```

### VS Code with Marp Extension

1. Install the [Marp for VS Code](https://marketplace.visualstudio.com/items?itemName=marp-team.marp-vscode) extension
2. Open any `.md` file in this folder
3. Click the Marp preview icon (or `Ctrl+Shift+V` / `Cmd+Shift+V`)
4. Use the slide navigation to present

### Export to PDF/PPTX

With Marp CLI:
```bash
# Install (if not already)
npm install -g @marp-team/marp-cli

# Export to PDF
marp intro.md --pdf

# Export to PowerPoint
marp intro.md --pptx
```

### Online (GitHub Pages)

Presentations are published automatically at:
- [Intro](https://solaris007.github.io/ai-first-guidelines/presentations/intro.html)
- [Getting Started](https://solaris007.github.io/ai-first-guidelines/presentations/getting-started.html)

## Marp Syntax Quick Reference

```markdown
---
marp: true
theme: default
paginate: true
---

# Slide 1 Title

Content here

---

# Slide 2 Title

- Bullet points
- Work as expected

---

<!-- _backgroundColor: #1e3a5f -->
<!-- _color: white -->

# Slide with custom styling

Only affects this slide (note the underscore prefix)
```

## Contributing

When editing presentations:

1. Keep slides concise (aim for 5-7 bullet points max)
2. Use the Marp preview to check formatting
3. Test exports if sharing outside VS Code
4. Update this README if adding new presentations
