#if DEVELOPER_FEATURES
import SwiftUI

private struct LevelObjectPosition {
    let x: Double
    let y: Double
}

private enum VocabularyEditorMode: String, CaseIterable, Identifiable {
    case manual = "Manual List"
    case generated = "Generated"

    var id: Self { self }
}

private enum LevelEditorSection: String, CaseIterable, Identifiable {
    case level = "Level"
    case tools = "Tools"

    var id: Self { self }
}

struct LevelCreatorView: View {
    @ObservedObject var store: LevelCreatorStore
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    let initialLevelID: UUID?
    let onPlay: (CustomLevelDefinition) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var draft = CustomLevelDefinition.empty
    @State private var selectedID: UUID?
    @State private var selectedIDs = Set<UUID>()
    @State private var isRectangleSelecting = false
    @State private var selectionStart: CGPoint?
    @State private var selectionCurrent: CGPoint?
    @State private var confirmsDeleteSelection = false
    @State private var savedDefinition: CustomLevelDefinition?
    @State private var showsVocabularyEditor = false
    @State private var vocabularyDraft = ""
    @State private var vocabularyError: String?
    @State private var vocabularyMode = VocabularyEditorMode.manual
    @State private var generationPrompt = ""
    @State private var dragOrigins: [UUID: LevelObjectPosition] = [:]
    @State private var loadedInitialLevel = false
    @State private var editorSection = LevelEditorSection.level

    private let levelEmojis = ["🛠️", "🌟", "🏰", "🌳", "🌊", "🏜️", "❄️", "🌋", "🌙", "🎨", "🎵", "⚽️", "🐾", "🚀", "🗺️", "📚"]
    private let horizontalScale: CGFloat = 0.16
    private var availableLevelEmojis: [String] {
        levelEmojis.contains(draft.emoji) || draft.emoji.isEmpty ? levelEmojis : [draft.emoji] + levelEmojis
    }
    private var isCompactEditor: Bool { verticalSizeClass == .compact }
    private var verticalScale: CGFloat { isCompactEditor ? 0.38 : 0.52 }
    private var timelineHeight: CGFloat { isCompactEditor ? 150 : 190 }

    var body: some View {
        NavigationStack {
            ZStack {
                StorybookBackdrop()
                VStack(spacing: 10) {
                    creatorTopBar
                    ScrollView(.vertical) {
                        VStack(spacing: 10) {
                            timeline
                            inspector
                            objectPalette
                        }
                        #if os(iOS)
                        .padding(.bottom, 28)
                        #endif
                    }
                    .scrollIndicators(.visible)
                }
                #if os(iOS)
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .ignoresSafeArea(.container, edges: .bottom)
                #else
                .padding(14)
                #endif
            }
            .navigationTitle("Level Creator")
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #else
            .toolbar { creatorToolbar }
            #endif
        }
        #if os(macOS)
        .frame(minWidth: 900, minHeight: 560)
        #endif
        .sheet(isPresented: $showsVocabularyEditor) {
            vocabularyEditor
        }
        .confirmationDialog(
            "Delete \(selectedIDs.count) selected objects?",
            isPresented: $confirmsDeleteSelection,
            titleVisibility: .visible
        ) {
            Button("Delete objects", role: .destructive, action: deleteSelectedObjects)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
        .onAppear(perform: loadInitialLevelIfNeeded)
    }

    private var creatorTopBar: some View {
        HStack(spacing: isCompactEditor ? 7 : 10) {
            VStack(alignment: .leading) {
                HStack {
                    Picker("Editor section", selection: $editorSection) {
                        ForEach(LevelEditorSection.allCases) { section in
                            Text(section.rawValue).tag(section)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()

                    ScrollView(.horizontal) {
                        sectionControls
                            .padding(.horizontal, 2)
                    }
                    .scrollIndicators(.hidden)
                    .frame(maxWidth: .infinity)
                }

                editorStatus
            }
            .fixedSize()

            Spacer()

            Button(action: saveDraft) {
                actionLabel("Save", systemImage: "square.and.arrow.down.fill")
            }
            .buttonStyle(StorybookSecondaryButtonStyle())
            Button(action: playDraft) {
                actionLabel("Play", systemImage: "play.fill")
            }
            .buttonStyle(StorybookPrimaryButtonStyle())
            .disabled(draft.validationMessage != nil)
            #if os(iOS)
            Button(action: saveAndClose) {
                actionLabel("Save & Close", systemImage: "xmark.circle.fill")
            }
            .buttonStyle(StorybookSecondaryButtonStyle())
            #endif
        }
        .textFieldStyle(.roundedBorder)
        .foregroundStyle(Color.storybookInk)
        .padding(10)
        .background(Color.storybookPaper, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder private var sectionControls: some View {
        switch editorSection {
        case .level:
            HStack(spacing: 8) {
                Picker("Level emoji", selection: $draft.emoji) {
                    ForEach(availableLevelEmojis, id: \.self) { emoji in
                        Text(emoji).tag(emoji)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityValue(draft.emoji)
                .labelsHidden()
                TextField("Level title", text: $draft.title).frame(width: 150)
                LabeledContent("Length") {
                    TextField("Length", value: $draft.finishX, format: .number).frame(width: 72)
                }
                .fixedSize()
                Stepper("Difficulty \(draft.difficultyIndex + 1)",
                        value: $draft.difficultyIndex, in: 0...11)
                    .fixedSize()
            }
        case .tools:
            HStack(spacing: 8) {
                Button {
                    draft = .empty
                    draft.id = UUID()
                    savedDefinition = nil
                    clearSelection()
                } label: {
                    Label("New", systemImage: "doc.badge.plus")
                }
                Button {
                    vocabularyMode = draft.usesGeneratedVocabulary ? .generated : .manual
                    vocabularyDraft = draft.vocabularyText
                    generationPrompt = draft.vocabularyPrompt ?? ""
                    vocabularyError = nil
                    showsVocabularyEditor = true
                } label: {
                    Label("Words", systemImage: "text.book.closed.fill")
                }
                Button {
                    if isRectangleSelecting {
                        isRectangleSelecting = false
                        selectionStart = nil
                        selectionCurrent = nil
                    } else {
                        clearSelection()
                        isRectangleSelecting = true
                    }
                } label: {
                    Label(isRectangleSelecting ? "Drag a box" : "Select", systemImage: "rectangle.dashed")
                }
                if !selectedIDs.isEmpty {
                    Button(role: .destructive) { confirmsDeleteSelection = true } label: {
                        Label("Delete \(selectedIDs.count)", systemImage: "trash.fill")
                    }
                }
                Text("\(draft.vocabularyCount) words · \(draft.objects.count) objects")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private var editorStatus: some View {
        if let message = draft.validationMessage {
            Label(isCompactEditor ? "" : message, systemImage: "exclamationmark.triangle.fill")
                .font(.caption.bold())
                .foregroundStyle(Color.storybookRed)
                .accessibilityLabel(message)
        } else if savedDefinition == draft {
            Label(isCompactEditor ? "" : "Saved", systemImage: "checkmark.circle.fill")
                .font(.caption.bold())
                .foregroundStyle(Color.storybookGreen)
        } else {
            Label(isCompactEditor ? "" : "Unsaved", systemImage: "pencil.circle.fill")
                .font(.caption.bold())
                .foregroundStyle(Color.storybookBlue)
        }
    }

    @ViewBuilder
    private func actionLabel(_ title: String, systemImage: String) -> some View {
        if isCompactEditor {
            Image(systemName: systemImage)
                .accessibilityLabel(title)
        } else {
            Label(title, systemImage: systemImage)
        }
    }

    private var vocabularyEditor: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Vocabulary source", selection: $vocabularyMode) {
                    ForEach(VocabularyEditorMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if vocabularyMode == .generated {
                    GroupBox("Dynamic vocabulary") {
                        VStack(alignment: .leading, spacing: 10) {
                            TextField("Prompt, e.g. animals on a farm", text: $generationPrompt)
                                .textFieldStyle(.roundedBorder)
                            Label(
                                "\(draft.objects.count(where: { $0.kind == .coin })) word coins will produce the same number of fresh words each run.",
                                systemImage: "book.pages.fill"
                            )
                            .font(.subheadline.weight(.semibold))
                            Label(
                                "Apple Intelligence creates a fresh Spanish–English list whenever this level is played.",
                                systemImage: "sparkles"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                } else {
                    Text("Enter one Spanish and English pair per line, separated by an equals sign.")
                        .font(.subheadline)
                    Text("hola = hello\nsalta = jump")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                    TextEditor(text: $vocabularyDraft)
                        .font(.body.monospaced())
                        .padding(6)
                        .background(Color.storybookPaper, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.storybookInk.opacity(0.3)))
                }
                if let vocabularyError {
                    Label(vocabularyError, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(Color.storybookRed)
                }
            }
            .padding()
            .navigationTitle("Level Vocabulary")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showsVocabularyEditor = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") { applyVocabulary() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 420)
        #endif
    }

    private func applyVocabulary() {
        if vocabularyMode == .generated {
            let prompt = generationPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !prompt.isEmpty else {
                vocabularyError = "Add a prompt for dynamic vocabulary generation."
                return
            }
            draft.configureGeneratedVocabulary(prompt: prompt)
        } else {
            guard let words = CustomLevelDefinition.parseVocabulary(vocabularyDraft) else {
                vocabularyError = "Use “Spanish = English” on every non-empty line."
                return
            }
            draft.replaceVocabulary(with: words)
        }
        clearSelection()
        vocabularyError = nil
        showsVocabularyEditor = false
    }

    private var timeline: some View {
        ScrollView(.horizontal) {
            ZStack(alignment: .topLeading) {
                timelineBackground
                finishMarker
                ForEach($draft.objects) { $object in
                    timelineObject($object)
                }
                if let rectangle = selectionRectangle {
                    Rectangle()
                        .fill(Color.storybookBlue.opacity(0.18))
                        .overlay(Rectangle().stroke(
                            Color.storybookBlue,
                            style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                        ))
                        .frame(width: rectangle.width, height: rectangle.height)
                        .position(x: rectangle.midX, y: rectangle.midY)
                        .allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle())
            .frame(width: timelineWidth, height: timelineHeight)
            .simultaneousGesture(
                DragGesture(minimumDistance: 4)
                    .onChanged(updateRectangleSelection)
                    .onEnded(finishRectangleSelection),
                including: isRectangleSelecting ? .all : .none
            )
        }
        .scrollDisabled(isRectangleSelecting)
        .scrollIndicators(.visible)
        .background(Color.storybookPaper.opacity(0.9), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.storybookInk.opacity(0.45), lineWidth: 2))
    }

    private var timelineBackground: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [Color.storybookBlue.opacity(0.55), Color.storybookCream.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            Path { path in
                let groundY = timelineHeight - 32
                path.move(to: CGPoint(x: 0, y: groundY))
                path.addLine(to: CGPoint(x: timelineWidth, y: groundY))
            }
            .stroke(Color.storybookGreen, lineWidth: 12)
            ForEach(0...Int(draft.finishX / 500), id: \.self) { marker in
                let x = CGFloat(marker * 500) * horizontalScale
                VStack(spacing: 1) {
                    Text("\(marker * 5)m").font(.caption2.monospacedDigit())
                    Rectangle().frame(width: 1, height: timelineHeight - 22)
                }
                .foregroundStyle(Color.storybookInk.opacity(0.2))
                .position(x: x, y: timelineHeight / 2)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var finishMarker: some View {
        Label("FINISH", systemImage: "flag.checkered")
            .font(.caption2.weight(.black))
            .foregroundStyle(Color.storybookRed)
            .rotationEffect(.degrees(-90))
            .position(x: CGFloat(draft.finishX) * horizontalScale, y: timelineHeight / 2)
    }

    private func timelineObject(_ object: Binding<EditableLevelObject>) -> some View {
        let value = object.wrappedValue
        let isSelected = selectedIDs.contains(value.id)
        return VStack(spacing: 1) {
            Image(systemName: value.kind.symbol)
                .font(.system(size: isSelected ? 20 : 17, weight: .bold))
            Text(value.kind.title)
                .font(.system(size: 7, weight: .bold))
                .lineLimit(1)
        }
        .foregroundStyle(objectColor(value.kind))
        .frame(width: objectDisplayWidth(value), height: 35)
        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(isSelected ? Color.storybookRed : Color.storybookInk.opacity(0.3),
                        lineWidth: isSelected ? 3 : 1)
        }
        .position(x: CGFloat(value.x) * horizontalScale, y: timelineY(for: value))
        .onTapGesture { selectObject(value.id) }
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    guard !isRectangleSelecting else { return }
                    moveObject(from: value, by: gesture.translation)
                }
                .onEnded { gesture in
                    guard !isRectangleSelecting else { return }
                    moveObject(from: value, by: gesture.translation)
                    clearDragOrigins(for: value.id)
                }
        )
        .accessibilityLabel("\(value.kind.title) at \(Int(value.x))")
    }

    @ViewBuilder private var inspector: some View {
        if selectedIDs.count > 1 {
            HStack(spacing: 12) {
                Label("\(selectedIDs.count) objects selected", systemImage: "rectangle.3.group.fill")
                    .font(.headline)
                Text("Drag any selected object to move the group.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Delete selected", systemImage: "trash.fill", role: .destructive) {
                    confirmsDeleteSelection = true
                }
            }
            .foregroundStyle(Color.storybookInk)
            .padding(12)
            .background(Color.storybookPaper, in: RoundedRectangle(cornerRadius: 14))
        } else if let index = draft.objects.firstIndex(where: { $0.id == selectedID }) {
            selectedInspector(object: $draft.objects[index])
        } else {
            HStack {
                Image(systemName: "hand.draw.fill")
                Text("Select an object to edit it, or drag it directly on the timeline.")
                Spacer()
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.storybookInk)
            .padding(12)
            .background(Color.storybookPaper, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func selectedInspector(object: Binding<EditableLevelObject>) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                Picker("Type", selection: object.kind) {
                    ForEach(EditableLevelObject.Kind.allCases) { kind in
                        Label(kind.title, systemImage: kind.symbol).tag(kind)
                    }
                }
                .frame(maxWidth: 210)
                LabeledContent("X") {
                    TextField("X", value: object.x, format: .number).frame(width: 66)
                }
                if supportsVerticalPosition(object.wrappedValue.kind) {
                    LabeledContent("Y") {
                        TextField("Y", value: object.y, format: .number).frame(width: 58)
                    }
                }
                if supportsWidth(object.wrappedValue.kind) {
                    LabeledContent("Width") {
                        TextField("Width", value: object.width, format: .number).frame(width: 66)
                    }
                }
                if object.wrappedValue.kind == .coin {
                    TextField("Spanish", text: object.spanish).frame(minWidth: 90)
                    Image(systemName: "arrow.right")
                    TextField("English", text: object.english).frame(minWidth: 90)
                }
                Spacer()
                Button(role: .destructive) {
                    draft.objects.removeAll { $0.id == object.wrappedValue.id }
                    clearSelection()
                } label: {
                    Image(systemName: "trash.fill")
                }
            }
            .frame(minWidth: object.wrappedValue.kind == .coin ? 720 : 500)
        }
        .scrollIndicators(.visible)
        .textFieldStyle(.roundedBorder)
        .foregroundStyle(Color.storybookInk)
        .padding(10)
        .background(Color.storybookPaper, in: RoundedRectangle(cornerRadius: 14))
    }

    private var objectPalette: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 7) {
                ForEach(EditableLevelObject.Kind.allCases) { kind in
                    Button {
                        add(kind)
                    } label: {
                        Label(kind.title, systemImage: kind.symbol)
                            .font(.caption.weight(.bold))
                    }
                    .buttonStyle(StorybookSecondaryButtonStyle())
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ToolbarContentBuilder private var creatorToolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Save & Close", action: saveAndClose)
        }
    }

    private func saveAndClose() {
        saveDraft()
        dismiss()
    }

    private func loadInitialLevelIfNeeded() {
        guard !loadedInitialLevel else { return }
        loadedInitialLevel = true
        guard let initialLevelID,
              let level = store.levels.first(where: { $0.id == initialLevelID }) else { return }
        draft = level
        savedDefinition = level
        clearSelection()
    }

    private func saveDraft() {
        store.save(draft)
        withAnimation(.easeOut(duration: 0.18)) {
            savedDefinition = draft
        }
    }

    private func playDraft() {
        saveDraft()
        dismiss()
        onPlay(draft)
    }

    private var selectionRectangle: CGRect? {
        guard let selectionStart, let selectionCurrent else { return nil }
        return CGRect(
            x: selectionStart.x,
            y: selectionStart.y,
            width: selectionCurrent.x - selectionStart.x,
            height: selectionCurrent.y - selectionStart.y
        ).standardized
    }

    private func updateRectangleSelection(_ gesture: DragGesture.Value) {
        guard isRectangleSelecting else { return }
        selectionStart = gesture.startLocation
        selectionCurrent = gesture.location
    }

    private func finishRectangleSelection(_ gesture: DragGesture.Value) {
        guard isRectangleSelecting else { return }
        selectionCurrent = gesture.location
        let rectangle = selectionRectangle ?? .zero
        selectedIDs = Set(draft.objects.filter { object in
            rectangle.intersects(objectFrame(object))
        }.map(\.id))
        selectedID = selectedIDs.count == 1 ? selectedIDs.first : nil
        selectionStart = nil
        selectionCurrent = nil
        isRectangleSelecting = false
    }

    private func objectFrame(_ object: EditableLevelObject) -> CGRect {
        CGRect(
            x: CGFloat(object.x) * horizontalScale - objectDisplayWidth(object) / 2,
            y: timelineY(for: object) - 17.5,
            width: objectDisplayWidth(object),
            height: 35
        )
    }

    private func selectObject(_ id: UUID) {
        if isRectangleSelecting {
            if selectedIDs.contains(id) {
                selectedIDs.remove(id)
            } else {
                selectedIDs.insert(id)
            }
            selectedID = selectedIDs.count == 1 ? selectedIDs.first : nil
        } else if !selectedIDs.contains(id) || selectedIDs.count == 1 {
            selectedIDs = [id]
            selectedID = id
        }
    }

    private func moveObject(from value: EditableLevelObject, by translation: CGSize) {
        let movingIDs = selectedIDs.contains(value.id) ? selectedIDs : [value.id]
        if !selectedIDs.contains(value.id) {
            selectedIDs = [value.id]
            selectedID = value.id
        }
        for object in draft.objects where movingIDs.contains(object.id) && dragOrigins[object.id] == nil {
            dragOrigins[object.id] = LevelObjectPosition(x: object.x, y: object.y)
        }
        for index in draft.objects.indices where movingIDs.contains(draft.objects[index].id) {
            let object = draft.objects[index]
            guard let origin = dragOrigins[object.id] else { continue }
            draft.objects[index].x = min(
                draft.finishX - 100,
                max(500, origin.x + Double(translation.width / horizontalScale))
            )
            if supportsVerticalPosition(object.kind) {
                draft.objects[index].y = min(
                    340,
                    max(0, origin.y - Double(translation.height / verticalScale))
                )
            }
        }
    }

    private func clearDragOrigins(for id: UUID) {
        let movingIDs = selectedIDs.contains(id) ? selectedIDs : [id]
        for movingID in movingIDs { dragOrigins[movingID] = nil }
    }

    private func clearSelection() {
        selectedID = nil
        selectedIDs.removeAll()
        selectionStart = nil
        selectionCurrent = nil
        isRectangleSelecting = false
    }

    private func deleteSelectedObjects() {
        draft.objects.removeAll { selectedIDs.contains($0.id) }
        clearSelection()
    }

    private func add(_ kind: EditableLevelObject.Kind) {
        let furthest = draft.objects.map(\.x).max() ?? 500
        let x = min(draft.finishX - 120, max(600, furthest + 220))
        var object = EditableLevelObject.make(kind: kind, x: x)
        if kind == .coin, draft.usesGeneratedVocabulary {
            object.spanish = ""
            object.english = ""
        }
        draft.objects.append(object)
        selectedIDs = [object.id]
        selectedID = object.id
    }

    private var timelineWidth: CGFloat {
        max(900, CGFloat(draft.finishX) * horizontalScale + 80)
    }

    private func timelineY(for object: EditableLevelObject) -> CGFloat {
        let groundY = timelineHeight - 49
        if object.kind == .gap { return timelineHeight - 27 }
        return groundY - CGFloat(max(0, object.y)) * verticalScale
    }

    private func objectDisplayWidth(_ object: EditableLevelObject) -> CGFloat {
        if supportsWidth(object.kind) {
            return max(42, min(160, CGFloat(object.width) * horizontalScale))
        }
        return 58
    }

    private func supportsWidth(_ kind: EditableLevelObject.Kind) -> Bool {
        kind == .solidPlatform || kind == .crumblingPlatform || kind == .wind || kind == .gap
    }

    private func supportsVerticalPosition(_ kind: EditableLevelObject.Kind) -> Bool {
        switch kind {
        case .coin, .star, .flyer, .solidPlatform, .crumblingPlatform, .shield: true
        default: false
        }
    }

    private func objectColor(_ kind: EditableLevelObject.Kind) -> Color {
        switch kind {
        case .coin, .star: .storybookGold
        case .spike, .hopper: .storybookRed
        case .gate, .checkpoint: .storybookBlue
        case .solidPlatform, .crumblingPlatform, .gap: .storybookGreen
        case .wind, .shield, .flyer: .cyan
        default: .purple
        }
    }
}
#endif
