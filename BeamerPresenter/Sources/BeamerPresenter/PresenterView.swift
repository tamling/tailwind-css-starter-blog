import SwiftUI

/// Your private screen: current slide, next slide, notes, and a status bar with
/// slide counter, elapsed timer, and wall clock.
struct PresenterView: View {
    @EnvironmentObject var state: PresentationState

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                slidePane(title: "Current", index: state.index)
                slidePane(title: "Next", index: state.index + 1)
                    .opacity(state.index + 1 < state.pageCount ? 1 : 0.25)
            }
            .frame(maxHeight: .infinity)

            notesPane
                .frame(maxHeight: .infinity)

            StatusBar()
        }
        .padding(8)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func slidePane(title: String, index: Int) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            PDFPageView(document: state.slideDoc, pageIndex: index)
                .border(.gray.opacity(0.5))
        }
    }

    @ViewBuilder
    private var notesPane: some View {
        if state.hasNotes {
            VStack(spacing: 4) {
                Text("Notes").font(.caption).foregroundStyle(.secondary)
                PDFPageView(document: state.notesDoc, pageIndex: state.index)
                    .border(.gray.opacity(0.5))
            }
        } else {
            VStack(spacing: 8) {
                Text("No notes in this PDF").font(.headline)
                Text("Compile your Beamer deck with:\n\\setbeameroption{show notes on second screen=right}")
                    .font(.system(.body, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct StatusBar: View {
    @EnvironmentObject var state: PresentationState
    @State private var now = Date()
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack {
            Text("Slide \(state.pageCount == 0 ? 0 : state.index + 1) / \(state.pageCount)")
            if state.blackout {
                Text("• BLACKED OUT").foregroundStyle(.orange)
            }
            Spacer()
            Text("Elapsed " + elapsed)
            Spacer()
            Text(now, style: .time)
        }
        .font(.headline.monospacedDigit())
        .onReceive(tick) { now = $0 }
    }

    private var elapsed: String {
        let secs = max(0, Int(now.timeIntervalSince(state.startDate)))
        return String(format: "%02d:%02d", secs / 60, secs % 60)
    }
}
