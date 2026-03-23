import Foundation

/// The set of bytes that are output literally (not percent-encoded).
private let literalBytes: Set<UInt8> = {
    var set = Set<UInt8>()
    for byte in UInt8(ascii: "a")...UInt8(ascii: "z") { set.insert(byte) }
    for byte in UInt8(ascii: "A")...UInt8(ascii: "Z") { set.insert(byte) }
    for byte in UInt8(ascii: "0")...UInt8(ascii: "9") { set.insert(byte) }
    set.insert(UInt8(ascii: "_"))
    return set
}()

/// Encode a single element (namespace tuple or track name) to its serialized form.
private func encodeElement(_ value: String) -> String {
    var result = ""
    for byte in value.utf8 {
        if literalBytes.contains(byte) {
            result.append(Character(UnicodeScalar(byte)))
        } else {
            result.append(".")
            let hex = String(byte, radix: 16)
            if hex.count == 1 {
                result.append("0")
            }
            result.append(hex)
        }
    }
    return result
}

public enum TrackNamespaceError: Error, Equatable {
    case invalidHexDigits(String)
    case uppercaseHexDigit(String)
    case redundantEncoding(UInt8)
    case trailingPeriod
    case emptyInput
}

/// Decode a single encoded element back to its original string.
private func decodeElement(_ encoded: String) throws -> String {
    var bytes: [UInt8] = []
    var iterator = encoded.utf8.makeIterator()
    while let byte = iterator.next() {
        if byte == UInt8(ascii: ".") {
            guard let hi = iterator.next(), let lo = iterator.next() else {
                throw TrackNamespaceError.trailingPeriod
            }
            let hexStr = String(Character(Unicode.Scalar(hi))) + String(Character(Unicode.Scalar(lo)))
            // Reject uppercase hex digits.
            if hi >= UInt8(ascii: "A") && hi <= UInt8(ascii: "F") ||
               lo >= UInt8(ascii: "A") && lo <= UInt8(ascii: "F") {
                throw TrackNamespaceError.uppercaseHexDigit(hexStr)
            }
            guard let value = UInt8(hexStr, radix: 16) else {
                throw TrackNamespaceError.invalidHexDigits(hexStr)
            }
            // Reject redundant encodings of literal bytes.
            if literalBytes.contains(value) {
                throw TrackNamespaceError.redundantEncoding(value)
            }
            bytes.append(value)
        } else {
            bytes.append(byte)
        }
    }
    return String(decoding: bytes, as: UTF8.self)
}

/// A namespace tuple for a track, encoded per the MoQ spec.
///
/// The namespace is an ordered tuple of string elements. When serialized,
/// elements are joined with `-`, with non-literal bytes encoded as `.xx`.
/// Since `-` itself is always encoded (`.2d`) when it appears in a value,
/// literal `-` in the serialized form is always a structural separator.
public struct TrackNamespace: Sendable, Equatable {
    public var tuples: [String]

    public init(_ tuples: [String]) {
        self.tuples = tuples
    }

    /// The serialized form of just the namespace (no track name).
    public var serialized: String {
        tuples.map(encodeElement).joined(separator: "-")
    }

    /// Parse a serialized namespace string back into its tuple elements.
    public init(parsing serialized: String) throws {
        guard !serialized.isEmpty else {
            throw TrackNamespaceError.emptyInput
        }
        // Split on literal `-` which is always a structural separator.
        let parts = serialized.split(separator: "-", omittingEmptySubsequences: false)
        self.tuples = try parts.map { try decodeElement(String($0)) }
    }

    /// Combine this namespace with a track name into a full serialized track name.
    /// Format: `<ns1>-<ns2>--<trackname>`
    public func fullTrackName(track: String) -> String {
        serialized + "--" + encodeElement(track)
    }
}

/// Parse a full serialized track name (namespace + track) back into components.
/// Format: `<ns1>-<ns2>--<trackname>`
public func parseFullTrackName(_ serialized: String) throws -> (namespace: TrackNamespace, track: String) {
    // Find the *last* `--` to split namespace from track name.
    // Since `-` in values is encoded as `.2d`, a literal `--` is always the delimiter.
    guard let range = serialized.range(of: "--", options: .backwards) else {
        throw TrackNamespaceError.emptyInput
    }
    let nsPart = String(serialized[serialized.startIndex..<range.lowerBound])
    let trackPart = String(serialized[range.upperBound...])
    let ns = try TrackNamespace(parsing: nsPart)
    let track = try decodeElement(trackPart)
    return (ns, track)
}

extension TrackNamespace: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let encoded = try container.decode(String.self)
        do {
            try self.init(parsing: encoded)
        } catch {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid namespace encoding: \(error)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(serialized)
    }
}
