import Foundation
import Yams

/// Concrete implementation of plan I/O operations using the filesystem.
///
/// Plans are stored as directories with plan.yaml frontmatter files and
/// symlinks to cards. This service handles all plan CRUD operations and
/// maintains relative symlinks for portability.
final class PlanService: PlanProviding {

    enum PlanError: Error {
        case invalidDirectory
        case yamlParsingFailed(Error)
        case directoryCreationFailed(Error)
        case fileWriteFailed(Error)
        case planNotFound
        case cardNotFound
        case symlinkCreationFailed(Error)
    }

    private let fileManager: FileManager
    private let dateFormatter = ISO8601DateFormatter()

    /// Initialize with optional FileManager dependency.
    ///
    /// - Parameter fileManager: FileManager instance (defaults to .default)
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    // MARK: - Date Formatting Helpers

    private func formatDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }

    private func parseDate(_ string: String) -> Date? {
        return dateFormatter.date(from: string)
    }

    // MARK: - Read Operations

    func loadPlans(projectPath: String) throws -> [Plan] {
        let projectURL = URL(fileURLWithPath: projectPath)
        let plansURL = projectURL.appendingPathComponent("plans")

        guard fileManager.fileExists(atPath: plansURL.path) else {
            return []
        }

        let planURLs = try discoverPlanDirectories(in: plansURL)
        return try parsePlans(from: planURLs, projectPath: projectPath)
    }

    private func discoverPlanDirectories(in plansURL: URL) throws -> [URL] {
        let contents = try fileManager.contentsOfDirectory(
            at: plansURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        return contents.filter { url in
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                return false
            }

            let planFile = url.appendingPathComponent("plan.yaml")
            return fileManager.fileExists(atPath: planFile.path)
        }
    }

    private func parsePlans(from urls: [URL], projectPath: String) throws -> [Plan] {
        var plans: [Plan] = []

        for url in urls {
            do {
                let plan = try parsePlan(from: url, projectPath: projectPath)
                plans.append(plan)
            } catch {
                // Log and skip malformed plans
                print("Warning: Failed to parse plan at \(url.path): \(error)")
                continue
            }
        }

        return plans
    }

    private func parsePlan(from url: URL, projectPath: String) throws -> Plan {
        let planFileURL = url.appendingPathComponent("plan.yaml")
        let yamlContent = try String(contentsOf: planFileURL, encoding: .utf8)

        let frontmatter: [String: Any]
        do {
            if let parsed = try Yams.load(yaml: yamlContent) as? [String: Any] {
                frontmatter = parsed
            } else {
                frontmatter = [:]
            }
        } catch {
            throw PlanError.yamlParsingFailed(error)
        }

        guard let idString = frontmatter["id"] as? String,
              let id = UUID(uuidString: idString),
              let title = frontmatter["title"] as? String,
              let number = frontmatter["number"] as? Int else {
            throw PlanError.yamlParsingFailed(
                NSError(domain: "PlanService", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Missing required fields: id, title, or number"
                ])
            )
        }

        let statusString = frontmatter["status"] as? String ?? "planning"
        let status = PlanStatus(rawValue: statusString) ?? .planning
        let slug = url.lastPathComponent

        let created: Date
        if let createdDate = frontmatter["created"] as? Date {
            created = createdDate
        } else if let createdString = frontmatter["created"] as? String,
                  let parsedCreated = parseDate(createdString) {
            created = parsedCreated
        } else {
            created = Date()
        }

        let updated: Date
        if let updatedDate = frontmatter["updated"] as? Date {
            updated = updatedDate
        } else if let updatedString = frontmatter["updated"] as? String,
                  let parsedUpdated = parseDate(updatedString) {
            updated = parsedUpdated
        } else {
            updated = Date()
        }

        // Enumerate symlinks to derive linked card slugs
        let linkedCardSlugs = try enumerateLinkedCards(in: url)

        // Read PHASE_PROMPT.md content
        let phasePromptURL = url.appendingPathComponent("PHASE_PROMPT.md")
        let phasePrompt: String
        if fileManager.fileExists(atPath: phasePromptURL.path) {
            phasePrompt = try String(contentsOf: phasePromptURL, encoding: .utf8)
        } else {
            phasePrompt = ""
        }

        return Plan(
            id: id,
            title: title,
            number: number,
            slug: slug,
            status: status,
            created: created,
            updated: updated,
            linkedCardSlugs: linkedCardSlugs,
            phasePrompt: phasePrompt
        )
    }

    private func enumerateLinkedCards(in planURL: URL) throws -> [String] {
        let contents = try fileManager.contentsOfDirectory(
            at: planURL,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
            options: [.skipsHiddenFiles]
        )

        var cardSlugs: [String] = []
        for item in contents {
            // Skip plan metadata files
            guard item.lastPathComponent != "plan.yaml",
                  item.lastPathComponent != "PHASE_PROMPT.md" else {
                continue
            }

            let values = try item.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])

            // Include symlinks (even dangling ones) or directories containing card.md
            let isSymlink = values.isSymbolicLink == true
            let isDirectoryWithCard = values.isDirectory == true &&
                fileManager.fileExists(atPath: item.appendingPathComponent("card.md").path)

            if isSymlink || isDirectoryWithCard {
                cardSlugs.append(item.lastPathComponent)
            }
        }

        return cardSlugs.sorted()
    }

    // MARK: - Write Operations

    func createPlan(title: String, number: Int, projectPath: String) throws -> Plan {
        let slug = generatePlanSlug(title: title, number: number)
        let projectURL = URL(fileURLWithPath: projectPath)
        let plansURL = projectURL.appendingPathComponent("plans")
        let planURL = plansURL.appendingPathComponent(slug)

        // Create plans directory if it doesn't exist
        if !fileManager.fileExists(atPath: plansURL.path) {
            do {
                try fileManager.createDirectory(
                    at: plansURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                throw PlanError.directoryCreationFailed(error)
            }
        }

        // Create plan directory
        do {
            try fileManager.createDirectory(
                at: planURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            throw PlanError.directoryCreationFailed(error)
        }

        let id = UUID()
        let now = Date()
        let frontmatter: [String: Any] = [
            "id": id.uuidString,
            "title": title,
            "number": number,
            "slug": slug,
            "status": "planning",
            "created": formatDate(now),
            "updated": formatDate(now)
        ]

        // Write plan.yaml
        let planFileURL = planURL.appendingPathComponent("plan.yaml")
        do {
            let yamlString = try Yams.dump(object: frontmatter, allowUnicode: true)
            try yamlString.write(to: planFileURL, atomically: true, encoding: .utf8)
        } catch {
            throw PlanError.fileWriteFailed(error)
        }

        // Write empty PHASE_PROMPT.md
        let phasePromptURL = planURL.appendingPathComponent("PHASE_PROMPT.md")
        do {
            try "".write(to: phasePromptURL, atomically: true, encoding: .utf8)
        } catch {
            throw PlanError.fileWriteFailed(error)
        }

        return Plan(
            id: id,
            title: title,
            number: number,
            slug: slug,
            status: .planning,
            created: now,
            updated: now,
            linkedCardSlugs: [],
            phasePrompt: ""
        )
    }

    private func generatePlanSlug(title: String, number: Int) -> String {
        let titleSlug = SlugGenerator.generateSlug(from: title)
        let paddedNumber = String(format: "%04d", number)
        return "\(paddedNumber)-\(titleSlug)"
    }

    func updatePlan(_ plan: Plan, projectPath: String) throws {
        let projectURL = URL(fileURLWithPath: projectPath)
        let plansURL = projectURL.appendingPathComponent("plans")
        let planURL = plansURL.appendingPathComponent(plan.slug)
        let planFileURL = planURL.appendingPathComponent("plan.yaml")

        guard fileManager.fileExists(atPath: planFileURL.path) else {
            throw PlanError.planNotFound
        }

        let existingYAML = try String(contentsOf: planFileURL, encoding: .utf8)
        var frontmatter: [String: Any]
        do {
            if let parsed = try Yams.load(yaml: existingYAML) as? [String: Any] {
                frontmatter = parsed
            } else {
                frontmatter = [:]
            }
        } catch {
            throw PlanError.yamlParsingFailed(error)
        }

        // Update fields
        frontmatter["id"] = plan.id.uuidString
        frontmatter["title"] = plan.title
        frontmatter["number"] = plan.number
        frontmatter["slug"] = plan.slug
        frontmatter["status"] = plan.status.rawValue
        frontmatter["created"] = formatDate(plan.created)
        frontmatter["updated"] = formatDate(Date())

        // Write back
        do {
            let yamlString = try Yams.dump(object: frontmatter, allowUnicode: true)
            try yamlString.write(to: planFileURL, atomically: true, encoding: .utf8)
        } catch {
            throw PlanError.fileWriteFailed(error)
        }
    }

    // MARK: - Card Operations

    func addCardToPlan(cardSlug: String, planSlug: String, projectPath: String) throws {
        let projectURL = URL(fileURLWithPath: projectPath)
        let plansURL = projectURL.appendingPathComponent("plans")
        let planURL = plansURL.appendingPathComponent(planSlug)
        let symlinkURL = planURL.appendingPathComponent(cardSlug)

        // Check that card exists
        let cardsURL = projectURL.appendingPathComponent("cards")
        let cardURL = cardsURL.appendingPathComponent(cardSlug)
        guard fileManager.fileExists(atPath: cardURL.path) else {
            throw PlanError.cardNotFound
        }

        // Create relative symlink: ../../cards/{cardSlug}/
        let relativeTarget = "../../cards/\(cardSlug)/"
        do {
            try fileManager.createSymbolicLink(
                atPath: symlinkURL.path,
                withDestinationPath: relativeTarget
            )
        } catch {
            throw PlanError.symlinkCreationFailed(error)
        }
    }

    func removeCardFromPlan(cardSlug: String, planSlug: String, projectPath: String) throws {
        let projectURL = URL(fileURLWithPath: projectPath)
        let plansURL = projectURL.appendingPathComponent("plans")
        let planURL = plansURL.appendingPathComponent(planSlug)
        let symlinkURL = planURL.appendingPathComponent(cardSlug)

        guard fileManager.fileExists(atPath: symlinkURL.path) else {
            throw PlanError.planNotFound
        }

        do {
            try fileManager.removeItem(at: symlinkURL)
        } catch {
            throw PlanError.fileWriteFailed(error)
        }
    }

    func updatePlanStatus(plan: Plan, status: PlanStatus, projectPath: String) throws {
        // Update the plan status
        var updatedPlan = plan
        updatedPlan = Plan(
            id: plan.id,
            title: plan.title,
            number: plan.number,
            slug: plan.slug,
            status: status,
            created: plan.created,
            updated: Date(),
            linkedCardSlugs: plan.linkedCardSlugs,
            phasePrompt: plan.phasePrompt
        )
        try updatePlan(updatedPlan, projectPath: projectPath)

        // Map plan status to card status and update all linked cards
        let targetCardStatus = mapPlanStatusToCardStatus(status)
        try updateLinkedCardStatuses(
            plan: plan,
            status: targetCardStatus,
            projectPath: projectPath
        )
    }

    private func mapPlanStatusToCardStatus(_ planStatus: PlanStatus) -> CardStatus {
        switch planStatus {
        case .planning:
            return .backlog
        case .ready:
            return .todo
        case .inProgress:
            return .inProgress
        case .done:
            return .done
        }
    }

    private func updateLinkedCardStatuses(
        plan: Plan,
        status: CardStatus,
        projectPath: String
    ) throws {
        let projectURL = URL(fileURLWithPath: projectPath)
        let cardsURL = projectURL.appendingPathComponent("cards")

        for cardSlug in plan.linkedCardSlugs {
            let cardURL = cardsURL.appendingPathComponent(cardSlug)
            let cardFileURL = cardURL.appendingPathComponent("card.md")

            // Skip dangling symlinks
            guard fileManager.fileExists(atPath: cardFileURL.path) else {
                print("Warning: Skipping dangling symlink for card: \(cardSlug)")
                continue
            }

            // Read card, update status, write back
            do {
                let existingMarkdown = try String(contentsOf: cardFileURL, encoding: .utf8)
                let parsed = try FrontmatterParser.parse(existingMarkdown)
                var frontmatter = parsed.frontmatter

                frontmatter["status"] = status.rawValue
                frontmatter["updated"] = formatDate(Date())

                let markdown = try FrontmatterParser.serialize(
                    frontmatter: frontmatter,
                    body: parsed.body
                )

                try markdown.write(to: cardFileURL, atomically: true, encoding: .utf8)
            } catch {
                print("Warning: Failed to update card \(cardSlug): \(error)")
                continue
            }
        }
    }

    func writePhasePrompt(planSlug: String, content: String, projectPath: String) throws {
        let projectURL = URL(fileURLWithPath: projectPath)
        let plansURL = projectURL.appendingPathComponent("plans")
        let planURL = plansURL.appendingPathComponent(planSlug)
        let phasePromptURL = planURL.appendingPathComponent("PHASE_PROMPT.md")

        do {
            try content.write(to: phasePromptURL, atomically: true, encoding: .utf8)
        } catch {
            throw PlanError.fileWriteFailed(error)
        }
    }

    func removeCardFromPlans(cardSlug: String, projectPath: String) throws {
        let projectURL = URL(fileURLWithPath: projectPath)
        let plansURL = projectURL.appendingPathComponent("plans")

        // If plans directory doesn't exist, no cleanup needed
        guard fileManager.fileExists(atPath: plansURL.path) else {
            return
        }

        // Get all plan directories
        let planURLs = try discoverPlanDirectories(in: plansURL)

        // For each plan directory, check for and remove matching card directory
        for planURL in planURLs {
            let cardURL = planURL.appendingPathComponent(cardSlug)

            // Skip if card directory doesn't exist
            guard fileManager.fileExists(atPath: cardURL.path) else {
                continue
            }

            // Remove the card directory (symlink, hard link, or regular directory)
            do {
                try fileManager.removeItem(at: cardURL)
            } catch {
                print("Warning: Failed to remove card at \(cardURL.path): \(error)")
                continue
            }
        }
    }

    func findNextPlanNumber(projectPath: String) throws -> Int {
        let projectURL = URL(fileURLWithPath: projectPath)
        let plansURL = projectURL.appendingPathComponent("plans")

        // Return 1 if plans directory doesn't exist
        guard fileManager.fileExists(atPath: plansURL.path) else {
            return 1
        }

        // Get all plan directories
        let contents = try fileManager.contentsOfDirectory(
            at: plansURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        // Extract numbers from directory names
        var maxNumber = 0
        for url in contents {
            let dirName = url.lastPathComponent

            // Split on hyphen and get first component
            let components = dirName.split(separator: "-", maxSplits: 1)
            guard let firstComponent = components.first else {
                continue
            }

            // Try to parse as integer
            if let number = Int(firstComponent) {
                maxNumber = max(maxNumber, number)
            }
        }

        return maxNumber + 1
    }
}
