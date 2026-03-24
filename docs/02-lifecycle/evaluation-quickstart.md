# Quick Start: Evaluating an Agent or Crew

Get from zero to evaluation scores in under 10 minutes.

## Prerequisites

```bash
# 1. Connect to Adobe VPN (required for Langfuse)
# 2. Set environment variables
export LANGFUSE_PUBLIC_KEY="pk-lf-..."
export LANGFUSE_SECRET_KEY="sk-lf-..."
export LANGFUSE_HOST="https://cloud.langfuse.com"   # or self-hosted instance
export AZURE_OPENAI_ENDPOINT="https://your-instance.openai.azure.com/"
export AZURE_OPENAI_KEY="your-key"
export PYTHONPATH=$PYTHONPATH:./app

# 3. Install dependencies
uv sync
```

## Option A: Use `/optimize-agent` (Recommended)

The `/optimize-agent` skill in Claude Code handles everything: detects your agent type, creates the evaluation folder, writes schemas, evaluators, dataset, and runner scripts.

```
/optimize-agent
```

Follow the interactive prompts. When it's done, you'll have a complete `app/evaluation/<your_crew>/` folder ready to go.

## Option B: Manual (If Eval Folder Already Exists)

If your evaluation folder is already set up (e.g., by a teammate or the skill), run these three commands:

```bash
# 1. Upload dataset to Langfuse (first time or after YAML changes)
uv run python app/evaluation/<your_crew>/load_dataset.py

# 2. Run baseline evaluation
uv run python app/evaluation/<your_crew>/run_baseline.py

# 3. (Optional) Run prompt optimization
uv run python app/evaluation/<your_crew>/optimize_crew.py
```

## What to Expect

**`load_dataset.py`** validates your YAML test cases and uploads them to Langfuse.

**`run_baseline.py`** runs each test case through the agent, scores with evaluators, and prints a summary:

```
# Evaluation Report: your_crew_baseline_20260212_143000

**Dataset**: your_crew_eval_dataset_v1.0.0
**Status**: 10/10 items completed successfully

## Summary Scores

| Dimension       | Average Score | Status         |
|-----------------|--------------|----------------|
| Output Format   | 0.95         | Excellent      |
| Content Quality | 0.72         | Good           |

**Overall Average**: 0.84
```

**`optimize_crew.py`** iteratively improves prompts based on low-scoring items, then re-evaluates. An `OPTIMIZATION_LOG.md` is generated automatically.

## Review Results

All scores and traces are stored in Langfuse. Navigate to **Datasets** in the Langfuse UI to:

- Compare runs side-by-side
- Drill into individual items to see agent output, scores, and evaluator reasoning
- Track improvement over time

## Next Steps

- [EVALUATION_GUIDE.md](EVALUATION_GUIDE.md) - Deep dive into how each file works and how to customize
- [PROMPT_OPTIMIZATION.md](PROMPT_OPTIMIZATION.md) - Details on the LangGraph optimization loop
- [TOOL_REPLAY.md](TOOL_REPLAY.md) - Deterministic testing with recorded tool responses
- Working examples: [Alt-Text Crew](../../app/evaluation/alt_text_crew/), [Metatags Crew](../../app/evaluation/metatags_crew/)