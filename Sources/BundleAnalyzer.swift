// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Foundation
import Rosalind
import Path

@main
struct BundleAnalyzer: AsyncParsableCommand {
    @Option var path: String

    mutating func run() async throws {
        let path = try ipaBundlePath()

        let rosalind = Rosalind()
        print("Analyzing bundle at \(path)")

        let report = try await rosalind.analyzeAppBundle(at: path)
        analyzeAndPrintReport(report)
    }

    private func analyzeAndPrintReport(_ report: AppBundleReport) {
        print("\(report.name) (\(report.version)) bundle report is ready:")

        if let downloadSize = report.downloadSize {
            print("Download size: \(downloadSize.formattedSize)")
        }

        print("Install size: \(report.installSize.formattedSize)")
        print("Total artifacts: \(report.artifacts.count)")

        print("") // an empty line between artifacts count and their contents

        var contents: [(String, Int)] = []
        let sortedArtifacts = report.artifacts.sorted(by: { $0.size > $1.size })
        for artifact in sortedArtifacts {
            analyzeArtifact(artifact, indent: 0, contents: &contents)
        }

        printArtifacts(contents)
    }

    private func analyzeArtifact(
        _ artifact: AppBundleArtifact,
        indent: Int,
        contents: inout [(String, Int)]
    ) {
        let name = artifact.path.components(separatedBy: "/").last ?? ""
        contents.append(("\(name): \(artifact.size.formattedSize)", indent))

        guard artifact.shouldPrintChildren else { return }

        for child in artifact.sortedChildren {
            analyzeArtifact(child, indent: indent + 1, contents: &contents)
        }
    }

    private func printArtifacts(_ messages: [(text: String, indent: Int)]) {
        for message in messages {
            let indentString = String(repeating: " ", count: message.indent * 4) + "∙"
            print(indentString, message.text)
        }
    }

    func ipaBundlePath() throws -> AbsolutePath {
        let workingDirectory = try AbsolutePath(validating: FileManager.default.currentDirectoryPath)

        guard let validatedPath = try? AbsolutePath(
            validating: path,
            relativeTo: workingDirectory
        ), validatedPath.extension == "ipa" else {
            throw ValidationError("The provided path is not an IPA file.")
        }

        return validatedPath
    }
}

extension AppBundleArtifact {
    var sortedChildren: [AppBundleArtifact] {
        children?.sorted { $0.size > $1.size } ?? []
    }

    var shouldPrintChildren: Bool {
        if path.hasSuffix(".car") || path.hasSuffix(".lproj") {
            return false
        }

        return true
    }
}

extension Int {
    var formattedSize: String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var size = Double(self)
        var unitIndex = 0

        while size >= 1024 && unitIndex < units.count - 1 {
            size /= 1024
            unitIndex += 1
        }

        return String(format: "%.1f", size) + units[unitIndex]
    }
}
