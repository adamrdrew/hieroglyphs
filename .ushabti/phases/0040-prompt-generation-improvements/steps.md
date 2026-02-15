# Steps

## S001: Configure greedy sampling

**Intent:** Eliminate randomness from model responses by setting deterministic generation options.

**Work:**
- Add `GenerationOptions(sampling: .greedy)` to the `session.respond()` call in `PromptGenerator.generate(from:)`
- Greedy sampling selects the most probable token at each step, removing stochasticity
- This is the single highest-impact fix — may eliminate worst hallucinations alone

**Done when:** `session.respond(to:options:)` called with `GenerationOptions(sampling: .greedy)` and tests verify deterministic output.

---

## S002: Harden the system prompt

**Intent:** Rewrite `ScribePromptInstructions` to explicitly forbid hallucination and enforce strict adherence to input.

**Work:**
- Rewrite the system prompt in `ScribePromptInstructions.swift` to be blunt and directive:
  - "You are a prompt formatter. Use ONLY the information provided."
  - "Do not add, infer, or describe anything not explicitly stated in the input."
  - "Never describe current application behavior, UI flows, menus, or interaction patterns."
- Remove example output that might encourage invention
- Keep instructions simple and direct — less prose, more commands

**Done when:** System prompt explicitly forbids hallucination, tests show no invented context in generated output.

---

## S003: Implement `@Generable` structured output

**Intent:** Constrain the model response to a defined schema with specific fields, making hallucination harder.

**Work:**
- Define a `@Generable` struct (e.g., `PhasePromptSchema`) with fields:
  - `context: String` — Why this phase exists (2-3 sentences)
  - `whatToBuild: String` — Features/fixes to implement
  - `requirements: String` — Acceptance criteria and constraints
  - `cardsAddressed: [String]` — List of card titles
- Add `@Guide` annotations to each field reinforcing "use only provided input"
- Update `PromptGenerator.generate(from:)` to request structured output via `session.respond(to:options:generable:)`
- Format the structured response into markdown in `PromptGenerator` after generation completes

**Done when:** `PromptGenerator` uses structured output, tests verify all fields are populated without hallucination.

---

## S004: Add token measurement and logging

**Intent:** Audit context window usage to verify we're not approaching the 4096-token limit and causing quality degradation.

**Work:**
- Calculate approximate token count for `cardSummary` input string (1 token ≈ 4 chars as current heuristic)
- Log input token estimate before calling `session.respond()`
- Log response length after generation completes
- If input approaches 3000 tokens (75% of context window), log warning and consider more aggressive truncation in `assembleCardSummary()`

**Done when:** Token usage logged for every generation call, tests verify logging occurs.

---

## S005: Refine card summary assembly

**Intent:** Ensure `assembleCardSummary()` provides clear, structured input without extraneous formatting that might confuse the model.

**Work:**
- Review current card summary format (title, type, priority, status, body preview)
- Ensure card metadata is presented clearly without markdown noise
- Consider prioritizing critical/high-priority cards explicitly in input order
- Keep body preview truncation at 500 chars but verify this is adequate for typical cards

**Done when:** Card summary assembly is clear, concise, and prioritizes important information.

---

## S006: Write tests for generation quality

**Intent:** Validate generation quality against multiple card types and verify no hallucination occurs.

**Work:**
- Create test cases in `PromptGeneratorTests.swift` for:
  - Single bug card (simple, focused)
  - Single feature card (complex, multi-requirement)
  - Multiple cards with varying priorities (critical + low)
  - Edge case: card with minimal body content
- For each test, verify:
  - Generated prompt contains only information from input cards
  - No invented UI flows, menus, or application behavior
  - All card titles appear in "Cards Addressed" section
  - Output is well-formed markdown
- Use mocked `LanguageModelSession` if needed to avoid dependency on live model during tests

**Done when:** Tests cover 3+ card types, all tests pass, no hallucination detected in test output.

---

## S007: Update documentation

**Intent:** Ensure `.ushabti/docs/plans-system.md` reflects the new generation approach.

**Work:**
- Update "Phase Prompt Generation" section in `.ushabti/docs/plans-system.md`
- Document greedy sampling, hardened prompt, structured output via `@Generable`
- Document token measurement and logging
- Note that generation is deterministic (greedy sampling)
- Update any references to old generation behavior

**Done when:** Documentation accurately describes new prompt generation implementation.
