# Phase 0033: On-Device Scribe Prompt Generation

card: on-device-scribe-prompt-generation

## Intent

Enable automatic generation of PHASE_PROMPT content from a plan's linked cards using Apple's on-device foundation models (FoundationModels framework). This removes Claude spend from prompt generation entirely and leverages macOS 26's built-in AI capabilities for a summarization task that doesn't require complex reasoning.

## Scope

**In scope:**
- New `PromptGenerator` service with `PromptGenerating` protocol
- System prompt file instructing the model to write structured Scribe prompts
- PlanDetail UI updates: wire Generate button, loading state with shimmer, result handling
- Apple Intelligence shimmer effect (port TakeNote's MovingGradientForeground pattern)
- Service injection via App.swift and SwiftUI Environment
- Tests for card assembly logic, availability checking, error handling

**Out of scope:**
- Changes to card or plan data structures
- Changes to plan dispatch workflow
- Streaming (await full response, no incremental updates)
- @Generable structured output (plain text is sufficient)
- Automatic prompt generation without user action

## Constraints

- **L06 (Platform Leverage):** Use FoundationModels framework for on-device AI. macOS provides this capability; we use it.
- **L09 (Sandi Metz):** PromptGenerator is protocol-based with single responsibility (generate prompts from cards). Focused, testable, injected.
- **L11 (Test Coverage):** Test card content assembly, availability checks, error handling. Mock LanguageModelSession if possible.
- **L17 (UI State Correctness):** Loading state with progress indication, disabled controls during generation, visible error alerts on failure.
- **L18 (Design Is How It Works):** Button hidden when unavailable (no cards or model not available). Shimmer communicates "AI is working." Cancel button allows escape. Controls disabled during generation.
- **Style: Async Operation Feedback** — Explicit state modeling (.idle, .generating, .generated, .failed), ProgressView/shimmer, error alerts.
- **Style: Platform Nativeness** — Apple Intelligence shimmer matches system conventions for on-device AI. System colors, SF Symbols, standard controls.

## Acceptance Criteria

1. **Service exists:** `PromptGenerating` protocol and `PromptGenerator` implementation in `Sources/Hieroglyphs/Services/`
2. **Availability check:** `isAvailable` property returns true when `SystemLanguageModel.default.availability == .available`
3. **Card assembly:** Service assembles card titles, types, priorities, and body content into concise input respecting 4096 token limit
4. **Generation works:** `generate(from:)` creates LanguageModelSession, sends card summary, returns generated text
5. **Cancellation works:** `cancel()` sets flag; if response arrives after cancel, result is discarded
6. **System prompt exists:** Prompt file in `Sources/Hieroglyphs/Prompts/ScribePromptInstructions.swift` instructs model to write ~500 word narrative Scribe prompts
7. **PlanDetail wired:** Generate button visible only when `isAvailable && plan has cards`. On tap: calls `generate(from:)`, shows shimmer, populates `phasePromptContent` on success, shows alert on error
8. **Shimmer works:** AIMessage-style view with `apple.intelligence` SF Symbol, rotating gradient (orange/pink/blue/purple), bounce+rotate symbol effects, respects `accessibilityReduceMotion`
9. **Loading state:** Generate button and TextEditor disabled during generation. Shimmer visible. Cancel button shown.
10. **Error handling:** Alert shown on generation failure with error message
11. **Injection works:** PromptGenerator created in App.swift, injected via Environment, available in PlanDetail
12. **Tests pass:** PromptGenerator tests verify card assembly, availability logic, error handling

## Risks / Notes

- **Token limit handling:** 4096 token context window requires truncating card bodies if needed. Strategy: prioritize titles and requirements, truncate body content if total length excessive. Simple heuristic (character count approximation) sufficient for MVP.
- **Model availability:** Not all macOS 26 systems have language model available (depends on hardware, settings). Button hidden when unavailable — no error, just not shown.
- **No true cancellation:** LanguageModelSession doesn't support cancellation. We use flag-based discard pattern from TakeNote (check flag after response, throw away result if cancelled).
- **TakeNote reference:** Patterns to port are in `/Users/adam/Library/Mobile Documents/com~apple~CloudDocs/Xcode Projects/TakeNote`, specifically `Library/MagicFormatter.swift` and `Views/Shared/AIMessage.swift`.
