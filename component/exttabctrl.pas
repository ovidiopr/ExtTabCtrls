unit ExtTabCtrl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Buttons, LCLType, Types, Math,
  LResources, LCLIntf, GraphUtil, ImgList, LMessages, Forms, Menus,
  ComponentEditors, PropEdits, IntfGraphics;

type
  TTabPosition = (tpTop, tpBottom, tpLeft, tpRight);

  TTabStyle = (tsFlat, tsButton, tsDelphi, tsChrome, tsMacOS);

  TExtTabOption = (toActivateNewTab, toShowCloseButton, toShowAddButton,
                   toCloseOnMiddleClick, toAllowDragReorder,
                   toRotateTabImages, toRotateAddImage, toGetFocus,
                   toShowFocusRect, toActiveBold, toActiveItalic);
  TExtTabOptions = set of TExtTabOption;

  TExtTab = class;

  TTabCreatingEvent = procedure(Sender: TObject; var Caption: String; var Data: TObject; var Allow: Boolean) of object;
  TTabIndexAllowEvent = procedure(Sender: TObject; Index: Integer; var Allow: Boolean) of object;
  TTabChangedEvent = procedure(Sender: TObject; NewIndex: Integer) of object;
  TTabChangingEvent = procedure(Sender: TObject; OldIndex, NewIndex: Integer; var Allow: Boolean) of object;
  TTabReorderedEvent = procedure(Sender: TObject; OldIndex, NewIndex: Integer) of object;
  TTabReorderingEvent = procedure(Sender: TObject; OldIndex, NewIndex: Integer; var Allow: Boolean) of object;
  TTabClickEvent = procedure(Sender: TObject; Index: Integer) of object;
  TTabImportEvent = procedure(Sender: TObject; Tab: TExtTab; AObject: TObject) of object;
  TButtonClickEvent = procedure(Sender: TObject) of object;

  TButtonImages = class(TPersistent)
  private
    FPrevImageIndex: Integer;
    FNextImageIndex: Integer;
    FAddImageIndex: Integer;
    FOnChange: TNotifyEvent;
    procedure SetIndex(Index: Integer; Value: Integer);
  public
    constructor Create;
    procedure Assign(Source: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property PrevImageIndex: Integer index 0 read FPrevImageIndex write SetIndex default -1;
    property NextImageIndex: Integer index 1 read FNextImageIndex write SetIndex default -1;
    property AddImageIndex: Integer index 2 read FAddImageIndex write SetIndex default -1;
  end;

  TButtonHints = class(TPersistent)
  private
    FAddHint: String;
    FScrollPrevHint: String;
    FScrollNextHint: String;
  public
    procedure Assign(Source: TPersistent); override;
  published
    property AddHint: String read FAddHint write FAddHint;
    property ScrollPrevHint: String read FScrollPrevHint write FScrollPrevHint;
    property ScrollNextHint: String read FScrollNextHint write FScrollNextHint;
  end;

  TExtFontOptions = class(TPersistent)
  private
    FFontSize: Integer;
    FFontStyles: TFontStyles;
    FOnRedraw: TNotifyEvent;
    procedure SetFontSize(AValue: Integer);
    procedure SetFontStyles(AValue: TFontStyles);
  protected
    procedure Changed;
  public
    constructor Create;
    procedure Assign(Source: TPersistent); override;
  published
    property FontSize: Integer read FFontSize write SetFontSize default 0;
    property FontStyles: TFontStyles read FFontStyles write SetFontStyles default [];
    property OnRedraw: TNotifyEvent read FOnRedraw write FOnRedraw;
  end;

  TExtTabCtrl = class;

  TExtTab = class(TCollectionItem)
  private
    FCaption: TCaption;
    FColor: TColor;
    FVisible: Boolean;
    FValue: String;
    FData: TObject;
    FFontOptions: TExtFontOptions;
    FOwnerCtrl: TExtTabCtrl;
    FImage: TBitmap;
    FImageIndex: Integer;
    FHint: String;
    FShowCloseButton: Boolean;
    FTextWidth: Integer;
    FTextHeight: Integer;
    FCachedTabImage: TBitmap;
    FCachedImageRotation: Integer;
    procedure SetCaption(AValue: TCaption);
    procedure SetColor(AValue: TColor);
    procedure SetVisible(AValue: Boolean);
    procedure SetImage(AValue: TBitmap);
    function  GetImage: TBitmap;
    procedure Redraw(Sender: TObject);
  protected
    FBoundRect: TRect;
    function GetDisplayName: String; override;
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
    property BoundRect: TRect read FBoundRect;
  published
    property Caption: TCaption read FCaption write SetCaption;
    property Color: TColor read FColor write SetColor default clNone;
    property Visible: Boolean read FVisible write SetVisible default True;
    property Value: String read FValue write FValue;
    property Data: TObject read FData write FData;
    property FontOptions: TExtFontOptions read FFontOptions;
    property Image: TBitmap read GetImage write SetImage;
    property ImageIndex: Integer read FImageIndex write FImageIndex default -1;
    property Hint: String read FHint write FHint;
    property ShowCloseButton: Boolean read FShowCloseButton write FShowCloseButton default True;
  end;

  TExtTabs = class(TCollection)
  private
    FOwnerCtrl: TExtTabCtrl;
    function GetItems(Index: Integer): TExtTab;
  protected
    procedure Update(Item: TCollectionItem); override;
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TExtTabCtrl);
    function Add(const ACaption: String): TExtTab;
    property Items[Index: Integer]: TExtTab read GetItems; default;
  end;

  TExtTabCtrl = class(TCustomControl)
  private
    FAutoSizeTabs: Boolean;
    FUpdateCount: Integer;
    FLayoutDirty: Boolean;
    FUpdatingButtons: Boolean;
    FTabSize: Integer;
    FTotalTabsSize: Integer;
    FTabs: TExtTabs;
    FTabIndex: Integer;
    FTabStyle: TTabStyle;
    FTabOptions: TExtTabOptions;
    FBtnAdd: TSpeedButton;
    FAddImage, FCloseImage: TBitmap;

    FImages: TCustomImageList;
    FButtonImages: TButtonImages;
    FButtonHints: TButtonHints;

    FDragging: Boolean;
    FDragIndex, FDragTargetIndex: Integer;
    FMouseDownPos: TPoint;
    FMouseDownIndex: Integer;

    FTabPosition: TTabPosition;
    FOnTabCreating: TTabCreatingEvent;
    FOnTabCreated: TNotifyEvent;
    FOnTabDeleting: TTabIndexAllowEvent;
    FOnTabDeleted: TNotifyEvent;
    FOnTabChanging: TTabChangingEvent;
    FOnTabChanged: TTabChangedEvent;
    FOnTabReordering: TTabReorderingEvent;
    FOnTabReordered: TTabReorderedEvent;
    FOnTabClick: TTabClickEvent;
    FOnTabDblClick: TTabClickEvent;
    FOnImportTab: TTabImportEvent;
    FOnAddButtonClick: TButtonClickEvent;

    FScrollOffset: Integer;
    FHoverTab, FHoverCloseTab: Integer;
    FBtnScrollPrev, FBtnScrollNext: TSpeedButton;
    FScrollImages: array[0..1] of TBitmap;

    FCachedAddGlyph: TBitmap;
    FCachedScrollGlyphs: array[0..1] of TBitmap;
    FLastRotation: Integer;
    FAddTabCounter: Integer;
    FImportActive: Boolean;
    FInternalChange: Integer;

    procedure BeginInternalChange;
    procedure EndInternalChange;
    procedure NormalizeState;
    procedure CancelDrag;
    procedure ClearGlyphCache;
    procedure RefreshGlyphCache;
    procedure InvalidateTabImageCaches;

    procedure SetTabIndex(AValue: Integer);
    procedure SetTabSize(AValue: Integer);
    procedure AddBtnClick(Sender: TObject);
    procedure ScrollPrev(Sender: TObject);
    procedure ScrollNext(Sender: TObject);

    procedure SetTabStyle(AValue: TTabStyle);
    procedure SetTabPosition(AValue: TTabPosition);
    procedure SetTabOptions(AValue: TExtTabOptions);
    procedure SetImages(AValue: TCustomImageList);
    procedure SetButtonImages(AValue: TButtonImages);
    procedure SetButtonHints(AValue: TButtonHints);
    procedure SetTabs(AValue: TExtTabs);

    procedure SetAddMenu(AValue: TPopupMenu);
    function GetAddMenu: TPopupMenu;

    procedure ButtonImagesChanged(Sender: TObject);
    function TabsViewportRect: TRect;
    procedure UpdateButtonLayout;
    function IsVertical: Boolean;
    function IsHorizontal: Boolean;
    function CloseButtonRect(Tab: TExtTab): TRect;
    function TabAtPos(X, Y: Integer): Integer;
    procedure LoadBitmapFromLRS(const ResName: String; DestBitmap: TBitmap);
    function MaxScrollOffset: Integer;
    procedure EnsureTabVisible(Index: Integer);
    procedure UpdateScrollButtons;
    function GetScale(Value: Integer): Integer;
    procedure DrawTabTextAndImage(ACanvas: TCanvas; const R: TRect; Tab: TExtTab; IsActive: Boolean);
    procedure DrawCloseButton(ACanvas: TCanvas; const R: TRect; Tab: TExtTab; IsActive: Boolean);
    procedure DrawColorStripe(ACanvas: TCanvas; const R: TRect; Tab: TExtTab);

    procedure DrawTabImage(ACanvas: TCanvas; Tab: TExtTab; X, Y: Integer);
    procedure DrawRotatedText(ACanvas: TCanvas; const S: String; const R: TRect; Degrees: Integer);
    function GetRotationForPosition: Integer;
    function HasAnyImage(Tab: TExtTab): Boolean;
    function GetTabImageWidth(Tab: TExtTab): Integer;
    function GetTabImageHeight(Tab: TExtTab): Integer;
    function GetTabTextBounds(ACanvas: TCanvas; const R: TRect; Tab: TExtTab): TRect;
    procedure GetBaseTabBitmap(Tab: TExtTab; Dest: TBitmap);
  protected
  const
    cContentIndent = 6;
    cTabOverlap = 2;
    cImageSpacing = 6;
    cDragThreshold = 6;

    class function GetControlClassDefaultSize: TSize; override;
    procedure SetAutoSizeTabs(AValue: Boolean);

    procedure Paint; override;
    procedure Resize; override;
    procedure CalcLayout;

    procedure DrawFlatTab(ACanvas: TCanvas; R: TRect; IsActive: Boolean; Tab: TExtTab);
    procedure DrawButtonTab(ACanvas: TCanvas; R: TRect; IsActive: Boolean; Tab: TExtTab);
    procedure DrawDelphiTab(ACanvas: TCanvas; R: TRect; IsActive: Boolean; Tab: TExtTab);
    procedure DrawChromeTab(ACanvas: TCanvas; R: TRect; IsActive: Boolean; Tab: TExtTab);
    procedure DrawMacOSTab(ACanvas: TCanvas; R: TRect; IsActive: Boolean; Tab: TExtTab);
    procedure DrawTab(ACanvas: TCanvas; Index: Integer; ARect: TRect; IsActive: Boolean);

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
    procedure DblClick; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;

    procedure DoEnter; override;
    procedure DoExit; override;

    procedure WMLMGetDlgCode(var Message: TLMessage); message LM_GETDLGCODE;

    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure CalculatePreferredSize(var PreferredWidth, PreferredHeight: Integer; WithImplicitConstraints: Boolean); override;
    procedure CMShowHintChanged(var Message: TLMessage); message CM_SHOWHINTCHANGED;
    procedure CMFontChanged(var Message: TLMessage); message CM_FONTCHANGED;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure InvalidateLayout;
    function  NextVisibleTab(FromIndex: Integer): Integer;
    function  PrevVisibleTab(FromIndex: Integer): Integer;
    function AddTab(const ACaption: String; AData: TObject = nil): TExtTab;
    procedure DeleteTab(Index: Integer);
    procedure ImportFromStrings(Source: TStrings; ClearExisting: Boolean = True);
    procedure SetDesignTabIndex(AValue: Integer);
  published
    property Align;
    property BorderSpacing;
    property Color default clForm;
    property DoubleBuffered;
    property AutoSizeTabs: Boolean read FAutoSizeTabs write SetAutoSizeTabs default False;
    property Tabs: TExtTabs read FTabs write SetTabs;
    property TabIndex: Integer read FTabIndex write SetTabIndex default -1;
    property TabSize: Integer read FTabSize write SetTabSize default 26;
    property TabStyle: TTabStyle read FTabStyle write SetTabStyle default tsFlat;
    property TabOptions: TExtTabOptions read FTabOptions write SetTabOptions
                           default [toActivateNewTab, toShowCloseButton,
                                    toShowAddButton, toCloseOnMiddleClick,
                                    toAllowDragReorder, toGetFocus, toShowFocusRect];
    property TabPosition: TTabPosition read FTabPosition write SetTabPosition default tpTop;

    property ShowHint default True;
    property Font;
    property ParentFont;
    property ParentColor;

    property Images: TCustomImageList read FImages write SetImages;
    property ButtonImages: TButtonImages read FButtonImages write SetButtonImages;
    property ButtonHints: TButtonHints read FButtonHints write SetButtonHints;

    property AddMenu: TPopupMenu read GetAddMenu write SetAddMenu;

    property OnTabReordering: TTabReorderingEvent read FOnTabReordering write FOnTabReordering;
    property OnTabReordered: TTabReorderedEvent read FOnTabReordered write FOnTabReordered;
    property OnTabCreating: TTabCreatingEvent read FOnTabCreating write FOnTabCreating;
    property OnTabCreated: TNotifyEvent read FOnTabCreated write FOnTabCreated;
    property OnTabDeleting: TTabIndexAllowEvent read FOnTabDeleting write FOnTabDeleting;
    property OnTabDeleted: TNotifyEvent read FOnTabDeleted write FOnTabDeleted;
    property OnTabChanging: TTabChangingEvent read FOnTabChanging write FOnTabChanging;
    property OnTabChanged: TTabChangedEvent read FOnTabChanged write FOnTabChanged;
    property OnTabClick: TTabClickEvent read FOnTabClick write FOnTabClick;
    property OnTabDblClick: TTabClickEvent read FOnTabDblClick write FOnTabDblClick;
    property OnImportTab: TTabImportEvent read FOnImportTab write FOnImportTab;
    property OnAddButtonClick: TButtonClickEvent read FOnAddButtonClick write FOnAddButtonClick;
  end;

  TExtTabCtrlEditor = class(TComponentEditor)
  public
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): String; override;
    procedure ExecuteVerb(Index: Integer); override;
  end;

  // Property editor for TabIndex that also notifies the control to repaint
  // when the value is changed from the Object Inspector/component
  // tree, so the selected tab is visible at design time
  TTabIndexPropertyEditor = class(TIntegerPropertyEditor)
  public
    function  GetAttributes: TPropertyAttributes; override;
    function  GetValue: String; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const NewValue: String); override;
  end;

procedure Register;

implementation

{ Global Helpers }
procedure SwapIntegers(var A, B: Integer);
var
  Temp: Integer;
begin
  Temp := A;
  A := B;
  B := Temp;
end;

function BlendColors(C1, C2: TColor; Ratio: Single): TColor;
var
  R1, G1, B1, R2, G2, B2: Byte;
begin
  C1 := ColorToRGB(C1);
  C2 := ColorToRGB(C2);
  R1 := GetRValue(C1);
  G1 := GetGValue(C1);
  B1 := GetBValue(C1);
  R2 := GetRValue(C2);
  G2 := GetGValue(C2);
  B2 := GetBValue(C2);
  Result := RGB(Round(R1*(1 - Ratio) + R2*Ratio),
                Round(G1*(1 - Ratio) + G2*Ratio),
                Round(B1*(1 - Ratio) + B2*Ratio));
end;

procedure RotateBitmap(Source, Dest: TBitmap; Degrees: Integer);
var
  SrcIntf, DestIntf: TLazIntfImage;
  x, y: Integer;
begin
  if Source.Empty then Exit;
  SrcIntf := Source.CreateIntfImage;
  DestIntf := TLazIntfImage.Create(0, 0);
  try
    DestIntf.DataDescription := SrcIntf.DataDescription;
    if (Degrees = 90) or (Degrees = 270) then
      DestIntf.SetSize(SrcIntf.Height, SrcIntf.Width)
    else
      DestIntf.SetSize(SrcIntf.Width, SrcIntf.Height);

    case Degrees of
      90: // 90° clockwise: src(x,y) --> dest(Height-1-y, x)
        for y := 0 to SrcIntf.Height - 1 do
          for x := 0 to SrcIntf.Width - 1 do
            DestIntf.Colors[SrcIntf.Height - 1 - y, x] := SrcIntf.Colors[x, y];
      180:
        for y := 0 to SrcIntf.Height - 1 do
          for x := 0 to SrcIntf.Width - 1 do
            DestIntf.Colors[SrcIntf.Width - 1 - x, SrcIntf.Height - 1 - y] := SrcIntf.Colors[x, y];
      270: // 270° clockwise (= 90° CCW): src(x,y) --> dest(y, Width-1-x)
        for y := 0 to SrcIntf.Height - 1 do
          for x := 0 to SrcIntf.Width - 1 do
            DestIntf.Colors[y, SrcIntf.Width - 1 - x] := SrcIntf.Colors[x, y];
    else
      DestIntf.Assign(SrcIntf);
    end;
    Dest.LoadFromIntfImage(DestIntf);
  finally
    SrcIntf.Free;
    DestIntf.Free;
  end;
end;

{ TButtonImages }
constructor TButtonImages.Create;
begin
  FPrevImageIndex := -1;
  FNextImageIndex := -1;
  FAddImageIndex := -1;
end;

procedure TButtonImages.Assign(Source: TPersistent);
begin
  if Source is TButtonImages then
  begin
    FPrevImageIndex := TButtonImages(Source).PrevImageIndex;
    FNextImageIndex := TButtonImages(Source).NextImageIndex;
    FAddImageIndex := TButtonImages(Source).AddImageIndex;
    if Assigned(FOnChange) then FOnChange(Self);
  end
  else
    inherited Assign(Source);
end;

procedure TButtonImages.SetIndex(Index: Integer; Value: Integer);
var
  Ptr: ^Integer;
begin
  Ptr := nil;
  case Index of
    0: Ptr := @FPrevImageIndex;
    1: Ptr := @FNextImageIndex;
    2: Ptr := @FAddImageIndex;
  end;
  if Ptr = nil then Exit;
  if Ptr^ <> Value then
  begin
    Ptr^ := Value;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

{ TButtonHints }
procedure TButtonHints.Assign(Source: TPersistent);
begin
  if Source is TButtonHints then
  begin
    FAddHint := TButtonHints(Source).AddHint;
    FScrollPrevHint := TButtonHints(Source).ScrollPrevHint;
    FScrollNextHint := TButtonHints(Source).ScrollNextHint;
  end
  else
    inherited Assign(Source);
end;

{ TExtFontOptions }
procedure TExtFontOptions.SetFontSize(AValue: Integer);
begin
  if FFontSize <> AValue then
  begin
    FFontSize := AValue;
    Changed;
  end;
end;

procedure TExtFontOptions.SetFontStyles(AValue: TFontStyles);
begin
  if FFontStyles <> AValue then
  begin
    FFontStyles := AValue;
    Changed;
  end;
end;

procedure TExtFontOptions.Changed;
begin
  if Assigned(FOnRedraw) then FOnRedraw(Self);
end;

constructor TExtFontOptions.Create;
begin
  FFontSize := 0;
  FFontStyles := [];
end;

procedure TExtFontOptions.Assign(Source: TPersistent);
begin
  if Source is TExtFontOptions then
  begin
    FFontSize := TExtFontOptions(Source).FontSize;
    FFontStyles := TExtFontOptions(Source).FontStyles;
    Changed;
  end
  else
    inherited Assign(Source);
end;

{ TExtTab }
procedure TExtTab.SetCaption(AValue: TCaption);
begin
  if FCaption <> AValue then
  begin
    FCaption := AValue;
    FTextWidth := -1;
    FTextHeight := -1;
    Changed(False);
    Redraw(Self);
  end;
end;

procedure TExtTab.SetColor(AValue: TColor);
begin
  if FColor = AValue then Exit;
  FColor := AValue;
  if Assigned(FOwnerCtrl) then
    FOwnerCtrl.Invalidate;
end;

procedure TExtTab.SetVisible(AValue: Boolean);
var
  WasActive: Boolean;
  OldIndex, Candidate: Integer;
  Allow: Boolean;
begin
  if FVisible = AValue then Exit;
  if not Assigned(FOwnerCtrl) then
  begin
    FVisible := AValue;
    Exit;
  end;

  // If we just hid the active tab, route through SetTabIndex so that
  // OnTabChanging and OnTabChange fire normally
  WasActive := (not AValue) and (FOwnerCtrl.TabIndex = Self.Index);
  if WasActive then
  begin
    OldIndex := Self.Index;
    Candidate := FOwnerCtrl.NextVisibleTab(OldIndex);
    if Candidate = -1 then Candidate := FOwnerCtrl.PrevVisibleTab(OldIndex);
    // Fire OnTabChanging; if vetoed, keep the tab visible and abort
    Allow := True;
    if Assigned(FOwnerCtrl.FOnTabChanging) then
      FOwnerCtrl.FOnTabChanging(FOwnerCtrl, OldIndex, Candidate, Allow);
    if not Allow then Exit;
    FVisible := AValue;
    FOwnerCtrl.FTabIndex := Candidate;
    FOwnerCtrl.InvalidateLayout;
    if Assigned(FOwnerCtrl.FOnTabChanged) then
      FOwnerCtrl.FOnTabChanged(FOwnerCtrl, Candidate);
  end
  else
  begin
    FVisible := AValue;
    FOwnerCtrl.InvalidateLayout;
  end;
end;

function TExtTab.GetImage: TBitmap;
begin
  if FImage = nil then
    FImage := TBitmap.Create;
  Result := FImage;
end;

procedure TExtTab.SetImage(AValue: TBitmap);
begin
  if FImage = AValue then Exit;
  FreeAndNil(FImage);
  FreeAndNil(FCachedTabImage);
  FImage := AValue;
  FTextWidth := -1;
  Redraw(Self);
end;

procedure TExtTab.Redraw(Sender: TObject);
begin
  if Sender = FFontOptions then
  begin
    FTextWidth := -1;
    FTextHeight := -1;
  end;
  if Assigned(FOwnerCtrl) then FOwnerCtrl.InvalidateLayout;
end;

function TExtTab.GetDisplayName: String;
begin
  Result := FCaption;
  if Result = '' then
    Result := inherited GetDisplayName;
end;

constructor TExtTab.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);

  FOwnerCtrl := TExtTabs(ACollection).FOwnerCtrl;
  FFontOptions := TExtFontOptions.Create;
  FFontOptions.OnRedraw := @Redraw;
  FVisible := True;
  FColor := clNone;
  FImageIndex := -1;
  FTextWidth := -1;
  FTextHeight := -1;
  FCachedTabImage := nil;
  FCachedImageRotation := -1;
  FShowCloseButton := True;
  // Provide a default caption so new tabs are never empty
  FCaption := 'New Tab ' + IntToStr(Index + 1);
end;

destructor TExtTab.Destroy;
begin
  FImage.Free;
  FCachedTabImage.Free;
  FFontOptions.Free;
  inherited Destroy;
end;

{ TExtTabs }
function TExtTabs.GetItems(Index: Integer): TExtTab;
begin
  Result := TExtTab(inherited Items[Index]);
end;

procedure TExtTabs.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  if Assigned(FOwnerCtrl) then
  begin
    FOwnerCtrl.NormalizeState;
    FOwnerCtrl.InvalidateLayout;

    // Notify the IDE that the internal structure changed so it updates the Object Inspector
    if (csDesigning in FOwnerCtrl.ComponentState) and Assigned(GlobalDesignHook) then
    begin
      GlobalDesignHook.Modified(FOwnerCtrl);
      GlobalDesignHook.RefreshPropertyValues;
    end;
  end;
end;

function TExtTabs.GetOwner: TPersistent;
begin
  Result := FOwnerCtrl;
end;

constructor TExtTabs.Create(AOwner: TExtTabCtrl);
begin
  inherited Create(TExtTab);
  FOwnerCtrl := AOwner;
end;

function TExtTabs.Add(const ACaption: String): TExtTab;
begin
  Result := inherited Add as TExtTab;
  Result.Caption := ACaption;
end;

{ TExtTabCtrl - Private Methods }

procedure TExtTabCtrl.BeginInternalChange;
begin
  Inc(FInternalChange);
end;

procedure TExtTabCtrl.EndInternalChange;
begin
  if FInternalChange > 0 then Dec(FInternalChange);
end;

procedure TExtTabCtrl.CancelDrag;
begin
  if FDragging then
  begin
    FDragging := False;
    FDragIndex := -1;
    FDragTargetIndex := -1;
    FMouseDownIndex := -1;
    MouseCapture := False;
    Invalidate;
  end;
end;

procedure TExtTabCtrl.NormalizeState;
var
  Candidate: Integer;
begin
  // Clamp or fix FTabIndex
  if FTabs.Count = 0 then
    FTabIndex := -1
  else
  begin
    if FTabIndex >= FTabs.Count then
      FTabIndex := FTabs.Count - 1;
    // If active tab became invisible, move to nearest visible one
    if (FTabIndex >= 0) and not FTabs[FTabIndex].Visible then
    begin
      Candidate := NextVisibleTab(FTabIndex);
      if Candidate = -1 then Candidate := PrevVisibleTab(FTabIndex);
      FTabIndex := Candidate; // -1 if none visible at all
    end;
  end;

  // Clamp scroll offset
  if HandleAllocated then
    FScrollOffset := Max(0, Min(FScrollOffset, MaxScrollOffset))
  else
    FScrollOffset := Max(0, FScrollOffset);

  // Reset stale hover state
  if (FHoverTab >= FTabs.Count) then FHoverTab := -1;
  if (FHoverCloseTab >= FTabs.Count) then FHoverCloseTab := -1;

  // Cancel drag if indexes are now out of range
  if FDragging and
     ((FDragIndex < 0) or (FDragIndex >= FTabs.Count) or
      (FDragTargetIndex > FTabs.Count)) then
    CancelDrag;
end;

procedure TExtTabCtrl.ClearGlyphCache;
begin
  FCachedAddGlyph.Clear;
  FCachedScrollGlyphs[0].Clear;
  FCachedScrollGlyphs[1].Clear;
  FLastRotation := -1; // Invalidate rotation state
end;

procedure TExtTabCtrl.RefreshGlyphCache;
var
  TargetRotation: Integer;
  i: Integer;
begin
  TargetRotation := GetRotationForPosition;

  if (FLastRotation <> TargetRotation) or FCachedAddGlyph.Empty then
  begin
    FLastRotation := TargetRotation;

    if (toRotateAddImage in FTabOptions) and IsVertical then
      RotateBitmap(FAddImage, FCachedAddGlyph, TargetRotation)
    else
      FCachedAddGlyph.Assign(FAddImage);

    // For vertical layouts the horizontal glyphs need rotating
    for i := 0 to 1 do
      if IsVertical then
        RotateBitmap(FScrollImages[i], FCachedScrollGlyphs[i], 90)
      else
        FCachedScrollGlyphs[i].Assign(FScrollImages[i]);
  end;
end;

procedure TExtTabCtrl.InvalidateTabImageCaches;
var
  i: Integer;
begin
  for i := 0 to FTabs.Count - 1 do
  begin
    FreeAndNil(FTabs[i].FCachedTabImage);
    FTabs[i].FCachedImageRotation := -1;
  end;
end;

// Set an initial size when dropped onto a form by click
class function TExtTabCtrl.GetControlClassDefaultSize: TSize;
begin
  Result.cx := 300;
  Result.cy := 30;
end;

// AutoSizeTabs restricts the control to the tab-strip thickness
procedure TExtTabCtrl.SetAutoSizeTabs(AValue: Boolean);
begin
  if FAutoSizeTabs = AValue then Exit;
  FAutoSizeTabs := AValue;
  InvalidatePreferredSize;
  AdjustSize;
end;

function TExtTabCtrl.NextVisibleTab(FromIndex: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := FromIndex + 1 to FTabs.Count - 1 do
    if FTabs[i].Visible then Exit(i);
end;

function TExtTabCtrl.PrevVisibleTab(FromIndex: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := FromIndex - 1 downto 0 do
    if FTabs[i].Visible then Exit(i);
end;

procedure TExtTabCtrl.SetTabIndex(AValue: Integer);
var
  Allow: Boolean;
  Candidate: Integer;
begin
  if FInternalChange > 0 then Exit;
  if (AValue < -1) or (AValue >= FTabs.Count) then
    AValue := -1;

  // If target tab is invisible, find the nearest visible one
  if (AValue >= 0) and not FTabs[AValue].Visible then
  begin
    Candidate := NextVisibleTab(AValue);
    if Candidate = -1 then
      Candidate := PrevVisibleTab(AValue);
    AValue := Candidate;
  end;

  if FTabIndex = AValue then Exit;

  Allow := True;
  if Assigned(FOnTabChanging) then
  begin
    FOnTabChanging(Self, FTabIndex, AValue, Allow);
    if csDestroying in ComponentState then Exit;
    // Re-validate: user callback may have changed the collection
    if (AValue >= FTabs.Count) then AValue := -1;
  end;
  if not Allow then Exit;

  BeginInternalChange;
  try
    // If toActiveBold/Italic is on, the old and new active tabs are
    // measured with different font styles
    if (toActiveBold in FTabOptions) or (toActiveItalic in FTabOptions) then
    begin
      if (FTabIndex >= 0) and (FTabIndex < FTabs.Count) then
      begin
        FTabs[FTabIndex].FTextWidth := -1;
        FTabs[FTabIndex].FTextHeight := -1;
      end;
      if (AValue >= 0) and (AValue < FTabs.Count) then
      begin
        FTabs[AValue].FTextWidth := -1;
        FTabs[AValue].FTextHeight := -1;
      end;
    end;
    FTabIndex := AValue;
    if FTabIndex <> -1 then
      EnsureTabVisible(FTabIndex);
  finally
    EndInternalChange;
  end;

  if Assigned(FOnTabChanged) then
  begin
    FOnTabChanged(Self, FTabIndex);
    if csDestroying in ComponentState then Exit;
  end;

  Invalidate;
end;

procedure TExtTabCtrl.SetTabSize(AValue: Integer);
begin
  if FTabSize <> AValue then
  begin
    FTabSize := AValue;
    InvalidateLayout;
  end;
end;

procedure TExtTabCtrl.AddBtnClick(Sender: TObject);
var
  P: TPoint;
begin
  // If the event has been assigned just call it and let the user add the tab
  if Assigned(FOnAddButtonClick) then
  begin
    FOnAddButtonClick(Self);
  end
  // If a menu is assigned, show it on left-click
  else if Assigned(FBtnAdd.PopupMenu) then
  begin
    P := FBtnAdd.ClientToScreen(Point(0, FBtnAdd.Height));
    FBtnAdd.PopupMenu.PopUp(P.X, P.Y);
  end
  else // Just add the tab
  begin
    // Reset the counter when the strip is empty
    if FTabs.Count = 0 then
      FAddTabCounter := 0;
    Inc(FAddTabCounter);
    AddTab('New Tab ' + IntToStr(FAddTabCounter));
  end;
end;

procedure TExtTabCtrl.ScrollPrev(Sender: TObject);
var
  i: Integer;
  VisibleStart: Integer;
begin
  if FScrollOffset = 0 then Exit;

  // Find the first tab that starts before the current scroll position and scroll to show it
  VisibleStart := FScrollOffset;

  for i := FTabs.Count - 1 downto 0 do
  begin
    if not FTabs[i].Visible then Continue;
    if IsHorizontal then
    begin
      if FTabs[i].FBoundRect.Left < VisibleStart then
      begin
        FScrollOffset := FTabs[i].FBoundRect.Left;
        Break;
      end;
    end
    else
    begin
      if FTabs[i].FBoundRect.Top < VisibleStart then
      begin
        FScrollOffset := FTabs[i].FBoundRect.Top;
        Break;
      end;
    end;
  end;
  if FScrollOffset < 0 then FScrollOffset := 0;
  UpdateScrollButtons;
  Invalidate;
end;

procedure TExtTabCtrl.ScrollNext(Sender: TObject);
var
  i: Integer;
  V: TRect;
  ViewSize, VisibleEnd: Integer;
begin
  V := TabsViewportRect;
  if IsHorizontal then
  begin
    ViewSize := V.Width;
    VisibleEnd := FScrollOffset + ViewSize;
    for i := 0 to FTabs.Count - 1 do
    begin
      if not FTabs[i].Visible then Continue;
      if FTabs[i].FBoundRect.Right > VisibleEnd then
      begin
        FScrollOffset := FTabs[i].FBoundRect.Left;
        Break;
      end;
    end;
  end
  else
  begin
    ViewSize := V.Height;
    VisibleEnd := FScrollOffset + ViewSize;
    for i := 0 to FTabs.Count - 1 do
    begin
      if not FTabs[i].Visible then Continue;
      if FTabs[i].FBoundRect.Bottom > VisibleEnd then
      begin
        FScrollOffset := FTabs[i].FBoundRect.Top;
        Break;
      end;
    end;
  end;
  FScrollOffset := Min(MaxScrollOffset, FScrollOffset);
  UpdateScrollButtons;
  Invalidate;
end;

procedure TExtTabCtrl.SetTabStyle(AValue: TTabStyle);
begin
  if FTabStyle <> AValue then
  begin
    FTabStyle := AValue;
    InvalidateLayout;
  end;
end;

procedure TExtTabCtrl.SetTabPosition(AValue: TTabPosition);
begin
  if FTabPosition <> AValue then
  begin
    BeginUpdate;
    try
      FTabPosition := AValue;
      FScrollOffset := 0;

      // Reset alignment to allow UpdateButtonLayout to manually set bounds
      FBtnAdd.Align := alNone;
      FBtnScrollPrev.Align := alNone;
      FBtnScrollNext.Align := alNone;

      // Invalidate the glyph cache to trigger a re-rotation of bitmaps
      // matching the new position during the next RefreshGlyphCache call
      FLastRotation := -1;

      // Rotation angle changed --> per-tab image caches are stale
      InvalidateTabImageCaches;

      UpdateButtonLayout;

      // Mark the internal layout (tab rects) as dirty
      InvalidateLayout;
    finally
      EndUpdate;
      Invalidate; // Force a full repaint of the control
    end;
  end;
end;

procedure TExtTabCtrl.SetTabOptions(AValue: TExtTabOptions);
var
  i: Integer;
begin
  if FTabOptions = AValue then Exit;
  FTabOptions := AValue;
  FLastRotation := -1;
  FLayoutDirty := True;
  // toActiveBold/Italic affects text measurements, reset all caches
  for i := 0 to FTabs.Count - 1 do
  begin
    FTabs[i].FTextWidth := -1;
    FTabs[i].FTextHeight := -1;
  end;
  UpdateButtonLayout;
  Invalidate;
end;

procedure TExtTabCtrl.SetImages(AValue: TCustomImageList);
begin
  if FImages <> AValue then
  begin
    FImages := AValue;
    if FImages <> nil then FImages.FreeNotification(Self);
    InvalidateTabImageCaches;
    InvalidateLayout;
  end;
end;

procedure TExtTabCtrl.SetButtonImages(AValue: TButtonImages);
begin
  FButtonImages.Assign(AValue);
end;

procedure TExtTabCtrl.SetButtonHints(AValue: TButtonHints);
begin
  FButtonHints.Assign(AValue);

  if not (csLoading in ComponentState) then
    UpdateButtonLayout;
end;

procedure TExtTabCtrl.SetTabs(AValue: TExtTabs);
begin
  FTabs.Assign(AValue);
end;

function TExtTabCtrl.GetAddMenu: TPopupMenu;
begin
  Result := FBtnAdd.PopupMenu;
end;

procedure TExtTabCtrl.SetAddMenu(AValue: TPopupMenu);
begin
  FBtnAdd.PopupMenu := AValue;
end;

procedure TExtTabCtrl.ButtonImagesChanged(Sender: TObject);
begin
  UpdateButtonLayout;
  Invalidate;
end;

function TExtTabCtrl.TabsViewportRect: TRect;
var
  ScaledSize: Integer;
begin
  Result := ClientRect;
  ScaledSize := GetScale(FTabSize);

  case FTabPosition of
    tpTop: Result.Bottom := Result.Top + ScaledSize;
    tpBottom: Result.Top := Result.Bottom - ScaledSize;
    tpLeft: Result.Right := Result.Left + ScaledSize;
    tpRight: Result.Left := Result.Right - ScaledSize;
  end;

  // Clip the button areas (Scroll/Add)
  if IsHorizontal then
  begin
    if FBtnScrollPrev.Visible then Inc(Result.Left, FBtnScrollPrev.Width);
    if FBtnScrollNext.Visible then Dec(Result.Right, FBtnScrollNext.Width);
    if FBtnAdd.Visible then Dec(Result.Right, FBtnAdd.Width);
  end
  else
  begin
    if FBtnScrollPrev.Visible then Inc(Result.Top, FBtnScrollPrev.Height);
    if FBtnScrollNext.Visible then Dec(Result.Bottom, FBtnScrollNext.Height);
    if FBtnAdd.Visible then Dec(Result.Bottom, FBtnAdd.Height);
  end;
end;

procedure TExtTabCtrl.UpdateButtonLayout;
var
  ScaledTabSize: Integer;
  ScrollW, ScrollH, AddW, AddH: Integer;
  PrevIdx, NextIdx: Integer;
begin
  // Added FUpdateCount check to honor BeginUpdate/EndUpdate blocks
  if (FUpdateCount > 0) or FUpdatingButtons or
     (csDestroying in ComponentState) or not HandleAllocated then
    Exit;

  FUpdatingButtons := True;
  Self.DisableAlign;
  try
    ScaledTabSize := GetScale(FTabSize);

    ScrollW := FScrollImages[0].Width;
    ScrollH := FScrollImages[0].Height;

    AddW := FAddImage.Width;
    AddH := FAddImage.Height;

    // Hide the Add button at design time — it has no function there
    if FBtnAdd.Visible <> ((toShowAddButton in FTabOptions) and
                            not (csDesigning in ComponentState)) then
      FBtnAdd.Visible := (toShowAddButton in FTabOptions) and
                          not (csDesigning in ComponentState);

    PrevIdx := 0;
    NextIdx := 1;

    if IsHorizontal then
    begin
      if FTabPosition = tpTop then
      begin
        FBtnScrollPrev.SetBounds(0, 0, ScrollW, ScaledTabSize);
        FBtnAdd.SetBounds(ClientWidth - AddW, 0, AddW, ScaledTabSize);
        FBtnScrollNext.SetBounds(FBtnAdd.Left - ScrollW, 0, ScrollW, ScaledTabSize);
      end
      else
      begin
        FBtnScrollPrev.SetBounds(0, ClientHeight - ScaledTabSize, ScrollW, ScaledTabSize);
        FBtnAdd.SetBounds(ClientWidth - AddW, ClientHeight - ScaledTabSize, AddW, ScaledTabSize);
        FBtnScrollNext.SetBounds(FBtnAdd.Left - ScrollW, ClientHeight - ScaledTabSize, ScrollW, ScaledTabSize);
      end;
    end
    else
    begin
      if (toRotateAddImage in FTabOptions) and (GetRotationForPosition <> 0) then
        SwapIntegers(AddW, AddH);

      if FTabPosition = tpLeft then
      begin
        FBtnScrollPrev.SetBounds(0, 0, ScaledTabSize, ScrollH);
        FBtnAdd.SetBounds(0, ClientHeight - AddH, ScaledTabSize, AddH);
        FBtnScrollNext.SetBounds(0, FBtnAdd.Top - ScrollH, ScaledTabSize, ScrollH);
      end
      else
      begin
        FBtnScrollPrev.SetBounds(ClientWidth - ScaledTabSize, 0, ScaledTabSize, ScrollH);
        FBtnAdd.SetBounds(ClientWidth - ScaledTabSize, ClientHeight - AddH, ScaledTabSize, AddH);
        FBtnScrollNext.SetBounds(ClientWidth - ScaledTabSize, FBtnAdd.Top - ScrollH, ScaledTabSize, ScrollH);
      end;
    end;

    RefreshGlyphCache;
    FBtnScrollPrev.Glyph.Assign(FCachedScrollGlyphs[PrevIdx]);
    FBtnScrollNext.Glyph.Assign(FCachedScrollGlyphs[NextIdx]);
    FBtnAdd.Glyph.Assign(FCachedAddGlyph);

    FLayoutDirty := True;
  finally
    Self.EnableAlign;
    FUpdatingButtons := False;
  end;
end;

function TExtTabCtrl.IsVertical: Boolean;
begin
  Result := FTabPosition in [tpLeft, tpRight];
end;

function TExtTabCtrl.IsHorizontal: Boolean;
begin
  Result := not IsVertical;
end;

function TExtTabCtrl.CloseButtonRect(Tab: TExtTab): TRect;
var
  CloseW, CloseH, M: Integer;
begin
  // Determine dynamic Close Button size
  if Assigned(FCloseImage) and not FCloseImage.Empty then
  begin
    CloseW := FCloseImage.Width;
    CloseH := FCloseImage.Height;
  end
  else
  begin
    CloseW := GetScale(16);
    CloseH := CloseW;
  end;

  M := GetScale(cContentIndent);

  if IsHorizontal then
  begin
    // Horizontal: Positioned at the right end of the tab, vertically centered
    Result.Left := Tab.FBoundRect.Width - CloseW - M;
    Result.Top := (Tab.FBoundRect.Height - CloseH) div 2;
    Result.Right := Tab.FBoundRect.Width - M;
    Result.Bottom := Result.Top + CloseH;
  end
  else
  begin
    // Vertical: Horizontally centered within the tab strip
    Result.Left := (Tab.FBoundRect.Width - CloseW) div 2;
    Result.Right := Result.Left + CloseW;

    if FTabPosition = tpLeft then
    begin
      // tpLeft: Close button at the top
      Result.Top := M;
      Result.Bottom := M + CloseH;
    end
    else
    begin
      // tpRight: Close button at the bottom
      Result.Bottom := Tab.FBoundRect.Height - M;
      Result.Top := Result.Bottom - CloseH;
    end;
  end;
end;

function TExtTabCtrl.TabAtPos(X, Y: Integer): Integer;
var
  i: Integer;
  P: TPoint;
  V: TRect;
begin
  Result := -1;
  V := TabsViewportRect;
  if not PtInRect(V, Point(X, Y)) then Exit;
  if IsHorizontal then
    P := Point(X - V.Left + FScrollOffset, Y - V.Top)
  else
    P := Point(X - V.Left, Y - V.Top + FScrollOffset);
  for i := 0 to FTabs.Count - 1 do
    if PtInRect(FTabs[i].FBoundRect, P) then Exit(i);
end;

procedure TExtTabCtrl.LoadBitmapFromLRS(const ResName: String; DestBitmap: TBitmap);
var
  PNG: TPortableNetworkGraphic;
begin
  if LazarusResources.Find(ResName) = nil then Exit;
  PNG := TPortableNetworkGraphic.Create;
  try
    PNG.LoadFromLazarusResource(ResName);
    DestBitmap.Assign(PNG);
  finally
    PNG.Free;
  end;
end;

function TExtTabCtrl.MaxScrollOffset: Integer;
var
  V: TRect;
begin
  V := TabsViewportRect;
  if IsHorizontal then
    Result := Max(0, FTotalTabsSize - V.Width)
  else
    Result := Max(0, FTotalTabsSize - V.Height);
end;

procedure TExtTabCtrl.EnsureTabVisible(Index: Integer);
var
  R, V: TRect;
begin
  if (Index < 0) or (Index >= FTabs.Count) then Exit;

  // Force buttons to update state so we know exactly how much
  // viewable space is actually "eaten" by the scroll buttons
  UpdateScrollButtons;
  CalcLayout;

  R := FTabs[Index].FBoundRect;
  V := TabsViewportRect;

  if IsHorizontal then
  begin
    // Check if the tab is hidden by the 'Next' button (Right side)
    if FBtnScrollNext.Visible and (R.Right > FScrollOffset + V.Width - FBtnScrollNext.Width) then
      FScrollOffset := R.Right - (V.Width - FBtnScrollNext.Width)
    // Check if the tab is hidden by the 'Previous' button (Left side)
    else if R.Left < FScrollOffset then
      FScrollOffset := R.Left;

    // Final check: if the Previous button is visible, ensure it doesn't overlap R.Left
    if FBtnScrollPrev.Visible and (R.Left < FScrollOffset + FBtnScrollPrev.Width) then
      FScrollOffset := R.Left - FBtnScrollPrev.Width;
  end
  else
  begin
    // Check if the tab is hidden by the 'Next' button (Bottom side)
    if FBtnScrollNext.Visible and (R.Bottom > FScrollOffset + V.Height - FBtnScrollNext.Height) then
      FScrollOffset := R.Bottom - (V.Height - FBtnScrollNext.Height)
    // Check if the tab is hidden by the 'Previous' button (Top side)
    else if R.Top < FScrollOffset then
      FScrollOffset := R.Top;

    // Final check: if the Previous button is visible, ensure it doesn't overlap R.Top
    if FBtnScrollPrev.Visible and (R.Top < FScrollOffset + FBtnScrollPrev.Height) then
      FScrollOffset := R.Top - FBtnScrollPrev.Height;
  end;

  // Final safety bounds — clamp BEFORE UpdateScrollButtons uses the value
  if FScrollOffset < 0 then FScrollOffset := 0;

  UpdateScrollButtons;
  Invalidate;
end;

procedure TExtTabCtrl.UpdateScrollButtons;
var
  Avail: Integer;
  Can: Boolean;
  NewPrevVis, NewNextVis: Boolean;
  HasChanged: Boolean;
begin
  if (FUpdateCount > 0) or FUpdatingButtons or not HandleAllocated then Exit;

  if IsHorizontal then
    Avail := ClientWidth - IfThen(FBtnAdd.Visible, FBtnAdd.Width, 0)
  else
    Avail := ClientHeight - IfThen(FBtnAdd.Visible, FBtnAdd.Height, 0);

  Can := FTotalTabsSize > Avail;
  NewPrevVis := Can and (FScrollOffset > 0);
  NewNextVis := Can and (FScrollOffset < MaxScrollOffset);

  HasChanged := (FBtnScrollPrev.Visible <> NewPrevVis) or
                (FBtnScrollNext.Visible <> NewNextVis);

  if HasChanged then
  begin
    FBtnScrollPrev.Visible := NewPrevVis;
    FBtnScrollNext.Visible := NewNextVis;
    if not Can then FScrollOffset := 0;
    UpdateButtonLayout;
  end;
end;

function TExtTabCtrl.GetScale(Value: Integer): Integer;
begin
  Result := Scale96ToFont(Value);
end;

procedure TExtTabCtrl.DrawTabTextAndImage(ACanvas: TCanvas; const R: TRect; Tab: TExtTab; IsActive: Boolean);
var
  TextRect: TRect;
  ImgPos: TPoint;
  ImgW, ImgH: Integer;
  ActiveExtra: TFontStyles;
begin
  ACanvas.Font.Assign(Font);

  // Apply per-tab font overrides
  if Tab.FFontOptions.FontSize > 0 then
    ACanvas.Font.Size := Tab.FFontOptions.FontSize;
  if Tab.FFontOptions.FontStyles <> [] then
    ACanvas.Font.Style := Tab.FFontOptions.FontStyles;

  // Optionally render the active tab in bold and/or italic
  if IsActive then
  begin
    ActiveExtra := [];
    if toActiveBold in FTabOptions then Include(ActiveExtra, fsBold);
    if toActiveItalic in FTabOptions then Include(ActiveExtra, fsItalic);
    if ActiveExtra <> [] then
      ACanvas.Font.Style := ACanvas.Font.Style + ActiveExtra;
  end;

  if not IsActive then ACanvas.Font.Color := clGrayText;
  ACanvas.Brush.Style := bsClear;

  TextRect := GetTabTextBounds(ACanvas, R, Tab);

  if HasAnyImage(Tab) then
  begin
    ImgW := GetTabImageWidth(Tab);
    ImgH := GetTabImageHeight(Tab);

    if IsHorizontal then
      ImgPos := Point(TextRect.Left - GetScale(cImageSpacing) - ImgW, R.Top + (R.Height - ImgH) div 2)
    else
      // Vertical logic: adjust Y based on whether it's tpLeft or tpRight
      ImgPos := Point(R.Left + (R.Width - ImgW) div 2,
                  IfThen(FTabPosition = tpLeft, TextRect.Bottom + GetScale(cImageSpacing),
                                                TextRect.Top - GetScale(cImageSpacing) - ImgH));

    DrawTabImage(ACanvas, Tab, ImgPos.X, ImgPos.Y);
  end;

  if IsHorizontal then
    DrawText(ACanvas.Handle, PChar(Tab.Caption), -1, TextRect, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX)
  else
    DrawRotatedText(ACanvas, Tab.Caption, TextRect, GetRotationForPosition);
end;

procedure TExtTabCtrl.DrawTabImage(ACanvas: TCanvas; Tab: TExtTab; X, Y: Integer);
var
  SrcBmp: TBitmap;
  Angle: Integer;
  NeedsRotation: Boolean;
begin
  // Cache the bitmap on the TExtTab
  Angle := GetRotationForPosition;
  // Invert the angle for images: CCW for tpLeft, CW for tpRight
  case Angle of
    90: Angle := 270;
    270: Angle := 90;
  end;

  NeedsRotation := (toRotateTabImages in FTabOptions) and (Angle <> 0);

  // Rebuild the cache when stale (first use, source changed, or rotation changed)
  if (Tab.FCachedTabImage = nil) or (Tab.FCachedImageRotation <> Angle) then
  begin
    SrcBmp := TBitmap.Create;
    try
      GetBaseTabBitmap(Tab, SrcBmp);
      if SrcBmp.Empty then Exit;

      if Tab.FCachedTabImage = nil then
        Tab.FCachedTabImage := TBitmap.Create;

      if NeedsRotation then
        RotateBitmap(SrcBmp, Tab.FCachedTabImage, Angle)
      else
        Tab.FCachedTabImage.Assign(SrcBmp);

      Tab.FCachedImageRotation := Angle;
    finally
      SrcBmp.Free;
    end;
  end;

  if Assigned(Tab.FCachedTabImage) and not Tab.FCachedTabImage.Empty then
    ACanvas.Draw(X, Y, Tab.FCachedTabImage);
end;

procedure TExtTabCtrl.DrawRotatedText(ACanvas: TCanvas; const S: String; const R: TRect; Degrees: Integer);
var
  SavedOrientation: Integer;
begin
  SavedOrientation := ACanvas.Font.Orientation;
  ACanvas.Font.Orientation := Degrees * 10;

  if Degrees = 90 then
    // 90°: anchor is Bottom-Left
    ACanvas.TextOut(R.Left, R.Bottom, S)
  else if Degrees = 270 then
    // 270°: anchor is Top-Right
    ACanvas.TextOut(R.Right, R.Top, S)
  else
    ACanvas.TextOut(R.Left, R.Top, S);

  ACanvas.Font.Orientation := SavedOrientation;
end;

function TExtTabCtrl.GetRotationForPosition: Integer;
begin
  case FTabPosition of
    tpLeft: Result := 90;
    tpRight: Result := 270;
    else Result := 0;
  end;
end;

function TExtTabCtrl.HasAnyImage(Tab: TExtTab): Boolean;
begin
  Result := (Assigned(FImages) and (Tab.ImageIndex >= 0)) or
            (Assigned(Tab.FImage) and not Tab.FImage.Empty);
end;

function TExtTabCtrl.GetTabImageWidth(Tab: TExtTab): Integer;
begin
  if Assigned(FImages) and (Tab.ImageIndex >= 0) then
    Result := FImages.Width
  else if Assigned(Tab.FImage) and not Tab.FImage.Empty then
    Result := Tab.FImage.Width
  else
    Result := 0;
end;

function TExtTabCtrl.GetTabImageHeight(Tab: TExtTab): Integer;
begin
  if Assigned(FImages) and (Tab.ImageIndex >= 0) then
    Result := FImages.Height
  else if Assigned(Tab.FImage) and not Tab.FImage.Empty then
    Result := Tab.FImage.Height
  else
    Result := 0;
end;

function TExtTabCtrl.GetTabTextBounds(ACanvas: TCanvas; const R: TRect; Tab: TExtTab): TRect;
var
  Indent, Spacing, CloseW, CloseH, ImgH: Integer;
  TextSize: TSize;
  TxtRect: TRect;
  CX, CY: Integer;
begin
  Indent := GetScale(cContentIndent);
  Spacing := GetScale(cImageSpacing);

  // Reuse the cached dimensions measured in CalcLayout, except when the cache is stale
  if Tab.FTextWidth >= 0 then
  begin
    TextSize.cx := Tab.FTextWidth;
    TextSize.cy := Tab.FTextHeight;
  end
  else
    TextSize := ACanvas.TextExtent(Tab.Caption);

  Result := R;

  if IsHorizontal then
  begin
    if Assigned(FCloseImage) and not FCloseImage.Empty then
      CloseW := FCloseImage.Width
    else
      CloseW := GetScale(16);

    TxtRect := R;
    TxtRect.Left := R.Left + Indent;

    Dec(TxtRect.Right, Indent);

    // Account for Image
    if HasAnyImage(Tab) then
      Inc(TxtRect.Left, GetTabImageWidth(Tab) + Spacing);

    // Account for Close Button
    if (toShowCloseButton in FTabOptions) and Tab.ShowCloseButton then
      Dec(TxtRect.Right, CloseW + Indent);

    Result.Left := TxtRect.Left + (TxtRect.Width - TextSize.cx) div 2;
    Result.Right := Result.Left + TextSize.cx;
    Result.Top := TxtRect.Top + (TxtRect.Height - TextSize.cy) div 2;
    Result.Bottom := Result.Top + TextSize.cy;
  end
  else
  begin
    // Mirroring DrawVerticalTab logic
    if Assigned(FCloseImage) and not FCloseImage.Empty then
      CloseH := FCloseImage.Height
    else
      CloseH := GetScale(16);

    TxtRect := R;
    InflateRect(TxtRect, -Indent, -Indent);

    if (toShowCloseButton in FTabOptions) and Tab.ShowCloseButton then
    begin
      if FTabPosition = tpLeft then
        Inc(TxtRect.Top, CloseH + Indent)
      else
        Dec(TxtRect.Bottom, CloseH + Indent);
    end;

    CX := (TxtRect.Left + TxtRect.Right) div 2;
    if FTabPosition = tpLeft then CY := TxtRect.Bottom else CY := TxtRect.Top;

    if HasAnyImage(Tab) then
    begin
      ImgH := GetTabImageHeight(Tab);
      if FTabPosition = tpLeft then
        CY := TxtRect.Bottom - ImgH - Spacing
      else
        CY := TxtRect.Top + ImgH + Spacing;
    end;

    if FTabPosition = tpLeft then
    begin
      // 90°: TextOut anchor is Bottom-Left
      Result.Left := CX - (TextSize.cy div 2);
      Result.Right := Result.Left + TextSize.cy;
      Result.Bottom := CY;
      Result.Top := CY - TextSize.cx;
    end
    else
    begin
      // 270°: TextOut anchor is Top-Right
      Result.Left := CX - (TextSize.cy div 2);
      Result.Right := Result.Left + TextSize.cy;
      Result.Top := CY;
      Result.Bottom := CY + TextSize.cx;
    end;
  end;
end;

procedure TExtTabCtrl.GetBaseTabBitmap(Tab: TExtTab; Dest: TBitmap);
begin
  if Assigned(FImages) and (Tab.ImageIndex >= 0) then
    FImages.GetBitmap(Tab.ImageIndex, Dest)
  else if Assigned(Tab.FImage) and not Tab.FImage.Empty then
    Dest.Assign(Tab.FImage)
  else
    Dest.Clear;
end;

procedure TExtTabCtrl.DrawCloseButton(ACanvas: TCanvas;
  const R: TRect; Tab: TExtTab; IsActive: Boolean);
var
  CloseR: TRect;
begin
  if not (toShowCloseButton in FTabOptions) or not Tab.ShowCloseButton then Exit;

  CloseR := CloseButtonRect(Tab);
  Types.OffsetRect(CloseR, R.Left, R.Top);
  if FHoverCloseTab = Tab.Index then
  begin
    ACanvas.Brush.Color := clSilver;
    ACanvas.FillRect(CloseR);
  end;
  if Assigned(FCloseImage) and not FCloseImage.Empty then
    ACanvas.Draw(CloseR.Left + (CloseR.Width - FCloseImage.Width) div 2,
                 CloseR.Top + (CloseR.Height - FCloseImage.Height) div 2,
                 FCloseImage)
  else
  begin
    // Vector fallback: draw a simple x using the pen
    ACanvas.Pen.Color := IfThen(FHoverCloseTab = Tab.Index, clBlack, clGray);
    ACanvas.Pen.Width := GetScale(1);
    ACanvas.Line(CloseR.Left + GetScale(3), CloseR.Top + GetScale(3),
                 CloseR.Right - GetScale(3), CloseR.Bottom - GetScale(3));
    ACanvas.Line(CloseR.Right - GetScale(3), CloseR.Top + GetScale(3),
                 CloseR.Left + GetScale(3), CloseR.Bottom - GetScale(3));
  end;
end;

procedure TExtTabCtrl.DrawColorStripe(ACanvas: TCanvas; const R: TRect; Tab: TExtTab);
var
  IndicatorRect, TextBounds: TRect;
  Thick: Integer;
begin
  if (Tab.Color = clNone) then Exit;

  ACanvas.Brush.Color := Tab.Color;
  ACanvas.Pen.Style := psClear;
  Thick := GetScale(3);
  TextBounds := GetTabTextBounds(ACanvas, R, Tab);
  IndicatorRect := R;

  case FTabPosition of
    tpTop: IndicatorRect := Rect(TextBounds.Left, R.Top + 1, TextBounds.Right, R.Top + 1 + Thick);
    tpBottom: IndicatorRect := Rect(TextBounds.Left, R.Bottom - 1 - Thick, TextBounds.Right, R.Bottom - 1);
    tpLeft: IndicatorRect := Rect(R.Left + 1, TextBounds.Top, R.Left + 1 + Thick, TextBounds.Bottom);
    tpRight: IndicatorRect := Rect(R.Right - 1 - Thick, TextBounds.Top, R.Right - 1, TextBounds.Bottom);
  end;
  ACanvas.FillRect(IndicatorRect);
  ACanvas.Pen.Style := psSolid;
end;

{ Drawing Handlers }

procedure TExtTabCtrl.DrawFlatTab(ACanvas: TCanvas; R: TRect; IsActive: Boolean; Tab: TExtTab);
var
  P: array[0..3] of TPoint;
begin
  // Draw Background
  ACanvas.Brush.Color := IfThen(IsActive, Color, IfThen(Tab.Index =
    FHoverTab, BlendColors(clBtnFace, clHighlight, 0.2), clBtnFace));
  ACanvas.Brush.Style := bsSolid;
  ACanvas.FillRect(R);

  // Draw Color Stripe
  if (Tab.Color <> clNone) then
  begin
    DrawColorStripe(ACanvas, R, Tab);

    ACanvas.Brush.Style := bsClear;
    ACanvas.Pen.Style := psSolid;
  end;

  // Border Logic
  ACanvas.Pen.Color := clBtnShadow;
  case FTabPosition of
    tpTop: begin
      P[0] := Point(R.Left, R.Bottom - 1);
      P[1] := Point(R.Left, R.Top);
      P[2] := Point(R.Right - 1, R.Top);
      P[3] := Point(R.Right - 1, R.Bottom - 1);
    end;
    tpBottom: begin
      P[0] := Point(R.Left, R.Top);
      P[1] := Point(R.Left, R.Bottom - 1);
      P[2] := Point(R.Right - 1, R.Bottom - 1);
      P[3] := Point(R.Right - 1, R.Top);
    end;
    tpLeft: begin
      P[0] := Point(R.Right - 1, R.Top);
      P[1] := Point(R.Left, R.Top);
      P[2] := Point(R.Left, R.Bottom - 1);
      P[3] := Point(R.Right - 1, R.Bottom - 1);
    end;
    tpRight: begin
      P[0] := Point(R.Left, R.Top);
      P[1] := Point(R.Right - 1, R.Top);
      P[2] := Point(R.Right - 1, R.Bottom - 1);
      P[3] := Point(R.Left, R.Bottom - 1);
    end;
  end;

  if IsActive then ACanvas.Polyline(P) else ACanvas.Polygon(P);

  // Draw Content
  DrawTabTextAndImage(ACanvas, R, Tab, IsActive);
  DrawCloseButton(ACanvas, R, Tab, IsActive);
end;

procedure TExtTabCtrl.DrawButtonTab(ACanvas: TCanvas; R: TRect; IsActive: Boolean; Tab: TExtTab);
var
  LightClr, ShadowClr, BackClr: TColor;
begin
  LightClr := clBtnHighlight;
  ShadowClr := clBtnShadow;

  // Determine and Draw Background
  if IsActive then
    BackClr := BlendColors(clBtnFace, clBlack, 0.05)
  else if Tab.Index = FHoverTab then
    BackClr := BlendColors(clBtnFace, clWhite, 0.4)
  else
    BackClr := clBtnFace;

  ACanvas.Brush.Color := BackClr;
  ACanvas.Brush.Style := bsSolid;
  ACanvas.FillRect(R);

  // Draw Color Stripe
  if (Tab.Color <> clNone) then
  begin
    DrawColorStripe(ACanvas, R, Tab);

    ACanvas.Brush.Style := bsClear;
    ACanvas.Pen.Style := psSolid;
  end;

  // Draw 3D Frame
  if IsActive then
  begin
    // Inverted 3D frame (Shadow on Top/Left, Light on Bottom/Right)
    ACanvas.Pen.Color := ShadowClr;
    ACanvas.Polyline([Point(R.Left, R.Bottom - 1), Point(R.Left, R.Top),
      Point(R.Right - 1, R.Top)]);
    ACanvas.Pen.Color := LightClr;
    ACanvas.Polyline([Point(R.Right - 1, R.Top), Point(R.Right - 1, R.Bottom - 1),
      Point(R.Left, R.Bottom - 1)]);

    // Adjust Content Position for "Pressed" effect
    Types.OffsetRect(R, GetScale(1), GetScale(1));
  end
  else
  begin
    // Standard 3D frame (Light on Top/Left, Shadow on Bottom/Right)
    ACanvas.Pen.Color := LightClr;
    ACanvas.Polyline([Point(R.Left, R.Bottom - 1), Point(R.Left, R.Top),
      Point(R.Right - 1, R.Top)]);
    ACanvas.Pen.Color := ShadowClr;
    ACanvas.Polyline([Point(R.Right - 1, R.Top), Point(R.Right - 1, R.Bottom - 1),
      Point(R.Left, R.Bottom - 1)]);
  end;

  // Draw Content
  DrawTabTextAndImage(ACanvas, R, Tab, IsActive);
  DrawCloseButton(ACanvas, R, Tab, IsActive);
end;

procedure TExtTabCtrl.DrawDelphiTab(ACanvas: TCanvas; R: TRect; IsActive: Boolean; Tab: TExtTab);
var
  P: array[0..3] of TPoint;
  S: Integer;
begin
  S := GetScale(3); // Angle slant amount

  // Set Colors and draw background
  if IsActive then
    ACanvas.Brush.Color := Color
  else if Tab.Index = FHoverTab then
    ACanvas.Brush.Color := BlendColors(clBtnFace, clWhite, 0.8)
  else
    ACanvas.Brush.Color := clBtnFace;

  ACanvas.Pen.Color := clBtnShadow;
  ACanvas.Brush.Style := bsSolid;

  // Define Polygon Points for the tab body
  case FTabPosition of
    tpTop: begin
      P[0] := Point(R.Left, R.Bottom);
      P[1] := Point(R.Left + S, R.Top);
      P[2] := Point(R.Right - S, R.Top);
      P[3] := Point(R.Right, R.Bottom);
    end;
    tpBottom: begin
      P[0] := Point(R.Left, R.Top);
      P[1] := Point(R.Left + S, R.Bottom - 1);
      P[2] := Point(R.Right - S, R.Bottom - 1);
      P[3] := Point(R.Right, R.Top);
    end;
    tpLeft: begin
      P[0] := Point(R.Right, R.Top);
      P[1] := Point(R.Left, R.Top + S);
      P[2] := Point(R.Left, R.Bottom - S);
      P[3] := Point(R.Right, R.Bottom);
    end;
    tpRight: begin
      P[0] := Point(R.Left, R.Top);
      P[1] := Point(R.Right - 1, R.Top + S);
      P[2] := Point(R.Right - 1, R.Bottom - S);
      P[3] := Point(R.Left, R.Bottom);
    end;
  end;

  ACanvas.Polygon(P);

  // Draw Color Stripe following the narrower edge
  if (Tab.Color <> clNone) then
  begin
    DrawColorStripe(ACanvas, R, Tab);

    ACanvas.Brush.Style := bsClear;
    ACanvas.Pen.Style := psSolid;
    ACanvas.Pen.Color := clBtnShadow;
  end;

  // Draw the Base Separator Line
  case FTabPosition of
    tpTop: ACanvas.Line(R.Left, R.Bottom - 1, R.Right, R.Bottom - 1);
    tpBottom: ACanvas.Line(R.Left, R.Top, R.Right, R.Top);
    tpLeft: ACanvas.Line(R.Right - 1, R.Top, R.Right - 1, R.Bottom);
    tpRight: ACanvas.Line(R.Left, R.Top, R.Left, R.Bottom);
  end;

  // "Open" the Active Tab
  if IsActive then
  begin
    ACanvas.Pen.Color := Color;
    case FTabPosition of
      tpTop: ACanvas.Line(P[0].X + 1, P[0].Y - 1, P[3].X - 1, P[3].Y - 1);
      tpBottom: ACanvas.Line(P[0].X + 1, P[0].Y, P[3].X - 1, P[3].Y);
      tpLeft: ACanvas.Line(P[0].X - 1, P[0].Y + 1, P[3].X - 1, P[3].Y - 1);
      tpRight: ACanvas.Line(P[0].X, P[0].Y + 1, P[3].X, P[3].Y - 1);
    end;
  end;

  DrawTabTextAndImage(ACanvas, R, Tab, IsActive);
  DrawCloseButton(ACanvas, R, Tab, IsActive);
end;

procedure TExtTabCtrl.DrawChromeTab(ACanvas: TCanvas; R: TRect; IsActive: Boolean; Tab: TExtTab);
var
  Radius: Integer;
  TextBounds: TRect;
begin
  Radius := GetScale(8);

  // Background and hover
  if IsActive then
  begin
    ACanvas.Brush.Color := Color;
    ACanvas.Brush.Style := bsSolid;
  end
  else
  begin
    if Tab.Index = FHoverTab then
    begin
      // Light subtle hover
      ACanvas.Brush.Color := BlendColors(Color, clWhite, 0.7);
      ACanvas.Brush.Style := bsSolid;
    end
    else
      ACanvas.Brush.Style := bsClear;
  end;

  // Draw Tab (RoundRect with overlap to square the bottom)
  if IsActive or (Tab.Index = FHoverTab) then
  begin
    ACanvas.Pen.Color := clBtnShadow;
    case FTabPosition of
      tpTop:
        ACanvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom + Radius, Radius, Radius);
      tpBottom:
        ACanvas.RoundRect(R.Left, R.Top - Radius, R.Right, R.Bottom, Radius, Radius);
      tpLeft:
        ACanvas.RoundRect(R.Left, R.Top, R.Right + Radius, R.Bottom, Radius, Radius);
      tpRight:
        ACanvas.RoundRect(R.Left - Radius, R.Top, R.Right, R.Bottom, Radius, Radius);
    end;
  end;

  // Draw the shadow line for all tabs on the side touching the body
  ACanvas.Pen.Color := clBtnShadow;
  case FTabPosition of
    tpTop: ACanvas.Line(R.Left, R.Bottom - 1, R.Right, R.Bottom - 1);
    tpBottom: ACanvas.Line(R.Left, R.Top, R.Right, R.Top);
    tpLeft: ACanvas.Line(R.Right - 1, R.Top, R.Right - 1, R.Bottom);
    tpRight: ACanvas.Line(R.Left, R.Top, R.Left, R.Bottom);
  end;

  // Separators (For inactive non-hovered tabs)
  if not IsActive and (Tab.Index <> FHoverTab) and (Tab.Index <> FTabIndex - 1) then
  begin
    ACanvas.Pen.Color := clBtnShadow;
    if IsHorizontal then
      ACanvas.Line(R.Right - 1, R.Top + GetScale(6), R.Right - 1, R.Bottom - GetScale(6))
    else
      ACanvas.Line(R.Left + GetScale(6), R.Bottom - 1, R.Right -
        GetScale(6), R.Bottom - 1);
  end;

  // Active Tab: Accent Line and "Open" Connection
  if IsActive then
  begin
    // First, "Open" the tab (erase the segment of the base line)
    ACanvas.Pen.Color := Color;
    case FTabPosition of
      tpTop: ACanvas.Line(R.Left + 1, R.Bottom - 1, R.Right - 1, R.Bottom - 1);
      tpBottom: ACanvas.Line(R.Left + 1, R.Top, R.Right - 1, R.Top);
      tpLeft: ACanvas.Line(R.Right - 1, R.Top + 1, R.Right - 1, R.Bottom - 1);
      tpRight: ACanvas.Line(R.Left, R.Top + 1, R.Left, R.Bottom - 1);
    end;

    // Second, Draw the Accent Line (Top blue bar style)
    ACanvas.Pen.Color := clHighlight;
    ACanvas.Pen.Width := GetScale(3);

    // Get text bounds for precise alignment
    TextBounds := GetTabTextBounds(ACanvas, R, Tab);

    case FTabPosition of
      tpTop: ACanvas.Line(TextBounds.Left, R.Top + 1, TextBounds.Right, R.Top + 1);
      tpBottom: ACanvas.Line(TextBounds.Left, R.Bottom - 2, TextBounds.Right, R.Bottom - 2);
      tpLeft: ACanvas.Line(R.Left + 1, TextBounds.Top, R.Left + 1, TextBounds.Bottom);
      tpRight: ACanvas.Line(R.Right - 2, TextBounds.Top, R.Right - 2, TextBounds.Bottom);
    end;
    ACanvas.Pen.Width := 1;
  end;

  // Draw Color Stripe (Accent)
  if (Tab.Color <> clNone) then
  begin
    DrawColorStripe(ACanvas, R, Tab);

    ACanvas.Brush.Style := bsClear;
    ACanvas.Pen.Style := psSolid;
  end;

  // Draw content
  DrawTabTextAndImage(ACanvas, R, Tab, IsActive);
  DrawCloseButton(ACanvas, R, Tab, IsActive);
end;

procedure TExtTabCtrl.DrawMacOSTab(ACanvas: TCanvas; R: TRect; IsActive: Boolean; Tab: TExtTab);
var
  Radius: Integer;
  DrawR: TRect;
begin
  Radius := GetScale(6);
  DrawR := R;

  // Floating segment effect
  InflateRect(DrawR, -GetScale(2), -GetScale(2));

  if IsActive then
  begin
    ACanvas.Brush.Color := BlendColors(Color, clWindow, 0.85);
    ACanvas.Pen.Color := BlendColors(Color, clBtnShadow, 0.15); // subtle border
    ACanvas.RoundRect(DrawR.Left, DrawR.Top, DrawR.Right, DrawR.Bottom, Radius, Radius);
  end
  else
  begin
    if Tab.Index = FHoverTab then
    begin
      // Light hover: 90% blend toward the system window color
      ACanvas.Brush.Color := BlendColors(Color, clWindow, 0.9);
      ACanvas.Pen.Style := psClear;
      ACanvas.RoundRect(DrawR.Left, DrawR.Top, DrawR.Right, DrawR.Bottom,
        Radius, Radius);
      ACanvas.Pen.Style := psSolid;
    end;

    // Minimalist separators
    if (Tab.Index < FTabs.Count - 1) and (Tab.Index <> FTabIndex) and
      (Tab.Index <> FTabIndex - 1) then
    begin
      ACanvas.Pen.Color := BlendColors(Color, clBlack, 0.05); // Barely visible line
      ACanvas.MoveTo(R.Right - 1, R.Top + GetScale(7));
      ACanvas.LineTo(R.Right - 1, R.Bottom - GetScale(7));
    end;
  end;

  // Draw Color Stripe (Accent)
  if (Tab.Color <> clNone) then
  begin
    DrawColorStripe(ACanvas, R, Tab);

    ACanvas.Brush.Style := bsClear;
    ACanvas.Pen.Style := psSolid;
  end;

  ACanvas.Font.Color := IfThen(IsActive, clWindowText, clGrayText);
  DrawTabTextAndImage(ACanvas, R, Tab, IsActive);
  DrawCloseButton(ACanvas, R, Tab, IsActive);
end;

procedure TExtTabCtrl.DrawTab(ACanvas: TCanvas; Index: Integer; ARect: TRect; IsActive: Boolean);
begin
  case FTabStyle of
    tsButton: DrawButtonTab(ACanvas, ARect, IsActive, FTabs[Index]);
    tsDelphi: DrawDelphiTab(ACanvas, ARect, IsActive, FTabs[Index]);
    tsMacOS: DrawMacOSTab(ACanvas, ARect, IsActive, FTabs[Index]);
    tsFlat: DrawFlatTab(ACanvas, ARect, IsActive, FTabs[Index]);
    tsChrome: DrawChromeTab(ACanvas, ARect, IsActive, FTabs[Index]);
  end;
end;

procedure TExtTabCtrl.CalcLayout;
var
  i, Pos, TabLen: Integer;
  TxtExtent, ImgExtent,
  CloseExtent, Padding: Integer;
  ActiveExtra: TFontStyles;
begin
  if not FLayoutDirty then Exit;
  FLayoutDirty := False;

  Canvas.Font.Assign(Font);
  Pos := 0;
  Padding := GetScale(cContentIndent) * 2;

  for i := 0 to FTabs.Count - 1 do
  begin
    if not FTabs[i].Visible then
    begin
      FTabs[i].FBoundRect := Rect(0, 0, 0, 0);
      Continue;
    end;

    // Apply per-tab FontOptions overrides before measuring
    Canvas.Font.Assign(Font);
    if FTabs[i].FFontOptions.FontSize > 0 then
      Canvas.Font.Size := FTabs[i].FFontOptions.FontSize;
    if FTabs[i].FFontOptions.FontStyles <> [] then
      Canvas.Font.Style := FTabs[i].FFontOptions.FontStyles;

    // If the active tab will be rendered bold/italic, measure with those
    // styles applied so the tab is wide enough to hold its caption
    if i = FTabIndex then
    begin
      ActiveExtra := [];
      if toActiveBold in FTabOptions then Include(ActiveExtra, fsBold);
      if toActiveItalic in FTabOptions then Include(ActiveExtra, fsItalic);
      if ActiveExtra <> [] then
        Canvas.Font.Style := Canvas.Font.Style + ActiveExtra;
    end;

    // Use cached text width and height; measure only when stale
    if FTabs[i].FTextWidth < 0 then
    begin
      FTabs[i].FTextWidth := Canvas.TextWidth(FTabs[i].Caption);
      FTabs[i].FTextHeight := Canvas.TextHeight(FTabs[i].Caption);
    end;
    TxtExtent := FTabs[i].FTextWidth;

    ImgExtent := 0;

    // Check for ImageList + ImageIndex
    if Assigned(FImages) and (FTabs[i].ImageIndex >= 0) then
      ImgExtent := FImages.Width + GetScale(cImageSpacing)
    // Fallback to the standalone TBitmap property
    else if Assigned(FTabs[i].FImage) and not FTabs[i].FImage.Empty then
      ImgExtent := FTabs[i].Image.Width + GetScale(cImageSpacing);

    if (toShowCloseButton in FTabOptions) and FTabs[i].ShowCloseButton and
       Assigned(FCloseImage) and not FCloseImage.Empty then
    begin
      if IsHorizontal then
        CloseExtent := FCloseImage.Width + GetScale(cContentIndent)
      else
        CloseExtent := FCloseImage.Height + GetScale(cContentIndent);
      end
    else
      CloseExtent := 0;

    TabLen := Padding + TxtExtent + ImgExtent + CloseExtent;

    if IsHorizontal then
      FTabs[i].FBoundRect := Rect(Pos, 0, Pos + TabLen, GetScale(FTabSize))
    else
      FTabs[i].FBoundRect := Rect(0, Pos, GetScale(FTabSize), Pos + TabLen);

    Pos := Pos + TabLen - GetScale(cTabOverlap);
  end;

  // Restore control-level font after per-tab override passes
  Canvas.Font.Assign(Font);

  FTotalTabsSize := Pos + GetScale(cTabOverlap);
  UpdateScrollButtons;
end;

procedure TExtTabCtrl.Paint;
var
  i, SaveIdx: Integer;
  R, View, Dummy, TabRect: TRect;
  IndicatorPos: Integer;
begin
  if not HandleAllocated then Exit;
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);

  if FTabs.Count = 0 then Exit;

  CalcLayout;
  View := TabsViewportRect;
  SaveIdx := SaveDC(Canvas.Handle);
  try
    IntersectClipRect(Canvas.Handle, View.Left, View.Top, View.Right, View.Bottom);

    // Draw all tabs in their original places
    for i := 0 to FTabs.Count - 1 do
    begin
      if not FTabs[i].Visible then Continue;
      R := FTabs[i].FBoundRect;
      if IsHorizontal then Types.OffsetRect(R, View.Left - FScrollOffset, View.Top)
      else
        Types.OffsetRect(R, View.Left, View.Top - FScrollOffset);

      if IntersectRect(Dummy, R, View) then
        DrawTab(Canvas, i, R, i = FTabIndex);
    end;

    // Draw drop indicator (where the tab will be inserted)
    if FDragging and (FDragTargetIndex <> -1) then
    begin
      Canvas.Pen.Color := clHotLight;

      Canvas.Pen.Width := 3;

      if FDragTargetIndex < FTabs.Count then
        TabRect := FTabs[FDragTargetIndex].FBoundRect
      else
      begin
        // Drop at end
        if FTabs.Count = 0 then
          TabRect := Rect(0, 0, 0, 0)
        else
          TabRect := FTabs[FTabs.Count - 1].FBoundRect;
      end;

      if IsHorizontal then
      begin
        // Calculate logical X position
        if FDragTargetIndex = FTabs.Count then
          IndicatorPos := TabRect.Right
        else
          IndicatorPos := TabRect.Left;

        // Transform Logical X to Visual X: (Pos - Scroll + Offset)
        IndicatorPos := IndicatorPos - FScrollOffset + View.Left;

        Canvas.MoveTo(IndicatorPos, View.Top);
        Canvas.LineTo(IndicatorPos, View.Bottom);
      end
      else
      begin
        // Calculate logical Y position
        if FDragTargetIndex = FTabs.Count then
          IndicatorPos := TabRect.Bottom
        else
          IndicatorPos := TabRect.Top;

        // Transform Logical Y to Visual Y
        IndicatorPos := IndicatorPos - FScrollOffset + View.Top;

        Canvas.MoveTo(View.Left, IndicatorPos);
        Canvas.LineTo(View.Right, IndicatorPos);
      end;

      Canvas.Pen.Width := 1;
    end;

    if Focused and (toShowFocusRect in FTabOptions) and
       (FTabIndex >= 0) and (FTabIndex < FTabs.Count) then
    begin
      R := FTabs[FTabIndex].FBoundRect;
      if IsHorizontal then
        Types.OffsetRect(R, View.Left - FScrollOffset, View.Top)
      else
        Types.OffsetRect(R, View.Left, View.Top - FScrollOffset);
      R := GetTabTextBounds(Canvas, R, FTabs[FTabIndex]);
      InflateRect(R, GetScale(2), GetScale(2));
      DrawFocusRect(Canvas.Handle, R);
    end;

  finally
    RestoreDC(Canvas.Handle, SaveIdx);
  end;
end;

procedure TExtTabCtrl.Resize;
begin
  inherited Resize;
  if not HandleAllocated then Exit;
  FLayoutDirty := True;
  UpdateButtonLayout;

  if FUpdateCount = 0 then
  begin
    CalcLayout;
    UpdateScrollButtons;
  end;
  Invalidate;
end;

// Lightweight tab-switch for use at design time and from the component tree
// Bypasses the OnTabChanging/OnTabChanged event chain so that design-time
// selection does not fire user event handlers
procedure TExtTabCtrl.SetDesignTabIndex(AValue: Integer);
begin
  if FTabIndex <> AValue then
  begin
    SetTabIndex(AValue);
    if Assigned(GlobalDesignHook) then
    begin
      GlobalDesignHook.Modified(Self);
      // Forces the Object Inspector to reload lists
      GlobalDesignHook.RefreshPropertyValues;
    end;
  end;
end;

procedure TExtTabCtrl.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Idx: Integer;
  V, R, CR: TRect;
begin
  if (csDesigning in ComponentState) and (Button in [mbLeft, mbRight]) then
  begin
    // Force the Object Inspector to instantly select this component
    if Assigned(GlobalDesignHook) then
      GlobalDesignHook.SelectOnlyThis(Self);

    if Button = mbLeft then
    begin
      // Child TSpeedButtons don't receive clicks at design time because the
      // designer intercepts them
      if FBtnScrollPrev.Visible and
         PtInRect(FBtnScrollPrev.BoundsRect, Point(X, Y)) then
      begin
        ScrollPrev(nil);
        Exit;
      end;
      if FBtnScrollNext.Visible and
         PtInRect(FBtnScrollNext.BoundsRect, Point(X, Y)) then
      begin
        ScrollNext(nil);
        Exit;
      end;
    end;

    // Switch tabs if a specific tab item was clicked
    Idx := TabAtPos(X, Y);
    if Idx <> -1 then
    begin
      SetDesignTabIndex(Idx);

      // Load the selected tab into the property editor on click
      if (Button = mbLeft) and Assigned(GlobalDesignHook) then
        GlobalDesignHook.SelectOnlyThis(Tabs[Idx]);
    end;

    Exit; // Bypass runtime mouse tracking actions
  end;

inherited MouseDown(Button, Shift, X, Y);

  Idx := TabAtPos(X, Y);
  FMouseDownPos := Point(X, Y);
  FMouseDownIndex := Idx;

  if Idx = -1 then Exit;

  // Close button click: only on left mouse button
  if (Button = mbLeft) and (toShowCloseButton in FTabOptions) and
     FTabs[Idx].ShowCloseButton then
  begin
    V := TabsViewportRect;
    CR := CloseButtonRect(FTabs[Idx]);
    R := FTabs[Idx].FBoundRect;

    if IsHorizontal then
      Types.OffsetRect(R, V.Left - FScrollOffset, V.Top)
    else
      Types.OffsetRect(R, V.Left, V.Top - FScrollOffset);

    Types.OffsetRect(CR, R.Left, R.Top);

    if PtInRect(CR, Point(X, Y)) then
    begin
      DeleteTab(Idx);
      Exit;
    end;
  end;

  // Middle click closes tab
  if (Button = mbMiddle) and (toCloseOnMiddleClick in FTabOptions) then
  begin
    DeleteTab(Idx);
    Exit;
  end;

  if Button = mbLeft then
  begin
    if toGetFocus in FTabOptions then SetFocus;
    TabIndex := Idx;
  end;
end;

procedure TExtTabCtrl.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  i, NT: Integer;
  TabRect: TRect;
  MousePos: Integer;
  V: TRect;
  P: TPoint;
  OldHint: String;
  Msg: TLMMouse;
begin
  if csDesigning in ComponentState then
  begin
    if FHoverTab <> -1 then
    begin
      FHoverTab := -1;
      Invalidate;
    end;
    inherited MouseMove(Shift, X, Y);
    Exit;
  end;

  inherited MouseMove(Shift, X, Y);

  NT := TabAtPos(X, Y);
  V := TabsViewportRect;

  // Capture existing hint to detect change
  OldHint := Self.Hint;

  if not FDragging then
  begin
    // Update hover state and dynamic hint
    if FHoverTab <> NT then
    begin
      FHoverTab := NT;

      if ShowHint then
      begin
        if (NT <> -1) then
        begin
          // Set hint to Tab.Hint or fallback to Tab.Text
          if FTabs[NT].Hint <> '' then
            Self.Hint := FTabs[NT].Hint
          else
            Self.Hint := FTabs[NT].Caption;
        end
        else
        begin
          // Button hover fallback logic
          if FBtnAdd.BoundsRect.Contains(Point(X, Y)) then
            Self.Hint := FButtonHints.AddHint
          else if FBtnScrollPrev.BoundsRect.Contains(Point(X, Y)) then
            Self.Hint := FButtonHints.ScrollPrevHint
          else if FBtnScrollNext.BoundsRect.Contains(Point(X, Y)) then
            Self.Hint := FButtonHints.ScrollNextHint
          else
            Self.Hint := '';
        end;

        if (Self.Hint <> OldHint) then
        begin
          // On macOS/Linux, we must cancel the existing timer/window first
          Application.CancelHint;

          if Self.Hint <> '' then
          begin
            // Construct the message to trigger the Hint Manager immediately
            FillChar(Msg, SizeOf(Msg), 0);
            Msg.Msg := LM_MOUSEMOVE;
            Msg.XPos := X;
            Msg.YPos := Y;
            Application.HintMouseMessage(Self, TLMessage(Msg));
          end;
        end;
      end;
      Invalidate;
    end;

    // Close button hover
    if FHoverCloseTab <> -1 then
    begin
      FHoverCloseTab := -1;
      Invalidate;  // clear the button that was previously highlighted
    end;
    if (NT <> -1) and (toShowCloseButton in FTabOptions) and
       FTabs[NT].ShowCloseButton then
    begin
      TabRect := FTabs[NT].FBoundRect;
      if IsHorizontal then
        Types.OffsetRect(TabRect, V.Left - FScrollOffset, V.Top)
      else
        Types.OffsetRect(TabRect, V.Left, V.Top - FScrollOffset);

      P := Point(X, Y);
      if PtInRect(CloseButtonRect(FTabs[NT]), Point(P.X - TabRect.Left,
        P.Y - TabRect.Top)) then
      begin
        FHoverCloseTab := NT;
        Invalidate;
      end;
    end;

    // Drag detection
    if (ssLeft in Shift) and (FMouseDownIndex <> -1) and
      (toAllowDragReorder in FTabOptions) then
    begin
      if (Abs(X - FMouseDownPos.X) > cDragThreshold) or
        (Abs(Y - FMouseDownPos.Y) > cDragThreshold) then
      begin
        FDragging := True;
        FDragIndex := FMouseDownIndex;
        FDragTargetIndex := FDragIndex;
        MouseCapture := True; // retain mouse events even when cursor leaves control
      end;
    end;
  end
  else
  begin
    // Drag reorder
    FDragTargetIndex := FTabs.Count;

    if IsHorizontal then
      MousePos := X - V.Left + FScrollOffset
    else
      MousePos := Y - V.Top + FScrollOffset;

    for i := 0 to FTabs.Count - 1 do
    begin
      if i = FDragIndex then Continue;

      TabRect := FTabs[i].FBoundRect;

      if IsHorizontal then
      begin
        // Check midpoint of the tab in logical space
        if MousePos < (TabRect.Left + TabRect.Right) div 2 then
        begin
          FDragTargetIndex := i;
          Break;
        end;
      end
      else
      begin
        // Check midpoint of the tab in logical space
        if MousePos < (TabRect.Top + TabRect.Bottom) div 2 then
        begin
          FDragTargetIndex := i;
          Break;
        end;
      end;
    end;
    Invalidate;
  end;
end;

procedure TExtTabCtrl.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Allow: Boolean;
  Idx: Integer;
begin
  if FDragging then
  begin
    // Handle Reordering
    if (FDragTargetIndex <> -1) and (FDragIndex <> FDragTargetIndex) then
    begin
      if FDragTargetIndex > FDragIndex then
        Dec(FDragTargetIndex);

      Allow := True;
      if Assigned(FOnTabReordering) then
        FOnTabReordering(Self, FDragIndex, FDragTargetIndex, Allow);

      if Allow then
      begin
        Self.BeginUpdate; // Batch the internal layout changes
        try
          FTabs.Items[FDragIndex].Index := FDragTargetIndex;
          FTabIndex := FDragTargetIndex;
          FLayoutDirty := True;
        finally
          Self.EndUpdate;
        end;

        if Assigned(FOnTabReordered) then
          FOnTabReordered(Self, FDragIndex, FDragTargetIndex);
      end;
    end;

    FDragging := False;
    FDragIndex := -1;
    FDragTargetIndex := -1;
    FHoverTab := -1;
    FHoverCloseTab := -1;
    MouseCapture := False; // release capture acquired at drag start
    Invalidate;
  end
  else if (Button = mbLeft) then
  begin
    // Handle Single Click Event
    Idx := TabAtPos(X, Y);
    if (Idx <> -1) and (Idx = FMouseDownIndex) then
    begin
      if Assigned(FOnTabClick) then
        FOnTabClick(Self, Idx);
    end;
  end;

  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TExtTabCtrl.MouseLeave;
begin
  FHoverTab := -1;
  FHoverCloseTab := -1;
  Invalidate;
end;

function TExtTabCtrl.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
var
  Candidate: Integer;
begin
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);
  if Result then Exit; // parent already handled it
  if FTabs.Count = 0 then Exit;

  if WheelDelta < 0 then
    Candidate := NextVisibleTab(FTabIndex)
  else
    Candidate := PrevVisibleTab(FTabIndex);

  if Candidate <> -1 then
    TabIndex := Candidate;

  Result := True;
end;

procedure TExtTabCtrl.DoEnter;
begin
  inherited DoEnter;
  Invalidate; // repaint to show focus indicator
end;

procedure TExtTabCtrl.DoExit;
begin
  inherited DoExit;
  Invalidate; // repaint to hide focus indicator
end;

procedure TExtTabCtrl.WMLMGetDlgCode(var Message: TLMessage);
begin
  // Only claim arrow keys when the control is allowed to hold focus
  if toGetFocus in FTabOptions then
    Message.Result := DLGC_WANTARROWS
  else
    Message.Result := 0;
end;

procedure TExtTabCtrl.DblClick;
var
  Idx: Integer;
begin
  inherited DblClick;
  // Use coordinates from MouseDown to identify which tab was double-clicked
  Idx := TabAtPos(FMouseDownPos.X, FMouseDownPos.Y);
  if (Idx <> -1) and Assigned(FOnTabDblClick) then
    FOnTabDblClick(Self, Idx);
end;

procedure TExtTabCtrl.KeyDown(var Key: Word; Shift: TShiftState);
var
  Candidate: Integer;
begin
  inherited KeyDown(Key, Shift);
  case Key of
    VK_LEFT, VK_UP:
    begin
      Candidate := PrevVisibleTab(FTabIndex);
      if Candidate <> -1 then TabIndex := Candidate;
    end;
    VK_RIGHT, VK_DOWN:
    begin
      Candidate := NextVisibleTab(FTabIndex);
      if Candidate <> -1 then TabIndex := Candidate;
    end;
    VK_HOME:
    begin
      Candidate := NextVisibleTab(-1);
      if Candidate <> -1 then TabIndex := Candidate;
    end;
    VK_END:
    begin
      Candidate := PrevVisibleTab(FTabs.Count);
      if Candidate <> -1 then TabIndex := Candidate;
    end;
  end;
end;

procedure TExtTabCtrl.Loaded;
begin
  inherited Loaded;

  if Assigned(FBtnAdd) then
  begin
    FBtnAdd.ShowHint := Self.ShowHint;
    FBtnAdd.Hint := FButtonHints.AddHint;
  end;

  if Assigned(FBtnScrollPrev) then
  begin
    FBtnScrollPrev.ShowHint := ShowHint;
    FBtnScrollPrev.Hint := FButtonHints.ScrollPrevHint;
  end;

  if Assigned(FBtnScrollNext) then
  begin
    FBtnScrollNext.ShowHint := ShowHint;
    FBtnScrollNext.Hint := FButtonHints.ScrollNextHint;
  end;

  UpdateButtonLayout;
  FLayoutDirty := True;
  Invalidate;
end;

procedure TExtTabCtrl.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FImages) then
    FImages := nil;
end;

procedure TExtTabCtrl.CalculatePreferredSize(var PreferredWidth, PreferredHeight: Integer; WithImplicitConstraints: Boolean);
var
  ScaledSize: Integer;
begin
  if FAutoSizeTabs then
  begin
    // AutoSizeTabs --> clamp the control to exactly the tab-strip thickness
    // Return 0 for the free dimension so the LCL leaves it alone
    ScaledSize := GetScale(FTabSize);
    if IsHorizontal then
    begin
      PreferredWidth := 0;            // user controls width freely
      PreferredHeight := ScaledSize;  // height = one tab row
    end
    else
    begin
      PreferredWidth := ScaledSize;   // width = one tab column
      PreferredHeight := 0;           // user controls height freely
    end;
  end
  else
  begin
    // Normal (non-autosize) mode: return a reasonable default size
    // but don't force the control to any particular size
    if IsHorizontal then
    begin
      PreferredWidth := GetScale(200);
      PreferredHeight := GetScale(FTabSize);
    end
    else
    begin
      PreferredWidth := GetScale(FTabSize);
      PreferredHeight := GetScale(200);
    end;
  end;
end;

procedure TExtTabCtrl.CMShowHintChanged(var Message: TLMessage);
begin
  inherited;

  if Assigned(FBtnAdd) then
    FBtnAdd.ShowHint := Self.ShowHint;
  if Assigned(FBtnScrollPrev) then
    FBtnScrollPrev.ShowHint := Self.ShowHint;
  if Assigned(FBtnScrollNext) then
    FBtnScrollNext.ShowHint := Self.ShowHint;
end;

procedure TExtTabCtrl.CMFontChanged(var Message: TLMessage);
var
  i: Integer;
begin
  inherited;
  // Invalidate all cached text metrics, the new font makes them stale
  for i := 0 to FTabs.Count - 1 do
  begin
    FTabs[i].FTextWidth := -1;
    FTabs[i].FTextHeight := -1;
  end;
  InvalidateLayout;
end;

procedure TExtTabCtrl.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TExtTabCtrl.EndUpdate;
begin
  if FUpdateCount > 0 then Dec(FUpdateCount);
  if FUpdateCount = 0 then InvalidateLayout;
end;

procedure TExtTabCtrl.InvalidateLayout;
begin
  FLayoutDirty := True;
  if (FUpdateCount = 0) and HandleAllocated then Invalidate;
end;

function TExtTabCtrl.AddTab(const ACaption: String; AData: TObject): TExtTab;
var
  Allow: Boolean;
  Cap: String;
  Data: TObject;
  NewIndex: Integer;
begin
  Result := nil;
  if FInternalChange > 0 then Exit;

  Cap := ACaption;
  Data := AData;
  Allow := True;

  if not FImportActive then
  begin
    if Assigned(FOnTabCreating) then
      FOnTabCreating(Self, Cap, Data, Allow);
    // User callback may have destroyed or mutated us --> revalidate
    if csDestroying in ComponentState then Exit;
  end;

  if not Allow then Exit;

  NewIndex := -1;
  BeginInternalChange;
  try
    Result := FTabs.Add(Cap);
    Result.Data := Data;

    // Defer layout: if inside BeginUpdate, CalcLayout will fire in EndUpdate
    InvalidateLayout;

    if toActivateNewTab in FTabOptions then
      NewIndex := Result.Index;
  finally
    EndInternalChange;
  end;

  if NewIndex >= 0 then
    SetTabIndex(NewIndex);

  if not FImportActive then
  begin
    if Assigned(FOnTabCreated) then
    begin
      FOnTabCreated(Self);
      if csDestroying in ComponentState then Exit;
    end;
  end;
end;

procedure TExtTabCtrl.DeleteTab(Index: Integer);
var
  Allow: Boolean;
  OldIndex, NewIndex: Integer;
begin
  if (Index < 0) or (Index >= FTabs.Count) then Exit;
  if FInternalChange > 0 then Exit;

  Allow := True;
  if Assigned(FOnTabDeleting) then
  begin
    FOnTabDeleting(Self, Index, Allow);
    // User callback may have mutated collection — revalidate index
    if csDestroying in ComponentState then Exit;
    if (Index < 0) or (Index >= FTabs.Count) then Exit;
  end;
  if not Allow then Exit;

  OldIndex := FTabIndex;
  NewIndex := FTabIndex;

  if Index = FTabIndex then
  begin
    // Deleting the active tab: find a replacement
    NewIndex := NextVisibleTab(Index);
    if NewIndex = -1 then NewIndex := PrevVisibleTab(Index);
    // Adjust for the upcoming index shift caused by the deletion itself
    if (NewIndex > Index) then Dec(NewIndex);

    // Fire OnTabChanging before the structural change
    Allow := True;
    if Assigned(FOnTabChanging) then
    begin
      FOnTabChanging(Self, OldIndex, NewIndex, Allow);
      if csDestroying in ComponentState then Exit;
      if (Index < 0) or (Index >= FTabs.Count) then Exit;
    end;
    if not Allow then Exit;
  end
  else if Index < FTabIndex then
    Dec(NewIndex); // shift active index down

  BeginInternalChange;
  try
    FTabs.Delete(Index);
    FTabIndex := NewIndex;

    // Cancel any in-progress drag — indexes are now stale
    CancelDrag;

    // Reset hover state — indices may now be stale
    FHoverTab := -1;
    FHoverCloseTab := -1;

    NormalizeState;
  finally
    EndInternalChange;
  end;

  // Fire events after the structural change is complete
  if Assigned(FOnTabDeleted) then
  begin
    FOnTabDeleted(Self);
    if csDestroying in ComponentState then Exit;
  end;

  // Fire OnTabChanged if the active tab changed
  if ((NewIndex <> OldIndex) or (Index = OldIndex)) and Assigned(FOnTabChanged) then
    FOnTabChanged(Self, FTabIndex);

  InvalidateLayout;
end;

procedure TExtTabCtrl.ImportFromStrings(Source: TStrings; ClearExisting: Boolean = True);
var
  i: Integer;
  NewTab: TExtTab;
begin
  if not Assigned(Source) then Exit;

  Self.BeginUpdate;
  FImportActive := True;
  try
    if ClearExisting then
      FTabs.Clear;

    for i := 0 to Source.Count - 1 do
    begin
      NewTab := AddTab(Source.Strings[i]);
      if not Assigned(NewTab) then Continue;

      if Assigned(Source.Objects[i]) then
      begin
        if Assigned(FOnImportTab) then
          FOnImportTab(Self, NewTab, Source.Objects[i])
        else
          NewTab.Data := Source.Objects[i];
      end;
    end;

    NormalizeState;
    InvalidateLayout;
  finally
    FImportActive := False;
    Self.EndUpdate;
  end;

  // Fire a single OnTabCreated to signal import is complete
  if Assigned(FOnTabCreated) then
    FOnTabCreated(Self);
end;

constructor TExtTabCtrl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  ControlStyle := ControlStyle + [csClickEvents, csDoubleClicks, csOpaque, csDesignInteractive];
  TabStop := True;

  // Provide a proper initial size when dropped onto a form by a  single click
  with GetControlClassDefaultSize do
    SetInitialBounds(0, 0, CX, CY);

  ShowHint := True;
  DoubleBuffered := True;
  FTabs := TExtTabs.Create(Self);
  FTabIndex := -1;
  FTabStyle := tsFlat;
  FTabPosition := tpTop;
  FTabSize := 26;
  FAutoSizeTabs := False;
  FTabOptions := [toActivateNewTab, toShowCloseButton, toShowAddButton,
                  toCloseOnMiddleClick, toAllowDragReorder, toGetFocus,
                  toShowFocusRect];

  FAddImage := TBitmap.Create;
  FCloseImage := TBitmap.Create;
  FScrollImages[0] := TBitmap.Create;
  FScrollImages[1] := TBitmap.Create;

  LoadBitmapFromLRS('tab_new', FAddImage);
  LoadBitmapFromLRS('cross', FCloseImage);
  LoadBitmapFromLRS('tab_prev', FScrollImages[0]);
  LoadBitmapFromLRS('tab_next', FScrollImages[1]);

  FButtonImages := TButtonImages.Create;
  FButtonImages.OnChange := @ButtonImagesChanged;
  FButtonHints := TButtonHints.Create;

  FBtnAdd := TSpeedButton.Create(Self);
  FBtnAdd.Parent := Self;
  FBtnAdd.Flat := True;
  FBtnAdd.ParentShowHint := False;
  FBtnAdd.Glyph.Assign(FAddImage);
  FBtnAdd.NumGlyphs := 1;
  FBtnAdd.OnClick := @AddBtnClick;
  FBtnAdd.BringToFront;

  FBtnScrollPrev := TSpeedButton.Create(Self);
  FBtnScrollPrev.Parent := Self;
  FBtnScrollPrev.Flat := True;
  FBtnScrollPrev.ParentShowHint := False;
  FBtnScrollPrev.ShowHint := ShowHint;
  FBtnScrollPrev.OnClick := @ScrollPrev;

  FBtnScrollNext := TSpeedButton.Create(Self);
  FBtnScrollNext.Parent := Self;
  FBtnScrollNext.Flat := True;
  FBtnScrollNext.ParentShowHint := False;
  FBtnScrollNext.ShowHint := ShowHint;
  FBtnScrollNext.OnClick := @ScrollNext;

  FCachedAddGlyph := TBitmap.Create;
  FCachedScrollGlyphs[0] := TBitmap.Create;
  FCachedScrollGlyphs[1] := TBitmap.Create;
  FLastRotation := -1;

  FMouseDownIndex := -1;
  FDragIndex := -1;
  FDragTargetIndex := -1;
  FHoverTab := -1;
  FHoverCloseTab := -1;
  FAddTabCounter := 0;
  FImportActive := False;
  FInternalChange := 0;
end;

destructor TExtTabCtrl.Destroy;
begin
  // Cancel any pending hint window that may reference our handle
  Application.CancelHint;
  ShowHint := False;

  // Explicitly free child buttons before their glyph bitmaps are freed
  FreeAndNil(FBtnAdd);
  FreeAndNil(FBtnScrollPrev);
  FreeAndNil(FBtnScrollNext);

  FreeAndNil(FCachedAddGlyph);
  FreeAndNil(FCachedScrollGlyphs[0]);
  FreeAndNil(FCachedScrollGlyphs[1]);

  FreeAndNil(FButtonImages);
  FreeAndNil(FButtonHints);

  FreeAndNil(FAddImage);
  FreeAndNil(FCloseImage);
  FreeAndNil(FScrollImages[0]);
  FreeAndNil(FScrollImages[1]);
  FreeAndNil(FTabs);

  inherited Destroy;
end;

{ TExtTabCtrlEditor }
procedure TExtTabCtrlEditor.ExecuteVerb(Index: Integer);
var
  TabControl: TExtTabCtrl;
  TargetIndex: Integer;
  CurrentTab, NewTab: TExtTab;

procedure RebuildDesignerTabTree(Ctrl: TExtTabCtrl; OldIdx, NewIdx: Integer);
  begin
    // Move the tab in the collection
    Ctrl.Tabs[OldIdx].Index := NewIdx;
    Ctrl.TabIndex := NewIdx;

    // Notify the designer. The component tree does not reorder existing
    // nodes in Lazarus, but the control renders correctly and the Object
    // Inspector reflects the right state. Attempting to delete+readd nodes
    // causes "list index out of bounds" because DeletePersistent frees the
    // collection items while the loop is still running.
    Designer.Modified;
    if Assigned(GlobalDesignHook) then
    begin
      GlobalDesignHook.RefreshPropertyValues;
      GlobalDesignHook.SelectOnlyThis(Ctrl.Tabs[NewIdx]);
    end;
  end;
begin
  TabControl := TExtTabCtrl(Component);
  TargetIndex := TabControl.TabIndex;

  case Index of
    0: begin // Add Tab
      NewTab := TabControl.AddTab('New Tab ' + IntToStr(TabControl.Tabs.Count + 1));
      Designer.Modified;
      if Assigned(NewTab) and Assigned(GlobalDesignHook) then
      begin
        GlobalDesignHook.PersistentAdded(NewTab, True);
        Exit;
      end;
    end;

    1: begin // Delete Tab
      if (TargetIndex >= 0) and (TargetIndex < TabControl.Tabs.Count) then
      begin
        CurrentTab := TabControl.Tabs[TargetIndex];
        if Assigned(GlobalDesignHook) then
          GlobalDesignHook.DeletePersistent(TPersistent(CurrentTab));
        //TabControl.DeleteTab(TargetIndex);
      end;
    end;

    2: begin // Move Left / Move Up
      if TargetIndex > 0 then
      begin
        RebuildDesignerTabTree(TabControl, TargetIndex, TargetIndex - 1);
        Exit;
      end;
    end;

    3: begin // Move Right / Move Down
      if (TargetIndex >= 0) and (TargetIndex < TabControl.Tabs.Count - 1) then
      begin
        RebuildDesignerTabTree(TabControl, TargetIndex, TargetIndex + 1);
        Exit;
      end;
    end;
  end;

  Designer.Modified;
  Designer.SelectOnlyThisComponent(TabControl);
end;

function TExtTabCtrlEditor.GetVerb(Index: Integer): String;
var
  TabControl: TExtTabCtrl;
begin
  TabControl := TExtTabCtrl(Component);

  case Index of
    0: Result := 'Add Tab';
    1: Result := 'Delete Tab';
    2: if TabControl.IsHorizontal then
         Result := 'Move Left'
       else
         Result := 'Move Up';
    3: if TabControl.IsHorizontal then
         Result := 'Move Right'
       else
         Result := 'Move Down';
    else
      Result := '';
  end;
end;

function TExtTabCtrlEditor.GetVerbCount: Integer;
begin
  Result := 4;
end;

procedure Register;
begin
  RegisterComponents('Common Controls', [TExtTabCtrl]);
  RegisterComponentEditor(TExtTabCtrl, TExtTabCtrlEditor);
  // Register the custom property editor so that changing TabIndex in the
  // Object Inspector immediately updates the visible tab at design time
  RegisterPropertyEditor(TypeInfo(Integer), TExtTabCtrl, 'TabIndex', TTabIndexPropertyEditor);
end;

{ TTabIndexPropertyEditor }
procedure TTabIndexPropertyEditor.GetValues(Proc: TGetStrProc);
var
  Ctrl: TExtTabCtrl;
  i: Integer;
begin
  Ctrl := GetComponent(0) as TExtTabCtrl;
  if not Assigned(Ctrl) then Exit;
  for i := 0 to Ctrl.Tabs.Count - 1 do
    Proc(IntToStr(i) + ' - ' + Ctrl.Tabs[i].Caption);
end;

function TTabIndexPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueList, paRevertable];
end;

function TTabIndexPropertyEditor.GetValue: String;
var
  Ctrl: TExtTabCtrl;
begin
  Ctrl := GetComponent(0) as TExtTabCtrl;
  if Assigned(Ctrl) and (Ctrl.TabIndex >= 0) and (Ctrl.TabIndex < Ctrl.Tabs.Count) then
    Result := IntToStr(Ctrl.TabIndex) + ' - ' + Ctrl.Tabs[Ctrl.TabIndex].Caption
  else
    Result := IntToStr(GetOrdValue);
end;

procedure TTabIndexPropertyEditor.SetValue(const NewValue: String);
var
  Ctrl: TExtTabCtrl;
  Idx: Integer;
  S: String;
begin
  Ctrl := GetComponent(0) as TExtTabCtrl;
  if not Assigned(Ctrl) then Exit;
  // Accept either a plain integer ("2") or the "2 - Caption" format
  S := Trim(NewValue);
  if Pos(' ', S) > 0 then
    S := Copy(S, 1, Pos(' ', S) - 1);
  Idx := StrToIntDef(S, -1);
  Ctrl.SetDesignTabIndex(Idx);
end;

initialization
  {$I ExtTabCtrl.lrs}
end.
