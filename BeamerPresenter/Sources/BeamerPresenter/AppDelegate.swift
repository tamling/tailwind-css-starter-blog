import AppKit
import SwiftUI
import UniformTypeIdentifiers

final class AppDelegate: NSObject, NSApplicationDelegate {
    let state = PresentationState()
    private var presenterWindow: NSWindow?
    private var audienceWindow: NSWindow?
    private var keyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenu()
        installKeyMonitor()
        NotificationCenter.default.addObserver(
            self, selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NSApp.activate(ignoringOtherApps: true)
        openDocument(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    // MARK: - Menu

    private func setupMenu() {
        let mainMenu = NSMenu()
        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appItem.submenu = appMenu
        appMenu.addItem(withTitle: "Open…", action: #selector(openDocument(_:)), keyEquivalent: "o")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        NSApp.mainMenu = mainMenu
    }

    @objc func openDocument(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }

        if state.load(url: url) {
            buildWindowsIfNeeded()
            positionWindows()
        } else {
            let alert = NSAlert()
            alert.messageText = "Could not open PDF"
            alert.informativeText = url.lastPathComponent
            alert.runModal()
        }
    }

    // MARK: - Windows

    private func buildWindowsIfNeeded() {
        if presenterWindow == nil {
            let presenter = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1280, height: 800),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered, defer: false)
            presenter.title = "Presenter — BeamerPresenter"
            presenter.contentView = NSHostingView(rootView: PresenterView().environmentObject(state))
            presenter.makeKeyAndOrderFront(nil)
            presenterWindow = presenter
        }
        if audienceWindow == nil {
            let audience = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1280, height: 720),
                styleMask: [.borderless],
                backing: .buffered, defer: false)
            audience.contentView = NSHostingView(rootView: AudienceView().environmentObject(state))
            audience.level = .mainMenu
            audience.collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces]
            audience.orderFront(nil)
            audienceWindow = audience
        }
    }

    @objc private func screensChanged() { positionWindows() }

    /// Audience window fills the external display (or the only display if there's
    /// just one); presenter window is centered on the built-in display.
    private func positionWindows() {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return }
        let audienceScreen = screens.count > 1 ? screens[1] : screens[0]
        let presenterScreen = NSScreen.main ?? screens[0]

        audienceWindow?.setFrame(audienceScreen.frame, display: true)

        if let p = presenterWindow, screens.count > 1 {
            let visible = presenterScreen.visibleFrame
            let size = p.frame.size
            p.setFrameOrigin(NSPoint(x: visible.midX - size.width / 2,
                                     y: visible.midY - size.height / 2))
        }
    }

    // MARK: - Keyboard

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            return self.handleKey(event) ? nil : event
        }
    }

    /// Returns true if the key was consumed.
    private func handleKey(_ event: NSEvent) -> Bool {
        switch event.keyCode {
        case 124, 49, 121: state.next()              // → / space / page down
        case 123, 116:     state.previous()          // ← / page up
        case 115:          state.goToFirst()         // home
        case 119:          state.goToLast()          // end
        case 11:           state.blackout.toggle()   // B
        case 15:           state.resetTimer()        // R
        case 53:           NSApp.terminate(nil)      // esc
        default:           return false
        }
        return true
    }
}
