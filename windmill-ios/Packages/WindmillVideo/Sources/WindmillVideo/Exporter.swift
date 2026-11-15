// The exporter: writes the final MP4 and its thumbnail.
public enum Exporter {
    /// 50 MiB, the same number as the backend's video upload limit.
    public static let maxBytes = 52_428_800
}
