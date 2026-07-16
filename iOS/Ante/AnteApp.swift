import SwiftUI
import SwiftData

@main
struct AnteApp: App {
    let modelContainer: ModelContainer = {
        let schema = Schema([MorningRecord.self])
        let configuration = ModelConfiguration(schema: schema)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    @State private var alarmEngine = AlarmEngine()
    @State private var settings = AppSettings.load()

    var body: some Scene {
        WindowGroup {
            RootRouter()
                .environment(alarmEngine)
                .environment(settings)
                .modelContainer(modelContainer)
                .preferredColorScheme(.dark)
        }
    }
}
