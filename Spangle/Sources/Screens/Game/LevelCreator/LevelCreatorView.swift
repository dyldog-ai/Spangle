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

struct LevelCreatorView: View {
    @ObservedObject var store: LevelCreatorStore
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    let initialLevelID: UUID?
    @Environment(\.dismiss) private var dismiss
    @State private var draft = CustomLevelDefinition.empty
    @State private var selectedID: UUID?
    @State private var selectedIDs = Set<UUID>()
    @State private var isRectangleSelecting = false
    @State private var selectionStart: CGPoint?
    @State private var selectionCurrent: CGPoint?
    @State private var confirmsDeleteSelection = false
    @State private var previewLevel: CustomLevelDefinition?
    @State private var savedDefinition: CustomLevelDefinition?
    @State private var showsVocabularyEditor = false
    @State private var vocabularyDraft = ""
    @State private var vocabularyError: String?
    @State private var vocabularyMode = VocabularyEditorMode.manual
    @State private var generationPrompt = ""
    @State private var dragOrigins: [UUID: LevelObjectPosition] = [:]
    @State private var loadedInitialLevel = false
    @State private var showsTools = true

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
                            HStack(alignment: .top, spacing: 10) {
                                timeline
                                if showsTools {
                                    toolsSidebar
                                }
                            }
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
        #if os(iOS)
        .fullScreenCover(item: $previewLevel) { level in
            GameView(previewLevel: level) { previewLevel = nil }
        }
        #else
        .sheet(item: $previewLevel) { level in
            GameView(previewLevel: level) { previewLevel = nil }
        }
        #endif
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
                ScrollView(.horizontal) {
                    levelControls
                        .padding(.horizontal, 2)
                }
                .scrollIndicators(.hidden)
                editorStatus
            }
            .fixedSize()

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.18)) { showsTools.toggle() }
            } label: {
                actionLabel(showsTools ? "Hide Tools" : "Show Tools", systemImage: "sidebar.right")
            }
            .buttonStyle(StorybookSecondaryButtonStyle())
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

    private var levelControls: some View {
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
    }

    private var toolsSidebar: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: openVocabularyEditor) {
                Label("Words", systemImage: "text.book.closed.fill")
            }
            Button(action: toggleRectangleSelection) {
                Label(isRectangleSelecting ? "Drag a box" : "Select", systemImage: "rectangle.dashed")
            }
            if !selectedIDs.isEmpty {
                Button(role: .destructive) { confirmsDeleteSelection = true } label: {
                    Label("Delete \(selectedIDs.count)", systemImage: "trash.fill")
                }
            }
        }
        .font(.caption.bold())
        .buttonStyle(StorybookSecondaryButtonStyle())
        .foregroundStyle(Color.storybookInk)
        .padding(10)
        .frame(width: isCompactEditor ? 125 : 165, alignment: .topLeading)
        .background(Color.storybookPaper, in: RoundedRectangle(cornerRadius: 16))
    }

    private func openVocabularyEditor() {
        vocabularyMode = draft.usesGeneratedVocabulary ? .generated : .manual
        vocabularyDraft = draft.vocabularyText
        generationPrompt = draft.vocabularyPrompt ?? ""
        vocabularyError = nil
        showsVocabularyEditor = true
    }

    private func toggleRectangleSelection() {
        if isRectangleSelecting {
            isRectangleSelecting = false
            selectionStart = nil
            selectionCurrent = nil
        } else {
            clearSelection()
            isRectangleSelecting = true
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
        let size = objectDisplaySize(value)
        return ZStack {
            RoundedRectangle(cornerRadius: min(7, size.height / 3))
                .fill(objectColor(value.kind).opacity(value.kind == .gap ? 0.16 : 0.72))
            Image(systemName: value.kind.symbol)
                .font(.system(size: max(7, min(18, min(size.width, size.height) * 0.55)), weight: .bold))
                .foregroundStyle(value.kind == .gap ? objectColor(value.kind) : .white)
            if size.width > 72 {
                Text(value.kind.title)
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
        }
        .frame(width: size.width, height: size.height)
        .overlay {
            RoundedRectangle(cornerRadius: min(7, size.height / 3))
                .stroke(
                    isSelected ? Color.storybookRed : Color.storybookInk.opacity(0.45),
                    style: StrokeStyle(
                        lineWidth: isSelected ? 3 : 1,
                        dash: value.kind == .gap ? [4, 3] : []
                    )
                )
        }
        .frame(width: max(30, size.width), height: max(30, size.height))
        .contentShape(Rectangle())
        .position(x: timelineX(for: value), y: timelineY(for: value))
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
        previewLevel = draft
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
        let size = objectDisplaySize(object)
        return CGRect(
            x: timelineX(for: object) - size.width / 2,
            y: timelineY(for: object) - size.height / 2,
            width: size.width,
            height: size.height
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
        let object = draft.addObject(kind: kind, after: selectedIDs)
        selectedIDs = [object.id]
        selectedID = object.id
    }

    private var timelineWidth: CGFloat {
        max(900, CGFloat(draft.finishX) * horizontalScale + 80)
    }

    private func timelineX(for object: EditableLevelObject) -> CGFloat {
        let worldX = object.kind == .wind ? object.x + object.width / 2 : object.x
        return CGFloat(worldX) * horizontalScale
    }

    private func timelineY(for object: EditableLevelObject) -> CGFloat {
        let groundSurfaceY = timelineHeight - 38
        let size = objectDisplaySize(object)
        switch object.kind {
        case .gap:
            return groundSurfaceY
        case .spike, .gate, .spring, .trickster, .hopper, .checkpoint, .wind:
            return groundSurfaceY - size.height / 2
        case .coin, .star, .flyer, .solidPlatform, .crumblingPlatform, .shield:
            return groundSurfaceY - CGFloat(max(0, object.y)) * verticalScale
        }
    }

    private func objectDisplaySize(_ object: EditableLevelObject) -> CGSize {
        let worldSize: CGSize
        switch object.kind {
        case .coin: worldSize = CGSize(width: 46, height: 46)
        case .spike: worldSize = CGSize(width: 66, height: 54)
        case .gate: worldSize = CGSize(width: 100, height: 226)
        case .spring: worldSize = CGSize(width: 82, height: 28)
        case .star: worldSize = CGSize(width: 54, height: 54)
        case .trickster, .hopper: worldSize = CGSize(width: 62, height: 55)
        case .flyer: worldSize = CGSize(width: 92, height: 55)
        case .solidPlatform, .crumblingPlatform:
            worldSize = CGSize(width: max(100, object.width), height: 25)
        case .wind: worldSize = CGSize(width: max(120, object.width), height: 180)
        case .shield: worldSize = CGSize(width: 62, height: 62)
        case .checkpoint: worldSize = CGSize(width: 90, height: 180)
        case .gap: worldSize = CGSize(width: max(80, object.width), height: 18)
        }
        return CGSize(
            width: max(7, worldSize.width * horizontalScale),
            height: max(7, worldSize.height * verticalScale)
        )
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
