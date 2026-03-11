# AI Readiness Checklist

## Overview

This checklist helps teams assess how prepared their repositories are for AI-first development. It is org-agnostic and applicable to any codebase - use it to identify gaps, track progress, and prioritize improvements.

The checklist is organized into four groups, progressing from basic setup to mature AI-first practices.

## Tool Initialization

Is the repo set up for AI?

- [ ] AI instructions file exists (CLAUDE.md, AGENTS.md, or .cursorrules)
- [ ] MCP servers configured (.mcp.json or equivalent)
- [ ] Skills installed (.agents/skills/ or .claude/skills/)
- [ ] Ignore files configured (.claudeignore, .cursorignore)
- [ ] Secrets managed via env vars or credential managers (not hardcoded)

## Repository Knowledge

Can the AI understand the project?

- [ ] Project structure documented (architecture, key directories)
- [ ] Technology stack documented
- [ ] Build/test/deploy commands documented
- [ ] External dependencies documented
- [ ] Code patterns and conventions documented

## Workflow Depth

Can the AI work effectively?

- [ ] MUST/SHOULD rules defined
- [ ] Branch naming and commit conventions specified
- [ ] PR template exists
- [ ] Test requirements documented
- [ ] CI/CD pipeline described

## Development Process

Is the team AI-first?

- [ ] Spec-driven development practiced (specs before code)
- [ ] AI-assisted code review in place
- [ ] Configuration evolves (rules added when corrections repeat)
- [ ] Team members trained on AI-first practices
- [ ] Cross-repo context available (ARCHITECTURE.md, USE_CASES.md)

## Scoring Guide

Count the number of checked items and divide by the total (20) to get a readiness percentage.

| Score | Level | Description |
|-------|-------|-------------|
| 0-40% (0-8 items) | Getting Started | Basic setup incomplete. Focus on Tool Initialization and Repository Knowledge first. |
| 40-70% (9-14 items) | Progressing | Foundations in place. Fill gaps in Workflow Depth and start adopting Development Process practices. |
| 70-90% (15-18 items) | Advanced | Strong AI-first posture. Refine rules based on real-world friction and share patterns across repos. |
| 90%+ (19-20 items) | AI-First Native | Mature AI-first workflow. Focus on cross-repo consistency and mentoring other teams. |

## How to Use This Checklist

**Initial assessment**: Walk through each item with your team. Check items that are genuinely in place - not aspirational, but actually working today.

**Prioritization**: Items in earlier groups (Tool Initialization, Repository Knowledge) are prerequisites for later groups. A repo with perfect Workflow Depth but no AI instructions file will not benefit from those rules.

**Tracking progress**: Re-run the assessment quarterly. Track scores per repo if you manage multiple repositories.

**Team discussion**: Use unchecked items as conversation starters. Some items may not apply to every repo - that is fine. The goal is awareness, not a perfect score.

## Reference

The ASO team (aso-ai-toolkit) maintains a detailed readiness dashboard tracking these criteria across their repos. Their 22-criteria version includes team-specific items; this checklist captures the universal subset applicable to any organization.

## See Also

- [Onboarding Guide](onboarding-guide.md) - Getting started as a new engineer on an AI-first team
- [Tools Checklist](../01-foundations/tools-checklist.md) - Environment setup and verification
- [Config Evolution](../02-lifecycle/06-config-evolution.md) - Maintaining AI configuration over time
