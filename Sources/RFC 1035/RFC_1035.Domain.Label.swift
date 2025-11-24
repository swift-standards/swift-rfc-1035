//
//  File.swift
//  swift-rfc-1035
//
//  Created by Coen ten Thije Boonkkamp on 20/11/2025.
//

import Standards

extension RFC_1035.Domain {
    /// A type-safe domain label that enforces RFC 1035 rules
    public struct Label: Hashable, Sendable {
        /// Canonical byte storage (ASCII-only per RFC 1035)
        let _value: [UInt8]

        /// Initialize a label from a string, validating RFC 1035 rules
        ///
        /// This is the canonical initializer that performs validation.
        public init(_ string: some StringProtocol) throws(Error) {
            // Check emptiness
            guard !string.isEmpty else {
                throw Error.empty
            }

            // Check length
            guard string.count <= RFC_1035.Domain.Limits.maxLabelLength else {
                throw Error.tooLong(string.count, label: String(string))
            }

            // Convert to String once for validation and error messages
            let stringValue = String(string)

            // RFC 1035: Label must match pattern [a-zA-Z](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?
            guard (try? RFC_1035.Domain.labelRegex.wholeMatch(in: stringValue)) != nil else {
                // Provide more specific error
                if string.first == "-" {
                    throw Error.startsWithHyphen(stringValue)
                } else if string.last == "-" {
                    throw Error.endsWithHyphen(stringValue)
                } else if string.first?.isNumber == true {
                    throw Error.startsWithDigit(stringValue)
                } else {
                    throw Error.invalidCharacters(stringValue)
                }
            }

            // Store as canonical byte representation (ASCII-only)
            self._value = [UInt8](utf8: string)
        }
    }
}

extension RFC_1035.Domain.Label {
    /// String representation derived from canonical bytes
    public var value: String {
        String(self)
    }
}

// MARK: - Convenience Initializers
extension RFC_1035.Domain.Label {
    /// Initialize a label from bytes, validating RFC 1035 rules
    ///
    /// Convenience initializer that decodes bytes as UTF-8 and validates.
    public init(_ bytes: [UInt8]) throws(Error) {
        // Decode bytes as UTF-8 and validate
        let string = String(decoding: bytes, as: UTF8.self)
        try self.init(string)
    }
}

extension RFC_1035.Domain.Label: CustomStringConvertible {
    public var description: String { String(self) }
}
