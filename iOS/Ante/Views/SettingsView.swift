import SwiftUI

private let orderedWeekdays: [Locale.Weekday] = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
private let weekdayLabels: [Locale.Weekday: String] = [
    .sunday: "S", .monday: "M", .tuesday: "T", .wednesday: "W",
    .thursday: "T", .friday: "F", .saturday: "S"
]

struct SettingsView: View {
    @Environment(AlarmEngine.self) private var alarmEngine
    @Environment(AppSettings.self) private var settings
    @Environment(AppleSignInService.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Wake time") {
                    DatePicker(
                        "Time",
                        selection: Binding(
                            get: { Calendar.current.date(from: DateComponents(hour: settings.wakeHour, minute: settings.wakeMinute)) ?? Date() },
                            set: { newValue in
                                let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                                settings.wakeHour = comps.hour ?? 7
                                settings.wakeMinute = comps.minute ?? 0
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    weekdayPicker
                }

                Section("Task") {
                    ForEach(TaskType.allCases) { task in
                        Button {
                            settings.taskType = task
                        } label: {
                            HStack {
                                Image(systemName: task.systemImageName)
                                Text(task.title)
                                Spacer()
                                if task == settings.taskType {
                                    Image(systemName: "checkmark").foregroundStyle(AnteTheme.gold)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }

                Section("Stakes") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Fine for skipping: \(Money.format(cents: settings.fineCents))")
                            .font(.subheadline)
                        MoneyPresetPicker(presets: MoneyPreset.fineCents, selectedCents: Binding(
                            get: { settings.fineCents }, set: { settings.fineCents = $0 }
                        ))
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Snooze cost: \(Money.format(cents: settings.snoozeCostCents))")
                            .font(.subheadline)
                        MoneyPresetPicker(presets: MoneyPreset.snoozeCostCents, selectedCents: Binding(
                            get: { settings.snoozeCostCents }, set: { settings.snoozeCostCents = $0 }
                        ))
                    }
                    .padding(.vertical, 4)

                    Stepper("Snooze length: \(settings.snoozeMinutes) min", value: Binding(
                        get: { settings.snoozeMinutes }, set: { settings.snoozeMinutes = $0 }
                    ), in: 1...30)
                }

                Section("Account") {
                    if let name = auth.displayName {
                        LabeledContent("Signed in as", value: name)
                    } else {
                        LabeledContent("Signed in", value: "Apple Account")
                    }
                    Label(
                        CloudSync.shared.isAvailable ? "Syncing via iCloud" : "iCloud unavailable on this device",
                        systemImage: CloudSync.shared.isAvailable ? "icloud.fill" : "icloud.slash"
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

                Section("Legal") {
                    Link("Privacy Policy", destination: LegalLinks.privacy)
                    Link("Terms of Use", destination: LegalLinks.terms)
                }

                Section {
                    Button("Turn off Ante", role: .destructive) {
                        alarmEngine.cancelDailyAlarm()
                    }
                }

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Done") { save() }
                        .disabled(isSaving)
                }
            }
        }
        .dismissKeyboardOnTap()
    }

    private var weekdayPicker: some View {
        HStack {
            ForEach(orderedWeekdays, id: \.self) { day in
                let isOn = settings.repeatWeekdayRawValues.contains(day.rawValue)
                Button {
                    toggle(day)
                } label: {
                    Text(weekdayLabels[day] ?? "?")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 28, height: 28)
                        .background(isOn ? AnteTheme.gold : Color.gray.opacity(0.25))
                        .foregroundStyle(isOn ? AnteTheme.feltDeep : .primary)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toggle(_ day: Locale.Weekday) {
        var set = Set(settings.repeatWeekdayRawValues)
        if set.contains(day.rawValue) {
            set.remove(day.rawValue)
        } else {
            set.insert(day.rawValue)
        }
        settings.repeatWeekdayRawValues = orderedWeekdays.map(\.rawValue).filter(set.contains)
    }

    private func save() {
        isSaving = true
        errorMessage = nil
        Task {
            do {
                try await alarmEngine.scheduleDailyAlarm(settings: settings)
                CloudSync.shared.pushSettings(settings.snapshot)
                dismiss()
            } catch {
                errorMessage = "Couldn't reschedule: \(error.localizedDescription)"
            }
            isSaving = false
        }
    }
}
