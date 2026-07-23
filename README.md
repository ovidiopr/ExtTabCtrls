# ExtTabCtrl [ExtPageCtrl](EXTPAGECTRL.md)

A feature-rich custom tab control for [Lazarus](https://www.lazarus-ide.org/) / Free Pascal, including Chrome, MacOS, and Delphi styles with drag-reordering and vertical orientation support. It can be used as a replacement for `TPageControl` and `TTabControl`.

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
- **Custom tab painting**: the `OnDrawTab` event lets you fully replace the built-in style rendering for the tab background/border while the control still draws the caption, image, and close button on top.
- **Per-tab properties**: each tab (`TExtTab`) has `Caption`, `Color` (tab background), `StripeColor` (accent stripe), `Visible`, `Hint`, `ImageIndex`, `Image` (standalone bitmap), `Value` (string), `Data` (object), `ShowCloseButton`, and per-tab `FontOptions`.
- **Image list support**: link a `TCustomImageList` via the `Images` property; images are drawn alongside tab captions and optionally rotated for vertical tabs.
- **Multi-resolution icon selection**: `ImagesWidth` lets you pick which resolution variant of a multi-resolution `ImageList` is used for each individual glyph (scroll, add, close, tab icons), useful for crisp HiDPI rendering.
- **Hint support**: per-tab hints, with automatic fallback to the caption; scroll and add button hints are configurable via `ButtonHints`.
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
| `ButtonImageIndexes` | `TButtonImageIndexes` | Selects specific `ImageList` indices for the scroll Prev/Next, Add, and Close buttons |
| `ImagesWidth` | `TImagesWidth` | Selects which resolution variant of a multi-resolution `ImageList` to use for each glyph/tab icon |
| `ButtonHints` | `TButtonHints` | Customizes hints for the Add and Scroll navigation buttons |
| `BorderColor` | `TColor` | Color of the tab strip border / strip-line separating tabs from the page area |
| `MinCaptionLen` | `Integer` | Minimum number of characters for a caption (the text is padded with spaces to complete this length) |
| `MaxCaptionLen` | `Integer` | Maximum caption length before truncation (with ellipsis) is applied |
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
| `toGetFocus` | Allows the control to receive keyboard focus via Tab or click |
| `toShowFocusRect` | Draws a focus rectangle around the active tab text when focused |
| `toActiveBold` | Renders the active tab's caption in a bold font |
| `toActiveItalic` | Renders the active tab's caption in an italic font |

### `TButtonImageIndexes` (the `ButtonImageIndexes` property)

| Property | Description |
|---|---|
| `ScrollPrevIndex` | Index into `ImageList` used for the "scroll to previous tab" button (`-1` = use a drawn default) |
| `ScrollNextIndex` | Index into `ImageList` used for the "scroll to next tab" button |
| `AddIndex` | Index into `ImageList` used for the Add button |
| `CloseIndex` | Index into `ImageList` used for the per-tab close button |

### `TImagesWidth` (the `ImagesWidth` property)

Each value below refers to the "Width" key of a multi-resolution `TCustomImageList` (i.e. which registered resolution to pick for that glyph):

| Property | Description |
|---|---|
| `PrevWidth` | Resolution used for the scroll-previous button glyph |
| `NextWidth` | Resolution used for the scroll-next button glyph |
| `AddWidth` | Resolution used for the Add button glyph |
| `CloseWidth` | Resolution used for the close button glyph |
| `TabsWidth` | Resolution used for per-tab `ImageIndex` icons |

### `TButtonHints` (the `ButtonHints` property)

| Property | Description |
|---|---|
| `AddHint` | Hint text for the Add button |
| `ScrollPrevHint` | Hint text for the scroll-previous button |
| `ScrollNextHint` | Hint text for the scroll-next button |
| `CloseHint` | Hint text for the per-tab close button |

---

## Keyboard Navigation

When the component has keyboard focus (via Tab key or by clicking), the following keys are supported:

| Key | Action |
|---|---|
| `Left Arrow` / `Up Arrow` | Select the previous visible tab (or next in RTL mode) |
| `Right Arrow` / `Down Arrow` | Select the next visible tab (or previous in RTL mode) |
| `Home` | Select the first visible tab |
| `End` | Select the last visible tab |
| `Mouse Wheel` (scroll up/down) | Select the previous/next visible tab |

---

## Key Events

| Event | When fired |
|---|---|
| `OnAddButtonClick` | Click on the add button |
| `OnImportTab` | After a new tab is imported from a TStrings |
| `OnTabCreating` | Before a new tab is added; allows cancellation and caption/data override |
| `OnTabCreated` | After a tab (or batch import) is complete |
| `OnTabDeleting` | Before a tab is deleted; allows cancellation |
| `OnTabDeleted` | After a tab has been deleted |
| `OnTabChanging` | Before the active tab changes; allows cancellation |
| `OnTabChanged` | After the active tab changes |
| `OnTabClick` | Single left-click on a tab |
| `OnTabDblClick` | Double-click on a tab |
| `OnTabReordering` | Before a drag-reorder is applied; allows cancellation |
| `OnTabReordered` | After a drag-reorder is complete |
| `OnMouseEnterTab` | The mouse pointer enters the bounds of a tab |
| `OnMouseLeaveTab` | The mouse pointer leaves the bounds of a tab |
| `OnGetFocus` | The control receives keyboard focus |
| `OnLostFocus` | The control loses keyboard focus |
| `OnDrawTab` | Replaces the built-in style drawing for a tab's background/border; receives the canvas, tab rectangle, active/hover state, and `var` `FontColor`/`Indent` parameters so you can still influence how the caption and stripe line are subsequently drawn |
| `OnDrawButton` | Custom drawing for control buttons (scroll prev/next, add, close); receives canvas, button rectangle, button type, associated tab (if any), active/hover state, and a `var Skip` parameter to override the default drawing. Image drawing order: 1. `TImageList`, 2. Custom method (this event), 3. Internal method |

---

## Public Methods

| Method | Description |
|---|---|
| `AddTab(const ACaption: String; AData: TObject = nil): TExtTab` | Adds a new tab, firing `OnTabCreating`/`OnTabCreated` |
| `DeleteTab(Index: Integer)` | Removes a tab, automatically selecting a sensible replacement active tab and firing the relevant `OnTabDeleting`/`OnTabDeleted`/`OnTabChanging`/`OnTabChanged` events |
| `ImportFromStrings(Source: TStrings; ClearExisting: Boolean = True)` | Bulk-creates tabs from a `TStrings` instance, firing a single `OnTabCreated` at the end rather than once per tab |
| `BeginUpdate` / `EndUpdate` | Suppress layout recalculation and repaints while making several changes; call in matching pairs |
| `IsVertical: Boolean` | Returns `True` when `TabPosition` is `tpLeft` or `tpRight` |
| `IsHorizontal: Boolean` | Returns `True` when `TabPosition` is `tpTop` or `tpBottom` |
| `NextVisibleTab(FromIndex: Integer): Integer` | Returns the index of the next `Visible` tab after `FromIndex`, or `-1` if none |
| `PrevVisibleTab(FromIndex: Integer): Integer` | Returns the index of the previous `Visible` tab before `FromIndex`, or `-1` if none |
| `InvalidateLayout` | Marks the tab layout as dirty and forces a recalculation/repaint |
| `SetDesignTabIndex(AValue: Integer)` | Lightweight tab switch intended for design-time/component-tree use; updates `TabIndex` without firing `OnTabChanging`/`OnTabChanged` |

---

## Design-Time Usage

When using `TExtTabCtrl` in the Lazarus IDE:

- **Selecting tabs**: Click directly on a tab in the designer to select it and preview its properties.
- **Adding tabs**: Right-click the component in the designer and select "Add Tab" to create a new tab.
- **Editing tabs**: Double-click a tab in the designer to open the collection editor, where you can add, delete, and reorder tabs.
- **Reordering tabs**: In the collection editor, use the arrow buttons to move tabs up or down the list, or drag tabs within the editor.
- **Properties panel**: Select individual tabs in the collection editor to edit their properties (Caption, Hint, Color, etc.) in the Object Inspector.
- **Quick preview**: Use the `TabIndex` property in the Object Inspector to switch between tabs and preview how the control looks at design time.

### Known Lazarus Designer Issue

When clicking on tabs at design time, a selection rectangle may appear around the component. This is a known Lazarus designer bug ([https://gitlab.com/freepascal.org/lazarus/lazarus/-/work_items/41825](https://gitlab.com/freepascal.org/lazarus/lazarus/-/work_items/41825)) that will be fixed in Lazarus 5.0 and will be included in an eventual Lazarus 4.10 maintenance release.

**Manual fix (if needed):** Edit `designer/designer.pp` and replace:
```pascal
TControlAccess(MouseDownComponent).MouseUp(Button, Shift, p.X, p.Y);
Exit;
```
with:
```pascal
TControlAccess(MouseDownComponent).MouseUp(Button, Shift, p.X, p.Y);
MouseDownComponent:=nil;
MouseDownSender:=nil;
Exit;
```

---

## Per-Tab Properties (`TExtTab`)

| Property | Type | Description |
|---|---|---|
| `Caption` | `TCaption` | Tab label |
| `Color` | `TColor` | Tab background color (`clNone` = default color) |
| `StripeColor` | `TColor` | Accent stripe color (`clNone` = no stripe) |
| `Visible` | `Boolean` | Hide/show without deleting |
| `Hint` | `String` | Tooltip; falls back to `Caption` if empty |
| `ImageIndex` | `Integer` | Index into the control's `ImageList` |
| `Image` | `TBitmap` | Standalone bitmap (used when no `ImageList` is set) |
| `Value` | `String` | Arbitrary string payload |
| `Data` | `TObject` | Arbitrary object payload (not owned by the tab) |
| `ShowCloseButton` | `Boolean` | Toggles the close button visibility specifically for this tab (`True` by default) |
| `FontOptions` | `TExtFontOptions` | Per-tab font size and style overrides |

### `TExtFontOptions` (the `FontOptions` property)

| Property | Description |
|---|---|
| `FontSize` | Overrides the tab's font size; `0` means "use the control's `Font.Size`" |
| `FontColor` | Overrides the tab's font color; `clNone` means "use the default/active color" |
| `FontStyles` | Overrides the tab's font styles (bold, italic, etc.) |

---

## Notes on `Data` Ownership

The `Data: TObject` property is a non-owning reference. The component will **never** free the object stored there. It is the caller's responsibility to manage the lifetime of any object assigned to `Data`.

---

## Screenshots

![macOS Style](images/Screenshot01.png)
![Flat Style](images/Screenshot02.png)
![Custom Style, with images on Tabs](images/Screenshot03.png)
![Chrome Style, dark theme](images/Screenshot04.png)
![Chrome Style, coupled with a TNotebook](images/Screenshot05.png)

## License

This component is released under the **GNU Lesser General Public License v2.1 or later (LGPL-2.1-or-later)**.

You are free to use, study, modify, and redistribute it under the terms of the LGPL. If you distribute a modified version of this library component, you must do so under the same license.

See [https://www.gnu.org/licenses/lgpl-2.1.html](https://www.gnu.org/licenses/lgpl-2.1.html) for the full license text.

> **Note for application developers:** `ExtTabCtrl` is licensed under the LGPL with the same linking exception as `Free Pascal` and `Lazarus`. This allows the component to be linked into commercial and closed-source applications without disclosing your overall application's source code. Only modifications made directly to the `ExtTabCtrl` library itself must remain open source under the LGPL.
