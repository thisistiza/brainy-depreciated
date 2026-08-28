import SwiftUI

struct CodeEditor: View {
    @Binding var text: String
    var placeholder: String = "Enter code..."
    @State private var selection: TextSelection?
    
    private let standardIndent = "    "  // 4 spaces
    private let autoPairs: [Character: Character] = [
        "{": "}",
        "[": "]",
        "(": ")",
    ]
    private let closingChars: Set<Character> = ["}", "]", ")"]

    var body: some View {
        TextField(
            placeholder,
            text: $text,
            selection: $selection,
            prompt: Text(placeholder).foregroundStyle(DS.Color.System.foreground.secondary),
            axis: .vertical
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .textInputAutocapitalization(.none)
        .autocorrectionDisabled(true)
        .keyboardType(.asciiCapable)
        .font(DS.Typography.code)
        .foregroundStyle(DS.Color.Palette.emerald.base)
        .background(.black)
        .onChange(of: text) { oldValue, newValue in
            processTextChange(old: oldValue, new: newValue)
        }
    }

    private func processTextChange(old: String, new: String) {
        // Prevent infinite loops from programmatic text changes
        guard old != new else { return }

        // Only trigger operations on single character additions (typing or Enter)
        guard new.count - old.count == 1 else { return }

        // Find exactly where the text difference occurred
        guard let changeIndex = findFirstDifferenceIndex(old: old, new: new) else { return }
        let typedChar = new[changeIndex]

        // 1. STEP-OVER LOGIC (Fixes the `"` and `)` duplicate bugs)
        // If the user types a closing character that is already sitting right next to the cursor,
        // we discard the typed character and just move the cursor forward.
        if closingChars.contains(typedChar), changeIndex < old.endIndex {
            if old[changeIndex] == typedChar {
                text = old // Revert the text change
                
                DispatchQueue.main.async {
                    let nextIndex = old.index(after: changeIndex)
                    self.selection = TextSelection(insertionPoint: nextIndex)
                }
                return
            }
        }

        // 2. AUTO-PAIRING (Brackets, Braces, Parentheses, Quotes)
        if let closingMatch = autoPairs[typedChar] {
            var modifiedText = new
            let nextIndex = new.index(after: changeIndex)
            modifiedText.insert(closingMatch, at: nextIndex)

            text = modifiedText

            // Retain cursor focus precisely between the opening and closing characters
            DispatchQueue.main.async {
                self.selection = TextSelection(insertionPoint: nextIndex)
            }
            return
        }

        // 3. RETURN / SMART INDENT PROCESSING
        if typedChar == "\n" {
            let prefixText = String(new[..<changeIndex])
            let suffixText = String(new[new.index(after: changeIndex)...])
            
            let lines = prefixText.components(separatedBy: "\n")
            guard let lastLine = lines.last else { return }

            let indentation = String(lastLine.prefix { $0 == " " || $0 == "\t" })
            let trimmedLine = lastLine.trimmingCharacters(in: .whitespacesAndNewlines)

            // Scenario A: Hitting enter right inside empty brackets `{}`
            if trimmedLine.hasSuffix("{") && suffixText.hasPrefix("}") {
                let innerIndent = indentation + standardIndent
                
                text = prefixText + "\n" + innerIndent + "\n" + indentation + suffixText

                DispatchQueue.main.async {
                    // Calculate exact offset: prefix + \n + inner indent
                    let cursorOffset = prefixText.count + 1 + innerIndent.count
                    let finalCursor = text.index(text.startIndex, offsetBy: cursorOffset)
                    self.selection = TextSelection(insertionPoint: finalCursor)
                }
                return
            }

            // Scenario B: Standard indentation increase triggers
            let indentTriggers = ["{", ":", "/", "["]
            if indentTriggers.contains(where: { trimmedLine.hasSuffix($0) }) {
                let newIndent = indentation + standardIndent
                
                text = prefixText + "\n" + newIndent + suffixText

                DispatchQueue.main.async {
                    let cursorOffset = prefixText.count + 1 + newIndent.count
                    let finalCursor = text.index(text.startIndex, offsetBy: cursorOffset)
                    self.selection = TextSelection(insertionPoint: finalCursor)
                }
                return
            }

            // Scenario C: Maintain current indentation
            if !indentation.isEmpty {
                text = prefixText + "\n" + indentation + suffixText

                DispatchQueue.main.async {
                    let cursorOffset = prefixText.count + 1 + indentation.count
                    let finalCursor = text.index(text.startIndex, offsetBy: cursorOffset)
                    self.selection = TextSelection(insertionPoint: finalCursor)
                }
                return
            }
        }
    }

    /// Safely finds the index where `new` diverges from `old`.
    private func findFirstDifferenceIndex(old: String, new: String) -> String.Index? {
        var oldIdx = old.startIndex
        var newIdx = new.startIndex

        while oldIdx < old.endIndex && newIdx < new.endIndex {
            if old[oldIdx] != new[newIdx] {
                return newIdx
            }
            old.formIndex(after: &oldIdx)
            new.formIndex(after: &newIdx)
        }
        
        // If the new string is longer and we matched all the way to the end of `old`,
        // the difference is at the very end.
        if newIdx < new.endIndex {
            return newIdx
        }
        
        return nil
    }
}
