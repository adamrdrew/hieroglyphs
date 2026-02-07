import SwiftUI
import CodeEditorView
import LanguageSupport
import MarkdownUI

/// Edits card markdown body using click-to-edit pattern from TakeNote.
///
/// ZStack with two modes:
/// - Preview mode: Rendered Markdown view (tap to enter edit mode)
/// - Edit mode: CodeEditor with syntax highlighting (Escape to return to preview)
struct CardBodyEditor: View {
    @Binding var content: String
    let onUpdate: () -> Void

    @State private var showPreview = true
    @State private var position = CodeEditor.Position()
    @State private var messages: Set<TextLocated<Message>> = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if showPreview {
                    previewMode
                } else {
                    editMode
                }
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
    }

    private var previewMode: some View {
        ScrollView {
            Markdown(content)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentMargins(.vertical, 8)
        .onTapGesture {
            showPreview = false
        }
    }

    private var editMode: some View {
        CodeEditor(
            text: contentBinding,
            position: $position,
            messages: $messages,
            language: .markdown()
        )
        .environment(
            \.codeEditorLayoutConfiguration,
            CodeEditor.LayoutConfiguration(
                showMinimap: false,
                wrapText: true
            )
        )
        .onExitCommand {
            showPreview = true
        }
    }

    private var contentBinding: Binding<String> {
        Binding(
            get: { content },
            set: { newValue in
                content = newValue
                onUpdate()
            }
        )
    }
}
