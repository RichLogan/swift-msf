/// The role of content carried by an MSF track.
///
/// The MSF spec defines reserved roles but allows custom ones,
/// so this is an open type rather than a closed enum.
public struct TrackRole: RawRepresentable, Codable, Sendable, Equatable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public static let video = TrackRole(rawValue: "video")
    public static let audio = TrackRole(rawValue: "audio")
    public static let audioDescription = TrackRole(rawValue: "audiodescription")
    public static let mediaTimeline = TrackRole(rawValue: "mediatimeline")
    public static let eventTimeline = TrackRole(rawValue: "eventtimeline")
    public static let caption = TrackRole(rawValue: "caption")
    public static let subtitle = TrackRole(rawValue: "subtitle")
    public static let signLanguage = TrackRole(rawValue: "signlanguage")
}
