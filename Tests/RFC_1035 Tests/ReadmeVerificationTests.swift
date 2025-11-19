//
//  ReadmeVerificationTests.swift
//  swift-rfc-1035
//
//  Verifies that README code examples actually work
//

import RFC_1035
import Testing
import Foundation

@Suite("README Verification")
struct ReadmeVerificationTests {

    @Test("README Line 51-52: Create from string")
    func createFromString() throws {
        let domain = try Domain("example.com")

        #expect(domain.name == "example.com")
    }

    @Test("README Line 54-55: Create from root components")
    func createFromRootComponents() throws {
        let domain = try Domain.root("example", "com")

        #expect(domain.name == "example.com")
    }

    @Test("README Line 57-59: Create subdomain with reversed components")
    func createSubdomainReversed() throws {
        let domain = try Domain.subdomain("com", "example", "api")

        #expect(domain.name == "api.example.com")
    }

    @Test("README Line 65-72: Working with domain components")
    func workingWithComponents() throws {
        let domain = try Domain("api.example.com")

        #expect(domain.tld?.stringValue == "com")
        #expect(domain.sld?.stringValue == "example")
        #expect(domain.name == "api.example.com")
    }

    @Test("README Line 78-95: Domain hierarchy navigation")
    func domainHierarchyNavigation() throws {
        let domain = try Domain("api.v1.example.com")

        // Get parent domain
        let parent = try domain.parent()
        #expect(parent?.name == "v1.example.com")

        // Get root domain
        let root = try domain.root()
        #expect(root?.name == "example.com")

        // Add subdomain
        let subdomain = try domain.addingSubdomain("staging")
        #expect(subdomain.name == "staging.api.v1.example.com")

        // Check subdomain relationships
        let parentDomain = try Domain("example.com")
        let childDomain = try Domain("api.example.com")
        #expect(childDomain.isSubdomain(of: parentDomain))
    }

    @Test("README Line 136-146: Error handling")
    func errorHandling() throws {
        // Empty domain
        #expect(throws: Domain.ValidationError.empty) {
            _ = try Domain("")
        }

        // Invalid label
        #expect(throws: Domain.ValidationError.invalidLabel("-example")) {
            _ = try Domain("-example.com")
        }
    }

    @Test("README Line 151-158: Codable support")
    func codableSupport() throws {
        let domain = try Domain("example.com")

        // Encode to JSON
        let encoded = try JSONEncoder().encode(domain)

        // Decode from JSON
        let decoded = try JSONDecoder().decode(Domain.self, from: encoded)

        #expect(domain == decoded)
    }
}
