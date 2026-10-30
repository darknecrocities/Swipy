import Foundation
import AppKit

/// Represents the release manifest metadata published by CI/CD or GitHub Releases.
public struct ReleaseManifest: Codable, Equatable, Sendable {
    public let version: String
    public let commitSHA: String
    public let buildTimestamp: String
    public let downloadURL: String

    public init(version: String, commitSHA: String, buildTimestamp: String, downloadURL: String) {
        self.version = version
        self.commitSHA = commitSHA
        self.buildTimestamp = buildTimestamp
        self.downloadURL = downloadURL
    }
}

/// Lifecycle state for the in-app Over-The-Air (OTA) updater.
public enum AppUpdateStatus: Equatable, Sendable {
    case idle
    case checking
    case upToDate(version: String, commitSHA: String)
    case updateAvailable(manifest: ReleaseManifest)
    case downloading
    case installing
    case failed(String)
}

/// Over-The-Air (OTA) updater that checks GitHub Releases / CI artifacts for new commits on `main`
/// and downloads, verifies, swaps, and relaunches `Swipy.app` in-place.
@MainActor
public final class AppUpdateManager: ObservableObject {
    public static let shared = AppUpdateManager()

    @Published public var status: AppUpdateStatus = .idle
    @Published public var autoCheckEnabled: Bool = true
    @Published public var lastCheckedDate: Date?

    public let currentVersion: String
    public let currentCommitSHA: String
    private var periodicTimer: Timer?

    nonisolated private static let githubReleaseAPI = URL(string: "https://api.github.com/repos/darknecrocities/Swipy/releases/tags/latest")!
    nonisolated private static let fallbackZipURL = "https://github.com/darknecrocities/Swipy/releases/latest/download/Swipy-macOS.zip"

    public init(
        bundle: Bundle = .main
    ) {
        self.currentVersion = (bundle.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0.0"
        self.currentCommitSHA = (bundle.infoDictionary?["SwipyCommitSHA"] as? String) ?? "local-dev"
    }

    /// Starts periodic background checks (every 30 minutes) and an initial check after launch.
    public func startAutomaticUpdateChecks() {
        periodicTimer?.invalidate()
        let timer = Timer(timeInterval: 1800, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.autoCheckEnabled else { return }
                await self.checkForUpdates(silent: true)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        periodicTimer = timer

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            if self.autoCheckEnabled {
                await self.checkForUpdates(silent: true)
            }
        }
    }

    /// Pure comparison helper used by unit tests and the live checker to evaluate if a remote manifest is newer.
    public nonisolated static func shouldOfferUpdate(
        localVersion: String,
        localCommitSHA: String,
        remote: ReleaseManifest
    ) -> Bool {
        let cleanLocalSHA = localCommitSHA.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanRemoteSHA = remote.commitSHA.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if !cleanRemoteSHA.isEmpty && cleanLocalSHA != "local-dev" && !cleanLocalSHA.isEmpty {
            let prefixLen = min(7, min(cleanLocalSHA.count, cleanRemoteSHA.count))
            if prefixLen >= 7 {
                return cleanLocalSHA.prefix(prefixLen) != cleanRemoteSHA.prefix(prefixLen)
            }
        }
        return remote.version.compare(localVersion, options: .numeric) == .orderedDescending
    }

    /// Queries the GitHub Release API (`tags/latest`) to inspect the newest build and commit SHA.
    public func checkForUpdates(silent: Bool = false) async {
        if !silent {
            status = .checking
        }

        var request = URLRequest(url: Self.githubReleaseAPI)
        request.timeoutInterval = 10.0
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                if !silent {
                    status = .upToDate(version: currentVersion, commitSHA: currentCommitSHA)
                }
                lastCheckedDate = Date()
                return
            }

            if let manifest = Self.parseGitHubReleasePayload(data, defaultVersion: currentVersion) {
                lastCheckedDate = Date()
                if Self.shouldOfferUpdate(
                    localVersion: currentVersion,
                    localCommitSHA: currentCommitSHA,
                    remote: manifest
                ) {
                    status = .updateAvailable(manifest: manifest)
                } else {
                    status = .upToDate(version: currentVersion, commitSHA: currentCommitSHA)
                }
            } else if !silent {
                status = .upToDate(version: currentVersion, commitSHA: currentCommitSHA)
            }
        } catch {
            if !silent {
                status = .failed("Could not reach update server: \(error.localizedDescription)")
            }
        }
    }

    /// Parses a GitHub Releases API JSON response and extracts the commit SHA, version, and ZIP asset URL.
    public nonisolated static func parseGitHubReleasePayload(_ data: Data, defaultVersion: String = "1.0.0") -> ReleaseManifest? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let tagName = (json["tag_name"] as? String) ?? defaultVersion
        let publishedAt = (json["published_at"] as? String) ?? ""
        let body = (json["body"] as? String) ?? ""
        let targetCommitish = (json["target_commitish"] as? String) ?? ""

        var extractedSHA = ""
        if let range = body.range(of: #"Commit:\s*`?([0-9a-fA-F]{7,40})`?"#, options: .regularExpression) {
            let match = String(body[range])
            let parts = match.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
            if let shaCandidate = parts.last, shaCandidate.count >= 7 {
                extractedSHA = String(shaCandidate.prefix(7)).lowercased()
            }
        }
        if extractedSHA.isEmpty, targetCommitish.count >= 7, targetCommitish != "main" {
            extractedSHA = String(targetCommitish.prefix(7)).lowercased()
        }

        var zipURL = fallbackZipURL
        if let assets = json["assets"] as? [[String: Any]] {
            for asset in assets {
                if let name = asset["name"] as? String,
                   name.hasSuffix(".zip"),
                   let browserURL = asset["browser_download_url"] as? String {
                    zipURL = browserURL
                    break
                }
            }
        }

        let cleanVersion = tagName == "latest" ? defaultVersion : tagName.replacingOccurrences(of: "v", with: "")
        return ReleaseManifest(
            version: cleanVersion,
            commitSHA: extractedSHA.isEmpty ? "latest" : extractedSHA,
            buildTimestamp: publishedAt,
            downloadURL: zipURL
        )
    }

    /// Downloads `Swipy-macOS.zip`, verifies its code signature, replaces the running `.app` bundle, and relaunches.
    public func downloadAndInstallUpdate(from manifest: ReleaseManifest) async {
        guard let url = URL(string: manifest.downloadURL) else {
            status = .failed("Invalid download URL.")
            return
        }

        status = .downloading
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 30.0
            let (tempZipURL, response) = try await URLSession.shared.download(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                status = .failed("Download failed with non-200 status.")
                return
            }

            status = .installing
            let fm = FileManager.default
            let stagingDir = fm.temporaryDirectory.appendingPathComponent("SwipyUpdate-\(UUID().uuidString)", isDirectory: true)
            try fm.createDirectory(at: stagingDir, withIntermediateDirectories: true)
            let stagedZip = stagingDir.appendingPathComponent("Swipy-macOS.zip")
            try fm.moveItem(at: tempZipURL, to: stagedZip)

            // Extract archive via /usr/bin/ditto
            let unzipProc = Process()
            unzipProc.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            unzipProc.arguments = ["-x", "-k", stagedZip.path, stagingDir.path]
            try unzipProc.run()
            unzipProc.waitUntilExit()

            let extractedApp = stagingDir.appendingPathComponent("Swipy.app")
            guard fm.fileExists(atPath: extractedApp.path) else {
                status = .failed("Extracted archive did not contain Swipy.app.")
                return
            }

            // Verify code signature before replacing bundle
            let verifyProc = Process()
            verifyProc.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
            verifyProc.arguments = ["--verify", "--deep", extractedApp.path]
            try verifyProc.run()
            verifyProc.waitUntilExit()
            guard verifyProc.terminationStatus == 0 else {
                status = .failed("Downloaded Swipy.app failed code signature verification.")
                return
            }

            let targetBundlePath = Bundle.main.bundleURL.path
            guard targetBundlePath.hasSuffix(".app") else {
                // Running from swift run CLI rather than .app bundle; open staging folder
                NSWorkspace.shared.activateFileViewerSelecting([extractedApp])
                status = .upToDate(version: manifest.version, commitSHA: manifest.commitSHA)
                return
            }

            let pid = ProcessInfo.processInfo.processIdentifier
            let relaunchScript = """
            (while kill -0 \(pid) 2>/dev/null; do sleep 0.2; done; \
            rm -rf "\(targetBundlePath)" && \
            mv "\(extractedApp.path)" "\(targetBundlePath)" && \
            xattr -cr "\(targetBundlePath)" 2>/dev/null || true; \
            open "\(targetBundlePath)"; \
            rm -rf "\(stagingDir.path)") &
            """

            let helper = Process()
            helper.executableURL = URL(fileURLWithPath: "/bin/sh")
            helper.arguments = ["-c", relaunchScript]
            try helper.run()

            NSApplication.shared.terminate(nil)
        } catch {
            status = .failed("Update installation error: \(error.localizedDescription)")
        }
    }
}
