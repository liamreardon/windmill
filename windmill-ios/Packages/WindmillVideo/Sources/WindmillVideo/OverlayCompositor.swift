import AVFoundation
import CoreImage
import ImageIO

/// One segment of the joined clip: where its frames come from and how to turn them upright.
final class SegmentInstruction: NSObject, AVVideoCompositionInstructionProtocol, @unchecked Sendable {
    let timeRange: CMTimeRange
    let enablePostProcessing = false
    let containsTweening = true
    let requiredSourceTrackIDs: [NSValue]?
    let passthroughTrackID = kCMPersistentTrackID_Invalid

    let trackID: CMPersistentTrackID
    let orientation: CGImagePropertyOrientation
    let naturalSize: CGSize
    /// Every overlay, already placed in the render frame.
    let text: CIImage?
    let context: CIContext

    init(timeRange: CMTimeRange, trackID: CMPersistentTrackID, orientation: CGImagePropertyOrientation,
         naturalSize: CGSize, text: CIImage?, context: CIContext) {
        self.timeRange = timeRange
        self.trackID = trackID
        self.requiredSourceTrackIDs = [NSNumber(value: trackID)]
        self.orientation = orientation
        self.naturalSize = naturalSize
        self.text = text
        self.context = context
    }
}

/// Turns each frame upright, scales it to cover the render size, centres it, and draws the text on top.
/// The same class runs for the Edit preview and for export.
final class OverlayCompositor: NSObject, AVVideoCompositing, @unchecked Sendable {
    private let queue = DispatchQueue(label: "windmill.compositor")
    private static let attributes: [String: any Sendable] = [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
    ]

    let sourcePixelBufferAttributes: [String: any Sendable]? = OverlayCompositor.attributes
    let requiredPixelBufferAttributesForRenderContext: [String: any Sendable] = OverlayCompositor.attributes
    /// HDR sources arrive already converted to SDR.
    let supportsHDRSourceFrames = false

    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {}

    func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
        queue.async { Self.render(request) }
    }

    func cancelAllPendingVideoCompositionRequests() {
        queue.sync {}
    }

    private static func render(_ request: AVAsynchronousVideoCompositionRequest) {
        guard let instruction = request.videoCompositionInstruction as? SegmentInstruction,
              let source = request.sourceFrame(byTrackID: instruction.trackID),
              let output = request.renderContext.newPixelBuffer()
        else {
            request.finish(with: WindmillVideoError.exportFailed(underlying: CocoaError(.featureUnsupported)))
            return
        }
        let size = request.renderContext.size
        var image = CIImage(cvPixelBuffer: source).oriented(instruction.orientation)
        image = image.transformed(by: CGAffineTransform(translationX: -image.extent.minX, y: -image.extent.minY))
        let scale = max(size.width / image.extent.width, size.height / image.extent.height)
        image = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        image = image.transformed(by: CGAffineTransform(translationX: (size.width - image.extent.width) / 2,
                                                        y: (size.height - image.extent.height) / 2))
        image = image.cropped(to: CGRect(origin: .zero, size: size))
        if let text = instruction.text { image = text.composited(over: image) }
        instruction.context.render(image, to: output, bounds: CGRect(origin: .zero, size: size),
                                   colorSpace: CGColorSpace(name: CGColorSpace.itur_709))
        request.finish(withComposedVideoFrame: output)
    }
}
