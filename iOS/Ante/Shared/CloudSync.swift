import Foundation

/// Cross-device sync over iCloud's key-value store - no server, no CloudKit
/// container. Carries the user's settings and morning history between their
/// own devices signed into the same Apple Account. Safe even when iCloud is
/// unavailable (it simply won't sync; never crashes). Same proven pattern
/// already in production in this codebase (pulse/friction/.../CloudSync.swift).
///
/// Settings use last-writer-wins (a single small blob, one device's most
/// recent edit should win outright). History is different: it's an
/// append-only log two devices could each add different mornings to, so
/// pulling merges by record id rather than overwriting.
@MainActor
final class CloudSync {
    static let shared = CloudSync()

    private let store = NSUbiquitousKeyValueStore.default
    private let settingsKey = "ante.cloud.settings"
    private let settingsStampKey = "ante.cloud.settings.stamp"
    private let localSettingsStampKey = "ante.cloud.settings.localStamp"
    private let historyKey = "ante.cloud.history"

    /// Fired (on the main actor) when another device pushed newer data.
    var onRemoteChange: (() -> Void)?

    private init() {}

    var isAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    func start() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(externalChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store
        )
        store.synchronize()
    }

    @objc private func externalChange(_ note: Notification) {
        Task { @MainActor in self.onRemoteChange?() }
    }

    // MARK: - Settings (last-writer-wins)

    func pushSettings(_ snapshot: AppSettings.Snapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        let now = Date().timeIntervalSince1970
        store.set(data, forKey: settingsKey)
        store.set(now, forKey: settingsStampKey)
        UserDefaults.standard.set(now, forKey: localSettingsStampKey)
        store.synchronize()
    }

    /// If iCloud holds a newer settings snapshot than this device last saw,
    /// return it (and record that we've now seen this stamp).
    func pullSettingsIfNewer() -> AppSettings.Snapshot? {
        store.synchronize()
        let cloudStamp = store.double(forKey: settingsStampKey)
        let localStamp = UserDefaults.standard.double(forKey: localSettingsStampKey)
        guard cloudStamp > localStamp,
              let data = store.data(forKey: settingsKey),
              let snapshot = try? JSONDecoder().decode(AppSettings.Snapshot.self, from: data)
        else { return nil }
        UserDefaults.standard.set(cloudStamp, forKey: localSettingsStampKey)
        return snapshot
    }

    // MARK: - History (union merge by id)

    struct HistoryEntry: Codable, Identifiable {
        var id: UUID
        var date: Date
        var outcome: String
        var fineChargedCents: Int
        var snoozeCount: Int
        var snoozeChargedCents: Int
    }

    func pushHistory(_ entries: [HistoryEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        store.set(data, forKey: historyKey)
        store.synchronize()
    }

    /// Returns the full cloud history (caller merges by id against its own
    /// local records and re-pushes the union). Nil if iCloud has nothing yet.
    func pullHistory() -> [HistoryEntry]? {
        store.synchronize()
        guard let data = store.data(forKey: historyKey) else { return nil }
        return try? JSONDecoder().decode([HistoryEntry].self, from: data)
    }
}
