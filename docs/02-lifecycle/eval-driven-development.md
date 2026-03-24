# Eval-Driven Development (EDD)

> Like TDD for AI agents: build datasets/evaluators first, then improve until they pass.

## What is EDD?

Eval-Driven Development applies the TDD mindset to AI agents. Instead of writing unit tests before code, you write **evaluators** before optimizing an agent. The evaluators define "good" — then you iterate until the agent meets that bar.

The key insight: AI agents don't have deterministic outputs, so traditional tests can't fully cover them. EDD replaces pass/fail unit tests with **scored evaluations** (deterministic checks + LLM-as-judge) and replaces "green CI" with **score thresholds**.

## The EDD Lifecycle

```
┌─────────────────────────────────────────────────────────────┐
│                    DEVELOPMENT (offline)                     │
│                                                             │
│  0. Build dataset       ──►  /eval-dataset                  │
│  1. Write evaluators    ──►  /evaluate-agent-offline        │
│  2. Run baseline        ──►  get initial scores             │
│  3. Auto-improve        ──►  /auto-improve-agent            │
│  4. Log results         ──►  IMPROVEMENT_LOG.md             │
│  5. Publish             ──►  /publish-evals                 │
│                              (sync dataset + scores)        │
└──────────────────────────────┬──────────────────────────────┘
                               │ deploy
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                   PRODUCTION (online)                        │
│                                                             │
│  6. Capture traces      ──►  Langfuse auto-tracing          │
│  7. Sample & evaluate   ──►  sample N days of traces,       │
│                              run full evaluator suite        │
│  8. Feed back           ──►  add failing traces to offline   │
│                              dataset                        │
│  9. Auto-improve again  ──►  /auto-improve-agent            │
│ 10. Publish updated     ──►  update Langfuse dataset +      │
│     results                  scores                         │
└─────────────────────────────────────────────────────────────┘
```

## Phase 1: Development (Offline)

### Step 0 — Build Dataset

Before writing evaluators, create or curate a dataset with `/eval-dataset`:

```bash
/eval-dataset <agent_name>
```

Useful options:

```bash
/eval-dataset <agent_name> --list                       # list existing Langfuse datasets
/eval-dataset <agent_name> --source blackboard-db       # bootstrap from DB facts
/eval-dataset <agent_name> --source langfuse-traces     # bootstrap from traces
```

`/eval-dataset` is responsible for dataset bootstrapping and curation. It writes/updates the local YAML dataset (source of truth in git), while also supporting Langfuse dataset discovery via `--list`.

### Step 1 — Write Evaluators

Before optimizing anything, define what "good" means. Use `/evaluate-agent-offline` to scaffold the evaluation:

```bash
/evaluate-agent-offline <agent_name>
```

This creates:
```
app/opportunities/<agent_name>/evaluation/
├── datasets/
│   └── <agent_name>_comprehensive.yaml   # test cases (from /eval-dataset)
├── evaluators.py                          # deterministic + LLM judges
├── schemas.py                             # expected output shapes
└── run_baseline.py                        # runner script
```

**Evaluator types:**
- **Deterministic** — objective, fast, free (format checks, field presence, value ranges)
- **LLM-as-judge** — subjective quality scoring (correctness, completeness, specificity)

The YAML dataset contains a metadata header and test cases with agent-specific inputs and expected outputs:

```yaml
dataset:
  name: "broken_links_producer_eval"
  version: "1.0.0"
  description: |
    Evaluation dataset for BacklinkAlternativesProducer.
    Tests tiered processing: redirect detection, heuristic matching, LLM analysis.

test_cases:
  - id: heuristic_locale_match
    enabled: true
    category: heuristic
    scenario: "Broken URL with locale should match same-locale alternative"

    input:
      site_id: "example.com"
      d_verified_broken_backlinks:       # agent-specific typed facts
        verified:
          - url_from: "https://external-site.com/article"
            url_to: "https://www.example.com/de/products/old-product"
            http_status: 404
      o_sitemap:
        urls:
          - url: "https://www.example.com/de/products/new-product"
          - url: "https://www.example.com/en/products/new-product"

    expected_output:
      description: "Should prefer /de/ locale match over /en/"
      min_recommendations: 1
      expected_urls:
        - "https://www.example.com/de/products/new-product"
      constraints:
        - "skipped == false"
```

Each agent's dataset uses that agent's real input facts and output schema. See `app/opportunities/broken_links/evaluation/datasets/` or `app/evaluation/h1_optimization_producer/datasets/` for full examples.

### Step 2 — Run Baseline

Run the evaluators against the current agent to get initial scores:

```bash
/evaluate-agent-offline <agent_name>
```

Output shows per-test scores and an overall score:

```
Results: 5/9 passed (threshold: 0.8)
  overall_score: 0.72
  correctness:   0.85
  completeness:  0.60
  specificity:   0.71
```

This is your baseline — the "red" in TDD terms.

### Step 3 — Auto-Improve

Use `/auto-improve-agent` to analyze failures and propose fixes:

```bash
/auto-improve-agent <agent_name>
```

The skill:
1. Runs the baseline evaluation
2. Identifies failure patterns (which evaluators fail most, common root causes)
3. Proposes targeted changes (prompt tuning, threshold adjustments, code fixes)
4. Validates the improvement by re-running evaluators
5. Only accepts changes that improve scores without regressions

### Step 4 — Log Results

Every improvement session produces an `IMPROVEMENT_LOG.md` in the evaluation directory:

```
app/opportunities/<agent_name>/evaluation/IMPROVEMENT_LOG.md
```

The log captures:
- **Failure patterns identified** — what went wrong and why
- **Changes made** — exact files, what changed, reasoning
- **Test results** — before/after scores with deltas
- **Verdict** — whether the improvement was validated
- **Lessons learned** — insights for future improvements
- **Remaining failures** — what still needs work

See [broken_links IMPROVEMENT_LOG](../../app/opportunities/broken_links/evaluation/IMPROVEMENT_LOG.md) for a real example.

### Step 5 — Publish to Langfuse

Once offline scores are satisfactory, publish to Langfuse to create a shared record:

```bash
/publish-evals <agent_name>
```

This:
1. **Syncs the local YAML dataset** to a Langfuse dataset (creates or updates)
2. **Runs evaluators** through the Langfuse-traced pipeline
3. **Publishes scores** to each trace in Langfuse
4. Creates a **dataset run** tagged with the commit SHA

After publishing, the team can see scores in the Langfuse dashboard, compare runs over time, and review individual trace evaluations.

## Phase 2: Production (Online)

### Step 6 — Capture Traces

In production, Langfuse auto-instruments all agent executions. Every producer run, crew execution, or agent call is traced with:
- Full input/output
- Tool calls and their results
- LLM prompts and completions
- Timing and token usage
- Tags (agent name, opportunity type, site, org)

No action needed — this happens automatically via the Langfuse SDK instrumentation.

### Step 7 — Sample & Evaluate Production Traces

Periodically (or on-demand), sample recent production traces and evaluate them offline:

```bash
/sample-traces <agent_name> --days 7
```

This:
1. Fetches traces from Langfuse for the agent over the past N days (each trace already contains `input` + `actual_output`)
2. Runs the **full evaluator suite** from Step 1 against each trace's output — both deterministic checks and LLM-as-judge
3. Identifies traces that **score below threshold** (failures in production)
4. Reports a summary:

```
Sampled 142 traces from last 7 days
  Above threshold: 128 (90.1%)
  Below threshold:  14 (9.9%)

Top failure patterns:
  - completeness < 0.7:  8 traces (missing recommendations for edge cases)
  - correctness < 0.8:   4 traces (wrong URL matching for non-English sites)
  - specificity < 0.6:   2 traces (generic advice instead of site-specific)
```

Evaluators inspect the trace's actual output directly — no `expected_output` is needed. Deterministic evaluators check structural properties of the output (format, field presence, value ranges). LLM judges assess quality (correctness, completeness, specificity). Same evaluators, same scores, directly comparable to offline.

### Optional — Audit Judge Quality on Sampled Traces

After Step 7 scores traces, you can optionally audit whether the evaluators got it right:

```bash
/sample-traces <agent_name> --days 7 --audit-size 30 --drift-report
```

This:
1. Picks a mixed subset of scored traces (some that passed, some that failed) for human review
2. Exports the subset with evaluator scores so a reviewer can agree/disagree with each verdict
3. After review, computes judge audit metrics (fail precision, pass miss rate)
4. Produces a drift snapshot across key segments (`locale`, `site_type`, `org_id`)
5. Recommends import mode for Step 8 (`auto` or `confirmed-only`)

Recommended defaults:
- Audit **20-40 traces/week** per active agent
- Ensure sampled traces cover key segments (`locale`, `site_type`, `org_id`)
- Switch to `confirmed-only` import if judge metrics degrade

### Step 8 — Feed Back to Offline Dataset

Failing production traces become new test cases:

```bash
/sample-traces <agent_name> --days 7 --import-failures --import-policy auto
# or
/sample-traces <agent_name> --days 7 --import-failures --import-policy confirmed-only
```

This:
1. Takes the failing traces from Step 7
2. Converts them to YAML test cases (trace input becomes test input, trace output is preserved as reference)
3. Appends them to the local dataset YAML
4. Tags them with `source: production` and the trace ID for traceability

Import policy:
- `auto` — import judge-failing traces directly
- `confirmed-only` — import only failures confirmed by human review

The dataset grows organically with real-world edge cases that the original hand-crafted dataset didn't cover.

### Step 9 — Auto-Improve Again

With the expanded dataset (original + production failures), run auto-improve:

```bash
/auto-improve-agent <agent_name>
```

The improvement loop now targets real production issues. The IMPROVEMENT_LOG.md gets a new entry documenting:
- Which production traces exposed the failure
- What change fixed it
- Before/after scores on both original and new test cases

### Step 10 — Publish Updated Results

After improvement, publish the updated dataset and scores back to Langfuse:

```bash
/publish-evals <agent_name>
```

This closes the loop:
- Langfuse dataset is updated with the new production-derived test cases
- New scores are published as a fresh dataset run
- The team can compare pre-improvement vs post-improvement scores
- Production traces that originally failed can be re-evaluated

## Skills Mapping

EDD unifies four focused skills into a coherent workflow:

| Phase | Skill | Role in EDD |
|-------|-------|-------------|
| Build/curate dataset | `/eval-dataset` *(new)* | Bootstrap local YAML dataset, list Langfuse datasets (`--list`) |
| Write evaluators + baseline | `/evaluate-agent-offline` | Scaffolding + local execution |
| Improve agent | `/auto-improve-agent` | Analyze failures + propose fixes |
| Publish to Langfuse | `/publish-evals` *(new)* | Sync dataset + scores to Langfuse |
| Sample production traces | `/sample-traces` *(new)* | Fetch + evaluate + import failures |

The existing `/optimize-agent` skill is **deprecated** in favor of this workflow. Its dataset bootstrapping, baseline, and optimization capabilities are absorbed into `/eval-dataset`, `/evaluate-agent-offline`, `/publish-evals`, and `/auto-improve-agent`.

## What Changes from Today

| Before (fragmented) | After (EDD) |
|---------------------|-------------|
| 3 overlapping skills with different entry points | 4 focused skills: dataset → evaluate → improve → publish/monitor |
| `/optimize-agent` requires Langfuse from the start | Start fully offline, publish when ready |
| Dataset creation is ad-hoc and mixed into optimization | `/eval-dataset` handles dataset bootstrapping and Langfuse `--list` discovery |
| No production feedback loop | Automatic: sample traces → find failures → expand dataset |
| No practical judge quality guardrail | Lightweight sampled human audit of judge decisions |
| No drift visibility during import | Drift snapshot informs what gets human-reviewed/imported |
| IMPROVEMENT_LOG.md only from auto-improve | IMPROVEMENT_LOG.md is the central artifact of every EDD cycle |
| Datasets live in Langfuse OR locally (unclear) | Local YAML is source of truth, synced to Langfuse |
| No connection between prod failures and evaluations | Failing traces become test cases automatically |

## Directory Structure (per agent)

```
app/opportunities/<agent_name>/evaluation/
├── datasets/
│   └── <agent_name>_comprehensive.yaml   # source of truth for test cases
├── evaluators.py                          # deterministic + LLM-as-judge
├── schemas.py                             # Pydantic output models
├── run_baseline.py                        # offline runner
├── JUDGE_AUDIT_LOG.md                     # sampled human-review metrics + import policy decisions
├── IMPROVEMENT_LOG.md                     # history of all improvement sessions
└── eval_config.yaml                       # Langfuse sync config (dataset name, tags)
```

## Principles

1. **Offline first** — evaluators must run without any external service. Langfuse is for sharing and production monitoring, not a prerequisite.
2. **Local YAML is source of truth** — the dataset YAML in git is authoritative. Langfuse is a synced copy.
3. **Evaluators are reusable** — the same evaluator suite (deterministic + LLM-as-judge) runs offline and on sampled production traces.
4. **Production feeds development** — failing production traces expand the dataset, preventing regression on real-world edge cases.
5. **Everything is logged** — IMPROVEMENT_LOG.md provides a human-readable audit trail of every change and its impact.
6. **Scores are directly comparable** — offline and sampled-online scores come from the same evaluator suite.
7. **Judges are audited, not exhaustively validated** — human spot checks on sampled traces keep effort bounded.
8. **Drift guides sampling/import policy** — drift signals where to audit more and when to switch to `confirmed-only` imports.

## Building a Golden Dataset from Production Signals

EDD starts with hand-crafted datasets, but the highest-value test cases come from real user behavior. The team cannot review all agent-generated opportunities, so the golden dataset should be built incrementally from implicit and explicit user signals.

### Signal tiers

| Signal | Source | Strength | Example |
|--------|--------|----------|---------|
| **Opportunity ignored** | UI telemetry | Weak / neutral | User opened an opportunity page but took no action |
| **Opportunity rejected** | UI telemetry | Strong negative | User explicitly dismissed or declined a suggestion |
| **Opportunity accepted** | UI telemetry | Strong positive | User accepted and applied a suggestion |
| **Explicit feedback** | UI / chat | Strong (either) | Thumbs up/down, free-text comment, or chat-based feedback |

Rejected opportunities are the most valuable signal for the dataset — they represent cases where the agent's output was wrong or unhelpful enough that a user actively said no.

### Phase 1: UI telemetry (current priority)

Track three interaction states for every opportunity/suggestion presented to users:

1. **Viewed but no action** — user opened the opportunity detail but did not accept or reject. This is a neutral signal; the opportunity may have been useful but not acted on, or the user may not have had time.
2. **Accepted** — user applied the suggestion. Positive signal confirming the agent's recommendation was actionable.
3. **Rejected / not approved** — user explicitly declined. Strong signal that the agent's output needs improvement for this input.

These signals flow into the golden dataset:
- **Rejected** opportunities become test cases where the agent should produce *different* output (negative examples)
- **Accepted** opportunities become test cases where the agent should produce *similar* output (positive examples)
- **Viewed-only** opportunities are candidates for human review to determine if they should be positive or negative examples

Related Jira:
- [SITES-38640](https://jira.corp.adobe.com/browse/SITES-38640) — UI telemetry for opportunity interactions
- [SITES-38639](https://jira.corp.adobe.com/browse/SITES-38639) — Feedback collection mechanism

### Phase 2: Chat-based feedback (future)

When the chat feature is introduced, conversational interactions become another feedback source:
- User asks follow-up questions about an opportunity → signal that the guidance was unclear or incomplete
- User asks the agent to regenerate or modify a suggestion → signal about quality gaps
- Explicit praise or complaints in conversation → direct quality signal

Chat traces in Langfuse can be correlated with the opportunity that triggered them, enriching the dataset with conversational context.

### How signals become dataset entries

```
Production signals (UI telemetry, chat)
    │
    ▼
/sample-traces <agent_name> --days 7
    │  fetches traces + correlates with UI signals
    │
    ▼
Failing traces + rejected opportunities
    │
    ▼
/sample-traces --import-failures
    │  converts to YAML test cases tagged with signal source
    │
    ▼
Local dataset (golden over time)
    │
    ▼
/auto-improve-agent <agent_name>
    │  improves agent using real user feedback
    │
    ▼
/publish-evals <agent_name>
```

Over time, the dataset shifts from hand-crafted examples to production-grounded cases backed by real user decisions. This directly addresses the [self-labeling circularity limitation](#1-self-labeling-circularity) — user accept/reject signals provide ground truth independent of evaluator judgments.

### Current state

- The suggestion projection model (`db/projection_models.py`) already tracks `SuggestionStatus` (`new`, `in_progress`, `fixed`) but has no `accepted`/`rejected` states
- The guide-viewer UI has thumbs up/down buttons but only logs to browser console — no backend persistence
- No telemetry events are emitted when users interact with opportunities

The Jira tickets above track the work to close these gaps.

## Known Limitations

### 1. Self-labeling circularity

When failing traces are imported into the offline dataset, the evaluator scores that flagged them as failures also shape what the dataset considers "expected." In ML terms this is self-labeling: `/auto-improve-agent` optimizes the agent to satisfy the evaluators, not necessarily ground truth. The human audit step (Step 8) partially mitigates this — reviewers can disagree with evaluator verdicts — but it does not eliminate the risk. Teams should periodically review imported test cases for evaluator bias and add independently-labeled ground-truth cases to the dataset.

### 2. Threshold-only validation lacks statistical rigor

The workflow uses pass rates and score thresholds (e.g., "5/9 passed, threshold 0.8") but does not define confidence intervals, variance controls, or significance tests. In traditional ML, release decisions require uncertainty-aware comparisons (e.g., "new prompt is better with p < 0.05"). EDD treats scores as point estimates. For agents with high output variance or small datasets, a score improvement of +0.04 may not be meaningful. Teams should be cautious about acting on small deltas and should increase dataset size before drawing conclusions.

### 3. Deployment safety gates are under-specified

EDD defines a feedback loop (sample → evaluate → improve → publish) but does not prescribe canary deployments, champion-challenger testing, rollback policies, or KPI guardrails. After `/auto-improve-agent` proposes a change and `/publish-evals` pushes updated scores, there is no built-in mechanism to verify the change performs well in production before full rollout. This is weaker than standard MLOps practice. Teams deploying to production should layer their own deployment safety (e.g., gradual rollout, monitoring dashboards, automatic rollback on KPI regression) on top of EDD.

## Implementation Status

| Component | Status | Notes |
|-----------|--------|-------|
| `/eval-dataset` | **New** | Build/curate datasets, list Langfuse datasets via `--list` |
| `/evaluate-agent-offline` | Exists | Keep as-is, entry point for EDD |
| `/auto-improve-agent` | Exists | Keep as-is, produces IMPROVEMENT_LOG.md |
| `/publish-evals` | **New** | Sync local dataset to Langfuse, run eval, publish scores |
| `/sample-traces` | **New** | Sample traces, evaluate, import failures to local dataset |
| `/optimize-agent` | Deprecate | Capabilities absorbed into EDD workflow |
| `app/evaluation/` framework | Exists | Has Langfuse score publishing, dataset sync, trace fetching |
| Production auto-tracing | Exists | Langfuse instrumentation already in place |
| IMPROVEMENT_LOG.md pattern | Exists | Used by broken_links, standardize for all agents |
