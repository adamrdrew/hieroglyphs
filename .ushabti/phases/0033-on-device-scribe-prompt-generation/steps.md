# Steps

## S001: Create PromptGenerating protocol

**Intent:** Define the contract for prompt generation services.

**Work:**
- Create `Sources/Hieroglyphs/Services/PromptGenerating.swift`
- Define protocol with:
  - `var isAvailable: Bool { get }` — true when on-device model available
  - `var isGenerating: Bool { get }` — true during active generation
  - `func generate(from cards: [Card]) async throws -> String` — generate prompt from cards
  - `func cancel()` — request cancellation of in-progress generation
- Add doc comments explaining 4096 token limit and truncation strategy

**Done when:** PromptGenerating.swift exists, protocol compiles, doc comments complete.

## S002: Create PromptGenerator implementation

**Intent:** Implement on-device prompt generation using FoundationModels.

**Work:**
- Create `Sources/Hieroglyphs/Services/PromptGenerator.swift`
- Import FoundationModels
- Implement `PromptGenerating`:
  - `isAvailable`: check `SystemLanguageModel.default.availability == .available`
  - `isGenerating`: track with `@Published var` (or simple Bool, depending on observation needs)
  - `generate(from:)`:
    - Create new `LanguageModelSession` with system prompt (from ScribePromptInstructions)
    - Assemble card data: title, type, priority, truncated body (if needed to fit 4096 tokens)
    - Use character count approximation (1 token ≈ 4 chars) for truncation heuristic
    - Call `session.respond(to:)` with assembled card summary
    - Extract `response.content`
    - Check cancellation flag; throw if cancelled
    - Return generated text
  - `cancel()`: set cancellation flag
- Add private `sessionCancelled` flag
- Handle errors from LanguageModelSession (wrap in typed error)

**Done when:** PromptGenerator.swift compiles, implements protocol, uses LanguageModelSession.

## S003: Create system prompt

**Intent:** Define instructions for the on-device model to generate Scribe prompts.

**Work:**
- Create `Sources/Hieroglyphs/Prompts/ScribePromptInstructions.swift`
- Define constant string with system prompt text:
  - Instruct model to read card titles, types, priorities, descriptions
  - Write concise, structured phase prompt for a development agent (Scribe)
  - Include: what to build, why, which cards addressed, key requirements
  - Use prose paragraphs (not bullet lists)
  - Keep under ~500 words
  - Example format: "# [Phase Name]\n\n## Context\n...\n\n## What to Build\n...\n\n## Requirements\n..."
- Tune prompt based on model behavior (may require iteration)

**Done when:** ScribePromptInstructions.swift exists, prompt text is clear and concise.

## S004: Create PromptGenerator environment key

**Intent:** Enable SwiftUI environment injection for PromptGenerator.

**Work:**
- Create `Sources/Hieroglyphs/Services/PromptGeneratorEnvironmentKey.swift`
- Define `PromptGeneratorKey: EnvironmentKey` with defaultValue nil
- Extend `EnvironmentValues` with `promptGenerator` computed property
- Follow existing pattern from PharaohServiceEnvironmentKey.swift

**Done when:** PromptGeneratorEnvironmentKey.swift exists, compiles, follows environment key pattern.

## S005: Create Apple Intelligence shimmer view

**Intent:** Port TakeNote's shimmer effect for AI operations.

**Work:**
- Create `Sources/Hieroglyphs/Views/Shared/AIMessage.swift`
- Define `AIMessage` view with:
  - `Image(systemName: "apple.intelligence")`
  - `.symbolEffect(.bounce.down)` and `.symbolEffect(.rotate)`
  - Custom `MovingGradientForeground` modifier
- Create `MovingGradientForeground` ViewModifier:
  - Rotating `AngularGradient` with orange, pink, blue, purple colors
  - Animated rotation with `.animation(.linear(duration: 4).repeatForever(autoreverses: false))`
  - Respect `@Environment(\.accessibilityReduceMotion)` — disable animation if true
- Add Label variant: `Label("Generating...", systemImage: "apple.intelligence")` with shimmer
- Reference TakeNote's implementation in `Views/Shared/AIMessage.swift` for exact gradient values and symbol effect usage

**Done when:** AIMessage.swift compiles, shimmer animates, respects accessibility settings.

## S006: Wire PromptGenerator in App.swift

**Intent:** Create PromptGenerator instance and inject via environment.

**Work:**
- Open `Sources/Hieroglyphs/App.swift`
- Create `PromptGenerator` instance in `init()`
- Store as property: `private let promptGenerator: PromptGenerating`
- Inject via `.environment(\.promptGenerator, promptGenerator)` on MainWindow
- Follow existing pattern for PharaohService

**Done when:** App.swift creates PromptGenerator, injects via environment, compiles.

## S007: Add generation state to PlanDetail

**Intent:** Track generation state for UI binding.

**Work:**
- Open `Sources/Hieroglyphs/Views/PlanDetail/PlanDetail.swift`
- Add `@Environment(\.promptGenerator) private var promptGenerator`
- Add `@State private var generationState: GenerationState = .idle`
- Define `GenerationState` enum:
  - `case idle`
  - `case generating`
  - `case failed(Error)`
- Add `@State private var showingGenerationError = false`
- Add `@State private var generationError: Error?`

**Done when:** PlanDetail has generation state properties, compiles.

## S008: Implement Generate button logic

**Intent:** Wire Generate button to call PromptGenerator and handle results.

**Work:**
- In PlanDetail, replace disabled placeholder button (lines 264-269) with functional button
- Button visible when:
  - `promptGenerator?.isAvailable == true`
  - `plan.linkedCardSlugs.isEmpty == false`
- Button tap action:
  - Set `generationState = .generating`
  - Disable Generate button and TextEditor
  - Call `Task { await generatePrompt() }`
- Create `generatePrompt()` async method:
  - Guard check: plan exists, cards exist
  - Filter `viewModel.cards` to only linked cards (match slugs)
  - Call `try await promptGenerator?.generate(from: linkedCards)`
  - On success: set `phasePromptContent = result`, `generationState = .idle`
  - On error: set `generationState = .failed(error)`, `showingGenerationError = true`

**Done when:** Generate button calls PromptGenerator, populates phasePromptContent on success.

## S009: Add loading UI with shimmer

**Intent:** Show shimmer and disable controls during generation.

**Work:**
- In PlanDetail `phasePromptSection`, add conditional rendering:
  - If `generationState == .generating`:
    - Show `AIMessage()` view below TextEditor
    - Show Cancel button
    - Disable Generate button
    - Disable TextEditor
  - Else: show Generate button (if available and has cards)
- Cancel button action:
  - Call `promptGenerator?.cancel()`
  - Set `generationState = .idle`

**Done when:** Shimmer shows during generation, Cancel button works, controls disabled.

## S010: Add error alert

**Intent:** Surface generation errors visibly to user.

**Work:**
- Add `.alert` modifier in PlanDetail body:
  - `isPresented: $showingGenerationError`
  - Title: "Prompt Generation Failed"
  - Message: `generationError?.localizedDescription` or generic message
  - Dismiss button
- Set `showingGenerationError = true` and `generationError = error` in generatePrompt catch block

**Done when:** Error alert appears on generation failure with error message.

## S011: Test PromptGenerator service

**Intent:** Verify card assembly, availability, error handling.

**Work:**
- Create `Tests/HieroglyphsTests/PromptGeneratorTests.swift`
- Test `isAvailable`:
  - Mock `SystemLanguageModel.default.availability` if possible
  - Verify `isAvailable` reflects model availability
- Test `generate(from:)`:
  - Create mock cards with titles, types, priorities, body content
  - Call `generate(from:)` (may need mock LanguageModelSession or integration test)
  - Verify result is non-empty string
- Test cancellation:
  - Start generation, call `cancel()`, verify result discarded if flag set
- Test truncation:
  - Create cards with very long body content (>4096 token equivalent)
  - Verify input is truncated to fit limit
  - Verify titles and requirements prioritized over body content
- Test error handling:
  - Mock LanguageModelSession error
  - Verify error propagates correctly

**Done when:** PromptGeneratorTests.swift exists, tests pass, coverage > 80%.

## S012: Update documentation

**Intent:** Document the new prompt generation system.

**Work:**
- Update `.ushabti/docs/plans-system.md`:
  - Add section "Phase Prompt Generation" after "PHASE_PROMPT.md"
  - Document PromptGenerating protocol, PromptGenerator service
  - Document Generate button behavior and shimmer UI
  - Note 4096 token limit and truncation strategy
  - Link to TakeNote shimmer reference
- Update `.ushabti/docs/architecture.md`:
  - Add `PromptGenerating` / `PromptGenerator` to Services Layer section
  - Note FoundationModels framework usage in Platform Leverage section
- Update `.ushabti/docs/index.md`:
  - Add link to prompt generation section in plans-system.md if necessary

**Done when:** Documentation updated, reconciled with implementation, accurate.

## S013: Remove stale Future Enhancements entry for Phase Prompt Generation

**Intent:** Complete docs reconciliation by removing the now-implemented feature from the future enhancements list.

**Work:**
- Open `.ushabti/docs/plans-system.md`
- Locate the "Future Enhancements" section (around line 770)
- Remove line 774: "1. **Phase Prompt Generation:** Populate PHASE_PROMPT.md automatically from linked cards"
- Renumber remaining list items if necessary
- Verify no other stale references to this as a future feature

**Done when:** Future Enhancements section no longer lists Phase Prompt Generation as unimplemented.
