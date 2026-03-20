/// A track object within an MSF catalog.
public struct Track: Codable, Sendable, Equatable {
    // Required
    public var name: String
    public var packaging: Packaging
    
    // TODO: Should isLive be non-optional.
    public var isLive: Bool?
    public var namespace: String?
    public var targetLatency: Int?
    public var role: TrackRole?
    public var label: String?
    public var renderGroup: Int?
    public var altGroup: Int?
    public var initData: String?
    public var depends: [String]?
    public var temporalId: Int?
    public var spatialId: Int?
    public var codec: String?
    public var mimeType: String?
    public var eventType: String?
    public var framerate: Double?
    public var timescale: Int?
    public var bitrate: Int?
    public var width: Int?
    public var height: Int?
    public var samplerate: Int?
    public var channelConfig: String?
    public var displayWidth: Int?
    public var displayHeight: Int?
    public var lang: String?
    public var trackDuration: Int?

    public init(
        name: String,
        packaging: Packaging,
        isLive: Bool? = nil,
        namespace: String? = nil,
        targetLatency: Int? = nil,
        role: TrackRole? = nil,
        label: String? = nil,
        renderGroup: Int? = nil,
        altGroup: Int? = nil,
        initData: String? = nil,
        depends: [String]? = nil,
        temporalId: Int? = nil,
        spatialId: Int? = nil,
        codec: String? = nil,
        mimeType: String? = nil,
        eventType: String? = nil,
        framerate: Double? = nil,
        timescale: Int? = nil,
        bitrate: Int? = nil,
        width: Int? = nil,
        height: Int? = nil,
        samplerate: Int? = nil,
        channelConfig: String? = nil,
        displayWidth: Int? = nil,
        displayHeight: Int? = nil,
        lang: String? = nil,
        trackDuration: Int? = nil
    ) {
        self.name = name
        self.packaging = packaging
        self.isLive = isLive
        self.namespace = namespace
        self.targetLatency = targetLatency
        self.role = role
        self.label = label
        self.renderGroup = renderGroup
        self.altGroup = altGroup
        self.initData = initData
        self.depends = depends
        self.temporalId = temporalId
        self.spatialId = spatialId
        self.codec = codec
        self.mimeType = mimeType
        self.eventType = eventType
        self.framerate = framerate
        self.timescale = timescale
        self.bitrate = bitrate
        self.width = width
        self.height = height
        self.samplerate = samplerate
        self.channelConfig = channelConfig
        self.displayWidth = displayWidth
        self.displayHeight = displayHeight
        self.lang = lang
        self.trackDuration = trackDuration
    }
}
