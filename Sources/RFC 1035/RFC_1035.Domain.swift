//
//  File.swift
//  swift-rfc-1035
//
//  Created by Coen ten Thije Boonkkamp on 20/11/2025.
//

import INCITS_4_1986
import Standards

extension RFC_1035 {
    /// RFC 1035 compliant domain name
    public struct Domain: Hashable, Sendable {
        /// The labels that make up the domain name, from least significant to most significant
        let labels: [Domain.Label]

        /// Initialize with an array of validated labels, performing domain-level validation
        ///
        /// This is the canonical initializer. Labels are already validated,
        /// so this only performs compositional validation (count, total length).
        public init(labels: [Domain.Label]) throws(Error) {
            guard !labels.isEmpty else {
                throw Error.empty
            }

            guard labels.count <= Limits.maxLabels else {
                throw Error.tooManyLabels
            }

            self.labels = labels

            // Check total length including dots
            let totalLength = self.name.count
            guard totalLength <= Limits.maxLength else {
                throw Error.tooLong(totalLength)
            }
        }
    }
}

// MARK: - Convenience Initializers
extension RFC_1035.Domain {
    /// Initialize with an array of string labels, validating and converting to Labels
    ///
    /// Convenience initializer that validates strings as labels, then delegates
    /// to the canonical `init(labels: [Label])`.
    public init(labels labelStrings: [String]) throws(Error) {
        // Validate and convert each label, wrapping Label.Error
        var validatedLabels: [Label] = []
        validatedLabels.reserveCapacity(labelStrings.count)
        for labelString in labelStrings {
            do {
                validatedLabels.append(try Label(labelString))
            } catch {
                // Typed throws: compiler knows error is Label.Error
                throw Error.invalidLabel(error)
            }
        }

        // Delegate to canonical initializer
        try self.init(labels: validatedLabels)
    }

    /// Initialize from a string representation (e.g. "example.com")
    ///
    /// Convenience initializer that parses dot-separated labels.
    public init(_ string: String) throws(Error) {
        try self.init(
            labels: string.split(separator: ".", omittingEmptySubsequences: true).map(String.init)
        )
    }

    /// Initialize from bytes representation
    ///
    /// Convenience initializer that decodes bytes as UTF-8 and validates.
    public init(_ bytes: [UInt8]) throws(Error) {
        // Decode bytes as UTF-8 and validate
        let string = String(decoding: bytes, as: UTF8.self)
        try self.init(string)
    }
}

extension RFC_1035.Domain {
    /// The complete domain name as a string
    public var name: String {
        labels.map(String.init).joined(separator: ".")
    }
    
    /// The top-level domain (rightmost label)
    public var tld: RFC_1035.Domain.Label? {
        labels.last
    }
    
    /// The second-level domain (second from right)
    public var sld: RFC_1035.Domain.Label? {
        labels.dropLast().last
    }
}

extension RFC_1035.Domain {
    /// Returns true if this is a subdomain of the given domain
    public func isSubdomain(of parent: RFC_1035.Domain) -> Bool {
        guard labels.count > parent.labels.count else { return false }
        return labels.suffix(parent.labels.count) == parent.labels
    }
    
    /// Creates a subdomain by prepending new labels
    public func addingSubdomain(_ components: [String]) throws(Error) -> RFC_1035.Domain {
        try RFC_1035.Domain(labels: components + labels.map(String.init))
    }

    public func addingSubdomain(_ components: String...) throws(Error) -> RFC_1035.Domain {
        try self.addingSubdomain(components)
    }

    /// Returns the parent domain by removing the leftmost label
    public func parent() throws(Error) -> RFC_1035.Domain? {
        guard labels.count > 1 else { return nil }
        // Use canonical init with validated Labels
        return try RFC_1035.Domain(labels: Array(labels.dropFirst()))
    }

    /// Returns the root domain (tld + sld)
    public func root() throws(Error) -> RFC_1035.Domain? {
        guard labels.count >= 2 else { return nil }
        // Use canonical init with validated Labels
        return try RFC_1035.Domain(labels: Array(labels.suffix(2)))
    }
}

// MARK: - Constants and Validation
extension RFC_1035.Domain {
    internal enum Limits {
        static let maxLength = 255
        static let maxLabels = 127
        static let maxLabelLength = 63
    }
    
    // RFC 1035 label regex:
    // - Must begin with a letter
    // - Must end with a letter or digit
    // - May have hyphens in interior positions only
    nonisolated(unsafe) internal static let labelRegex = /[a-zA-Z](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?/
}


// MARK: - Convenience Initializers
extension RFC_1035.Domain {
    /// Creates a domain from root level components
    public static func root(_ sld: String, _ tld: String) throws(Error) -> RFC_1035.Domain {
        try RFC_1035.Domain(labels: [sld, tld])
    }

    /// Creates a subdomain with components in most-to-least significant order
    public static func subdomain(_ components: String...) throws(Error) -> RFC_1035.Domain {
        try RFC_1035.Domain(labels: components.reversed())
    }
}

// MARK: - Protocol Conformances
extension RFC_1035.Domain: CustomStringConvertible {
    public var description: String { name }
}

extension RFC_1035.Domain: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(name)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        try self.init(string)
    }
}

extension RFC_1035.Domain: RawRepresentable {
    public var rawValue: String { name }
    public init?(rawValue: String) { try? self.init(rawValue) }
}
