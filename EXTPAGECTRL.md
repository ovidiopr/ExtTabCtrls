# [ExtTabCtrl](README.md) ExtPageCtrl

`TExtPageCtrl` pairs the `TExtTabCtrl` tab strip with an actual content page per tab — a drop-in alternative to `TPageControl`. It's built on top of `TExtTabCtrl`, so everything in the main [README](README.md) (tab styles, positions, images, close/add buttons, scrolling, drag-reorder, keyboard navigation, `OnDrawTab`/`OnDrawButton`, etc.) still applies. This document only covers what's specific to the page control.

---

## What it adds over `TExtTabCtrl`

- **A real page per tab**: each tab automatically owns a `TExtPage` — a `TCustomControl` that hosts whatever you drop onto it at design time or create at runtime. You never manage the pages' visibility, sizing, or z-order yourself.
- **Drop-to-active-page**: at design time, controls dropped anywhere on the page control land on the currently active page, not on the page control itself.
- **Design-time editor verbs**: right-click the component for **Add Page**, **Delete Page**, and **Move Left/Right** (or **Up/Down** for vertical tab positions).
- **`PageIndex` picker**: in the Object Inspector, `PageIndex` shows a dropdown of `index - caption` instead of a bare integer.
- **Per-page `Tab` properties**: each `TExtPage` exposes its own `Tab` (a `TExtTab`) so you can set `Tab.Caption`, `Tab.Color`, `Tab.StripeColor`, `Tab.ImageIndex`, `Tab.ShowCloseButton`, `Tab.Visible`, and `Tab.Hint` right on the page in the Object Inspector, without going through the collection editor.
- **`OnBeforeShow`**: per-page event fired just before that page becomes the visible one — useful for lazy-loading content.

---

## Quick Start

```pascal
var
  PageCtrl: TExtPageCtrl;
  Page1, Page2: TExtPage;
begin
  PageCtrl := TExtPageCtrl.Create(Self);
  PageCtrl.Parent := Self;
  PageCtrl.Align  := alClient;
  PageCtrl.TabStyle := tsChrome;

  Page1 := PageCtrl.AddPage('First');
  TButton.Create(Page1).Parent := Page1; // dropped straight onto the page

  Page2 := PageCtrl.AddPage('Second');
  Page2.Tab.StripeColor := clRed;

  PageCtrl.PageIndex := 0;
end;
```

---

## Key Properties (`TExtPageCtrl` / `TCustomExtPageCtrl`)

| Property | Type | Description |
|---|---|---|
| `PageIndex` | `Integer` | Index of the active page (`-1` = none). Kept in sync with the underlying `TabIndex`. |
| `ActivePage` | `TExtPage` | The currently active page, or `nil` if `PageIndex` is `-1` |
| `Page[Index: Integer]` | `TExtPage` | Read-only indexed access to a page |
| `PageCount` | `Integer` | Number of pages |

All other published properties (`TabStyle`, `TabPosition`, `TabSize`, `TabOptions`, `Images`, `ButtonImageIndexes`, `ImagesWidth`, `ButtonHints`, `BorderColor`, `MinCaptionLen`, `MaxCaptionLen`, `AddMenu`, etc.) are the same ones documented in the main README and behave identically — they control the tab strip, not the pages.

---

## Public Methods

| Method | Description |
|---|---|
| `AddPage(const ACaption: String): TExtPage` | Creates a new tab and its linked page, fires `OnPageAdded`, and returns the page |
| `DeletePage(Index: Integer)` | Removes the page and its tab, firing `OnPageDeleting`/the base `OnTabDeleting`/`OnTabDeleted` events |
| `MovePage(OldIndex, NewIndex: Integer)` | Reorders a page (and its tab) to a new position |
| `IndexOfPage(APage: TExtPage): Integer` | Returns the index of a given page, or `-1` if not found |

`AddTab`/`DeleteTab` are also available (inherited from `TExtTabCtrl`) and behave as thin wrappers: `AddTab` creates a page and returns its `Tab`; `DeleteTab` deletes the page at that index.

---

## Key Events

| Event | When fired |
|---|---|
| `OnPageAdded` | After `AddPage` creates a new page |
| `OnPageDeleting` | Before a page is deleted; observe (not cancel) via this event, or cancel via the base `OnTabDeleting` |
| `OnBeforeShow` *(on `TExtPage`, not the page control)* | Just before this specific page becomes the active/visible one |

All tab-level events from the base control (`OnTabChanging`, `OnTabChanged`, `OnTabCreating`, `OnTabCreated`, `OnTabClick`, etc.) still fire normally — `PageIndex` and `TabIndex` are kept in sync internally.

---

## `TExtPage`

Each page is a `TCustomControl` automatically created, parented, sized (`Align = alClient`, inset for the tab strip), and destroyed by the page control. You don't create or free pages yourself — use `AddPage`/`DeletePage`.

| Property | Type | Description |
|---|---|---|
| `PageIndex` | `Integer` | This page's current index within the page control (read-only) |
| `Tab` | `TExtTab` | The tab linked to this page — set `Tab.Caption`, `Tab.Color`, `Tab.StripeColor`, `Tab.ImageIndex`, `Tab.ShowCloseButton`, `Tab.Visible`, `Tab.Hint` directly here instead of via the tab collection editor |
| `Color`, `ChildSizing`, `Enabled`, `Font`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint` | *(as usual)* | Standard `TCustomControl` properties, published for convenience |
| `OnBeforeShow` | `TBeforeShowExtPageEvent` | `procedure(ASender: TObject; ANewPage: TExtPage; ANewIndex: Integer) of object` — fires right before this page is shown |

`Left`, `Top`, `Width`, `Height`, `Align`, `Visible`, and `Caption` are present (inherited) but not stored/editable — the page control manages layout and visibility for you, and `Tab.Caption` is what actually appears on the tab.

---

## Design-Time Usage

- **Adding a page**: right-click the page control in the designer → **Add Page**.
- **Deleting a page**: select it (click its tab), right-click → **Delete Page**.
- **Reordering**: right-click → **Move Left**/**Move Right** (or **Move Up**/**Move Down** when `TabPosition` is `tpLeft`/`tpRight`).
- **Selecting a page's controls**: click a tab to activate that page, then drop or select controls on it as you would on a panel.
- **Switching pages via the Object Inspector**: set `PageIndex` — it's shown as a dropdown of `index - caption` rather than a plain number.
- Pages themselves (`TExtPage`) don't appear in the component palette (`RegisterNoIcon`) and aren't meant to be created or deleted directly — always go through the page control's verbs or `AddPage`/`DeletePage`.

This inherits the same [known Lazarus designer selection-rectangle issue](README.md#known-lazarus-designer-issue) documented for `TExtTabCtrl`.

---

## Notes

- **Ownership**: pages are owned by the page control's `Owner` (typically your form/frame/datamodule), not by the page control itself — this matches how `TPageControl`/`TTabSheet` work in the VCL/LCL, and is what makes them show up correctly in the `.lfm` and the component tree.
- **`AddTab`/`DeleteTab` compatibility**: if you're migrating code that talks to a plain `TExtTabCtrl`, `TExtPageCtrl` still answers to `AddTab`/`DeleteTab`, so most tab-management code keeps working unchanged — you just also get a `TExtPage` per tab for free.
