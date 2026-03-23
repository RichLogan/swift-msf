import ArgumentParser
import Foundation
import MSF

@main
struct MSFGen: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "msf-gen",
        abstract: "Generate an MSF template catalog for a meeting."
    )

    @Option(name: .long, help: "Meeting namespace (e.g. meeting.example.com/room42)")
    var namespace: String

    @Option(
        name: .long,
        help: "Comma-separated video qualities: \(QualityPreset.allCases.map(\.rawValue).joined(separator: ","))"
    )
    var qualities: String = "1080p,720p,360p"

    @Option(name: .long, help: "Template participant name")
    var participant: String = "participant"

    func run() throws {
        let presets = try parseQualities(qualities)

        var tracks: [Track] = presets.map { preset in
            Track(
                name: preset.rawValue,
                packaging: .loc,
                isLive: true,
                namespace: TrackNamespace([namespace, preset.codec, participant]),
                role: .video,
                renderGroup: 1,
                altGroup: 1,
                codec: preset.codec,
                framerate: preset.framerate,
                bitrate: preset.bitrate,
                width: preset.width,
                height: preset.height
            )
        }

        tracks.append(Track(
            name: "audio",
            packaging: .loc,
            isLive: true,
            namespace: TrackNamespace([namespace, "opus", participant]),
            role: .audio,
            renderGroup: 1,
            codec: "opus",
            bitrate: 32000,
            samplerate: 48000,
            channelConfig: "2"
        ))

        let catalog = Catalog(version: 1, tracks: tracks)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(catalog)
        print(String(data: data, encoding: .utf8)!)
    }

    private func parseQualities(_ input: String) throws -> [QualityPreset] {
        try input.split(separator: ",").map { name in
            guard let preset = QualityPreset(rawValue: String(name)) else {
                throw ValidationError(
                    "Unknown quality '\(name)'. Valid: \(QualityPreset.allCases.map(\.rawValue).joined(separator: ", "))"
                )
            }
            return preset
        }
    }
}
