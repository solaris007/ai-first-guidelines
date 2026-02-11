# Configuration Evolution

Your AI configuration is a living document. It should evolve as your project matures, patterns emerge, and tools change.

This guide covers when and how to update CLAUDE.md, .cursorrules, and similar AI configuration files.

## When to Add Rules

### The "Three Times" Heuristic

If you correct AI behavior three times for the same issue, add a rule.

| Correction | Action |
|------------|--------|
| Once | Normal iteration |
| Twice | Note the pattern |
| Three times | Add to config |

### Signals to Watch

- Repeatedly saying "no, use X instead of Y"
- Explaining the same context in multiple sessions
- AI suggesting patterns your team has abandoned
- New team members making the same mistakes

## When to Promote or Demote Rules

### SHOULD to MUST

Promote when:
- Violations cause production issues
- New team members consistently miss it
- The rule has zero valid exceptions

### MUST to SHOULD

Demote when:
- Legitimate exceptions keep appearing
- The rule was overreaction to one incident
- Technology changes make it less critical

### Remove Entirely

Remove when:
- The underlying tool/pattern no longer exists
- The rule has been superseded by automation
- Nobody can explain why it exists

## When to Restructure

### Warning Signs

Your config needs reorganization when:
- File exceeds 200 lines
- Scrolling to find relevant sections
- Rules contradict each other
- New team members can't parse it
- Related information is scattered

### Restructuring Patterns

1. **Group by purpose** - Rules, Working Context, Reference (not by when added)
2. **Use tables** - Scannable reference beats prose
3. **Extract details** - Move lengthy docs elsewhere, link to them
4. **Apply MUST/SHOULD syntax** - Clear priority for rules

## Review Cadence

### Quarterly Review

Schedule a 30-minute review each quarter:

1. **Audit rules** - Are all MUST rules still critical? Any SHOULD rules earned promotion?
2. **Check defaults** - Still accurate? Projects renamed? Repos moved?
3. **Prune stale content** - Remove references to deprecated tools, old epics, former team members
4. **Validate structure** - Still scannable? Need reorganization?

### Trigger-Based Reviews

Review immediately when:
- Major project milestone (launch, migration complete)
- Team composition changes (new members, reorg)
- Tooling changes (new MCP server, tool deprecated)
- Post-incident (if AI-assisted work contributed to issue)

## Cross-Tool Synchronization

If your team uses multiple AI tools, keep configurations aligned.

### Shared vs Tool-Specific Content

| Content | Share Across Tools | Tool-Specific |
|---------|-------------------|---------------|
| Project rules (MUST/SHOULD) | Yes | No |
| Working context/defaults | Yes | No |
| Code patterns | Yes | No |
| MCP configuration | No | Yes (different formats) |
| IDE-specific features | No | Yes |

### Synchronization Strategies

**Manual:** Review both files when updating either. Works for small teams.

**Template-based:** Maintain a source doc, generate tool-specific files.

```bash
# Example: shared source, tool-specific output
./scripts/generate-ai-config.sh --claude > CLAUDE.md
./scripts/generate-ai-config.sh --cursor > .cursorrules
```

**Shared sections:** Reference common markdown files or use symlinks for shared content.

## Anti-Patterns

### Configuration Drift

**Problem:** CLAUDE.md says one thing, .cursorrules says another, codebase does a third.

**Solution:** Single source of truth. Update config when patterns change, not after.

### Rule Hoarding

**Problem:** Rules accumulate but never get removed. Config becomes a graveyard of old decisions.

**Solution:** Every rule needs a reason. If you can't explain why, remove it.

### Premature Rules

**Problem:** Adding rules after one bad experience. Config fills with edge cases.

**Solution:** Wait for the pattern. One incident = note it. Three incidents = rule.

### Copy-Paste Configuration

**Problem:** Copying another team's config wholesale without adaptation.

**Solution:** Start minimal. Add rules as your team discovers its own patterns.

## Getting Started

### New Project

Start with minimal config:

1. Project description (one paragraph)
2. Tech stack
3. How to run tests
4. One or two MUST rules (the truly critical ones)

Add more as patterns emerge. Resist the urge to front-load rules.

### Existing Project

Audit what you have:

1. Read entire config - does it reflect current reality?
2. Remove anything outdated
3. Reorganize into Working Context / Rules / Reference sections
4. Fill gaps based on common AI questions

## See Also

- [CLAUDE.md Structure](../04-configuration/ai-tools/claude-code.md#claudemd)
- [.cursorrules Structure](../04-configuration/ai-tools/cursor.md#cursorrules)
- [SHOULD Rules](../05-guardrails/should-rules.md)
- [Example Workspace CLAUDE.md](../examples/workspace-claude-md.md)
