import Foundation
import SwiftData
import SwiftUI

@Model
final class Note {
    // ID
    var id: UUID = UUID()

    // Parent
    var subject: Subject? = nil

    // Core
    #Index<Note>([\.title])
    var title: String = ""

    @Relationship(inverse: \Tag.notes)
    var tags: [Tag] = []

    @Relationship(deleteRule: .cascade, inverse: \Block.note)
    var blocks: [Block] = []
    var orderedBlocks: [Block] { blocks.sorted { $0.order < $1.order } }

    @Relationship(deleteRule: .cascade, inverse: \Review.note)
    var review: Review? = nil
    
    // Meta
    var createdAt: Date = Date()
    var deletedAt: Date? = nil
    var updatedAt: Date = Date()

    init(title: String = "", blocks: [Block] = [], isTemporary: Bool = false) {
        self.title = title
        self.blocks = blocks
    }
}

extension Note {
    var isEmpty: Bool {
        let hasNoTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if blocks.isEmpty { return hasNoTitle }
        if blocks.count == 1, let firstBlock = blocks.first {
            let textIsEmpty = firstBlock.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
            return hasNoTitle && textIsEmpty
        }
        
        return false
    }
}

extension Note {
    convenience init(copying otherNote: Note) {
        let copiedBlocks = otherNote.orderedBlocks.map { Block(copying: $0) }
        
        self.init(title: otherNote.title, blocks: copiedBlocks)
        
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.deletedAt = nil

        self.tags = otherNote.tags
        if let originalReview = otherNote.review {
            self.review = Review(copying: originalReview)
        }
        self.subject = otherNote.subject
    }
    
    convenience init(partiallyCopying otherNote: Note) {
        let copiedBlocks = otherNote.orderedBlocks.map { Block(copying: $0) }

        self.init(
            title: otherNote.title,
            blocks: copiedBlocks
        )
        self.review = Review()
        
        self.createdAt = Date()
        self.updatedAt = Date()
        self.deletedAt = nil

        self.tags = otherNote.tags
        self.subject = otherNote.subject
    }
}
