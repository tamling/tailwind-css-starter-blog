# BeamerPresenter

A native macOS (Apple Silicon) presenter app for LaTeX **Beamer** decks,
modelled on [magicPresenter](https://www.magicpresenter.app). The audience
screen shows the slide; your laptop shows a full presenter console: current
slide, next slide, speaker notes, a thumbnail strip, a slide overview, and a
timer.

It works directly off a compiled PDF, so there's no LaTeX parsing involved.

## GUI

- **Welcome screen** — open button, drag-and-drop a PDF, and a recent-files list.
- **Presenter console** — control bar (open, home, prev/next, overview, blackout,
  timer, clock), large current slide, next slide, notes pane.
- **Thumbnail strip** — click any slide to jump; auto-scrolls to the current one.
- **Overview grid** — press `G` for a full grid of every slide; click to jump.
- **Audience window** — full-bleed slide, fullscreen on the external display.

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
| `G` | Toggle the slide overview |
| `B` | Black out the audience screen |
| `R` | Reset the elapsed timer |
| Esc | Close the overview |

Bluetooth presenter remotes emit Page Up / Page Down, so they work out of the box.

## Project layout

| File | Responsibility |
| --- | --- |
| `main.swift` | AppKit bootstrap |
| `AppDelegate.swift` | Windows, screen placement, menu, keyboard |
| `PresentationState.swift` | Shared state (index, timer, blackout, overview, thumbnails) |
| `PDFModel.swift` | Loads the PDF and crops each page into halves |
| `PDFPageView.swift` | Renders one non-interactive page (SwiftUI ↔ PDFKit) |
| `RecentFiles.swift` | Recently-opened list persisted in UserDefaults |
| `WelcomeView.swift` | Start screen: open, drag-and-drop, recents |
| `PresenterView.swift` | Root switch + presenter console + control bar |
| `ThumbnailStrip.swift` | Clickable thumbnail navigation row |
| `OverviewGrid.swift` | Full-window slide overview overlay |
| `AudienceView.swift` | Full-bleed slide for the projector |

## Shipping a real `.app`

`swift run` is for iterating. To distribute a double-clickable, notarized app:

1. Create a new **macOS App** target in Xcode (SwiftUI lifecycle).
2. Add these `Sources/BeamerPresenter/*.swift` files to it (remove `main.swift`;
   use a `@main struct App` instead, or keep the `AppDelegate` via
   `NSApplicationDelegateAdaptor`).
3. Set the deployment target to macOS 13, build for `arm64`.
4. Enable Hardened Runtime, sign with your Developer ID, and notarize.

## Roadmap ideas (magicPresenter parity)

- **Magic ink** — presenter-only hidden notes + visible freehand annotation on slides
- On-slide laser pointer
- Embedded links and videos in the PDF
- Larger / scrollable / markdown notes via the `pdfpc` embedded-notes format
- Per-slide timing and a rehearsal mode
