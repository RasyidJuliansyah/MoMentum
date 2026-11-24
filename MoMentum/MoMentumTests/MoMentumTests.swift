//
//  MoMentumTests.swift
//  MoMentumTests
//
//  Created by Rasyid Juliansyah on 24/11/26.
//

import XCTest
@testable import MoMentum

final class MoMentumTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testKeychainStoreRoundTrip() throws {
        KeychainStore.delete(.assemblyAIAPIKey)
        XCTAssertNil(KeychainStore.get(.assemblyAIAPIKey))

        KeychainStore.set("test-key-123", for: .assemblyAIAPIKey)
        XCTAssertEqual(KeychainStore.get(.assemblyAIAPIKey), "test-key-123")

        KeychainStore.delete(.assemblyAIAPIKey)
        XCTAssertNil(KeychainStore.get(.assemblyAIAPIKey))
    }

}
