# swift-msf

Swift 6 types for the [MOQT Streaming Format](https://moq-wg.github.io/msf/draft-ietf-moq-msf.html) (MSF) catalog, based on `draft-ietf-moq-msf-00`.

Parse a catalog from JSON, or construct one and encode it. That's it.

## Usage

```swift
import MSF

// Decode a catalog from JSON
let catalog = try JSONDecoder().decode(Catalog.self, from: jsonData)

for track in catalog.tracks {
    print("\(track.name) — \(track.packaging)")
}

// Build one
let catalog = Catalog(version: 1, tracks: [
    Track(name: "video", packaging: .loc, isLive: true, role: .video,
          codec: "av01.0.08M.10.0.110.09", width: 1920, height: 1080),
    Track(name: "audio", packaging: .loc, isLive: true, role: .audio,
          codec: "opus", samplerate: 48000, channelConfig: "2"),
])

let json = try JSONEncoder().encode(catalog)
```

## What's in the box

- **`Catalog`** — top-level type (`version`, `tracks`, `generatedAt`, `isComplete`)
- **`Track`** — all fields from the spec (name, packaging, codec, dimensions, bitrate, dependencies, etc.)
- **`Packaging`** — enum: `loc`, `mediatimeline`, `eventtimeline`
- **`TrackRole`** — open type with constants for the reserved roles (`video`, `audio`, `caption`, etc.) — custom roles decode fine
- **`TrackNamespace`** — namespace tuple type with spec-compliant serialization (period-encoded, hyphen-separated)

Everything is `Codable`, `Sendable`, and `Equatable`. Unknown JSON fields are silently dropped per spec. Nil optionals are omitted when encoding.

## msf-gen

There's also a CLI tool for generating template catalogs for meetings. It outputs a single-participant template — clients read the catalog to learn the track structure, then publish their own tracks under a unique namespace.

```bash
# All three quality tiers
swift run msf-gen --namespace "meeting.example.com"

# Just one
swift run msf-gen --namespace "meeting.example.com" --qualities 360p

# Custom participant template name
swift run msf-gen --namespace "meeting.example.com" --participant user
```

Available quality presets: `1080p`, `720p`, `360p`. Output goes to stdout.

## Scope

This covers the full catalog format from section 5 of the spec. Delta updates and timeline payloads (sections 7-8) aren't implemented yet.

## Known RFC quirks

We found a couple of inconsistencies in draft-00:

- **`isLive`** is marked required but the spec's own examples omit it on timeline tracks. We model it as optional.
- **`mimeType`** is camelCase in the field table but lowercase `mimetype` in example 5.3.8. We follow the field table.

## Docker

Builds `msf-gen` and libquicr's `qclient` (`eof` branch), then runs `publish-catalog.sh`.

```bash
podman build -t msf-publish .
podman run --rm msf-publish moq://relay.example.com:33435
```

## Requirements

Swift 6.0+
