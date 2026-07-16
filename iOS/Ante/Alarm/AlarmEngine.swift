import AlarmKit
import Foundation
import Observation
import SwiftUI

@Observable
final class AlarmEngine {
    private(set) var authorizationState: AlarmManager.AuthorizationState = .notDetermined
    private(set) var isAlerting: Bool = false
    private(set) var isScheduled: Bool = false

    private var watchTask: Task<Void, Never>?

    init() {
        authorizationState = AlarmManager.shared.authorizationState
        watchTask = Task { [weak self] in
            guard let self else { return }
            for await alarms in AlarmManager.shared.alarmUpdates {
                await self.refresh(with: alarms)
            }
        }
    }

    deinit {
        watchTask?.cancel()
    }

    @MainActor
    private func refresh(with alarms: [Alarm]) {
        guard let id = SharedStore.currentAlarmID else {
            isAlerting = false
            isScheduled = false
            return
        }
        guard let current = alarms.first(where: { $0.id == id }) else {
            isAlerting = false
            isScheduled = false
            return
        }
        isAlerting = current.state == .alerting
        isScheduled = current.state == .scheduled || current.state == .countdown
    }

    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        if AlarmManager.shared.authorizationState == .authorized {
            authorizationState = .authorized
            return true
        }
        do {
            let state = try await AlarmManager.shared.requestAuthorization()
            authorizationState = state
            return state == .authorized
        } catch {
            return false
        }
    }

    /// Schedules (or reschedules) Ante's single daily alarm from the given
    /// settings. Any previous Ante alarm is cancelled first - this app only
    /// ever runs one active commitment at a time.
    func scheduleDailyAlarm(settings: AppSettings) async throws {
        let weekdays: [Locale.Weekday] = settings.repeatWeekdayRawValues.compactMap { Locale.Weekday(rawValue: $0) }
        let time = Alarm.Schedule.Relative.Time(hour: settings.wakeHour, minute: settings.wakeMinute)
        let recurrence: Alarm.Schedule.Relative.Recurrence = weekdays.isEmpty ? .never : .weekly(weekdays)
        let schedule = Alarm.Schedule.relative(.init(time: time, repeats: recurrence))
        try await replaceAlarm(schedule: schedule, settings: settings)
    }

    /// Silences the currently-ringing alarm (the snooze fee was already
    /// charged by the caller) and re-alerts once after `snoozeMinutes`. The
    /// same fine still applies if the snoozed alarm is also stopped without
    /// verifying - snoozing buys time, not amnesty.
    func snooze(settings: AppSettings) async throws {
        guard let id = SharedStore.currentAlarmID else { return }
        try? AlarmManager.shared.stop(id: id)
        let fireDate = Date().addingTimeInterval(TimeInterval(settings.snoozeMinutes * 60))
        try await replaceAlarm(schedule: .fixed(fireDate), settings: settings)
    }

    /// Restores the normal recurring daily schedule. Call this after a
    /// morning's cycle is fully resolved (verified or paid), including after
    /// a one-time snoozed alarm, so tomorrow's alarm is still armed.
    func rearmDailySchedule(settings: AppSettings) async throws {
        try await scheduleDailyAlarm(settings: settings)
    }

    private func replaceAlarm(schedule: Alarm.Schedule, settings: AppSettings) async throws {
        if let existing = SharedStore.currentAlarmID {
            try? AlarmManager.shared.cancel(id: existing)
        }

        let id = UUID()
        let metadata = AnteAlarmMetadata(label: "Ante")
        let stopButton = AlarmButton(text: "Stop", textColor: .white, systemImageName: "stop.fill")
        let wakeButton = AlarmButton(text: "I'm Up", textColor: .white, systemImageName: "camera.fill")

        let alert = AlarmPresentation.Alert(
            title: "Make your bed",
            stopButton: stopButton,
            secondaryButton: wakeButton,
            secondaryButtonBehavior: .custom
        )
        let attributes = AlarmAttributes<AnteAlarmMetadata>(
            presentation: AlarmPresentation(alert: alert),
            metadata: metadata,
            tintColor: .accentColor
        )

        let stopIntent = StopWithoutVerifyingIntent(alarmID: id, fineCents: settings.fineCents)
        let configuration = AlarmManager.AlarmConfiguration.alarm(
            schedule: schedule,
            attributes: attributes,
            stopIntent: stopIntent,
            secondaryIntent: WakeCheckIntent()
        )

        _ = try await AlarmManager.shared.schedule(id: id, configuration: configuration)
        SharedStore.currentAlarmID = id
        isScheduled = true
    }

    func cancelDailyAlarm() {
        guard let id = SharedStore.currentAlarmID else { return }
        try? AlarmManager.shared.cancel(id: id)
        SharedStore.currentAlarmID = nil
        isScheduled = false
        isAlerting = false
    }

    /// Called once the app has confirmed the bed photo passed verification
    /// for the currently-alerting alarm. This is the only "free" way to
    /// silence the alarm before its own stop button is tapped.
    func markVerifiedAndStop() {
        guard let id = SharedStore.currentAlarmID else { return }
        try? AlarmManager.shared.stop(id: id)
        SharedStore.pendingSettlement = nil
    }
}
