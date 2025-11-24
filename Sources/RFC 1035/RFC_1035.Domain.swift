//
//  RFC_1035.Domain.swift
//  swift-rfc-1035
//
//  Created by Coen ten Thije Boonkkamp on 20/11/2025.
//

public import INCITS_4_1986

extension RFC_1035 {
    /// RFC 1035 compliant domain name
    ///
    /// Represents a fully qualified domain name as defined by RFC 1035 Section 2.3.4.
    /// Domain names consist of labels separated by dots, with strict length and format constraints.
    ///
    /// ## RFC 1035 Constraints
    ///
    /// Per RFC 1035 Section 2.3.4:
    /// - Maximum 255 octets total length
    /// - Maximum 127 labels
    /// - Each label follows RFC 1035 Section 2.3.1 rules
    ///
    /// ## Example
    ///
    /// ```swift
    /// let domain = try RFC_1035.Domain("www.example.com")
    /// print(domain.tld) // "com"
    /// print(domain.sld) // "example"
    /// ```
    ///
    /// ## RFC Reference
    ///
    /// From RFC 1035 Section 2.3.4:
    ///
    /// > The total number of octets that represent a domain name (i.e.,
    /// > the sum of all label octets and label lengths) is limited to 255.
    public struct Domain: Sendable, Codable {
        /// The domain name as a string
        public let rawValue: String

        /// The labels that make up the domain name, from least significant to most significant
        package let labels: [RFC_1035.Domain.Label]

        /// Creates a domain WITHOUT validation
        ///
        /// **Warning**: Bypasses RFC 1035 validation.
        /// Only use with compile-time constants or pre-validated values.
        ///
        /// - Parameters:
        ///   - unchecked: Void parameter to prevent accidental use
        ///   - rawValue: The raw domain name (unchecked)
        ///   - labels: Pre-validated labels
        init(
            __unchecked: Void,
            rawValue: String,
            labels: [RFC_1035.Domain.Label]
        ) {
            self.rawValue = rawValue
            self.labels = labels
        }
    }
}

// MARK: - Hashable

extension RFC_1035.Domain: Hashable {
    /// Hash value (case-insensitive per RFC 1035)
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue.lowercased())
    }

    /// Equality comparison (case-insensitive per RFC 1035)
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue.lowercased() == rhs.rawValue.lowercased()
    }

    /// Equality comparison with raw value (case-insensitive)
    public static func == (lhs: Self, rhs: Self.RawValue) -> Bool {
        lhs.rawValue.lowercased() == rhs.lowercased()
    }
}

// MARK: - Serializing

extension RFC_1035.Domain: UInt8.ASCII.Serializing {
    public static let serialize: @Sendable (Self) -> [UInt8] = [UInt8].init

    /// Parses a domain name from canonical byte representation (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// RFC 1035 domain names are ASCII-only, dot-separated labels.
    ///
    /// ## RFC 1035 Compliance
    ///
    /// Per RFC 1035 Section 2.3.4:
    /// - Maximum 255 octets total
    /// - Maximum 127 labels
    /// - Labels separated by dots (0x2E)
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_1035.Domain (structured data)
    ///
    /// String-based parsing is derived as composition:
    /// ```
    /// String → [UInt8] (UTF-8 bytes) → Domain
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let bytes = Array("www.example.com".utf8)
    /// let domain = try RFC_1035.Domain(ascii: bytes)
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of the domain
    /// - Throws: `RFC_1035.Domain.Error` if the bytes are malformed
    public init(ascii bytes: [UInt8]) throws(Error) {
        // Empty check
        guard !bytes.isEmpty else {
            throw Error.empty
        }

        // Length check (RFC 1035: max 255 octets)
        guard bytes.count <= Limits.maxLength else {
            throw Error.tooLong(bytes.count)
        }

        // Split on dots (0x2E) and parse each label
        var labels: [RFC_1035.Domain.Label] = []
        var currentStart = bytes.startIndex

        for (index, byte) in bytes.enumerated() {
            if byte == .ascii.period {
                let labelBytes = Array(bytes[currentStart..<index])
                if !labelBytes.isEmpty {
                    do {
                        labels.append(try RFC_1035.Domain.Label(ascii: labelBytes))
                    } catch {
                        throw Error.invalidLabel(error)
                    }
                }
                currentStart = bytes.index(after: index)
            }
        }

        // Handle final label (after last dot or entire string if no dots)
        if currentStart < bytes.endIndex {
            let labelBytes = Array(bytes[currentStart...])
            do {
                labels.append(try RFC_1035.Domain.Label(ascii: labelBytes))
            } catch {
                throw Error.invalidLabel(error)
            }
        }

        // Must have at least one label
        guard !labels.isEmpty else {
            throw Error.empty
        }

        // Check label count (RFC 1035: max 127 labels)
        guard labels.count <= Limits.maxLabels else {
            throw Error.tooManyLabels
        }

        let rawValue = String(decoding: bytes, as: UTF8.self)
        self.init(__unchecked: (), rawValue: rawValue, labels: labels)
    }
}

// MARK: - Byte Serialization

extension [UInt8] {
    /// Creates ASCII byte representation of an RFC 1035 domain name
    ///
    /// This is the canonical serialization of domain names to bytes.
    /// The format is labels joined by dots (ASCII 0x2E).
    ///
    /// ## Category Theory
    ///
    /// This is the most universal serialization (natural transformation):
    /// - **Domain**: RFC_1035.Domain (structured data)
    /// - **Codomain**: [UInt8] (ASCII bytes)
    ///
    /// String representation is derived as composition:
    /// ```
    /// Domain → [UInt8] (ASCII) → String (UTF-8 interpretation)
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let domain = try RFC_1035.Domain("www.example.com")
    /// let bytes = [UInt8](domain)
    /// // bytes == "www.example.com" as ASCII bytes
    /// ```
    ///
    /// - Parameter domain: The domain name to serialize
    public init(_ domain: RFC_1035.Domain) {
        self = Array(domain.rawValue.utf8)
    }
}

// MARK: - Protocol Conformances

extension RFC_1035.Domain: RawRepresentable {}
extension RFC_1035.Domain: CustomStringConvertible {}

// MARK: - Domain Properties

extension RFC_1035.Domain {
    /// The complete domain name as a string
    public var name: String {
        rawValue
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

// MARK: - Domain Operations

extension RFC_1035.Domain {
    /// Returns true if this is a subdomain of the given domain
    public func isSubdomain(of parent: RFC_1035.Domain) -> Bool {
        guard labels.count > parent.labels.count else { return false }
        return labels.suffix(parent.labels.count) == parent.labels
    }

    /// Creates a subdomain by prepending new labels
    public func addingSubdomain(_ components: [String]) throws(Error) -> RFC_1035.Domain {
        var newLabels: [Label] = []
        for component in components {
            do {
                newLabels.append(try Label(component))
            } catch {
                throw Error.invalidLabel(error)
            }
        }

        let allLabels = newLabels + labels
        guard allLabels.count <= Limits.maxLabels else {
            throw Error.tooManyLabels
        }

        let newName = (components + labels.map(\.rawValue)).joined(separator: ".")
        guard newName.count <= Limits.maxLength else {
            throw Error.tooLong(newName.count)
        }

        return RFC_1035.Domain(__unchecked: (), rawValue: newName, labels: allLabels)
    }

    /// Creates a subdomain by prepending new labels
    public func addingSubdomain(_ components: String...) throws(Error) -> RFC_1035.Domain {
        try self.addingSubdomain(components)
    }

    /// Returns the parent domain by removing the leftmost label
    public func parent() throws(Error) -> RFC_1035.Domain? {
        guard labels.count > 1 else { return nil }
        let parentLabels = Array(labels.dropFirst())
        let parentName = parentLabels.map(\.rawValue).joined(separator: ".")
        return RFC_1035.Domain(__unchecked: (), rawValue: parentName, labels: parentLabels)
    }

    /// Returns the root domain (tld + sld)
    public func root() throws(Error) -> RFC_1035.Domain? {
        guard labels.count >= 2 else { return nil }
        let rootLabels = Array(labels.suffix(2))
        let rootName = rootLabels.map(\.rawValue).joined(separator: ".")
        return RFC_1035.Domain(__unchecked: (), rawValue: rootName, labels: rootLabels)
    }
}

// MARK: - Convenience Initializers

extension RFC_1035.Domain {
    /// Initialize with an array of validated labels
    ///
    /// Labels are already validated, so this only performs compositional validation.
    public init(labels: [RFC_1035.Domain.Label]) throws(Error) {
        guard !labels.isEmpty else {
            throw Error.empty
        }

        guard labels.count <= Limits.maxLabels else {
            throw Error.tooManyLabels
        }

        let name = labels.map(\.rawValue).joined(separator: ".")
        guard name.count <= Limits.maxLength else {
            throw Error.tooLong(name.count)
        }

        self.init(__unchecked: (), rawValue: name, labels: labels)
    }

    /// Initialize with an array of string labels
    public init(labels labelStrings: some Sequence<some StringProtocol>) throws(Error) {
        var validatedLabels: [Label] = []
        for labelString in labelStrings {
            do {
                validatedLabels.append(try Label(labelString))
            } catch {
                throw Error.invalidLabel(error)
            }
        }
        try self.init(labels: validatedLabels)
    }

    /// Creates a domain from root level components
    public static func root(_ sld: String, _ tld: String) throws(Error) -> RFC_1035.Domain {
        try RFC_1035.Domain(labels: [sld, tld])
    }

    /// Creates a subdomain with components in most-to-least significant order
    public static func subdomain(_ components: String...) throws(Error) -> RFC_1035.Domain {
        try RFC_1035.Domain(labels: components.reversed())
    }
}

// MARK: - Constants and Validation

extension RFC_1035.Domain {
    package enum Limits {
        static let maxLength = 255
        static let maxLabels = 127
        static let maxLabelLength = 63
    }
}
