import SwiftUI

@main
struct WindmillApp: App {
    private let config = AppConfig.baseURL(info: Bundle.main.infoDictionary ?? [:])

    var body: some Scene {
        WindowGroup {
            switch config {
            case .success:
                Text("Windmill")
            case .failure(let error):
                Text(error.message).padding()
            }
        }
    }
}
