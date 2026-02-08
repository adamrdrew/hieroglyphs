import Foundation
import Yams

/// Service for reading Ushabti phase data from disk.
///
/// Discovers phase directories in `.ushabti/phases/`, parses phase metadata
/// from progress.yaml, extracts intent from phase.md, and review notes from
/// review.md. This is a read-only service.
final class PhaseService: PhaseProviding {

    enum ServiceError: Error {
        case invalidSourceDirectory
        case phasesDirectoryNotFound
    }

    func loadPhases(from sourceDirectory: String) throws -> [Phase] {
        let ushabtiPath = (sourceDirectory as NSString)
            .appendingPathComponent(".ushabti")
        let phasesPath = (ushabtiPath as NSString)
            .appendingPathComponent("phases") as String

        guard directoryExists(at: phasesPath) else {
            return []
        }

        let phaseDirectories = discoverPhaseDirectories(at: phasesPath)
        let phases = phaseDirectories.compactMap { directory in
            parsePhase(at: directory)
        }

        return phases.sorted { $0.number < $1.number }
    }

    private func directoryExists(at path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(
            atPath: path,
            isDirectory: &isDirectory
        )
        return exists && isDirectory.boolValue
    }

    private func discoverPhaseDirectories(at phasesPath: String) -> [String] {
        let fileManager = FileManager.default
        guard let contents = try? fileManager.contentsOfDirectory(
            atPath: phasesPath
        ) else {
            return []
        }

        return contents.compactMap { item in
            let fullPath = (phasesPath as NSString).appendingPathComponent(item)
            guard directoryExists(at: fullPath) else { return nil }
            guard item.contains("-") else { return nil }
            return fullPath
        }
    }

    private func parsePhase(at directoryPath: String) -> Phase? {
        let directoryName = (directoryPath as NSString).lastPathComponent

        guard let number = parsePhaseNumber(from: directoryName) else {
            print("Warning: Could not parse phase number from \(directoryName)")
            return nil
        }

        let progressPath = (directoryPath as NSString)
            .appendingPathComponent("progress.yaml")
        let phasePath = (directoryPath as NSString)
            .appendingPathComponent("phase.md")
        let reviewPath = (directoryPath as NSString)
            .appendingPathComponent("review.md")

        guard let progressData = loadProgressYaml(at: progressPath) else {
            return nil
        }

        let intent = extractIntent(from: phasePath)
        let reviewNotes = extractReviewNotes(from: reviewPath)

        return Phase(
            number: number,
            slug: directoryName,
            title: progressData.title,
            status: progressData.status,
            intent: intent,
            steps: progressData.steps,
            reviewNotes: reviewNotes
        )
    }

    private func parsePhaseNumber(from directoryName: String) -> Int? {
        let components = directoryName.split(separator: "-", maxSplits: 1)
        guard let first = components.first else { return nil }
        return Int(String(first))
    }

    private func loadProgressYaml(at path: String) -> ProgressData? {
        guard let yamlString = try? String(
            contentsOfFile: path,
            encoding: .utf8
        ) else {
            print("Warning: Could not read progress.yaml at \(path)")
            return nil
        }

        guard let yaml = try? Yams.load(yaml: yamlString) as? [String: Any] else {
            print("Warning: Could not parse YAML at \(path)")
            return nil
        }

        guard let phase = yaml["phase"] as? [String: Any] else {
            return nil
        }

        let title = phase["title"] as? String ?? ""
        let statusString = phase["status"] as? String ?? "planned"
        let status = PhaseStatus(rawValue: statusString) ?? .planned

        let stepsArray = yaml["steps"] as? [[String: Any]] ?? []
        let steps = stepsArray.compactMap { stepDict -> PhaseStep? in
            parseStep(from: stepDict)
        }

        return ProgressData(title: title, status: status, steps: steps)
    }

    private func parseStep(from dict: [String: Any]) -> PhaseStep? {
        guard let id = dict["id"] as? String else { return nil }
        let title = dict["title"] as? String ?? ""
        let implemented = dict["implemented"] as? Bool ?? false
        let reviewed = dict["reviewed"] as? Bool ?? false

        return PhaseStep(
            id: id,
            summary: title,
            implemented: implemented,
            reviewed: reviewed
        )
    }

    private func extractIntent(from phasePath: String) -> String {
        guard let content = try? String(
            contentsOfFile: phasePath,
            encoding: .utf8
        ) else {
            return ""
        }

        return extractSectionContent(
            from: content,
            sectionTitle: "## Intent"
        )
    }

    private func extractReviewNotes(from reviewPath: String) -> String {
        guard let content = try? String(
            contentsOfFile: reviewPath,
            encoding: .utf8
        ) else {
            return ""
        }
        return content
    }

    private func extractSectionContent(
        from markdown: String,
        sectionTitle: String
    ) -> String {
        let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false)
        guard let sectionIndex = lines.firstIndex(where: {
            $0.hasPrefix(sectionTitle)
        }) else {
            return ""
        }

        let contentStartIndex = lines.index(after: sectionIndex)
        var contentLines: [Substring] = []

        for line in lines[contentStartIndex...] {
            if line.hasPrefix("##") {
                break
            }
            contentLines.append(line)
        }

        return contentLines.joined(separator: "\n").trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private struct ProgressData {
        let title: String
        let status: PhaseStatus
        let steps: [PhaseStep]
    }
}
