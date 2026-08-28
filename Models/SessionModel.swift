import CoreTransferable
import Foundation
import SwiftData
import SwiftUI
import os

@Model
final class Session {
    @Attribute(.unique) var id: UUID = UUID()

    // Data
    @Relationship(deleteRule: .nullify) var currentProfile: Profile? = nil
    @Relationship(deleteRule: .nullify) var currentSubject: Subject? = nil
    @Relationship(deleteRule: .nullify) var currentTemporaryNote: Note? = nil
    @Relationship(deleteRule: .nullify) var currentEditingNote: Note? = nil
    @Relationship(deleteRule: .nullify) var currentEditingBlock: Block? = nil
    @Relationship(deleteRule: .nullify) var currentBlockInClipboard: Block? =
        nil
    @Relationship(deleteRule: .nullify) var currentEditingTag: Tag? = nil
    @Relationship(deleteRule: .nullify) var currentEditingTagGroup: TagGroup? =
        nil
    @Relationship(deleteRule: .nullify) var currentReviewingNoteList: [Note] =
        []
    var currentReviewingNoteListIndex: Int = 0
    var currentNotesReviewed: [UUID:Bool] = [:]
    var currentPath: [Route] = []

    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var deletedAt: Date? = nil

    init(
        id: UUID = UUID(),
        currentProfile: Profile? = nil,
        currentSubject: Subject? = nil,
        currentTemporaryNote: Note? = nil,
        currentEditingNote: Note? = nil,
        currentEditingBlock: Block? = nil,
        currentBlockInClipboard: Block? = nil,
        currentEditingTag: Tag? = nil,
        currentEditingTagGroup: TagGroup? = nil,
        currentReviewingNoteList: [Note] = [],
        currentReviewingNoteListIndex: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.currentProfile = currentProfile
        self.currentSubject = currentSubject
        self.currentTemporaryNote = currentTemporaryNote
        self.currentEditingNote = currentEditingNote
        self.currentEditingBlock = currentEditingBlock
        self.currentBlockInClipboard = currentBlockInClipboard
        self.currentEditingTag = currentEditingTag
        self.currentEditingTagGroup = currentEditingTagGroup
        self.currentReviewingNoteList = currentReviewingNoteList
        self.currentReviewingNoteListIndex = currentReviewingNoteListIndex
        self.updatedAt = updatedAt
        self.createdAt = createdAt
        self.deletedAt = deletedAt
    }
}

extension Session {
    convenience init(copying otherSession: Session) {
        self.init(
            id: UUID(),
            currentProfile: otherSession.currentProfile,
            currentSubject: otherSession.currentSubject,
            currentTemporaryNote: otherSession.currentTemporaryNote,
            currentEditingNote: otherSession.currentEditingNote,
            currentEditingBlock: otherSession.currentEditingBlock,
            currentBlockInClipboard: otherSession.currentBlockInClipboard,
            currentEditingTag: otherSession.currentEditingTag,
            currentEditingTagGroup: otherSession.currentEditingTagGroup,
            currentReviewingNoteList: otherSession.currentReviewingNoteList,
            currentReviewingNoteListIndex: otherSession
                .currentReviewingNoteListIndex
        )
    }
}

extension Session {
    func saveSession(in modelContext: ModelContext) {
        modelContext.insert(self)
        Log.model.debug(
            "Session: Inserted new session \"\(self.id)\" to model context."
        )
        save(in: modelContext)
    }

    func copyBlockToClipboard(_ block: Block) {
        self.currentBlockInClipboard = block
        Log.model.debug("Session: Copied \"\(block.id)\" to clipboard.")
    }

    func pasteBlockFromClipboard(
        to note: Note,
        isTemporary: Bool = false,
        in modelContext: ModelContext
    ) {
        if let block = currentBlockInClipboard {
            let blockCopy = Block(copying: block)
            if isTemporary {
                blockCopy.isTested = false
            }
            self.appendBlock(
                existingBlock: blockCopy,
                to: note,
                in: modelContext
            )
            Log.model.debug(
                "Session: Pasted block \"\(block.id)\" to note \"\(!note.title.isEmpty ? note.title : note.id.uuidString)\" from clipboard."
            )
        } else {
            Log.model.debug(
                "Session: Failed to paste from clipboard: Block clipboard is empty."
            )
        }
    }

    @discardableResult
    func createProfile(
        fistName: String,
        lastName: String,
        dateOfBirth: Date,
        for session: Session,
        in modelContext: ModelContext
    ) -> Profile {
        let newProfile = Profile(
            firstName: fistName,
            lastName: lastName,
            dateOfBirth: dateOfBirth
        )
        Log.model.debug(
            "Session: Created new profile \"\(newProfile.firstName) \(newProfile.lastName)\"."
        )
        modelContext.insert(newProfile)
        Log.model.debug(
            "Session: Inserted new profile \"\(newProfile.firstName) \(newProfile.lastName)\" to model context."
        )
        save(in: modelContext)
        self.setCurrentProfile(to: newProfile)
        return newProfile
    }

    @discardableResult
    func appendSubject(
        named name: String,
        to profile: Profile,
        in modelContext: ModelContext
    ) -> Subject? {
        let newSubject = Subject(name: name)
        Log.model.debug("Session: Created new subject \"\(name)\".")
        newSubject.profile = profile
        Log.model.debug(
            "Session: Profile of new subject \"\(name)\" is set to profile \"\(profile.firstName) \(profile.lastName)\"."
        )
        modelContext.insert(newSubject)
        Log.model.debug(
            "Session: Inserted new subject \"\(name)\" to model context."
        )
        save(in: modelContext)
        appendTagGroup(
            named: "All Notes",
            colored: .sapphire,
            matchingRule: .universal,
            for: newSubject,
            in: modelContext
        )
        return newSubject
    }

    @discardableResult
    func appendNote(to subject: Subject, in modelContext: ModelContext) -> Note
    {
        let newNote = Note()
        Log.model.debug("Session: Created new note \"\(newNote.id)\".")
        newNote.subject = subject
        Log.model.debug(
            "Session: Subject of new subject \"\(newNote.id)\" is set to subject \"\(subject.name)\"."
        )
        modelContext.insert(newNote)
        Log.model.debug(
            "Session: Inserted new note \"\(newNote.id)\" to model context."
        )
        newNote.review = Review()
        Log.model.debug(
            "Session: Created review for new note \"\(newNote.id)\" to model context."
        )
        save(in: modelContext)
        return newNote
    }

    @discardableResult
    func createTemporaryNote(in modelContext: ModelContext) -> Note {
        let newNote = Note(isTemporary: true)
        Log.model.debug("Session: Created new note \"\(newNote.id)\".")
        modelContext.insert(newNote)
        Log.model.debug(
            "Session: Inserted new note \"\(newNote.id)\" to model context."
        )
        save(in: modelContext)
        return newNote
    }

    @discardableResult
    func appendBlock(
        of type: BlockType,
        to note: Note,
        in modelContext: ModelContext
    ) -> Block {
        let maxOrder = note.blocks.map { $0.order }.max() ?? -1
        let nextOrder = maxOrder + 1
        let newBlock = Block(type: type, order: nextOrder)
        Log.model.debug(
            "Session: Created new block \"\(newBlock.id)\" on line \(nextOrder)."
        )
        newBlock.note = note
        Log.model.debug(
            "Session: Note of new block \"\(newBlock.id)\" is set to note \"\(!note.title.isEmpty ? note.title : note.id.uuidString)\"."
        )
        modelContext.insert(newBlock)
        Log.model.debug(
            "Session: Inserted new block \"\(newBlock.id)\" to model context."
        )
        save(in: modelContext)
        return newBlock
    }

    @discardableResult
    func appendBlock(
        existingBlock block: Block,
        to note: Note,
        in modelContext: ModelContext
    ) -> Block {
        let maxOrder = note.blocks.map { $0.order }.max() ?? -1
        let nextOrder = maxOrder + 1
        block.order = nextOrder
        Log.model.debug(
            "Session: Set new block \"\(block.id)\" on line \(nextOrder)."
        )
        block.note = note
        Log.model.debug(
            "Session: Note of new block \"\(block.id)\" is set to note \"\(!note.title.isEmpty ? note.title : note.id.uuidString)\"."
        )
        modelContext.insert(block)
        Log.model.debug(
            "Session: Inserted new block \"\(block.id)\" to model context."
        )
        save(in: modelContext)
        return block
    }

    func moveBlocks(in note: Note, from offsets: IndexSet, to destination: Int)
    {
        var sorted = note.orderedBlocks
        sorted.move(fromOffsets: offsets, toOffset: destination)
        for (index, block) in sorted.enumerated() {
            block.order = index
        }
        note.blocks = sorted
    }

    @discardableResult
    func appendTagGroup(
        named name: String,
        colored color: DS.Color.Palette,
        matchingRule: TagMatchingRule,
        for subject: Subject,
        in modelContext: ModelContext
    ) -> TagGroup? {
        let newTagGroup = TagGroup(
            name: name,
            color: color,
            matchingRule: matchingRule
        )
        Log.model.debug("Session: Created new tag group \"\(name)\".")
        newTagGroup.order = subject.tagGroups.count
        Log.model.debug(
            "Session: Existing tag group is ordered to \"\(newTagGroup.order)\"."
        )
        newTagGroup.subject = subject
        Log.model.debug(
            "Session: Subject of new tag group \"\(name)\" is set to subject \"\(subject.name)\"."
        )
        subject.tagGroups.append(newTagGroup)
        Log.model.debug(
            "Session: New tag group \"\(name)\" is appended to tag group list in subject \"\(subject.name)\"."
        )
        modelContext.insert(newTagGroup)
        Log.model.debug(
            "Session: Inserted new tag group \"\(name)\" to model context."
        )
        save(in: modelContext)
        return newTagGroup
    }

    @discardableResult
    func appendTagGroup(
        existingTagGroup tagGroup: TagGroup,
        in modelContext: ModelContext
    ) -> TagGroup? {
        guard let subject = tagGroup.subject else {
            Log.model.debug(
                "Session: Subject in existing tag group \"\(tagGroup.name)\" is missing."
            )
            return nil
        }
        tagGroup.order = subject.tagGroups.count
        Log.model.debug(
            "Session: Existing tag group is ordered to \"\(tagGroup.order)\"."
        )
        subject.tagGroups.append(tagGroup)
        Log.model.debug(
            "Session: New tag group \"\(tagGroup.name)\" is appended to tag group list in subject \"\(subject.name)\"."
        )
        modelContext.insert(tagGroup)
        Log.model.debug(
            "Session: Inserted new tag group \"\(tagGroup.name)\" to model context."
        )
        save(in: modelContext)
        return tagGroup
    }

    @discardableResult
    func appendTag(
        named name: String,
        colored color: DS.Color.Palette,
        to note: Note,
        in modelContext: ModelContext
    ) -> Tag? {
        if let subject = note.subject {
            if let tag = subject.tags.filter({
                $0.name.lowercased() == name.lowercased()
            }).first {
                Log.model.debug(
                    "Session: Failed to add tag \"\(name)\" to current subject in session: Tag already exists."
                )
                if note.tags.filter({
                    $0.name.lowercased() == name.lowercased()
                }).first != nil {
                    Log.model.debug(
                        "Session: Failed to add tag \"\(name)\" to current editing note: Tag already exists."
                    )
                    save(in: modelContext)
                    return tag
                } else {
                    note.tags.append(tag)
                    Log.model.debug(
                        "Session: Added tag \"\(name)\" to current editing note."
                    )
                    save(in: modelContext)
                    return tag
                }
            } else {
                let newTag = Tag(name: name, color: color)
                Log.model.debug("Session: Created new tag \"\(newTag.name)\".")
                subject.tags.append(newTag)
                Log.model.debug(
                    "Session: Added tag \"\(name)\" to current subject of note \"\(!note.title.isEmpty ? note.title : note.id.uuidString)\"."
                )
                note.tags.append(newTag)
                Log.model.debug(
                    "Session: Added tag \"\(name)\" to current note \"\(!note.title.isEmpty ? note.title : note.id.uuidString)\"."
                )
                modelContext.insert(newTag)
                Log.model.debug(
                    "Session: Inserted new tag \"\(name)\" to model context."
                )
                save(in: modelContext)
                return newTag

            }
        } else {
            Log.model.debug(
                "Session: Failed to add tag \"\(name)\" to current subject in session and editing note: Note has no subject."
            )
            return nil
        }
    }

    @discardableResult
    func appendTag(
        named name: String,
        colored color: DS.Color.Palette,
        to subject: Subject,
        in modelContext: ModelContext
    ) -> Tag? {
        guard
            let tag = subject.tags.filter({
                $0.name.lowercased() == name.lowercased()
            }).first
        else {
            let newTag = Tag(name: name, color: color)
            Log.model.debug("Session: Created new tag \"\(newTag.name)\".")
            subject.tags.append(newTag)
            Log.model.debug(
                "Session: Added tag \"\(name)\" to subject \"\(subject.name)\"."
            )
            modelContext.insert(newTag)
            Log.model.debug(
                "Session: Inserted new tag \"\(name)\" to model context."
            )
            save(in: modelContext)
            return newTag
        }
        return tag
    }

    func appendTag(
        existingTag tag: Tag,
        to note: Note,
        in modelContext: ModelContext
    ) {
        guard let subject = note.subject else {
            Log.model.debug(
                "Session: Failed to add tag \"\(tag.name)\" to note \"\(!note.title.isEmpty ? note.title : note.id.uuidString)\" to subject: Subject does not exist."
            )
            return
        }
        guard subject.tags.contains(tag) else {
            Log.model.debug(
                "Session: Failed to add tag \"\(tag.name)\" to note \"\(!note.title.isEmpty ? note.title : note.id.uuidString)\" to subject \"\(subject.name)\": Tag does not exist."
            )
            return
        }
        note.tags.append(tag)
        Log.model.debug(
            "Session: Added tag \"\(tag.name)\" to note \"\(!note.title.isEmpty ? note.title : note.id.uuidString)\"."
        )
        modelContext.insert(tag)
        Log.model.debug(
            "Session: Inserted new tag \"\(tag.name)\" to model context."
        )
        save(in: modelContext)
    }

    func schedule(note: Note, isPass: Bool, reviewDate: Date = Date()) {
        if note.review == nil {
            Log.model.debug("Session: Review for note is missing.")
            note.review = Review()
            Log.model.debug("Session: Created review for note.")
        }
        Scheduler.schedule(
            review: note.review!,
            isPass: isPass,
            reviewDate: reviewDate
        )
        Log.model.debug("Session: Scheduled next review for note.")
    }
    
    func schedule(id: UUID, isPass: Bool, reviewDate: Date = Date(), in modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate { $0.id == id }
        )
        
        guard let note = try? modelContext.fetch(descriptor).first else {
            Log.model.error("Session: Failed to find Note with ID \(id)")
            return
        }

        if note.review == nil {
            Log.model.debug("Session: Review for note is missing.")
            let newReview = Review(note: note)
            modelContext.insert(newReview)
            note.review = newReview
        }

        Scheduler.schedule(
            review: note.review!,
            isPass: isPass,
            reviewDate: reviewDate
        )
        Log.model.debug("Session: Scheduled next review for note.")
    }
    
    func scheduleNotesReviewed(in modelContext: ModelContext){
        for (noteID, isPass) in self.currentNotesReviewed{
            self.schedule(id: noteID, isPass: isPass, in: modelContext)
        }
        Log.model.debug("Session: Scheduled next review for all notes.")
    }

    func undoLastReview(note: Note) {
        if let review = note.review{
            if !review.logs.isEmpty{
                review.logs.removeLast()
            }
            if let newLastReview = note.review?.logs.last?.review{
                note.review = newLastReview
            }
            else{
                note.review = Review()
            }
            Log.model.debug("Session: Reverted review for note.")
        }
        else{
            Log.model.debug("Session: Review is missing.")
        }
    }
    
    func filterNewNotes(from allNotes: [Note], in currentSubject: Subject) -> [Note]{
        return allNotes.filter { note in
            if note.subject != currentSubject { return false }
            guard let review = note.review else { return false }
            return review.state == .new
        }
    }

    func filterLearnNotes(from allNotes: [Note], in currentSubject: Subject) -> [Note] {
        return allNotes.filter { note in
            guard note.subject == currentSubject else { return false }
            guard let review = note.review else { return false }
            return (review.state == .learning || review.state == .relearning)
        }
    }

    func filterReviewNotesDueToday(from allNotes: [Note], in currentSubject: Subject) -> [Note] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        guard let endOfToday = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: startOfToday) else {
            return []
        }
        
        return allNotes.filter { note in
            guard note.subject == currentSubject else { return false }
            guard let review = note.review else { return false }
            return review.state == .review && review.nextReviewAt <= endOfToday
        }
    }

    func appendTag(
        existingTag tag: Tag,
        to tagGroup: TagGroup,
        for subject: Subject,
        in modelContext: ModelContext
    ) {
        guard subject.tags.contains(tag) else {
            Log.model.debug(
                "Session: Failed to add tag \"\(tag.name)\" to tag group \"\(tagGroup.name)\" to subject \"\(subject.name)\": Tag does not exist."
            )
            return
        }
        tagGroup.tags.append(tag)
        tag.groups.append(tagGroup)
        Log.model.debug(
            "Session: Added tag \"\(tag.name)\" to tag group \"\(tagGroup.name)\"."
        )
    }

    func update(
        subject: Subject,
        name newName: String,
        in modelContext: ModelContext
    ) {
        let oldName = subject.name
        subject.name = newName
        Log.model.debug(
            "Session: Updated tag name from \"\(oldName)\" to \"\(newName)\"."
        )
        save(in: modelContext)
    }

    func update(
        note: Note,
        to newState: SchedulingState,
        in modelContext: ModelContext
    ) {
        if let review = note.review {
            let oldState = review.state
            review.state = newState
            Log.model.debug(
                "Session: Updated note's review state from \"\(oldState.rawValue)\" to \"\(newState.rawValue)\"."
            )
            save(in: modelContext)
        } else {
            Log.model.debug(
                "Session: Failed to update state: Missing review in note."
            )
        }
    }

    func update(
        tagGroup: TagGroup,
        for subject: Subject,
        name newName: String? = nil,
        order newOrder: Int? = nil,
        matchingRule: TagMatchingRule? = nil,
        in modelContext: ModelContext
    ) {
        let tagGroupName = tagGroup.name
        let tagGroupOrder = tagGroup.order
        let tagGroupMatchingRule = tagGroup.matchingRule
        if let newName = newName {
            tagGroup.name = newName
            Log.model.debug(
                "Session: Updated tag group name from \"\(tagGroupName)\" to \"\(newName)\"."
            )
        }
        if let newOrder = newOrder {
            tagGroup.order = newOrder
            Log.model.debug(
                "Session: Updated tag group order from \"\(tagGroupOrder)\" to \"\(newOrder)\"."
            )
        }
        if let matchingRule = matchingRule {
            tagGroup.matchingRule = matchingRule
            Log.model.debug(
                "Session: Updated tag group strictness from \"\(tagGroupMatchingRule.rawValue)\" to \"\(matchingRule.rawValue)\"."
            )

        }
        save(in: modelContext)
    }

    func reorderTagGroups(for subject: Subject) {
        let sorted = subject.orderedTagGroups
        for (index, tagGroup) in sorted.enumerated() {
            tagGroup.order = index
        }
        subject.tagGroups = sorted
        Log.model.debug("Session: Reordered tag groups in \"\(subject.name)\".")
    }

    func reorderBlocks(for note: Note) {
        let sorted = note.orderedBlocks
        for (index, block) in sorted.enumerated() {
            block.order = index
        }
        note.blocks = sorted
        Log.model.debug(
            "Session: Reordered blocks in \"\(!note.title.isEmpty ? note.title : note.id.uuidString)\"."
        )
    }
    
    func updateNotesReviewed(id: UUID, isPass: Bool?){
        if let isPass = isPass{
            Log.model.debug("Session: Reviewed note to \(isPass ? "Pass" : "Fail").")
        }
        else{
            Log.model.debug("Session: Reset Review for note.")
        }
        self.currentNotesReviewed[id] = isPass
    }
    
    func resetNotesReviewed(){
        self.currentNotesReviewed = Dictionary<UUID, Bool>()
        Log.model.debug("Session: Reset all notes reviewed.")
    }
    
    func isNotePassing(id: UUID) -> Bool?{
        return self.currentNotesReviewed[id]
    }
    
    func isAllNotesReviewed() -> Bool{
        return self.currentNotesReviewed.count == self.currentReviewingNoteList.count
    }

    func update(
        tag: Tag,
        for subject: Subject,
        name newName: String? = nil,
        color: DS.Color.Palette? = nil,
        in modelContext: ModelContext
    ) {
        let tagName = tag.name
        let tagColor = tag.color.rawValue
        if let newName = newName {
            tag.name = newName
            Log.model.debug(
                "Session: Updated tag name from \"\(tagName)\" to \"\(newName)\"."
            )
        }
        if let color = color {
            tag.color = color
            Log.model.debug(
                "Session: Updated tag color from \"\(tagColor)\" to \"\(color.rawValue)\"."
            )
        }
        save(in: modelContext)
    }

    func update(path: [Route], in modelContext: ModelContext) {
        self.currentPath = path
        Log.model.debug("Session: Route path updated to \"\(path)\".")
        save(in: modelContext)
    }

    func delete(tag: Tag, from note: Note, in modelContext: ModelContext) {
        let tagName = tag.name
        note.tags = note.tags.filter { $0 != tag }
        Log.model.debug(
            "Session: Deleted tag \"\(tagName)\" from note \"\(!note.title.isEmpty ? note.title : note.id.uuidString)\"."
        )
        save(in: modelContext)
    }

    func delete(tag: Tag, from subject: Subject, in modelContext: ModelContext)
    {
        let tagName = tag.name
        modelContext.delete(tag)
        for tagGroup in subject.tagGroups {
            tagGroup.tags.removeAll { $0 == tag }
        }
        Log.model.debug(
            "Session: Deleted tag \"\(tagName)\" from tag groups in subject \"\(subject.name)\"."
        )
        subject.tags = subject.tags.filter { $0 != tag }
        Log.model.debug(
            "Session: Deleted tag \"\(tagName)\" from subject \"\(subject.name)\"."
        )
        save(in: modelContext)
    }

    func delete(
        tag: Tag,
        from tagGroup: TagGroup,
        in modelContext: ModelContext
    ) {
        let tagName = tag.name
        tagGroup.tags = tagGroup.tags.filter { $0 != tag }
        Log.model.debug(
            "Session: Deleted tag \"\(tagName)\" from tag groups \"\(tagGroup.name)\"."
        )
        save(in: modelContext)
    }

    func delete(tagGroup: TagGroup, in modelContext: ModelContext) {
        let tagGroupName = tagGroup.name
        if let subject = tagGroup.subject {
            modelContext.delete(tagGroup)
            subject.tagGroups = subject.tagGroups.filter { $0 != tagGroup }
            self.reorderTagGroups(for: subject)
            Log.model.debug(
                "Session: Deleted tag group \"\(tagGroupName)\" from subject \"\(subject.name)\"."
            )
            save(in: modelContext)
        } else {
            Log.model.debug(
                "Session: Failed to delete tag group \"\(tagGroupName)\": Subject is missing."
            )
        }
    }

    func delete(profile: Profile, in modelContext: ModelContext) {
        modelContext.delete(profile)
        Log.model.debug(
            "Session: Deleted profile \"\(profile.firstName) \(profile.lastName)\"."
        )
        save(in: modelContext)
    }

    func delete(subject: Subject, in modelContext: ModelContext) {
        modelContext.delete(subject)
        Log.model.debug("Session: Deleted subject \"\(subject.name)\".")
        save(in: modelContext)
    }

    func delete(note: Note, in modelContext: ModelContext) {
        modelContext.delete(note)
        Log.model.debug(
            "Session: Deleted note \"\(!note.title.isEmpty ? note.title : note.id.uuidString)\"."
        )
        save(in: modelContext)
    }

    func delete(block: Block, in modelContext: ModelContext) {
        if let note = block.note {
            modelContext.delete(block)
            note.blocks = note.blocks.filter { $0 != block }
            self.reorderBlocks(for: note)
            Log.model.debug(
                "Session: Deleted block \"\(block.id)\" from \(!note.title.isEmpty ? note.title : note.id.uuidString)."
            )
            save(in: modelContext)
        } else {
            Log.model.debug("Session: Failed to delete block \"\(block.id)\".")
        }
    }

    func setCurrentProfile(to profile: Profile?) {
        self.currentProfile = profile
        if let profile = profile {
            Log.model.debug(
                "Session: Current profile is set to \"\(profile.firstName) \(profile.lastName)\"."
            )
        } else {
            Log.model.debug("Session: Current profile is emptied.")
        }
    }

    func setCurrentSubject(to subject: Subject?) {
        self.currentSubject = subject

        if let subject = subject {
            Log.model.debug(
                "Session: Current profile is set to \"\(subject.name)\"."
            )
        } else {
            Log.model.debug("Session: Current subject is emptied.")
        }
    }

    func setCurrentEditingNote(to note: Note?) {
        self.currentEditingNote = note

        if let note = note {
            Log.model.debug(
                "Session: Current editing note is set to \"\(!note.title.isEmpty ? note.title : note.id.uuidString)\"."
            )
        } else {
            Log.model.debug("Session: Current editing note is emptied.")
        }
    }

    func setCurrentTemporaryNote(to note: Note?) {
        self.currentTemporaryNote = note

        if let note = note {
            Log.model.debug(
                "Session: Current temporary note is set to \"\(!note.title.isEmpty ? note.title : note.id.uuidString)\"."
            )
        } else {
            Log.model.debug("Session: Current temporary note is emptied.")
        }
    }

    func setCurrentReviewingNoteList(to noteList: [Note]) {
        self.currentReviewingNoteList = noteList

        if !noteList.isEmpty {
            Log.model.debug("Session: Current reviewing note list is set.")
        } else {
            Log.model.debug("Session: Current reviewing note is emptied.")
        }
    }

    func setCurrentReviewingNoteListIndex(to index: Int) {
        if index >= 0 && index < self.currentReviewingNoteList.count {
            self.currentReviewingNoteListIndex = index
            Log.model.debug(
                "Session: Current reviewing note list index is set to \"\(index)\"."
            )
        } else {
            Log.model.debug(
                "Session: Current reviewing note list index is out of range \"\(index)\"."
            )
        }
    }

    func incrementCurrentReviewingNoteListIndex() {
        let index = self.currentReviewingNoteListIndex + 1
        if index >= 0 && index < self.currentReviewingNoteList.count {
            self.currentReviewingNoteListIndex = index
            Log.model.debug(
                "Session: Current reviewing note list index is set to \"\(index)\"."
            )
        } else {
            Log.model.debug(
                "Session: Current reviewing note list index is out of range \"\(index)\"."
            )
        }
    }

    func decrementCurrentReviewingNoteListIndex() {
        let index = self.currentReviewingNoteListIndex - 1
        if index >= 0 && index < self.currentReviewingNoteList.count {
            self.currentReviewingNoteListIndex = index
            Log.model.debug(
                "Session: Current reviewing note list index is set to \"\(index)\"."
            )
        } else {
            Log.model.debug(
                "Session: Current reviewing note list index is out of range \"\(index)\"."
            )
        }
    }

    func setCurrentEditingBlock(to block: Block?) {
        self.currentEditingBlock = block

        if let block = block {
            Log.model.debug(
                "Session: Current editing block is set to \"\(block.id)\"."
            )
        } else {
            Log.model.debug("Session: Current editing block is emptied.")
        }
    }

    func setCurrentEditingTag(to tag: Tag?) {
        self.currentEditingTag = tag

        if let tag = tag {
            Log.model.debug(
                "Session: Current editing tag is set to \"\(tag.name)\"."
            )
        } else {
            Log.model.debug("Session: Current editing tag is emptied.")
        }
    }

    func setCurrentEditingTagGroup(to tagGroup: TagGroup?) {
        self.currentEditingTagGroup = tagGroup

        if let tagGroup = tagGroup {
            Log.model.debug(
                "Session: Current editing tag group is set to \"\(tagGroup.name)\"."
            )
        } else {
            Log.model.debug("Session: Current editing tag group is emptied.")
        }
    }

    func filterNotes(for tagGroup: TagGroup) -> [Note] {
        guard let allSubjectNotes = self.currentSubject?.notes else {
            Log.model.debug(
                "Session: Failed to build notes from tag group's matching rule: Subject is missing."
            )
            return []
        }

        // Helper closure to extract tag IDs from a note
        let getTagIDs: (Note) -> Set<PersistentIdentifier> = { note in
            Set(note.tags.map(\.persistentModelID))
        }

        Log.model.debug(
            "Session: Built notes from tag group's matching rule \"\(tagGroup.matchingRule.rawValue)\"."
        )

        switch tagGroup.matchingRule {

        // --- Universal & Default Complement ---

        case .universal:
            // Universal Set (All Notes)
            return allSubjectNotes.sorted { $0.createdAt < $1.createdAt }

        case .complement:
            // Untagged Notes (Complement of having any tag)
            return
                allSubjectNotes
                .filter { $0.tags.isEmpty }
                .sorted { $0.createdAt < $1.createdAt }

        // --- Primary Operations ---

        case .union:
            // ANY (OR): Note shares at least 1 tag with group
            let groupTagIDs = Set(tagGroup.tags.map(\.persistentModelID))
            guard !groupTagIDs.isEmpty else { return [] }

            return
                allSubjectNotes
                .filter { !groupTagIDs.isDisjoint(with: getTagIDs($0)) }
                .sorted { $0.createdAt < $1.createdAt }

        case .intersection:
            // ALL (AND): Note contains all group tags
            let groupTagIDs = Set(tagGroup.tags.map(\.persistentModelID))
            guard !groupTagIDs.isEmpty else { return [] }

            return
                allSubjectNotes
                .filter { groupTagIDs.isSubset(of: getTagIDs($0)) }
                .sorted { $0.createdAt < $1.createdAt }

        case .subset:
            // EXACT MATCH: Note tags match group tags exactly
            let groupTagIDs = Set(tagGroup.tags.map(\.persistentModelID))
            guard !groupTagIDs.isEmpty else { return [] }

            return
                allSubjectNotes
                .filter { groupTagIDs == getTagIDs($0) }
                .sorted { $0.createdAt < $1.createdAt }

        // --- Complement Operations (Inverted Logic) ---

        case .complementOfUnion:
            // NOT ANY: Note contains NONE of the selected tags (Inverted Union)
            let groupTagIDs = Set(tagGroup.tags.map(\.persistentModelID))
            guard !groupTagIDs.isEmpty else { return [] }

            return
                allSubjectNotes
                .filter { groupTagIDs.isDisjoint(with: getTagIDs($0)) }
                .sorted { $0.createdAt < $1.createdAt }

        case .complementOfIntersection:
            // NOT ALL: Note does NOT contain all selected tags (Inverted Intersection)
            let groupTagIDs = Set(tagGroup.tags.map(\.persistentModelID))
            guard !groupTagIDs.isEmpty else { return [] }

            return
                allSubjectNotes
                .filter { !groupTagIDs.isSubset(of: getTagIDs($0)) }
                .sorted { $0.createdAt < $1.createdAt }

        case .complementOfSubset:
            // NOT EXACT: Everything except an exact tag match (Inverted Subset)
            let groupTagIDs = Set(tagGroup.tags.map(\.persistentModelID))
            guard !groupTagIDs.isEmpty else { return [] }

            return
                allSubjectNotes
                .filter { groupTagIDs != getTagIDs($0) }
                .sorted { $0.createdAt < $1.createdAt }
        }
    }

    func save(in modelContext: ModelContext) {
        do {
            try modelContext.save()
            Log.model.debug("Session: Changes saved.")
        } catch { Log.model.debug("Session: Changes failed to save: \(error)") }
    }
}

extension Array where Element == Note {
    var averageMaturity: Double {
        let reviews = self.compactMap { $0.review }
        guard !reviews.isEmpty else { return 0.0 }

        let totalMaturity = reviews.reduce(0.0) { $0 + $1.maturity }
        return totalMaturity / Double(reviews.count)
    }

    var averageRetrievalStrength: Double {
        let reviews = self.compactMap { $0.review }
        guard !reviews.isEmpty else { return 0.0 }

        let totalStrength = reviews.reduce(0.0) { $0 + $1.retrievalStrength }
        return totalStrength / Double(reviews.count)
    }
}
