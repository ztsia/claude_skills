# Prompt Framework Decision Guide

Use this guide to select the best prompting framework for a given prompt. Read the relevant model doc after selecting a framework for model-specific adjustments.

---

## Framework Roster

| Framework | Full Name | Best For |
|:--|:--|:--|
| **TCF** | Task-Context-Format | Simple, single-step instructions with a clear output format |
| **PC** | Persona + Constraint | Role-playing agents, tutors, assistants with behavioral guardrails |
| **CRAFT** | Context, Role, Action, Format, Target | Complex multi-constraint instructions needing structured output |
| **CoStar** | Context, Objective, Style, Tone, Audience, Response | Content generation with strong stylistic/audience requirements |
| **Few-Shot** | In-context examples | Classification, extraction, or formatting tasks with edge cases |
| **CoT** | Chain-of-Thought | Multi-step reasoning, math, logic, diagnosis |
| **ToT** | Tree-of-Thought | Open-ended exploration, creative synthesis, hypothesis generation |
| **ReAct** | Reasoning + Acting | Agentic tool-use, iterative search, external API calls |

---

## Decision Tree

### Step 1 — How many steps does the task require?

- **One step, clear output** → go to Step 2
- **Multiple steps, reasoning needed** → go to Step 3
- **Agentic: tool calls, search, iteration** → use **ReAct**

### Step 2 — Single-step tasks

| Condition | Framework |
|:--|:--|
| Simple instruction + known output shape | **TCF** |
| Needs a persona/role + behavioral guardrails | **PC** |
| Multiple constraints (role + format + audience + tone) | **CoStar** or **CRAFT** |
| Has edge cases best shown by example | **Few-Shot** |
| Structured JSON / typed output required | **CRAFT** (add output schema example) |

Use **CRAFT** when the prompt has 3+ of: role, context, action verb, format spec, target audience.
Use **CoStar** when the biggest variable is *style, tone, or audience* rather than *format*.

### Step 3 — Multi-step / reasoning tasks

| Condition | Framework |
|:--|:--|
| Reasoning can follow a linear chain | **CoT** |
| Task benefits from exploring multiple branches | **ToT** |
| Task involves decisions based on intermediate results | **CoT** + self-check step |
| Requires calling tools or searching between reasoning steps | **ReAct** |

---

## Quick Reference: Framework Skeletons

### TCF
```
Task: [what to do]
Context: [relevant background]
Format: [output shape — JSON / bullet list / prose / etc.]
```

### PC (Persona + Constraint)
```
You are a [role] with [expertise].
Your constraints:
- [constraint 1]
- [constraint 2]
[task]
```

### CRAFT
```
Context: [situation / background]
Role: [who the model is]
Action: [specific verb — classify / extract / generate / summarize]
Format: [exact output structure]
Target: [audience or use case]
```

### CoStar
```
Context: [situation]
Objective: [goal]
Style: [writing style]
Tone: [emotional register]
Audience: [who reads this]
Response: [output format]
```

### Few-Shot
```
[Instruction]

Examples:
Input: [x1] → Output: [y1]
Input: [x2] → Output: [y2]
Input: [x3] → Output: [y3]

Input: {{input}} → Output:
```

### CoT
```
[Task instruction]

Think step by step:
1. [reasoning step]
2. [reasoning step]
...
Then give your final answer.
```

### ToT
```
[Task instruction]

Consider multiple approaches:
Approach A: [explore]
Approach B: [explore]
Approach C: [explore]

Evaluate each, then produce the best answer.
```

### ReAct
```
[Task instruction]

You have access to: [tool list]

For each step:
Thought: [what you need to find out]
Action: [tool call]
Observation: [result]
... repeat until done ...
Answer: [final answer]
```

---

## Cross-cutting rules (apply to all frameworks)

1. **Be specific about output format** — vague instructions produce vague output. If the output is JSON, include the schema. If it's a list, say how many items.
2. **Add context that justifies constraints** — "Never use ellipses because the output will be read by TTS" is more effective than "Never use ellipses."
3. **For classification/extraction** — always add at least 2 few-shot examples even if using another framework.
4. **For structured output (JSON)** — include an example of the exact JSON object expected.
5. **For agentic prompts** — define the stopping condition explicitly ("stop when you have found X" or "stop after 3 attempts").
6. **Delimiters** — use model-native delimiters (XML tags for Claude, markdown headers for Gemini/GPT) to separate sections.

---

## After selecting a framework

Read the model-specific doc in `docs/models/` for:
- Preferred delimiter style (XML tags vs markdown)
- System instruction vs user message split
- Structured output support (native JSON mode, tool calling)
- Few-shot example format
- Token/length guidance
