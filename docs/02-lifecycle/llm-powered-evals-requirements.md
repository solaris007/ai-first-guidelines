# LLM-Powered Evals - Requirements

**Version**: 1.0 | **Date**: 2025-10-31 | **Status**: Draft

See [Design Document](./llm-powered-evals.md) for implementation details.

## Goals

1. **Quality Assurance**: Validate Business Agent responses across all Priority 1 skills
2. **Regression Prevention**: Catch quality degradation before production
3. **Continuous Improvement**: Enable data-driven iteration on agents
4. **Full Coverage**: Test all Priority 1 skills from `AsoBusinessAgentsSkills.csv`

## Phased Rollout

**Phase 1 (MVP)**: Sites Opportunities Agent
- Validate the eval framework approach with a single agent
- Build core infrastructure (dataset generator, runner, evaluators)
- Establish baseline scores and thresholds
- Prove value before expanding to other agents

**Phase 2**: Expand to CWV, Accessibility, and Tech SEO agents

## Must-Have Requirements (P0)

### Dataset Management
- Convert `AsoBusinessAgentsSkills.csv` to Langfuse datasets (Sites Opportunities Agent skills only for Phase 1)
- Generate 3-5 query variations per skill
- Support Sites Opportunities Agent initially, expand to other agents later

### Evaluation Execution
- Execute Sites Opportunities Agent against dataset items
- Create Langfuse traces for each evaluation
- Handle errors gracefully (timeouts, API failures)
- Capture full input/output for debugging
- Support for additional agents via plugin architecture

### LLM-as-Judge Scoring
- Evaluate on 3+ dimensions: Correctness, Completeness, Business Context
- Store scores (0.0-1.0) in Langfuse with reasoning
- Use temperature=0.0 for consistency
- Support GPT-4 and Claude as evaluators

### Reporting
- Generate markdown summary reports (pass/fail, scores, failures)
- Display all results in Langfuse UI
- Group by evaluation run and agent

### CI/CD Integration
- GitHub Actions workflow triggered on agent code changes
- Post results to PRs with pass/fail status
- Complete full suite in <15 minutes
- Block PRs if scores below threshold

## Should-Have Requirements (P1)

- Parallel execution for faster runs
- Dataset organization using Langfuse folders
- Custom evaluator support
- Detailed failure analysis with root causes
- Configurable quality gates and thresholds

## Non-Functional Requirements

### Performance
- Full evaluation suite completes in <15 minutes
- Scale to 1000+ test cases without degradation

### Reliability
- Scores consistent across runs (±0.05 variance)
- 3x retry on LLM API errors
- Partial results saved if interrupted

### Usability
- Single command to run evaluations locally
- Clear, actionable feedback for developers
- Easy to add new test cases

## Technical Stack

**Required**:
- Langfuse ≥2.0.0 (tracing and scoring)
- OpenAI ≥1.0.0 (LLM-as-judge)
- Python 3.13+ with AsyncIO
- GitHub Actions runner

**Configuration**:
- `LANGFUSE_PUBLIC_KEY`, `LANGFUSE_SECRET_KEY`, `LANGFUSE_HOST`
- `OPENAI_API_KEY` or `ANTHROPIC_API_KEY`
- Test sites with SpaceCat audit data

**Test Sites** (from existing tests in `/app/tests`):
- `https://www.qualcomm.com` - Used in accessibility tests
- `https://www.1firstbank.com` - Used in forms accessibility tests
- `https://www.adobe.com` - Used in various e2e and MCP tests
- `https://main--wknd--hlxsites.hlx.live` - Used in memory/cache tests
- `https://business.adobe.com` - Used in test cases

**Site IDs** (examples from tests):
- `0ceeef1f-c56e-4c31-b8d3-55af6b9509c7` (1firstbank.com)
- `9ae8877a-bbf3-407d-9adb-d6a72ce3c5e3` (test config)
- `0f889afa-270c-46b1-b831-425818c3fdd4` (optimization reports)

## Constraints

- LLM API costs <$100/month
- No PII or confidential data in test cases
- Must work with existing Business Agent architecture

## Success Metrics

**Phase 1 - Sites Opportunities Agent (Week 1-2)**:
- All Sites Opportunities Agent skills have 3-5 test cases each
- Evaluation pipeline runs successfully end-to-end
- Results appear in Langfuse with scores across 3 dimensions
- Baseline scores established for the agent

**Phase 1 - Validation (Week 3-4)**:
- Manually validate 20% of LLM-judge scores against human judgment
- Identify and fix any framework issues
- Evaluations run on every PR touching agent code
- Average score >0.7 across all dimensions

**Phase 2 - Expansion (Month 2+)**:
- Expand to CWV, Accessibility, and Tech SEO agents
- 100% Priority 1 skills coverage across all agents
- 10% quality improvement demonstrated
