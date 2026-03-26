import ArgumentParser
import Dispatch
#if canImport(Glibc)
@preconcurrency import Glibc
#endif
import Foundation
import MSF

@main
struct PublishCatalog: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "publish-catalog",
        abstract: "Generate and publish an MSF catalog via qclient, restarting on failure."
    )

    @Option(name: .long, help: "Relay URL")
    var relay: String = "moq://localhost:33435"

    @Option(name: .long, help: "Encoded namespace prefix (e.g. cisco.2ewebex.2ecom-nab-v1)")
    var namespace: String = "cisco.2ewebex.2ecom-nab-v1"

    @Option(name: .long, help: "Path to catalog output file")
    var catalogFile: String = "/tmp/msf-catalog.json"

    @Option(name: .long, help: "Path to qclient binary")
    var qclient: String? = nil

    mutating func run() async throws {
        disableOutputBuffering()
        let buildDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().path
        let msfGenPath = findInPath("msf-gen") ?? "\(buildDir)/msf-gen"
        let qclientPath = qclient ?? findInPath("qclient") ?? "qclient"

        let publisherId = "publisher_0XCA1A109"
        print("Publisher ID: \(publisherId)")

        // Generate catalog.
        _ = FileManager.default.createFile(atPath: catalogFile, contents: nil)
        let gen = Process()
        gen.executableURL = URL(fileURLWithPath: msfGenPath)
        gen.arguments = ["--namespace", namespace, "--publisher-id", publisherId]
        gen.standardOutput = try FileHandle(forWritingTo: URL(fileURLWithPath: catalogFile))
        try gen.run()
        gen.waitUntilExit()
        guard gen.terminationStatus == 0 else {
            throw ExitCode(gen.terminationStatus)
        }

        let prefix = try TrackNamespace(parsing: namespace)
        let catalogNamespace = TrackNamespace(prefix.tuples + ["catalog", publisherId])
        let pubNamespace = catalogNamespace.tuples.joined(separator: ",")

        // Supervise qclient with restart-on-failure.
        // Race the supervisor loop against a termination signal.
        let relay = relay
        let catalogFile = catalogFile
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await awaitTerminationSignal()
            }
            group.addTask {
                while !Task.isCancelled {
                    print("Starting qclient (relay: \(relay))...")
                    let proc = Process()
                    proc.executableURL = URL(fileURLWithPath: qclientPath)
                    proc.arguments = [
                        "-r", relay,
                        "--pub_namespace", pubNamespace,
                        "--pub_name", "catalog",
                        "--watch", catalogFile,
                    ]

                    do {
                        try await runProcess(proc)
                        if Task.isCancelled { break }
                        print("qclient exited (\(proc.terminationStatus)), restarting in 5s...")
                    } catch {
                        if Task.isCancelled { break }
                        print("Failed to start qclient: \(error), retrying in 5s...")
                    }
                    try? await Task.sleep(for: .seconds(5))
                }
            }

            // First to finish wins — cancel the other.
            await group.next()
            group.cancelAll()
        }
    }

    private func findInPath(_ name: String) -> String? {
        let which = Process()
        which.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        which.arguments = ["which", name]
        let pipe = Pipe()
        which.standardOutput = pipe
        which.standardError = FileHandle.nullDevice
        try? which.run()
        which.waitUntilExit()
        guard which.terminationStatus == 0 else { return nil }
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private func disableOutputBuffering() {
    setbuf(stdout, nil)
}

// Bridges Process into structured concurrency — interrupts the process on cancellation.
private func runProcess(_ proc: Process) async throws {
    try await withTaskCancellationHandler {
        try await withCheckedThrowingContinuation { continuation in
            proc.terminationHandler = { _ in continuation.resume() }
            do {
                try proc.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    } onCancel: {
        if proc.isRunning { proc.interrupt() }
    }
}

// Waits for SIGINT or SIGTERM using dispatch sources bridged into a continuation.
private func awaitTerminationSignal() async {
    signal(SIGINT, SIG_IGN)
    signal(SIGTERM, SIG_IGN)
    await withCheckedContinuation { continuation in
        let sigint = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        let sigterm = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        var resumed = false
        let handler = {
            guard !resumed else { return }
            resumed = true
            sigint.cancel()
            sigterm.cancel()
            continuation.resume()
        }
        sigint.setEventHandler(handler: handler)
        sigterm.setEventHandler(handler: handler)
        sigint.resume()
        sigterm.resume()
    }
}
