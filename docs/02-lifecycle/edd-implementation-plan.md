# EDD Implementation Plan

> Implementation plan for the [Eval-Driven Development](EVAL_DRIVEN_DEVELOPMENT.md) workflow.

## Overview

Keep `/evaluate-agent-offline` and `/auto-improve-agent` as-is. Deprecate `/optimize-agent`. Add three new skills (`/eval-dataset`, `/publish-evals`, `/sample-traces`) to separate dataset bootstrapping from evaluation/publishing and close the development↔production feedback loop via Langfuse, with lightweight sampled human judge audits.

## Motivation: Why Deprecate `/optimize-agent`

The three existing evaluation skills have overlapping responsibilities that create confusion about which to use and when:

### Current Skill Comparison

| Aspect | `/evaluate-agent-offline` | `/optimize-agent` | `/auto-improve-agent` |
|--------|--------------------------|--------------------|-----------------------|
| **Goal** | Create evaluators, run locally, get scores | End-to-end optimization via Langfuse with automated prompt rewriting | Analyze failures, propose targeted fixes |
| **Dependencies** | None (offline, local YAML) | Langfuse, Azure OpenAI, sometimes DB | Local evaluators + LLM for analysis |
| **Complexity** | ~280 lines, 5 steps | ~1,700 lines, 9 steps + 3 agent-type sub-paths | ~260 lines, focused |
| **Dataset creation** | Simple YAML, no upload | 4 methods (traces, YAML, DB, manual), requires Langfuse upload | Uses existing dataset |
| **Evaluator pattern** | Standalone functions | Class hierarchy (`RuleBasedEvaluator`, `LLMBasedEvaluator`) | Uses existing evaluators |
| **Directory convention** | `app/evaluation/<agent_name>/` | `app/evaluation/<crew_name>/` | `app/opportunities/<name>/evaluation/` |
| **Output** | Pass/fail scores | Rewritten prompts + OPTIMIZATION_LOG.md | Code changes + IMPROVEMENT_LOG.md |

### Problems with `/optimize-agent`

1. **Monolithic scope** — One 1,700-line skill tries to cover dataset creation, Langfuse sync, optimization, CI/CD integration, and dashboard readiness. Too much for one skill.

2. **Conflicting patterns** — `/evaluate-agent-offline` uses standalone evaluator functions; `/optimize-agent` requires inheriting from base classes (`RuleBasedEvaluator`, `LLMBasedEvaluator`). Developers creating evaluators get contradictory guidance depending on which skill they start with.

3. **Conflicting directory conventions** — `/evaluate-agent-offline` points to `app/evaluation/<agent_name>/`, `/optimize-agent` points to `app/evaluation/<crew_name>/`, and the canonical producer pattern uses `app/opportunities/<name>/evaluation/`. Three conventions for the same thing.

4. **Langfuse as primary store** — `/optimize-agent` treats Langfuse as the dataset authority (upload via `load_dataset.py`, fetch via API). EDD inverts this: local YAML is source of truth, Langfuse is a synced copy.

5. **Disconnected production feedback** — `/optimize-agent` has resource scripts for pulling production traces (`find_traces.py`, `create_dataset_from_traces.py`), but this is a manual, ad-hoc process. There's no integrated workflow that evaluates sampled traces against the same evaluator suite used offline, identifies failures, and imports them back into the local dataset as regression cases.

6. **Agent-type coupling** — `/optimize-agent` requires choosing between three explicit paths (PATH A: LangGraph, PATH B: CrewAI, PATH C: FactProducers), each with different factory functions, optimizer modules, and prompt storage locations. This couples the optimization workflow to the agent architecture. In contrast, `/evaluate-agent-offline` and `/auto-improve-agent` are agent-type agnostic — they work with any agent as long as it has evaluators and a runner.

### How EDD Decomposes `/optimize-agent`

The useful capabilities from `/optimize-agent` are redistributed across focused skills:

| `/optimize-agent` capability | EDD equivalent |
|------------------------------|----------------|
| List existing Langfuse datasets | `/eval-dataset --list` (new) |
| Create/bootstrap local YAML dataset (scratch, DB, traces) | `/eval-dataset` (new) |
| Create YAML evaluator scaffolding + run baseline scores | `/evaluate-agent-offline` (existing) |
| Analyze failures, improve agent | `/auto-improve-agent` — already exists; agent-agnostic, can change prompts, code, or any other artifact |
| Sync dataset to Langfuse | `/publish-evals` — **new** |
| Run evaluators as Langfuse dataset run | `/publish-evals` — **new** |
| Find + import production traces | `/sample-traces` — **new**, with integrated evaluate→filter→import loop |
| Tool replay for deterministic testing | Retained in `app/evaluation/` framework — not deprecated |
| CI/CD auto-discovery pipeline | Retained in `Makefile.eval` + `watch_paths.yaml` — not deprecated |
| Evals Dashboard integration | Retained in `eval_config.yaml` pattern — not deprecated |
| Automated prompt rewriting (LangGraph optimizer) | Not carried forward — `/auto-improve-agent` is more powerful: agent-agnostic, can modify prompts, code logic, or any artifact, guided by failure analysis rather than blind iteration |

### What's NOT Deprecated

The `/optimize-agent` **skill** (the SKILL.md guide) is deprecated. Its underlying code is not deleted, but the relationship to EDD varies:

**Still actively used by EDD:**
- `app/evaluation/pipeline.py` — `EvaluationPipeline` remains the orchestration layer, used by `/publish-evals`
- `app/evaluation/eval_runner.py` — `EvaluationRunner` used by dataset sync and evaluation runs

**Superseded by EDD patterns (not deleted, but not recommended for new work):**
- `app/evaluation/prompt_optimizer_langgraph.py`, `prompt_optimizer_crewai.py`, `prompt_optimizer_producer.py` — automated prompt rewriting is superseded by `/auto-improve-agent`, which is agent-agnostic and can modify any artifact, not just prompts
- `.claude/skills/optimize-agent/resources/find_traces.py`, `create_dataset_from_traces.py` — superseded by `/sample-traces`, which adds integrated evaluate→filter→import instead of manual trace picking
- `app/evaluation/base_evaluators.py` — `RuleBasedEvaluator`, `LLMBasedEvaluator` class hierarchy still works for existing evaluators, but new evaluators should use the standalone function pattern from `/evaluate-agent-offline`

**Absorbed into EDD skills:**
- `.claude/skills/optimize-agent/resources/list_datasets.py` → absorbed into `/eval-dataset` as a `--list` flag (listing Langfuse datasets is part of dataset discovery/bootstrap)
- `.claude/skills/optimize-agent/resources/create_dataset_from_db.py`, `create_dataset_from_traces.py`, `create_dataset_from_scratch.py` → absorbed into `/eval-dataset` as dataset source modes
- Tool replay infrastructure (`InvocationContext`, `ToolReplayContext`) — cross-cutting execution concern, documented in `/evaluate-agent-offline` references, not attributed to any single skill

## Step 0: `/eval-dataset` skill (new)

Build/curate local YAML datasets before `/evaluate-agent-offline`.

**Files:**
```
.claude/skills/eval-dataset/
├── SKILL.md                              # args: <agent_name> [--list] [--source scratch|blackboard-db|langfuse-traces] [--dataset-name] [--dry-run]
└── resources/
    └── eval_dataset.py                   # executable script
```

**Script workflow:**
1. If `--list`: list existing Langfuse datasets (absorbs `list_datasets.py` from `/optimize-agent`)
2. Resolve agent evaluation dir (`app/opportunities/<name>/evaluation/` preferred, fallback to `app/evaluation/<name>/`)
3. Bootstrap dataset from selected source:
   - `scratch`: scaffold local YAML with dataset metadata and starter test cases
   - `blackboard-db`: build from DB facts via `create_dataset_from_db.py`/`ProducerDatasetBuilder`
   - `langfuse-traces`: build from traces via `create_dataset_from_traces.py`
4. Write/update local YAML dataset as source of truth in git
5. Print next command (`/evaluate-agent-offline <agent_name>`)

## Step 1: `app/evaluation/trace_sampler.py` (new)

Shared utility for fetching and evaluating production traces.

**Functions:**

| Function | Purpose |
|----------|---------|
| `fetch_traces_by_date_range(agent_name, days, limit, tags)` | Fetch traces from Langfuse using `api.trace.list()` with `from_timestamp`/`to_timestamp` |
| `evaluate_traces(traces, evaluators_module_path, threshold)` | Run the full evaluator suite (deterministic + LLM judge) against each trace's actual output |
| `trace_to_yaml_test_case(trace, eval_results, agent_name)` | Convert a failing trace to a YAML test case dict |
| `append_test_cases_to_yaml(yaml_path, new_test_cases)` | Append to existing YAML dataset, deduplicate by `source_trace_id` |

**Reuses:** `get_langfuse_client()` from `app/services/langfuse_client.py`, `load_yaml_file()` from `app/evaluation/yaml_utils.py`, trace listing pattern from `.claude/skills/optimize-agent/resources/find_traces.py`

**Design note:** Each production trace already contains `input` + `actual_output`. Evaluators run directly against the output — deterministic checks inspect structure/format, LLM judges assess quality. No `expected_output` is needed; evaluators define what "good" looks like.

## Step 2: `app/evaluation/judge_monitoring.py` (new)

Lightweight judge-audit and drift utilities used by `/sample-traces`.

**Functions:**

| Function | Purpose |
|----------|---------|
| `build_audit_sample(scored_traces, audit_size, mix)` | Pick a mixed subset of scored traces (pass + fail) for human review |
| `export_audit_queue(audit_sample, output_path)` | Export traces with evaluator verdicts for human agree/disagree review |
| `load_audit_verdicts(verdicts_path)` | Load human agree/disagree verdicts |
| `compute_judge_audit_metrics(audit_verdicts)` | Compute fail precision, pass miss rate, and score deltas from human review |
| `compute_segment_drift(current_trace_scores, baseline_trace_scores, segment_keys, min_samples)` | Detect score/pass-rate drift by segment (`locale`, `site_type`, `org_id`) |
| `recommend_import_policy(audit_metrics, drift_report, policy_config)` | Recommend `auto` vs `confirmed-only` import mode |

**Reuses:** YAML loading from `app/evaluation/yaml_utils.py`, trace evaluation output from `trace_sampler.evaluate_traces()`

## Step 3: `app/evaluation/langfuse_dataset_sync.py` (new)

Sync local YAML datasets to Langfuse and run evaluators as dataset runs.

**Functions:**

| Function | Purpose |
|----------|---------|
| `sync_yaml_to_langfuse(yaml_path, dataset_name, description)` | Create/update Langfuse dataset from local YAML. Returns `(created, updated, deleted)` |
| `run_langfuse_dataset_eval(dataset_name, agent_func, evaluator_func, run_name, commit_sha)` | Run evaluators as a Langfuse dataset run, publish scores, tag with commit SHA |

**Reuses:** `LangfuseDatasetProvider.create_dataset()`, `add_item()` from `app/evaluation/dataset_providers.py`, `sync_langfuse_dataset_items()` from `app/evaluation/langfuse_utils.py`, `EvaluationRunner.run_dataset()` from `app/evaluation/eval_runner.py`

## Step 4: `/publish-evals` skill (new)

Sync local dataset to Langfuse, run evaluators, publish scores.

**Files:**
```
.claude/skills/publish-evals/
├── SKILL.md                              # args: <agent_name> [--dry-run] [--skip-eval] [--run-name]
└── resources/
    └── publish_to_langfuse.py            # executable script
```

**Script workflow:**
1. Find agent's evaluation dir (`app/opportunities/<name>/evaluation/`)
2. Load local YAML dataset
3. Sync to Langfuse via `sync_yaml_to_langfuse()`
4. Run evaluators and publish scores via `run_langfuse_dataset_eval()`
5. Tag run with commit SHA, print Langfuse dashboard link

## Step 5: `/sample-traces` skill (new)

Sample production traces, evaluate, find failures, import to local dataset.

**Files:**
```
.claude/skills/sample-traces/
├── SKILL.md                              # args: <agent_name> [--days N] [--limit N] [--audit-size N] [--audit-out PATH] [--audit-verdicts PATH] [--import-failures] [--threshold] [--drift-report] [--import-policy auto|confirmed-only]
└── resources/
    └── sample_and_evaluate.py            # executable script
```

**Script workflow:**
1. Find agent's evaluation dir
2. Fetch traces via `fetch_traces_by_date_range()` (each trace has `input` + `actual_output`)
3. Run full evaluator suite via `evaluate_traces()` against each trace's output (deterministic + LLM judges)
4. Report pass/fail summary with failure patterns
5. If `--audit-size N`: pick mixed subset of scored traces, export for human agree/disagree review (`--audit-out`)
6. If `--audit-verdicts PATH`: load human verdicts, compute judge audit metrics
7. If `--drift-report`: compute segment drift snapshot
8. If `--import-failures`: import failing traces with selected policy:
   - `auto`: import evaluator-failing traces directly
   - `confirmed-only`: import only failures where human agreed with evaluator verdict

## Step 6: Deprecate `/optimize-agent`

Add deprecation notice to `.claude/skills/optimize-agent/SKILL.md`:
- Update frontmatter description to mention deprecation
- Add banner at top pointing to EDD workflow and new skills
- Keep existing content and resource scripts intact for reference

## Step 7: Align `/evaluate-agent-offline` and `/eval-dataset`

### 7a: Fix shared dataset template

The YAML template used for dataset scaffolding is oversimplified compared to real datasets. Real datasets like `broken_links_comprehensive.yaml` and `h1_optimization_comprehensive.yaml` include:
- `dataset:` metadata block with `name`, `version`, `description`
- `enabled`, `category`, `scenario` fields per test case
- Typed fact inputs matching the producer's `@consumes` decorators (e.g., `d_verified_broken_backlinks`, `o_sitemap`)
- Rich `expected_output` with `expected_urls`, `forbidden_urls`, `constraints`

The EDD doc ([EVAL_DRIVEN_DEVELOPMENT.md](EVAL_DRIVEN_DEVELOPMENT.md) Step 0/1) already has a corrected example. This step aligns the template to match:

| File | Change |
|------|--------|
| `.claude/skills/evaluate-agent-offline/templates/dataset.yaml` | Replace simplified template with structure matching real datasets |
| `.claude/skills/eval-dataset/resources/eval_dataset.py` | Reuse the same template when scaffolding from `--source scratch` |

### 7b: Move dataset bootstrapping guidance to `/eval-dataset`

Dataset source selection should be documented in `/eval-dataset` (not `/evaluate-agent-offline`), so the evaluate skill stays focused on evaluators and baseline runs.

For **new agents**, `--source scratch` is the default (no production data yet).  
For **mature agents**, `/eval-dataset` should expose bootstrap modes:

| Source | When to use | Backing implementation |
|--------|-------------|------------------------|
| `scratch` | New agent, no production data yet | local YAML scaffold |
| `blackboard-db` | Mature FactProducer with stored facts | `create_dataset_from_db.py` |
| `langfuse-traces` | Agent with production trace history | `create_dataset_from_traces.py` |
| `/sample-traces --import-failures` | Agent with evaluators already running in production | EDD Phase 2 feedback loop |

## Step 8: Documentation updates

| File | Change |
|------|--------|
| `docs/evals/README.md` | Add EDD section at top, update skills table, mark `/optimize-agent` deprecated |
| `CLAUDE.md` | Add EDD doc link in Evaluations section |

## Key Design Decisions

1. **Local YAML is source of truth** — Langfuse is a synced copy, not the primary store
2. **Production trace evaluation uses the same full evaluator suite** — evaluators run directly against the trace's actual output (no `expected_output` needed); deterministic checks inspect structure, LLM judges assess quality
3. **Deduplication on import** — `source_trace_id` prevents re-importing the same failing trace
4. **Producer pattern is canonical** — `app/opportunities/<name>/evaluation/` is the directory structure (not legacy `app/evaluation/<crew>/`)
5. **Judge audits are sampled, not exhaustive** — small weekly review sets track judge quality without reviewing all runs
6. **Import policy is adaptive** — use `auto` normally, switch to `confirmed-only` when audit metrics degrade
7. **Drift is advisory for targeting** — drift highlights where to increase human audit coverage
8. **Dataset discovery belongs to `/eval-dataset`** — Langfuse dataset listing (`--list`) and bootstrap source selection are dataset concerns, not publish concerns

## Known Limitations

See [EVAL_DRIVEN_DEVELOPMENT.md — Known Limitations](EVAL_DRIVEN_DEVELOPMENT.md#known-limitations) for three documented gaps:

1. **Self-labeling circularity** — imported traces are labeled by the same evaluators that flagged them; `/auto-improve-agent` may optimize to judge bias rather than ground truth. Mitigated by human audit and periodic ground-truth review.
2. **Threshold-only validation** — scores are point estimates without confidence intervals or significance tests. Small deltas on small datasets may not be meaningful.
3. **No deployment safety gates** — EDD does not prescribe canary rollout, champion-challenger, or automatic rollback. Teams should layer their own deployment safety on top.

These are deliberate scope boundaries for v1. Addressing them (statistical testing, canary integration) are candidates for future iterations.

## Files Summary

**New (10):**

| File | Purpose |
|------|---------|
| `app/evaluation/trace_sampler.py` | Fetch traces, evaluate, convert to YAML |
| `app/evaluation/judge_monitoring.py` | Judge audit metrics, drift snapshot, import-policy recommendation |
| `app/evaluation/langfuse_dataset_sync.py` | Sync YAML → Langfuse, run eval as dataset run |
| `.claude/skills/eval-dataset/SKILL.md` | Skill definition |
| `.claude/skills/eval-dataset/resources/eval_dataset.py` | Dataset bootstrap + Langfuse list script |
| `.claude/skills/publish-evals/SKILL.md` | Skill definition |
| `.claude/skills/publish-evals/resources/publish_to_langfuse.py` | Publish script |
| `.claude/skills/sample-traces/SKILL.md` | Skill definition |
| `.claude/skills/sample-traces/resources/sample_and_evaluate.py` | Sample + evaluate script |
| `docs/evals/EDD_IMPLEMENTATION_PLAN.md` | This plan |

**Modified (6):**

| File | Change |
|------|--------|
| `.claude/skills/optimize-agent/SKILL.md` | Deprecation notice |
| `.claude/skills/evaluate-agent-offline/templates/dataset.yaml` | Update template to match real dataset structure |
| `.claude/skills/evaluate-agent-offline/SKILL.md` | Clarify `/eval-dataset` handoff and evaluator focus |
| `docs/evals/README.md` | Add EDD section |
| `docs/evals/EVAL_DRIVEN_DEVELOPMENT.md` | Add `/eval-dataset` to lifecycle/skills mapping |
| `CLAUDE.md` | Add EDD doc link |

## Verification

```bash
# trace_sampler
export PYTHONPATH=$PYTHONPATH:./app
uv run python -c "from evaluation.trace_sampler import fetch_traces_by_date_range; print('OK')"

# judge_monitoring
uv run python -c "from evaluation.judge_monitoring import compute_judge_audit_metrics; print('OK')"

# eval-dataset: list Langfuse datasets
uv run python .claude/skills/eval-dataset/resources/eval_dataset.py broken_links --list

# eval-dataset: scaffold local dataset from scratch
uv run python .claude/skills/eval-dataset/resources/eval_dataset.py broken_links --source scratch --dry-run

# publish-evals (dry run)
uv run python .claude/skills/publish-evals/resources/publish_to_langfuse.py broken_links --dry-run

# sample-traces
uv run python .claude/skills/sample-traces/resources/sample_and_evaluate.py broken_links --days 7 --limit 5

# sample-traces with audit: export scored traces for human agree/disagree review
uv run python .claude/skills/sample-traces/resources/sample_and_evaluate.py broken_links --days 7 --limit 50 --audit-size 30 --audit-out /tmp/broken_links_audit.yaml

# sample-traces: load human verdicts + drift snapshot
uv run python .claude/skills/sample-traces/resources/sample_and_evaluate.py broken_links --days 7 --audit-verdicts /tmp/broken_links_verdicts.yaml --drift-report

# sample-traces import using confirmed-only mode after audit
uv run python .claude/skills/sample-traces/resources/sample_and_evaluate.py broken_links --days 7 --import-failures --import-policy confirmed-only
```
