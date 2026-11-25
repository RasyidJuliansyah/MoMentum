import CoreData
import SwiftData
import XCTest
@testable import MoMentum

/// Database di iPhone dibuat oleh versi app sebelumnya. Versi baru harus bisa membukanya tanpa crash
/// (bug 25 Nov: `Segment.index` ditambahkan tanpa nilai bawaan → "missing attribute values on
/// mandatory destination attribute" → fatalError saat app dibuka).
final class SchemaMigrationTests: XCTestCase {

    /// Skema rilis pertama (commit f0e9309), dibangun ulang lewat Core Data karena SwiftData
    /// memakai Core Data di bawahnya dengan nama entity = nama class.
    private func firstReleaseModel() -> NSManagedObjectModel {
        func attribute(_ name: String, _ type: NSAttributeType, optional: Bool = false) -> NSAttributeDescription {
            let a = NSAttributeDescription()
            a.name = name
            a.attributeType = type
            a.isOptional = optional
            return a
        }
        let meeting = NSEntityDescription()
        meeting.name = "Meeting"
        let segment = NSEntityDescription()
        segment.name = "Segment"
        let actionItem = NSEntityDescription()
        actionItem.name = "ActionItem"

        meeting.properties = [
            attribute("title", .stringAttributeType),
            attribute("createdAt", .dateAttributeType),
            attribute("durationSeconds", .doubleAttributeType),
            attribute("status", .stringAttributeType),
        ]
        segment.properties = [
            attribute("fileName", .stringAttributeType),
            attribute("startedAt", .dateAttributeType),
            attribute("durationSeconds", .doubleAttributeType),
            attribute("transcribed", .booleanAttributeType),
        ]
        actionItem.properties = [
            attribute("task", .stringAttributeType),
            attribute("pic", .stringAttributeType),
        ]
        let model = NSManagedObjectModel()
        model.entities = [meeting, segment, actionItem]
        return model
    }

    func testStoreFromFirstReleaseOpensWithCurrentSchema() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("migration-\(UUID().uuidString).store")
        defer {
            for suffix in ["", "-shm", "-wal"] {
                try? FileManager.default.removeItem(atPath: url.path + suffix)
            }
        }

        // 1. Database lama berisi satu segmen dan satu action item.
        let oldContainer = NSPersistentContainer(name: "Old", managedObjectModel: firstReleaseModel())
        oldContainer.persistentStoreDescriptions = [NSPersistentStoreDescription(url: url)]
        var loadError: Error?
        oldContainer.loadPersistentStores { _, error in loadError = error }
        XCTAssertNil(loadError)
        let ctx = oldContainer.viewContext
        let segment = NSEntityDescription.insertNewObject(forEntityName: "Segment", into: ctx)
        segment.setValue("lama.m4a", forKey: "fileName")
        segment.setValue(Date(), forKey: "startedAt")
        segment.setValue(60.0, forKey: "durationSeconds")
        segment.setValue(false, forKey: "transcribed")
        let item = NSEntityDescription.insertNewObject(forEntityName: "ActionItem", into: ctx)
        item.setValue("Tugas lama", forKey: "task")
        item.setValue("Dina", forKey: "pic")
        try ctx.save()
        for store in oldContainer.persistentStoreCoordinator.persistentStores {
            try oldContainer.persistentStoreCoordinator.remove(store)
        }

        // 2. Buka dengan skema app sekarang, sama seperti `MoMentumApp`.
        let schema = Schema([Meeting.self, Segment.self, Utterance.self, ActionItem.self, Speaker.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url)])
        let context = ModelContext(container)

        let segments = try context.fetch(FetchDescriptor<Segment>())
        XCTAssertEqual(segments.map(\.fileName), ["lama.m4a"])
        XCTAssertEqual(segments.first?.index, 0)
        let items = try context.fetch(FetchDescriptor<ActionItem>())
        XCTAssertEqual(items.first?.task, "Tugas lama")
        XCTAssertEqual(items.first?.isDone, false)
    }
}
