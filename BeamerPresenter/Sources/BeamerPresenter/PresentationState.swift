import SwiftUI
import PDFKit
import Combine

/// Single source of truth shared by both windows. A keypress mutates `index`
/// here and both the presenter and audience views update in lockstep.
final class PresentationState: ObservableObject {
    @Published private(set) var slideDoc: PDFDocument?   // left half (or full page)
    @Published private(set) var notesDoc: PDFDocument?   // right half, nil for plain PDFs
    @Published private(set) var pageCount: Int = 0
    @Published private(set) var hasNotes: Bool = false
    @Published var index: Int = 0
    @Published var blackout: Bool = false
    @Published private(set) var startDate = Date()

    @discardableResult
    func load(url: URL) -> Bool {
        guard let probe = PDFDocument(url: url), probe.pageCount > 0 else { return false }
        let split = PDFModel.isNotesLayout(probe)

        slideDoc = PDFModel.croppedDocument(url: url, half: split ? .left : .full)
        notesDoc = split ? PDFModel.croppedDocument(url: url, half: .right) : nil
        hasNotes = split
        pageCount = slideDoc?.pageCount ?? 0
        index = 0
        blackout = false
        startDate = Date()
        return slideDoc != nil
    }

    func next()       { if index < pageCount - 1 { index += 1 } }
    func previous()   { if index > 0 { index -= 1 } }
    func goToFirst()  { index = 0 }
    func goToLast()   { index = max(0, pageCount - 1) }
    func resetTimer() { startDate = Date() }
}
