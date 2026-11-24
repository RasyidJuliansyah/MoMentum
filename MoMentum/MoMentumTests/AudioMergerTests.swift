import XCTest
import AVFoundation
@testable import MoMentum

// L4.1: AudioMerger — gabung segmen jadi satu file sebelum upload (D2 = A).
final class AudioMergerTests: XCTestCase {

    /// WAV PCM sintetis (nada hening, bukan suara orang) dengan durasi tertentu.
    private func writeToneFile(seconds: Double) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).wav")
        let sampleRate: UInt32 = 8_000
        let sampleCount = UInt32(Double(sampleRate) * seconds)
        let dataSize = sampleCount * 2
        var header = Data()
        header.append(contentsOf: Array("RIFF".utf8))
        header.append(contentsOf: withUnsafeBytes(of: UInt32(36 + dataSize).littleEndian, Array.init))
        header.append(contentsOf: Array("WAVE".utf8))
        header.append(contentsOf: Array("fmt ".utf8))
        header.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian, Array.init))
        header.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian, Array.init))
        header.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian, Array.init))
        header.append(contentsOf: withUnsafeBytes(of: sampleRate.littleEndian, Array.init))
        header.append(contentsOf: withUnsafeBytes(of: (sampleRate * 2).littleEndian, Array.init))
        header.append(contentsOf: withUnsafeBytes(of: UInt16(2).littleEndian, Array.init))
        header.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian, Array.init))
        header.append(contentsOf: Array("data".utf8))
        header.append(contentsOf: withUnsafeBytes(of: dataSize.littleEndian, Array.init))
        header.append(Data(repeating: 0, count: Int(dataSize)))
        try header.write(to: url)
        return url
    }

    func testMergeThreeSegmentsDurationEqualsSum() async throws {
        let durations: [Double] = [1.0, 2.0, 1.5]
        let urls = try durations.map { try writeToneFile(seconds: $0) }
        defer { urls.forEach { try? FileManager.default.removeItem(at: $0) } }

        let merged = try await AudioMerger.merge(segmentURLs: urls)
        defer { try? FileManager.default.removeItem(at: merged) }

        let asset = AVURLAsset(url: merged)
        let mergedDuration = try await asset.load(.duration).seconds

        XCTAssertEqual(mergedDuration, durations.reduce(0, +), accuracy: 0.2)
    }

    func testMergeEmptyListThrowsNoSegments() async throws {
        do {
            _ = try await AudioMerger.merge(segmentURLs: [])
            XCTFail("Harus melempar noSegments")
        } catch AudioMergerError.noSegments {
            // sesuai harapan
        }
    }
}
