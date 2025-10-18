import Foundation

enum AppGroup {
    static let identifier = "group.com.example.SimpleFocus"

    static func containerURL() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
}
