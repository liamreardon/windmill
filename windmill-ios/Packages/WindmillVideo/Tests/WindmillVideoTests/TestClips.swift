import AVFoundation
import CoreGraphics
import CoreImage
import Foundation
import ImageIO
@testable import WindmillVideo

/// The transforms a phone writes on its clips, as `AVAssetTrack.preferredTransform`.
enum ClipTransform: CaseIterable, Sendable {
    case identity, rotate90, rotate180, rotate270, mirrored, flipVertical, transpose, transverse

    /// The transform for a stored frame of `natural` size.
    func affine(natural: CGSize) -> CGAffineTransform {
        let w = natural.width, h = natural.height
        switch self {
        case .identity: return .identity
        case .rotate90: return CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: h, ty: 0)
        case .rotate180: return CGAffineTransform(a: -1, b: 0, c: 0, d: -1, tx: w, ty: h)
        case .rotate270: return CGAffineTransform(a: 0, b: -1, c: 1, d: 0, tx: 0, ty: w)
        case .mirrored: return CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: w, ty: 0)
        case .flipVertical: return CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: h)
        case .transpose: return CGAffineTransform(a: 0, b: 1, c: 1, d: 0, tx: 0, ty: 0)
        case .transverse: return CGAffineTransform(a: 0, b: -1, c: -1, d: 0, tx: h, ty: w)
        }
    }

    /// Stored size for a clip shown at `display` size.
    func natural(display: CGSize) -> CGSize {
        switch self {
        case .rotate90, .rotate270, .transpose, .transverse: CGSize(width: display.height, height: display.width)
        default: display
        }
    }
}

struct RGB: Equatable, CustomStringConvertible {
    var r: Int, g: Int, b: Int
    static let red = RGB(r: 255, g: 0, b: 0)
    static let green = RGB(r: 0, g: 255, b: 0)
    static let blue = RGB(r: 0, g: 0, b: 255)
    static let yellow = RGB(r: 255, g: 255, b: 0)
    static let black = RGB(r: 0, g: 0, b: 0)
    static let white = RGB(r: 255, g: 255, b: 255)

    /// Within 40 of 255 on every channel, for H.264's losses.
    func near(_ other: RGB) -> Bool {
        abs(r - other.r) <= 40 && abs(g - other.g) <= 40 && abs(b - other.b) <= 40
    }

    var description: String { "(\(r), \(g), \(b))" }
}

enum ClipAudio: Sendable {
    case none
    case tone(seconds: Double)
}

/// One decoded frame, read by fractions of its size from the top left.
struct TestFrame {
    let width: Int, height: Int
    private let bytes: [UInt8]

    init(_ image: CGImage) {
        let w = image.width, h = image.height
        var data = [UInt8](repeating: 0, count: w * h * 4)
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        data.withUnsafeMutableBytes { raw in
            let context = CGContext(data: raw.baseAddress, width: w, height: h, bitsPerComponent: 8,
                                    bytesPerRow: w * 4, space: space,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        width = w
        height = h
        bytes = data
    }

    func pixel(x: Double, y: Double) -> RGB {
        let px = min(width - 1, max(0, Int(x * Double(width))))
        let py = min(height - 1, max(0, Int(y * Double(height))))
        let i = (py * width + px) * 4
        return RGB(r: Int(bytes[i]), g: Int(bytes[i + 1]), b: Int(bytes[i + 2]))
    }

    /// True when any pixel in rows `y0..<y1` (fractions) is near `color`.
    func band(y0: Double, y1: Double, has color: RGB) -> Bool {
        let rows = Int(y0 * Double(height))..<Int(y1 * Double(height))
        for py in rows {
            for px in stride(from: 0, to: width, by: 2) {
                let i = (py * width + px) * 4
                if RGB(r: Int(bytes[i]), g: Int(bytes[i + 1]), b: Int(bytes[i + 2])).near(color) { return true }
            }
        }
        return false
    }
}

enum TestClips {
    static func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "windmill-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Frames that, once `transform` is applied, show red top left, green top right,
    /// blue bottom left and yellow bottom right at `size`.
    static func quarters(transform: ClipTransform, size: CGSize = CGSize(width: 1080, height: 1920),
                         duration: Double = 1, fps: Int32 = 30, audio: ClipAudio = .none) async throws -> URL {
        let natural = transform.natural(display: size)
        let affine = transform.affine(natural: natural)
        let inverse = affine.inverted()
        let half = CGSize(width: size.width / 2, height: size.height / 2)
        let quads: [(CGRect, RGB)] = [
            (CGRect(x: 0, y: 0, width: half.width, height: half.height), .red),
            (CGRect(x: half.width, y: 0, width: half.width, height: half.height), .green),
            (CGRect(x: 0, y: half.height, width: half.width, height: half.height), .blue),
            (CGRect(x: half.width, y: half.height, width: half.width, height: half.height), .yellow),
        ]
        let fills = quads.map { ($0.0.applying(inverse).integral, $0.1) }
        return try await write(natural: natural, transform: affine, duration: duration, fps: fps, audio: audio, fills: fills)
    }

    static func solid(_ color: RGB, size: CGSize = CGSize(width: 1080, height: 1920), duration: Double = 1,
                      fps: Int32 = 30, audio: ClipAudio = .none) async throws -> URL {
        try await write(natural: size, transform: .identity, duration: duration, fps: fps, audio: audio,
                        fills: [(CGRect(origin: .zero, size: size), color)])
    }

    /// A 1 s HEVC clip tagged BT.2020 HLG, as an iPhone records HDR.
    static func hlg() async throws -> URL {
        let size = CGSize(width: 1080, height: 1920)
        return try await write(natural: size, transform: .identity, duration: 1, fps: 30, audio: .none,
                               fills: [(CGRect(origin: .zero, size: size), .red)], hdr: true)
    }

    /// The segments joined into one edit, with an optional trim and overlays.
    static func compose(_ urls: [URL], trim: ClosedRange<Double>? = nil, overlays: [TextOverlay] = [],
                        context: CIContext) async throws -> Composition {
        var segments: [Segment] = []
        for url in urls {
            segments.append(try await Segment.measured(url))
        }
        var edit = try Edit(segments: segments)
        if let trim { edit.setTrim(trim) }
        edit.overlays = overlays
        return try await Composer.make(edit, context: context)
    }

    static func fileSize(_ url: URL) throws -> Int {
        try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? -1
    }

    static func frame(at seconds: Double, in asset: AVAsset, videoComposition: AVVideoComposition?) async throws -> TestFrame {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.videoComposition = videoComposition
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        let (image, _) = try await generator.image(at: CMTime(seconds: seconds, preferredTimescale: 600))
        return TestFrame(image)
    }

    // MARK: writing

    private static func write(natural: CGSize, transform: CGAffineTransform, duration: Double, fps: Int32,
                              audio: ClipAudio, fills: [(CGRect, RGB)], hdr: Bool = false) async throws -> URL {
        let url = try folder().appending(path: "clip.mov")
        let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
        var settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(natural.width),
            AVVideoHeightKey: Int(natural.height),
        ]
        if hdr {
            // ponytail: no Main10 profile key; with 8-bit BGRA input it fails (-12902), and the HLG tags alone make an HDR track.
            settings[AVVideoCodecKey] = AVVideoCodecType.hevc
            settings[AVVideoColorPropertiesKey] = [
                AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_2020,
                AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_2100_HLG,
                AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_2020,
            ]
        }
        let video = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        video.transform = transform
        video.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: video, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: Int(natural.width),
            kCVPixelBufferHeightKey as String: Int(natural.height),
        ])
        writer.add(video)

        var audioInput: AVAssetWriterInput?
        if case .tone = audio {
            let input = AVAssetWriterInput(mediaType: .audio, outputSettings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 48_000,
                AVNumberOfChannelsKey: 1,
                AVEncoderBitRateKey: 64_000,
            ])
            input.expectsMediaDataInRealTime = false
            writer.add(input)
            audioInput = input
        }

        guard writer.startWriting() else { throw writer.error ?? CocoaError(.fileWriteUnknown) }
        writer.startSession(atSourceTime: .zero)

        let buffer = try pixelBuffer(size: natural, fills: fills)
        var tones: ArraySlice<CMSampleBuffer> = []
        if case .tone(let seconds) = audio { tones = try toneBuffers(seconds: seconds)[...] }
        // Video and audio go in by time: with every frame first, the writer stops taking video about 1 s ahead of the audio.
        let frames = Int(duration * Double(fps))
        for index in 0..<frames {
            let time = CMTime(value: CMTimeValue(index), timescale: fps)
            try await append(&tones, through: time, to: audioInput, of: writer)
            while !video.isReadyForMoreMediaData { try await waitWhileWriting(writer) }
            guard adaptor.append(buffer, withPresentationTime: time) else {
                throw writer.error ?? CocoaError(.fileWriteUnknown)
            }
        }
        video.markAsFinished()
        try await append(&tones, through: .positiveInfinity, to: audioInput, of: writer)
        audioInput?.markAsFinished()

        guard writer.status == .writing else { throw writer.error ?? CocoaError(.fileWriteUnknown) }
        var end = duration
        if case .tone(let seconds) = audio { end = max(end, seconds) }
        writer.endSession(atSourceTime: CMTime(seconds: end, preferredTimescale: 600))
        // The SDK's `await writer.finishWriting()` crashed the test process (swift_continuation_resume) with
        // several writers running at once; the completion handler form has not.
        await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
            writer.finishWriting { done.resume() }
        }
        if let error = writer.error { throw error }
        return url
    }

    /// Appends the tone buffers that start at or before `time`.
    private static func append(_ tones: inout ArraySlice<CMSampleBuffer>, through time: CMTime,
                               to input: AVAssetWriterInput?, of writer: AVAssetWriter) async throws {
        guard let input else { return }
        while let sample = tones.first, sample.presentationTimeStamp <= time {
            while !input.isReadyForMoreMediaData { try await waitWhileWriting(writer) }
            guard input.append(sample) else { throw writer.error ?? CocoaError(.fileWriteUnknown) }
            tones.removeFirst()
        }
    }

    private static func waitWhileWriting(_ writer: AVAssetWriter) async throws {
        guard writer.status == .writing else { throw writer.error ?? CocoaError(.fileWriteUnknown) }
        try await Task.sleep(for: .milliseconds(2))
    }

    private static func pixelBuffer(size: CGSize, fills: [(CGRect, RGB)]) throws -> CVPixelBuffer {
        var made: CVPixelBuffer?
        CVPixelBufferCreate(nil, Int(size.width), Int(size.height), kCVPixelFormatType_32BGRA,
                            [kCVPixelBufferIOSurfacePropertiesKey as String: [:]] as CFDictionary, &made)
        guard let buffer = made else { throw CocoaError(.fileWriteUnknown) }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        let base = CVPixelBufferGetBaseAddress(buffer)!.assumingMemoryBound(to: UInt8.self)
        let rowBytes = CVPixelBufferGetBytesPerRow(buffer)
        let width = Int(size.width), height = Int(size.height)
        for (rect, color) in fills {
            let x0 = max(0, Int(rect.minX)), x1 = min(width, Int(rect.maxX))
            let y0 = max(0, Int(rect.minY)), y1 = min(height, Int(rect.maxY))
            guard x0 < x1, y0 < y1 else { continue }
            for y in y0..<y1 {
                let row = base + y * rowBytes
                for x in x0..<x1 {
                    row[x * 4] = UInt8(color.b)
                    row[x * 4 + 1] = UInt8(color.g)
                    row[x * 4 + 2] = UInt8(color.r)
                    row[x * 4 + 3] = 255
                }
            }
        }
        return buffer
    }

    /// A quiet 440 Hz tone as 48 kHz mono PCM, in buffers of 4,800 frames.
    private static func toneBuffers(seconds: Double) throws -> [CMSampleBuffer] {
        let rate = 48_000
        var asbd = AudioStreamBasicDescription(mSampleRate: Double(rate), mFormatID: kAudioFormatLinearPCM,
                                               mFormatFlags: kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked,
                                               mBytesPerPacket: 2, mFramesPerPacket: 1, mBytesPerFrame: 2,
                                               mChannelsPerFrame: 1, mBitsPerChannel: 16, mReserved: 0)
        var format: CMAudioFormatDescription?
        CMAudioFormatDescriptionCreate(allocator: nil, asbd: &asbd, layoutSize: 0, layout: nil, magicCookieSize: 0,
                                       magicCookie: nil, extensions: nil, formatDescriptionOut: &format)
        guard let format else { throw CocoaError(.fileWriteUnknown) }
        let total = Int(seconds * Double(rate))
        var buffers: [CMSampleBuffer] = []
        var start = 0
        while start < total {
            let count = min(4_800, total - start)
            var samples = [Int16](repeating: 0, count: count)
            for i in 0..<count {
                samples[i] = Int16(3_000 * sin(2 * Double.pi * 440 * Double(start + i) / Double(rate)))
            }
            var block: CMBlockBuffer?
            CMBlockBufferCreateWithMemoryBlock(allocator: nil, memoryBlock: nil, blockLength: count * 2,
                                               blockAllocator: nil, customBlockSource: nil, offsetToData: 0,
                                               dataLength: count * 2, flags: 0, blockBufferOut: &block)
            guard let block else { throw CocoaError(.fileWriteUnknown) }
            samples.withUnsafeBytes { raw in
                _ = CMBlockBufferReplaceDataBytes(with: raw.baseAddress!, blockBuffer: block, offsetIntoDestination: 0,
                                                  dataLength: count * 2)
            }
            var sample: CMSampleBuffer?
            CMAudioSampleBufferCreateReadyWithPacketDescriptions(
                allocator: nil, dataBuffer: block, formatDescription: format, sampleCount: count,
                presentationTimeStamp: CMTime(value: CMTimeValue(start), timescale: CMTimeScale(rate)),
                packetDescriptions: nil, sampleBufferOut: &sample)
            guard let sample else { throw CocoaError(.fileWriteUnknown) }
            buffers.append(sample)
            start += count
        }
        return buffers
    }
}
