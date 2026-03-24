# LLM-Powered Evals

## Related Documentation

- [Business Agents](../agents/business/business_agents.md)
- [Testing A2A Agents](./testing-a2a-agents.md)
- [Langfuse Evaluation Docs](https://langfuse.com/docs/evaluation/overview)
- [Langfuse Datasets](https://langfuse.com/docs/datasets/overview)

## Overview

This document describes the offline evaluation framework for Business Agents using Langfuse datasets and LLM-as-judge evaluations. The framework enables systematic testing of agent quality through:

1. **Dataset Management**: Curated test cases derived from `AsoBusinessAgentsSkills.csv` and expanded with variations
2. **Automated Evaluation**: LLM-powered evaluation of agent responses across multiple dimensions
3. **Continuous Monitoring**: Track agent quality over time as implementations evolve
4. **Langfuse Integration**: All results visible in Langfuse UI with tracing and scoring

### Phased Approach

**Phase 1 (MVP)**: Focus on **Sites Opportunities Agent** to validate the framework
- Build core infrastructure with a single agent
- Establish evaluation patterns and best practices
- Prove value before expanding to other agents
- Iterate on eval prompts and thresholds based on learnings

**Phase 2**: Expand to CWV, Accessibility, and Tech SEO agents using proven patterns

### Key Benefits

- **Regression Detection**: Catch quality degradation before production
- **Systematic Coverage**: Test all business agent skills comprehensively
- **Objective Metrics**: Consistent LLM-based evaluation across runs
- **Historical Tracking**: Compare agent performance across versions
- **CI/CD Integration**: Run evals automatically on every commit

## Architecture

### Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Evaluation Framework                      │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Dataset    │    │   Runner     │    │  Evaluators  │
│  Generator   │───▶│  (Executor)  │───▶│ (LLM-Judge)  │
└──────────────┘    └──────────────┘    └──────────────┘
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Langfuse   │    │   Business   │    │   Langfuse   │
│   Datasets   │    │    Agents    │    │    Scores    │
└──────────────┘    └──────────────┘    └──────────────┘
```

### Data Flow

1. **Dataset Creation**: Convert CSV skills → Langfuse dataset items
2. **Execution**: Run business agents against dataset inputs
3. **Evaluation**: LLM judges score outputs on multiple dimensions
4. **Reporting**: Results appear in Langfuse with traces and scores

## Dataset Structure

### Source: AsoBusinessAgentsSkills.csv

The CSV contains business agent skills organized by:
- Priority level (1 = highest)
- Skill category (Guidance, Insights, CWV, Accessibility, Tech SEO)
- Expected capabilities
- Customer ETAs

### Dataset Organization

Use Langfuse folder structure to organize datasets:

**Phase 1: Sites Opportunities Agent**
```
evaluation/
└── sites-opportunities-agent/
    ├── general-optimization
    ├── comprehensive-analysis
    ├── priority-recommendations
    ├── performance-recommendations
    └── opportunity-specific-guidance
```

**Phase 2: Expand to other agents**
```
evaluation/
├── sites-opportunities-agent/ (from Phase 1)
├── cwv-agent/
│   ├── identify-cls-issues
│   ├── identify-lcp-issues
│   └── identify-inp-issues
├── accessibility-agent/
│   ├── wcag-compliance
│   └── alt-text-issues
└── techseo-agent/
    ├── canonical-url-issues
    └── hreflang-issues
```

### Dataset Item Format

Each dataset item contains:

**Phase 1 Example - Sites Opportunities Agent:**
```python
{
    "input": {
        "agent": "sites_opportunities_agent",
        "query": "What should I optimize first for better SEO on my website?",
        "site_id": "0ceeef1f-c56e-4c31-b8d3-55af6b9509c7",  # Optional
        "website_url": "https://www.1firstbank.com"  # Optional
    },
    "expected_output": {
        "provides_recommendations": True,
        "includes_priorities": True,
        "mentions_business_impact": True,
        "actionable": True,
        "identifies_opportunities": True
    },
    "metadata": {
        "skill_id": "general_optimization_guidance",
        "priority": 2,
        "category": "guidance",
        "source": "AsoBusinessAgentsSkills.csv row 3"
    }
}
```

## Evaluation Dimensions

### 1. Correctness

**What it measures**: Does the response correctly address the query?

**LLM-Judge Prompt**:
```
You are evaluating the correctness of an AI agent's response.

Query: {{input.query}}
Agent Response: {{output}}
Expected Characteristics: {{expected_output}}

Rate the response on correctness (0.0 to 1.0):
- 1.0: Fully correct, addresses all aspects
- 0.7: Mostly correct with minor issues
- 0.5: Partially correct but missing key elements
- 0.3: Significant errors or omissions
- 0.0: Completely incorrect or irrelevant

Score: <float between 0.0 and 1.0>
Reasoning: <explanation>
```

### 2. Completeness

**What it measures**: Does the response include all expected information?

**Criteria**:
- Identifies specific pages/URLs
- Provides relevant metrics
- Explains business impact
- Suggests actionable next steps
- Prioritizes recommendations

### 3. Business Context

**What it measures**: Does the response include business-relevant context?

**Criteria**:
- Mentions business impact (traffic, revenue, user experience)
- Provides ROI estimates
- Suggests implementation effort
- Prioritizes by business value

### 4. Specificity

**What it measures**: Does the response provide specific, actionable guidance based on detected opportunities, rather than generic instructions?

**Criteria**:
- References specific opportunities detected on the site
- Mentions specific pages/URLs affected
- Uses data/metrics from the opportunity system
- Provides pre-written guidance from runbooks
- Avoids generic "best practices" advice

**Good example**: "Based on your Core Web Vitals opportunity, optimize images on pages X, Y, Z..."
**Bad example**: "You should optimize images, use lazy-loading, implement caching..."

> **Note**: The original design included "Actionability" and "Tone & Professionalism" evaluators. These were consolidated into "Specificity" during implementation, which better captures the distinction between site-specific recommendations and generic advice.

## Implementation

> **Note**: The implementation has evolved from the original design. See the actual code in `app/evaluation/` for current implementation details.

### Architecture Overview

```
app/evaluation/
├── __init__.py
├── dataset_providers.py     # Langfuse/LangSmith dataset abstraction
├── eval_runner.py           # Execute agents against datasets
├── evaluators.py            # LLM-as-judge (4 evaluators)
├── pipeline.py              # End-to-end orchestration
├── prompt_optimizer_langgraph.py   # LangGraph-based optimization
├── prompt_optimizer_crewai.py      # CrewAI crew optimization
├── failure_dataset_builder.py      # Build datasets from failures
├── langfuse_tool_extractor.py      # Extract tool calls for replay
└── examples/                # Example scripts
```

### 1. Dataset Providers

**Location**: `app/evaluation/dataset_providers.py`

The framework supports both Langfuse and LangSmith as dataset platforms:

```python
from evaluation.dataset_providers import create_dataset_provider

# Create provider (Langfuse or LangSmith)
provider = create_dataset_provider("langfuse")

# Get dataset
dataset = provider.get_dataset("my-eval-dataset")

# Iterate over items
for item in dataset:
    print(item.input, item.expected_output)

# Get scores from a previous run
scores = provider.get_baseline_scores("my-dataset", "run-name")
```

### 2. Evaluation Runner

**Location**: `app/evaluation/eval_runner.py`

```python
from evaluation.eval_runner import EvaluationRunner

runner = EvaluationRunner(
    tracing_platform="langfuse",  # or "langsmith" or "both"
    dataset_platform="langfuse"
)

results = await runner.run_dataset(
    dataset_name="my-dataset",
    agent_func=my_agent_function,
    run_name="eval-run-001",
    evaluator_func=my_evaluator  # Optional inline evaluation
)
```

### 3. LLM Evaluators

**Location**: `app/evaluation/evaluators.py`

Four evaluator classes using Azure OpenAI as LLM-judge:

```python
from evaluation.evaluators import (
    CorrectnessEvaluator,
    CompletenessEvaluator,
    BusinessContextEvaluator,
    SpecificityEvaluator
)
from langchain_openai import AzureChatOpenAI

azure_llm = AzureChatOpenAI(...)
evaluator = CorrectnessEvaluator(azure_llm)

# Evaluate a response
score, reasoning = evaluator.evaluate(input_data, output, expected_output)
```

### 4. Evaluation Pipeline

**Location**: `app/evaluation/pipeline.py`

The `EvaluationPipeline` orchestrates end-to-end evaluation:

```python
from evaluation.pipeline import EvaluationPipeline

pipeline = EvaluationPipeline()

report = await pipeline.run_evaluation(
    dataset_name="my-dataset",
    agent_func=my_agent_function,
    run_name="eval-run-001",
    sample_size=10  # Optional: limit for fast testing
)

print(report.get_summary())
```

### 5. Prompt Optimization

**Location**: `app/evaluation/prompt_optimizer_langgraph.py`

LangGraph-based iterative prompt improvement:

```python
# See app/evaluation/examples/ for usage examples
# The optimizer uses a state machine with nodes:
# analyze_failures → propose_update → execute_and_evaluate → decide_next_step
```

## Usage

### Running Evaluations

See `app/evaluation/examples/` for complete working examples:

```bash
# Example: Optimize a CrewAI crew
export PYTHONPATH=$PYTHONPATH:./app
uv run python app/evaluation/examples/optimize_llmo_crew.py

# Example: Create evaluation dataset
uv run python app/evaluation/examples/create_contextual_greeter_dataset.py
```

### View Results in Langfuse

Navigate to Langfuse UI to see:
- **Traces**: Each agent invocation with full context
- **Scores**: LLM-judge scores for each evaluation dimension
- **Datasets**: Test datasets with runs
- **Comparison**: Compare different prompt versions

## Best Practices

### Dataset Management

1. **Version Control**: Keep CSV in git, regenerate datasets when skills change
2. **Folder Organization**: Use meaningful hierarchy (agent/skill-category)
3. **Query Variations**: Generate 3-5 variations per skill for robustness
4. **Real Data**: Use actual site URLs and IDs from test accounts

**Available Test Sites** (from `/app/tests/`):
- `https://www.qualcomm.com` - Accessibility testing
- `https://www.1firstbank.com` - Forms accessibility (Site ID: `0ceeef1f-c56e-4c31-b8d3-55af6b9509c7`)
- `https://www.adobe.com` - General testing
- `https://main--wknd--hlxsites.hlx.live` - Memory/cache testing
- `https://business.adobe.com` - General testing

### Evaluation Design

1. **Multiple Dimensions**: Don't rely on single score, evaluate multiple aspects
2. **Temperature 0**: Use deterministic LLM-judge for consistency
3. **Clear Rubrics**: Provide explicit scoring criteria in prompts
4. **Validation**: Manually validate a sample of LLM-judge scores initially

### Continuous Improvement

1. **Baseline**: Establish baseline scores for each agent
2. **Regression Alerts**: Alert when scores drop below baseline
3. **Iterate**: Use failures to add new test cases
4. **Track Over Time**: Monitor score trends as agents evolve

## Next Steps

### Phase 1: Sites Opportunities Agent MVP

**Sites Opportunities Agent Skills** (from `AsoBusinessAgentsSkills.csv`):
- Row 3 (Priority 2): "What could I do to improve my page <URL>?" (Guidance Agent)
- Row 5 (Priority 2): "How optimized is the following URL? What optimization opportunities are most important?" (Insights Agent)
- Row 6 (Priority 2): "What are the most important optimizations I should work on for my site?" (Insights Agent)
- Row 7 (Priority 2): "What pages should I fix that would make the most impact?" (Insights Agent)

**Implementation Steps**:
1. **Extract Sites Opportunities Skills from CSV**: Parse rows 3, 5-7 (Guidance + Insights Agent skills)
2. **Generate Query Variations**: Create 3-5 variations per skill using LLM
3. **Implement Dataset Generator**: Build tool to convert skills → Langfuse datasets
4. **Create Base Evaluators**: Implement correctness, completeness, business context evaluators
5. **Build Evaluation Runner**: Execute Sites Opportunities Agent against dataset
6. **Run Initial Eval**: Execute full pipeline and validate results in Langfuse
7. **Manual Validation**: Review 20% of LLM-judge scores, adjust prompts as needed
8. **Establish Baselines**: Document baseline scores for the agent

### Phase 2: Expand to Other Agents

9. **Replicate Pattern**: Apply proven framework to CWV, Accessibility, Tech SEO agents
10. **Full Coverage**: Ensure all Priority 1 skills have test cases
11. **CI/CD Integration**: Add GitHub Actions workflow
12. **Continuous Monitoring**: Track quality trends over time
