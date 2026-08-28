import SwiftData
import SwiftUI
import os

struct ProgrammingLanguageListView: View {
    @Environment(Router.self) var router
    @Environment(\.modelContext) var modelContext
    @Query var sessions: [Session]
    var session: Session? {
        sessions.sorted { $0.createdAt > $1.createdAt }.first
    }
    var programmingLanguageNameToIdentifier: [String: String] = [
        "AppleScript": "applescript",
        "Arduino": "arduino",
        "Awk": "awk",
        "Bash / Shell": "bash",
        "Basic": "basic",
        "C": "c",
        "C++": "cpp",
        "C#": "csharp",
        "Clojure": "clojure",
        "CSS": "css",
        "Dart": "dart",
        "Delphi": "delphi",
        "Diff": "diff",
        "Django / Jinja templates": "django",
        "Dockerfile": "dockerfile",
        "Elixir": "elixir",
        "Elm": "elm",
        "Erlang": "erlang",
        "Gherkin": "gherkin",
        "Go": "go",
        "Gradle": "gradle",
        "GraphQL": "graphql",
        "Haskell": "haskell",
        "HTML": "html",
        "Java": "java",
        "JavaScript": "javascript",
        "JSON": "json",
        "Julia": "julia",
        "Kotlin": "kotlin",
        "LaTeX": "latex",
        "Less": "less",
        "Lisp": "lisp",
        "Lua": "lua",
        "Makefile": "makefile",
        "Markdown": "markdown",
        "Mathematica": "mathematica",
        "MATLAB": "matlab",
        "Nix": "nix",
        "Objective C": "objectivec",
        "Perl": "perl",
        "PHP": "php",
        "PHP Template": "php-template",
        "Plaintext": "plaintext",
        "Swift": "swift",
        "Shell": "shell",
        "SQL": "sql",
        "PostgreSQL": "postgresql",
        "Protocol Buffers": "protobuf",
        "Python": "python",
        "Python REPL": "python-repl",
        "R": "r",
        "Ruby": "ruby",
        "Rust": "rust",
        "Scala": "scala",
        "SCSS": "scss",
        "TOML": "toml",
        "TypeScript": "typescript",
        "Visual Basic": "vbnet",
        "WebAssembly": "wasm",
        "YAML": "yaml",
    ]

    var body: some View {
        DS.Component.ContentContainer {
            if let session = session,
                let currentEditingBlock = session.currentEditingBlock
            {
                VStack(spacing: 0) {
                    paneBar(session: session)
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: DS.Spacing.md) {
                            Text(
                                "Pick what language you would like to see your code highlighted in. This will only be visible when not editing."
                            )
                            .font(DS.Typography.bodyMedium)
                            .foregroundStyle(DS.Color.System.foreground.primary)

                            ForEach(
                                Array(programmingLanguageNameToIdentifier.keys)
                                    .sorted(),
                                id: \.self
                            ) { programmingLanguageName in
                                HStack {
                                    let isProgrammingLanguageNameSelected = currentEditingBlock.format == programmingLanguageNameToIdentifier[programmingLanguageName]

                                    DS.Component.Button(
                                        icon: "terminal",
                                        text: programmingLanguageName,
                                        theme: .system(.emerald),
                                        style: .hollow,
                                        alignment: .leading,
                                        preserveIconColor: true,
                                        isSelected:
                                            isProgrammingLanguageNameSelected
                                    ) {
                                        let originalFormat = currentEditingBlock.format
                                        if isProgrammingLanguageNameSelected {
                                            currentEditingBlock.format = nil
                                        } else {
                                            currentEditingBlock.format =
                                                programmingLanguageNameToIdentifier[
                                                    programmingLanguageName
                                                ]
                                            session.setCurrentEditingBlock(to: nil)
                                            router.navigateBack()
                                        }
                                        Log.model.debug("ProgrammingLanguageListView: Current editing block in session updated format from \(originalFormat ?? "plain text") to \(currentEditingBlock.format ?? "plain text")")
                                    }
                                }
                            }
                        }
                        .cancelScrollViewDelay()
                        .padding()
                    }
                }
            } else {
                DS.Component.ErrorView(messages: ["ProgrammingLanguageListView: Session is missing."]).onAppear{
                    Log.model.debug("ProgrammingLanguageListView: Session is missing.")
                }
            }
        }
    }
}

extension ProgrammingLanguageListView {
    func paneBar(session: Session) -> some View {
        return VStack {
            ZStack {
                HStack {
                    DS.Component.Button(
                        icon: "cross",
                        theme: .system(.sapphire),
                        style: .plain,
                        size: .compact
                    ) {
                        session.setCurrentEditingBlock(to: nil)
                        router.navigateBack()
                    }
                    Spacer()
                }
                HStack {
                    Spacer()
                    Text("Programming Languages")
                        .font(DS.Typography.bodyLarge)
                        .foregroundStyle(DS.Color.System.foreground.primary)
                    Spacer()
                }
            }
            .padding(.horizontal, DS.Spacing.md)
            DS.Component.HorizontalDivider()
        }
    }
}
