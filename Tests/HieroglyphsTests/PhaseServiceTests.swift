import XCTest
@testable import Hieroglyphs

final class PhaseServiceTests: XCTestCase {

    private var fixtureRoot: URL!
    private var sourceDirectory: URL!
    private var phasesDirectory: URL!
    private var fileManager: FileManager!
    private var service: PhaseService!

    override func setUp() {
        super.setUp()
        fileManager = FileManager.default

        let tempDir = fileManager.temporaryDirectory
        fixtureRoot = tempDir.appendingPathComponent(UUID().uuidString)
        sourceDirectory = fixtureRoot.appendingPathComponent("source")
        phasesDirectory = sourceDirectory
            .appendingPathComponent(".ushabti")
            .appendingPathComponent("phases")

        try? fileManager.createDirectory(
            at: phasesDirectory,
            withIntermediateDirectories: true
        )

        service = PhaseService()
    }

    override func tearDown() {
        if let fixtureRoot = fixtureRoot {
            try? fileManager.removeItem(at: fixtureRoot)
        }
        super.tearDown()
    }

    func testLoadPhasesReturnsEmptyForNonExistentDirectory() throws {
        let nonExistent = "/nonexistent/path"
        let phases = try service.loadPhases(from: nonExistent)
        XCTAssertEqual(phases.count, 0)
    }

    func testLoadPhasesReturnsEmptyWhenNoPhasesExist() throws {
        let phases = try service.loadPhases(from: sourceDirectory.path)
        XCTAssertEqual(phases.count, 0)
    }

    func testLoadPhasesDiscoversSinglePhase() throws {
        try createPhase(
            number: 1,
            slug: "0001-initial-setup",
            title: "Initial Setup",
            status: "planned"
        )

        let phases = try service.loadPhases(from: sourceDirectory.path)
        XCTAssertEqual(phases.count, 1)
        XCTAssertEqual(phases.first?.number, 1)
        XCTAssertEqual(phases.first?.slug, "0001-initial-setup")
        XCTAssertEqual(phases.first?.title, "Initial Setup")
        XCTAssertEqual(phases.first?.status, .planned)
    }

    func testLoadPhasesDiscoversMultiplePhases() throws {
        try createPhase(
            number: 1,
            slug: "0001-initial-setup",
            title: "Initial Setup",
            status: "green"
        )
        try createPhase(
            number: 5,
            slug: "0005-middleware",
            title: "Middleware",
            status: "active"
        )
        try createPhase(
            number: 3,
            slug: "0003-database",
            title: "Database",
            status: "planned"
        )

        let phases = try service.loadPhases(from: sourceDirectory.path)
        XCTAssertEqual(phases.count, 3)
    }

    func testLoadPhasesSortsByNumberAscending() throws {
        try createPhase(
            number: 5,
            slug: "0005-middleware",
            title: "Middleware",
            status: "active"
        )
        try createPhase(
            number: 1,
            slug: "0001-initial-setup",
            title: "Initial Setup",
            status: "green"
        )
        try createPhase(
            number: 3,
            slug: "0003-database",
            title: "Database",
            status: "planned"
        )

        let phases = try service.loadPhases(from: sourceDirectory.path)
        XCTAssertEqual(phases[0].number, 1)
        XCTAssertEqual(phases[1].number, 3)
        XCTAssertEqual(phases[2].number, 5)
    }

    func testLoadPhasesParsesDirectoryName() throws {
        try createPhase(
            number: 42,
            slug: "0042-complex-name-with-dashes",
            title: "Complex Name",
            status: "planned"
        )

        let phases = try service.loadPhases(from: sourceDirectory.path)
        XCTAssertEqual(phases.first?.number, 42)
        XCTAssertEqual(phases.first?.slug, "0042-complex-name-with-dashes")
    }

    func testLoadPhasesExtractsIntent() throws {
        try createPhase(
            number: 1,
            slug: "0001-test",
            title: "Test",
            status: "planned",
            intent: "This is the intent section.\n\nWith multiple paragraphs."
        )

        let phases = try service.loadPhases(from: sourceDirectory.path)
        XCTAssertTrue(phases.first?.intent.contains("This is the intent section") ?? false)
    }

    func testLoadPhasesExtractsReviewNotes() throws {
        try createPhase(
            number: 1,
            slug: "0001-test",
            title: "Test",
            status: "green",
            reviewNotes: "# Review\n\nThis phase is complete."
        )

        let phases = try service.loadPhases(from: sourceDirectory.path)
        XCTAssertTrue(phases.first?.reviewNotes.contains("This phase is complete") ?? false)
    }

    func testLoadPhasesHandlesMissingReviewFile() throws {
        try createPhase(
            number: 1,
            slug: "0001-test",
            title: "Test",
            status: "planned",
            reviewNotes: nil
        )

        let phases = try service.loadPhases(from: sourceDirectory.path)
        XCTAssertEqual(phases.first?.reviewNotes, "")
    }

    func testLoadPhasesParsesSteps() throws {
        try createPhase(
            number: 1,
            slug: "0001-test",
            title: "Test",
            status: "active",
            steps: [
                PhaseStepFixture(
                    id: "S001",
                    title: "First Step",
                    implemented: true,
                    reviewed: false
                ),
                PhaseStepFixture(
                    id: "S002",
                    title: "Second Step",
                    implemented: false,
                    reviewed: false
                )
            ]
        )

        let phases = try service.loadPhases(from: sourceDirectory.path)
        XCTAssertEqual(phases.first?.steps.count, 2)
        XCTAssertEqual(phases.first?.steps[0].id, "S001")
        XCTAssertEqual(phases.first?.steps[0].summary, "First Step")
        XCTAssertEqual(phases.first?.steps[0].implemented, true)
        XCTAssertEqual(phases.first?.steps[0].reviewed, false)
        XCTAssertEqual(phases.first?.steps[1].id, "S002")
        XCTAssertEqual(phases.first?.steps[1].implemented, false)
    }

    func testLoadPhasesParsesAllStatusValues() throws {
        let statusCases: [(String, PhaseStatus)] = [
            ("planned", .planned),
            ("active", .active),
            ("green", .green),
            ("yellow", .yellow),
            ("red", .red)
        ]

        for (index, statusCase) in statusCases.enumerated() {
            try createPhase(
                number: index + 1,
                slug: String(format: "%04d-test", index + 1),
                title: "Test",
                status: statusCase.0
            )
        }

        let phases = try service.loadPhases(from: sourceDirectory.path)
        XCTAssertEqual(phases.count, 5)

        for (index, statusCase) in statusCases.enumerated() {
            XCTAssertEqual(phases[index].status, statusCase.1)
        }
    }

    func testLoadPhasesSkipsMalformedDirectory() throws {
        try createPhase(
            number: 1,
            slug: "0001-valid",
            title: "Valid",
            status: "planned"
        )

        let malformedDir = phasesDirectory.appendingPathComponent("invalid-name")
        try fileManager.createDirectory(
            at: malformedDir,
            withIntermediateDirectories: true
        )

        let phases = try service.loadPhases(from: sourceDirectory.path)
        XCTAssertEqual(phases.count, 1)
        XCTAssertEqual(phases.first?.slug, "0001-valid")
    }

    func testLoadPhasesSkipsPhaseWithMissingProgressFile() throws {
        try createPhase(
            number: 1,
            slug: "0001-valid",
            title: "Valid",
            status: "planned"
        )

        let brokenDir = phasesDirectory.appendingPathComponent("0002-broken")
        try fileManager.createDirectory(
            at: brokenDir,
            withIntermediateDirectories: true
        )
        let phaseFile = brokenDir.appendingPathComponent("phase.md")
        try "# Phase\n\n## Intent\n\nIntent text.".write(
            to: phaseFile,
            atomically: true,
            encoding: .utf8
        )

        let phases = try service.loadPhases(from: sourceDirectory.path)
        XCTAssertEqual(phases.count, 1)
        XCTAssertEqual(phases.first?.slug, "0001-valid")
    }

    // MARK: - Helpers

    private struct PhaseStepFixture {
        let id: String
        let title: String
        let implemented: Bool
        let reviewed: Bool
    }

    private func createPhase(
        number: Int,
        slug: String,
        title: String,
        status: String,
        intent: String = "Default intent.",
        steps: [PhaseStepFixture] = [],
        reviewNotes: String? = nil
    ) throws {
        let phaseDir = phasesDirectory.appendingPathComponent(slug)
        try fileManager.createDirectory(
            at: phaseDir,
            withIntermediateDirectories: true
        )

        let progressContent = createProgressYAML(
            number: number,
            slug: slug,
            title: title,
            status: status,
            steps: steps
        )
        let progressFile = phaseDir.appendingPathComponent("progress.yaml")
        try progressContent.write(to: progressFile, atomically: true, encoding: .utf8)

        let phaseContent = createPhaseMD(intent: intent)
        let phaseFile = phaseDir.appendingPathComponent("phase.md")
        try phaseContent.write(to: phaseFile, atomically: true, encoding: .utf8)

        if let reviewNotes = reviewNotes {
            let reviewFile = phaseDir.appendingPathComponent("review.md")
            try reviewNotes.write(to: reviewFile, atomically: true, encoding: .utf8)
        }
    }

    private func createProgressYAML(
        number: Int,
        slug: String,
        title: String,
        status: String,
        steps: [PhaseStepFixture]
    ) -> String {
        var content = """
        phase:
          id: \(number)
          slug: \(slug)
          title: \(title)
          status: \(status)

        steps:
        """

        if steps.isEmpty {
            content += "\n  []"
        } else {
            for step in steps {
                content += """
                \n  - id: \(step.id)
                    title: \(step.title)
                    implemented: \(step.implemented)
                    reviewed: \(step.reviewed)
                    notes: ""
                    touched: []
                """
            }
        }

        return content
    }

    private func createPhaseMD(intent: String) -> String {
        return """
        # Phase

        ## Intent

        \(intent)

        ## Scope

        Some scope text.
        """
    }
}
