import SwiftUI
import PDFKit
import Combine

/// Single source of truth shared by both windows. A keypress or click mutates
/// state here and the presenter + audience views update in lockstep.
final class PresentationState: ObservableObject {
    @Published private(set) var slideDoc: PDFDocument?   // left half (or full page)
    @Published private(set) var notesDoc: PDFDocument?   // right half, nil for plain PDFs
    @Published private(set) var pageCount: Int = 0
    @Published private(set) var hasNotes: Bool = false
    @Published private(set) var isLoaded: Bool = false
    @Published private(set) var title: String = ""

    @Published var index: Int = 0
    @Published var blackout: Bool = false
    @Published var showOverview: Bool = false
    @Published private(set) var startDate = Date()

    private var thumbCache: [Int: NSImage] = [:]

    // MARK: - Loading

    @discardableResult
    func load(url: URL) -> Bool {
        guard let probe = PDFDocument(url: url), probe.pageCount > 0 else { return false }
        let split = PDFModel.isNotesLayout(probe)

        slideDoc = PDFModel.croppedDocument(url: url, half: split ? .left : .full)
        notesDoc = split ? PDFModel.croppedDocument(url: url, half: .right) : nil
        guard slideDoc != nil else { return false }

        hasNotes = split
        pageCount = slideDoc?.pageCount ?? 0
        title = url.deletingPathExtension().lastPathComponent
        thumbCache.removeAll()
        index = 0
        blackout = false
        showOverview = false
        startDate = Date()
        isLoaded = true
        return true
    }

    func unload() {
        slideDoc = nil
        notesDoc = nil
        pageCount = 0
        hasNotes = false
        title = ""
        thumbCache.removeAll()
        index = 0
        blackout = false
        showOverview = false
        isLoaded = false
    }

    // MARK: - Navigation

    func next()      { go(to: index + 1) }
    func previous()  { go(to: index - 1) }
    func goToFirst() { go(to: 0) }
    func goToLast()  { go(to: pageCount - 1) }

    func go(to i: Int) {
        guard pageCount > 0 else { return }
        index = min(max(0, i), pageCount - 1)
    }

    func resetTimer() { startDate = Date() }

    // MARK: - Thumbnails

    /// Lazily renders and caches a thumbnail of the slide half for the strip and
    /// the overview grid.
    func thumbnail(at i: Int, height: CGFloat = 110) -> NSImage? {
        guard let doc = slideDoc, i >= 0, i < doc.pageCount, let page = doc.page(at: i) else { return nil }
        if let cached = thumbCache[i] { return cached }
        let box = page.bounds(for: .cropBox)
        let aspect = box.width / max(box.height, 1)
        let size = NSSize(width: height * aspect, height: height)
        let image = page.thumbnail(of: size, for: .cropBox)
        thumbCache[i] = image
        return image
    }
}
