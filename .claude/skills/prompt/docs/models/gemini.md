# Prompt Design Strategies for Gemini

## Overview

**Prompt design** is the process of creating prompts, or natural language requests, that elicit accurate, high quality responses from a language model.

This guide introduces basic concepts, strategies, and best practices to get you started designing prompts to get the most out of Gemini AI models.

> **Note:** Prompt engineering is iterative. These guidelines and templates are starting points. Experiment and refine based on your specific use cases and observed model responses.

### Topic-Specific Guides

For more specific prompt strategies, see:
- [Prompting with media files](#)
- [Prompting for image generation with Imagen and Gemini Native Image Generation](#)
- [Prompting for video generation](#)

See the [prompt gallery](#) for interactive examples that showcase many of the concepts in this guide.

---

## Clear and Specific Instructions
An effective way to customize model behavior is to provide clear and specific instructions. Instructions can be:
- Questions that the model answers
- Step-by-step tasks to perform
- Complex mappings of user experience and mindset

### Input Types

Input is the required text in the prompt that you want the model to provide a response to. The following table shows the main input types:

| Input Type | Purpose | Example |
|:-----------|:--------|:--------|
| **Question** | Model answers a question | "What's a good name for a flower shop specializing in dried flowers?" |
| **Task** | Model performs an action | "Give me 5 things I must bring on a camping trip" |
| **Entity** | Model operates on data | "Classify these items as [large, small]" |
| **Completion** | Model completes partial input | Provide a pattern and let the model continue |

#### Example: Question Input
```
What's a good name for a flower shop that specializes in selling bouquets of
dried flowers? Create a list of 5 options with just the names.
```

**Output:**
```
1. Everlasting Blooms
2. Dried & Delightful
3. The Petal Preserve
4. Whispers of Wildflowers
5. Forever Blooms
```

#### Example: Task Input
```
Give me a simple list of just the things that I must bring on a camping trip. 
The list should have 5 items.
```

**Output:**
```
1. Tent – Your shelter from the elements.
2. Sleeping Bag – Stay warm and comfortable.
3. Sleeping Pad – Insulation and cushioning for a good night's sleep.
4. Headlamp or Flashlight – Light for nighttime activities.
5. First Aid Kit – Be prepared for minor injuries.
```

#### Example: Entity Input
```
Classify the following items as [large, small]:
- Elephant
- Mouse
- Snail
```

**Output:**
```
- Elephant: Large
- Mouse: Small
- Snail: Small
```

### Partial Input Completion Strategy

Generative language models work like advanced auto-completion. When you provide partial content with examples, the model learns the pattern and generates continuations accordingly.

#### Without Few-Shot Example
```
For the given order, return a JSON object that has the fields 
cheeseburger, hamburger, fries, or drink, with the value being the quantity.

Order: A burger and a drink.
```

**Output:**
```json
{
  "cheeseburger": 0,
  "hamburger": 1,
  "fries": 0,
  "drink": 1
}
```
*(Note: The model included all fields unnecessarily)*

#### With Few-Shot Example
```
Valid fields are cheeseburger, hamburger, fries, and drink.

Order: Give me a cheeseburger and fries
Output:
{
  "cheeseburger": 1,
  "fries": 1
}

Order: I want two burgers, a drink, and fries.
Output:
```

**Output:**
```json
{
  "hamburger": 2,
  "drink": 1,
  "fries": 1
}
```
*(Note: The model now omits fields that weren't ordered)*

> **Tip:** For complex JSON schemas, use Gemini API's structured output feature instead of prompt-based formatting.

---

## Constraints

Specify constraints on how the model reads and generates responses. Tell the model what to do and what not to do.

### Example: Length Constraint

**Prompt:**
```
Summarize this text in one sentence:

Text: A quantum computer exploits quantum mechanical phenomena to perform 
calculations exponentially faster than any modern traditional computer. 
At very tiny scales, physical matter acts as both particles and as waves, 
and quantum computing uses specialized hardware to leverage this behavior.
The operating principles of quantum devices is beyond the scope of classical physics. 
When deployed at scale, quantum computers could be used in a wide variety of 
applications such as: in cybersecurity to break existing encryption methods 
while helping researchers create new ones, in meteorology to develop better 
weather forecasting etc. However, the current state of the art quantum 
computers are still largely experimental and impractical.
```

**Output:**
```
Exploiting quantum mechanical phenomena, quantum computers can perform 
calculations exponentially faster than traditional computers for potential 
applications like cybersecurity and meteorology, although they are currently 
largely experimental and impractical.
```

---

## Response Format

You can give instructions that specify the format of the response. For example, you can ask for the response to be formatted as:
- Table
- Bulleted list
- Elevator pitch
- Keywords
- Sentence
- Paragraph

### Example: System Instruction for Conversational Response

**System instruction:**
```
All questions should be answered comprehensively with details, 
unless the user requests a concise response specifically.
```

**Prompt:**
```
What is a smart way to make a business that sells DVD's in 2026?
```

**Output:**
```
Starting a business selling DVDs in 2026 presents significant challenges 
due to the overwhelming dominance of digital streaming and on-demand services. 
A "smart" approach would require a highly specialized niche, strong value 
proposition, and likely focus on community or collector markets.

1. Extreme Niche Specialization
   - Out-of-Print & Rare Titles: Sourcing films unavailable on streaming platforms
   - [Additional options...]

[Full breakdown continues...]
```

### Completing Responses with Patterns

The completion strategy can help format responses. You can initiate a pattern and let the model complete it:

**Prompt (without format specified):**
```
Create an outline for an essay about hummingbirds.
```

**Model output:**
```
I. Introduction
A. Hook: [description]
B. Background: [information]
C. Thesis Statement: [main point]

II. Appearance and Identification
[continues...]
```

**Prompt (with pattern initiated):**
```
Create an outline for an essay about hummingbirds.

I. Introduction
*
```

**Model output (following your pattern):**
```
I. Introduction
* Hook: Start with a captivating fact or description
* Background: Briefly introduce hummingbirds—where they're found and reputation
* Thesis Statement: State the main point about their adaptations and significance
```

---

## Zero-Shot vs Few-Shot Prompts

You can include examples in the prompt to show the model what getting it right looks like. The model identifies patterns and applies them when generating responses.

### Key Definitions

- **Few-shot prompts:** Contain examples showing the desired task and response format
- **Zero-shot prompts:** Provide no examples, relying only on instructions

Few-shot prompts are generally more effective at regulating formatting, phrasing, scoping, and response patterns. We recommend **always including few-shot examples** in your prompts.

### Example: Impact of Few-Shot Examples

**Zero-shot prompt:**
```
Please choose the best explanation to the question:

Question: How is snow formed?

Explanation 1: Snow is formed when water vapor in the air freezes into ice 
crystals in the atmosphere, which can combine and grow into snowflakes as they 
fall through the atmosphere and accumulate on the ground.

Explanation 2: Water vapor freezes into ice crystals forming snow.

Answer:
```

**Output (prefers detailed answer):**
```
Explanation 1 is the better explanation because it provides more detail on the 
process, including how ice crystals combine and grow into snowflakes.
```

**Few-shot prompt (showing preference for concise answers):**
```
Below are some examples showing a question, explanation, and answer format:

Question: Why is the sky blue?
Explanation 1: The sky appears blue because of Rayleigh scattering, which causes 
shorter blue wavelengths of light to be scattered more easily than longer red 
wavelengths, making the sky look blue.
Explanation 2: Due to Rayleigh scattering effect.
Answer: Explanation 2

Question: What is the cause of earthquakes?
Explanation 1: Sudden release of energy in the Earth's crust.
Explanation 2: Earthquakes happen when tectonic plates suddenly slip or break 
apart, causing a release of energy that creates seismic waves.
Answer: Explanation 1

Now, Answer the following question given the example formats above:

Question: How is snow formed?
Explanation 1: Snow is formed when water vapor in the air freezes into ice 
crystals in the atmosphere, which can combine and grow into snowflakes as they 
fall through the atmosphere and accumulate on the ground.
Explanation 2: Water vapor freezes into ice crystals forming snow.
Answer:
```

**Output (follows the pattern for concise answers):**
```
Answer: Explanation 2
```

### Best Practices for Few-Shot Examples

1. **Consistent Formatting:** Structure examples identically to avoid undesired response formats. Pay attention to:
   - XML tags and whitespace
   - Newlines and indentation
   - Example separators

2. **Optimal Number:** Use a few examples (typically 2-5). Too many examples can cause the model to overfit.

3. **Remove Instructions if Possible:** If examples are clear enough, you can remove explicit instructions—the model learns from patterns.

---

## Adding Context

Include instructions and contextual information in prompts that the model needs to solve the problem, rather than assuming it has all required information.

### Example: Generic vs. Contextual Troubleshooting

**Generic prompt (no context):**
```
What should I do to fix my disconnected wifi? The light on my Google Wifi 
router is yellow and blinking slowly.
```

**Output:** Generic troubleshooting steps (may not be router-specific)

**Contextual prompt (with router documentation):**
```
Answer the question using the text below. Respond with only the text provided.

Question: What should I do to fix my disconnected wifi? The light on my Google 
Wifi router is yellow and blinking slowly.

Text:
Color: Slowly pulsing yellow
What it means: There is a network error.
What to do: Check that the Ethernet cable is connected to both your router and 
modem and both devices are turned on. You might need to unplug and plug in each 
device again.

Color: Fast blinking yellow
What it means: You are holding down the reset button and are factory resetting 
this device.
What to do: If you keep holding down the reset button, after 12 seconds, the 
light will turn solid yellow. Once it is solid yellow, let go of the reset button.

Color: Solid yellow
What it means: Router is factory resetting.
What to do: This can take up to 10 minutes. When done, the device will reset 
itself and start pulsing white.

Color: Solid red
What it means: Something is wrong.
What to do: Critical failure. Factory reset the router. If the light stays red, 
contact Wifi customer support.
```

**Output (specific and accurate):**
```
Check that the Ethernet cable is connected to both your router and your modem 
and both devices are turned on. You might need to unplug and plug in each 
device again.
```

---

## Breaking Down Complex Prompts

For complex prompts, break down complexity into simpler components:

### Strategy 1: Break Down Instructions
Instead of many instructions in one prompt, create one prompt per instruction. Choose which prompt to use based on user input.

### Strategy 2: Chain Prompts
For multi-step tasks, create a sequence of prompts where:
- Each step is a separate prompt
- The output of one prompt becomes the input of the next
- The final prompt's output is your result

### Strategy 3: Aggregate Responses
For parallel processing:
- Perform one operation on the first portion of data
- Perform another operation on a different portion
- Aggregate the results into a final output

---

## Experiment with Model Parameters

Each API call includes parameter values that control response generation. Different parameters produce different results. The most common parameters are:

| Parameter | Purpose | Default | Guidance |
|:----------|:--------|:--------|:----------|
| **Max output tokens** | Maximum tokens in response (~4 characters per token) | Model-specific | 100 tokens ≈ 60-80 words |
| **Temperature** | Randomness in token selection (0 = deterministic, higher = more creative) | 1.0 (Gemini 3) | Lower for focused tasks; higher for creative tasks |
| **topK** | Number of top probable tokens to sample from | Model-specific | 1 = greedy; 3 = sample from top 3 |
| **topP** | Probability threshold for token selection | 0.95 | Filters unlikely options; lower = more focused |
| **stop_sequences** | String(s) that trigger generation to stop | None | Avoid sequences likely to appear in output |

### Temperature Note for Gemini 3

> ⚠️ **Important:** Keep temperature at its default value of 1.0 for Gemini 3 models. Lowering temperature may cause unexpected behavior, looping, or degraded performance in complex mathematical or reasoning tasks.

---

## Prompt Iteration Strategies

Prompt design often requires iteration. Here are strategies to try:

### 1. Use Different Phrasing

Same intent, different wording:
```
Version 1: How do I bake a pie?
Version 2: Suggest a recipe for a pie.
Version 3: What's a good pie recipe?
```

### 2. Switch to Analogous Tasks

If the model won't follow your instructions, try an analogous task that achieves the same result.

**Categorization approach (less effective):**
```
Which category does The Odyssey belong to:
- thriller
- sci-fi
- mythology
- biography
```

**Multiple-choice approach (more effective):**
```
Multiple choice problem: Which of the following options describes the book 
The Odyssey?

Options:
- thriller
- sci-fi
- mythology
- biography
```

### 3. Change Content Order

The order of prompt elements affects responses. Experiment with different orderings:

| Order | Structure |
|:------|:----------|
| Version 1 | [examples] → [context] → [input] |
| Version 2 | [input] → [examples] → [context] |
| Version 3 | [examples] → [input] → [context] |

---

## Fallback Responses

A fallback response occurs when a prompt or response triggers a safety filter. Example: "I'm not able to help with that, as I'm only a language model."

**Solution:** Try increasing the temperature.

---

## Grounding and Code Execution

Gemini can use tools to avoid hallucinations:

### Grounding with Google Search
- Connects Gemini to real-time web content
- **Use when:** Model needs obscure or recent facts
- **Benefit:** Reduces hallucinations on time-sensitive topics

### Code Execution
- Generates and runs Python code
- **Use when:** Model needs to perform arithmetic, counting, or calculations
- **Benefit:** Ensures mathematical accuracy

---

## Best Practices for Gemini 3 Models

Gemini 3 models are designed for advanced reasoning and instruction following. They respond best to direct, well-structured prompts that clearly define tasks and constraints.

### Core Principles

| Principle | Guidelines |
|:----------|:-----------|
| **Be Precise & Direct** | State your goal clearly and concisely; avoid unnecessary language |
| **Use Consistent Structure** | Employ clear delimiters (XML tags or Markdown headings); choose one and stick with it |
| **Define Parameters** | Explicitly explain ambiguous terms or parameters |
| **Control Verbosity** | Gemini 3 provides direct answers by default; explicitly request detail if needed |
| **Handle Multimodal Inputs** | Treat text, images, audio, and video as equal-class inputs; ensure instructions reference each modality |
| **Prioritize Critical Instructions** | Place essential constraints, role definitions, and output format requirements at the very beginning |
| **Structure Large Contexts** | Supply all context first; place specific instructions or questions at the end |
| **Anchor Context** | After large data blocks, use transition phrases like "Based on the information above..." |

### Gemini 3 Flash Specific Strategies

#### Current Day Accuracy
Add this to system instructions to help the model reference current date (2026):
```
For time-sensitive user queries that require up-to-date information, you
MUST follow the provided current time (date and year) when formulating
search queries in tool calls. Remember it is 2026 this year.
```

#### Knowledge Cutoff Awareness
```
Your knowledge cutoff date is January 2025.
```

#### Grounding Performance
```
You are a strictly grounded assistant limited to the information provided in
the User Context. In your answers, rely **only** on the facts that are
directly mentioned in that context. You must **not** access or utilize your
own knowledge or common sense to answer. Do not assume or infer from the
provided facts; simply report them exactly as they appear. Your answer must
be factual and fully truthful to the provided text, leaving absolutely no
room for speculation or interpretation. Treat the provided context as the
absolute limit of truth; any facts or details that are not directly
mentioned in the context must be considered **completely untruthful** and
**completely unsupported**. If the exact answer is not explicitly written in
the context, you must state that the information is not available.
```

---

## Enhancing Reasoning and Planning

Gemini 2.5 and 3 series models automatically generate internal "thinking" text to improve reasoning performance. You generally don't need to have the model outline or detail reasoning steps in the response.

**For heavy reasoning tasks:** Simple requests like "Think very hard before answering" can improve performance, though at a cost of extra thinking tokens.

> See the Gemini thinking documentation for more detail.

---

## Structured Prompting Examples

Using tags or Markdown helps the model distinguish between instructions, context, and tasks.

### XML-Style Structured Prompt

```xml
<role>
You are a helpful assistant.
</role>

<constraints>
1. Be objective.
2. Cite sources.
</constraints>

<context>
[Insert User Input Here - The model knows this is data, not instructions]
</context>

<task>
[Insert the specific user request here]
</task>
```

### Markdown-Style Structured Prompt

```markdown
# Identity
You are a senior solution architect.

# Constraints
- No external libraries allowed.
- Python 3.11+ syntax only.

# Output format
Return a single code block.
```

---

## Complete Template: Best Practices Combined

This template captures core principles for prompting with Gemini 3. Always iterate and modify for your specific use case.

### System Instruction

```xml
<role>
You are Gemini 3, a specialized assistant for [Insert Domain, e.g., Data Science].
You are precise, analytical, and persistent.
</role>

<instructions>
1. **Plan**: Analyze the task and create a step-by-step plan.
2. **Execute**: Carry out the plan.
3. **Validate**: Review your output against the user's task.
4. **Format**: Present the final answer in the requested structure.
</instructions>

<constraints>
- Verbosity: [Specify Low/Medium/High]
- Tone: [Specify Formal/Casual/Technical]
</constraints>

<output_format>
Structure your response as follows:
1. **Executive Summary**: [Short overview]
2. **Detailed Response**: [The main content]
</output_format>
```

### User Prompt

```xml
<context>
[Insert relevant documents, code snippets, or background info here]
</context>

<task>
[Insert specific user request here]
</task>

<final_instruction>
Remember to think step-by-step before answering.
</final_instruction>
```

---

## Agentic Workflows

For deep agentic workflows, specific instructions control how the model reasons, plans, and executes tasks. While Gemini provides strong general performance, complex agents require you to configure the trade-off between computational cost (latency and tokens) and task accuracy.

### Dimensions of Agent Behavior

When designing prompts for agents, consider these controllable dimensions:

#### 1. Reasoning and Strategy

Configuration for how the model thinks and plans before taking action:

- **Logical Decomposition:** How thoroughly the model must analyze constraints, prerequisites, and operation order
- **Problem Diagnosis:** Depth of analysis when identifying root causes; whether to accept obvious answers or explore complex, less probable explanations
- **Information Exhaustiveness:** Trade-off between analyzing all policies/documents vs. prioritizing efficiency and speed

#### 2. Execution and Reliability

Configuration for how the agent operates autonomously and handles roadblocks:

- **Adaptability:** How the model reacts to new data—strictly follow initial plan or pivot when observations contradict assumptions
- **Persistence & Recovery:** Degree to which the model attempts self-correction; high persistence increases success but risks higher tokens or loops
- **Risk Assessment:** Logic for evaluating consequences; distinguishes between low-risk explores (reads) vs. high-risk state changes (writes)

#### 3. Interaction and Output

Configuration for how the agent communicates and formats results:

- **Ambiguity & Permission Handling:** When the model can assume vs. when it must pause and ask for clarification
- **Verbosity:** Volume of text explaining actions vs. silent execution
- **Precision & Completeness:** Must solve every edge case and provide exact figures vs. accept ballpark estimates

### Advanced System Instruction Template for Agents

This system instruction has been evaluated by researchers to improve performance on agentic benchmarks. It encourages strong reasoning and planning while enforcing specific behaviors:

```
You are a very strong reasoner and planner. Use these critical instructions 
to structure your plans, thoughts, and responses.

Before taking any action (either tool calls *or* responses to the user), 
you must proactively, methodically, and independently plan and reason about:

1) Logical dependencies and constraints: Analyze the intended action against:
    1.1) Policy-based rules, mandatory prerequisites, and constraints.
    1.2) Order of operations: Ensure taking an action doesn't prevent 
         subsequent necessary actions.
        1.2.1) Reorder operations to maximize successful completion.
    1.3) Other prerequisites (information and/or actions needed).
    1.4) Explicit user constraints or preferences.

2) Risk assessment: What are the consequences? Will the new state cause 
   future issues?
    2.1) For exploratory tasks (like searches), missing optional parameters 
         is LOW risk. Prefer calling the tool with available information 
         over asking the user, unless Rule 1 determines otherwise.

3) Abductive reasoning and hypothesis exploration: Identify the most logical 
   likely reason for problems encountered.
    3.1) Look beyond immediate causes; likely reasons may require deeper inference.
    3.2) Hypotheses may require additional research; each may take multiple steps.
    3.3) Prioritize by likelihood, but don't discard unlikely options prematurely.

4) Outcome evaluation and adaptability: Does the previous observation require 
   changes to your plan?
    4.1) If initial hypotheses are disproven, generate new ones from evidence.

5) Information availability: Incorporate all applicable sources:
    5.1) Using available tools and their capabilities
    5.2) All policies, rules, checklists, and constraints
    5.3) Previous observations and conversation history
    5.4) Information only available by asking the user

6) Precision and Grounding: Ensure your reasoning is extremely precise and 
   relevant to the exact situation.
    6.1) Verify claims by quoting exact applicable information.

7) Completeness: Ensure all requirements, constraints, options, and preferences 
   are exhaustively incorporated.
    7.1) Resolve conflicts using order of importance from #1.
    7.2) Avoid premature conclusions; there may be multiple relevant options.
        7.2.1) Check ALL information sources from #5.
        7.2.2) Consult the user if unsure about applicability.
    7.3) Review applicable sources from #5 for current relevance.

8) Persistence and patience: Do not give up unless all reasoning is exhausted.
    8.1) Don't be dissuaded by time or user frustration.
    8.2) Be intelligent: On transient errors, RETRY unless an explicit limit 
         is reached. On other errors, CHANGE strategy, don't repeat failed calls.

9) Inhibit your response: Only take action after ALL reasoning above is completed.
```

---

## Summary

Effective prompt design for Gemini involves:
- Clear, specific instructions with examples
- Appropriate constraints and response formatting
- Context and grounding for accuracy
- Iteration and parameter experimentation
- Structured prompts for complex tasks
- Agentic configurations for autonomous workflows

Remember: **Prompt engineering is iterative.** Experiment, measure results, and refine based on your specific use cases.


Version 1:
[examples]
[context]
[input]

Version 2:
[input]
[examples]
[context]

Version 3:
[examples]
[input]
[context]
Fallback responses
A fallback response is a response returned by the model when either the prompt or the response triggers a safety filter. An example of a fallback response is "I'm not able to help with that, as I'm only a language model."

If the model responds with a fallback response, try increasing the temperature.

Grounding and code execution
Gemini is able to use tools to avoid hallucinations in scenarios where it might otherwise produce incorrect responses.

Grounding with Google Search connects the Gemini model to real-time web content, and should be enabled whenever the model may need to know obscure or recent facts.

Gemini's code execution tool enables the model to generate and run Python code, and should be enabled whenever the model needs to perform any kind of arithmetic, counting, or calculation.

Gemini 3
Gemini 3 models are designed for advanced reasoning and instruction following. They respond best to prompts that are direct, well-structured, and clearly define the task and any constraints. The following practices are recommended for optimal results with Gemini 3:

Core prompting principles
Be precise and direct: State your goal clearly and concisely. Avoid unnecessary or overly persuasive language.
Use consistent structure: Employ clear delimiters to separate different parts of your prompt. XML-style tags (e.g., <context>, <task>) or Markdown headings are effective. Choose one format and use it consistently within a single prompt.
Define parameters: Explicitly explain any ambiguous terms or parameters.
Control output verbosity: By default, Gemini 3 models provide direct and efficient answers. If you need a more conversational or detailed response, you must explicitly request it in your instructions.
Handle multimodal inputs coherently: When using text, images, audio, or video, treat them as equal-class inputs. Ensure your instructions clearly reference each modality as needed.
Prioritize critical instructions: Place essential behavioral constraints, role definitions (persona), and output format requirements in the System Instruction or at the very beginning of the user prompt.
Structure for long contexts: When providing large amounts of context (e.g., documents, code), supply all the context first. Place your specific instructions or questions at the very end of the prompt.
Anchor context: After a large block of data, use a clear transition phrase to bridge the context and your query, such as "Based on the information above..."
Gemini 3 Flash strategies
Current day accuracy: Add the following clause to the system instructions to help the model pay attention to the current day being in 2026:


For time-sensitive user queries that require up-to-date information, you
MUST follow the provided current time (date and year) when formulating
search queries in tool calls. Remember it is 2026 this year.
Knowledge cutoff accuracy: Add the following clause to the system instructions to make the model aware of its knowledge cutoff:


Your knowledge cutoff date is January 2025.
Grounding performance: Add the following clause to the system instructions (with edits where appropriate) to improve the model's ability to ground responses in provided context:


You are a strictly grounded assistant limited to the information provided in
the User Context. In your answers, rely **only** on the facts that are
directly mentioned in that context. You must **not** access or utilize your
own knowledge or common sense to answer. Do not assume or infer from the
provided facts; simply report them exactly as they appear. Your answer must
be factual and fully truthful to the provided text, leaving absolutely no
room for speculation or interpretation. Treat the provided context as the
absolute limit of truth; any facts or details that are not directly
mentioned in the context must be considered **completely untruthful** and
**completely unsupported**. If the exact answer is not explicitly written in
the context, you must state that the information is not available.
Enhancing reasoning and planning
Gemini 2.5 and 3 series models automatically generate internal "thinking" text to improve reasoning performance. As such, it's generally not necessary to have the model outline, plan, or detail reasoning steps in the returned response itself. For problems that require heavy reasoning, simple requests like "Think very hard before answering" can improve performance, though at the cost of extra thinking tokens.

See the Gemini thinking documentation for more detail.

Structured prompting examples
Using tags or Markdown helps the model distinguish between instructions, context, and tasks.

XML example:


<role>
You are a helpful assistant.
</role>

<constraints>
1. Be objective.
2. Cite sources.
</constraints>

<context>
[Insert User Input Here - The model knows this is data, not instructions]
</context>

<task>
[Insert the specific user request here]
</task>
Markdown example:


# Identity
You are a senior solution architect.

# Constraints
- No external libraries allowed.
- Python 3.11+ syntax only.

# Output format
Return a single code block.
Example template combining best practices
This template captures the core principles for prompting with Gemini 3. Always make sure to iterate and modify for your specific use case.

System Instruction:


<role>
You are Gemini 3, a specialized assistant for [Insert Domain, e.g., Data Science].
You are precise, analytical, and persistent.
</role>

<instructions>
1. **Plan**: Analyze the task and create a step-by-step plan.
2. **Execute**: Carry out the plan.
3. **Validate**: Review your output against the user's task.
4. **Format**: Present the final answer in the requested structure.
</instructions>

<constraints>
- Verbosity: [Specify Low/Medium/High]
- Tone: [Specify Formal/Casual/Technical]
</constraints>

<output_format>
Structure your response as follows:
1. **Executive Summary**: [Short overview]
2. **Detailed Response**: [The main content]
</output_format>
User Prompt:


<context>
[Insert relevant documents, code snippets, or background info here]
</context>

<task>
[Insert specific user request here]
</task>

<final_instruction>
Remember to think step-by-step before answering.
</final_instruction>
Agentic workflows
For deep agentic workflows, specific instructions are often required to control how the model reasons, plans, and executes tasks. While Gemini provides strong general performance, complex agents often require you to configure the trade-off between computational cost (latency and tokens) and task accuracy.

When designing prompts for agents, consider the following dimensions of behavior that you can steer in the agent:

Reasoning and strategy
Configuration for how the model thinks and plans before taking action.

Logical decomposition: Defines how thoroughly the model must analyze constraints, prerequisites, and the order of operations.
Problem diagnosis: Controls the depth of analysis when identifying causes and the model’s use of abductive reasoning. Determines if the model should accept the most obvious answer or explore complex, less probable explanations.
Information exhaustiveness: The trade-off between analyzing every available policy and document versus prioritizing efficiency and speed.
Execution and reliability
Configuration for how the agent operates autonomously and handles roadblocks.

Adaptability: How the model reacts to new data. Determines whether it should strictly adhere to its initial plan or pivot immediately when observations contradict assumptions.
Persistence and Recovery: The degree to which the model attempts to self-correct errors. High persistence increases success rates but risks higher token costs or loops.
Risk Assessment: The logic for evaluating consequences. Explicitly distinguishes between low-risk exploratory actions (reads) and high-risk state changes (writes).
Interaction and output
Configuration for how the agent communicates with the user and formats results.

Ambiguity and permission handling: Defines when the model is permitted to make assumptions versus when it must pause execution to ask the user for clarification or permission.
Verbosity: Controls the volume of text generated alongside tool calls. This determines if the model explains its actions to the user or remains silent during execution.
Precision and completeness: The required fidelity of the output. Specifies whether the model must solve for every edge case and provide exact figures or if ballpark estimates are acceptable.
System instruction template
The following system instruction is an example that has been evaluated by researchers to improve performance on agentic benchmarks where the model must adhere to a complex rulebook and interact with a user. It encourages the agent to act as a strong reasoner and planner, enforces specific behaviors across dimensions listed above and requires the model to proactively plan before taking any action.

You can adapt this template to fit your specific use case constraints.


You are a very strong reasoner and planner. Use these critical instructions to structure your plans, thoughts, and responses.

Before taking any action (either tool calls *or* responses to the user), you must proactively, methodically, and independently plan and reason about:

1) Logical dependencies and constraints: Analyze the intended action against the following factors. Resolve conflicts in order of importance:
    1.1) Policy-based rules, mandatory prerequisites, and constraints.
    1.2) Order of operations: Ensure taking an action does not prevent a subsequent necessary action.
        1.2.1) The user may request actions in a random order, but you may need to reorder operations to maximize successful completion of the task.
    1.3) Other prerequisites (information and/or actions needed).
    1.4) Explicit user constraints or preferences.

2) Risk assessment: What are the consequences of taking the action? Will the new state cause any future issues?
    2.1) For exploratory tasks (like searches), missing *optional* parameters is a LOW risk. **Prefer calling the tool with the available information over asking the user, unless** your `Rule 1` (Logical Dependencies) reasoning determines that optional information is required for a later step in your plan.

3) Abductive reasoning and hypothesis exploration: At each step, identify the most logical and likely reason for any problem encountered.
    3.1) Look beyond immediate or obvious causes. The most likely reason may not be the simplest and may require deeper inference.
    3.2) Hypotheses may require additional research. Each hypothesis may take multiple steps to test.
    3.3) Prioritize hypotheses based on likelihood, but do not discard less likely ones prematurely. A low-probability event may still be the root cause.

4) Outcome evaluation and adaptability: Does the previous observation require any changes to your plan?
    4.1) If your initial hypotheses are disproven, actively generate new ones based on the gathered information.

5) Information availability: Incorporate all applicable and alternative sources of information, including:
    5.1) Using available tools and their capabilities
    5.2) All policies, rules, checklists, and constraints
    5.3) Previous observations and conversation history
    5.4) Information only available by asking the user

6) Precision and Grounding: Ensure your reasoning is extremely precise and relevant to each exact ongoing situation.
    6.1) Verify your claims by quoting the exact applicable information (including policies) when referring to them. 

7) Completeness: Ensure that all requirements, constraints, options, and preferences are exhaustively incorporated into your plan.
    7.1) Resolve conflicts using the order of importance in #1.
    7.2) Avoid premature conclusions: There may be multiple relevant options for a given situation.
        7.2.1) To check for whether an option is relevant, reason about all information sources from #5.
        7.2.2) You may need to consult the user to even know whether something is applicable. Do not assume it is not applicable without checking.
    7.3) Review applicable sources of information from #5 to confirm which are relevant to the current state.

8) Persistence and patience: Do not give up unless all the reasoning above is exhausted.
    8.1) Don't be dissuaded by time taken or user frustration.
    8.2) This persistence must be intelligent: On *transient* errors (e.g. please try again), you *must* retry **unless an explicit retry limit (e.g., max x tries) has been reached**. If such a limit is hit, you *must* stop. On *other* errors, you must change your strategy or arguments, not repeat the same failed call.

9) Inhibit your response: only take an action after all the above reasoning is completed. Once you've taken an 