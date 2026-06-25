import SwiftUI
import WidgetKit

private let widgetGroupId = "group.mamoru.keisan.widget"

struct MamoruEntry: TimelineEntry {
    let date: Date
    let gapLabel: String
    let gapValue: String
    let updatedAt: String
}

struct MamoruProvider: TimelineProvider {
    func placeholder(in context: Context) -> MamoruEntry {
        MamoruEntry(
            date: Date(),
            gapLabel: "不足額",
            gapValue: "▲ 2,300万円",
            updatedAt: "2026/06/25"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MamoruEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MamoruEntry>) -> Void) {
        let entry = readEntry()
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }

    private func readEntry() -> MamoruEntry {
        let prefs = UserDefaults(suiteName: widgetGroupId)
        return MamoruEntry(
            date: Date(),
            gapLabel: prefs?.string(forKey: "gap_label") ?? "未診断",
            gapValue: prefs?.string(forKey: "gap_value") ?? "-",
            updatedAt: prefs?.string(forKey: "updated_at") ?? ""
        )
    }
}

struct MamoruHomeWidgetEntryView: View {
    var entry: MamoruProvider.Entry

    var body: some View {
        Group {
            if #available(iOSApplicationExtension 17.0, *) {
                content
                    .containerBackground(for: .widget) {
                        Color(.systemBackground)
                    }
            } else {
                content
                    .background(Color(.systemBackground))
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("まもる計算")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(entry.gapLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(entry.gapValue)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(entry.gapValue.contains("▲") ? .red : .green)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            if !entry.updatedAt.isEmpty {
                Text(entry.updatedAt)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
    }
}

@main
struct MamoruHomeWidget: Widget {
    let kind: String = "MamoruHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MamoruProvider()) { entry in
            MamoruHomeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("まもる計算")
        .description("最新の不足保障額を表示します。")
        .supportedFamilies([.systemSmall, .systemMedium])
        .widgetURL(URL(string: "mamorukeisan://home"))
    }
}

struct MamoruHomeWidget_Previews: PreviewProvider {
    static var previews: some View {
        MamoruHomeWidgetEntryView(
            entry: MamoruEntry(
                date: Date(),
                gapLabel: "不足額",
                gapValue: "▲ 2,300万円",
                updatedAt: "2026/06/25"
            )
        )
        .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
