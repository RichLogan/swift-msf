/// Baked-in video quality presets.
enum QualityPreset: String, CaseIterable, Sendable {
    case p1080 = "1080p"
    case p720 = "720p"
    case p360 = "360p"

    var width: Int {
        switch self {
        case .p1080: 1920
        case .p720: 1280
        case .p360: 640
        }
    }

    var height: Int {
        switch self {
        case .p1080: 1080
        case .p720: 720
        case .p360: 360
        }
    }

    var bitrate: Int {
        switch self {
        case .p1080: 1_500_000
        case .p720: 1_000_000
        case .p360: 500_000
        }
    }

    var framerate: Double { 60 }
    var codec: String { "avc1" }
}
