import Foundation
import Testing
@testable import Windmill

struct AppConfigTests {
    @Test func validLocalhost() throws {
        let url = try AppConfig.baseURL(info: ["WindmillAPIBaseURL": "http://localhost:8080"]).get()
        #expect(url == URL(string: "http://localhost:8080"))
    }

    @Test func missingKey() {
        #expect(AppConfig.baseURL(info: [:]) == .failure(.missing))
    }

    @Test func badScheme() {
        #expect(AppConfig.baseURL(info: ["WindmillAPIBaseURL": "ftp://x"]) == .failure(.badScheme("ftp")))
    }

    @Test func emptyHost() {
        #expect(AppConfig.baseURL(info: ["WindmillAPIBaseURL": "http://"]) == .failure(.badHost("")))
    }
}
