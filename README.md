# ExtTabCtrl

A custom tab control component for [Lazarus](https://www.lazarus-ide.org/) / Free Pascal, offering a richer feature set than the standard `TPageControl`.

---

## Disclaimer

> I am not a professional programmer. This component is a hobby project, written for my own use and shared in the hope that others may find it useful. It has been developed and tested to the best of my ability, but it comes with **no warranty of any kind**. Use it at your own risk. Bug reports and suggestions are welcome, but I cannot guarantee timely responses or fixes.

---

## Features

- **Five tab styles**: `Flat`, `Button`, `Delphi`, `Chrome`, and `macOS`, each with its own look and feel.
- **Four tab positions**: `Top`, `Bottom`, `Left`, and `Right`. Vertical tabs (Left/Right) rotate text and optionally rotate images.
- **Close button**: per-tab close button, visible on the active tab and on any hovered tab. Supports a custom close image or falls back to a drawn x symbol.
- **Add button**: built-in button to add new tabs, optionally backed by a `TPopupMenu` for custom actions.
- **Scroll buttons**: automatically appear when tabs overflow the available width/height, scrolling by one tab at a time.
- **Drag-to-reorder**: tabs can be dragged to new positions with visual drop indicator.
- **Middle-click to close**: optional.
- **Keyboard navigation**: arrow keys (Left/Right/Up/Down), Home, End; focus is obtained by clicking or via Tab key.
- **Mouse-wheel navigation**: scroll through tabs with the mouse wheel.
- **Per-tab properties**: each tab (`TExtTab`) has `Caption`, `Color` (accent stripe), `Visible`, `Hint`, `ImageIndex`, `Image` (standalone bitmap), `Value` (string), `Data` (object), and per-tab `FontOptions`.
- **Image list support**: link a `TCustomImageList` via the `Images` property; images are drawn alongside tab captions and optionally rotated for vertical tabs.
- **Hint support**: per-tab hints, with automatic fallback to the caption; scroll and add button hints are configurable.
- **Batch update**: `BeginUpdate`/`EndUpdate` suppress layout recalculation and repaints during bulk operations.
- **Import from strings**: `ImportFromStrings` populates tabs from a `TStrings` instance, firing a single `OnTabCreated` event at the end rather than one per tab.
- **Design-time editor**: right-click the component in the Lazarus IDE to add, delete, or reorder tabs.
- **Multiplatform**: tested on Windows, Linux (GTK2/GTK3/Qt5), and macOS (Cocoa). Uses only LCL units; no platform-specific `{$IFDEF}` blocks.

---

## Installation

1. Copy `ExtTabCtrl.pas` (and `ExtTabCtrl.lrs` if you use the built-in glyphs) into your project or a shared component directory.
2. In the Lazarus IDE, open **Package → Open Package File** and add the unit, or simply add the unit path to your project's search path.
3. If installing as a package, call `Register` (already present in the unit) and rebuild the IDE.
4. The component will appear in the **Common Controls** tab of the component palette.

---

## Quick Start

```pascal
var
  TabCtrl: TExtTabCtrl;
begin
  TabCtrl := TExtTabCtrl.Create(Self);
  TabCtrl.Parent  := Self;
  TabCtrl.Align   := alTop;
  TabCtrl.TabStyle := tsChrome;
  TabCtrl.TabPosition := tpTop;

  TabCtrl.AddTab('First');
  TabCtrl.AddTab('Second');
  TabCtrl.AddTab('Third');

  TabCtrl.TabIndex := 0;
end;
```

---

## Key Properties

| Property | Type | Description |
|---|---|---|
| `TabStyle` | `TTabStyle` | Visual style: `tsFlat`, `tsButton`, `tsDelphi`, `tsChrome`, `tsMacOS` |
| `TabPosition` | `TTabPosition` | Where tabs are drawn: `tpTop`, `tpBottom`, `tpLeft`, `tpRight` |
| `TabSize` | `Integer` | Thickness of the tab strip in pixels (before DPI scaling) |
| `TabIndex` | `Integer` | Index of the currently active tab (`-1` = none) |
| `TabOptions` | `TExtTabOptions` | Set of feature flags (see below) |
| `Tabs` | `TExtTabs` | The collection of `TExtTab` items |
| `Images` | `TCustomImageList` | Optional image list for tab icons |
| `AddMenu` | `TPopupMenu` | Menu shown when the Add button is clicked |

### `TExtTabOptions` flags

| Flag | Effect |
|---|---|
| `toActivateNewTab` | Newly added tabs become active immediately |
| `toShowCloseButton` | Show a close button on tabs |
| `toShowAddButton` | Show the Add button at the end of the tab strip |
| `toCloseOnMiddleClick` | Middle-click closes a tab |
| `toAllowDragReorder` | Tabs can be reordered by dragging |
| `toRotateTabImages` | Rotate image-list images for vertical tabs |
| `toRotateAddImage` | Rotate the Add button glyph for vertical tabs |

---

## Key Events

| Event | When fired |
|---|---|
| `OnTabCreating` | Before a new tab is added; allows cancellation and caption/data override |
| `OnTabCreated` | After a tab (or batch import) is complete |
| `OnTabDeleting` | Before a tab is deleted; allows cancellation |
| `OnTabDeleted` | After a tab has been deleted |
| `OnTabChanging` | Before the active tab changes; allows cancellation |
| `OnTabChange` | After the active tab changes |
| `OnTabClick` | Single left-click on a tab |
| `OnTabDblClick` | Double-click on a tab |
| `OnTabReordering` | Before a drag-reorder is applied; allows cancellation |
| `OnTabReordered` | After a drag-reorder is complete |

---

## Per-Tab Properties (`TExtTab`)

| Property | Type | Description |
|---|---|---|
| `Caption` | `TCaption` | Tab label |
| `Color` | `TColor` | Accent stripe colour (`clNone` = no stripe) |
| `Visible` | `Boolean` | Hide/show without deleting |
| `Hint` | `String` | Tooltip; falls back to `Caption` if empty |
| `ImageIndex` | `Integer` | Index into the control's `Images` list |
| `Image` | `TBitmap` | Standalone bitmap (used when no `Images` list is set) |
| `Value` | `String` | Arbitrary string payload |
| `Data` | `TObject` | Arbitrary object payload (not owned by the tab) |
| `FontOptions` | `TExtFontOptions` | Per-tab font size and style overrides |

---

## Notes on `Data` Ownership

The `Data: TObject` property is a non-owning reference. The component will **never** free the object stored there. It is the caller's responsibility to manage the lifetime of any object assigned to `Data`.

---

## License

This component is released under the **GNU General Public License v2 or later (GPL-2.0-or-later)**.

You are free to use, study, modify, and redistribute it under the terms of the GPL. If you distribute a modified version, you must do so under the same license.

See [https://www.gnu.org/licenses/gpl-2.0.html](https://www.gnu.org/licenses/gpl-2.0.html) for the full license text.

> **Note for application developers:** the GPL requires that applications linking this component also be released under a GPL-compatible license. If you need to use this component in a closed-source application, you would need to relicense it separately with the author's permission.
