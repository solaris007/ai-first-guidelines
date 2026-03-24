# Cross-Platform Skill Exposure Plan

## Shipping Agent Skills to Every Major AI Surface

---

## 1. Executive Summary

Agent Skills (agentskills.io) has emerged as the definitive open format for "write once, use everywhere" agent capabilities. Comprising folders of SKILL.md instructions, scripts, and resources, this standard has achieved broad native adoption across the CLI and IDE agent landscape, including Claude Code, Gemini CLI, OpenAI Codex CLI, Goose, OpenCode, Spring AI, and Qodo.

The critical "distribution layer" has been solved by Vercel's skills CLI (released January 2026) and the skills.sh registry, which normalize filesystem path divergence across 40+ agents. The remaining challenge lies in bridging the gap between these developer-centric CLI/IDE agents and the broader consumer and enterprise surfaces—such as Claude.ai web, ChatGPT web, Vertex AI, and Copilot Studio—where distribution requires platform-specific packaging.

This report maps the extensibility models of every major AI platform, identifies the gaps in consumer and enterprise cloud coverage, and proposes a strategic plan to maximize surface coverage by leveraging the SKILL.md standard as the "Source of Truth."

---

## 2. The Agent Skills Format — Core Primitives

The Agent Skills standard defines a skill as a modular directory containing the following primitives:

| Primitive | Purpose | Token Budget |
|-----------|---------|-------------|
| **Frontmatter** | Discovery & routing (name, description) — loaded at startup. | ~50-100 tokens/skill |
| **SKILL.md body** | Full procedural instructions — loaded on activation. | <5000 tokens |
| **scripts/** | Executable code (Python, Bash, JS) agents can run. | On-demand |
| **references/** | Supplementary docs loaded when needed. | On-demand |
| **assets/** | Templates, schemas, static files. | On-demand |

**Integration Modes:**
- **Filesystem-based**: Agents read SKILL.md via shell commands (e.g., Claude Code, Gemini CLI).
- **Tool-based**: Agents trigger skills through API tools when no filesystem is available (e.g., via MCP).

---

## 3. The Path Divergence Problem (and Its Solution)

### 3.1 Filesystem Paths Per Agent

Native support for SKILL.md is widespread, but each agent utilizes a unique directory convention, creating a fragmentation issue for manual installation:

| Agent | User-Level Skills | Project-Level Skills |
|-------|------------------|---------------------|
| **Claude Code** | `~/.claude/skills/` | `.claude/skills/` |
| **Gemini CLI** | `~/.gemini/skills/` | `.gemini/skills/` |
| **OpenAI Codex** | `~/.codex/skills/` | `.agents/skills/` |
| **GitHub Copilot** | — | `.github/skills/` |
| **Cursor** | — | `.cursor/skills/` |
| **Universal (XDG)** | `~/.agents/skills/` | `.agents/skills/` |

### 3.2 The Distribution Solution: Vercel's `skills` CLI

The `skills` CLI functions as the package manager for this ecosystem. It maintains a canonical copy of skills in `~/.agents/skills/` and generates symlinks to the specific directories required by each detected agent.

- **Install to all**: `npx skills add vercel-labs/agent-skills --skill frontend-design`
- **Registry**: skills.sh serves as the central directory and leaderboard.
- **Supported Agents**: Includes amp, claude-code, codex, cursor, gemini, github-copilot, and more.

### 3.3 Other Distribution Channels

| Channel | Model | Coverage |
|---------|-------|----------|
| **Vercel `skills` CLI** | GitHub repos → symlinks | CLI/IDE Agents (Native) |
| **SkillsMP.com** | Community marketplace | Discovery Layer |
| **Claude.ai Settings** | ZIP upload or Partner Directory | Claude Consumer Web |
| **OpenAI Sandbox** | Pre-loaded (`/home/oai/skills`) | ChatGPT Consumer Web |
| **Anthropic Plugins** | `/plugin marketplace add` | Claude Code |
| **Codex `$skill-installer`** | Built-in installer | Codex CLI |

---

## 4. Platform-by-Platform Analysis

### 4.1 Anthropic — Claude Ecosystem

**Surfaces**: Claude Code (CLI), Claude.ai (Web), Claude API.

- **Claude Code**: Native implementation. Discovers skills via system prompt injection and executes scripts via bash. Supports decentralized marketplaces via `marketplace.json`.
- **Claude.ai**: Consumer surface requires manual ZIP uploads (Settings > Capabilities) or admin provisioning. Skills run in a sandboxed Linux container (`/mnt/skills/`).
- **Strategy**: Primary distribution is via Git repositories for Claude Code. For the web consumer surface, tooling is needed to package skills into ZIPs or push via enterprise admin APIs.

### 4.2 OpenAI — Codex / ChatGPT Ecosystem

**Surfaces**: Codex CLI, Codex IDE, ChatGPT (Code Interpreter), Custom GPTs.

- **Codex CLI**: Full native support. Uses progressive disclosure, loading metadata first and full instructions only upon activation. Reads from `~/.codex/skills/` and `.agents/skills/`.
- **ChatGPT**: Pre-loads select skills server-side in the Code Interpreter sandbox. No direct user-facing upload mechanism for generic skills yet, though Custom GPTs map closely to the SKILL.md structure.
- **Apps SDK**: Allows building "Apps" (formerly plugins) that wrap MCP servers, providing a path for dynamic skill exposure.

### 4.3 Google — Gemini Ecosystem

**Surfaces**: Gemini CLI, Vertex AI, Agent Garden.

- **Gemini CLI**: Native support. Scans `.gemini/skills/` and executes via `activate_skill` tool. Supports extensions that bundle skills.
- **Vertex AI (Enterprise)**: The most robust enterprise path.
  - **Agent Development Kit (ADK)**: Can wrap SKILL.md instructions and scripts as ADK tools.
  - **Agent Garden**: A destination for pre-built agent samples.
  - **Gemini Enterprise**: Allows internal organization-wide distribution of registered agents.
- **A2A Protocol**: Google's "Agent-to-Agent" protocol is an emerging standard for cross-vendor interoperability, though production adoption is still nascent.

### 4.4 Microsoft — Copilot Ecosystem

**Surfaces**: GitHub Copilot, M365 Copilot, Copilot Studio.

- **GitHub Copilot**: Supports `.github/skills` and `.github/copilot-instructions.md` natively.
- **M365 Copilot / Studio**: Requires a "Declarative Agent" manifest. A compiler is needed to transform SKILL.md metadata into the manifest format and `scripts/` into Power Platform connectors or MCP server tools.

### 4.5 Meta — Llama Ecosystem

**Surfaces**: Llama Stack, Meta AI.

- **Llama Stack**: Uses a "Distribution" model where agents are bundles of models and tools. Integration requires an adapter to expose skills as Llama Stack tool providers.

---

## 5. The Three-Layer Model

**Layer 1 — Format (SOLVED ✅)**: SKILL.md is the universal standard.

**Layer 2 — Distribution to CLI/IDE (SOLVED ✅)**: Vercel's `skills` CLI handles path divergence and installation.

**Layer 3 — Consumer & Enterprise Surfaces (GAP 🔴)**: Platforms like Claude.ai, ChatGPT Web, and Copilot Studio do not participate in the filesystem model. They require compilers (e.g., Skill-to-ADK, Skill-to-Manifest).

---

## 6. Strategy for Maximum Surface Coverage

### Phase 1: Leverage Existing Infrastructure (Now)

- **Developer Focus**: Use `skills` CLI as the primary distribution channel.
- **Source of Truth**: Publish valid SKILL.md packages to GitHub.
- **Symlinking**: Use the `~/.agents/skills` universal path to instantly bridge all local CLI agents.

### Phase 2: Bridge to Consumer Surfaces (1-3 Months)

- **Claude.ai**: Automate ZIP packaging for manual uploads.
- **Vertex AI**: Develop a "Skill-to-ADK" bridge to compile skills into enterprise agents.

### Phase 3: Enterprise Cloud Distribution (3-6 Months)

- **Copilot Studio**: Build a compiler to generate declarative agent manifests from SKILL.md.
- **Agent Garden**: Publish high-quality skills as ADK agent samples.
- **A2A**: Ensure architectural compatibility for future cross-vendor interop.

---

## 7. Vertex AI Deep Dive — The Enterprise Pipeline

Google's Vertex AI offers a high-leverage path for enterprise distribution:

1. **Input**: SKILL.md folder.
2. **Compiler**: "Skill-to-ADK" parses frontmatter to metadata, body to system instructions, and `scripts/` to ADK tools.
3. **Deploy**: `adk deploy` pushes the agent to the Agent Engine runtime.
4. **Register**: The agent is registered in Gemini Enterprise, making it discoverable to employees.
5. **Marketplace**: Optionally listed in Google Cloud Marketplace for external discovery.

---

## 8. Skills vs. MCP — The Convergence

While the Model Context Protocol (MCP) provides a standard transport for tools, Agent Skills often subsume the need for a dedicated server in developer environments.

**The Skill Advantage**: A skill that instructs "run `gh pr list --json`" replaces the need for a persistent "GitHub MCP Server." It is simpler, stateless, and dependency-free.

**The MCP Niche**: MCP remains essential for:
- **Sandboxed Consumers**: Web surfaces (Claude.ai) that lack shell access.
- **Governance**: Enterprise scenarios requiring centralized API control (e.g., via Apigee/Cloud API Registry).
- **Auth Management**: OAuth flows for non-technical users.

**Strategic Conclusion**: Skills are the primary primitive for logic and workflows. MCP is the fallback transport layer for constrained or governed environments.

---

## 9. Key Strategic Recommendations

**The Format War is Over**: Do not invent new formats. Adopt SKILL.md and the agentskills standard.

**Distribution is Key**: Rely on Vercel's `skills` CLI for the "long tail" of developer agents.

**Build Compilers, Not Forks**: Maintain one skill repository. Build build-time tools that compile that repository into M365 Manifests, ADK Agents, and ZIP archives.

**Wait on A2A**: The Agent-to-Agent protocol is architecturally sound but lacks production adoption. Ensure compatibility, but prioritize Vertex AI and Copilot Studio for immediate enterprise reach.