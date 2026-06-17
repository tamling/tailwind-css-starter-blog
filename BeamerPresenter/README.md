# BeamerPresenter

A native macOS (Apple Silicon) presenter app for LaTeX **Beamer** decks — a
PowerPoint-style presenter view. The audience screen shows the slide; your
laptop shows the current slide, the next slide, your speaker notes, and a timer.

It works directly off a compiled PDF, so there's no LaTeX parsing involved.

## How notes work

Compile your Beamer deck so each PDF page carries the slide on the left half and
your `\note{}` text on the right half:

```latex
\documentclass{beamer}
\setbeameroption{show notes on second screen=right}

\begin{document}
\begin{frame}{Title}
  Slide content here.
  \note{These are my speaker notes for this slide.}
\end{frame}
\end{document}
```

The app detects the double-width layout automatically and splits each page:
left half → audience, right half → your notes pane. A plain PDF (no notes
layout) still presents fine — the notes pane just shows a hint instead.

## Run it (development)

Requires Xcode / the Swift toolchain on macOS 13+.

```bash
cd BeamerPresenter
swift run
```

An open panel appears — pick your compiled PDF. The audience window goes
fullscreen on your external display (or the only display if there's just one).

## Keyboard / remote controls

| Key | Action |
| --- | --- |
| → / Space / Page Down | Next slide |
| ← / Page Up | Previous slide |
| Home / End | First / last slide |
| `B` | Black out the audience screen |
| `R` | Reset the elapsed timer |
| Esc | Quit |

Bluetooth presenter remotes emit Page Up / Page Down, so they work out of the box.

## Project layout

| File | Responsibility |
| --- | --- |
| `main.swift` | AppKit bootstrap |
| `AppDelegate.swift` | Windows, screen placement, menu, keyboard |
| `PresentationState.swift` | Shared state (current index, timer, blackout) |
| `PDFModel.swift` | Loads the PDF and crops each page into halves |
| `PDFPageView.swift` | Renders one non-interactive page (SwiftUI ↔ PDFKit) |
| `PresenterView.swift` | Presenter layout + status bar |
| `AudienceView.swift` | Full-bleed slide for the projector |

## Shipping a real `.app`

`swift run` is for iterating. To distribute a double-clickable, notarized app:

1. Create a new **macOS App** target in Xcode (SwiftUI lifecycle).
2. Add these `Sources/BeamerPresenter/*.swift` files to it (remove `main.swift`;
   use a `@main struct App` instead, or keep the `AppDelegate` via
   `NSApplicationDelegateAdaptor`).
3. Set the deployment target to macOS 13, build for `arm64`.
4. Enable Hardened Runtime, sign with your Developer ID, and notarize.

## Roadmap ideas

- Thumbnail grid for jumping around (`PDFThumbnailView`)
- Larger / scrollable / markdown notes via the `pdfpc` embedded-notes format
- On-slide laser pointer and freehand annotations
- Per-slide timing and a rehearsal mode
