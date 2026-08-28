import HighlightSwift
import SwiftUI
import SwiftData

struct CodeBlockView: View {
    @Environment(Router.self) var router
    @Environment(\.modelContext) var modelContext
    @Query var sessions: [Session]
    var session: Session? {
        sessions.sorted { $0.createdAt > $1.createdAt }.first
    }
    var block: Block
    var isEditable: Bool

    var body: some View {
        Group {
            if isEditable {
                ZStack(alignment: .top) {
                    editableEditorView()
                    HStack {
                        DS.Component.Button(
                            icon: "terminalMuted",
                            style: .plain,
                            size: .compact,
                            preserveIconColor: true,
                            isDisabled: session == nil
                        ) {
                            if let session = session{
                                hideKeyboard()
                                session.setCurrentEditingBlock(to: block)
                                router.navigate(to: .programmingLanguageListRoute)
                            }
                        }
                    }.frame(maxWidth: .infinity, alignment: .trailing)
                }
            } else {
                readOnlyDisplayView()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension CodeBlockView {
    private func editableEditorView() -> some View {
        return CodeEditor(text: codeBinding, placeholder: "Enter code...")
    }

    private func readOnlyDisplayView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            CodeText(block.text ?? "")
                .codeTextColors(
                    .custom(
                        dark: .custom(css: CodeTheme.dark),
                        light: .custom(css: CodeTheme.light)
                    )
                )
                .highlightLanguage(getHighlightLanguage(from: block.format))
                .font(DS.Typography.code)
                .fixedSize(horizontal: true, vertical: false)
                .padding()
        }
        .background(Color.black)
        .contextMenu {
            Button(action: copyToPasteboard) {
                Label("Copy Code", systemImage: "doc.on.doc")
            }
        }
    }
}

extension CodeBlockView {
    private var codeBinding: Binding<String> {
        Binding(
            get: { block.text ?? "" },
            set: { block.text = $0.isEmpty ? nil : $0 }
        )
    }

    private func copyToPasteboard() {
        UIPasteboard.general.string = block.text ?? ""
    }
}

private enum CodeTheme {
    static let dark = """
        .hljs { background: transparent; color: #ffffff; }
        .hljs-keyword, .hljs-selector-tag { color: #986ef7; font-weight: bold; }
        .hljs-string, .hljs-literal, .hljs-number { color: #e85159; }
        .hljs-title, .hljs-function { color: #f3af3d; }
        .hljs-type { color: #55b77c; }
        .hljs-comment, .hljs-quote { color: #55b77c; font-style: italic; }
        """
        
    static let light = """
        .hljs { background: transparent; color: #ffffff; }
        .hljs-keyword, .hljs-selector-tag { color: #986ef7; font-weight: bold; }
        .hljs-string, .hljs-literal, .hljs-number { color: #e85159; }
        .hljs-title, .hljs-function { color: #f3af3d; }
        .hljs-type { color: #55b77c; }
        .hljs-comment, .hljs-quote { color: #55b77c; font-style: italic; }
        """
}

func getHighlightLanguage(from languageString: String?) -> HighlightLanguage {
    guard let languageString = languageString else { return .plaintext }

    let normalized = languageString.trimmingCharacters(
        in: .whitespacesAndNewlines
    ).lowercased()

    switch normalized {
    case "applescript": return .appleScript
    case "arduino": return .arduino
    case "awk": return .awk
    case "bash": return .bash
    case "basic": return .basic
    case "c": return .c
    case "cpp": return .cPlusPlus
    case "csharp": return .cSharp
    case "clojure": return .clojure
    case "css": return .css
    case "dart": return .dart
    case "delphi": return .delphi
    case "diff": return .diff
    case "django": return .django
    case "dockerfile": return .dockerfile
    case "elixir": return .elixir
    case "elm": return .elm
    case "erlang": return .erlang
    case "gherkin": return .gherkin
    case "go": return .go
    case "gradle": return .gradle
    case "graphql": return .graphQL
    case "haskell": return .haskell
    case "html": return .html
    case "java": return .java
    case "javascript": return .javaScript
    case "json": return .json
    case "julia": return .julia
    case "kotlin": return .kotlin
    case "latex": return .latex
    case "less": return .less
    case "lisp": return .lisp
    case "lua": return .lua
    case "makefile": return .makefile
    case "markdown": return .markdown
    case "mathematica": return .mathematica
    case "matlab": return .matlab
    case "nix": return .nix
    case "objectivec": return .objectiveC
    case "perl": return .perl
    case "php": return .php
    case "php-template": return .phpTemplate
    case "plaintext": return .plaintext
    case "swift": return .swift
    case "shell": return .shell
    case "sql": return .sql
    case "postgresql": return .postgreSQL
    case "protobuf": return .protocolBuffers
    case "python": return .python
    case "python-repl": return .pythonRepl
    case "r": return .r
    case "ruby": return .ruby
    case "rust": return .rust
    case "scala": return .scala
    case "scss": return .scss
    case "toml": return .toml
    case "typescript": return .typeScript
    case "vbnet": return .visualBasic
    case "wasm": return .webAssembly
    case "yaml": return .yaml
    default: return .plaintext
    }
}
