//
//  RFC_1035.swift
//  swift-rfc-1035
//
//  Created by Coen ten Thije Boonkkamp on 28/12/2024.
//

/// RFC 1035: Domain Names - Implementation and Specification
///
/// This module provides Swift types for RFC 1035 compliant domain names.
///
/// ## Overview
///
/// RFC 1035 defines the Domain Name System (DNS), including the structure
/// and constraints for domain names. This implementation provides:
/// - Type-safe domain name validation
/// - Label-based domain composition
/// - ASCII byte-level operations
///
/// ## Example
///
/// ```swift
/// let domain = try RFC_1035.Domain("www.example.com")
/// let tld = domain.tld // "com"
/// ```
///
/// ## RFC Reference
///
/// - [RFC 1035](https://www.rfc-editor.org/rfc/rfc1035)
public enum RFC_1035 {}
