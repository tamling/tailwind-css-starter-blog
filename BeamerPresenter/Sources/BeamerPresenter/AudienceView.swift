import SwiftUI

/// What the projector/external display shows: just the slide, full-bleed, with a
/// black-out toggle (press `B`).
struct AudienceView: View {
    @EnvironmentObject var state: PresentationState

    var body: some View {
        ZStack {
            Color.black
            if !state.blackout {
                PDFPageView(document: state.slideDoc, pageIndex: state.index)
            }
        }
        .ignoresSafeArea()
    }
}
