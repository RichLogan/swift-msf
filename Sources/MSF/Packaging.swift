/// The type of payload encapsulation for an MSF track.
public enum Packaging: String, Codable, Sendable, Equatable {
    case loc
    case mediatimeline
    case eventtimeline
}
