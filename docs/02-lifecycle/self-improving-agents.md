

# **Architectures for Self-Improving AI Agents: A Framework for Automated Prompt Optimization in LangChain and CrewAI**

## **Executive Summary**

This framework automates AI agent improvement through continuous learning. Instead of manually refining prompts through trial and error, the system automatically evaluates agent performance, identifies failures, and optimizes prompts to achieve higher quality. The architecture uses three core steps—Execution (your existing agents), Evaluation (automated quality assessment), and Optimization (iterative prompt refinement)—to create agents that learn from their own performance and systematically improve over time.

## **Quick Start: Understanding the System**

### **What This Does**

Converts manual prompt engineering (hours of trial and error) into an automated workflow that continuously improves agent quality.

### **How It Works: 30-Second Overview**

```
┌─────────────────────────────────────────────────────────────┐
│          SELF-IMPROVING AGENT ARCHITECTURE                  │
└─────────────────────────────────────────────────────────────┘

                  Synthetic
                  Dataset ──┐
                  (Golden   │
                   tests)   │
                            ▼
               ┌─────────────────┐◄──────────────┐
               │   EXECUTION     │               │
               │                 │               │
               │   Your agent    │               │
               │   performs      │               │
               │   tasks         │               │
               └─────────────────┘               │
                       │                         │
                       │ Produces traces         │
                       ▼                         │
            ┌──────────────────────┐             │
            │    TRACES            │             │
            │  • Production runs   │             │
            │  • Test runs         │             │
            └──────────────────────┘             │
                       │                         │
                       │ Consumed by             │
                       ▼                         │
               ┌─────────────────┐               │
               │   EVALUATION    │               │
               │   (AI Judge)    │               │
               │                 │               │
               │   Scores both:  │               │
               │   • Production  │               │
               │   • Synthetic   │               │
               └─────────────────┘               │
                       │                         │
                       │ Failures from           │
                       │ both sources            │
                       ▼                         │
               ┌─────────────────┐               │
               │  OPTIMIZATION   │               │
               │   (LangGraph)   │               │
               │                 │               │
               │  Refines prompt │               │
               │  to fix both    │               │
               └─────────────────┘               │
                       │                         │
                       │ Improved prompt         │
                       └─────────────────────────┘
                                  Deploy
```

**The Continuous Learning Loop:**

1. Your agent performs tasks (using production traces + synthetic dataset) →
2. LLM Judge scores outputs automatically →
3. System identifies failures (scores < 0.7) →
4. Optimization step refines prompts →
5. Improved agent deploys → Loop continues

### **Key Benefits**

- **Quality Improvement:** Agent quality improves from 0.3-0.4 baseline to 0.7+ production-ready in 3-5 iterations
- **Time Savings:** Eliminates manual prompt tweaking hours
- **Systematic Coverage:** Continuously addresses failure cases from production data
- **Data-Driven:** Every change backed by quantitative evaluation

**Next:** See detailed architecture and implementation guide below.

---

## **Key Concepts Glossary**

Before diving into the details, familiarize yourself with these core concepts:

- **Execution:** Your existing LangChain or CrewAI agent that performs tasks. Takes a system prompt and user input, produces output. The component being optimized. Uses both production traces (real user interactions) and synthetic dataset (golden test cases).

- **Evaluation (LLM-as-a-Judge):** An AI system that automatically scores agent outputs across quality dimensions (correctness, completeness, business context, specificity). Provides both quantitative scores (0.0-1.0) and qualitative feedback explaining the assessment.

- **Optimization:** The meta-level process that analyzes evaluation feedback and iteratively refines the agent's system prompt. Implemented using LangGraph's state machine patterns to orchestrate the improvement cycle.

- **RLAIF (Reinforcement Learning from AI Feedback):** A paradigm where AI models provide the feedback signal for training other AI models, eliminating the need for expensive human annotation. The Evaluation step uses RLAIF principles to generate improvement signals.

- **Generator-Critic Loop:** A cyclic pattern where a Generator proposes prompt improvements, a Critic evaluates the results, and a conditional decision determines whether to accept the change or try again. The core pattern powering the Optimization step.

- **Meta-Prompting:** Using an LLM to act as a "prompt engineer" that analyzes failures and suggests improvements to another LLM's instructions. The technique used by the Optimization step to propose prompt refinements.

- **Convergence:** The point at which prompt optimization stops because either (1) quality scores exceed the target threshold (e.g., >0.7), (2) improvements between iterations become negligible (<0.05), or (3) maximum iteration count is reached.

---

## **The Theoretical Foundation: From Agentic RL to Practical Self-Correction**

### **Defining the Agentic Learning Loop: Beyond Manual Prompt Engineering**

The current paradigm for developing many AI agents, particularly those built with frameworks like LangChain and CrewAI, relies on a static definition of behavior. An agent's capabilities, personality, and constraints are encoded in a system prompt, a set of instructions that remains fixed until a human developer intervenes.5 While effective for well-defined tasks, this approach becomes a significant impediment when high-quality, nuanced performance is required. The developer is locked into a laborious cycle of trial and error: write a prompt, test, observe a failure, guess at a corrective modification, and repeat. This process is not only time-consuming but is also limited by the developer's ability to explore the vast and complex space of possible instructions.

A self-improving agentic system transcends this limitation by internalizing the improvement cycle. Instead of relying on external human intervention, the system is designed to perform, assess, and refine its own behavior autonomously.7 This capability is built upon a foundational architectural pattern: the automated learning loop. This loop consists of four distinct stages that operate continuously:

1. **Execute:** The agent performs a given task based on its current set of instructions (its system prompt).  
2. **Evaluate:** The agent's output is assessed against a set of quality criteria by an automated evaluation mechanism. This stage generates a performance signal, akin to a reward in reinforcement learning.  
3. **Reflect:** The system analyzes the evaluation feedback, identifying discrepancies between the actual and desired output. It forms a hypothesis about what changes to its instructions might lead to a better outcome.  
4. **Refine:** Based on the reflection, the system modifies its own instructions—the system prompt—and prepares for the next execution cycle.

By automating this loop, the system can conduct more experiments in a fraction of the time it would take a human, systematically exploring the instruction space to discover prompts that yield superior performance. This directly addresses the core need to have the "LLM do this auto learning cycle," transforming the agent from a static tool into a dynamic, adaptive entity.

### **The RLAIF Paradigm: Automating Feedback with AI**

The concept of an agent learning from feedback is central to the field of Reinforcement Learning (RL). In a traditional RL setup, an agent learns an optimal policy by interacting with an environment and receiving reward signals that guide its actions.5 However, applying traditional RL to LLM-based agents presents significant challenges. The "reward" for complex language tasks—such as writing a high-quality report or generating a nuanced piece of code—is often sparse, difficult to quantify, and sometimes unverifiable without human judgment.8 This makes direct credit assignment for a sequence of generated words extremely difficult.

To overcome these limitations, the field has largely adopted **Reinforcement Learning from Human Feedback (RLHF)**, a technique where human evaluators provide preference data (e.g., ranking two different model responses) to train a "reward model." This reward model then serves as a proxy for human judgment during the RL training phase. While highly effective, RLHF is notoriously expensive, time-consuming, and difficult to scale due to its reliance on continuous human annotation.4

**Reinforcement Learning from AI Feedback (RLAIF)** emerges as a powerful and scalable alternative. RLAIF replaces the human annotator with another capable AI model, often a more powerful LLM, to provide the feedback or preference labels.3 This "AI Judge" or "preference model" is prompted with a set of principles or a constitution, enabling it to evaluate an agent's output for qualities like helpfulness, harmlessness, and accuracy.9 The core process involves several steps:

1. An initial, helpful model generates responses to a set of prompts.  
2. The model is then prompted again, this time to critique its own responses based on a constitution and revise them.  
3. This process generates a dataset of response pairs (e.g., a "chosen" and a "rejected" response).  
4. A preference model is trained on this AI-generated dataset.  
5. Finally, the original agent model is fine-tuned using RL, with the AI-trained preference model providing the reward signal.9

For the purpose of building a self-improving agent that refines its prompts, the full RLAIF fine-tuning pipeline is not strictly necessary. Instead, the core principle can be adapted: using one AI model to generate a qualitative and quantitative feedback signal for another. This forms the theoretical basis for the Evaluation, where an LLM-as-a-Judge provides the "reward" that drives the prompt optimization process, creating a practical and efficient self-improvement loop without the need for model retraining.

### **Conceptual Architecture: The Three Core Steps (Execution, Evaluation, Optimization)**

To translate the theoretical concepts of an automated learning loop and RLAIF into a practical, implementable system, a modular architecture is required. The most robust and flexible approach is to structure the system into three distinct but interconnected steps, each with a specialized function. This modularity is crucial because it separates concerns and allows for each component to be developed, tested, and upgraded independently. The search for a single, monolithic "framework" for agentic RL is often misguided; the true solution lies in architecting a composite system from best-in-class components that fulfill these specific roles.

1. **The Execution:** This is the primary, task-oriented component of the system. In the context of the user's request, this engine is their existing LangChain or CrewAI agent. Its function is to take a system prompt and a user task as input and produce an output. Crucially, **execution produces traces**—structured records of what was executed, including inputs, outputs, tool calls, and metadata. These traces are generated both from production runs (real-world usage) and test runs (evaluation on synthetic datasets). The quality of the execution's output is the variable the entire system is designed to optimize. The Execution is treated as a "black box" by the other steps; its internal workings are less important than its input-output behavior.
2. **The Evaluation:** This engine is the heart of the automated feedback mechanism. Its sole purpose is to assess the quality of outputs by **consuming traces** produced by the Execution. The state-of-the-art implementation for this is the **LLM-as-a-Judge** pattern, where a powerful LLM is prompted with a detailed rubric to score the output against predefined criteria (e.g., correctness, clarity, adherence to format).11 This engine retrieves traces from both production runs and test runs, analyzes them, and produces two critical signals for the next stage: a quantitative score and qualitative, text-based feedback explaining the reasoning behind the score. This feedback is the "AI Feedback" in the RLAIF paradigm.
3. **The Optimization:** This is the meta-level component that closes the learning loop. It orchestrates the entire process and is responsible for generating improvements. The Optimization receives the evaluation score and feedback from the Evaluation and uses this information to propose a modification to the system prompt used by the Execution. This can be achieved through various techniques, from meta-prompting, where an LLM is asked to act as a prompt engineer 1, to more structured approaches like cyclical agentic workflows built in LangGraph.1

By separating the system into these three steps, the complex problem of "agentic reinforcement learning" is broken down into manageable engineering challenges: building a reliable agent (Execution), creating a trustworthy automated evaluator (Evaluation), and designing an effective improvement proposal mechanism (Optimization). This architecture provides a clear and robust path to building a truly self-improving agent.

## **The Evaluation: Building a Reliable LLM-as-a-Judge**

The efficacy of any self-improving system is fundamentally limited by the quality of its feedback signal. If the system cannot accurately distinguish between good and bad performance, it cannot learn effectively. Therefore, constructing a robust and reliable Evaluation is the most critical prerequisite for automating prompt optimization. The LLM-as-a-Judge pattern has emerged as the industry-standard method for this, offering a scalable, cost-effective, and nuanced approach to automated quality assessment.13

### **Principles of Automated Quality Assessment**

Traditional automated text evaluation metrics, such as BLEU and ROUGE, were designed for tasks like machine translation and summarization. They operate by measuring surface-level features like n-gram overlap with a reference text.11 While useful in those contexts, they are fundamentally incapable of capturing the deeper, qualitative aspects of an AI agent's output. They cannot assess factual correctness, logical coherence, adherence to a specific tone, or the helpfulness of a response.13

The LLM-as-a-Judge approach overcomes these limitations by leveraging the advanced reasoning capabilities of a large language model to perform the evaluation. Instead of relying on rigid algorithms, the judge model is given a detailed, natural-language rubric and asked to score an output in a structured way. This method offers several key advantages:

* **Scalability and Speed:** An LLM judge can process vast quantities of text far more quickly and cheaply than a team of human reviewers.11  
* **Nuance and Flexibility:** The judge can be instructed to evaluate complex, subjective criteria that are impossible to capture with traditional metrics. The evaluation criteria can be easily modified by simply changing the judge's prompt.13  
* **Consistency and Explainability:** While not perfect, an LLM judge can apply a rubric more consistently than multiple human annotators, who may have differing subjective opinions. Furthermore, the judge can be instructed to provide detailed reasoning for its score, making the evaluation process transparent and interpretable.11

### **Crafting Effective Judge Prompts: Rubrics, Biases, and Scoring**

The prompt provided to the LLM judge is the single most important element of the Evaluation. It is not merely an instruction; it is a detailed evaluation rubric that must be crafted with the same rigor as a scientific measurement tool. An effective judge prompt typically includes several key components 12:

1. **Role and Persona:** The prompt should begin by assigning a clear role to the judge (e.g., "You are a meticulous quality assurance analyst...").  
2. **Context:** It must provide all necessary context, including the original user query and any reference materials or ground truth answers.  
3. **Evaluation Criteria:** This is the core of the rubric. It should explicitly define 3-5 distinct quality aspects to be assessed (e.g., Correctness, Relevance, Conciseness, Tone). Overloading the judge with too many criteria can dilute its focus.13  
4. **Scoring Instructions:** The prompt must specify the evaluation strategy and scoring mechanism. Common strategies include:  
   * **Single Output Scoring:** The judge assigns a numerical score (e.g., on a 1-5 or 1-10 scale) for each criterion. This is useful for tracking performance over time.13  
   * **Pairwise Comparison:** The judge is presented with two outputs (e.g., from a baseline prompt and a candidate prompt) and asked to declare a winner. This is ideal for A/B testing and is often more reliable for LLMs than assigning absolute scores.11  
5. **Step-by-Step Reasoning:** Instructing the judge to "think step-by-step" before providing a final score often improves the quality and reliability of its assessment.13  
6. **Output Format:** The prompt must demand a structured output format, typically JSON, to ensure the results are machine-parsable.

However, it is critical to acknowledge that LLM judges are susceptible to inherent biases that can undermine their reliability. Developers must actively design prompts and evaluation workflows to mitigate these issues 11:

* **Position Bias:** Models often show a preference for the first response they see in a pairwise comparison. This can be mitigated by running the evaluation twice and swapping the positions of the responses to ensure the preference is consistent.11  
* **Verbosity Bias:** LLMs tend to favor longer, more detailed answers, even if they are less correct or helpful. The rubric should explicitly reward conciseness where appropriate.11  
* **Self-Enhancement Bias:** A judge model may unfairly favor outputs generated by itself or models from the same family (e.g., GPT-4 judging a GPT-4o output). Using a judge from a different model provider can help reduce this bias.13

### **Deep Dive: The Calibration Challenge and Meta-Alignment**

The shift from Reinforcement Learning from Human Feedback (RLHF) to Reinforcement Learning from AI Feedback (RLAIF) was driven by the need for scalability, speed, and consistency. The "LLM-as-a-judge" is the engine of RLAIF, replacing the costly and slow process of human annotation.

However, this introduces a critical problem: **an AI judge is not an objective arbiter of truth**. It is a model with its own inherent biases and flaws. If an AI judge is misaligned—for example, if it has a "length bias" and prefers longer answers regardless of quality—then any model aligned using its feedback will inherit and amplify this flaw.

Therefore, before an "LLM-as-a-judge" can be used to evaluate and train other models, it must *itself* be evaluated and aligned. This is the **meta-alignment loop**: a human-in-the-loop workflow to calibrate the AI judge until it becomes a reliable proxy for human preferences.

### **The Process: Aligning the "LLM-as-a-Judge"**

The process you've outlined is a "human-in-the-loop" workflow to create a high-quality, automated evaluator. This is done by calibrating the AI judge's scores against a "gold standard" set of human scores.

Here are the steps, just as you laid them out.

#### **Step 1: Create the "Gold Standard" (Human Scores)**

This is your "have humans provide a score" step.

**Action:** You take a representative sample of your model's outputs (or outputs from various models) and have human experts evaluate them.

**Data Type:** Instead of the simple pairwise (A > B) comparison used for RLHF, you are asking for scalar (point-wise) scores. For example, humans rate the output on a 1-5 scale.

**Best Practice:** This is notoriously "noisy" because one human's "7/10" is another's "9/10". To solve this, you must create a very clear, detailed evaluation rubric. This rubric often breaks the score into specific attributes, like "helpfulness," "fluency," or "factuality". This human-annotated dataset becomes your "gold standard."

#### **Step 2: Benchmark the AI Judge (Compare Scores)**

This is your "compare human's score with AI's score" step.

**Action:** You run your "LLM-as-a-judge" on the exact same set of outputs that your humans evaluated in Step 1. You prompt the AI judge to provide scores using the exact same rubric.

**Metrics:** You then statistically measure the alignment between the two sets of scores. The most common metrics for this are:

* **Spearman's Correlation or Kendall's Tau:** These measure if the ranks of the scores agree (i.e., if the AI and humans both generally agree that A is better than B, even if their scores aren't identical).
* **F1-Score / Cohen's Kappa:** If you convert the scores to binary labels (e.g., 1-3 = "Bad," 4-5 = "Good"), these metrics can measure the agreement.

This step gives you a clear metric for your judge's quality and identifies exactly where its judgments diverge from your human experts.

#### **Step 3: Iteratively Refine the Judge (The "Work On" Loop)**

This is your "work on evaluators... until their score matches" step. This is the "failure detect" loop in your diagram. There are two primary ways the community does this:

**Method A: Iterative Prompt & Rubric Refinement**

This is a "human-in-the-loop" process that refines the judge's instructions.

1. **Analyze Failures:** You look at the examples where the AI judge's score was most different from the human score.
2. **Refine Criteria:** You try to understand why the judge "got it wrong." Was your rubric unclear? Did the judge fixate on something irrelevant, like answer length?
3. **Update Prompt:** You update the judge's prompt and rubric to be more explicit and cover these edge cases. For example: "You must rate for 'helpfulness.' Conciseness is a bonus, but a short, unhelpful answer should get a low score."
4. **Repeat:** You re-run the benchmark (Step 2) and see if your correlation score has improved. This refinement loop is critical, as the understanding of the criteria often evolves ("criteria drift").

**Method B: Fine-Tuning the Judge Model**

This is a more powerful, automated approach where you train the judge model itself.

1. **Use SFT:** You can take your "gold standard" dataset of (output, human_score, rationale) and use standard supervised fine-tuning (SFT) to train a smaller, cheaper LLM to act as a judge.
2. **Use DPO:** A more advanced technique is to use Direct Preference Optimization (DPO) to align the judge. You can convert your scalar scores back into preference pairs (e.g., an output with a "5" is preferred over an output with a "3"). You then fine-tune your judge model using DPO on these preference pairs. This has been shown to significantly improve the judge's alignment with human preferences.

In short, your proposed process is not only correct but represents the frontier of building reliable, scalable, and automated evaluation systems that are the backbone of modern alignment research.

### **Leveraging Evaluation Libraries to Create "Golden" Datasets**

While LangSmith provides the ideal environment for refining and aligning an evaluator, other open-source libraries can be instrumental in creating the initial "golden" datasets needed for this process. These tools offer structured ways to run initial evaluations and gather the labeled data that will be fed into the LangSmith alignment workflow.

* **DeepEval and RAGAs:** Other specialized frameworks offer robust suites for programmatic evaluation. DeepEval is designed to integrate into Python testing workflows like Pytest, allowing developers to unit-test LLM outputs against various metrics.23 RAGAs is purpose-built for evaluating Retrieval-Augmented Generation (RAG) pipelines, measuring critical aspects like faithfulness and context relevance.24 Using these frameworks to run initial batch evaluations can help identify common failure modes and generate a rich, labeled dataset that serves as the input for creating and aligning a more sophisticated LLM-as-a-Judge in LangSmith.

## **The Optimization: LangGraph-Based Prompt Refinement**

Once a reliable Evaluation is in place, the next step is to build the Optimization—the component that takes the evaluator's feedback and uses it to propose improvements to the agent's system prompt. This project uses LangGraph for its native integration with the LangChain ecosystem, powerful stateful workflows, and support for cyclical refinement loops.

### **LangGraph: Cyclical Refinement with Generator-Critic Loops**

For developers already invested in the LangChain ecosystem, LangGraph represents the most logical and powerful choice for building the Optimization. Traditional agentic frameworks built on linear "chains" of thought (like the ReAct pattern) are ill-suited for self-correction. If a chain-based agent makes a mistake, it typically plows ahead, unable to backtrack, revise its plan, or learn from the error.14

LangGraph overcomes this limitation by modeling agent workflows as state machines or graphs. This architecture is inherently more flexible, allowing for the creation of cycles, branches, and persistent state (memory) across execution steps.14 This capability is essential for implementing the iterative refinement loop required for self-improvement.

#### **Implementing Core Patterns**

Two primary patterns are particularly effective for building a self-correcting optimization loop in LangGraph:

* **The Generator-Critic Loop:** This is the foundational pattern for self-correction. The graph consists of at least two nodes and a conditional edge:
  * **Generator Node:** This node represents the Execution. It takes the current system prompt and the user's task from the shared state, executes the agent, and writes the agent's output back to the state.14
  * **Critic Node:** This node is the Evaluation. It takes the agent's output from the state, runs it through the LLM-as-a-Judge, and updates the state with a score and textual feedback.14
  * **Conditional Edge:** This is the "brain" of the loop. It inspects the score in the state. If the score meets a predefined success threshold, the edge routes the workflow to a final "end" node. If the score is unsatisfactory, it routes the flow back to a "Refine" node (or directly back to the Generator), passing along the critic's feedback to inform the next attempt.14
* **Reflection Agents:** This is an enhancement of the basic critic pattern. Instead of just scoring the output, a dedicated "Reflector" node is prompted to perform a more in-depth critique of the generator's performance. It might be asked to identify superfluous information, point out missing details, or suggest alternative approaches.26 This more structured and constructive feedback can steer the generator more effectively in the subsequent iteration. The reflector can even be given a different persona (e.g., a skeptical editor) to encourage more critical analysis.27

This implementation is the foundation of the current system, as detailed in the notebooks and prompt optimizer implementation.


## **Architectural Blueprint: A Unified Framework for a Self-Improving "Prompt Engineer" Agent**

Synthesizing the analysis of the core steps and optimization frameworks, this section presents a concrete architectural blueprint for a self-improving "Prompt Engineer" agent. This system is designed using the recommended LangChain-native path, leveraging LangGraph for its stateful, cyclical control flow. This architecture provides a robust, flexible, and powerful solution for fully automating the prompt optimization lifecycle.

### **High-Level Diagram**

The system is architected as a LangGraph state machine. The flow begins with an initial task and a baseline system prompt. The agent executes the task, its output is evaluated by a critic, and if the performance is suboptimal, a refinement node proposes an updated prompt. This cycle continues until a satisfactory performance level is achieved or a maximum number of iterations is reached.

The primary components are the **State**, the **Nodes** that operate on the state, and the **Conditional Edges** that direct the flow of logic between the nodes.

### **State Definition (AgentState)**

The AgentState is the central memory of the graph, a shared object that persists across all nodes and iterations. It is typically defined as a TypedDict in Python, ensuring type safety and clarity.

Python

from typing import List, TypedDict

class AgentState(TypedDict):  
    initial\_task: str               \# The original user request to the agent.  
    current\_prompt: str             \# The system prompt being tested and refined.  
    agent\_output: str               \# The final output from the agent's execution.  
    evaluation\_score: float         \# The numeric score (e.g., 0.0 to 1.0) from the judge.  
    evaluation\_feedback: str        \# The textual reasoning from the LLM-as-a-Judge.  
    improvement\_history: List\[dict\] \# A log of past prompts and scores to track progress.  
    iteration\_count: int            \# A counter to prevent infinite loops.

### **Node Implementation**

Each node in the graph is a Python function or a LangChain Runnable that takes the current state as input and returns a dictionary of updates to the state.

* **execute\_agent (Generator Node):** This node is responsible for running the target agent (the Execution). It reads the current\_prompt and initial\_task from the state. It then instantiates and runs the agent (which could be a LangChain agent or a CrewAI crew) with these inputs. The final output from the agent is then used to update the agent\_output field in the state.  
* **evaluate\_output (Critic Node):** This node invokes the Evaluation. It takes the agent\_output and initial\_task from the state and passes them to the LangSmith-aligned LLM-as-a-Judge. The judge returns a structured response containing a score and feedback. This node updates the evaluation\_score and evaluation\_feedback fields in the state.  
* **propose\_update (Refinement Node):** This is the core of the Optimization. Its function is to generate a new, potentially better system prompt. It receives the entire state as input, paying close attention to the current\_prompt, the evaluation\_feedback, and the improvement\_history. It can be implemented using several techniques:  
  * **Meta-Prompting:** The node can call an LLM with a "meta-prompt" that instructs it to act as an expert prompt engineer. The meta-prompt would include the failed prompt, the agent's output, and the judge's critique, and ask the LLM to write a revised prompt that addresses the identified flaws.1  
  * langmem Optimizer: A more structured approach is to use the langmem.create\_prompt\_optimizer function. This function can take the history of attempts as input and programmatically generate an improved prompt.29  
    The output of this node is a new string that updates the current\_prompt in the state. It also increments the iteration\_count and appends the last attempt to the improvement\_history.

### **Conditional Edging**

The logic of the loop is controlled by a conditional edge that originates from the evaluate\_output node. After the critic has run, this edge function inspects the state:

Python

def should\_refine(state: AgentState):  
    score \= state\["evaluation\_score"\]  
    iterations \= state\["iteration\_count"\]  
    if score \> 0.9 or iterations \>= 5:  
        return "end"  
    else:  
        return "refine"

This function routes the graph. If the score is high enough or the iteration limit is reached, it transitions to a final end node, completing the process. Otherwise, it transitions to the propose\_update node to begin another refinement cycle.

## **Implementation Roadmap and Strategic Recommendations**

A successful transition from manual prompt engineering to a fully autonomous, self-improving system requires a methodical, phased approach. Plunging directly into building a complex agentic loop without establishing foundational components can lead to unreliable behavior that is difficult to debug. The following roadmap outlines a strategic sequence of steps, starting with measurement and gradually building towards full automation.

### **Step 1: Establish Baselines with LangSmith Observability**

Before any attempt at automation, it is imperative to understand and quantify the performance of the current, manually-engineered agent. The first step is to fully instrument the existing LangChain or CrewAI agent with LangSmith.40 By ensuring all agent runs are traced, developers gain deep visibility into the agent's behavior, including tool calls, intermediate LLM reasoning steps, and final outputs.41 This provides a rich dataset of existing performance. Key metrics such as cost per run, end-to-end latency, and token usage should be tracked in LangSmith dashboards to establish a clear performance baseline against which all future automated improvements will be measured.41 This step moves the process from subjective "gut feel" to objective, data-driven analysis.

### **Step 2: Bootstrap the Evaluation**

With observability in place, the next critical phase is to build the v1 Evaluation. This involves creating a reliable LLM-as-a-Judge using the LangSmith "Align Evaluator" workflow. The process is as follows:

1. **Create a "Golden" Dataset:** From the traces collected in Step 1, select a diverse set of 50-100 examples that are representative of the agent's typical tasks and failure modes.  
2. **Human Annotation:** Use LangSmith's annotation queues to have subject-matter experts label this dataset according to the desired quality criteria (e.g., correctness, helpfulness). This creates the ground truth.17  
3. **Align the Evaluator:** In the Evaluator Playground, iteratively craft and test an LLM-as-a-Judge prompt against this golden set. The goal is to refine the prompt until the judge's automated scores achieve a high alignment (\>85%) with the human labels.17 This step ensures that the automated feedback signal is trustworthy and accurately reflects the desired quality standards.

### **Step 3: Build the V1.0 Optimization Loop in LangGraph**

With a reliable evaluator, the autonomous loop can now be constructed. Implement the "Prompt Engineer Agent" architecture detailed in the previous section using LangGraph. The initial implementation should focus on creating a functional end-to-end cycle:

* Define the AgentState.  
* Implement the execute\_agent node to run the target agent.  
* Implement the evaluate\_output node to call the LangSmith-aligned judge from Step 2\.  
* Implement a v1 propose\_update node using a simple meta-prompting strategy.39  
* Define the conditional edge to control the loop based on the evaluation score.

The goal of this step is not to achieve perfect optimization immediately, but to create a working, autonomous system that can execute, evaluate, and refine a prompt over several iterations without human intervention.

### **Step 4: Integrate into Your CrewAI Workflow**

The self-improving LangGraph application acts as an offline "training" or "optimization" process. The output of a successful run of this application is a highly optimized system prompt. This refined prompt can then be integrated back into the production CrewAI agents. In CrewAI, agent definitions are often managed in agents.yaml files, which can include a system\_template parameter.6 The optimized prompt generated by the LangGraph "Prompt Engineer" agent should be used as the new value for this system\_template. This creates a clear workflow: run the optimization agent to discover the best prompt, then update the production agent's configuration with this new, validated prompt.

### **Step 5: Scaling and Long-Term Maintenance**

A self-improving system requires continuous maintenance to remain effective. As the production agent encounters new edge cases or as user expectations evolve, the prompt may begin to "drift" from optimal performance. To combat this, a long-term maintenance strategy should be implemented:

* **Continuous Feedback Loop:** Use LangSmith to monitor production traffic. When failures or poor-quality outputs are identified, flag these specific traces and add them to the annotation queue.
* **Periodic Re-alignment:** Regularly (e.g., weekly or bi-weekly), have experts process the annotation queue, adding new labeled examples to the golden dataset. This keeps the ground truth current.
* **Re-run Optimization:** Periodically re-run the "Prompt Engineer" agent. Because it uses the LLM-as-a-Judge, which is grounded in the continuously updated golden dataset, it will be able to refine the system prompt to account for the newly identified failure modes, ensuring the agent's performance continues to improve over time.

## **Development Workflow: Bootstrapping Without Production Data**

The production workflow documented above assumes you already have production traces with real user interactions. However, during initial development or when building a new agent from scratch, you don't have production data yet. This section documents the **development-specific workflow** for establishing baselines and iterating on prompts before deployment.

### **The Development Challenge**

When developing a new agent or significantly refactoring an existing one, you face a chicken-and-egg problem:
- The production workflow requires real traces to identify failure cases
- But you can't deploy to production without validating the agent works well
- You need evaluation data to improve the agent, but have no production traces yet

The solution is to **synthesize a test dataset** from your agent's skill definitions and use it to establish baselines and iterate during development.

### **4-Step Development Workflow**

```
┌─────────────────────────────────────────────────────────────────┐
│              DEVELOPMENT WORKFLOW (No Production Data)           │
└─────────────────────────────────────────────────────────────────┘

    ┌──────────────────┐
    │   STEP 1:        │
    │   Generate       │
    │   Synthetic      │──────┐
    │   Dataset        │      │  From skills CSV:
    └──────────────────┘      │  4 skills × 1 variation = 4 test items
            │                 │
            │ Dataset created │  💡 Use --variations 1 during development
            │                 │     for faster iteration cycles
            ▼                 │
    ┌──────────────────┐      │
    │   STEP 2:        │      │
    │   Run Baseline   │      │
    │   Evaluation     │◀─────┘
    │   (Get Scores)   │
    └──────────────────┘
            │
            │ Baseline scores:
            │ • Correctness: 0.35
            │ • Completeness: 0.45
            │ • Business Context: 0.40
            │ • Specificity: 0.30
            ▼
    ┌──────────────────┐
    │   STEP 3:        │
    │   Filter Items   │
    │   with Scores    │──────┐
    │   Below 0.7      │      │  Create failure-focused dataset
    └──────────────────┘      │  for optimization
            │                 │
            │ Filtered items  │
            │ with any score  │
            │ < 0.7           │
            ▼                 │
    ┌──────────────────┐      │
    │   STEP 4:        │      │
    │   Optimize       │      │
    │   Prompt         │      │
    │   (Automated)    │◀─────┘
    └──────────────────┘
            │
            │ Improved prompt generated
            │ via iterative refinement
            │ until convergence
            ▼
    ┌──────────────────┐
    │   Deploy to      │
    │   Production     │
    └──────────────────┘

Once all dimensions > 0.7 and optimization converges:
→ Deploy to production
→ Switch to production workflow (continuous improvement)
```

### **Step 1: Generate Synthetic Dataset**

Use the agent's skill definitions (CSV) to automatically generate test queries. This creates a dataset with diverse queries that test each of the agent's capabilities.

**What This Creates:**
- A dataset with test queries like:
  - "How can I improve my site https://www.infosys.com?"
  - "What optimization opportunities should I focus on for https://www.infosys.com?"
  - "Which pages should I fix for maximum impact on https://www.infosys.com?"
- Each query is designed to test a specific agent skill/capability

**Implementation:** See the companion notebook `app/evaluation/self_improving_agent_workflow.ipynb` for the complete implementation with all parameters and execution details.

### **Step 2: Run Baseline Evaluation**

Execute the agent against your test dataset to establish baseline performance.

**What This Does:**
1. Loads the test items from the dataset
2. For each query:
   - Runs the agent
   - Captures full trace
   - Runs LLM-as-a-Judge across 4 dimensions:
     - **Correctness**: Does the response accurately address the query?
     - **Completeness**: Does it include all expected information?
     - **Business Context**: Does it frame findings in business terms (ROI, impact)?
     - **Specificity**: Does it provide specific, actionable guidance from detected opportunities?
3. Generates evaluation report with scores

**Implementation:** See `app/evaluation/self_improving_agent_workflow.ipynb` for execution details and expected output with scores across all dimensions.

### **Step 3: Filter Items with Scores Below 0.7**

After running the baseline evaluation, identify and filter dataset items where any evaluation dimension scored below the 0.7 threshold. These low-scoring items become the focus for automated optimization.

**What This Does:**
1. Queries the evaluation run from Step 2 for all traces
2. Filters traces where ANY dimension (correctness, completeness, business_context, specificity) scored < 0.7
3. Creates a new dataset containing only the failing items
4. This failure-focused dataset becomes the training set for optimization

**Implementation:** See `app/evaluation/self_improving_agent_workflow.ipynb` for the filtering process with configurable thresholds and dimension-specific filtering options.

### **Step 4: Optimize Prompt (Automated)**

With a failure-focused dataset in hand, run the automated optimization loop to iteratively refine the agent's system prompt until convergence.

**What This Does:**
1. **Baseline Evaluation**: Runs current prompt against failure dataset, computes average scores
2. **Propose Improvement**: Uses LLM "meta-engineer" to analyze failures and propose refined prompt
3. **Test Candidate**: Runs updated prompt against same dataset
4. **Convergence Check**: Accepts improvement if significant, continues iterating
5. **Stops When**:
   - All dimension scores > 0.7 (success threshold)
   - Improvement < 0.05 (diminishing returns)
   - Max iterations reached

**Implementation:** See `app/evaluation/self_improving_agent_workflow.ipynb` for the complete Generator-Critic loop implementation with iteration tracking, convergence criteria, and optimization trajectory visualization.

### **Transitioning to Production**

Once development scores are satisfactory (all dimensions > 0.7):

1. **Deploy Agent**: Push updated prompt to production
2. **Enable Production Tracing**: Ensure LangChain callbacks are configured
3. **Monitor Initial Performance**: Watch first 100-200 production traces
4. **Switch Workflows**: Move to the 4-step production workflow:
   - Step 0: Automatic scoring on sampled production traffic (10%)
   - Step 1 & 2: Create failure datasets from poor-scoring runs (< 0.7)
   - Step 3: Run automated optimization on failure dataset
   - Step 4: Deploy improved prompt, repeat cycle

### **Development Workflow Benefits**

This development-specific workflow provides several key advantages:

1. **No Production Data Required**: Start evaluating and improving before deployment
2. **Fast Iteration Cycles**: 1 variation per skill = 4 items = ~5 min eval runs
3. **Objective Quality Gates**: Don't deploy until scores > 0.7 across all dimensions
4. **Systematic Improvement**: Track score improvements across iterations
5. **Smooth Production Transition**: Established evaluation patterns carry over to production

### **Running the Workflow**

For both development and production workflows, refer to the companion Jupyter notebook `app/evaluation/self_improving_agent_workflow.ipynb`, which provides a complete, executable implementation of all four steps with:

- Interactive parameter configuration
- Step-by-step execution with progress tracking
- Inline visualization of results and scores
- Links to view traces in Lang Smith/Langfuse
- Detailed documentation of each step's purpose and expected outcomes

The notebook can be run interactively in Jupyter or executed headless using Papermill for automation and CI/CD integration.

## **Production Workflow: Automated Score-Driven Improvement**

The ultimate goal of this evaluation framework is not merely to measure agent performance, but to use those measurements to drive continuous, automated improvement. This section outlines the production workflow that closes the loop between evaluation and optimization, creating a self-improving system.

### **The Four-Step Continuous Improvement Loop**

#### **High-Level Learning Progress Architecture**

This diagram shows how the self-improving agent learns through continuous feedback. Based on **2025 research**, the system has TWO parallel learning loops with MULTIPLE pathways:

**🆕 2025 UPDATE:** You now have THREE options for judge training:
1. **Self-Taught Evaluators (NEW!)**: NO human annotations - fully synthetic training data (75.4% → 88.3% alignment)
2. **Hybrid Approach (RECOMMENDED)**: Start with 15-20 human annotations, then self-improve with AI feedback
3. **Traditional RLHF**: Full human annotation (most expensive, but highest initial quality)

**Key 2025 Insights:**
- 85% LLM judge alignment > 81% human-to-human agreement!
- Direct-RLAIF bypasses reward model training entirely
- Confidence-based sampling >> random sampling
- Recursive advisors automate the generate→evaluate→retry loop

```
┌─────────────────────────────────────────────────────────────────────────────┐
│         SELF-IMPROVING AGENT: TWO PARALLEL LEARNING LOOPS                   │
│                                                                              │
│  Loop A: Train the Judge (Human-in-the-Loop) - ONE-TIME SETUP               │
│  Loop B: Train the Agent (Automated) - CONTINUOUS                           │
└─────────────────────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════════
LOOP A: TRAIN THE JUDGE (ONE-TIME SETUP + ONGOING REFINEMENT)
═══════════════════════════════════════════════════════════════════════════════

    PHASE 1: Bootstrap the Judge (Run Once)
    ┌──────────────────────────────────────────┐
    │                                          │
    │  ① COLLECT DIVERSE EXAMPLES              │
    │     Sample ~50-100 agent runs            │
    │     covering different scenarios         │
    │            │                             │
    │            ↓                             │
    │  ② ADD TO ANNOTATION QUEUE               │
    │     ┌────────────────────────┐           │
    │     │ ANNOTATION QUEUE       │           │
    │     │ ───────────────────    │           │
    │     │ • 50 runs pending      │           │
    │     │ • Assigned to SMEs     │           │
    │     │ • Priority: failures   │           │
    │     └───────────┬────────────┘           │
    │                 │                        │
    │                 ↓                        │
    │  ③ HUMAN LABELING                        │
    │     ┌────────────────────────┐           │
    │     │ Subject Matter Experts │           │
    │     │ review each run:       │           │
    │     │                        │           │
    │     │ • correctness: 0.8     │           │
    │     │ • completeness: 0.4    │           │
    │     │ • reasoning: "Missing  │           │
    │     │   business context"    │           │
    │     └───────────┬────────────┘           │
    │                 │                        │
    │                 ↓                        │
    │  ④ CREATE GOLDEN DATASET                 │
    │     ┌────────────────────────┐           │
    │     │ GOLDEN/REFERENCE       │           │
    │     │ DATASET                │           │
    │     │ ───────────────────    │           │
    │     │ 50 human-labeled       │           │
    │     │ examples with          │           │
    │     │ ground truth scores    │           │
    │     └───────────┬────────────┘           │
    │                 │                        │
    │                 ↓                        │
    │  ⑤ TEST LLM JUDGE ALIGNMENT              │
    │     ┌────────────────────────┐           │
    │     │ LLM Judge scores       │           │
    │     │ golden dataset         │           │
    │     │                        │           │
    │     │ Alignment: 72% ✗       │  < 85%    │
    │     │ (Too low!)             │           │
    │     └───────────┬────────────┘           │
    │                 │                        │
    │                 ↓                        │
    │  ⑥ ANALYZE MISALIGNMENTS                 │
    │     "Judge penalizes brevity too much"   │
    │     "Judge ignores business context"     │
    │            │                             │
    │            ↓                             │
    │  ⑦ REFINE JUDGE PROMPT                   │
    │     Update rubric:                       │
    │     "Don't penalize concise answers      │
    │      if they're complete"                │
    │            │                             │
    │            ↓                             │
    │  ⑧ RE-TEST ALIGNMENT                     │
    │     ┌────────────────────────┐           │
    │     │ Alignment: 88% ✓       │  > 85%    │
    │     │ Judge is ready!        │           │
    │     └────────────────────────┘           │
    │                                          │
    └──────────────────────────────────────────┘
                     │
                     ↓
    ┌──────────────────────────────────────────┐
    │  JUDGE IS NOW CALIBRATED                 │
    │  Can be used for automated scoring       │
    └──────────────────────────────────────────┘
                     │
                     │
    PHASE 2: Continuous Judge Improvement (Ongoing) - 🆕 2025 UPDATES
    ┌──────────────────────────────────────────┐
    │                                          │
    │  ⑨ MONITOR PRODUCTION SCORING            │
    │     🆕 CONFIDENCE-BASED SAMPLING         │
    │     ┌────────────────────────┐           │
    │     │ Judge scores output    │           │
    │     │ AND reports:           │           │
    │     │ • Score: 0.65          │           │
    │     │ • Confidence: 0.45 ⚠️  │  < 0.7    │
    │     │   (LOW CONFIDENCE!)    │           │
    │     └───────────┬────────────┘           │
    │                 │                        │
    │                 ↓                        │
    │  ⑩ INTELLIGENT ROUTING                   │
    │     ┌────────────────────────┐           │
    │     │ IF confidence > 0.7:   │           │
    │     │   → Trust AI judge     │           │
    │     │                        │           │
    │     │ IF confidence < 0.7:   │           │
    │     │   → Send to human      │           │
    │     │      review queue      │           │
    │     └───────────┬────────────┘           │
    │                 │                        │
    │                 ↓                        │
    │  ⑪ ADD CORRECTIONS TO GOLDEN DATASET     │
    │     🆕 FEW-SHOT AUTO-LEARNING            │
    │     ┌────────────────────────┐           │
    │     │ Human correction       │           │
    │     │ automatically becomes  │           │
    │     │ few-shot example       │           │
    │     │ in judge prompt        │           │
    │     └───────────┬────────────┘           │
    │                 │                        │
    │                 ↓                        │
    │  ⑫ JUDGE AUTO-IMPROVES                   │
    │     🆕 SELF-IMPROVING WITHOUT RETRAINING │
    │     Self-improving evaluators            │
    │     learn from corrections               │
    │     without manual prompting             │
    │     or model fine-tuning                 │
    │                                          │
    └──────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│  🆕 SELF-TAUGHT EVALUATORS (NO HUMAN ANNOTATIONS!)         │
└──────────────────────────────────────────────────────────────────────────────┘

    FULLY AUTOMATED JUDGE TRAINING (Research: 75.4% → 88.3% alignment)
    ┌──────────────────────────────────────────┐
    │                                          │
    │  ① GENERATE SYNTHETIC TRAINING DATA      │
    │     ┌────────────────────────┐           │
    │     │ LLM generates:         │           │
    │     │ • Good response A      │           │
    │     │ • Bad response B       │           │
    │     │ • Contrasting pair     │           │
    │     └───────────┬────────────┘           │
    │                 │                        │
    │                 ↓                        │
    │  ② TRAIN JUDGE ON SYNTHETIC DATA         │
    │     ┌────────────────────────┐           │
    │     │ Judge learns to:       │           │
    │     │ • Produce reasoning    │           │
    │     │ • Make judgments       │           │
    │     │ • Identify quality     │           │
    │     └───────────┬────────────┘           │
    │                 │                        │
    │                 ↓                        │
    │  ③ ITERATIVE SELF-IMPROVEMENT            │
    │     ┌────────────────────────┐           │
    │     │ Generate more examples │           │
    │     │ → Judge evaluates      │           │
    │     │ → Improve judge        │           │
    │     │ → Repeat               │           │
    │     └───────────┬────────────┘           │
    │                 │                        │
    │                 ↓                        │
    │  ④ READY FOR PRODUCTION                  │
    │     Judge achieves 88.3% alignment       │
    │     WITHOUT any human labels!            │
    │                                          │
    └──────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│  💡 RECOMMENDED APPROACH: HYBRID (Best of Both Worlds)                  │
└──────────────────────────────────────────────────────────────────────────────┘

    ① Start with 15-20 human annotations (not 50-100!)
    ② Bootstrap judge to ~75% alignment
    ③ Switch to self-improvement with synthetic data
    ④ Use confidence-based sampling for edge cases
    ⑤ Achieve 85%+ alignment with minimal human effort

    COST COMPARISON:
    • Traditional RLHF: $10,000+ in human annotations
    • Hybrid 2025:     $500-1,000 (15-20 examples)
    • Self-Taught:     $0 (fully automated)

    QUALITY COMPARISON:
    • Traditional RLHF: 85-90% alignment
    • Hybrid 2025:      85-88% alignment (recommended!)
    • Self-Taught:      83-88% alignment

═══════════════════════════════════════════════════════════════════════════════
LOOP B: TRAIN THE AGENT (CONTINUOUS - REQUIRES CALIBRATED JUDGE)
═══════════════════════════════════════════════════════════════════════════════

    STAGE 1: IDEATION & EXECUTION
    ┌─────────────────────────────────────────┐
    │                                         │
    │  ① GENERATE NEW IDEA                    │
    │     "What if I change the prompt        │
    │      to be more specific?"              │
    │            │                            │
    │            ↓                            │
    │  ② MAKE THE CHANGE                      │
    │     ┌─────────────────────┐             │
    │     │  New System Prompt  │             │
    │     │  Version 2.0        │             │
    │     └──────────┬──────────┘             │
    │                │                        │
    │                ↓                        │
    │  ③ RUN EVALUATION TESTS                 │
    │     ┌─────────────────────┐             │
    │     │ Agent executes      │             │
    │     │ test queries        │             │
    │     └──────────┬──────────┘             │
    │                │                        │
    └────────────────┼────────────────────────┘
                     │
                     ↓ [outputs]

    STAGE 2: AUTOMATED SCORING
    ┌─────────────────────────────────────────┐
    │                                         │
    │  ④ SCORE EACH OUTPUT                    │
    │                                         │
    │     ┌──────────────┐  ┌──────────────┐  │
    │     │ LLM-as-Judge │  │ Human Expert │  │
    │     │ (Automated)  │  │ (Calibration)│  │
    │     └───────┬──────┘  └──────┬───────┘  │
    │             └─────────────────┘          │
    │                     │                    │
    │                     ↓                    │
    │     ┌───────────────────────────┐        │
    │     │      SCORE RESULTS        │        │
    │     │  ┌────────────────┐       │        │
    │     │  │ correctness: 0.8  ✓    │        │
    │     │  │ completeness: 0.4  ✗   │ < 0.7  │
    │     │  │ business_ctx: 0.7  ✓   │        │
    │     │  │ specificity: 0.2   ✗   │ < 0.7  │
    │     │  └────────────────┘       │        │
    │     └───────────┬───────────────┘        │
    │                 │                        │
    └─────────────────┼────────────────────────┘
                      │
                      ↓ [filter failures]

    STAGE 3: FAILURE ANALYSIS & LEARNING
    ┌─────────────────────────────────────────┐
    │                                         │
    │  ⑤ FILTER POOR SCORES (< 0.7)           │
    │     ┌─────────────────────┐             │
    │     │  FAILURE DATASET    │             │
    │     │  ─────────────────  │             │
    │     │  • Query X:         │             │
    │     │    completeness=0.4 │             │
    │     │    specificity=0.2  │             │
    │     │                     │             │
    │     │  • Original output  │             │
    │     │  • Judge feedback   │             │
    │     │  • Expected quality │             │
    │     └──────────┬──────────┘             │
    │                │                        │
    │                ↓                        │
    │  ⑥ OPTIMIZE PROMPT                      │
    │     "Analyze failures, propose          │
    │      improvements"                      │
    │     ┌─────────────────────┐             │
    │     │  Meta-Engineer LLM  │             │
    │     │  reads failures &   │             │
    │     │  suggests changes   │             │
    │     └──────────┬──────────┘             │
    │                │                        │
    │                ↓                        │
    │     ┌─────────────────────┐             │
    │     │ IMPROVED PROMPT     │             │
    │     │ Version 3.0         │             │
    │     │ "Now includes       │             │
    │     │  specific details"  │             │
    │     └──────────┬──────────┘             │
    │                │                        │
    └────────────────┼────────────────────────┘
                     │
                     ↓
    STAGE 4: DEPLOYMENT & PRODUCTION
    ┌─────────────────────────────────────────┐
    │                                         │
    │  ⑦ DEPLOY TO PRODUCTION                 │
    │     ┌─────────────────────┐             │
    │     │  Replace old prompt │             │
    │     │  with new version   │             │
    │     └──────────┬──────────┘             │
    │                │                        │
    │                ↓                        │
    │  ⑧ MONITOR REAL ACTIVITY                │
    │     ┌─────────────────────┐             │
    │     │ Production traffic  │             │
    │     │ generates new       │             │
    │     │ evaluation data     │             │
    │     └──────────┬──────────┘             │
    │                │                        │
    └────────────────┼────────────────────────┘
                     │
                     └────────────┐
                                  │
         ┌────────────────────────┘
         │ LOOP BACK TO ①
         └──▶ "Generate next idea based on new data"


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
LEGEND:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ① ② ③ ...        Sequential steps in the workflow

  ✓                Score above threshold (0.7) - PASS
  ✗                Score below threshold (0.7) - FAIL

  LLM-as-Judge     Automated AI evaluator (AF = AI Feedback)
  Human Expert     Subject matter expert (HF = Human Feedback)

  Failure Dataset  Collection of poor-scoring examples used for training
  Meta-Engineer    LLM that analyzes failures and proposes prompt improvements

  0.7 Threshold    Minimum acceptable score across all dimensions
                   (correctness, completeness, business_context, specificity)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
WHY THIS WORKS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The system improves because:

  1. FAILURES ARE DATA: Every poor score becomes a training example
  2. AUTOMATED FEEDBACK: LLM-as-Judge provides instant, scalable evaluation
  3. HUMAN CALIBRATION: Experts ensure the AI judge aligns with real quality
  4. ITERATIVE REFINEMENT: Each cycle produces measurably better prompts
  5. PRODUCTION LEARNING: Real user interactions continuously improve the system

Traditional approach: Human manually tweaks prompts → Slow, limited exploration
This approach:       AI explores prompt space systematically → Fast, thorough

```

#### **4-Step Workflow with Detailed Execution Flow**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    CONTINUOUS IMPROVEMENT WORKFLOW                           │
└─────────────────────────────────────────────────────────────────────────────┘

    ┌──────────────────┐
    │   STEP 0:        │
    │   Run Evals      │──────┐
    │   (Auto Score)   │      │
    └──────────────────┘      │
            │                 │
            │ Scores stored   │
            │ in LangSmith/   │
            │ Langfuse        │
            ▼                 │
    ┌──────────────────┐      │
    │   STEP 1:        │      │
    │   Query Poor     │      │    ┌─────────────────────────────┐
    │   Scores         │      │    │  Evaluation Dimensions:     │
    │   (< 0.7)        │      │    │  • Correctness              │
    └──────────────────┘      │    │  • Completeness             │
            │                 │    │  • Business Context         │
            │ Failure cases   │    │  • Specificity              │
            │ identified      │    └─────────────────────────────┘
            ▼                 │
    ┌──────────────────┐      │
    │   STEP 2:        │      │
    │   Create         │      │
    │   Failure        │      │
    │   Dataset        │      │
    └──────────────────┘      │
            │                 │
            │ Dataset with    │
            │ poor examples   │
            ▼                 │
    ┌──────────────────┐      │
    │   STEP 3:        │      │
    │   Optimize       │      │
    │   Prompt         │      │
    │   (Iterative)    │      │
    └──────────────────┘      │
            │                 │
            │ Improved        │
            │ prompt          │
            ▼                 │
    ┌──────────────────┐      │
    │   Deploy to      │      │
    │   Production     │      │
    └──────────────────┘      │
            │                 │
            └─────────────────┘
            Loop back to Step 0

```

#### **Implementation**

The complete 4-step workflow is implemented in the companion notebook `app/evaluation/self_improving_agent_workflow.ipynb`. Each step is detailed below with conceptual guidance.

#### **Step 0: Automatic Scoring with Sampling**

In production, the evaluation system runs continuously in the background, automatically scoring a sample of live agent responses. Not every interaction needs to be evaluated—this would be costly and unnecessary. Instead, implement a **sampling rate** to balance cost and coverage (e.g., evaluate 10% of production traffic).

The evaluation framework supports four dimensions:
- **Correctness**: Does the response accurately address the query?
- **Completeness**: Does the response include all expected information?
- **Business Context**: Does the response frame findings in business terms (impact, ROI, priorities)?
- **Specificity**: Does the response provide specific, actionable guidance from detected opportunities rather than generic instructions?

Each dimension is scored from 0.0 to 1.0, with detailed reasoning provided by the LLM judge. These scores and reasoning traces are automatically sent to both Langfuse and LangSmith (if dual-tracing is enabled), providing rich observability into agent quality over time.

**Implementation:** See the companion notebook `app/evaluation/self_improving_agent_workflow.ipynb` for the complete implementation with sampling configuration.

#### **Step 1: Query for Poor Scores**

Once evaluation data has accumulated, the next step is to systematically identify failure cases. A **poor score** is defined as any evaluation dimension scoring **below 0.7**. This threshold represents the boundary between acceptable and unacceptable performance.

Both Langfuse and LangSmith provide APIs and web UIs for querying traces by score. The goal of this step is to gather a representative set of failure cases—typically 50-100 examples per failure mode—that will form the basis for the next improvement iteration.

**Implementation:** See the companion notebook `app/evaluation/self_improving_agent_workflow.ipynb` for examples of querying poor scores from both platforms.

#### **Step 2: Create a New Dataset**

Once poor-performing traces have been identified, they are converted into a structured **dataset** for systematic improvement. The evaluation framework's dataset providers support creating new datasets programmatically.

This dataset becomes the **training set** for the optimization loop. It represents the agent's current weaknesses and provides concrete examples that the optimization process will use to refine the agent's system prompt.

**Implementation:** See the companion notebook `app/evaluation/self_improving_agent_workflow.ipynb` for examples of creating failure datasets programmatically.

#### **Step 3: Iterative Prompt Improvement Until Convergence**

With a failure-focused dataset in hand, the optimization engine can now run iteratively to improve the agent's prompt. This is implemented using the **Generator-Critic Loop** pattern in LangGraph (as detailed in earlier sections).

The optimization process follows this logic:

1. **Baseline Evaluation**: Run the current agent prompt against the entire failure dataset and compute average scores

2. **Propose Improvement**: Use an LLM "meta-engineer" to analyze failures and propose a refined prompt
   - The meta-engineer receives the current prompt, failed outputs, and judge feedback
   - It proposes specific modifications (e.g., "Add explicit instruction to reference opportunity system findings")

3. **Test Candidate**: Run the updated prompt against the same dataset

4. **Decide Next Action**: Compare the new score to the baseline
   - **If improved significantly** (e.g., +0.15 or more): Accept the new prompt and continue iterating
   - **If improved marginally** (e.g., +0.05): Accept but consider stopping if subsequent iterations show diminishing returns
   - **If degraded**: Reject the change and try a different approach

5. **Convergence Check**: Stop when one of these conditions is met:
   - Average score exceeds 0.7 (success threshold)
   - Improvement between iterations drops below 0.05 (diminishing returns)
   - Maximum iteration count reached (e.g., 5 iterations)

The final, optimized prompt becomes the new production prompt for the agent.

**Implementation:** See the companion notebook `app/evaluation/self_improving_agent_workflow.ipynb` for the complete iterative optimization implementation with convergence logic and example trajectories.

### **Integration with Existing System Architecture**

This four-step workflow integrates seamlessly with the LangGraph-based optimization architecture detailed earlier in this document:

- **Step 0 (Automatic Scoring)** is handled by the `Evaluation` running as a background process on sampled production traffic
- **Step 1 (Query Poor Scores)** uses the Langfuse or LangSmith APIs to identify failure cases
- **Step 2 (Create Dataset)** uses the `DatasetProvider` abstraction to programmatically build failure-focused training sets
- **Step 3 (Iterative Improvement)** is implemented as the `Optimization` using the Generator-Critic loop in LangGraph

The key insight is that this is a **continuous loop**: as the agent encounters new edge cases in production, Step 0 identifies them, Steps 1-2 curate them into datasets, and Step 3 refines the prompt. The improved prompt is deployed back to production, where Step 0 monitors its performance, and the cycle continues.

### **Expected Outcomes and ROI**

This automated score-driven improvement workflow delivers several key benefits:

1. **Systematic Quality Improvement**: Agent quality increases incrementally over time without manual prompt engineering
2. **Rapid Iteration**: The optimization loop can run nightly or weekly, continuously adapting to new failure modes
3. **Data-Driven Decisions**: Every prompt change is backed by quantitative evaluation data, eliminating guesswork
4. **Failure Case Coverage**: By converting production failures into training datasets, the system systematically eliminates weaknesses
5. **Reduced Manual Labor**: What previously required hours of manual prompt tweaking now runs automatically

In practice, this workflow has demonstrated the ability to improve agent scores from baseline levels (0.3-0.4) to production-ready levels (0.7+) within 3-5 optimization iterations, typically completing in under 2 hours of compute time.

## **Alternative Approaches Not Implemented**

The current implementation uses LangGraph as the optimization framework. During the research phase, several alternative approaches were explored but ultimately not selected for implementation, including:

- **langmem:** Direct prompt optimization library from LangChain
- **CrewAI train feature:** Human-in-the-loop guided improvement
- **DSPy:** Declarative self-improving Python framework

These alternative approaches and the rationale for not selecting them are documented in detail in [alternative-optimization-approaches.md](alternative-optimization-approaches.md).

## **Advanced Concepts and Future Trajectories**

The framework detailed in this report provides a powerful and practical solution for today's agent development challenges. However, the field of agentic AI is advancing at a rapid pace, and it is valuable to understand the future trajectories of this research. The concepts of offline prompt optimization are evolving towards more dynamic, online, and open-ended forms of learning.

### **Exploring Test-Time Self-Improvement (TT-SI)**

The architecture described in this report focuses on an *offline* optimization process: the system iterates on a prompt to find a generally optimal version, which is then deployed. This is the recommended and most robust approach for your stated goal of improving the quality of your existing agents.

However, for the sake of exploring the research frontier, an emerging and more advanced paradigm is **Test-Time Self-Improvement (TT-SI)**. This approach is distinct from offline optimization; it enables an agent to improve its performance *on-the-fly* for a single, particularly challenging task at the moment of inference.45 This is less about creating one perfect, static prompt and more about giving the agent the ability to "cram" for a test it realizes it's unprepared for.

The traditional method of fine-tuning LMs relies on creating massive, diverse training datasets, which is prohibitively expensive and inefficient.45 This process often wastes resources training the model on redundant information it has already mastered.45 TT-SI offers a different path by focusing on "local" or "instance-specific" learning, adapting only when faced with a novel challenge.46

The TT-SI algorithm is often compared to the metacognitive reflection of a human student encountering a difficult problem.46 The process can be summarized in three steps 45:

1. **Self-Awareness (Metacognition):** The agent first uses an "uncertainty estimator" to identify if the current task is a sample it is likely to struggle with.46 This "self-awareness" allows it to strategically identify gaps in its knowledge, rather than wasting time on problems it has already mastered.45  
2. **Self-Data Augmentation:** Once an uncertain or challenging task is identified, the agent's data synthesis function generates one or more similar, "distributionally similar" examples to practice on.46 This is analogous to a student finding related problems in a textbook to understand a specific concept before an exam.46  
3. **Self-Improvement (Test-Time Fine-Tuning):** The agent performs a temporary, lightweight fine-Tuning update on itself using *only* these newly generated practice examples.45 This is often accomplished using Parameter Efficient Fine-Tuning (PEFT) techniques.46 This temporary adaptation makes the agent better equipped to handle the original, difficult task it was first presented with.

Research into this method has explored two main variants: true **TT-SI**, where the model generates its *own* practice examples to learn from, and **Test-Time Distillation (TT-D)**, where a separate, stronger "teacher" model generates the practice examples for the agent to learn from.45

The results of this approach are promising, with studies showing significant improvements in agent performance (e.g., an average \+5.48% absolute accuracy gain on some benchmarks) while using substantially less training data (up to 68 times less) than standard learning methods.45 This highlights the potential of self-improving algorithms as a new paradigm for building more capable, adaptive agents in the future.45

### **The Frontier: Multi-Agent Co-evolution and Open-Ended Learning**

The ultimate vision for agentic AI extends beyond optimizing performance on a fixed set of tasks. The frontier of research lies in creating systems capable of **open-ended learning**, where agents can autonomously generate their own curriculum of increasingly complex problems and improve their capabilities in a continuous, upward spiral.

Recent frameworks like **Multi-Agent Evolve (MAE)** showcase this potential. MAE employs a triplet of interacting agents, all instantiated from the same base LLM: a **Proposer** that generates new questions, a **Solver** that attempts to answer them, and a **Judge** that evaluates both the quality of the question and the solution.43 These three agents co-evolve through reinforcement learning; as the Solver gets better, the Proposer must generate harder questions to challenge it, and the Judge must become more discerning to provide a useful learning signal. This creates a virtuous cycle of self-improvement without any reliance on human-curated datasets.43

This approach of multi-role co-evolution within a closed loop represents a scalable path toward building agents that do not just master predefined tasks but can continuously expand the boundary of their own competence. While still an active area of research, these concepts highlight the long-term trajectory of agentic systems: from manually engineered tools to autonomously self-improving and, eventually, open-endedly creative intelligences.

#### **Works cited**

1. Exploring Prompt Optimization \- LangChain Blog, accessed October 31, 2025, [https://blog.langchain.com/exploring-prompt-optimization/](https://blog.langchain.com/exploring-prompt-optimization/)  
2. Prompt Optimization with DSPy: GEPA Explained with Python Examples | by Melike Nur Erdoğan | Sep, 2025, accessed October 31, 2025, [https://medium.com/@melikedulkadir/prompt-optimization-with-dspy-gepa-explained-with-python-examples-e85f4ea17a8d](https://medium.com/@melikedulkadir/prompt-optimization-with-dspy-gepa-explained-with-python-examples-e85f4ea17a8d)  
3. mengdi-li/awesome-RLAIF: A continually updated list of literature on Reinforcement Learning from AI Feedback (RLAIF) \- GitHub, accessed October 31, 2025, [https://github.com/mengdi-li/awesome-RLAIF](https://github.com/mengdi-li/awesome-RLAIF)  
4. Reinforcement learning from AI feedback (RLAIF): Complete overview \- SuperAnnotate, accessed October 31, 2025, [https://www.superannotate.com/blog/reinforcement-learning-from-ai-feedback-rlaif](https://www.superannotate.com/blog/reinforcement-learning-from-ai-feedback-rlaif)  
5. Can someone explain how Agentic AI differs to Agents Trained Using RL To Someone Who Knows RL Very Well? : r/ArtificialInteligence \- Reddit, accessed October 31, 2025, [https://www.reddit.com/r/ArtificialInteligence/comments/1nolp74/can\_someone\_explain\_how\_agentic\_ai\_differs\_to/](https://www.reddit.com/r/ArtificialInteligence/comments/1nolp74/can_someone_explain_how_agentic_ai_differs_to/)  
6. Agents \- CrewAI Documentation, accessed October 31, 2025, [https://docs.crewai.com/en/concepts/agents](https://docs.crewai.com/en/concepts/agents)  
7. Self-Evolving LLM Agents \- Emergent Mind, accessed October 31, 2025, [https://www.emergentmind.com/topics/self-evolving-llm-agents](https://www.emergentmind.com/topics/self-evolving-llm-agents)  
8. \[2509.19199\] Agentic Reinforcement Learning with Implicit Step Rewards \- arXiv, accessed October 31, 2025, [https://arxiv.org/abs/2509.19199](https://arxiv.org/abs/2509.19199)  
9. How to Implement Reinforcement Learning from AI Feedback (RLAIF) \- Labelbox, accessed October 31, 2025, [https://labelbox.com/guides/reinforcement-learning-from-ai-feedback-rlaif/](https://labelbox.com/guides/reinforcement-learning-from-ai-feedback-rlaif/)  
10. RLAIF: What is Reinforcement Learning From AI Feedback? \- DataCamp, accessed October 31, 2025, [https://www.datacamp.com/blog/rlaif-reinforcement-learning-from-ai-feedback](https://www.datacamp.com/blog/rlaif-reinforcement-learning-from-ai-feedback)  
11. Scaling Evaluation with LLM Judges: Our Approach and Findings | by Nayeem Islam | Sep, 2025, accessed October 31, 2025, [https://medium.com/@nomannayeem/scaling-evaluation-with-llm-judges-our-approach-and-findings-0a046e8344c4](https://medium.com/@nomannayeem/scaling-evaluation-with-llm-judges-our-approach-and-findings-0a046e8344c4)  
12. LLM-as-a-judge: a complete guide to using LLMs for evaluations \- Evidently AI, accessed October 31, 2025, [https://www.evidentlyai.com/llm-guide/llm-as-a-judge](https://www.evidentlyai.com/llm-guide/llm-as-a-judge)  
13. LLM-as-a-Judge: A Practical Guide | Towards Data Science, accessed October 31, 2025, [https://towardsdatascience.com/llm-as-a-judge-a-practical-guide/](https://towardsdatascience.com/llm-as-a-judge-a-practical-guide/)  
14. A Deep Dive into LangGraph for Self-Correcting AI Agents | ActiveWizards, accessed October 31, 2025, [https://activewizards.com/blog/a-deep-dive-into-langgraph-for-self-correcting-ai-agents](https://activewizards.com/blog/a-deep-dive-into-langgraph-for-self-correcting-ai-agents)  
15. LLM-as-a-Judge: The Scalable Solution to AI Evaluation Challenges, accessed October 31, 2025, [https://prabhakar-borah.medium.com/llm-as-a-judge-the-scalable-solution-to-ai-evaluation-challenges-14c3d98a6256](https://prabhakar-borah.medium.com/llm-as-a-judge-the-scalable-solution-to-ai-evaluation-challenges-14c3d98a6256)  
16. Self-improving LLM evaluators in LangSmith \- LangChain \- Changelog, accessed October 31, 2025, [https://changelog.langchain.com/announcements/self-improving-llm-evaluators-in-langsmith](https://changelog.langchain.com/announcements/self-improving-llm-evaluators-in-langsmith)  
17. Introducing Align Evals: Streamlining LLM Application Evaluation \- LangChain Blog, accessed October 31, 2025, [https://blog.langchain.com/introducing-align-evals/](https://blog.langchain.com/introducing-align-evals/)  
18. Improve LLM-as-judge evaluators using human feedback \- Docs by ..., accessed October 31, 2025, [https://docs.langchain.com/langsmith/improve-judge-evaluator-feedback](https://docs.langchain.com/langsmith/improve-judge-evaluator-feedback)  
19. Evaluation \- LangChain, accessed October 31, 2025, [https://www.langchain.com/langsmith/evaluation](https://www.langchain.com/langsmith/evaluation)  
20. Introducing Align Evals: Streamlining LLM Application Evaluation \- YouTube, accessed October 31, 2025, [https://www.youtube.com/watch?v=-9o94oj4x0A](https://www.youtube.com/watch?v=-9o94oj4x0A)  
21. Corrections \+ Few Shot Examples (Part 1\) | LangSmith Evaluations \- YouTube, accessed October 31, 2025, [https://www.youtube.com/watch?v=3gCTa0Li4ew](https://www.youtube.com/watch?v=3gCTa0Li4ew)  
22. Aligning LLM-as-a-Judge with Human Preferences \- LangChain Blog, accessed October 31, 2025, [https://blog.langchain.com/aligning-llm-as-a-judge-with-human-preferences/](https://blog.langchain.com/aligning-llm-as-a-judge-with-human-preferences/)  
23. LLM Evaluation Frameworks: Head-to-Head Comparison \- Comet, accessed October 31, 2025, [https://www.comet.com/site/blog/llm-evaluation-frameworks/](https://www.comet.com/site/blog/llm-evaluation-frameworks/)  
24. Top 6 Open Source LLM Evaluation Frameworks : r/LLMDevs \- Reddit, accessed October 31, 2025, [https://www.reddit.com/r/LLMDevs/comments/1i6r1h9/top\_6\_open\_source\_llm\_evaluation\_frameworks/](https://www.reddit.com/r/LLMDevs/comments/1i6r1h9/top_6_open_source_llm_evaluation_frameworks/)  
25. LangGraph \- LangChain, accessed October 31, 2025, [https://www.langchain.com/langgraph](https://www.langchain.com/langgraph)  
26. LangGraph — Build Self-Improving Agents | by Shuvrajyoti Debroy | Medium, accessed October 31, 2025, [https://medium.com/@shuv.sdr/langgraph-build-self-improving-agents-8ffefb52d146](https://medium.com/@shuv.sdr/langgraph-build-self-improving-agents-8ffefb52d146)  
27. Reflection Agents \- LangChain Blog, accessed October 31, 2025, [https://blog.langchain.com/reflection-agents/](https://blog.langchain.com/reflection-agents/)  
28. Prompt Optimization API Reference, accessed October 31, 2025, [https://langchain-ai.github.io/langmem/reference/prompt\_optimization/](https://langchain-ai.github.io/langmem/reference/prompt_optimization/)  
29. How to Optimize a Prompt, accessed October 31, 2025, [https://langchain-ai.github.io/langmem/guides/optimize\_memory\_prompt/](https://langchain-ai.github.io/langmem/guides/optimize_memory_prompt/)  
30. Building a Self-Learning AI Marketing Agent with LangMem \+ LangGraph (Part 2\) | by Reelfy, accessed October 31, 2025, [https://pub.towardsai.net/building-a-self-learning-ai-marketing-agent-with-langmem-langgraph-part-2-787639c53947](https://pub.towardsai.net/building-a-self-learning-ai-marketing-agent-with-langmem-langgraph-part-2-787639c53947)  
31. LangMem SDK for agent long-term memory \- LangChain Blog, accessed October 31, 2025, [https://blog.langchain.com/langmem-sdk-launch/](https://blog.langchain.com/langmem-sdk-launch/)  
32. Training \- CrewAI Documentation, accessed October 31, 2025, [https://docs.crewai.com/en/concepts/training](https://docs.crewai.com/en/concepts/training)  
33. Mastering CrewAI: Chapter 5— Train, Test, Replay & Plan | by Okan Yenigün, accessed October 31, 2025, [https://ai.plainenglish.io/mastering-crewai-chapter-5-train-test-replay-plan-024d81e265ee](https://ai.plainenglish.io/mastering-crewai-chapter-5-train-test-replay-plan-024d81e265ee)  
34. Programming, Not Prompting: A Hands-on Guide to DSPy, accessed October 31, 2025, [https://miptgirl.medium.com/programming-not-prompting-a-hands-on-guide-to-dspy-04ea2d966e6d](https://miptgirl.medium.com/programming-not-prompting-a-hands-on-guide-to-dspy-04ea2d966e6d)  
35. Optimizers \- DSPy, accessed October 31, 2025, [https://dspy.ai/learn/optimization/optimizers/](https://dspy.ai/learn/optimization/optimizers/)  
36. Thoughts on DSPy : r/LangChain \- Reddit, accessed October 31, 2025, [https://www.reddit.com/r/LangChain/comments/1cqexk6/thoughts\_on\_dspy/](https://www.reddit.com/r/LangChain/comments/1cqexk6/thoughts_on_dspy/)  
37. How to create tools \- Install LangChain, accessed October 31, 2025, [https://python.langchain.com/docs/how\_to/custom\_tools/](https://python.langchain.com/docs/how_to/custom_tools/)  
38. dspy.Tool, accessed October 31, 2025, [https://dspy.ai/api/primitives/Tool/](https://dspy.ai/api/primitives/Tool/)  
39. Building Agents: Self-Improving Prompt Engineering Agent that Runs Evals and Iterates on a Prompt \- YouTube, accessed October 31, 2025, [https://www.youtube.com/watch?v=6Q8xeQLqRE8](https://www.youtube.com/watch?v=6Q8xeQLqRE8)  
40. LangSmith docs \- Docs by LangChain, accessed October 31, 2025, [https://docs.langchain.com/langsmith/home](https://docs.langchain.com/langsmith/home)  
41. LangSmith \- Observability \- LangChain, accessed October 31, 2025, [https://www.langchain.com/langsmith/observability](https://www.langchain.com/langsmith/observability)  
42. A Guide to LangGraph and LangSmith for Building AI Agents \- Analytics Vidhya, accessed October 31, 2025, [https://www.analyticsvidhya.com/blog/2025/10/a-guide-to-langgraph-and-langsmith-for-building-ai-agents/](https://www.analyticsvidhya.com/blog/2025/10/a-guide-to-langgraph-and-langsmith-for-building-ai-agents/)  
43. \[2510.23595\] Multi-Agent Evolve: LLM Self-Improve through Co-evolution \- arXiv, accessed October 31, 2025, [https://arxiv.org/abs/2510.23595](https://arxiv.org/abs/2510.23595)  
44. \[2510.14253\] Towards Agentic Self-Learning LLMs in Search Environment \- arXiv, accessed October 31, 2025, [https://www.arxiv.org/abs/2510.14253](https://www.arxiv.org/abs/2510.14253)  
45. \[2510.07841\] Self-Improving LLM Agents at Test-Time \- arXiv, accessed October 31, 2025, [https://arxiv.org/abs/2510.07841](https://arxiv.org/abs/2510.07841)  
46. Self-Improving LLM Agents at Test-Time \- arXiv, accessed October 31, 2025, [https://arxiv.org/html/2510.07841v1](https://arxiv.org/html/2510.07841v1)
---

## Practical Implementation in This Codebase

This section documents the actual implementation of the self-improving AI agents framework within this codebase.

### Implementation Overview

We have implemented **two optimization systems** to support different agent frameworks:

1. **LangGraph Agent Optimizer** (`app/evaluation/prompt_optimizer_langgraph.py`)
   - For single-agent LangGraph workflows
   - Optimizes inline `system_prompt` in Python files
   - Uses regex-based extraction and replacement

2. **CrewAI Crew Optimizer** (`app/evaluation/prompt_optimizer_crewai.py`)
   - For multi-agent CrewAI workflows  
   - Optimizes both agents (goal, backstory) and tasks (description, expected_output)
   - Uses YAML configuration files
   - Performs holistic optimization ensuring agent-task coherence

Both systems follow the same architectural pattern:
- **Execution**: Run agent/crew on evaluation dataset
- **Evaluation**: Score outputs using EvaluationPipeline + Langfuse
- **Optimization**: LangGraph workflow that iteratively improves prompts

### Dataset Creation from Multiple Sources

Our dataset creation pipeline combines four key data sources to create comprehensive evaluation datasets:

#### 1. Production Traces (Langfuse)
Real user interactions automatically collected during production usage:
```python
# Production traces are automatically logged to Langfuse
# Query them for dataset creation:
from langfuse import Langfuse

client = Langfuse()
traces = client.fetch_traces(
    name="agent_execution",
    from_timestamp=datetime.now() - timedelta(days=30)
)
```

#### 2. Customer Feedback
User feedback attached directly to traces in Langfuse:
- Thumbs up/down ratings
- Free-text comments
- Bug reports

Users can provide feedback via the UI, which gets linked to specific traces.

#### 3. Human Annotations
QA team and domain experts review traces and add:
- Quality scores (0-100)
- Expected outputs (ground truth)
- Error categorization
- Severity assessments

```python
# Add human annotation to a trace
client.score(
    trace_id="trace_abc123",
    name="quality_score",
    value=85,
    comment="Good response but missed one edge case"
)
```

#### 4. PM Requirements
Product specifications defining:
- Required features
- Edge cases to handle
- Quality thresholds
- Success criteria

These are translated into synthetic test cases that ensure all requirements are covered.

#### Complete Dataset Builder Example

See `app/evaluation/examples/create_contextual_greeter_dataset.py` for a working example:

```python
from langfuse import Langfuse

client = Langfuse()
dataset = client.create_dataset(name="contextual_greeter_dataset")

# Combine data from all sources
for item in combined_dataset_items:
    client.create_dataset_item(
        dataset_name="contextual_greeter_dataset",
        input=item["input"],
        expected_output=item["expected_output"],
        metadata={
            "source": item["source"],  # production_trace, pm_requirement, etc.
            "trace_id": item.get("trace_id"),
            "feedback_score": item.get("feedback_score"),
            "quality_score": item.get("quality_score"),
            "requirement_id": item.get("requirement_id")
        }
    )
```

### Running CrewAI Optimization

Example workflow for optimizing a CrewAI crew:

```bash
# 1. Create evaluation dataset (if not exists)
export PYTHONPATH=$PYTHONPATH:./app
uv run python app/evaluation/examples/create_contextual_greeter_dataset.py

# 2. Run the optimizer
uv run python app/evaluation/examples/test_contextual_greeter_optimizer.py
```

The optimizer will:
1. Load current agent and task prompts from YAML files
2. Execute crew on dataset and evaluate with Langfuse
3. Analyze performance dimensions below threshold
4. Use GPT-4 to propose improved prompts
5. Test improvements and iterate
6. Save best prompts back to YAML files

### Continuous Improvement Loop

The complete flow creates a continuous improvement cycle:

```
┌─────────────────────────────────────────────────────────┐
│                Production Environment                    │
│  • Users interact with AI agents                        │
│  • Traces logged to Langfuse                            │
│  • Feedback collected                                   │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│           Dataset Builder (Weekly/On-Demand)            │
│  • Query production traces from Langfuse                │
│  • Collect customer feedback                            │
│  • Add human annotations from QA                        │
│  • Include PM requirements for new features             │
│  • Generate/update evaluation dataset                   │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│        Prompt Optimization (Automated/Triggered)        │
│  • Run CrewAI/LangGraph optimizer                       │
│  • Evaluate on latest dataset                           │
│  • Iteratively improve prompts                          │
│  • Save optimized configuration                         │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│             Deploy Updated Agents                        │
│  • Review optimization results                          │
│  • Deploy improved prompts to staging                   │
│  • A/B test if desired                                  │
│  • Roll out to production                               │
└────────────────────┬────────────────────────────────────┘
                     │
                     └──────────────┐
                                    │ Loop continues
                                    ▼
                        Back to Production Environment
```

### File Structure

```
app/evaluation/
├── prompt_optimizer_crewai.py          # CrewAI optimizer implementation
├── prompt_optimizer_langgraph.py       # LangGraph optimizer implementation
├── pipeline.py                         # Shared EvaluationPipeline
├── PROMPT_OPTIMIZATION.md             # Technical documentation
├── unified_optimization_flow.md        # System diagram with data flow
├── examples/
│   ├── create_contextual_greeter_dataset.py
│   ├── demo_contextual_greeter_inputs.py
│   └── test_contextual_greeter_optimizer.py
└── ...

docs/evals/
└── self-improving-ai-agents.md         # This document

app/agents/crews/
├── contextual_greeter/
│   ├── config/
│   │   ├── agents.yaml                 # Optimized by CrewAI optimizer
│   │   └── tasks.yaml                  # Optimized by CrewAI optimizer
│   └── ...
└── ...
```

### Key Implementation Files

- **`prompt_optimizer_crewai.py`**: 682 lines implementing holistic agent+task optimization for CrewAI
- **`prompt_optimizer_langgraph.py`**: Single-agent prompt optimization for LangGraph agents
- **`pipeline.py`**: Shared evaluation infrastructure using Langfuse
- **`unified_optimization_flow.md`**: Mermaid diagrams showing complete system architecture

### Metrics and Monitoring

All evaluations are tracked in Langfuse:
- Individual run scores
- Aggregate performance over time
- Comparison between prompt versions
- Cost and latency metrics
- Trace-level debugging

Access Langfuse UI to:
- View evaluation runs
- Analyze failure patterns
- Compare prompt performance
- Review production traces
- Manage datasets

### Next Steps

To implement self-improving agents for a new use case:

1. **Set up evaluation dataset**:
   - Collect production traces
   - Add customer feedback mechanisms
   - Define quality dimensions
   - Create initial dataset in Langfuse

2. **Implement evaluation**:
   - Create LLM-as-a-Judge prompts
   - Set up EvaluationPipeline
   - Run baseline evaluation

3. **Run optimization**:
   - For CrewAI: Use `optimize_crew()`
   - For LangGraph: Use `optimize_agent()`
   - Review improvements
   - Deploy optimized prompts

4. **Monitor and iterate**:
   - Track production performance
   - Collect new failure cases
   - Update dataset regularly
   - Re-run optimization as needed

See `PROMPT_OPTIMIZATION.md` for detailed technical documentation.
