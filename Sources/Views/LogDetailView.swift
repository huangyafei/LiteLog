
import SwiftUI

struct LogDetailView: View {
    let log: LogEntry?

    var body: some View {
        if let log = self.log {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header(log: log)
                    Divider()
                    details(log: log)
                    Divider()
                    payloads(log: log)
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack {
                Spacer()
                Text("Select a log to see details")
                    .font(.title)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    @ViewBuilder
    private func header(log: LogEntry) -> some View {
        HStack {
            Image(systemName: log.status == "success" ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(log.status == "success" ? .green : .red)
                .font(.largeTitle)
            VStack(alignment: .leading) {
                Text(log.model)
                    .font(.title)
                    .bold()
                Text(log.requestId)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private func details(log: LogEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            DetailRow(label: "Status", value: log.status.capitalized)
            DetailRow(label: "Spend", value: "\(String(format: "%.8f", log.spend)) USD")
            DetailRow(label: "Start Time", value: formattedDate(log.startTime))
            DetailRow(label: "End Time", value: formattedDate(log.endTime))
            DetailRow(label: "Total Tokens", value: "\(log.totalTokens ?? 0)")
            DetailRow(label: "User", value: log.user ?? "N/A")
        }
    }
    
    @ViewBuilder
    private func payloads(log: LogEntry) -> some View {
        VStack(alignment: .leading) {
            Text("Request Payload").font(.headline)
            HighlightedJsonView(data: log.requestPayload)
            
            Text("Response Payload").font(.headline).padding(.top)
            HighlightedJsonView(data: log.responsePayload)
        }
    }
    
    private func formattedDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            return date.formatted(date: .abbreviated, time: .complete)
        }
        return "Invalid Date"
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.headline)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .font(.body)
                .textSelection(.enabled)
        }
    }
}


