# Phase 0040: Prompt Generation Improvements

card: on-device-prompt-generation-hallucinates-context

## Intent

Fix the on-device Apple Intelligence prompt generation (FoundationModels framework) which currently hallucinates context — inventing UI flows, menus, and interaction patterns that don't exist in the app. The generated prompts are worse than useless because they mislead the implementing agent.

This phase implements the fixes outlined in the card, in priority order: greedy sampling, hardened system prompt, structured output via `@Generable`, and token measurement.

## Scope

**In scope:**
- Set `GenerationOptions(sampling: .greedy)` to eliminate randomness
- Harden the system prompt in `ScribePromptInstructions` to explicitly forbid hallucination
- Implement `@Generable` structured output with field-level `@Guide` annotations
- Add token measurement and context window auditing
- Test generation against 3+ different card types (bug, feature, varying complexity)

**Out of scope:**
- UI changes to the prompt generation flow
- Two-pass generation approach (deferred unless single-pass fixes prove insufficient)

## Constraints

- **L09**: Protocol-based services, Sandi Metz principles — small focused methods
- **L11**: Test coverage for all public APIs with multiple card types
- **L14**: Builder must update `.ushabti/docs/plans-system.md` to reflect changes to prompt generation
- **Style**: No regex, clarity over brevity, composition over inheritance

## Acceptance Criteria

- [ ] `GenerationOptions` configured with `sampling: .greedy` to eliminate randomness
- [ ] System prompt rewritten to explicitly forbid adding, inferring, or describing anything not in input
- [ ] `@Generable` structured output implemented with schema fields for Context, What to Build, Requirements, Cards Addressed
- [ ] Each `@Guide` annotation reinforces "use only provided input"
- [ ] Token measurement implemented — log input token consumption to verify context window usage
- [ ] Tests validate generation quality against 3+ different card types (bug, feature, varying complexity)
- [ ] Generated prompts use ONLY information from input cards — no invented UI flows or application behavior
- [ ] Documentation updated in `.ushabti/docs/plans-system.md` to reflect new generation approach

## Risks / Notes

- The FoundationModels framework has a 4096-token context window (input + output combined) and cannot signal when context is lost. If quality remains poor after single-pass fixes, we may need a two-pass approach (extract facts → format facts into prompt).
- Structured output via `@Generable` may constrain the model too much, producing overly terse or incomplete prompts. Will validate against real card data during testing.
- Greedy sampling eliminates creativity, which may produce repetitive phrasing. This is acceptable — correctness over style.
