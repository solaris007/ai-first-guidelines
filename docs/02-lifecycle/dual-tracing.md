# Dual Tracing Support: Langfuse + LangSmith

The evaluation framework now supports sending traces to both **Langfuse** and **LangSmith** simultaneously, giving you the best of both platforms:

- **Langfuse**: Better UI for reading prompts and responses (no tiny text areas!)
- **LangSmith**: Powerful Align Evaluator for creating and aligning LLM-as-a-Judge evaluators with human feedback

## Quick Start

### Langfuse Only (Default)

By default, only Langfuse tracing is enabled. No additional configuration needed:

```bash
export PYTHONPATH=$PYTHONPATH:./app
uv run python -m evaluation run-evals
```

### Langfuse + LangSmith (Dual Tracing)

To enable dual tracing, add these environment variables to your `.env` file:

```bash
# Enable LangSmith tracing
LANGSMITH_TRACING=true

# LangSmith credentials
LANGSMITH_API_KEY=ls__...
LANGSMITH_PROJECT=my-evaluation-project
```

Then run evaluations as normal:

```bash
export PYTHONPATH=$PYTHONPATH:./app
uv run python -m evaluation run-evals
```

You'll see traces in **both** platforms:
- Langfuse: Your usual Langfuse UI (better for reading prompts)
- LangSmith: https://smith.langchain.com (for Align Evaluator workflows)

## Why Dual Tracing?

### Langfuse Strengths
- ✅ Better UI for reading prompts/responses (no tiny text areas)
- ✅ Cleaner trace visualization
- ✅ Better for manual inspection of agent outputs

### LangSmith Strengths
- ✅ Align Evaluator feature for calibrating LLM-as-a-Judge
- ✅ Automatic conversion of human corrections to few-shot examples
- ✅ Iterative prompt refinement for evaluators
- ✅ Alignment score tracking (% match with human labels)

### Best of Both Worlds
Use **Langfuse for reading** and **LangSmith for evaluator alignment** as recommended in `app/docs/self-improving-ai-agents.md`.

## Configuration Reference

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `LANGSMITH_TRACING` | Yes | Set to `true` or `1` to enable LangSmith tracing |
| `LANGSMITH_API_KEY` | Yes | Your LangSmith API key (starts with `ls__`) |
| `LANGSMITH_PROJECT` | Yes | LangSmith project name for organizing traces |

### How It Works

When dual tracing is enabled:

1. The evaluation framework creates two callback handlers:
   - `Langfuse.CallbackHandler` - sends traces to Langfuse
   - `LangChainTracer` - sends traces to LangSmith

2. Both handlers are passed to the agent's `ask()` method via the `callbacks` parameter

3. LangChain automatically sends traces to both platforms in parallel

4. No performance impact - traces are sent asynchronously

## Testing Your Configuration

Run the test script to verify your configuration:

```bash
export PYTHONPATH=$PYTHONPATH:./app
uv run python /tmp/test_dual_tracing.py
```

Expected output with dual tracing enabled:
```
✅ Dual tracing enabled: 2 callback handlers created
   - Langfuse: CallbackHandler
   - LangSmith: LangChainTracer (project: my-project)
```

## Recommended Workflow (per self-improving-ai-agents.md)

1. **Step 1: Generate Dataset**
   ```bash
   uv run python -m evaluation generate-dataset
   ```

2. **Step 2: Run Baseline Evaluation**
   - Enable dual tracing in `.env`
   - Run evaluations to collect traces in both platforms
   ```bash
   uv run python -m evaluation run-evals
   ```

3. **Step 3: Build LLM-as-a-Judge in LangSmith**
   - Use LangSmith UI to select traces for human labeling
   - Create "golden set" with human annotations
   - Use Align Evaluator to calibrate judge against human labels
   - Iterate until alignment score > 85%

4. **Step 4: Review Results in Langfuse**
   - Use Langfuse UI to read full prompts/responses
   - Better visualization for understanding agent behavior
   - Export insights for documentation

5. **Step 5: Run Optimization**
   ```bash
   uv run python -m evaluation optimize-prompt <baseline-run-name>
   ```

## Troubleshooting

### Traces Only Appearing in Langfuse

Check that all three environment variables are set correctly:
```bash
echo $LANGSMITH_TRACING    # Should be 'true' or '1'
echo $LANGSMITH_API_KEY    # Should start with 'ls__'
echo $LANGSMITH_PROJECT    # Your project name
```

### LangSmith API Key Not Working

Make sure you're using a **LangSmith API key** (starts with `ls__`), not a LangChain API key.

Get your key from: https://smith.langchain.com/settings

### Want to Disable LangSmith Temporarily

Just set `LANGSMITH_TRACING=false` (or remove it from `.env`) and restart your evaluation.

## Implementation Details

### Modified Files

- `app/evaluation/eval_runner.py` - Added LangSmith tracer creation and callback management
- `app/evaluation/pipeline.py` - Updated agent wrapper to accept callback lists
- `app/evaluation/README_DUAL_TRACING.md` - This file

### Code References

**eval_runner.py:187-208** - Dual tracing initialization
```python
# Check if LangSmith tracing is enabled
langsmith_enabled = os.getenv("LANGSMITH_TRACING", "").lower() in ("true", "1")
langsmith_api_key = os.getenv("LANGSMITH_API_KEY")
langsmith_project = os.getenv("LANGSMITH_PROJECT")

# Build callbacks list - always include Langfuse
callbacks = [langfuse_handler]

# Add LangSmith callback if configured
if langsmith_enabled and langsmith_api_key and langsmith_project:
    from langchain_core.tracers import LangChainTracer
    langsmith_tracer = LangChainTracer(project_name=langsmith_project)
    callbacks.append(langsmith_tracer)
```

## References

- [Self-Improving AI Agents Design Doc](self-improving-ai-agents.md)
- [LangSmith Documentation](https://docs.langchain.com/langsmith/home)
- [Align Evaluator Guide](https://blog.langchain.com/introducing-align-evals/)
- [Langfuse Documentation](https://langfuse.com/docs)
