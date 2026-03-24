# Speaker Notes

## Presentation Structure
- **Duration:** 20 minutes
- **5 Parts:** Tracing, LLM Evaluation, Datasets, Use Cases, Optimization

---

## Slide 1-2: Intro & Problem (2 min)
- Set the stage: "We've all shipped agents that worked in testing but failed in production"
- Build the case for observability + evaluation

---

## PART 1: TRACING

## Slides 3-4: Tracing (3 min)
**Key message:** You need visibility before you can evaluate

- "Tracing is the foundation - you can't score what you can't see"
- Langfuse captures: inputs, LLM calls, tool calls, outputs
- Benefits: debugging, pattern analysis, linking scores to traces

---

## PART 2: LLM-AS-JUDGE

## Slides 5-8: LLM-as-Judge (4 min)
**Key message:** Automated, scalable quality assessment

- Slide 5: Concept - "GPT-4 grades the responses"
- Slide 6: Four dimensions - mindmap shows the full picture
- Slide 7: Specificity example - **read both aloud**
  - "One gives you data, the other gives you homework"
- Slide 8: Flow - show how scores get attached to traces

---

## PART 3: DATASETS

## Slides 9-12: Dataset Management (4 min)
**Key message:** Human input is essential

- Slide 9: Basic structure - input, expected output, metadata
- Slide 10: Sources - production traces are gold
- Slide 11: **CRITICAL SLIDE** - Human assertions
  - "Generic expectations aren't enough"
  - "If the agent should find 3 broken links, you need to assert that"
  - "Without specific assertions, you're just checking vibes"
- Slide 12: Best practices - keep datasets fresh

---

## PART 4: USE CASES

## Slides 13-16: Evaluation Use Cases (4 min)
**Key message:** Multiple ways to use evaluations

- Slide 13: Tracking over time - "Are we getting better?"
- Slide 14: Regression detection - "Did we break something?"
- Slide 15: CI/CD - "Block bad PRs automatically"
- Slide 16: Results overview - what the output looks like

---

## PART 5: OPTIMIZATION

## Slides 17-21: Prompt Optimization (3 min)
**Key message:** Automate the tedious work

- Slide 17: The problem - manual prompt engineering is slow
- Slide 18: The loop - analyze, propose, evaluate, decide
- Slide 19: Failure analysis - GPT-4 finds patterns
- Slide 20: Progress tracking - show the improvement table
- Slide 21: Key principle - "Surgical changes, not rewrites"

---

## Slides 22-23: Summary & Q&A

### Key points to reiterate:
1. Tracing = visibility
2. LLM-as-Judge = scalable scoring
3. Datasets need human assertions
4. Use cases: tracking, regressions, CI/CD
5. Optimization closes the loop

### Common Questions:

**Q: How accurate is LLM-as-Judge?**
> 80-90% agreement with human reviewers

**Q: How much human effort for datasets?**
> Initial setup: 2-4 hours. Ongoing: 30 min/week to add failures

**Q: Can this run in CI/CD?**
> Yes, evaluation can be a required check before merge
