import Testing
import Foundation
@testable import MSF

// MARK: - Encoding

@Test func encodesSimpleNamespace() {
    let ns = TrackNamespace(["team2", "project_x"])
    #expect(ns.serialized == "team2-project_x")
}

@Test func encodesDotsAsPeriodHex() {
    let ns = TrackNamespace(["example.net"])
    #expect(ns.serialized == "example.2enet")
}

@Test func encodesSlashesAndHyphens() {
    let ns = TrackNamespace(["a/b", "c-d"])
    #expect(ns.serialized == "a.2fb-c.2dd")
}

@Test func rfcExampleEncoding() {
    let ns = TrackNamespace(["example.net", "team2", "project_x"])
    #expect(ns.fullTrackName(track: "report") == "example.2enet-team2-project_x--report")
}

@Test func encodesSpacesAndSpecialChars() {
    let ns = TrackNamespace(["hello world"])
    #expect(ns.serialized == "hello.20world")
}

// MARK: - Parsing

@Test func parsesSimpleNamespace() throws {
    let ns = try TrackNamespace(parsing: "team2-project_x")
    #expect(ns.tuples == ["team2", "project_x"])
}

@Test func parsesEncodedDots() throws {
    let ns = try TrackNamespace(parsing: "example.2enet")
    #expect(ns.tuples == ["example.net"])
}

@Test func parsesRfcExample() throws {
    let (ns, track) = try parseFullTrackName("example.2enet-team2-project_x--report")
    #expect(ns.tuples == ["example.net", "team2", "project_x"])
    #expect(track == "report")
}

// MARK: - Round-trips

@Test func roundTripsNamespace() throws {
    let original = TrackNamespace(["conference.example.com", "room-42", "alice"])
    let parsed = try TrackNamespace(parsing: original.serialized)
    #expect(parsed == original)
}

@Test func roundTripsFullTrackName() throws {
    let ns = TrackNamespace(["movies.example.com", "assets", "boy-meets-girl"])
    let full = ns.fullTrackName(track: "video")
    let (parsedNs, parsedTrack) = try parseFullTrackName(full)
    #expect(parsedNs == ns)
    #expect(parsedTrack == "video")
}

// MARK: - Canonical validation

@Test func rejectsUppercaseHex() {
    #expect(throws: TrackNamespaceError.uppercaseHexDigit("2E")) {
        try TrackNamespace(parsing: "example.2Enet")
    }
}

@Test func rejectsRedundantEncoding() {
    // .61 is 'a', which must be literal
    #expect(throws: TrackNamespaceError.redundantEncoding(0x61)) {
        try TrackNamespace(parsing: ".61bc")
    }
}

@Test func rejectsTrailingPeriod() {
    #expect(throws: TrackNamespaceError.trailingPeriod) {
        try TrackNamespace(parsing: "abc.")
    }
}

@Test func rejectsPeriodWithOneHexDigit() {
    #expect(throws: TrackNamespaceError.trailingPeriod) {
        try TrackNamespace(parsing: "abc.2")
    }
}

@Test func rejectsEmptyInput() {
    #expect(throws: TrackNamespaceError.emptyInput) {
        try TrackNamespace(parsing: "")
    }
}

// MARK: - Codable

@Test func decodesFromJSON() throws {
    let json = Data(#""example.2ecom-session1""#.utf8)
    let ns = try JSONDecoder().decode(TrackNamespace.self, from: json)
    #expect(ns.tuples == ["example.com", "session1"])
}

@Test func encodesToJSON() throws {
    let ns = TrackNamespace(["example.com", "session1"])
    let data = try JSONEncoder().encode(ns)
    let string = String(data: data, encoding: .utf8)
    #expect(string == #""example.2ecom-session1""#)
}

@Test func rejectsInvalidEncodingInJSON() {
    let json = Data(#""example.2Ecom""#.utf8)
    #expect(throws: DecodingError.self) {
        try JSONDecoder().decode(TrackNamespace.self, from: json)
    }
}
