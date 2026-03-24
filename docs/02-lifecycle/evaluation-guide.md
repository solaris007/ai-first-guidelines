# Evaluation Guide: How to Evaluate and Optimize AI Agents

This guide explains how evaluation and prompt optimization work in Mystique, and how to get started. It covers the key concepts, architecture, and workflow so you can confidently evaluate any agent or crew.

For working references, see [Alt-Text Crew](../../app/evaluation/alt_text_crew/README.md) and [Metatags Crew](../../app/evaluation/metatags_crew/).

## Why Evaluate?

Without evaluation, prompt changes are guesswork. The evaluation framework gives you:

- **Measurable baselines** - Know how your agent performs today across specific dimensions.
- **Automated scoring** - Rule-based evaluators for structure/format, LLM-as-judge for quality/accuracy.
- **Regression detection** - Catch quality drops when prompts, tools, or models change.
- **Automated optimization** - The optimizer analyzes low-scoring items, proposes prompt improvements, and verifies they actually help.
- **Traceability** - Every run is stored in Langfuse with scores, traces, and metadata.

The typical workflow:

```
Write test cases  -->  Run baseline  -->  Review scores  -->  Optimize  -->  Verify  -->  Ship
     (once)           (establish)       (in Langfuse)      (iterate)     (re-run)    (commit)
```

## Getting Started

The fastest way to set up evaluation for a new agent or crew is the **`/optimize-agent` skill** in Claude Code. It detects your agent type, scaffolds the entire evaluation folder (schemas, dataset, evaluators, baseline runner, optimizer), and guides you through each step interactively.

```
/optimize-agent
```

The rest of this guide explains the concepts behind what the skill creates, so you understand how it works and can customize it.

## Prerequisites

### Environment Variables

```bash
# Langfuse (dataset storage and tracing)
LANGFUSE_PUBLIC_KEY=pk-lf-...
LANGFUSE_SECRET_KEY=sk-lf-...
LANGFUSE_HOST=https://cloud.langfuse.com  # or self-hosted instance

# Azure OpenAI (required for LLM-based evaluators)
AZURE_OPENAI_ENDPOINT=https://your-instance.openai.azure.com/
AZURE_OPENAI_KEY=your-api-key
AZURE_OPENAI_API_VERSION=2025-01-01-preview

# PYTHONPATH (always required)
export PYTHONPATH=$PYTHONPATH:./app
```

### VPN & Dependencies

- Connect to Adobe VPN to access Langfuse.
- Run `uv sync` to install all dependencies.

## Two Agent Types

Before evaluating, determine whether you have a **CrewAI Crew** or a **LangGraph Agent**. Both use the same evaluation pipeline, but the prompt storage and optimizer differ.

| | CrewAI Crew | LangGraph Agent |
|---|---|---|
| **Location** | `app/agents/crews/<name>/` | `app/agents/<category>/<name>.py` |
| **Prompt storage** | YAML files (`config/agents.yaml`, `config/tasks.yaml`) | Python code (`system_prompt = """..."""`) |
| **How to detect** | Has `config/` directory, `@CrewBase` decorator | Single Python file, imports `langchain`/`langgraph` |
| **Optimizer** | `prompt_optimizer_crewai.py` | `prompt_optimizer_langgraph.py` |
| **What gets optimized** | Multiple agent goals/backstories + task descriptions | Single `system_prompt` string |

The `/optimize-agent` skill auto-detects this for you and generates the appropriate code.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   YAML Dataset (source of truth)            │
│               app/evaluation/<crew>/datasets/*.yaml         │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                      load_dataset.py                        │
│  1. Validate YAML (schemas.py)                              │
│  2. Preprocess items (scrape, extract context, etc.)        │
│  3. Upload to Langfuse                                      │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                         Langfuse                            │
│           Dataset items with input / expected_output        │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                      run_baseline.py                        │
│  1. Create crew function (crew_factory.py)                  │
│  2. Fetch dataset from Langfuse                             │
│  3. Run crew on each item                                   │
│  4. Score with evaluators (evaluators.py)                   │
│  5. Generate report                                         │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                     optimize_crew.py                        │
│  Iterative prompt optimization via LangGraph/CrewAI         │
└─────────────────────────────────────────────────────────────┘
```

### Shared Framework Components

The following modules in `app/evaluation/` are shared across all crew evaluations:

| Module | Purpose |
|--------|---------|
| `base_evaluators.py` | `RuleBasedEvaluator` and `LLMBasedEvaluator` base classes |
| `pipeline.py` | `EvaluationPipeline` - orchestrates dataset execution, scoring, and reporting |
| `eval_runner.py` | `EvaluationRunner` - runs agent functions against Langfuse dataset items |
| `dataset_providers.py` | Langfuse/LangSmith dataset abstraction layer |
| `yaml_utils.py` | YAML loading, schema validation, duplicate ID checks, group distribution |
| `prompt_optimizer_crewai.py` | Shared CrewAI prompt optimizer |
| `prompt_optimizer_langgraph.py` | Shared LangGraph prompt optimizer |

## Steps in Detail

> **Note:** The `/optimize-agent` skill scaffolds all of these files for you automatically. The steps below explain what each file does and how to customize it. If you used the skill, you can skip straight to [Running](#running) and come back here when you need to tweak something.

### Step 1: Create the Directory Structure

The evaluation package for your crew follows this layout:

```
app/evaluation/<your_crew>/
├── __init__.py
├── datasets/
│   └── <your_crew>.yaml          # Test cases (source of truth)
├── schemas.py                     # Pydantic models for dataset validation
├── evaluators.py                  # Custom evaluators (rule-based + LLM)
├── crew_factory.py                # Wraps your crew for the evaluation pipeline
├── load_dataset.py                # Validates and uploads dataset to Langfuse
├── run_baseline.py                # Runs baseline evaluation
├── optimize_crew.py               # Runs prompt optimization
├── validate_dataset.py            # (Optional) Standalone validation for CI/CD
└── generate_visualizer.py         # (Optional) HTML visualizer for test cases
```

### Step 2: Define the Dataset Schema

Create `schemas.py` with Pydantic models that define the shape of your test cases.

```python
from typing import Literal
from pydantic import BaseModel, Field, HttpUrl


class DatasetMetadata(BaseModel):
    """Dataset-level metadata."""
    name: str = Field(..., description="Dataset name (used in Langfuse)")
    version: str = Field(..., description="Semantic version (e.g., '1.0.0')")
    description: str = Field(..., description="Human-readable description")


class TestCaseInput(BaseModel):
    """Input data for a single test case. Customize for your crew."""
    # Add crew-specific input fields
    query: str = Field(..., description="The input query")
    url: HttpUrl = Field(..., description="Target URL")


class ExpectedOutput(BaseModel):
    """Expected output for evaluation. Customize for your crew."""
    description: str = Field(..., description="Qualitative description for LLM-as-judge")
    # Add crew-specific expected output fields


CategoryType = Literal["category_a", "category_b", "edge_case"]


class TestCase(BaseModel):
    """A single test case."""
    id: str = Field(..., description="Unique identifier")
    enabled: bool = Field(default=True)
    category: CategoryType
    scenario: str = Field(..., description="Human-readable scenario description")
    input: TestCaseInput
    expected_output: ExpectedOutput


class YourCrewDataset(BaseModel):
    """Complete dataset."""
    dataset: DatasetMetadata
    test_cases: list[TestCase]

    def get_enabled_test_cases(self) -> list[TestCase]:
        return [tc for tc in self.test_cases if tc.enabled]
```

### Step 3: Write the YAML Dataset

Create `datasets/<your_crew>.yaml`:

```yaml
dataset:
  name: your_crew_eval_dataset
  version: "1.0.0"
  description: "Evaluation dataset for YourCrew"

test_cases:
  - id: basic_happy_path
    enabled: true
    category: category_a
    scenario: "Basic scenario to verify core functionality"
    input:
      query: "What is the best approach for X?"
      url: https://example.com/page
    expected_output:
      description: "Should provide specific, actionable recommendations for X"

  - id: edge_case_empty_input
    enabled: true
    category: edge_case
    scenario: "Empty or minimal input handling"
    input:
      query: ""
      url: https://example.com/empty
    expected_output:
      description: "Should handle gracefully and return meaningful error or fallback"
```

#### Dataset Naming Convention

- **Langfuse dataset name**: `{dataset.name}_v{dataset.version}` (e.g., `your_crew_eval_dataset_v1.0.0`)
- **Item IDs**: `{test_case.id}_v{version}` (e.g., `basic_happy_path_v1.0.0`)

#### Tips for Good Test Cases

- Cover happy paths, edge cases, and failure modes.
- Group test cases into categories for analysis.
- Include `expected_output.description` that clearly states what the output should contain - this drives LLM-as-judge evaluators.
- Use `enabled: false` to temporarily skip problematic cases without deleting them.
- Start small (5-10 cases) and expand as you identify gaps.

### Step 4: Write Custom Evaluators

Create `evaluators.py` with a mix of rule-based and LLM-based evaluators.

#### Base Classes

All evaluators inherit from shared base classes in `evaluation.base_evaluators`:

```python
from evaluation.base_evaluators import RuleBasedEvaluator, LLMBasedEvaluator
```

#### Evaluator Interface

Every evaluator implements the same interface:

```python
def evaluate(
    self,
    input_data: dict[str, Any],
    output: str,
    expected_output: Any,
    metadata: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Returns {"score": float (0.0-1.0), "reasoning": str}"""
```

#### Rule-Based Evaluators

Fast, deterministic, free. Use for structural checks, length validation, format compliance.

```python
class OutputFormatEvaluator(RuleBasedEvaluator):
    """Checks that output is valid JSON with required fields."""

    name = "output_format"

    def evaluate(self, input_data, output, expected_output, metadata=None):
        try:
            data = json.loads(output)
            if "result" not in data:
                return {"score": 0.5, "reasoning": "Missing 'result' field"}
            return {"score": 1.0, "reasoning": "Valid structure"}
        except json.JSONDecodeError:
            return {"score": 0.0, "reasoning": "Invalid JSON"}
```

#### LLM-Based Evaluators

Use for nuanced quality assessment where rules fall short. Only override `_build_prompt()`:

```python
class ContentQualityEvaluator(LLMBasedEvaluator):
    """Evaluates content quality using LLM-as-judge."""

    name = "content_quality"

    def _build_prompt(self, input_data, output, expected_output, metadata=None):
        expected_desc = expected_output.get("description", "") if isinstance(expected_output, dict) else str(expected_output)

        return f"""Evaluate the quality of this output.

**Input**: {input_data.get("query", "")}
**Output**: {output}
**Expected**: {expected_desc}

Scoring:
- 1.0: Excellent - fully addresses the input with accurate, specific content
- 0.7: Good - mostly accurate with minor omissions
- 0.5: Fair - partially addresses the input
- 0.3: Poor - significant gaps or inaccuracies
- 0.0: Fails - completely wrong or irrelevant

Provide your evaluation in this exact format:
Score: <float between 0.0 and 1.0>
Reasoning: <explanation>"""
```

The base class handles LLM invocation, response parsing (`Score: X.X / Reasoning: ...`), error handling, and provides both sync `evaluate()` and async `aevaluate()`.

#### Factory Function

Every evaluator module must export a factory function:

```python
def get_your_crew_evaluators(azure_openai_client=None) -> list:
    """Get all evaluators for YourCrew."""
    evaluators = [
        # Rule-based (always available)
        OutputFormatEvaluator(),
        LengthCheckEvaluator(),
    ]

    # LLM-based (require Azure OpenAI)
    if azure_openai_client:
        evaluators.extend([
            ContentQualityEvaluator(azure_openai_client),
        ])

    return evaluators
```

The factory function signature must be `(azure_openai_client) -> list[Evaluator]` - this is what `EvaluationPipeline` passes when using `evaluator_factory`.

### Step 5: Create the Crew Factory

Create `crew_factory.py` to wrap your crew for the evaluation pipeline.

The pipeline expects an async function with this signature:

```python
async def crew_func(input_data: dict, callbacks=None) -> str
```

Example:

```python
from evaluation.prompt_optimizer_crewai import optimize_crew


def create_your_crew_func():
    """Factory to create crew function for evaluation."""

    async def crew_func(input_data: dict, callbacks=None) -> str:
        from agents.crews.your_module.your_crew import YourCrew

        # Extract inputs from dataset item
        query = input_data.get("query", "")
        url = input_data.get("url", "")

        # Create and run crew
        crew = YourCrew()
        result = await crew.crew().kickoff_async(
            inputs={"query": query, "url": url}
        )

        # Return string output
        if result.pydantic is not None:
            return json.dumps(result.pydantic.model_dump(), default=str)
        return str(result)

    return crew_func
```

### Step 6: Write the Load Dataset Script

Create `load_dataset.py` to validate the YAML and upload to Langfuse.

```python
import asyncio
import logging
import sys
from pathlib import Path

app_dir = Path(__file__).resolve().parent.parent.parent
if str(app_dir) not in sys.path:
    sys.path.insert(0, str(app_dir))

from evaluation.yaml_utils import validate_yaml_dataset, get_dataset_name_from_yaml
from evaluation.your_crew.schemas import YourCrewDataset, TestCase
from services.langfuse_client import get_langfuse_client

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

YAML_PATH = Path(__file__).parent / "datasets" / "your_crew.yaml"


async def main(dry_run=False):
    # 1. Validate
    is_valid, dataset = validate_yaml_dataset(
        YAML_PATH,
        YourCrewDataset,
        items_getter=lambda d: d.test_cases,
        id_getter=lambda tc: tc.id,
        group_getter=lambda tc: tc.category,
        enabled_getter=lambda tc: tc.enabled,
    )
    if not is_valid:
        sys.exit(1)

    if dry_run:
        logger.info("Dry run complete. No data uploaded.")
        return

    # 2. Upload to Langfuse
    client = get_langfuse_client()
    dataset_name = get_dataset_name_from_yaml(YAML_PATH)
    version = dataset.dataset.version

    client.create_dataset(
        name=dataset_name,
        description=dataset.dataset.description,
    )

    enabled_cases = dataset.get_enabled_test_cases()
    for tc in enabled_cases:
        item_id = f"{tc.id}_v{version}"
        client.create_dataset_item(
            dataset_name=dataset_name,
            id=item_id,
            input=tc.input.model_dump(mode="json"),
            expected_output=tc.expected_output.model_dump(mode="json"),
            metadata={
                "test_case_id": tc.id,
                "category": tc.category,
                "scenario": tc.scenario,
            },
        )
        logger.info(f"  Uploaded: {item_id}")

    client.flush()
    logger.info(f"Uploaded {len(enabled_cases)} items to '{dataset_name}'")


if __name__ == "__main__":
    dry_run = "--dry-run" in sys.argv
    asyncio.run(main(dry_run=dry_run))
```

### Step 7: Write the Baseline Runner

Create `run_baseline.py`:

```python
import asyncio
import logging
import sys
from datetime import datetime
from pathlib import Path

app_dir = Path(__file__).resolve().parent.parent.parent
if str(app_dir) not in sys.path:
    sys.path.insert(0, str(app_dir))

from evaluation.your_crew.crew_factory import create_your_crew_func
from evaluation.your_crew.evaluators import get_your_crew_evaluators
from evaluation.pipeline import EvaluationPipeline

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

DATASET_NAME = "your_crew_eval_dataset_v1.0.0"
BASELINE_RUN_NAME_PREFIX = "your_crew_baseline"


async def main():
    timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    run_name = f"{BASELINE_RUN_NAME_PREFIX}_{timestamp}"

    crew_func = create_your_crew_func()
    pipeline = EvaluationPipeline()

    report = await pipeline.run_evaluation(
        dataset_name=DATASET_NAME,
        agent_func=crew_func,
        run_name=run_name,
        evaluator_factory=get_your_crew_evaluators,
        sample_size=None,  # Set to an int for fast testing
    )

    report.print_summary()


if __name__ == "__main__":
    asyncio.run(main())
```

#### Running

```bash
export PYTHONPATH=$PYTHONPATH:./app

# Step 1: Load dataset (first time or after YAML changes)
uv run python app/evaluation/your_crew/load_dataset.py

# Step 2: Run baseline
uv run python app/evaluation/your_crew/run_baseline.py
```

### Step 8: Prompt Optimization (Optional)

Create `optimize_crew.py` to iteratively improve prompts:

```python
import asyncio
import sys
from pathlib import Path

app_dir = Path(__file__).resolve().parent.parent.parent
if str(app_dir) not in sys.path:
    sys.path.insert(0, str(app_dir))

from evaluation.your_crew.crew_factory import create_your_crew_func
from evaluation.your_crew.evaluators import get_your_crew_evaluators
from evaluation.prompt_optimizer_crewai import optimize_crew


async def main():
    config_dir = "app/agents/crews/your_module/config"

    result = await optimize_crew(
        config_dir=config_dir,
        crew_func_factory=create_your_crew_func,
        dataset_name="your_crew_eval_dataset_v1.0.0",
        max_iterations=3,
        score_threshold=0.75,
        evaluator_factory=get_your_crew_evaluators,
        sample_size=None,
    )

    print(f"Initial score: {result['initial_score']:.3f}")
    print(f"Final score:   {result['final_score']:.3f}")


if __name__ == "__main__":
    asyncio.run(main())
```

Also see the [/optimize-agent skill](../../.claude/skills/optimize-agent/) for a CLI-driven workflow.

## How the Pipeline Works

### `EvaluationPipeline.run_evaluation()`

This is the main orchestrator. Here is what happens when you call it:

1. **Resolve evaluators**: Uses the priority chain: `evaluators` param > `evaluator_factory` param > default evaluators.
2. **Create evaluator function**: Wraps evaluators into an async function that runs all of them in parallel via `asyncio.gather`.
3. **Run dataset**: `EvaluationRunner.run_dataset()` fetches items from Langfuse, runs `agent_func` on each (with concurrency control via semaphore), and scores within the Langfuse dataset run context.
4. **Retrieve scores**: Fetches scores back from Langfuse for the report.
5. **Generate report**: `EvaluationReport` aggregates scores by dimension and produces a markdown summary.

### Score Dimensions Are Dynamic

The pipeline reads evaluator names to determine score dimensions. No hardcoded list - whatever evaluators your factory returns become the dimensions in the report.

### Concurrency

`EvaluationRunner` runs dataset items concurrently with configurable `max_concurrency` (default: 10). Each item execution is wrapped in a semaphore.

## Existing Crew Evaluations

| Crew | Location | Evaluators | Dataset |
|------|----------|------------|---------|
| **Alt-Text Crew** | `app/evaluation/alt_text_crew/` | 4 rule-based + 4 LLM-based | YAML with image/page context |
| **Metatags Crew** | `app/evaluation/metatags_crew/` | 11 rule-based + 1 LLM-based | YAML with detected/healthy tags |
| **Gen FAQ Crew** | `app/evaluation/gen_faq_crew/` | Uses shared evaluators | Programmatic dataset |

Use these as references when building your own.

## Checklist

- [ ] Create `app/evaluation/<crew>/` directory with `__init__.py`
- [ ] Define Pydantic schemas in `schemas.py`
- [ ] Write YAML dataset in `datasets/`
- [ ] Implement evaluators with factory function in `evaluators.py`
- [ ] Create crew wrapper in `crew_factory.py`
- [ ] Write `load_dataset.py` to upload to Langfuse
- [ ] Write `run_baseline.py` to run evaluation
- [ ] (Optional) Write `optimize_crew.py` for prompt optimization
- [ ] (Optional) Add `validate_dataset.py` for CI/CD validation
- [ ] Run `load_dataset.py --dry-run` to validate
- [ ] Run `load_dataset.py` to upload
- [ ] Run `run_baseline.py` and review scores in Langfuse

## Troubleshooting

### "No module named 'evaluation'"

```bash
export PYTHONPATH=$PYTHONPATH:./app
```

### "Langfuse client not configured"

Check credentials:
```bash
echo $LANGFUSE_PUBLIC_KEY
echo $LANGFUSE_SECRET_KEY
echo $LANGFUSE_HOST
```

### "Azure OpenAI not configured"

LLM-based evaluators will be skipped. You still get rule-based evaluator scores.

### "Dataset not found"

Run `load_dataset.py` before `run_baseline.py`.

### Low scores across the board

- Check that `crew_factory.py` correctly maps dataset `input` fields to crew inputs.
- Check that evaluator prompts reference the right fields from `expected_output`.
- Review a few items in Langfuse to see if the crew output is reasonable.

### Evaluation takes too long

Use `sample_size` in `run_baseline.py` for faster iteration:

```python
report = await pipeline.run_evaluation(
    ...,
    sample_size=5,  # Only run 5 items
)
```

## Related Documentation

- [Evaluation Quickstart](EVALUATION_QUICKSTART.md) - Zero to scores in 10 minutes
- [Evaluation Framework Overview](README.md) - Index of all evaluation docs
- [Quickstart Guide](QUICKSTART.md) - Step-by-step tutorial for Sites Opportunities Agent
- [Evaluator Refactor Summary](EVALUATOR_REFACTOR_SUMMARY.md) - Base class architecture
- [Prompt Optimization](PROMPT_OPTIMIZATION.md) - LangGraph-based optimization workflow
- [Tool Replay](TOOL_REPLAY.md) - Deterministic testing with recorded tool responses
- [Alt-Text Crew README](../../app/evaluation/alt_text_crew/README.md) - Full working example