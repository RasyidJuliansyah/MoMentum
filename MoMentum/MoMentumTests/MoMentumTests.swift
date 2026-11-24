//
//  MoMentumTests.swift
//  MoMentumTests
//
//  Created by Rasyid Juliansyah on 24/11/26.
//

import XCTest
import SwiftData
@testable import MoMentum

final class MoMentumTests: XCTestCase {

    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([Meeting.self, Segment.self, Utterance.self, ActionItem.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

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

    // L1.1: Meeting punya konteks (agenda, istilah, penanda) dan endedAt, lolos round-trip di container in-memory.
    func testMeetingContextFieldsRoundTrip() throws {
        let context = try makeInMemoryContext()
        let meeting = Meeting(title: "Weekly Sync Product")
        meeting.agenda = "review sprint & roadmap Q1"
        meeting.glossaryTerms = ["MoMentum", "AssemblyAI"]
        meeting.markerOffsets = [120, 930.5]
        context.insert(meeting)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Meeting>()).first
        XCTAssertEqual(fetched?.agenda, "review sprint & roadmap Q1")
        XCTAssertEqual(fetched?.glossaryTerms, ["MoMentum", "AssemblyAI"])
        XCTAssertEqual(fetched?.markerOffsets, [120, 930.5])
        XCTAssertNil(fetched?.endedAt, "endedAt nil berarti rekaman belum ditutup rapi")

        fetched?.endedAt = Date(timeIntervalSince1970: 1_700_000_000)
        try context.save()
        let reFetched = try context.fetch(FetchDescriptor<Meeting>()).first
        XCTAssertEqual(reFetched?.endedAt, Date(timeIntervalSince1970: 1_700_000_000))
    }

    // L1.2: langkah proses dan jenis error terakhir tersimpan, MeetingStatus tidak diubah.
    func testMeetingProcessingStepAndErrorRoundTrip() throws {
        let context = try makeInMemoryContext()
        let meeting = Meeting(title: "Sprint Planning", status: .failed)
        meeting.processingStep = .transcribing
        meeting.lastErrorKind = .invalidAPIKey
        meeting.lastErrorMessage = "API key STT ditolak (401)."
        context.insert(meeting)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Meeting>()).first
        XCTAssertEqual(fetched?.status, .failed)
        XCTAssertEqual(fetched?.processingStep, .transcribing)
        XCTAssertEqual(fetched?.lastErrorKind, .invalidAPIKey)
        XCTAssertEqual(fetched?.lastErrorMessage, "API key STT ditolak (401).")
    }

}
