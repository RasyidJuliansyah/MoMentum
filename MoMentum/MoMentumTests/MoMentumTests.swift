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
        let schema = Schema([Meeting.self, Segment.self, Utterance.self, ActionItem.self, Speaker.self])
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

        try KeychainStore.set("test-key-123", for: .assemblyAIAPIKey)
        XCTAssertEqual(KeychainStore.get(.assemblyAIAPIKey), "test-key-123")

        KeychainStore.delete(.assemblyAIAPIKey)
        XCTAssertNil(KeychainStore.get(.assemblyAIAPIKey))
    }

    // L1.5: item tersimpan dengan kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly dan
    // kSecAttrService sebagai namespace, supaya key terbaca walau proses jalan saat terkunci.
    func testKeychainStoreUsesAfterFirstUnlockAccessibleAndServiceNamespace() throws {
        KeychainStore.delete(.assemblyAIAPIKey)
        try KeychainStore.set("test-key-123", for: .assemblyAIAPIKey)
        defer { KeychainStore.delete(.assemblyAIAPIKey) }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: KeychainStore.Key.assemblyAIAPIKey.rawValue,
            kSecAttrService as String: KeychainStore.service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        XCTAssertEqual(status, errSecSuccess)
        let attributes = result as? [String: Any]
        XCTAssertEqual(
            attributes?[kSecAttrAccessible as String] as? String,
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
        )
    }

    // L1.5: KeychainStore.set bisa throws (bukan diam-diam gagal). Error membawa OSStatus asli.
    // Trigger kegagalan OSStatus nyata tidak bisa disimulasikan andal di simulator (Keychain
    // simulator cenderung permisif), jadi tes ini memverifikasi kontrak tipe error, bukan jalur gagal.
    func testKeychainStoreErrorCarriesStatus() {
        let error = KeychainStore.KeychainError(status: errSecParam)
        XCTAssertEqual(error.status, errSecParam)
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

    // L1.3: ganti nama speaker sekali mengubah nama tampil di semua utterance berlabel sama.
    func testSpeakerRenameAffectsAllUtterancesWithSameLabel() throws {
        let context = try makeInMemoryContext()
        let meeting = Meeting(title: "Daily Standup")
        let segment = Segment(fileName: "seg1.m4a")
        let utterance1 = Utterance(speakerLabel: "Speaker 1", startMs: 0, endMs: 1000, text: "Halo")
        let utterance2 = Utterance(speakerLabel: "Speaker 1", startMs: 1000, endMs: 2000, text: "Lanjut")
        segment.utterances = [utterance1, utterance2]
        meeting.segments = [segment]
        let speaker = Speaker(label: "Speaker 1")
        meeting.speakers = [speaker]
        context.insert(meeting)
        try context.save()

        XCTAssertEqual(meeting.displayName(for: "Speaker 1"), "Speaker 1", "belum diganti, jatuh ke label mentah")

        speaker.name = "Budi"
        try context.save()

        XCTAssertEqual(meeting.displayName(for: utterance1.speakerLabel), "Budi")
        XCTAssertEqual(meeting.displayName(for: utterance2.speakerLabel), "Budi")
        XCTAssertEqual(meeting.displayName(for: "Speaker 2"), "Speaker 2", "label tanpa Speaker tersimpan tetap mentah")
    }

    // L1.4: hapus Meeting ikut menghapus segment, utterance, action item, dan speaker (cascade).
    func testDeletingMeetingCascadesToChildren() throws {
        let context = try makeInMemoryContext()
        let meeting = Meeting(title: "Retro Sprint 9")
        let segment = Segment(fileName: "seg1.m4a", index: 0)
        let utterance = Utterance(speakerLabel: "Speaker 1", startMs: 0, endMs: 500, text: "Oke")
        segment.utterances = [utterance]
        meeting.segments = [segment]
        meeting.actionItems = [ActionItem(task: "Tulis notulen", pic: "Budi")]
        meeting.speakers = [Speaker(label: "Speaker 1", name: "Budi")]
        context.insert(meeting)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Segment>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Utterance>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ActionItem>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Speaker>()), 1)

        context.delete(meeting)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Segment>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Utterance>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ActionItem>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Speaker>()), 0)
    }

    // L1.4: index Segment dan providerJobId Meeting tersimpan dan terbaca kembali.
    func testSegmentIndexAndMeetingProviderJobIdRoundTrip() throws {
        let context = try makeInMemoryContext()
        let meeting = Meeting(title: "Daily Standup")
        meeting.providerJobId = "job-abc-123"
        meeting.segments = [
            Segment(fileName: "a.m4a", index: 0),
            Segment(fileName: "b.m4a", index: 1),
        ]
        context.insert(meeting)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Meeting>()).first
        XCTAssertEqual(fetched?.providerJobId, "job-abc-123")
        XCTAssertEqual(fetched?.segments.sorted(by: { $0.index < $1.index }).map(\.index), [0, 1])
    }

}
