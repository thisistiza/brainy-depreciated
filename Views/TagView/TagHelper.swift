import SwiftUI

func stringifyTags(for tags: [Tag]) -> String {
    if tags.isEmpty {
        return "No Tags"
    }
    return tags.map { $0.name }.joined(separator: ", ")
}
