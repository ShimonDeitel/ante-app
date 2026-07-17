import SwiftUI
import SwiftData

@main
struct AnteApp: App {
    let modelContainer: ModelContainer = {
        let schema = Schema([MorningRecord.self])
        let configuration = ModelConfiguration(schema: schema)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    @State private var alarmEngine: AlarmEngine
    @State private var settings: AppSettings
    @State private var auth: AppleSignInService

    init() {
        #if DEBUG
        // UI tests launch fresh processes but share the SAME on-disk
        // UserDefaults across test methods within one `xcodebuild test`
        // invocation - one test's state (e.g. onboardingComplete=true from
        // a bootstrap) otherwise leaks into the next test's "fresh app"
        // assumption. This flag gives each test a guaranteed clean slate,
        // independent of what any other test left behind or what order
        // they ran in.
        if ProcessInfo.processInfo.environment["ANTE_UI_TEST_RESET"] != nil {
            let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)
        }
        #endif
        _alarmEngine = State(initialValue: AlarmEngine())
        _settings = State(initialValue: AppSettings.load())
        _auth = State(initialValue: AppleSignInService())
    }

    var body: some Scene {
        WindowGroup {
            RootRouter()
                .environment(alarmEngine)
                .environment(settings)
                .environment(auth)
                .modelContainer(modelContainer)
                .preferredColorScheme(.dark)
                .task {
                    await auth.refreshCredentialState()
                    CloudSync.shared.start()
                    CloudSync.shared.onRemoteChange = { [settings] in
                        if let remote = CloudSync.shared.pullSettingsIfNewer() {
                            settings.apply(remote)
                        }
                    }
                    if let remote = CloudSync.shared.pullSettingsIfNewer() {
                        settings.apply(remote)
                    }
                }
        }
    }
}
