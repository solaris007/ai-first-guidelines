# Auto-Improve Agent Skill Design

> **Decision**: Create a new `/auto-improve-agent` skill that composes with `/evaluate-agent-offline`

## Context

We want to enable automatic agent improvement using evaluation datasets and evaluators to:
1. Identify failure patterns
2. Propose code changes
3. Validate improvements through re-evaluation
4. Create PRs for successful improvements

## Design Decisions (Confirmed)

| Question | Decision |
|----------|----------|
| **Separate skill?** | Yes - evaluate has its own iterative workflow (building datasets, tuning evaluators) |
| **Granularity** | Support `--analyze-only` and `--suggest-only` modes |
| **Model control** | Evals use their own model (gpt-4o-mini); improvements use GPT-4.1 |
| **Scope** | Start with prompts, then structural code (sequential in one run) |
| **Human-in-loop** | No - auto-evaluate in the loop without approval |
| **Rollback** | PR-based; humans handle recovery |

## Relationship to Existing Skills

```
┌─────────────────────────────────────────────────────────────┐
│                      /optimize-agent                         │
│  (bootstraps optimization: Langfuse → local test cases)      │
│  (prepares data for auto-improve)                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ triggers
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    /auto-improve-agent                       │
│  (orchestrates improvement loop, git operations, PR creation)│
└─────────────────────────────────────────────────────────────┘
                              │
                              │ uses
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  /evaluate-agent-offline                     │
│  (runs evaluations, returns scores and failure details)      │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ uses
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              app/evaluation/<agent>/                         │
│  (datasets, evaluators, schemas, run_baseline.py)            │
└─────────────────────────────────────────────────────────────┘
```

### Skill Responsibilities

| Skill | Responsibility |
|-------|----------------|
| `/evaluate-agent-offline` | Measure agent performance using local datasets |
| `/auto-improve-agent` | Iterate on agent code to improve evaluation scores |
| `/optimize-agent` | Bootstrap optimization (Langfuse → local), then delegate to auto-improve |

**Workflow**: `/optimize-agent` pulls production data → stores as local test cases → triggers `/auto-improve-agent` → which uses `/evaluate-agent-offline` for validation.

### `/optimize-agent` vs `/auto-improve-agent` Comparison

| Aspect | `/optimize-agent` | `/auto-improve-agent` |
|--------|-------------------|----------------------|
| **Evaluation Backend** | **Langfuse** (cloud service) | **Local** (YAML datasets + evaluators) |
| **Dependencies** | Requires Langfuse account & API | No external services needed |
| **Data Source** | Production traces from Langfuse | Local test datasets |
| **Setup Effort** | Higher (scripts, tool replay, Langfuse config) | Lower (just needs eval directory) |
| **Analysis** | Manual prompt iteration | **LLM-powered** (GPT-4.1 analyzes failures) |
| **Code Changes** | Manual (you modify prompts) | **Automatic** (LLM generates find/replace) |
| **Validation** | Run in Langfuse, check scores | Runs evaluation twice locally |

### When to Use Which

**Use `/optimize-agent`** when:
- Starting from scratch with no test data
- Want to pull real production traces from Langfuse
- Need the full optimization infrastructure

**Use `/auto-improve-agent`** when:
- Already have local evaluation datasets (via `/evaluate-agent-offline`)
- Want fast, automated improvement cycles
- Don't want to depend on external services
- Want LLM-powered analysis and automatic code fixes

## Proposed Workflow

```
┌─────────────────────────────────────────────────────────────┐
│  /auto-improve-agent h1_optimization_producer               │
│                                                             │
│  Options:                                                   │
│    --max-iterations 3     (default: 3)                      │
│    --analyze-only         (pattern analysis, no changes)    │
│    --suggest-only         (show suggestions, don't apply)   │
│    --create-pr            (create PR if improved)           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  (a) Run baseline evaluation                                │
│      → Run evaluation, capture structured results           │
│      → Store results as baseline                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  (b) Analyze failure patterns                               │
│      → Group failures by evaluator                          │
│      → Identify common issues (missing keywords, etc.)      │
│      → Generate improvement hypotheses                      │
│      → [If --analyze-only: stop here]                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  (c) Read and understand agent code                         │
│      → Find producer/crew files                             │
│      → Identify prompts, tools, flow                        │
│      → Map failures to code locations                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────────┐
│  (d) Propose and apply improvement                            │
│      → Phase 1: Try prompt improvements first                 │
│      → Phase 2: Try structural code changes if needed         │
│      → [If --suggest-only: show diff and stop]                │
│      → Apply change automatically                             │
└───────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  (e) Validate improvement (run eval twice for consistency)  │
│      → Run evaluation twice                                 │
│      → Compare to baseline                                  │
│      → Auto-continue without human approval                 │
└─────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
                    ▼                   ▼
        ┌───────────────────┐  ┌───────────────────┐
        │  Improved?        │  │  Not improved?    │
        │  → (f) Branch+PR  │  │  → (g) Revert     │
        │  → Report success │  │  → Try again      │
        └───────────────────┘  │  → (if < max)     │
                               └───────────────────┘
                                        │
                                        │ iteration < max?
                                        ▼
                               ┌───────────────────┐
                               │  Back to (d)      │
                               │  with new context │
                               │  (track what      │
                               │   didn't work)    │
                               └───────────────────┘
```

## Key Design Decisions

### 1. Granularity Modes

| Mode | Behavior |
|------|----------|
| `--analyze-only` | Run baseline, analyze patterns, report findings |
| `--suggest-only` | Analyze + propose changes, show diffs, don't apply |
| Default | Full loop: analyze → apply → validate → iterate |
| `--create-pr` | Default + create PR with successful improvements |

### 2. Improvement Scope (Sequential)

Changes are applied in phases within a single run:

```
Phase 1: Prompt improvements
  └── Modify instructions, examples, constraints
  └── Re-evaluate
  └── If still failing → Phase 2

Phase 2: Structural code changes
  └── Add/modify tools
  └── Change flow logic
  └── Re-evaluate
```

### 3. Model Usage

| Component | Model | Reason |
|-----------|-------|--------|
| Evaluators | gpt-4o-mini | Fast, cheap, configured per evaluator |
| Pattern Analysis | GPT-4.1 (Azure) | Good reasoning, already configured in project |
| Code Generation | GPT-4.1 (Azure) | Reliable find/replace generation |

### 4. Iteration Limits

```bash
# Try up to 5 different improvements before giving up
/auto-improve-agent my_producer --max-iterations 5
```

The skill tracks what changes were attempted to avoid repeating failed approaches.

### 5. Statistical Confidence

Run evaluation **twice** after each change to reduce noise:
- Both runs must show improvement
- Prevents lucky/unlucky single runs from misleading

### 6. Branch Strategy

```
main (or current branch)
  └── auto-improve/<agent>-<timestamp>
        └── Contains all successful improvements
        └── PR created with evaluation diff showing before/after scores
```

### 7. Rollback Strategy

- All changes go through PR review
- Humans handle recovery if improvements prove problematic in production
- PR includes full evaluation report for informed review

## File Structure

```
.claude/skills/auto-improve-agent/
├── SKILL.md                 # Main skill definition
├── resources/
│   ├── analyze_failures.py  # Pattern detection from eval results
│   ├── propose_changes.py   # Generate improvement suggestions
│   └── validate_improvement.py  # Compare before/after
├── templates/
│   └── pr_template.md       # PR description template
└── references/
    └── improvement-patterns.md  # Common improvement strategies
```

## Implementation Phases

### Phase 1: Prerequisites
- [x] Extend `/evaluate-agent-offline` to output structured JSON (`--output json`) ✅
- [x] Ensure evaluators report failure reasons (not just pass/fail) ✅
- [x] Document agent code conventions (where prompts live, etc.) ✅

### Phase 2: MVP (Single Iteration)
- [ ] Create `/auto-improve-agent` skill skeleton
- [ ] Implement `--analyze-only` mode (baseline + pattern analysis)
- [ ] Implement `--suggest-only` mode (+ code reading + diff generation)
- [ ] Implement single improvement cycle (apply + validate)

### Phase 3: Full Loop
- [ ] Add `--max-iterations` support with revert logic
- [ ] Track attempted changes to avoid repeating failures
- [ ] Implement Phase 1 → Phase 2 scope escalation (prompts → code)

### Phase 4: PR Integration
- [ ] `--create-pr` with branch management
- [ ] PR template with before/after evaluation scores
- [ ] Integration with existing PR workflows

## Technical Requirements

### 1. Evaluation Output Format ✅ IMPLEMENTED

`/evaluate-agent-offline --output json` returns:

```json
{
  "agent": "h1_optimization_producer",
  "dataset": "h1_optimization_producer_eval_dataset",
  "dataset_version": "1.0.0",
  "summary": {
    "total": 5,
    "passed": 3,
    "failed": 2,
    "skipped": 0,
    "score": 0.75
  },
  "evaluator_averages": {
    "schema_compliance": 1.0,
    "constraints": 0.8,
    "llm_seo_quality": 0.65
  },
  "test_cases": [
    {
      "id": "test-case-1",
      "status": "failed",
      "passed": false,
      "score": 0.4,
      "evaluators": [
        {
          "name": "llm_seo_quality",
          "passed": false,
          "score": 0.1,
          "reason": "Primary keyword 'solar panels' missing from H1",
          "errors": ["Primary keyword 'solar panels' missing from: \"Sustainable Energy Solutions\""],
          "details": {
            "primary_keyword": "solar panels",
            "primary_included": false
          }
        }
      ]
    }
  ]
}
```

**Key fields for auto-improve:**
- `summary.score` - Overall evaluation score (0-1)
- `test_cases[].evaluators[].reason` - Why the evaluator failed (extracted from errors/details)
- `test_cases[].evaluators[].errors` - List of specific error messages
- `evaluator_averages` - Which evaluators are performing poorly overall

### 2. Agent Code Discovery

The skill needs to locate agent code. Convention:

| Agent Type | Location Pattern |
|------------|------------------|
| Producer | `app/services/blackboard/producers/<name>_producer.py` |
| Crew | `app/agents/crews/<name>/` |
| LangGraph | `app/agents/<name>_agent.py` or `app/agents/<name>/` |

#### Prompt Locations by Agent Type

**CrewAI Crews** (`app/agents/crews/<name>/`):
```
app/agents/crews/<crew_name>/
├── <crew_name>.py          # Crew class, @agent and @task decorators
├── config/
│   ├── agents.yaml         # Agent definitions (role, goal, backstory)
│   └── tasks.yaml          # Task definitions (description, expected_output)
└── tools/                  # Optional custom tools
```

The `agents.yaml` contains:
```yaml
<agent_name>:
  role: "..."           # Agent's role/title
  goal: "..."           # What the agent aims to achieve
  backstory: "..."      # Context/personality (THIS IS THE MAIN PROMPT)
```

The `tasks.yaml` contains:
```yaml
<task_name>:
  description: "..."       # Task instructions (THIS IS THE TASK PROMPT)
  expected_output: "..."   # What the output should look like
  agent: <agent_name>      # Which agent handles this task
```

**Producers** (`app/services/blackboard/producers/<name>_producer.py`):
- System prompts in docstrings or string constants
- Often has a `SYSTEM_PROMPT` or `INSTRUCTIONS` variable
- May use `prompts.py` in same directory

**LangGraph Agents**:
- Prompts in node functions or dedicated `prompts.py`
- System messages in state initialization

### 3. Change Tracking

Track attempted changes to avoid loops:

```json
{
  "iteration": 2,
  "attempted_changes": [
    {
      "iteration": 1,
      "type": "prompt",
      "file": "h1_producer.py",
      "description": "Added explicit keyword instruction",
      "result": "no_improvement",
      "before_score": 0.70,
      "after_score": 0.68
    }
  ]
}
```

## Next Steps

1. **Extend `/evaluate-agent-offline`** to support `--output json`
2. **Create skill skeleton** with `--help` support
3. **Implement `--analyze-only`** as the first working mode
4. **Iterate** through remaining phases

---

*Created: 2025-02-04*
*Updated: 2025-02-04*
*Status: Design Confirmed - Ready for Implementation*
