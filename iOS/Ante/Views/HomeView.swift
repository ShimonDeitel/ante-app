import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AlarmEngine.self) private var alarmEngine
    @Environment(AppSettings.self) private var settings
    @Query(sort: \MorningRecord.date, order: .reverse) private var records: [MorningRecord]

    @State private var showSettings = false
    @State private var showHistory = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    wakeTimeCard
                    ChipStackView(chipCount: max(1, settings.fineCents / 200))
                    statsRow
                    recentList
                }
                .padding(24)
            }
            .background(AnteTheme.feltGradient.ignoresSafeArea())
            .navigationTitle("Ante")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill").foregroundStyle(AnteTheme.gold)
                    }
                }
            }
        }
        .tint(AnteTheme.gold)
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showHistory) { HistoryView(records: records) }
    }

    private var wakeTimeCard: some View {
        VStack(spacing: 8) {
            Text(alarmEngine.isScheduled ? "ARMED" : "NOT SET")
                .font(.caption)
                .fontWeight(.bold)
                .tracking(2)
                .foregroundStyle(alarmEngine.isScheduled ? AnteTheme.gold : AnteTheme.chipRed)
            Text(timeString)
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(AnteTheme.cream)
            Text("Forfeit on miss: \(Money.format(cents: settings.fineCents))")
                .font(.subheadline)
                .foregroundStyle(AnteTheme.cream.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(AnteTheme.felt, in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(AnteTheme.gold.opacity(0.35), lineWidth: 1))
    }

    private var timeString: String {
        let comps = DateComponents(hour: settings.wakeHour, minute: settings.wakeMinute)
        let date = Calendar.current.date(from: comps) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }

    private var statsRow: some View {
        HStack(spacing: 16) {
            StatTile(title: "Streak", value: "\(currentStreak)")
            StatTile(title: "Forfeited", value: Money.format(cents: totalForfeitedCents))
        }
    }

    private var currentStreak: Int {
        var streak = 0
        for record in records {
            if record.outcome == .verified { streak += 1 } else { break }
        }
        return streak
    }

    private var totalForfeitedCents: Int {
        records.reduce(0) { $0 + $1.totalChargedCents }
    }

    private var recentList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent mornings")
                    .font(.headline)
                    .foregroundStyle(AnteTheme.cream)
                Spacer()
                Button("See all") { showHistory = true }
                    .font(.footnote)
                    .foregroundStyle(AnteTheme.gold)
            }
            if records.isEmpty {
                Text("Nothing settled yet.")
                    .font(.footnote)
                    .foregroundStyle(AnteTheme.cream.opacity(0.5))
            } else {
                ForEach(records.prefix(5)) { record in
                    MorningRow(record: record)
                }
            }
        }
    }
}

private struct StatTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AnteTheme.goldBright)
            Text(title.uppercased())
                .font(.caption2)
                .tracking(1)
                .foregroundStyle(AnteTheme.cream.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AnteTheme.felt, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct MorningRow: View {
    let record: MorningRecord

    var body: some View {
        HStack {
            Image(systemName: record.outcome == .verified ? "checkmark.seal.fill" : "xmark.seal.fill")
                .foregroundStyle(record.outcome == .verified ? AnteTheme.gold : AnteTheme.chipRed)
            VStack(alignment: .leading, spacing: 2) {
                Text(record.date.formatted(date: .abbreviated, time: .shortened))
                    .foregroundStyle(AnteTheme.cream)
                    .font(.subheadline)
                if record.totalChargedCents > 0 {
                    Text("Charged \(Money.format(cents: record.totalChargedCents))")
                        .font(.caption)
                        .foregroundStyle(AnteTheme.cream.opacity(0.55))
                }
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}
