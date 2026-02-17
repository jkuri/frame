import SwiftUI

struct HistoryPopover: View {
  @Bindable var editorState: EditorState

  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    let _ = colorScheme
    VStack(alignment: .leading, spacing: 0) {
      SectionHeader(title: "History")

      if editorState.history.entries.isEmpty {
        Text("No history")
          .font(.system(size: 12))
          .foregroundStyle(ReframedColors.tertiaryText)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.vertical, 16)
      } else {
        ScrollViewReader { proxy in
          ScrollView {
            LazyVStack(spacing: 0) {
              ForEach(Array(editorState.history.entries.enumerated().reversed()), id: \.offset) {
                index,
                entry in
                let isCurrent = index == editorState.history.currentIndex
                historyRow(entry: entry, index: index, isCurrent: isCurrent)
                  .id(index)
              }
            }
          }
          .frame(maxHeight: 340)
          .onAppear {
            proxy.scrollTo(editorState.history.currentIndex, anchor: .center)
          }
        }
      }
    }
    .padding(.vertical, 8)
    .frame(width: 280)
    .background(ReframedColors.panelBackground)
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .strokeBorder(ReframedColors.subtleBorder, lineWidth: 0.5)
    )
  }

  private func historyRow(entry: HistoryEntry, index: Int, isCurrent: Bool) -> some View {
    let entries = editorState.history.entries
    let diffs: [String] =
      index > 0
      ? History.describeChanges(from: entries[index - 1].snapshot, to: entry.snapshot) : []

    return Button {
      editorState.jumpToHistory(index: index)
    } label: {
      VStack(alignment: .leading, spacing: 3) {
        HStack {
          if index == 0 {
            Text("Initial state")
              .font(.system(size: 12, weight: isCurrent ? .semibold : .regular))
              .foregroundStyle(isCurrent ? ReframedColors.primaryText : ReframedColors.secondaryText)
          } else {
            Text(diffs.isEmpty ? "Change" : diffs.first!)
              .font(.system(size: 12, weight: isCurrent ? .semibold : .regular))
              .foregroundStyle(
                isCurrent ? ReframedColors.primaryText : ReframedColors.secondaryText
              )
              .lineLimit(1)
          }

          Spacer()

          Text(relativeTime(entry.timestamp))
            .font(.system(size: 10))
            .foregroundStyle(ReframedColors.tertiaryText)
        }

        if diffs.count > 1 {
          VStack(alignment: .leading, spacing: 1) {
            ForEach(diffs.dropFirst().prefix(4), id: \.self) { diff in
              Text(diff)
                .font(.system(size: 10))
                .foregroundStyle(ReframedColors.tertiaryText)
                .lineLimit(1)
            }
            if diffs.count > 5 {
              Text("+\(diffs.count - 5) more")
                .font(.system(size: 10))
                .foregroundStyle(ReframedColors.tertiaryText)
            }
          }
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(isCurrent ? ReframedColors.selectedBackground : Color.clear)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  private func relativeTime(_ date: Date) -> String {
    let seconds = Int(-date.timeIntervalSinceNow)
    if seconds < 5 { return "just now" }
    if seconds < 60 { return "\(seconds)s ago" }
    let minutes = seconds / 60
    if minutes < 60 { return "\(minutes)m ago" }
    let hours = minutes / 60
    if hours < 24 { return "\(hours)h ago" }
    let days = hours / 24
    return "\(days)d ago"
  }
}
