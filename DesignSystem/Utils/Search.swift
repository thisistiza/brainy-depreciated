import SwiftUI

func levenshteinDistance(s1: String, s2: String) -> Int {
    let empty = [Int](repeating: 0, count: s2.count + 1)
    var last = [Int](0...s2.count)

    for (i, char1) in s1.enumerated() {
        var current = [i + 1] + empty.dropFirst()
        for (j, char2) in s2.enumerated() {
            current[j + 1] = char1 == char2 ? last[j] : min(last[j], last[j + 1], current[j]) + 1
        }
        last = current
    }
    return last.last!
}

func searchFilter<T>(
    text: String,
    source: [T],
    keyPath: KeyPath<T, String>,
    result: inout [T]
) {
    let query = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    
    withAnimation {
        if query.isEmpty {
            result = source
        } else {
            result = source.filter { item in
                let name = item[keyPath: keyPath].lowercased()
                if name.contains(query) { return true }
                let allowedEdits = query.count > 5 ? 2 : 1
                let distance = levenshteinDistance(s1: query, s2: name)
                
                return distance <= allowedEdits
            }
        }
    }
}
