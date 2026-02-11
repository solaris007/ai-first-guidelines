---
marp: true
theme: adobe
paginate: true
header: 'AI-First Development'
footer: 'github.com/adobe/ai-first-guidelines'
---

<!-- _class: lead -->
<!-- _paginate: false -->
<!-- _header: '' -->

# AI-First Development

## A New Way of Building Software

**[Your Name]**
[Your Role]

---

# What is AI-First Development?

- AI is your **design partner**, not just autocomplete
- Think of it as a **brilliant but junior colleague**
  - Fast and capable
  - Needs clear guidance
  - Can be confidently wrong
- Your expertise keeps it on track
- Result: **faster delivery, you stay in control**

---

# The Big Shift

### Old Way
Jump into coding, document later (or never)

### New Way
1. Describe what you want in plain language
2. AI helps refine before any code is written
3. Documentation happens as a byproduct

**Your knowledge becomes the foundation**

---

# The 5-Phase Workflow

| Phase | What Happens |
|-------|--------------|
| **1. Design** | Describe requirements in markdown |
| **2. Plan** | AI breaks it into actionable steps |
| **3. Build** | AI writes code, you guide decisions |
| **4. Validate** | Tests ensure it works correctly |
| **5. Complete** | Docs updated, ready for handoff |

Each phase has clear inputs, outputs, and checkpoints.

---

# Your Role

## You define the **what** and **why**
- Business requirements
- Acceptance criteria
- Constraints and context

## AI drafts the **how**
- Implementation approach
- Code structure
- Technical details

## You verify and approve
Review AI's work like a junior's: **trust but verify**

---

# Guardrails Keep Everyone Safe

- **MUST rules** — Non-negotiable (security, tests, no secrets)
- **SHOULD rules** — Strong recommendations
- AI follows your team's standards automatically
- Nothing ships without proper review
- Clear audit trail of all decisions

```markdown
# Example CLAUDE.md rules
- MUST run tests before committing
- MUST NOT commit secrets or credentials
- SHOULD use conventional commit messages
```

---

# The Risks

AI accelerates everything—including failure modes.

| Risk | What Happens |
|------|--------------|
| **The Review Gap** | 10x production, 1x review capacity |
| **Scope Creep by Vibe** | "We can just add it" compounds tech debt |
| **Prototype-to-Prod Gap** | Localhost success ≠ production success |
| **Traditional Exp. Matters** | Experts guide AI better, catch mistakes |
| **Flow Hypnosis** | Speed dulls critical thinking |

**The faster you can move, the more important your brakes.**

---

# Durable vs Fluid Substrate

<!-- _class: smaller -->

**Durable** — Core platform (auth, data, APIs)
- Traditional engineering rigor
- Failures cascade; changes infrequent
- Built by experienced engineers

**Fluid** — Features and integrations
- Moves fast, tolerates controlled failure
- **Primary goal: deliver customer value quickly**
- Producers: engineers AND domain experts

**Domain Experts** — SEO, GEO, analytics, content specialists who can now ship with AI assistance. The durable substrate keeps them safe.

---

# Vibeproofing

Protecting production from under-reviewed code

```
MUST   Have automated gates that cannot be bypassed
MUST   Require tests before merge
MUST   Deploy to staging first
MUST   Have another human review
```

**Vibeproofing Checklist:**
- [ ] Tests pass (automated, not "I ran it")
- [ ] Human reviewed (not just AI)
- [ ] Staging verified
- [ ] Rollback ready

---

# Tools of the Trade

### AI Coding Assistants
- **Claude Code** — CLI-based, full codebase understanding
- **Cursor** — IDE with AI built-in
- **GitHub Copilot** — Inline suggestions in VS Code

### MCP (Model Context Protocol)
Connect AI to your tools:
- Jira / Confluence
- GitHub / GitLab
- Slack, databases, deployment systems

---

# What This Means For You

| Before | After |
|--------|-------|
| Specs get lost or outdated | Specs are the source of truth |
| "What does this code do?" | Code explains itself via AI |
| Manual status updates | Jira/Slack updated automatically |
| Context lost between handoffs | Full history preserved |

**Faster turnaround, fewer misunderstandings**

---

# Resources

### Documentation
```
ai-first-guidelines/
├── 01-foundations/    # Core concepts, setup
├── 02-lifecycle/      # 5-phase workflow details
├── 03-templates/      # Ready-to-use templates
├── 04-configuration/  # Tools, plugins, MCP
├── 05-guardrails/     # MUST/SHOULD rules
└── 06-adoption/       # Team case studies
```

### Get Involved
- **Repo**: github.com/adobe/ai-first-guidelines
- **Issues**: Questions, ideas, feedback welcome
- **PRs**: Contributions encouraged

---

<!-- _class: lead -->
<!-- _paginate: false -->

# Ready to Start?

## Next: [Getting Started](getting-started.md)

Hands-on guide to set up your environment

---

**[Your Name]** — [your-email]

github.com/adobe/ai-first-guidelines
