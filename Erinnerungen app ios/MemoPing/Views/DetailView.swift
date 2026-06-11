import SwiftData
import SwiftUI

struct DetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @Bindable var item: MemoItem

    @State private var isEditing = false
    @State private var errorMessage: String?

    private let imageStorage = ImageStorageService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                titleSection
                organizationSection
                reminderSection
                textSection
                imagesSection
                detectedSection
                actionSection
            }
            .padding()
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Sichern" : "Bearbeiten") {
                    isEditing ? saveChanges() : (isEditing = true)
                }
            }
        }
        .alert("Hinweis", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if isEditing {
                TextField("Titel", text: $item.title)
                    .font(.title2.weight(.semibold))
                    .textFieldStyle(.roundedBorder)
            } else {
                Text(item.title)
                    .font(.title2.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Label(item.sourceType.displayName, systemImage: "square.and.pencil")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var organizationSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 14) {
                if isEditing {
                    CategoryPickerView(selection: categoryBinding)
                    PriorityPickerView(selection: priorityBinding)
                } else {
                    HStack {
                        if let category = item.category {
                            Label(category.displayName, systemImage: category.systemImage)
                                .foregroundStyle(category.tint)
                        } else {
                            Label("Keine Kategorie", systemImage: "tray")
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Label(item.priority.displayName, systemImage: item.priority.systemImage)
                            .foregroundStyle(item.priority.tint)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var reminderSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Erledigt", isOn: completedBinding)

                if isEditing {
                    Toggle("Erinnerung", isOn: reminderEnabledBinding)

                    if item.hasReminder {
                        DatePicker(
                            "Termin",
                            selection: reminderDateBinding,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                } else if item.hasReminder, let reminderDate = item.reminderDate {
                    Label(reminderDate.formatted(date: .abbreviated, time: .shortened), systemImage: "bell")
                        .foregroundStyle(.secondary)
                } else {
                    Label("Keine Erinnerung", systemImage: "bell.slash")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var textSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            editableTextBlock(title: "Notiztext", text: $item.bodyText)

            if isEditing || !item.recognizedText.trimmed.isEmpty {
                editableTextBlock(title: "Erkannter Bildtext", text: $item.recognizedText)
            }
        }
    }

    @ViewBuilder
    private var imagesSection: some View {
        if !item.imageFileNames.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Bilder")
                    .font(.headline)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                    ForEach(item.imageFileNames, id: \.self) { fileName in
                        if let image = imageStorage.load(fileName: fileName) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
        }
    }

    private var detectedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !item.detectedPhoneNumbers.isEmpty {
                detectedValues(title: "Telefonnummern", systemImage: "phone", values: item.detectedPhoneNumbers) { value in
                    openPhone(value)
                }
            }

            if !item.detectedURLs.isEmpty {
                detectedValues(title: "Links", systemImage: "link", values: item.detectedURLs) { value in
                    if let url = URL(string: value) {
                        openURL(url)
                    }
                }
            }

            if !item.detectedAddresses.isEmpty {
                detectedValues(title: "Adressen", systemImage: "mappin.and.ellipse", values: item.detectedAddresses, action: nil)
            }

            if !item.detectedDateStrings.isEmpty {
                detectedValues(title: "Erkannte Termine", systemImage: "calendar", values: item.detectedDateStrings, action: nil)
            }
        }
    }

    private var actionSection: some View {
        VStack(spacing: 12) {
            Button {
                toggleCompleted()
            } label: {
                Label(item.isCompleted ? "Als offen markieren" : "Als erledigt markieren", systemImage: item.isCompleted ? "circle" : "checkmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button(role: .destructive) {
                deleteMemo()
            } label: {
                Label("Löschen", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private var categoryBinding: Binding<MemoCategory?> {
        Binding(
            get: { item.category },
            set: {
                item.category = $0
                item.updatedAt = Date()
            }
        )
    }

    private var priorityBinding: Binding<MemoPriority> {
        Binding(
            get: { item.priority },
            set: {
                item.priority = $0
                item.updatedAt = Date()
            }
        )
    }

    private var reminderEnabledBinding: Binding<Bool> {
        Binding(
            get: { item.hasReminder },
            set: { isEnabled in
                item.hasReminder = isEnabled
                item.updatedAt = Date()

                if isEnabled, item.reminderDate == nil {
                    item.reminderDate = Date().addingTimeInterval(3_600)
                }
            }
        )
    }

    private var reminderDateBinding: Binding<Date> {
        Binding(
            get: { item.reminderDate ?? Date().addingTimeInterval(3_600) },
            set: {
                item.reminderDate = $0
                item.hasReminder = true
                item.updatedAt = Date()
            }
        )
    }

    private var completedBinding: Binding<Bool> {
        Binding(
            get: { item.isCompleted },
            set: { newValue in
                item.isCompleted = newValue
                item.updatedAt = Date()
                handleCompletionNotification()
            }
        )
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func editableTextBlock(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            if isEditing {
                TextEditor(text: text)
                    .frame(minHeight: 110)
                    .padding(8)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
            } else if !text.wrappedValue.trimmed.isEmpty {
                Text(text.wrappedValue)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            } else {
                Text("Kein Text")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func detectedValues(
        title: String,
        systemImage: String,
        values: [String],
        action: ((String) -> Void)?
    ) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: systemImage)
                    .font(.headline)

                ForEach(values, id: \.self) { value in
                    if let action {
                        Button {
                            action(value)
                        } label: {
                            Text(value)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        Text(value)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private func saveChanges() {
        item.updatedAt = Date()

        Task { @MainActor in
            do {
                let notificationService = NotificationService()

                if item.isCompleted || !item.hasReminder {
                    notificationService.removeNotification(for: item)
                } else {
                    try await notificationService.scheduleNotification(for: item)
                }

                try modelContext.save()
                isEditing = false
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func toggleCompleted() {
        completedBinding.wrappedValue = !item.isCompleted

        do {
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handleCompletionNotification() {
        Task { @MainActor in
            let notificationService = NotificationService()

            if item.isCompleted {
                notificationService.removeNotification(for: item)
            } else if item.hasReminder {
                do {
                    try await notificationService.scheduleNotification(for: item)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func deleteMemo() {
        Task { @MainActor in
            let notificationService = NotificationService()
            notificationService.removeNotification(for: item)
            imageStorage.delete(fileNames: item.imageFileNames)
            modelContext.delete(item)

            do {
                try modelContext.save()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func openPhone(_ phoneNumber: String) {
        let digits = phoneNumber.filter { $0.isNumber || $0 == "+" }
        if let url = URL(string: "tel://\(digits)") {
            openURL(url)
        }
    }
}
