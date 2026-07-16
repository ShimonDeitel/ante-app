import SwiftUI

private let orderedWeekdays: [Locale.Weekday] = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
private let weekdayLabels: [Locale.Weekday: String] = [
    .sunday: "S", .monday: "M", .tuesday: "T", .wednesday: "W",
    .thursday: "T", .friday: "F", .saturday: "S"
]

struct SettingsView: View {
    @Environment(AlarmEngine.self) private var alarmEngine
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    @State private var showCamera = false
    @State private var referenceImage: UIImage?
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

                Section("Stakes") {
                    VStack(alignment: .leading) {
                        Text("Fine for skipping: \(Money.format(cents: settings.fineCents))")
                        Slider(value: Binding(get: { settings.fineDollars }, set: { settings.fineDollars = $0 }), in: 1...1000, step: 1)
                    }
                    Stepper(
                        "Snooze cost: \(Money.format(cents: settings.snoozeCostCents))",
                        value: Binding(get: { settings.snoozeCostDollars }, set: { settings.snoozeCostDollars = $0 }),
                        in: 0...50, step: 1
                    )
                    Stepper("Snooze length: \(settings.snoozeMinutes) min", value: Binding(
                        get: { settings.snoozeMinutes }, set: { settings.snoozeMinutes = $0 }
                    ), in: 1...30)
                }

                Section("Reference photo") {
                    if let referenceImage {
                        Image(uiImage: referenceImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 160)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    Button("Retake reference photo") { showCamera = true }
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
        .onAppear { referenceImage = ReferencePhotoStore.load() }
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView(
                onCapture: { image in
                    referenceImage = image
                    ReferencePhotoStore.save(image)
                    showCamera = false
                },
                onCancel: { showCamera = false }
            )
            .ignoresSafeArea()
        }
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
                dismiss()
            } catch {
                errorMessage = "Couldn't reschedule: \(error.localizedDescription)"
            }
            isSaving = false
        }
    }
}
