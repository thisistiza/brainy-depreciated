import Foundation
import SwiftData
import PencilKit
import UIKit

enum BlockType: String, Codable, CaseIterable {
    case heading, paragraph, code, math, link, image, video, annotation, audio, file, annotatedImage
}

@Model
class Block {
    var id: UUID = UUID()
    var type: BlockType = BlockType.paragraph
    var format: String? = nil
    var text: String? = ""
    var order: Int = 0
    @Attribute(.externalStorage) var blob1: Data? = nil
    @Attribute(.externalStorage) var blob2: Data? = nil
    
    var isTested: Bool = false
    var note: Note? = nil
    
    init(type: BlockType = .paragraph, order: Int = 0, text: String = "", blob1: Data? = nil, blob2: Data? = nil) {
        self.type = type
        self.order = order
        self.text = text
        self.blob1 = blob1
        self.blob2 = blob2
    }
}

extension Block {
    @Transient
    var annotation: PKDrawing? {
        get {
            guard type == .annotation, let blob1 = blob1 else { return nil }
            return try? PKDrawing(data: blob1)
        }
        set {
            if let newValue = newValue {
                self.type = .annotation
                self.blob1 = newValue.dataRepresentation()
            } else {
                self.blob1 = nil
            }
        }
    }
    
    @Transient
    var image: UIImage? {
        get {
            guard (type == .image || type == .annotatedImage), let blob1 = blob1 else { return nil }
            return UIImage(data: blob1)
        }
        set {
            if let newValue = newValue {
                if self.type != .annotatedImage {
                    self.type = .image
                }
                self.blob1 = newValue.jpegData(compressionQuality: 1.0)
            } else {
                self.blob1 = nil
            }
        }
    }

    @Transient
    var imageAnnotation: PKDrawing? {
        get {
            guard type == .annotatedImage, let blob2 = blob2 else { return nil }
            return try? PKDrawing(data: blob2)
        }
        set {
            if let newValue = newValue {
                self.type = .annotatedImage
                self.blob2 = newValue.dataRepresentation()
            } else {
                self.blob2 = nil
            }
        }
    }
    
    @Transient
    var audio: Data? {
        get {
            guard type == .audio else { return nil }
            return blob1
        }
        set {
            if let newValue = newValue {
                self.type = .audio
                self.blob1 = newValue
            } else {
                self.blob1 = nil
            }
        }
    }
}

extension Block {
    convenience init(copying otherBlock: Block) {
        self.init(
            type: otherBlock.type,
            order: otherBlock.order,
            text: otherBlock.text ?? "",
            blob1: otherBlock.blob1,
            blob2: otherBlock.blob2
        )
        self.id = UUID()
        self.format = otherBlock.format
        self.isTested = otherBlock.isTested
        self.note = nil
    }
}
