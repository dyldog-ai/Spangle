#if DEVELOPER_FEATURES
import SwiftUI

private struct LevelObjectPosition {
    let x: Double
    let y: Double
}

struct LevelCreatorView: View {
    @ObservedObject var store: LevelCreatorStore
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    let initialLevelID: UUID?
    let onPlay: (CustomLevelDefinition) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var draft = CustomLevelDefinition.starter
    @State private var selectedID: UUID?
    @State private var savedDefinition: CustomLevelDefinition?
    @State private var showsVocabularyEditor = false
    @State private var vocabularyDraft = ""
    @State private var vocabularyError: String?
    @State private var dragOrigins: [UUID: LevelObjectPosition] = [:]
    @State private var loadedInitialLevel = false
    @State private var levelPendingDeletion: CustomLevelDefinition?

    private let horizontalScale: CGFloat = 0.16
    private var isCompactEditor: Bool { verticalSizeClass == .compact }
    private var verticalScale: CGFloat { isCompactEditor ? 0.38 : 0.52 }
    private var timelineHeight: CGFloat { isCompactEditor ? 150 : 190 }

    var body: some View {
        NavigationStack {
            ZStack {
                StorybookBackdrop()
                VStack(spacing: 10) {
                    creatorActionBar
                    ScrollView(.vertical) {
                        VStack(spacing: 10) {
                            metadataBar
                            timeline
                            inspector
                            objectPalette
                        }
                    }
                    .scrollIndicators(.visible)
                }
                .padding(14)
            }
            .navigationTitle("Level Creator")
            .toolbar { creatorToolbar }
        }
        #if os(macOS)
        .frame(minWidth: 900, minHeight: 560)
        #endif
        .sheet(isPresented: $showsVocabularyEditor) {
            vocabularyEditor
        }
        .confirmationDialog(
            "Delete \(levelPendingDeletion?.title ?? "this level")?",
            isPresented: deletionConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete level", role: .destructive, action: deletePendingLevel)
            Button("Cancel", role: .cancel) { levelPendingDeletion = nil }
        } message: {
            Text("This cannot be undone.")
        }
        .onAppear(perform: loadInitialLevelIfNeeded)
    }

    private var creatorActionBar: some View {
        HStack(spacing: isCompactEditor ? 7 : 10) {
            Menu {
                if store.levels.isEmpty {
                    Text("No saved levels")
                }
                ForEach(store.levels) { level in
                    Menu("\(level.emoji) \(level.title)") {
                        Button("Open", systemImage: "pencil") {
                            draft = level
                            savedDefinition = level
                            selectedID = nil
                        }
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            levelPendingDeletion = level
                        }
                    }
                }
            } label: {
                actionLabel("Saved Levels", systemImage: "folder.fill")
            }
            Button {
                draft = .starter
                draft.id = UUID()
                savedDefinition = nil
                selectedID = nil
            } label: {
                actionLabel("New", systemImage: "doc.badge.plus")
            }
            Button {
                vocabularyDraft = draft.vocabularyText
                vocabularyError = nil
                showsVocabularyEditor = true
            } label: {
                actionLabel("Words", systemImage: "text.book.closed.fill")
            }
            Spacer(minLength: isCompactEditor ? 0 : 8)
            if savedDefinition == draft {
                Label(isCompactEditor ? "" : "Saved", systemImage: "checkmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(Color.storybookGreen)
                    .transition(.opacity)
            }
            Button(action: saveDraft) {
                actionLabel("Save", systemImage: "square.and.arrow.down.fill")
            }
            .buttonStyle(StorybookSecondaryButtonStyle())
            Button(action: playDraft) {
                actionLabel("Play", systemImage: "play.fill")
            }
            .buttonStyle(StorybookPrimaryButtonStyle())
            .disabled(draft.validationMessage != nil)
        }
        .foregroundStyle(Color.storybookInk)
        .padding(10)
        .background(Color.storybookPaper, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .contain)
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
        guard let words = CustomLevelDefinition.parseVocabulary(vocabularyDraft) else {
            vocabularyError = "Use “Spanish = English” on every non-empty line."
            return
        }
        draft.replaceVocabulary(with: words)
        selectedID = nil
        vocabularyError = nil
        showsVocabularyEditor = false
    }

    private var metadataBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                TextField("Emoji", text: $draft.emoji)
                    .frame(width: 54)
                TextField("Level title", text: $draft.title)
                    .frame(minWidth: 150)
                LabeledContent("Finish") {
                    TextField("Finish", value: $draft.finishX, format: .number)
                        .frame(width: 78)
                }
                Stepper("Difficulty \(draft.difficultyIndex + 1)",
                        value: $draft.difficultyIndex, in: 0...11)
                Spacer()
                if let message = draft.validationMessage {
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.storybookRed)
                        .lineLimit(2)
                } else {
                    Label("Ready to play", systemImage: "checkmark.circle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(Color.storybookGreen)
                }
            }
            .frame(minWidth: isCompactEditor ? 760 : 0)
        }
        .scrollIndicators(.visible)
        .textFieldStyle(.roundedBorder)
        .padding(10)
        .background(Color.storybookPaper, in: RoundedRectangle(cornerRadius: 16))
        .foregroundStyle(Color.storybookInk)
    }

    private var timeline: some View {
        ScrollView(.horizontal) {
            ZStack(alignment: .topLeading) {
                timelineBackground
                finishMarker
                ForEach($draft.objects) { $object in
                    timelineObject($object)
                }
            }
            .frame(width: timelineWidth, height: timelineHeight)
        }
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
        return VStack(spacing: 1) {
            Image(systemName: value.kind.symbol)
                .font(.system(size: selectedID == value.id ? 20 : 17, weight: .bold))
            Text(value.kind.title)
                .font(.system(size: 7, weight: .bold))
                .lineLimit(1)
        }
        .foregroundStyle(objectColor(value.kind))
        .frame(width: objectDisplayWidth(value), height: 35)
        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(selectedID == value.id ? Color.storybookRed : Color.storybookInk.opacity(0.3),
                        lineWidth: selectedID == value.id ? 3 : 1)
        }
        .position(x: CGFloat(value.x) * horizontalScale, y: timelineY(for: value))
        .onTapGesture { selectedID = value.id }
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    moveObject(object, from: value, by: gesture.translation)
                }
                .onEnded { gesture in
                    moveObject(object, from: value, by: gesture.translation)
                    dragOrigins[value.id] = nil
                }
        )
        .accessibilityLabel("\(value.kind.title) at \(Int(value.x))")
    }

    @ViewBuilder private var inspector: some View {
        if let index = draft.objects.firstIndex(where: { $0.id == selectedID }) {
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
                    selectedID = nil
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
            Button("Save & Close") {
                saveDraft()
                dismiss()
            }
        }
    }

    private var deletionConfirmation: Binding<Bool> {
        Binding(
            get: { levelPendingDeletion != nil },
            set: { if !$0 { levelPendingDeletion = nil } }
        )
    }

    private func deletePendingLevel() {
        guard let level = levelPendingDeletion else { return }
        store.delete(level)
        if draft.id == level.id {
            draft = .starter
            draft.id = UUID()
            savedDefinition = nil
            selectedID = nil
        }
        levelPendingDeletion = nil
    }

    private func loadInitialLevelIfNeeded() {
        guard !loadedInitialLevel else { return }
        loadedInitialLevel = true
        guard let initialLevelID,
              let level = store.levels.first(where: { $0.id == initialLevelID }) else { return }
        draft = level
        savedDefinition = level
        selectedID = nil
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

    private func moveObject(
        _ object: Binding<EditableLevelObject>,
        from value: EditableLevelObject,
        by translation: CGSize
    ) {
        let origin = dragOrigins[value.id] ?? LevelObjectPosition(x: value.x, y: value.y)
        if dragOrigins[value.id] == nil { dragOrigins[value.id] = origin }
        object.wrappedValue.x = min(
            draft.finishX - 100,
            max(500, origin.x + Double(translation.width / horizontalScale))
        )
        if supportsVerticalPosition(value.kind) {
            object.wrappedValue.y = min(
                340,
                max(0, origin.y - Double(translation.height / verticalScale))
            )
        }
        selectedID = value.id
    }

    private func add(_ kind: EditableLevelObject.Kind) {
        let furthest = draft.objects.map(\.x).max() ?? 500
        let x = min(draft.finishX - 120, max(600, furthest + 220))
        let object = EditableLevelObject.make(kind: kind, x: x)
        draft.objects.append(object)
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
