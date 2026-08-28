import PhotosUI
import SwiftData
import SwiftUI
internal import UniformTypeIdentifiers
import os

func editBarItem(
    icon: String,
    isIconColorPreserved: Bool = true,
    action: @escaping () -> Void
) -> some View {
    DS.Component.Button(
        icon: icon,
        theme: .system(.sapphire),
        style: .plain,
        size: .compact,
        preserveIconColor: isIconColorPreserved,
    ) {
        action()
    }
}

func toolBarItem(
    icon: String,
    palette: DS.Color.Palette,
    isIconColorPreserved: Bool = true,
    isSelected: Bool = false,
    action: @escaping () -> Void
) -> some View {
    DS.Component.Button(
        icon: icon,
        theme: .palette(palette),
        style: .plain,
        size: .compact,
        preserveIconColor: isIconColorPreserved,
        isSelected: isSelected
    ) {
        withAnimation(DS.Animation.handleIcon) {
            action()
        }
    }
}

func update(note: Note, for session: Session, in modelContext: ModelContext) {
    guard !isEmpty(for: note) else {
        Log.model.debug("NoteEditorHelper: Update failed: Note is missing.")
        return
    }
    note.subject = session.currentSubject
    modelContext.insert(note)

}

func isEmpty(for note: Note) -> Bool{
    if note.title.isEmpty && note.tags.isEmpty && note.blocks.isEmpty{
            Log.model.debug("NoteEditorHelper: Current editing note is missing.")
            return true
    }
    Log.model.debug("NoteEditorHelper: Current editing note is filled.")
    return false
}

func delete(note: Note, for session: Session, in modelContext: ModelContext) {
    session.delete(note: note, in: modelContext)
}

func copyAndReplace(current: Note, for session: Session, in modelContext: ModelContext) {
    let newNote = Note(partiallyCopying: current)
    newNote.title = newNote.title + " Copy"
    modelContext.insert(newNote)
    session.currentEditingNote = newNote
}

@MainActor
func save(note: Note, for session: Session, in modelContext: ModelContext) {
    guard !isEmpty(for: note) else {
        Log.model.debug("NoteEditorHelper: Update failed: Note is missing.")
        return
    }
    update(note: note, for: session, in: modelContext)
    do {
        try modelContext.save()
        Log.model.debug("NoteEditorHelper: Saved work progress so far.")
    } catch {
        Log.model.debug("NoteEditorHelper: Save failed: \(error.localizedDescription).")
    }
}

func handleFileImport(result: Result<[URL], Error>, to note: Note, for session: Session, in modelContext: ModelContext){
    switch result {
    case .success(let urls):
        guard let selectedURL = urls.first else { return }
        importSelectedFiles(at: selectedURL, to: note, for: session, in: modelContext)

    case .failure(let error):
        Log.view.debug("NoteEditorHelper: File importer failed with error: \(error.localizedDescription)")
    }
}

func importSelectedFiles(at url: URL, to note: Note, for session: Session, in modelContext: ModelContext) {
    guard url.startAccessingSecurityScopedResource() else {
        Log.view.debug("NoteEditorHelper: Failed to access security scoped resource")
        return
    }
    defer { url.stopAccessingSecurityScopedResource() }

    if let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data){
        appendNewImageBlock(with: uiImage, to: note, for: session, in: modelContext)
    }
}

func appendNewImageBlock(with uiImage: UIImage, to note: Note, for session: Session, in modelContext: ModelContext) {
    let newImageBlock = Block(type: .annotatedImage, order: note.blocks.count)
    newImageBlock.image = uiImage
    session.appendBlock(existingBlock: newImageBlock, to: note, in: modelContext)
}

