import SwiftUI

struct HistoryView: View {
    let records: [MorningRecord]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        StatBlock(title: "Mornings kept", value: "\(records.filter { $0.outcome == .verified }.count)")
                        Divider()
                        StatBlock(title: "Total forfeited", value: Money.format(cents: records.reduce(0) { $0 + $1.totalChargedCents }))
                    }
                    .listRowBackground(Color.clear)
                }
                Section("Every morning") {
                    if records.isEmpty {
                        Text("Nothing yet.").foregroundStyle(.secondary)
                    } else {
                        ForEach(records) { record in
                            MorningRow(record: record)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct StatBlock: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title2).fontWeight(.bold)
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
