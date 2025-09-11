
import SwiftUI

struct LogEntryRowView: View {
    let log: LogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: log.status == "success" ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(log.status == "success" ? .green : .red)
                Text(log.model).font(.headline)
                Spacer()
                Text(formattedDate(log.startTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("\(String(format: "%.6f", log.spend)) USD")
                Spacer()
                Text("\(duration(from: log.startTime, to: log.endTime))s")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func formattedDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            return date.formatted(date: .numeric, time: .standard)
        }
        return "Invalid Date"
    }
    
    private func duration(from start: String, to end: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let startDate = formatter.date(from: start), let endDate = formatter.date(from: end) {
            let duration = endDate.timeIntervalSince(startDate)
            return String(format: "%.3f", duration)
        }
        return "--"
    }
}
