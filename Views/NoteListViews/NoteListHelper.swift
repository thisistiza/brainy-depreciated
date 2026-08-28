import SwiftUI
import SwiftData

struct GroupListView: View {
    let session: Session
    let isTagHidden: Bool
    let isReviewable: Bool
    let notes: [Note]
    let tagGroup: TagGroup?
    let color: DS.Color.Palette
    let isRated: Bool
    let isCharged: Bool

    @Environment(Router.self) private var router

    private let headerMaxWidth: CGFloat = 360
    
    private func getTagGroupIndex() -> String{
        if let tagGroup = tagGroup{
            return "\(tagGroup.order + 1). "
        }
        return ""
    }

    var body: some View {
        // Bind the index directly to the element to avoid stale closure captures
        ForEach(Array(notes.sorted{$0.createdAt < $1.createdAt}.enumerated()), id: \.element.id) { currentIndex, note in
            let compoundID = "\(tagGroup?.id.hashValue ?? 0)-\(note.id)"
            HStack(alignment: .top) {
                DS.Component.Tile(
                    text: note.title.isEmpty ? "Untitled" : note.title,
                    subtext: "\(getTagGroupIndex())\(currentIndex + 1)",
                    tags: isTagHidden ? nil : note.tags,
                    theme: .palette(color),
                    isPass: session.isNotePassing(id: note.id),
                    rating: isRated && note.review?.maturity != 0 ?  note.review?.maturity : nil,
                    charge: isCharged && note.review?.retrievalStrength != 0 ? note.review?.retrievalStrength : nil
                ) {
                    session.setCurrentReviewingNoteList(to: notes)
                    session.setCurrentReviewingNoteListIndex(to: currentIndex)
                    router.navigate(to: isReviewable ? .noteReviewerRoute: .noteRoute)
                }
                Spacer()
            }
            .frame(maxWidth: headerMaxWidth - DS.Spacing.lg)
            .id(compoundID)
        }
    }
}
