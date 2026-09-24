import WidgetKit
import SwiftUI

struct PartnerEntry: TimelineEntry {
    let date: Date
    let title: String
    let status: String
    let detail: String
    let quickPingEnabled: Bool
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> PartnerEntry { PartnerEntry(date: Date(), title: "143 · Our little world", status: "Partner status", detail: "Private by default ♡", quickPingEnabled: true) }
    func getSnapshot(in context: Context, completion: @escaping (PartnerEntry) -> Void) { completion(read()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<PartnerEntry>) -> Void) {
        let entry = read()
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(1800))))
    }
    private func read() -> PartnerEntry {
        let defaults = UserDefaults(suiteName: "group.com.x10think.onefourthree")
        return PartnerEntry(date: Date(), title: defaults?.string(forKey: "title") ?? "143 · Our little world", status: defaults?.string(forKey: "partner_status") ?? "Open 143 to refresh", detail: defaults?.string(forKey: "detail") ?? "Private by default ♡", quickPingEnabled: defaults?.bool(forKey: "quick_ping_enabled") ?? true)
    }
}

struct PartnerWidgetView: View {
    var entry: PartnerEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.title).font(.headline).foregroundStyle(Color(red: 0.42, green: 0.20, blue: 0.29))
            Text(entry.status).font(.subheadline)
            Text(entry.detail).font(.caption).foregroundStyle(.secondary)
            if entry.quickPingEnabled {
                Link(destination: URL(string: "143://widget/ping")!) {
                    Label("Quick Ping", systemImage: "heart.fill")
                        .font(.caption.bold())
                        .foregroundStyle(Color(red: 0.55, green: 0.24, blue: 0.35))
                }
                .accessibilityLabel("Open 143 to confirm a Quick Ping")
            }
        }
        .containerBackground(Color(red: 1.0, green: 0.96, blue: 0.95), for: .widget)
        .widgetURL(URL(string: "143://home"))
    }
}

@main
struct OneFourThreeWidgets: Widget {
    let kind = "OneFourThreePartnerWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in PartnerWidgetView(entry: entry) }
            .configurationDisplayName("143 Partner")
            .description("Partner status, days together, next date, mood or an on-this-day memory—only when enabled.")
            .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
