# LangSmith Evaluation Framework Fixes

## Overview

This document summarizes the fixes made to enable the self-improving AI agent workflow to work with LangSmith as the evaluation platform. Previously, the workflow only supported Langfuse.

## Problems Fixed

### 1. Steps 1-3: Basic LangSmith Integration Issues

**Problem**: Multiple issues prevented Steps 1-3 from working with LangSmith:
- Score retrieval was looking for 'value' key instead of 'score' key
- Threshold comparison logic was inverted
- Platform parameter wasn't being passed through the pipeline

**Solution**:
- Updated `LangSmithDatasetProvider.get_baseline_scores()` to use correct 'score' key
- Fixed threshold logic to properly filter low-scoring runs
- Added platform parameter support throughout the pipeline

**Files Modified**:
- `app/evaluation/dataset_providers.py`
- `app/evaluation/pipeline.py`
- `app/evaluation/self_improving_agent_workflow.ipynb`

**Commit**: "Fix LangSmith evaluation: score retrieval, threshold logic, platform support"

---

### 2. Step 4: Baseline Score Extraction from Failure Dataset

**Problem**: Step 4 (Optimization) failed with error:
```
ValueError: No scores found for run 'sites-opp-eval-20251107_095801'
in dataset 'mystique-failures-20251107_101245'
```

**Root Cause**:
- Step 3 creates a NEW failure dataset from low-scoring runs
- This new dataset has no runs against it yet, so no feedback scores exist
- The optimizer was trying to get baseline scores from run feedback

**Solution**:
Step 3 already stores original scores in example metadata:
```python
metadata = {
    "original_run_id": run["run_id"],
    "original_scores": scores,  # {"correctness": 1.0, "specificity": 0.2, ...}
    "focus_dimension": focus_dimension,
    "failure_threshold": self.score_threshold,
}
```

We extract baseline scores from this metadata instead:

**Implementation**:
1. Added `get_baseline_scores_from_metadata()` method to `LangSmithDatasetProvider`:
   ```python
   def get_baseline_scores_from_metadata(self, dataset_name: str) -> dict[str, float]:
       """Extract baseline scores from failure dataset example metadata."""
       examples = list(self.client.list_examples(dataset_name=dataset_name))

       scores_by_dim = {
           "correctness": [],
           "completeness": [],
           "business_context": [],
           "specificity": []
       }

       for example in examples:
           if "original_scores" in example.metadata:
               original_scores = example.metadata["original_scores"]
               for dim in scores_by_dim:
                   if dim in original_scores:
                       scores_by_dim[dim].append(original_scores[dim])

       # Average scores for each dimension
       return {
           dim: sum(values) / len(values)
           for dim, values in scores_by_dim.items() if values
       }
   ```

2. Updated optimizer to try metadata extraction first, with fallback:
   ```python
   try:
       # Try metadata extraction (for failure datasets from Step 3)
       baseline_scores = provider.get_baseline_scores_from_metadata(dataset_name)
   except (ValueError, AttributeError):
       # Fallback to run feedback (for regular datasets)
       baseline_scores = provider.get_baseline_scores(dataset_name, initial_run_name)
   ```

**Files Modified**:
- `app/evaluation/dataset_providers.py` (lines 622-679)
- `app/evaluation/prompt_optimizer_langgraph.py` (lines 660-677)

**Testing**:
Created `app/evaluation/test_baseline_from_metadata.py` to verify extraction works:
```
✓ Extracted baseline scores from 27 examples:
  correctness: 0.870
  completeness: 0.837
  business_context: 0.807
  specificity: 0.156
  Overall average: 0.668
```

**Commit**: "Add LangSmith baseline score extraction from failure dataset metadata"

---

### 3. Step 4: Iteration Score Retrieval

**Problem**: After each optimization iteration, the optimizer failed with:
```
ERROR: No scores found for run 'prompt_optimization_iter_1'
in dataset 'mystique-failures-20251107_101245'
```

**Root Cause**:
After running inline evaluation, the code tried to query LangSmith for iteration scores:
```python
provider = create_dataset_provider(dataset_platform)
avg_scores = provider.get_baseline_scores(dataset_name, run_name)
```

This failed because:
1. Inline evaluation attaches scores to individual example runs, not the main run
2. LangSmith doesn't aggregate feedback from example runs to dataset level
3. The failure dataset has no runs with feedback (it's new from Step 3)

**Solution**:
The evaluation pipeline already returns an `EvaluationReport` object with the scores:
```python
class EvaluationReport:
    def aggregate_scores(self) -> dict[str, float]:
        """Calculate and return average scores per dimension."""
        avg_scores = {}
        for evaluator_name in ["correctness", "completeness", "business_context", "specificity"]:
            eval_scores = self.scores.get(evaluator_name, [])
            if eval_scores:
                avg_score = sum(s["score"] for s in eval_scores) / len(eval_scores)
                avg_scores[evaluator_name] = avg_score
        return avg_scores
```

Changed the optimizer to use these scores directly:
```python
# OLD (broken):
provider = create_dataset_provider(dataset_platform)
avg_scores = provider.get_baseline_scores(dataset_name, run_name)

# NEW (working):
avg_scores = report.aggregate_scores()
```

**Files Modified**:
- `app/evaluation/prompt_optimizer_langgraph.py` (line 431)

**Commit**: "Fix Step 4 iteration score retrieval to use inline evaluation results"

---

## Testing Infrastructure

### Standalone Step 4 Test Script

Created `app/evaluation/run_step4_only.py` to test Step 4 independently:
- Uses existing failure dataset from Step 3
- Runs with `MAX_ITERATIONS=1` for quick verification
- Proves the optimizer can extract baseline and iteration scores

**Usage**:
```bash
export PYTHONPATH=$PYTHONPATH:./app
uv run python app/evaluation/run_step4_only.py
```

**Expected Output**:
```
================================================================================
STEP 4: Optimize Prompt (Automated)
================================================================================

🎯 Starting optimization loop
📊 Initial run: sites-opp-eval-20251107_095801
📁 Failure dataset: mystique-failures-20251107_101245
🔄 Max iterations: 1

[... evaluation runs ...]

================================================================================
✅ STEP 4 COMPLETE: Optimization Finished
================================================================================

Baseline Average: 0.668
Final Average: 0.668
Total Improvement: +0.000
Best Iteration: 0 of 1

Final Scores:
  correctness: 0.870
  completeness: 0.837
  business_context: 0.807
  specificity: 0.156
```

---

## Architecture Notes

### LangSmith Data Model

Understanding LangSmith's architecture was key to solving these issues:

```
Dataset
├── Examples (with metadata)
│   ├── Example 1
│   │   ├── inputs/outputs
│   │   └── metadata: { "original_scores": {...}, ... }
│   └── Example 2
│       └── ...
│
└── Runs (separate from examples)
    ├── Run 1 → has feedback scores
    ├── Run 2 → has feedback scores
    └── ...
```

**Key Insights**:
1. **Scores are on Runs, not Examples**: Feedback/scores are attached to runs, not dataset examples
2. **No automatic aggregation**: LangSmith doesn't aggregate feedback from example runs to the dataset level
3. **Metadata is the solution**: Since failure datasets are new (no runs), we store original scores in example metadata
4. **Inline evaluation scores**: The evaluation pipeline computes scores inline and returns them in the `EvaluationReport`, no need to query LangSmith

### Score Flow

```
Step 2: Baseline Evaluation
├── Run evaluation on original dataset
├── Scores attached as feedback to run
└── Retrieved via provider.get_baseline_scores()

Step 3: Build Failure Dataset
├── Filter low-scoring runs
├── Create new dataset with failure examples
└── Store original_scores in metadata ✓

Step 4: Optimize
├── Extract baseline from metadata ✓
├── Run iteration evaluation
├── Get scores from report.aggregate_scores() ✓
└── Compare and decide next step
```

---

## Summary of Changes

### Files Created
- `app/evaluation/test_baseline_from_metadata.py` - Test metadata extraction
- `app/evaluation/run_step4_only.py` - Standalone Step 4 runner

### Files Modified
- `app/evaluation/dataset_providers.py` - Added metadata extraction, fixed score retrieval
- `app/evaluation/prompt_optimizer_langgraph.py` - Fixed baseline and iteration score retrieval
- `app/evaluation/pipeline.py` - Added platform parameter support
- `app/evaluation/self_improving_agent_workflow.ipynb` - Updated for LangSmith

### Commits
1. "Fix LangSmith evaluation: score retrieval, threshold logic, platform support"
2. "Add LangSmith baseline score extraction from failure dataset metadata"
3. "Fix Step 4 iteration score retrieval to use inline evaluation results"

---

## Verification

All 4 steps of the self-improving agent workflow now work with LangSmith:

- ✅ **Step 1**: Load or create evaluation dataset
- ✅ **Step 2**: Run baseline evaluation and get scores
- ✅ **Step 3**: Build failure dataset with metadata
- ✅ **Step 4**: Optimize prompt using metadata-based baseline and inline iteration scores

The workflow is ready for end-to-end testing with the full notebook.
