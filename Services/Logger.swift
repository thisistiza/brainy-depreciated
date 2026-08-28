import Foundation
import os

enum Log{
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.briany.bundle"
    static let view = Logger(subsystem: subsystem, category: "View")
    static let router = Logger(subsystem: subsystem, category: "Router")
    static let model = Logger(subsystem: subsystem, category: "Model")
    static let animation = Logger(subsystem: subsystem, category: "Animation")
}
