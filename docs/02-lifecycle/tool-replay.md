# Tool Replay for Deterministic Evaluation

## Overview

Tool Replay is a feature that enables deterministic evaluation of AI agents and crews by replaying pre-recorded tool responses from Langfuse traces instead of executing real tools. This solves the critical problem of non-deterministic tool results affecting prompt optimization and evaluation.

## Problem Statement

When evaluating and optimizing prompts for AI agents, tool results can vary between runs due to:
- **External API changes**: APIs return different data over time
- **Time-sensitive data**: Weather, stock prices, traffic data changes
- **Rate limits**: API quotas can block repeated testing
- **Network issues**: Failures make results unreproducible
- **Cost**: Repeated API calls during optimization iterations

This variability makes it impossible to fairly compare different prompt versions since both the prompts AND the tool results are changing.

## Solution

**Tool Replay** captures tool calls and responses from Langfuse traces and replays them during evaluation, ensuring:
- ✅ **Deterministic Results**: Same inputs = same outputs every time
- ✅ **Fair Comparison**: Only prompts change, tool responses stay constant
- ✅ **Faster Testing**: No need to call external APIs
- ✅ **Cost Effective**: Avoid repeated API calls
- ✅ **Offline Testing**: Evaluate without network dependencies

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Production Run (Recording)                                │
│                                                               │
│   User Query → Agent → Tool Calls → External APIs            │
│                         ↓                                     │
│                    Langfuse Records:                          │
│                    - Tool name                                │
│                    - Input params                             │
│                    - Output response                          │
│                    - Timestamp                                │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Dataset Creation                                           │
│                                                               │
│   Extract tool calls from Langfuse traces                    │
│   Store in dataset metadata                                  │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Evaluation Run (Replay)                                    │
│                                                               │
│   User Query → Agent → Tool Check Context                    │
│                         ↓                                     │
│                    if tool_replay.enabled:                    │
│                        return recorded_response               │
│                    else:                                      │
│                        execute_real_tool()                    │
└─────────────────────────────────────────────────────────────┘
```

## Implementation

### 1. Core Components

**ToolReplayContext** (`app/agents/crews/context.py`):
- Stores recorded tool calls
- Matches tool calls by name + input
- Configurable strict/lenient mode

**MystiqueCrewAIBaseTool** (`app/agents/crews/context.py`):
- Automatically checks for mock responses
- Falls back to real tool if no mock found
- All tools inherit this behavior

**Langfuse Tool Extractor** (`app/evaluation/langfuse_tool_extractor.py`):
- Extracts tool observations from traces
- Formats data for ToolReplayContext

### 2. File Structure

```
app/
├── agents/crews/context.py
│   ├── ToolReplayContext (NEW)
│   ├── InvocationContext (UPDATED: +tool_replay field)
│   └── MystiqueCrewAIBaseTool (UPDATED: +replay logic)
│
├── agents/tools/example_tools.py (UPDATED: use _run_impl)
│
└── evaluation/
    ├── langfuse_tool_extractor.py (NEW)
    │   ├── extract_tool_calls_from_trace()
    │   ├── extract_tool_calls_from_observations()
    │   └── extract_tool_calls_batch()
    │
    └── examples/
        ├── demo_tool_replay.py (example with Langfuse)
        └── demo_tool_replay_simple.py (standalone demo)
```

## Usage

### Quick Start

```python
from evaluation.langfuse_tool_extractor import extract_tool_calls_from_trace
from agents.crews.invocation_context import InvocationContext, ToolReplayContext

# Step 1: Extract tool calls from a Langfuse trace
tool_calls = extract_tool_calls_from_trace("trace-123")

# Step 2: Create context with tool replay enabled
context = InvocationContext(
    tool_replay=ToolReplayContext(
        enabled=True,
        tool_calls=tool_calls,
        strict_mode=False  # Warn but don't fail if mock missing
    )
)

# Step 3: Run your crew with the context
result = await crew.execute(query, context=context)

# All tools will automatically use mocked responses!
```

### Dataset Creation with Tool Replay

```python
from langfuse import Langfuse
from evaluation.langfuse_tool_extractor import extract_tool_calls_from_trace

langfuse_client = Langfuse()

# Create dataset from traces with tool calls
dataset_items = []

for trace_id in production_trace_ids:
    # Fetch trace
    trace = langfuse_client.api.trace.get(trace_id)

    # Extract tool calls
    tool_calls = extract_tool_calls_from_trace(trace_id)

    # Create dataset item
    dataset_items.append({
        "input": trace.input,
        "expected_output": trace.output,
        "metadata": {
            "trace_id": trace_id,
            "tool_calls": tool_calls  # KEY: Include tool data
        }
    })

# Save dataset
dataset = langfuse_client.create_dataset(name="my_eval_dataset")
for item in dataset_items:
    dataset.create_item(
        input=item["input"],
        expected_output=item["expected_output"],
        metadata=item["metadata"]
    )
```

### Using Tool Replay in Optimization

```python
from evaluation.prompt_optimizer_crewai import optimize_crew
from evaluation.langfuse_tool_extractor import extract_tool_calls_from_trace

async def optimize_with_tool_replay():
    """Optimize crew prompts with deterministic tool responses."""

    # Load dataset
    dataset = langfuse_client.get_dataset("my_eval_dataset")

    # For each evaluation iteration
    for item in dataset.items:
        # Extract tool calls from metadata
        tool_calls = item.metadata.get("tool_calls", [])

        # Create context with replay
        context = InvocationContext(
            tool_replay=ToolReplayContext(
                enabled=True,
                tool_calls=tool_calls
            )
        )

        # Run crew with mocked tools
        crew = create_crew(context=context)
        result = await crew.kickoff(item.input)

        # Score result
        score = evaluate(result, item.expected_output)

    # All runs use same tool responses → fair comparison!
```

## Configuration Options

### ToolReplayContext Parameters

- **`enabled`** (bool): Enable/disable tool replay
  - `True`: Use mocked responses
  - `False`: Execute real tools

- **`tool_calls`** (list[dict]): Recorded tool data
  ```python
  [{
      "tool_name": "WeatherTool",
      "input": {"city": "San Francisco"},
      "output": {"temp": 68, "conditions": "Sunny"},
      "observation_id": "obs-123",
      "start_time": "2025-11-18T10:00:00Z"
  }]
  ```

- **`strict_mode`** (bool): Behavior when mock not found
  - `True`: Raise error (strict testing)
  - `False`: Warn and use real tool (lenient, default)

- **`call_counts`** (dict): Internal counter (auto-managed)

### Tool Matching Strategy

Tools are matched by:
1. **Tool name** (exact match)
2. **Call order** (sequential index for same tool)
3. **Input parameters** (exact match for validation)

Example:
```python
# First call to WeatherTool → uses recording #0
# Second call to WeatherTool → uses recording #1
# Third call (no recording) → warning + real tool (if strict_mode=False)
```

## Creating New Tools

All tools must inherit from `MystiqueCrewAIBaseTool` and implement `_run_impl()` instead of `_run()`:

```python
from agents.crews.context import MystiqueCrewAIBaseTool

class MyCustomTool(MystiqueCrewAIBaseTool):
    name: str = "My Custom Tool"
    description: str = "Does something useful"

    def _run_impl(self, param1: str, param2: int) -> str:
        """
        Implement your tool logic here.
        Tool replay is automatically handled by the base class.
        """
        # Your tool implementation
        result = call_external_api(param1, param2)
        return result
```

**Important**: Use `_run_impl()` not `_run()`. The base class's `_run()` method handles replay logic automatically.

## Examples

### Running the Demo

```bash
# Simple standalone demo (no dependencies)
export PYTHONPATH=$PYTHONPATH:./app
uv run python app/evaluation/examples/demo_tool_replay_simple.py

# Demo with actual Langfuse trace (requires trace_id)
uv run python app/evaluation/examples/demo_tool_replay.py <trace_id>
```

### Example Output

```
================================================================================
Tool Replay Demo - Simple Standalone Version
================================================================================

1. Simulating tool calls recorded from a previous run...
  Recording 1: WeatherTool - {'city': 'San Francisco'}
  Recording 2: StockPriceTool - {'symbol': 'ADBE'}
  Recording 3: WeatherTool - {'city': 'New York'}

2. Creating ToolReplayContext with recorded calls...
✓ Tool replay enabled with 3 recordings

3. Simulating tool calls during evaluation...

  Calling WeatherTool(city='San Francisco')...
✓ Using mock response for WeatherTool call #0
    Response: {'temp': 68, 'conditions': 'Sunny'}

  Calling StockPriceTool(symbol='ADBE')...
✓ Using mock response for StockPriceTool call #0
    Response: {'price': 550.25, 'change': '+2.5%'}

  Calling WeatherTool(city='New York')...
✓ Using mock response for WeatherTool call #1
    Response: {'temp': 45, 'conditions': 'Cloudy'}

  Calling TranslationTool(text='hello') - NO RECORDING...
⚠️ No mock for TranslationTool call #0, would use real tool
    No mock found - would execute real tool
```

## Benefits

| Aspect | Without Tool Replay | With Tool Replay |
|--------|-------------------|------------------|
| **Determinism** | ❌ Results vary between runs | ✅ Identical results every time |
| **Speed** | ❌ Slow (API calls) | ✅ Fast (instant responses) |
| **Cost** | ❌ High (repeated API calls) | ✅ Low (one-time recording) |
| **Offline Testing** | ❌ Requires network/APIs | ✅ Works offline |
| **Fair Comparison** | ❌ Prompts + tools change | ✅ Only prompts change |
| **Reproducibility** | ❌ Cannot replay exact scenario | ✅ Perfect reproducibility |

## Best Practices

1. **Record from Production**: Use real production traces for realistic data
2. **Regular Updates**: Refresh recordings periodically to match current API behavior
3. **Version Datasets**: Track which recordings are used for which evaluation runs
4. **Document Changes**: Note when API responses change significantly
5. **Test Both Modes**: Validate with real tools occasionally to catch API changes
6. **Use Lenient Mode**: Start with `strict_mode=False` during development

## Troubleshooting

### Input Mismatch Warning

```
Tool replay: Input mismatch for WeatherTool call #0.
Expected: {'city': 'SF'}, Got: {'city': 'San Francisco'}
```

**Cause**: Agent is calling tool with different parameters than recorded.

**Solutions**:
- Update prompts to match original format
- Re-record traces with new format
- Check if prompt optimization changed tool usage

### No Mock Found Warning

```
Tool replay: No mock for TranslationTool call #0, using real tool
```

**Cause**: Tool wasn't called in original trace, or recording is incomplete.

**Solutions**:
- Verify trace has tool observations
- Check if tool is newly added
- Set `strict_mode=True` to catch missing mocks during testing

### Circular Import Error

If you see circular import errors when importing context, it's a known issue with the existing codebase structure. The tool replay logic itself doesn't introduce new circular dependencies - it uses the existing context module structure.

## Next Steps

1. **Create Datasets**: Extract tool calls from production Langfuse traces
2. **Update Tools**: Ensure all tools use `_run_impl()` pattern
3. **Run Optimization**: Use tool replay in prompt optimization loops
4. **Monitor**: Track when recordings need updates

## Related Documentation

- [PROMPT_OPTIMIZATION.md](PROMPT_OPTIMIZATION.md) - Overall optimization system
- [unified_optimization_flow.md](unified_optimization_flow.md) - System architecture diagrams
- [QUICKSTART.md](QUICKSTART.md) - Getting started guide
