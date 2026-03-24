# Evaluation Framework - Quick Reference

## The Five Components

| Component | Purpose |
|-----------|---------|
| **Tracing** | Capture agent execution in Langfuse |
| **LLM-as-Judge** | Automated quality scoring via GPT-4 |
| **Datasets** | Test cases with human assertions |
| **Evaluation** | Track quality, detect regressions, CI/CD gates |
| **Optimization** | Automated prompt improvement |

## Four Evaluation Dimensions

| Dimension | What it measures |
|-----------|------------------|
| **Correctness** | Factual accuracy |
| **Completeness** | All expected info present |
| **Business Context** | Business-focused, not just technical |
| **Specificity** | Concrete findings vs. generic advice |

## Dataset Best Practices

### Human Assertions are Required

| Input | Assertion |
|-------|-----------|
| "How many broken links?" | `assert count == 3` |
| "What's the load time?" | `assert mentions "2.4s"` |

### Sources for Test Cases
- Production traces (real queries)
- PM requirements (expected behaviors)
- Known failures (prevent regressions)
- Edge cases (stress testing)

## Evaluation Use Cases

1. **Track over time** - Monitor quality trends
2. **Detect regressions** - Catch degradation
3. **CI/CD gates** - Block bad PRs

## Prompt Optimization

Loop: Analyze failures → Propose changes → Evaluate → Keep if better

**Principle:** Surgical changes, not rewrites

## Documentation

- [docs/evals/README.md](../README.md)
- [docs/evals/QUICKSTART.md](../QUICKSTART.md)
- [docs/evals/PROMPT_OPTIMIZATION.md](../PROMPT_OPTIMIZATION.md)
