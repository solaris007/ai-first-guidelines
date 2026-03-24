# Prompt Optimization System

Automated, LangGraph-based system for iteratively improving Business Agent system prompts through offline optimization.

## Overview

This system implements the **Generator-Critic Loop** pattern from the self-improving AI agents framework, using three distinct engines:

1. **Execution Engine**: Runs the agent with current prompt against evaluation dataset
2. **Evaluation Engine**: LLM-as-a-Judge scores responses on correctness, completeness, and business context
3. **Optimization Engine**: Meta-prompting to analyze failures and propose targeted prompt improvements

## Dataset Creation Pipeline

The optimization system requires high-quality evaluation datasets that combine multiple sources of real-world data. This ensures the agent is optimized for actual production scenarios, not just synthetic test cases.

### Data Sources

#### 1. Production Traces (Langfuse)
**Source**: Real user interactions with AI agents in production

Production traces capture:
- **User inputs**: Actual queries from customers
- **Agent outputs**: Real responses from deployed agents
- **Execution metadata**: Timestamps, latency, model used, costs
- **Conversation context**: Full chat history and session data

These traces are automatically collected in Langfuse during production usage, providing authentic examples of how users interact with the system.

#### 2. Customer Feedback
**Source**: Direct user feedback on AI agent responses

Customer feedback includes:
- **Thumbs up/down**: Binary quality signals
- **Comments**: Free-text feedback explaining issues
- **Bug reports**: Specific problems encountered
- **Feature requests**: Desired improvements

Feedback is attached to traces in Langfuse, allowing you to identify which specific interactions failed and why.

#### 3. Human Annotations
**Source**: Expert reviewers and QA team

Human annotations enrich traces with:
- **Quality scores**: Expert ratings (1-5 or 0-100)
- **Expected outputs**: What the correct answer should be
- **Error categorization**: Type of failure (hallucination, incomplete, incorrect)
- **Severity levels**: Critical, high, medium, low

Annotations provide ground truth for evaluation and help train better LLM-as-a-Judge models.

#### 4. PM Requirements
**Source**: Product Management specifications

PM requirements define:
- **New features**: Capabilities to be added
- **Edge cases**: Scenarios that must be handled
- **Quality standards**: Minimum acceptable performance
- **Success criteria**: What "good" looks like

These ensure the agent meets business objectives and handles all required scenarios.

### Dataset Builder Process

The Dataset Builder combines all sources into structured test cases:

**Step 1: Collect Production Traces**
- Query Langfuse for recent traces
- Filter by agent/crew type
- Apply date range (e.g., last 30 days)

**Step 2: Enrich with Feedback & Annotations**
- Join traces with customer feedback
- Add human annotations from review queue
- Calculate aggregate quality scores

**Step 3: Synthesize from PM Requirements**
- Generate synthetic test cases for new features
- Create edge case scenarios
- Ensure coverage of all requirement dimensions

**Step 4: Create Dataset Items**
```python
from langfuse import Langfuse

client = Langfuse()
dataset = client.create_dataset(name="agent_name_dataset_v2")

for item in dataset_items:
    client.create_dataset_item(
        dataset_name="agent_name_dataset_v2",
        input=item["input"],
        expected_output=item["expected_output"],
        metadata={
            "source": "production_trace",
            "trace_id": trace.id,
            "feedback_score": feedback.score,
            "quality_score": annotation.quality_score,
            "requirement_id": pm_requirement.id
        }
    )
```

### Dataset Evolution

Datasets evolve continuously as the system learns:

```
Week 1: Initial dataset
├── 10 items from PM requirements
└── 5 items from manual testing

Week 2: Production integration
├── Previous 15 items
├── 20 items from production traces
└── 10 items with customer feedback

Week 3: Quality refinement
├── Previous 45 items
├── 15 items with human annotations
└── 5 new edge cases discovered

Week 4: Ongoing optimization
├── Previous 65 items
├── Remove outdated items (features changed)
├── Add 10 new items from latest PM specs
└── Update expected outputs based on new standards
```

This continuous evolution ensures the evaluation dataset stays current with:
- Real user behavior patterns
- Latest product requirements
- Emerging edge cases
- Quality standard improvements

See [unified_optimization_flow.md](unified_optimization_flow.md) for a visual diagram of the complete data flow.

## Tool Replay for Deterministic Evaluation

### Problem: Non-Deterministic Tool Results

When evaluating and optimizing prompts, **tool results can vary between runs**, making it impossible to fairly compare different prompt versions:

- **External API changes**: APIs return different data over time
- **Time-sensitive data**: Weather, stock prices, traffic data changes
- **Rate limits**: API quotas can block repeated testing
- **Network issues**: Failures make results unreproducible
- **Cost**: Repeated API calls during optimization iterations

This variability means you're comparing prompts with **different tool responses**, making it impossible to isolate the impact of prompt changes alone.

### Solution: Tool Replay

**Tool Replay** captures tool calls and responses from Langfuse traces and replays them during evaluation:

✅ **Deterministic Results**: Same inputs = same outputs every time
✅ **Fair Comparison**: Only prompts change, tool responses stay constant
✅ **Faster Testing**: No need to call external APIs
✅ **Cost Effective**: Avoid repeated API calls
✅ **Offline Testing**: Evaluate without network dependencies

### How It Works

1. **Record** (Production): Langfuse automatically captures tool calls with input/output during production runs
2. **Extract** (Dataset Creation): Extract tool calls from Langfuse traces and store in dataset metadata
3. **Replay** (Evaluation): Enable tool replay in InvocationContext - tools return recorded responses instead of calling real APIs

### Quick Start

```python
from evaluation.langfuse_tool_extractor import extract_tool_calls_from_trace
from agents.crews.invocation_context import InvocationContext, ToolReplayContext

# Step 1: Extract tool calls from a production trace
tool_calls = extract_tool_calls_from_trace("trace-123")

# Step 2: Create context with tool replay enabled
context = InvocationContext(
    tool_replay=ToolReplayContext(
        enabled=True,
        tool_calls=tool_calls,
        strict_mode=False  # Warn but don't fail if mock missing
    )
)

# Step 3: Run your crew/agent with the context
result = await crew.execute(query, context=context)

# All tools automatically use mocked responses!
```

### Integration with Dataset Creation

When creating datasets for optimization, include tool recordings in metadata:

```python
from langfuse import Langfuse
from evaluation.langfuse_tool_extractor import extract_tool_calls_from_trace

langfuse_client = Langfuse()
dataset = langfuse_client.create_dataset(name="my_eval_dataset")

for trace_id in production_trace_ids:
    # Fetch trace
    trace = langfuse_client.api.trace.get(trace_id)

    # Extract tool calls
    tool_calls = extract_tool_calls_from_trace(trace_id)

    # Create dataset item with tool recordings
    dataset.create_item(
        input=trace.input,
        expected_output=trace.output,
        metadata={
            "trace_id": trace_id,
            "tool_calls": tool_calls  # Include tool recordings
        }
    )
```

### Using Tool Replay in Optimization

During prompt optimization, enable tool replay to ensure fair comparison:

```python
from agents.crews.example.example_crew import ExampleCrew
from evaluation.langfuse_tool_extractor import extract_tool_calls_from_trace

async def evaluate_with_tool_replay():
    # Load dataset with tool recordings
    dataset = langfuse_client.get_dataset("example_crew_dataset")

    # For each evaluation item
    for item in dataset.items:
        # Extract tool calls from metadata
        tool_calls = item.metadata.get("tool_calls", [])

        # Create context with replay enabled
        context = InvocationContext(
            auth=AuthContext(site_id="test-site"),
            tracing=TracingContext(trace_id=f"eval-{item.id}"),
            tool_replay=ToolReplayContext(
                enabled=True,
                tool_calls=tool_calls
            )
        )

        # Run ExampleCrew with tool replay - ExampleCrewAITool uses mocked responses!
        crew = ExampleCrew(context=context, number=5)
        result = crew.crew().kickoff()

        # Score result - tool responses are consistent across all evaluation runs!
        score = evaluate(result, item.expected_output)
```

### Benefits for Optimization

| Aspect | Without Tool Replay | With Tool Replay |
|--------|-------------------|---------------------|
| **Determinism** | ❌ Results vary between runs | ✅ Identical results every time |
| **Speed** | ❌ Slow (API calls) | ✅ Fast (instant responses) |
| **Cost** | ❌ High (repeated API calls) | ✅ Low (one-time recording) |
| **Fair Comparison** | ❌ Prompts + tools change | ✅ Only prompts change |
| **Reproducibility** | ❌ Cannot replay exact scenario | ✅ Perfect reproducibility |

### Configuration Options

**ToolReplayContext Parameters:**

- **`enabled`** (bool): Enable/disable tool replay
- **`tool_calls`** (list[dict]): Recorded tool data from Langfuse
- **`strict_mode`** (bool):
  - `True`: Raise error if mock not found (strict testing)
  - `False`: Warn and use real tool (lenient, default)

**Tool Matching Strategy:**

Tools are matched by:
1. **Tool name** (exact match)
2. **Call order** (sequential index for same tool)
3. **Input parameters** (validation only)

Example:
```python
# First call to WeatherTool → uses recording #0
# Second call to WeatherTool → uses recording #1
# Third call (no recording) → warning + real tool (if strict_mode=False)
```

### Best Practices

1. **Record from Production**: Use real production traces for realistic data
2. **Regular Updates**: Refresh recordings periodically to match current API behavior
3. **Version Datasets**: Track which recordings are used for which evaluation runs
4. **Test Both Modes**: Validate with real tools occasionally to catch API changes
5. **Use Lenient Mode**: Start with `strict_mode=False` during development

### Complete Documentation

For complete details on tool replay including:
- Architecture diagrams
- Tool implementation guide (using `_run_impl()` pattern)
- Troubleshooting guide
- Example scripts

See: [TOOL_REPLAY.md](TOOL_REPLAY.md)

## Architecture

### LangGraph State Machine

```
START
  ↓
analyze_failures → propose_update → execute_and_evaluate → decide_next_step
                                                                ↓
                                                           [continue?]
                                                              ↙  ↘
                                                    analyze_failures  END
```

### State (OptimizationState)

The stateful workflow tracks:
- **Current prompt** being tested
- **Evaluation results** (scores by dimension, failure patterns)
- **Best prompt** and scores across all iterations
- **Improvement history** (all attempts with deltas and rationales)
- **Control flow** (iteration count, convergence flags)

### Nodes

1. **analyze_failures**:
   - Fetches low-scoring responses from Langfuse
   - Uses LLM to cluster failures into 3-5 common themes
   - Identifies which dimensions are affected (correctness/completeness/business_context)

2. **propose_update**:
   - Meta-prompting: LLM acts as expert prompt engineer
   - Analyzes current prompt, failure patterns, and previous attempts
   - Proposes surgical, targeted improvements
   - Returns complete modified prompt with rationale

3. **execute_and_evaluate**:
   - Applies proposed prompt to agent file
   - Runs full evaluation pipeline against dataset
   - Collects scores across all dimensions
   - Returns average scores and run metadata

4. **decide_next_step**:
   - Compares current scores to best scores
   - Updates best_* if improved, reverts if not
   - Checks stopping conditions (max iterations, convergence, no failures)
   - Routes to next iteration or END

### Stopping Conditions

The loop stops when ANY of these conditions is met:

1. **Max iterations reached** (default: 10)
2. **No failure patterns found** (all responses score above threshold)
3. **Convergence** (improvement < threshold, e.g., < 0.02)

## Usage

### Prerequisites

1. **Langfuse credentials** configured:
   ```bash
   export LANGFUSE_PUBLIC_KEY="..."
   export LANGFUSE_SECRET_KEY="..."
   export LANGFUSE_HOST="https://cloud.langfuse.com"
   ```

2. **Azure OpenAI credentials** for LLM-as-judge and meta-prompting:
   ```bash
   export AZURE_OPENAI_ENDPOINT="..."
   export AZURE_OPENAI_KEY="..."
   export AZURE_COMPLETION_DEPLOYMENT="gpt-4.1"
   export AZURE_OPENAI_API_VERSION="2025-01-01-preview"
   ```

3. **Baseline evaluation run** already completed:
   ```bash
   export PYTHONPATH=$PYTHONPATH:./app
   uv run python -m evaluation run-evals
   ```
   This creates an initial run (e.g., `sites-opp-eval-20250131_120000`) to optimize from.

### Running Optimization

```bash
export PYTHONPATH=$PYTHONPATH:./app
uv run python -m evaluation optimize-prompt <initial_run_name> [options]
```

**Arguments:**
- `initial_run_name` (required): Name of the baseline evaluation run to start from

**Options:**
- `--max-iterations N`: Maximum optimization iterations (default: 10)
- `--min-score-threshold F`: Responses below this are considered failures (default: 0.7)
- `--convergence-threshold F`: Stop if improvement < this (default: 0.02)

**Example:**
```bash
# Run optimization starting from baseline evaluation
uv run python -m evaluation optimize-prompt sites-opp-eval-20250131_120000

# With custom parameters
uv run python -m evaluation optimize-prompt sites-opp-eval-20250131_120000 \
  --max-iterations 15 \
  --min-score-threshold 0.75 \
  --convergence-threshold 0.01
```

### Complete Workflow

```bash
# Step 1: Generate evaluation dataset (one-time)
export PYTHONPATH=$PYTHONPATH:./app
uv run python -m evaluation generate-dataset

# Step 2: Run baseline evaluation to establish starting point
uv run python -m evaluation run-evals
# Note the run name from output, e.g., "sites-opp-eval-20250131_120000"

# Step 3: Run iterative optimization
uv run python -m evaluation optimize-prompt sites-opp-eval-20250131_120000

# Step 4: Verify improvements
uv run python -m evaluation run-evals
# Compare new scores to baseline
```

## How It Works

### Iteration Cycle

Each iteration performs these steps:

1. **Analyze Failures** (analyze_failures node):
   - Query Langfuse for responses scoring < threshold (default: 0.7)
   - Extract query, response, and scores for each low-quality item
   - Use GPT-4 to identify 3-5 common failure patterns
   - Example patterns: "Fails to provide specific recommendations", "Lacks business impact context"

2. **Propose Improvement** (propose_update node):
   - Feed current prompt + failure patterns to GPT-4 (temperature 0.7 for creativity)
   - LLM acts as expert prompt engineer
   - Returns: themes addressed, proposed changes, full modified prompt, rationale
   - Previous failed attempts are included to avoid repeating mistakes

3. **Execute & Evaluate** (execute_and_evaluate node):
   - Apply modified prompt to agent file (sites_opportunities_agent.py)
   - Run full evaluation pipeline (same as `run-evals` command)
   - Collect scores from Langfuse for correctness, completeness, business_context
   - Calculate overall average

4. **Decide Next Step** (decide_next_step node):
   - Compare: current_overall_avg vs. best_overall_avg
   - **If improved**: Update best_*, increment iteration, continue
   - **If not improved**: Revert to best_prompt, try different approach next iteration
   - **If stopping condition met**: END

### Meta-Prompting Strategy

The `propose_update` node uses a sophisticated meta-prompt that instructs GPT-4 to:

- Act as an expert prompt engineer
- Make **surgical, targeted changes** (not wholesale rewrites)
- **Preserve what's working** (current score shown for context)
- Address specific failure patterns by dimension
- Avoid repeating previous failed attempts
- Provide detailed rationale for changes

This ensures improvements are:
- **Measurable**: Changes are testable via evaluation scores
- **Incremental**: Small, focused modifications reduce risk
- **Informed**: Based on actual failure data, not guesses

### Failure Analysis

The `analyze_failures` node uses an LLM to cluster low-quality responses:

**Input to LLM:**
- Up to 20 low-scoring responses
- Each with: query, response excerpt, scores by dimension

**LLM Output (JSON):**
```json
[
  {
    "theme": "Fails to provide specific, actionable recommendations",
    "example_indices": [1, 4, 7, 12],
    "explanation": "Responses are too generic, lack concrete next steps",
    "affected_dimension": "completeness"
  },
  {
    "theme": "Missing business impact analysis",
    "example_indices": [2, 5, 8],
    "explanation": "No mention of ROI, traffic, or conversions",
    "affected_dimension": "business_context"
  }
]
```

This structured analysis enables targeted prompt improvements.

## Configuration

### Agent-Specific Integration

To add optimization for a new agent, create an evaluation folder with the agent-specific scripts:

1. **Create evaluation folder**: `app/evaluation/<agent_name>/`

2. **Create `agent_factory.py`** with factory function:
   ```python
   """Factory function for MyAgent evaluation."""
   from typing import Any
   from agents.my_agent import MyAgent
   from evaluation.prompt_optimizer_langgraph import optimize_agent

   def create_my_agent_func():
       """Factory function to create agent_func for MyAgent"""
       async def agent_func(query: str | None = None, site_id: str | None = None,
                           website_url: str | None = None, langfuse_handler=None, **kwargs) -> str:
           agent = MyAgent(context=None)
           if langfuse_handler:
               return await agent.ask(query, callbacks=[langfuse_handler])
           else:
               return await agent.ask(query)
       return agent_func

   async def optimize_my_agent(
       initial_run_name: str,
       dataset_name: str = "my_agent_dataset",
       **kwargs
   ) -> dict[str, Any]:
       agent_file_path = "app/agents/my_agent.py"
       return await optimize_agent(
           agent_file_path=agent_file_path,
           agent_func_factory=create_my_agent_func,
           dataset_name=dataset_name,
           **kwargs
       )
   ```

3. **Create supporting scripts**:
   - `create_dataset.py` - Dataset creation
   - `run_baseline.py` - Baseline evaluation
   - `optimize_agent.py` - Optimization runner

**Note:** Agent-specific code stays in `app/evaluation/<agent_name>/`, NOT in the shared `prompt_optimizer_langgraph.py`.

### Tuning Parameters

**min_score_threshold** (default: 0.7)
- Responses scoring below this on ANY dimension are considered failures
- Lower = only analyze worst responses
- Higher = more responses analyzed, more patterns found
- Recommended: 0.6-0.8

**convergence_threshold** (default: 0.02)
- Stops when improvement is less than this
- Lower = more iterations before convergence
- Higher = stops earlier, may miss smaller improvements
- Recommended: 0.01-0.03 (1-3% improvement)

**max_iterations** (default: 10)
- Hard limit on optimization cycles
- Each iteration runs full evaluation (~2-5 minutes)
- Recommended: 10-20 for thorough optimization

## Monitoring & Debugging

### Langfuse UI

All evaluation runs and scores are tracked in Langfuse:

1. **Navigate to Datasets** → `sites-opportunities-agent-dataset`
2. **View Runs**: Each iteration creates a new run (`prompt_optimization_iter_1`, `_iter_2`, etc.)
3. **Inspect Traces**: Click into individual responses to see:
   - Agent output
   - LLM-as-judge scores and reasoning
   - Failure patterns

### Logs

The system logs extensively at INFO level:

```
2025-10-31 18:00:00 - evaluation - INFO - ============================================================
2025-10-31 18:00:00 - evaluation - INFO - ANALYZE FAILURES NODE - Iteration 1
2025-10-31 18:00:00 - evaluation - INFO - ============================================================
2025-10-31 18:00:05 - evaluation - INFO - Found 8 low-quality responses
2025-10-31 18:00:10 - evaluation - INFO - Identified 3 failure patterns:
2025-10-31 18:00:10 - evaluation - INFO -   - Fails to provide specific recommendations
2025-10-31 18:00:10 - evaluation - INFO -   - Missing business impact context
2025-10-31 18:00:10 - evaluation - INFO -   - Generic responses without prioritization
```

### Improvement History

The final output includes detailed history:

```python
{
  "baseline_avg": 0.723,
  "final_avg": 0.812,
  "total_improvement": +0.089,
  "best_iteration": 4,
  "num_iterations": 7,
  "improvement_history": [
    {
      "iteration": 1,
      "themes_addressed": ["specific recommendations", "business context"],
      "proposed_changes": "Added explicit instruction to include ROI and concrete steps",
      "scores": {"correctness": 0.75, "completeness": 0.73, "business_context": 0.69},
      "overall_avg": 0.723,
      "score_delta": 0.0,
      "improved": False,
      "rationale": "..."
    },
    {
      "iteration": 2,
      "themes_addressed": ["prioritization", "specificity"],
      "proposed_changes": "Enhanced guidelines for ranking by business value",
      "scores": {"correctness": 0.78, "completeness": 0.79, "business_context": 0.75},
      "overall_avg": 0.773,
      "score_delta": +0.050,
      "improved": True,
      "rationale": "..."
    },
    ...
  ]
}
```

## Best Practices

### 1. Start with Good Baseline

- Run multiple baseline evaluations to ensure consistency
- Verify dataset quality (diverse, representative queries)
- Check that scores are reasonable (not all 1.0 or all 0.0)

### 2. Monitor Early Iterations

- Watch first 2-3 iterations closely
- If no improvement after 3 iterations, check:
  - Are failure patterns being identified correctly?
  - Is the meta-prompt producing valid JSON?
  - Are proposed changes actually being applied?

### 3. Avoid Overfitting

- Don't run too many iterations (>20)
- Check if improvements generalize to new queries
- Periodically regenerate dataset with new variations

### 4. Manual Review

- After optimization, **manually review** the modified prompt
- Ensure changes make sense semantically
- Check for unintended side effects (e.g., prompt became too long)

### 5. Validate Improvements

- Run fresh evaluation after optimization completes
- Compare to baseline on **new** dataset items
- Test with real user queries

## Troubleshooting

### "No failure patterns found" immediately

**Cause**: All responses scoring > min_score_threshold

**Solutions**:
- Lower `--min-score-threshold` (e.g., to 0.65)
- Or: Your agent is already high-quality, optimization may not help

### Scores oscillating, not converging

**Cause**: Meta-prompt making too aggressive changes

**Solutions**:
- Review `propose_update` meta-prompt, emphasize "surgical changes"
- Lower temperature for meta-prompting LLM (currently 0.7)
- Reduce max_iterations to stop earlier

### Improvements revert in next iteration

**Cause**: LLM proposing changes that don't address root issues

**Solutions**:
- Check failure pattern quality in logs
- Increase min_score_threshold to focus on worst failures
- Add more context to meta-prompt about previous failures

### Evaluation runs fail

**Cause**: Agent code errors, Langfuse connection issues

**Solutions**:
- Check agent file syntax after prompt modification
- Verify Langfuse credentials
- Ensure dataset exists and has baseline run

## Theoretical Foundation

This system implements principles from:

- **RLAIF** (Reinforcement Learning from AI Feedback): Uses LLM-as-judge for automated feedback
- **Generator-Critic Loop**: Iterative refinement with evaluation-driven improvement
- **Meta-Prompting**: LLM acts as prompt engineer to optimize prompts
- **Offline Optimization**: Batch evaluation, not real-time adaptation

See [self-improving-ai-agents.md](self-improving-ai-agents.md) for detailed architectural background.

## Limitations

1. **Evaluation Quality**: Optimization is only as good as LLM-as-judge reliability
2. **Compute Cost**: Each iteration runs full dataset evaluation (~2-5 min)
3. **Local Optima**: May converge to local maximum, not global best
4. **Overfitting Risk**: Optimizing for specific dataset may reduce generalization
5. **Manual Review Required**: Automated improvements should be validated by humans

## Future Enhancements

- [ ] Support for multi-agent optimization (parallel workflows)
- [ ] Integration with langmem for memory-based prompt optimization
- [ ] A/B testing framework for comparing prompt versions
- [ ] Automated rollback if production metrics degrade
- [ ] Real-time optimization (online learning)
- [ ] Support for DSPy Teleprompters as alternative optimization engine

---

# CrewAI Crew Optimization

Extension of the prompt optimization system for CrewAI workflows, optimizing both agent and task prompts together as a cohesive system.

## Overview

CrewAI crews consist of:
- **Agents** (in `config/agents.yaml`): Defined by `goal` and `backstory`
- **Tasks** (in `config/tasks.yaml`): Defined by `description` and `expected_output`

Unlike single-agent LangGraph implementations, CrewAI workflows require **holistic optimization** because agents and tasks are interdependent.

## Architecture

### What Gets Optimized

**From `agents.yaml`:**
```yaml
traffic_analyzer_agent:
  role: Traffic Analyzer           # FIXED (agent identity)
  goal: >                          # OPTIMIZED ✓
    Parse and analyze website...
  backstory: >                     # OPTIMIZED ✓
    You are an expert traffic analyst...
```

**From `tasks.yaml`:**
```yaml
traffic_analysis_task:
  description: >                   # OPTIMIZED ✓
    Analyze the traffic data...
  expected_output: >               # OPTIMIZED ✓
    Detailed analysis presenting...
  agent: traffic_analyzer_agent    # FIXED (assignment)
```

### Key Differences from LangGraph Optimization

| Aspect | LangGraph | CrewAI |
|--------|-----------|--------|
| **Prompt Location** | Python f-string | YAML files |
| **Optimization Scope** | Single `system_prompt` | Multiple agents + tasks |
| **Configuration** | Inline code | External YAML |
| **Complexity** | 1 prompt to optimize | N agents × M tasks |

## Usage

### Python API

```python
from evaluation.prompt_optimizer_crewai import optimize_crew
from agents.crews.llmo.llm_optimizer import LLMOptimizerCrew

result = optimize_crew(
    config_dir="app/agents/crews/llmo/config",
    crew_func_factory=lambda: LLMOptimizerCrew(context_site="adobe.com"),
    dataset_name="llmo_comprehensive_dataset",
    max_iterations=5,
    score_threshold=0.8,
    tracing_platform="langsmith"
)

print(f"Improvement: {result['final_score'] - result['initial_score']:.3f}")
```

### Example Script

```bash
export PYTHONPATH=$PYTHONPATH:./app
uv run python app/evaluation/examples/optimize_llmo_crew.py
```

## How It Works

### Optimization Cycle

Each iteration:

1. **Load Current Configuration**
   - Extract all agent prompts (goal, backstory) from `agents.yaml`
   - Extract all task prompts (description, expected_output) from `tasks.yaml`
   - Package into `CrewPromptBundle`

2. **Execute & Evaluate**
   - Apply current bundle to YAML files
   - Create crew instance using factory function
   - Run evaluation on dataset
   - Collect scores

3. **Analyze Failures**
   - Build failure dataset from low-scoring responses
   - Identify common patterns across tasks
   - Determine which agents/tasks are underperforming

4. **Propose Holistic Improvements**
   - Meta-prompt with full crew configuration
   - LLM proposes improvements to **both** agents AND tasks
   - Ensures coherence between agent capabilities and task requirements

5. **Test & Compare**
   - Apply proposed bundle
   - Re-run evaluation
   - Keep if improved, revert if not

### Meta-Prompting Strategy

The optimizer uses a specialized meta-prompt that:

- Views the **entire crew configuration** (all agents + all tasks)
- Proposes changes that maintain **coherence**:
  - Agent goals align with task requirements
  - Task instructions match agent expertise
  - No contradictions between backstories and task descriptions
- Makes **surgical, targeted changes** to specific agents/tasks
- Provides detailed rationale for each modification

### Example Optimization

**Before:**
```yaml
# agents.yaml
traffic_analyzer_agent:
  goal: Analyze traffic
  backstory: You analyze traffic

# tasks.yaml  
traffic_analysis_task:
  description: Analyze the traffic
  expected_output: Traffic analysis
```

**After (iteration 3):**
```yaml
# agents.yaml
traffic_analyzer_agent:
  goal: >
    Parse and analyze website traffic data with zero tolerance for hallucinated
    keywords, extracting only real data from JSON responses
  backstory: >
    You are an expert traffic analyst who excels at JSON parsing.
    You NEVER create fake keywords like "Keyword1" or "Keyword2".
    You always present actual data with specific numbers.

# tasks.yaml
traffic_analysis_task:
  description: >
    Analyze traffic for {website_url} using SpaceCat tool.
    
    CRITICAL: Extract ONLY real keywords from metrics.organic_keywords.analysis.top_keywords.
    Present each keyword with its exact traffic number.
    
  expected_output: >
    Detailed traffic analysis with actual keyword names and traffic numbers.
    Zero placeholder or generic keywords. Use markdown tables for clarity.
```

## Best Practices

### 1. Start with Complete Crew

- Ensure all agents.yaml entries have `goal` and `backstory`
- Ensure all tasks.yaml entries have `description` and `expected_output`
- Test crew executes successfully before optimization

### 2. Create Quality Dataset

- Include diverse inputs that exercise all tasks
- Ensure dataset covers edge cases for each task
- Verify baseline scores are meaningful (not all 0 or all 1)

### 3. Monitor Coherence

- Check that agent improvements align with task changes
- Verify no contradictions introduced between agents
- Ensure task sequence still makes sense

### 4. Limit Iterations

- Start with 3-5 iterations for initial testing
- Too many iterations risk overfitting to dataset
- Monitor for oscillation between configurations

### 5. Manual Review

- **Always review** optimized YAML before committing
- Check for unintended changes to agent roles
- Verify task instructions remain clear and actionable

## Troubleshooting

### YAML Parsing Errors

**Symptom**: Optimization fails with YAML syntax errors

**Solutions**:
- Check for special characters in prompts (quotes, colons)
- Verify YAML indentation is preserved
- Use `>` for multi-line strings consistently

### Agents and Tasks Out of Sync

**Symptom**: Agent optimized but tasks don't match

**Solutions**:
- Check meta-prompt includes all agents AND tasks
- Verify LLM is returning complete JSON structure
- Review logs for partial updates

### No Improvement After Multiple Iterations

**Symptom**: Scores plateau or oscillate

**Solutions**:
- Lower score_threshold to analyze more failures
- Check if failure patterns are being identified correctly
- Try with smaller max_iterations to avoid local optima

### Crew Execution Fails After Optimization

**Symptom**: Optimized crew crashes or returns errors

**Solutions**:
- Validate YAML syntax after optimization
- Check that required YAML fields weren't removed
- Revert to backup and try lower max_iterations

## Implementation Details

**File**: `app/evaluation/prompt_optimizer_crewai.py`

**Key Components**:
- `CrewPromptBundle`: Data structure holding all prompts
- `_load_crew_prompts()`: Loads from YAML files
- `_save_crew_prompts()`: Saves back to YAML files
- `optimize_crew()`: Main optimization entry point

**LangGraph Workflow**:
```
initialize 
  ↓
execute_and_evaluate 
  ↓
analyze_failures 
  ↓
propose_improvements 
  ↓
decide_next_step 
  ↓
[continue?] → execute_and_evaluate OR END
```

## Future Enhancements

- [ ] Selective optimization (specific agents/tasks only)
- [ ] Multi-crew optimization (optimize multiple crews together)
- [ ] Agent role optimization (not just goal/backstory)
- [ ] Task dependency analysis (optimize based on task flow)
- [ ] Tool usage optimization (improve tool prompts)
- [ ] Memory optimization (integrate with crew memory settings)

## Related Documentation

- [Self-Improving AI Agents](self-improving-ai-agents.md) - Overall architecture
- [LangGraph Optimization](#prompt-optimization-system) - Single-agent optimization
- [CrewAI Documentation](https://docs.crewai.com/) - Official CrewAI docs

