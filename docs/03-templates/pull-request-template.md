# Pull Request Template with AI Disclosure

## Usage

Copy this template to your repository's `.github/` directory:

```bash
cp docs/03-templates/pull-request-template.md .github/PULL_REQUEST_TEMPLATE.md
```

Remove the Usage section and the "Why AI Disclosure?" section at the bottom. Keep everything between the `---` markers as your working template.

---

## Summary

<!-- What changed and why? Link to the relevant ticket. -->

**Ticket:** [PROJ-123](https://jira.example.com/browse/PROJ-123)

## Testing

<!-- How was this change validated? -->

- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manual testing performed (describe below)

**Manual testing notes:**

## AI Usage Disclosure

<!-- Be honest - this helps reviewers focus their attention. -->

**Was AI used in this change?**
- [ ] No AI assistance
- [ ] Yes (fill in below)

**Tool(s) used:** <!-- e.g., Claude Code, Cursor, GitHub Copilot, ChatGPT -->

**Level of AI involvement:**
- [ ] Assisted - AI helped with specific parts (autocomplete, suggestions, debugging)
- [ ] Primarily AI-generated - AI produced most of the code with human direction
- [ ] Fully AI-generated - AI generated the entire change from a prompt

**Level of understanding:**
- [ ] I fully understand all code in this PR
- [ ] Some sections need extra reviewer scrutiny (indicate which files/sections below)

**Sections needing extra review:** <!-- If applicable, list files or line ranges -->

## Checklist

- [ ] Tests pass locally
- [ ] Linting passes
- [ ] Documentation updated (if applicable)
- [ ] No secrets or credentials committed
- [ ] PR is linked to ticket
- [ ] Deployed to staging and verified (if applicable)

---

## Why AI Disclosure?

AI-accelerated development creates a specific risk: code that looks correct and passes a quick review but hasn't been deeply understood by the person submitting it. This template makes AI involvement visible so reviewers can calibrate their scrutiny.

This is not about discouraging AI use - it's about [vibeproofing](../05-guardrails/must-rules.md#vibeproofing). When a reviewer sees "primarily AI-generated" with "some sections need extra scrutiny," they know to slow down on those sections rather than assuming the author already caught the edge cases.

Key principles:
- **Honesty over optics** - Claiming no AI usage when AI was heavily involved undermines trust
- **Reviewers need context** - The review strategy for "I wrote this by hand" differs from "AI generated this from my prompt"
- **Understanding matters** - Shipping code you don't fully understand is a risk regardless of who (or what) wrote it

See [MUST Rules - Vibeproofing](../05-guardrails/must-rules.md#vibeproofing) for the full rationale.

*This template is adapted from the ASO UI team's PR process (Abhinav Saraswat, OneAdobe/experience-success-studio-ui).*
