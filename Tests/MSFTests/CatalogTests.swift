import Testing
import Foundation
@testable import MSF

@Test func packagingDecodesFromJSON() throws {
    let json = Data(#""loc""#.utf8)
    let result = try JSONDecoder().decode(Packaging.self, from: json)
    #expect(result == .loc)
}

@Test func packagingEncodesToJSON() throws {
    let data = try JSONEncoder().encode(Packaging.eventtimeline)
    let string = String(data: data, encoding: .utf8)
    #expect(string == #""eventtimeline""#)
}

@Test func trackRoleDecodesKnownRole() throws {
    let json = Data(#""video""#.utf8)
    let result = try JSONDecoder().decode(TrackRole.self, from: json)
    #expect(result == .video)
}

@Test func trackRoleDecodesCustomRole() throws {
    let json = Data(#""custom-role""#.utf8)
    let result = try JSONDecoder().decode(TrackRole.self, from: json)
    #expect(result.rawValue == "custom-role")
}

@Test func trackRoleEncodesToJSON() throws {
    let data = try JSONEncoder().encode(TrackRole.audio)
    let string = String(data: data, encoding: .utf8)
    #expect(string == #""audio""#)
}

@Test func trackDecodesMinimalLOC() throws {
    let json = Data("""
    {
        "name": "video",
        "packaging": "loc",
        "isLive": true
    }
    """.utf8)
    let track = try JSONDecoder().decode(Track.self, from: json)
    #expect(track.name == "video")
    #expect(track.packaging == .loc)
    #expect(track.isLive == true)
    #expect(track.namespace == nil)
    #expect(track.codec == nil)
}

@Test func trackDecodesTimelineWithoutIsLive() throws {
    let json = Data("""
    {
        "name": "history",
        "packaging": "mediatimeline",
        "mimeType": "application/json",
        "depends": ["video", "audio"]
    }
    """.utf8)
    let track = try JSONDecoder().decode(Track.self, from: json)
    #expect(track.name == "history")
    #expect(track.packaging == .mediatimeline)
    #expect(track.isLive == nil)
    #expect(track.depends == ["video", "audio"])
}

@Test func trackIgnoresUnknownFields() throws {
    let json = Data("""
    {
        "name": "video",
        "packaging": "loc",
        "isLive": true,
        "com.example-billing-code": 3201,
        "com.example-tier": "premium"
    }
    """.utf8)
    let track = try JSONDecoder().decode(Track.self, from: json)
    #expect(track.name == "video")
}

@Test func trackRoundTripsAllFields() throws {
    let track = Track(
        name: "hd-video",
        packaging: .loc,
        isLive: true,
        namespace: TrackNamespace(["example.com", "session1"]),
        targetLatency: 2000,
        role: .video,
        label: "HD Camera",
        renderGroup: 1,
        altGroup: 1,
        initData: "AAAA",
        depends: ["base"],
        temporalId: 1,
        spatialId: 0,
        codec: "av01.0.08M.10.0.110.09",
        mimeType: nil,
        eventType: nil,
        framerate: 30,
        timescale: 90000,
        bitrate: 5000000,
        width: 1920,
        height: 1080,
        samplerate: nil,
        channelConfig: nil,
        displayWidth: 1920,
        displayHeight: 1080,
        lang: "en",
        trackDuration: nil
    )
    let encoder = JSONEncoder()
    let data = try encoder.encode(track)
    let decoded = try JSONDecoder().decode(Track.self, from: data)
    #expect(decoded == track)
}

@Test func catalogDecodesMinimal() throws {
    let json = Data("""
    {
        "version": 1,
        "tracks": []
    }
    """.utf8)
    let catalog = try JSONDecoder().decode(Catalog.self, from: json)
    #expect(catalog.version == 1)
    #expect(catalog.tracks.isEmpty)
    #expect(catalog.generatedAt == nil)
    #expect(catalog.isComplete == nil)
}

@Test func catalogRoundTrip() throws {
    let catalog = Catalog(
        version: 1,
        tracks: [
            Track(name: "video", packaging: .loc, isLive: true)
        ],
        generatedAt: 1746104606044,
        isComplete: nil
    )
    let data = try JSONEncoder().encode(catalog)
    let decoded = try JSONDecoder().decode(Catalog.self, from: data)
    #expect(decoded == catalog)
}

@Test func catalogOmitsNilIsComplete() throws {
    let catalog = Catalog(version: 1, tracks: [])
    let data = try JSONEncoder().encode(catalog)
    let json = String(data: data, encoding: .utf8)!
    #expect(!json.contains("isComplete"))
}

// MARK: - RFC Example Tests

@Test func rfcExample531_timeAlignedAudioVideo() throws {
    let json = Data("""
    {
      "version": 1,
      "generatedAt": 1746104606044,
      "tracks": [
        {
          "name": "1080p-video",
          "namespace": "conference.2eexample.2ecom-conference123-alice",
          "packaging": "loc",
          "isLive": true,
          "targetLatency": 2000,
          "role": "video",
          "renderGroup": 1,
          "codec": "av01.0.08M.10.0.110.09",
          "width": 1920,
          "height": 1080,
          "framerate": 30,
          "bitrate": 1500000
        },
        {
          "name": "audio",
          "namespace": "conference.2eexample.2ecom-conference123-alice",
          "packaging": "loc",
          "isLive": true,
          "targetLatency": 2000,
          "role": "audio",
          "renderGroup": 1,
          "codec": "opus",
          "samplerate": 48000,
          "channelConfig": "2",
          "bitrate": 32000
        }
      ]
    }
    """.utf8)
    let catalog = try JSONDecoder().decode(Catalog.self, from: json)
    #expect(catalog.version == 1)
    #expect(catalog.generatedAt == 1746104606044)
    #expect(catalog.tracks.count == 2)

    let video = catalog.tracks[0]
    #expect(video.name == "1080p-video")
    #expect(video.packaging == .loc)
    #expect(video.role == .video)
    #expect(video.width == 1920)
    #expect(video.height == 1080)
    #expect(video.framerate == 30)
    #expect(video.renderGroup == 1)

    let audio = catalog.tracks[1]
    #expect(audio.name == "audio")
    #expect(audio.role == .audio)
    #expect(audio.codec == "opus")
    #expect(audio.samplerate == 48000)
    #expect(audio.channelConfig == "2")
}

@Test func rfcExample532_simulcastWithAltGroup() throws {
    let json = Data("""
    {
      "version": 1,
      "generatedAt": 1746104606044,
      "tracks": [
        {
          "name": "hd",
          "renderGroup": 1,
          "packaging": "loc",
          "isLive": true,
          "targetLatency": 1500,
          "role": "video",
          "codec": "av01",
          "width": 1920,
          "height": 1080,
          "bitrate": 5000000,
          "framerate": 30,
          "altGroup": 1
        },
        {
          "name": "md",
          "renderGroup": 1,
          "packaging": "loc",
          "isLive": true,
          "targetLatency": 1500,
          "role": "video",
          "codec": "av01",
          "width": 720,
          "height": 640,
          "bitrate": 3000000,
          "framerate": 30,
          "altGroup": 1
        },
        {
          "name": "sd",
          "renderGroup": 1,
          "packaging": "loc",
          "isLive": true,
          "targetLatency": 1500,
          "role": "video",
          "codec": "av01",
          "width": 192,
          "height": 144,
          "bitrate": 500000,
          "framerate": 30,
          "altGroup": 1
        },
        {
          "name": "audio",
          "renderGroup": 1,
          "packaging": "loc",
          "isLive": true,
          "targetLatency": 1500,
          "role": "audio",
          "codec": "opus",
          "samplerate": 48000,
          "channelConfig": "2",
          "bitrate": 32000
        }
      ]
    }
    """.utf8)
    let catalog = try JSONDecoder().decode(Catalog.self, from: json)
    #expect(catalog.tracks.count == 4)
    #expect(catalog.tracks[0].altGroup == 1)
    #expect(catalog.tracks[1].altGroup == 1)
    #expect(catalog.tracks[2].altGroup == 1)
    #expect(catalog.tracks[3].altGroup == nil)
    #expect(catalog.tracks[0].namespace == nil)
}

@Test func rfcExample533_svcWithDependencies() throws {
    let json = Data("""
    {
      "version": 1,
      "generatedAt": 1746104606044,
      "tracks": [
        {
          "name": "480p15",
          "namespace": "conference.2eexample.2ecom-conference123-alice",
          "renderGroup": 1,
          "packaging": "loc",
          "isLive": true,
          "role": "video",
          "codec": "av01.0.01M.10.0.110.09",
          "width": 640,
          "height": 480,
          "bitrate": 3000000,
          "framerate": 15
        },
        {
          "name": "480p30",
          "namespace": "conference.2eexample.2ecom-conference123-alice",
          "renderGroup": 1,
          "packaging": "loc",
          "isLive": true,
          "role": "video",
          "codec": "av01.0.04M.10.0.110.09",
          "width": 640,
          "height": 480,
          "bitrate": 3000000,
          "framerate": 30,
          "depends": ["480p15"]
        },
        {
          "name": "1080p15",
          "namespace": "conference.2eexample.2ecom-conference123-alice",
          "renderGroup": 1,
          "packaging": "loc",
          "isLive": true,
          "role": "video",
          "codec": "av01.0.05M.10.0.110.09",
          "width": 1920,
          "height": 1080,
          "bitrate": 3000000,
          "framerate": 15,
          "depends": ["480p15"]
        },
        {
          "name": "1080p30",
          "namespace": "conference.2eexample.2ecom-conference123-alice",
          "renderGroup": 1,
          "packaging": "loc",
          "isLive": true,
          "role": "video",
          "codec": "av01.0.08M.10.0.110.09",
          "width": 1920,
          "height": 1080,
          "bitrate": 5000000,
          "framerate": 30,
          "depends": ["480p30", "1080p15"]
        },
        {
          "name": "audio",
          "namespace": "conference.2eexample.2ecom-conference123-alice",
          "renderGroup": 1,
          "packaging": "loc",
          "isLive": true,
          "role": "audio",
          "codec": "opus",
          "samplerate": 48000,
          "channelConfig": "2",
          "bitrate": 32000
        }
      ]
    }
    """.utf8)
    let catalog = try JSONDecoder().decode(Catalog.self, from: json)
    #expect(catalog.tracks[0].depends == nil)
    #expect(catalog.tracks[1].depends == ["480p15"])
    #expect(catalog.tracks[3].depends == ["480p30", "1080p15"])
}

@Test func rfcExample536_customFieldsDropped() throws {
    let json = Data("""
    {
      "version": 1,
      "generatedAt": 1746104606044,
      "tracks": [
        {
          "name": "1080p-video",
          "namespace": "conference.2eexample.2ecom-conference123-alice",
          "packaging": "loc",
          "isLive": true,
          "role": "video",
          "renderGroup": 1,
          "codec": "av01.0.08M.10.0.110.09",
          "width": 1920,
          "height": 1080,
          "framerate": 30,
          "bitrate": 1500000,
          "com.example-billing-code": 3201,
          "com.example-tier": "premium",
          "com.example-debug": "h349835bfkjfg82394d945034jsdfn349fns"
        }
      ]
    }
    """.utf8)
    let catalog = try JSONDecoder().decode(Catalog.self, from: json)
    #expect(catalog.tracks.count == 1)
    #expect(catalog.tracks[0].name == "1080p-video")
    #expect(catalog.tracks[0].width == 1920)
}

@Test func rfcExample537_vod() throws {
    let json = Data("""
    {
      "version": 1,
      "tracks": [
        {
          "name": "video",
          "namespace": "movies.2eexample.2ecom-assets-boy.2dmeets.2dgirl.2dseason3-episode5",
          "packaging": "loc",
          "isLive": false,
          "trackDuration": 8072340,
          "renderGroup": 1,
          "codec": "av01.0.08M.10.0.110.09",
          "width": 1920,
          "height": 1080,
          "framerate": 30,
          "bitrate": 1500000
        },
        {
          "name": "audio",
          "namespace": "movies.2eexample.2ecom-assets-boy.2dmeets.2dgirl.2dseason3-episode5",
          "packaging": "loc",
          "isLive": false,
          "trackDuration": 8072340,
          "renderGroup": 1,
          "codec": "opus",
          "samplerate": 48000,
          "channelConfig": "2",
          "bitrate": 32000
        }
      ]
    }
    """.utf8)
    let catalog = try JSONDecoder().decode(Catalog.self, from: json)
    #expect(catalog.generatedAt == nil)
    #expect(catalog.tracks[0].isLive == false)
    #expect(catalog.tracks[0].trackDuration == 8072340)
    #expect(catalog.tracks[0].targetLatency == nil)
}

@Test func rfcExample538_timelineTracks() throws {
    let json = Data("""
    {
      "version": 1,
      "generatedAt": 1746104606044,
      "tracks": [
        {
          "name": "history",
          "namespace": "conference.2eexample.2ecom-conference123-alice",
          "packaging": "mediatimeline",
          "mimeType": "application/json",
          "depends": ["1080p-video", "audio"]
        },
        {
          "name": "identified-objects",
          "namespace": "another.2dprovider-time.2dsynchronized.2ddata",
          "packaging": "eventtimeline",
          "eventType": "com.ai-extraction/appID/v3",
          "mimeType": "application/json",
          "depends": ["1080p-video"]
        },
        {
          "name": "1080p-video",
          "namespace": "conference.2eexample.2ecom-conference123-alice",
          "packaging": "loc",
          "isLive": true,
          "targetLatency": 2000,
          "role": "video",
          "renderGroup": 1,
          "codec": "av01.0.08M.10.0.110.09",
          "width": 1920,
          "height": 1080,
          "framerate": 30,
          "bitrate": 1500000
        },
        {
          "name": "audio",
          "namespace": "conference.2eexample.2ecom-conference123-alice",
          "packaging": "loc",
          "isLive": true,
          "targetLatency": 2000,
          "role": "audio",
          "renderGroup": 1,
          "codec": "opus",
          "samplerate": 48000,
          "channelConfig": "2",
          "bitrate": 32000
        }
      ]
    }
    """.utf8)
    let catalog = try JSONDecoder().decode(Catalog.self, from: json)
    #expect(catalog.tracks.count == 4)

    let history = catalog.tracks[0]
    #expect(history.packaging == .mediatimeline)
    #expect(history.isLive == nil)
    #expect(history.mimeType == "application/json")
    #expect(history.depends == ["1080p-video", "audio"])

    let events = catalog.tracks[1]
    #expect(events.packaging == .eventtimeline)
    #expect(events.eventType == "com.ai-extraction/appID/v3")
    #expect(events.isLive == nil)
}

@Test func rfcExample539_broadcastTermination() throws {
    let json = Data("""
    {
      "version": 1,
      "generatedAt": 1746104606044,
      "isComplete": true,
      "tracks": []
    }
    """.utf8)
    let catalog = try JSONDecoder().decode(Catalog.self, from: json)
    #expect(catalog.isComplete == true)
    #expect(catalog.tracks.isEmpty)
}
