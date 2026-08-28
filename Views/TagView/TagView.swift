import SwiftData
import SwiftUI
import os

struct TagView: View {
    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext

    @Query private var sessions: [Session]
    private var session: Session? {
        sessions.sorted { $0.createdAt > $1.createdAt }.first
    }

    var note: Note
    var noteState: NoteState

    @Binding var isTagsHidden: Bool
    @State var isTagsNotDisplayed: Bool = true
    @State var tagName = ""
    let placeholder = "Enter tag + press ⏎"
    @FocusState private var isTagTextFieldFocused: Bool

    var body: some View {
        return Group {
            VStack {
                HStack{
                    DS.Component.Button(
                        icon: isTagsNotDisplayed ? "eyeClosed" : "eyeOpened",
                        theme: .system(.sapphire),
                        style: .plain,
                        size: .fitToIcon
                    ) {
                        isTagsNotDisplayed.toggle()
                    }
                    if isTagsNotDisplayed{
                        DS.Component.Capsule(text: "Tags Hidden")
                    }
                    if noteState == .editable {
                        editableTagListView()
                    }else {
                        viewableTagListView()
                    }
                }
                HStack{
                    DS.Component.Button(
                        icon: "tagBoxed",
                        theme: .system(.sapphire),
                        style: .plain,
                        size: .fitToIcon,
                        preserveIconColor: true
                    ) {
                        hideKeyboard()
                        router.navigate(to: .tagPickerRoute)
                    }
                    tagTextField()
                }.opacity(noteState == .editable ? 1:0)
                Spacer()
            }        }
        .font(DS.Typography.bodyMedium)
        .foregroundStyle(DS.Color.System.foreground.primary)
        .onAppear{
            withAnimation{
                isTagsNotDisplayed = isTagsHidden
            }
        }
        .onChange(of: isTagsHidden){ oldValue, newValue in
            withAnimation{
                isTagsNotDisplayed = newValue
            }
        }
    }
}

extension TagView{
    private func tagTextField() -> some View {
        return TextField(
            placeholder,
            text: $tagName,
            prompt: Text(placeholder).foregroundStyle(
                DS.Color.System.foreground.secondary
            )
        )
        .focused($isTagTextFieldFocused)
        .onSubmit {
            withAnimation {
                if let session = session{
                    session.appendTag(named: tagName, colored: Array(DS.Color.Palette.allCases).randomElement() ?? .sapphire, to: note,in: modelContext)
                }
                else{
                    Log.model.debug("TagView: Session is missing.")
                }
            }
            tagName = ""
            isTagTextFieldFocused = true
        }
    }
    
    private func editableTagListView() -> some View{
        return ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack {
                if note.tags.isEmpty{
                    DS.Component.Capsule(text: "No Tags")
                }
                ForEach(note.tags.sorted { $0.createdAt > $1.createdAt }) { tag in
                    DS.Component.Capsule(text: tag.name, palette: tag.color) {
                        withAnimation {
                            session?.delete(
                                tag: tag,
                                from: note,
                                in: modelContext
                            )
                        }
                    }
                }
            }
        }.clipShape(Capsule())
    }
    
    private func viewableTagListView() -> some View{ //ODO
        return ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    if !isTagsNotDisplayed{
                        if note.tags.isEmpty{
                            DS.Component.Capsule(text: "No Tags")
                        }
                        ForEach(note.tags.sorted { $0.createdAt > $1.createdAt }) { tag in
                            DS.Component.Capsule(
                                text: tag.name,
                                palette: tag.color
                            )
                        }
                    }
                    Spacer()
                }
            }.clipShape(Capsule())
    }
}
