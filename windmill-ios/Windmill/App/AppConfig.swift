import Foundation

enum AppConfigError: Error, Equatable {
    case missing
    case badScheme(String)
    case badHost(String)

    var message: String {
        switch self {
        case .missing:
            "WindmillAPIBaseURL is missing from Info.plist. Run make ios to generate the project again."
        case .badScheme(let scheme):
            "The API scheme is \(scheme). Set WINDMILL_API_SCHEME to http or https in windmill-ios/Config."
        case .badHost(let host):
            "The API host \"\(host)\" isn't valid. Set WINDMILL_API_HOST in windmill-ios/Config, or run make device-config."
        }
    }
}

enum AppConfig {
    /// The API base URL from Info.plist, checked at launch so a bad config shows a message instead of a crash.
    static func baseURL(info: [String: Any]) -> Result<URL, AppConfigError> {
        guard let raw = info["WindmillAPIBaseURL"] as? String, !raw.isEmpty else { return .failure(.missing) }
        guard let parts = URLComponents(string: raw), let scheme = parts.scheme else { return .failure(.badHost(raw)) }
        guard scheme == "http" || scheme == "https" else { return .failure(.badScheme(scheme)) }
        guard let host = parts.host, !host.isEmpty, let url = parts.url else { return .failure(.badHost(parts.host ?? "")) }
        return .success(url)
    }
}
