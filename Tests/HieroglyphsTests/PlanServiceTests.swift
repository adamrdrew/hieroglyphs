import XCTest
@testable import Hieroglyphs

final class PlanServiceTests: XCTestCase {

    private var fixtureRoot: URL!
    private var projectURL: URL!
    private var fileManager: FileManager!
    private var service: PlanService!

    override func setUp() {
        super.setUp()
        fileManager = FileManager.default
        service = PlanService(fileManager: fileManager)

        let tempDir = fileManager.temporaryDirectory
        fixtureRoot = tempDir.appendingPathComponent(UUID().uuidString)
        projectURL = fixtureRoot.appendingPathComponent("test-project")

        try? fileManager.createDirectory(
            at: projectURL,
            withIntermediateDirectories: true
        )
    }

    override func tearDown() {
        if let fixtureRoot = fixtureRoot {
            try? fileManager.removeItem(at: fixtureRoot)
        }
        super.tearDown()
    }

    private func createPlan(
        slug: String,
        id: String,
        title: String,
        number: Int,
        status: String = "planning",
        created: String = "2026-01-01T10:00:00Z",
        updated: String = "2026-01-02T10:00:00Z"
    ) throws {
        let plansDir = projectURL.appendingPathComponent("plans")
        try? fileManager.createDirectory(
            at: plansDir,
            withIntermediateDirectories: true
        )

        let planDir = plansDir.appendingPathComponent(slug)
        try fileManager.createDirectory(
            at: planDir,
            withIntermediateDirectories: true
        )

        let planContent = """
        id: \(id)
        title: \(title)
        number: \(number)
        slug: \(slug)
        status: \(status)
        created: \(created)
        updated: \(updated)
        """

        let planFile = planDir.appendingPathComponent("plan.yaml")
        try planContent.write(to: planFile, atomically: true, encoding: .utf8)

        let phasePromptFile = planDir.appendingPathComponent("PHASE_PROMPT.md")
        try "".write(to: phasePromptFile, atomically: true, encoding: .utf8)
    }

    private func createCard(slug: String) throws {
        let cardsDir = projectURL.appendingPathComponent("cards")
        try? fileManager.createDirectory(
            at: cardsDir,
            withIntermediateDirectories: true
        )

        let cardDir = cardsDir.appendingPathComponent(slug)
        try fileManager.createDirectory(
            at: cardDir,
            withIntermediateDirectories: true
        )

        let cardContent = """
        ---
        id: \(UUID().uuidString)
        title: Test Card
        type: task
        status: todo
        priority: medium
        tags: []
        created: 2026-01-01T10:00:00Z
        updated: 2026-01-02T10:00:00Z
        slug: \(slug)
        ---

        Card body.
        """

        let cardFile = cardDir.appendingPathComponent("card.md")
        try cardContent.write(to: cardFile, atomically: true, encoding: .utf8)
    }

    func testLoadPlansReturnsEmptyArrayWhenNoPlansExist() throws {
        let plans = try service.loadPlans(projectPath: projectURL.path)
        XCTAssertEqual(plans.count, 0)
    }

    func testLoadPlansLoadsPlanWithCorrectMetadata() throws {
        try createPlan(
            slug: "0001-test-plan",
            id: "123e4567-e89b-12d3-a456-426614174000",
            title: "Test Plan",
            number: 1,
            status: "planning"
        )

        let plans = try service.loadPlans(projectPath: projectURL.path)
        XCTAssertEqual(plans.count, 1)

        let plan = plans[0]
        XCTAssertEqual(plan.title, "Test Plan")
        XCTAssertEqual(plan.number, 1)
        XCTAssertEqual(plan.slug, "0001-test-plan")
        XCTAssertEqual(plan.status, .planning)
        XCTAssertEqual(plan.linkedCardSlugs.count, 0)
    }

    func testLoadPlansDerivesLinkedCardSlugsFromSymlinks() throws {
        try createPlan(
            slug: "0001-test-plan",
            id: "123e4567-e89b-12d3-a456-426614174000",
            title: "Test Plan",
            number: 1
        )

        try createCard(slug: "test-card")

        let plansDir = projectURL.appendingPathComponent("plans")
        let planDir = plansDir.appendingPathComponent("0001-test-plan")
        let symlinkPath = planDir.appendingPathComponent("test-card")

        try fileManager.createSymbolicLink(
            atPath: symlinkPath.path,
            withDestinationPath: "../../cards/test-card/"
        )

        let plans = try service.loadPlans(projectPath: projectURL.path)
        XCTAssertEqual(plans.count, 1)
        XCTAssertEqual(plans[0].linkedCardSlugs, ["test-card"])
    }

    func testLoadPlansHandlesDanglingSymlinksWithoutThrowing() throws {
        try createPlan(
            slug: "0001-test-plan",
            id: "123e4567-e89b-12d3-a456-426614174000",
            title: "Test Plan",
            number: 1
        )

        let plansDir = projectURL.appendingPathComponent("plans")
        let planDir = plansDir.appendingPathComponent("0001-test-plan")
        let symlinkPath = planDir.appendingPathComponent("missing-card")

        try fileManager.createSymbolicLink(
            atPath: symlinkPath.path,
            withDestinationPath: "../../cards/missing-card/"
        )

        let plans = try service.loadPlans(projectPath: projectURL.path)
        XCTAssertEqual(plans.count, 1)
        XCTAssertEqual(plans[0].linkedCardSlugs, ["missing-card"])
    }

    func testCreatePlanCreatesDirectoryAndFiles() throws {
        let plan = try service.createPlan(
            title: "Test Plan",
            number: 1,
            projectPath: projectURL.path
        )

        XCTAssertEqual(plan.title, "Test Plan")
        XCTAssertEqual(plan.number, 1)
        XCTAssertEqual(plan.slug, "0001-test-plan")
        XCTAssertEqual(plan.status, .planning)

        let planDir = projectURL
            .appendingPathComponent("plans")
            .appendingPathComponent("0001-test-plan")
        let planFile = planDir.appendingPathComponent("plan.yaml")
        let phasePromptFile = planDir.appendingPathComponent("PHASE_PROMPT.md")

        XCTAssertTrue(fileManager.fileExists(atPath: planFile.path))
        XCTAssertTrue(fileManager.fileExists(atPath: phasePromptFile.path))
    }

    func testCreatePlanGeneratesCorrectSlug() throws {
        let plan = try service.createPlan(
            title: "My Test Plan",
            number: 42,
            projectPath: projectURL.path
        )

        XCTAssertEqual(plan.slug, "0042-my-test-plan")
    }

    func testUpdatePlanPreservesUnknownFields() throws {
        try createPlan(
            slug: "0001-test-plan",
            id: "123e4567-e89b-12d3-a456-426614174000",
            title: "Test Plan",
            number: 1
        )

        let plans = try service.loadPlans(projectPath: projectURL.path)
        var plan = plans[0]

        plan = Plan(
            id: plan.id,
            title: "Updated Plan",
            number: plan.number,
            slug: plan.slug,
            status: .ready,
            created: plan.created,
            updated: Date(),
            linkedCardSlugs: plan.linkedCardSlugs,
            phasePrompt: plan.phasePrompt
        )

        try service.updatePlan(plan, projectPath: projectURL.path)

        let updatedPlans = try service.loadPlans(projectPath: projectURL.path)
        XCTAssertEqual(updatedPlans[0].title, "Updated Plan")
        XCTAssertEqual(updatedPlans[0].status, .ready)
    }

    func testAddCardToPlanCreatesRelativeSymlink() throws {
        try createPlan(
            slug: "0001-test-plan",
            id: "123e4567-e89b-12d3-a456-426614174000",
            title: "Test Plan",
            number: 1
        )

        try createCard(slug: "test-card")

        try service.addCardToPlan(
            cardSlug: "test-card",
            planSlug: "0001-test-plan",
            projectPath: projectURL.path
        )

        let symlinkPath = projectURL
            .appendingPathComponent("plans")
            .appendingPathComponent("0001-test-plan")
            .appendingPathComponent("test-card")

        XCTAssertTrue(fileManager.fileExists(atPath: symlinkPath.path))

        let destination = try fileManager.destinationOfSymbolicLink(atPath: symlinkPath.path)
        XCTAssertEqual(destination, "../../cards/test-card/")
    }

    func testRemoveCardFromPlanDeletesSymlink() throws {
        try createPlan(
            slug: "0001-test-plan",
            id: "123e4567-e89b-12d3-a456-426614174000",
            title: "Test Plan",
            number: 1
        )

        try createCard(slug: "test-card")

        try service.addCardToPlan(
            cardSlug: "test-card",
            planSlug: "0001-test-plan",
            projectPath: projectURL.path
        )

        try service.removeCardFromPlan(
            cardSlug: "test-card",
            planSlug: "0001-test-plan",
            projectPath: projectURL.path
        )

        let symlinkPath = projectURL
            .appendingPathComponent("plans")
            .appendingPathComponent("0001-test-plan")
            .appendingPathComponent("test-card")

        XCTAssertFalse(fileManager.fileExists(atPath: symlinkPath.path))
    }

    func testUpdatePlanStatusUpdatesStatus() throws {
        try createPlan(
            slug: "0001-test-plan",
            id: "123e4567-e89b-12d3-a456-426614174000",
            title: "Test Plan",
            number: 1,
            status: "planning"
        )

        let plans = try service.loadPlans(projectPath: projectURL.path)
        let plan = plans[0]

        try service.updatePlanStatus(
            plan: plan,
            status: .ready,
            projectPath: projectURL.path
        )

        let updatedPlans = try service.loadPlans(projectPath: projectURL.path)
        XCTAssertEqual(updatedPlans[0].status, .ready)
    }

    func testUpdatePlanStatusToDoneMarksLinkedCardsAsDone() throws {
        try createPlan(
            slug: "0001-test-plan",
            id: "123e4567-e89b-12d3-a456-426614174000",
            title: "Test Plan",
            number: 1
        )

        try createCard(slug: "test-card")

        try service.addCardToPlan(
            cardSlug: "test-card",
            planSlug: "0001-test-plan",
            projectPath: projectURL.path
        )

        let plans = try service.loadPlans(projectPath: projectURL.path)
        let plan = plans[0]

        try service.updatePlanStatus(
            plan: plan,
            status: .done,
            projectPath: projectURL.path
        )

        let cardFile = projectURL
            .appendingPathComponent("cards")
            .appendingPathComponent("test-card")
            .appendingPathComponent("card.md")
        let cardContent = try String(contentsOf: cardFile, encoding: .utf8)

        XCTAssertTrue(cardContent.contains("status: done"))
    }

    func testUpdatePlanStatusToPlanningMarksLinkedCardsAsBacklog() throws {
        try createPlan(
            slug: "0001-test-plan",
            id: "123e4567-e89b-12d3-a456-426614174000",
            title: "Test Plan",
            number: 1,
            status: "ready"
        )

        try createCard(slug: "test-card")

        try service.addCardToPlan(
            cardSlug: "test-card",
            planSlug: "0001-test-plan",
            projectPath: projectURL.path
        )

        let plans = try service.loadPlans(projectPath: projectURL.path)
        let plan = plans[0]

        try service.updatePlanStatus(
            plan: plan,
            status: .planning,
            projectPath: projectURL.path
        )

        let cardFile = projectURL
            .appendingPathComponent("cards")
            .appendingPathComponent("test-card")
            .appendingPathComponent("card.md")
        let cardContent = try String(contentsOf: cardFile, encoding: .utf8)

        XCTAssertTrue(cardContent.contains("status: backlog"))
    }

    func testUpdatePlanStatusToReadyMarksLinkedCardsAsTodo() throws {
        try createPlan(
            slug: "0001-test-plan",
            id: "123e4567-e89b-12d3-a456-426614174000",
            title: "Test Plan",
            number: 1,
            status: "planning"
        )

        try createCard(slug: "test-card")

        try service.addCardToPlan(
            cardSlug: "test-card",
            planSlug: "0001-test-plan",
            projectPath: projectURL.path
        )

        let plans = try service.loadPlans(projectPath: projectURL.path)
        let plan = plans[0]

        try service.updatePlanStatus(
            plan: plan,
            status: .ready,
            projectPath: projectURL.path
        )

        let cardFile = projectURL
            .appendingPathComponent("cards")
            .appendingPathComponent("test-card")
            .appendingPathComponent("card.md")
        let cardContent = try String(contentsOf: cardFile, encoding: .utf8)

        XCTAssertTrue(cardContent.contains("status: todo"))
    }

    func testUpdatePlanStatusUpdatesCardTimestamp() throws {
        try createPlan(
            slug: "0001-test-plan",
            id: "123e4567-e89b-12d3-a456-426614174000",
            title: "Test Plan",
            number: 1
        )

        try createCard(slug: "test-card")

        try service.addCardToPlan(
            cardSlug: "test-card",
            planSlug: "0001-test-plan",
            projectPath: projectURL.path
        )

        let cardFile = projectURL
            .appendingPathComponent("cards")
            .appendingPathComponent("test-card")
            .appendingPathComponent("card.md")
        let originalContent = try String(contentsOf: cardFile, encoding: .utf8)
        let originalUpdated = originalContent.components(separatedBy: "updated: ")[1].components(separatedBy: "\n")[0]

        Thread.sleep(forTimeInterval: 0.1)

        let plans = try service.loadPlans(projectPath: projectURL.path)
        let plan = plans[0]

        try service.updatePlanStatus(
            plan: plan,
            status: .done,
            projectPath: projectURL.path
        )

        let updatedContent = try String(contentsOf: cardFile, encoding: .utf8)
        let newUpdated = updatedContent.components(separatedBy: "updated: ")[1].components(separatedBy: "\n")[0]

        XCTAssertNotEqual(originalUpdated, newUpdated)
    }

    func testWritePhasePromptWritesContent() throws {
        try createPlan(
            slug: "0001-test-plan",
            id: "123e4567-e89b-12d3-a456-426614174000",
            title: "Test Plan",
            number: 1
        )

        let content = "# Phase Prompt\n\nTest content."
        try service.writePhasePrompt(
            planSlug: "0001-test-plan",
            content: content,
            projectPath: projectURL.path
        )

        let phasePromptFile = projectURL
            .appendingPathComponent("plans")
            .appendingPathComponent("0001-test-plan")
            .appendingPathComponent("PHASE_PROMPT.md")

        let writtenContent = try String(contentsOf: phasePromptFile, encoding: .utf8)
        XCTAssertEqual(writtenContent, content)
    }

    func testRemoveCardSymlinksFromPlansRemovesSymlinkFromOnePlan() throws {
        try createPlan(
            slug: "0001-test-plan",
            id: "123e4567-e89b-12d3-a456-426614174000",
            title: "Test Plan",
            number: 1
        )

        try createCard(slug: "test-card")

        let plansDir = projectURL.appendingPathComponent("plans")
        let planDir = plansDir.appendingPathComponent("0001-test-plan")
        let symlinkPath = planDir.appendingPathComponent("test-card")

        try fileManager.createSymbolicLink(
            atPath: symlinkPath.path,
            withDestinationPath: "../../cards/test-card/"
        )

        XCTAssertTrue(fileManager.fileExists(atPath: symlinkPath.path))

        try service.removeCardFromPlans(
            cardSlug: "test-card",
            projectPath: projectURL.path
        )

        XCTAssertFalse(fileManager.fileExists(atPath: symlinkPath.path))
    }

    func testRemoveCardSymlinksFromPlansRemovesSymlinkFromMultiplePlans() throws {
        try createPlan(
            slug: "0001-test-plan",
            id: "123e4567-e89b-12d3-a456-426614174000",
            title: "Test Plan",
            number: 1
        )

        try createPlan(
            slug: "0002-another-plan",
            id: "223e4567-e89b-12d3-a456-426614174000",
            title: "Another Plan",
            number: 2
        )

        try createCard(slug: "test-card")

        let plansDir = projectURL.appendingPathComponent("plans")
        let planDir1 = plansDir.appendingPathComponent("0001-test-plan")
        let planDir2 = plansDir.appendingPathComponent("0002-another-plan")
        let symlinkPath1 = planDir1.appendingPathComponent("test-card")
        let symlinkPath2 = planDir2.appendingPathComponent("test-card")

        try fileManager.createSymbolicLink(
            atPath: symlinkPath1.path,
            withDestinationPath: "../../cards/test-card/"
        )

        try fileManager.createSymbolicLink(
            atPath: symlinkPath2.path,
            withDestinationPath: "../../cards/test-card/"
        )

        XCTAssertTrue(fileManager.fileExists(atPath: symlinkPath1.path))
        XCTAssertTrue(fileManager.fileExists(atPath: symlinkPath2.path))

        try service.removeCardFromPlans(
            cardSlug: "test-card",
            projectPath: projectURL.path
        )

        XCTAssertFalse(fileManager.fileExists(atPath: symlinkPath1.path))
        XCTAssertFalse(fileManager.fileExists(atPath: symlinkPath2.path))
    }

    func testRemoveCardSymlinksFromPlansHandlesCardNotFoundInAnyPlan() throws {
        try createPlan(
            slug: "0001-test-plan",
            id: "123e4567-e89b-12d3-a456-426614174000",
            title: "Test Plan",
            number: 1
        )

        XCTAssertNoThrow(
            try service.removeCardFromPlans(
                cardSlug: "nonexistent-card",
                projectPath: projectURL.path
            )
        )
    }

    func testRemoveCardSymlinksFromPlansHandlesMissingPlansDirectory() throws {
        XCTAssertNoThrow(
            try service.removeCardFromPlans(
                cardSlug: "test-card",
                projectPath: projectURL.path
            )
        )
    }

    func testEnumerateLinkedCardsWithHardLinks() throws {
        try createPlan(
            slug: "0001-test-plan",
            id: "123e4567-e89b-12d3-a456-426614174000",
            title: "Test Plan",
            number: 1
        )

        try createCard(slug: "test-card")

        let plansDir = projectURL.appendingPathComponent("plans")
        let planDir = plansDir.appendingPathComponent("0001-test-plan")
        let hardLinkPath = planDir.appendingPathComponent("test-card")

        // Create hard link by copying the card directory
        let cardDir = projectURL.appendingPathComponent("cards")
            .appendingPathComponent("test-card")
        try fileManager.copyItem(at: cardDir, to: hardLinkPath)

        let plans = try service.loadPlans(projectPath: projectURL.path)
        XCTAssertEqual(plans.count, 1)
        XCTAssertEqual(plans[0].linkedCardSlugs, ["test-card"])
    }

    func testRemoveCardFromPlansWithHardLinks() throws {
        try createPlan(
            slug: "0001-test-plan",
            id: "123e4567-e89b-12d3-a456-426614174000",
            title: "Test Plan",
            number: 1
        )

        try createCard(slug: "test-card")

        let plansDir = projectURL.appendingPathComponent("plans")
        let planDir = plansDir.appendingPathComponent("0001-test-plan")
        let hardLinkPath = planDir.appendingPathComponent("test-card")

        // Create hard link by copying the card directory
        let cardDir = projectURL.appendingPathComponent("cards")
            .appendingPathComponent("test-card")
        try fileManager.copyItem(at: cardDir, to: hardLinkPath)

        XCTAssertTrue(fileManager.fileExists(atPath: hardLinkPath.path))

        try service.removeCardFromPlans(
            cardSlug: "test-card",
            projectPath: projectURL.path
        )

        XCTAssertFalse(fileManager.fileExists(atPath: hardLinkPath.path))
    }

    func testLoadPlansWithHardLinkedCards() throws {
        try createPlan(
            slug: "0001-test-plan",
            id: "123e4567-e89b-12d3-a456-426614174000",
            title: "Test Plan",
            number: 1
        )

        try createCard(slug: "test-card")

        let plansDir = projectURL.appendingPathComponent("plans")
        let planDir = plansDir.appendingPathComponent("0001-test-plan")
        let hardLinkPath = planDir.appendingPathComponent("test-card")

        // Create hard link by copying the card directory with card.md
        let cardDir = projectURL.appendingPathComponent("cards")
            .appendingPathComponent("test-card")
        try fileManager.copyItem(at: cardDir, to: hardLinkPath)

        let plans = try service.loadPlans(projectPath: projectURL.path)
        XCTAssertEqual(plans.count, 1)
        XCTAssertTrue(plans[0].linkedCardSlugs.contains("test-card"))
    }

    // MARK: - findNextPlanNumber() Tests

    func testFindNextPlanNumber_EmptyDirectory() throws {
        let plansDir = projectURL.appendingPathComponent("plans")
        try fileManager.createDirectory(at: plansDir, withIntermediateDirectories: true)

        let number = try service.findNextPlanNumber(projectPath: projectURL.path)
        XCTAssertEqual(number, 1, "Should return 1 when plans directory is empty")
    }

    func testFindNextPlanNumber_MissingDirectory() throws {
        let number = try service.findNextPlanNumber(projectPath: projectURL.path)
        XCTAssertEqual(number, 1, "Should return 1 when plans directory does not exist")
    }

    func testFindNextPlanNumber_SinglePlan() throws {
        _ = try service.createPlan(
            title: "Test Plan",
            number: 1,
            projectPath: projectURL.path
        )

        let number = try service.findNextPlanNumber(projectPath: projectURL.path)
        XCTAssertEqual(number, 2, "Should return 2 when only plan 0001 exists")
    }

    func testFindNextPlanNumber_MultipleWithGaps() throws {
        _ = try service.createPlan(
            title: "First Plan",
            number: 1,
            projectPath: projectURL.path
        )
        _ = try service.createPlan(
            title: "Third Plan",
            number: 3,
            projectPath: projectURL.path
        )
        _ = try service.createPlan(
            title: "Fifth Plan",
            number: 5,
            projectPath: projectURL.path
        )

        let number = try service.findNextPlanNumber(projectPath: projectURL.path)
        XCTAssertEqual(number, 6, "Should return 6 (max+1), not gap-fill")
    }

    func testFindNextPlanNumber_MalformedNames() throws {
        let plansDir = projectURL.appendingPathComponent("plans")
        try fileManager.createDirectory(at: plansDir, withIntermediateDirectories: true)

        // Create plan with valid number
        _ = try service.createPlan(
            title: "Valid Plan",
            number: 2,
            projectPath: projectURL.path
        )

        // Create directories with malformed names
        let malformedDir1 = plansDir.appendingPathComponent("invalid-plan")
        let malformedDir2 = plansDir.appendingPathComponent("abc-def")
        try fileManager.createDirectory(at: malformedDir1, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: malformedDir2, withIntermediateDirectories: true)

        let number = try service.findNextPlanNumber(projectPath: projectURL.path)
        XCTAssertEqual(number, 3, "Should skip malformed directory names and return max+1")
    }

    func testFindNextPlanNumber_NonNumericPrefixes() throws {
        let plansDir = projectURL.appendingPathComponent("plans")
        try fileManager.createDirectory(at: plansDir, withIntermediateDirectories: true)

        // Create directories with non-numeric prefixes
        let dir1 = plansDir.appendingPathComponent("abc-plan")
        let dir2 = plansDir.appendingPathComponent("xyz-plan")
        try fileManager.createDirectory(at: dir1, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: dir2, withIntermediateDirectories: true)

        let number = try service.findNextPlanNumber(projectPath: projectURL.path)
        XCTAssertEqual(number, 1, "Should return 1 when all directories have non-numeric prefixes")
    }

    // MARK: - deletePlan() Tests

    func testDeletePlanMovesDirectoryToTrash() throws {
        try createPlan(
            slug: "0001-test-plan",
            id: "123e4567-e89b-12d3-a456-426614174000",
            title: "Test Plan",
            number: 1
        )

        let planDir = projectURL
            .appendingPathComponent("plans")
            .appendingPathComponent("0001-test-plan")

        XCTAssertTrue(fileManager.fileExists(atPath: planDir.path))

        try service.deletePlan(
            planSlug: "0001-test-plan",
            projectPath: projectURL.path
        )

        XCTAssertFalse(fileManager.fileExists(atPath: planDir.path))
    }

    func testDeletePlanThrowsWhenPlanNotFound() throws {
        XCTAssertThrowsError(
            try service.deletePlan(
                planSlug: "nonexistent-plan",
                projectPath: projectURL.path
            )
        ) { error in
            XCTAssertTrue(error is PlanService.PlanError)
            if let planError = error as? PlanService.PlanError {
                if case .planNotFound = planError {
                    // Expected error
                } else {
                    XCTFail("Expected PlanError.planNotFound, got \(planError)")
                }
            }
        }
    }

    func testDeletePlanPreservesLinkedCards() throws {
        try createPlan(
            slug: "0001-test-plan",
            id: "123e4567-e89b-12d3-a456-426614174000",
            title: "Test Plan",
            number: 1
        )

        try createCard(slug: "test-card")

        try service.addCardToPlan(
            cardSlug: "test-card",
            planSlug: "0001-test-plan",
            projectPath: projectURL.path
        )

        let cardDir = projectURL
            .appendingPathComponent("cards")
            .appendingPathComponent("test-card")

        XCTAssertTrue(fileManager.fileExists(atPath: cardDir.path))

        try service.deletePlan(
            planSlug: "0001-test-plan",
            projectPath: projectURL.path
        )

        XCTAssertTrue(fileManager.fileExists(atPath: cardDir.path))
    }
}
