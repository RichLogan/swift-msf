/// A full (non-delta) MSF catalog.
public struct Catalog: Codable, Sendable, Equatable {
    public var version: Int
    public var tracks: [Track]
    public var generatedAt: Int?
    public var isComplete: Bool?

    public init(
        version: Int,
        tracks: [Track],
        generatedAt: Int? = nil,
        isComplete: Bool? = nil
    ) {
        self.version = version
        self.tracks = tracks
        self.generatedAt = generatedAt
        self.isComplete = isComplete
    }
}
