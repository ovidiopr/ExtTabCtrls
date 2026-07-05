unit ExtTabCtrl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, FPImage, GraphType, Graphics, Buttons, LCLType,
  Types, Math, LResources, LCLIntf, ImgList, LMessages, Forms, Menus,
  LazMethodList, ExtTabCtrlStyles{$IFDEF LCLDesign}, PropEdits{$ENDIF};

type
  TExtTabOption = (etoActivateNewTab, etoShowCloseButton, etoShowAddButton,
                   etoCloseOnMiddleClick, etoAllowDragReorder,
                   etoRotateTabImages, etoRotateAddImage, etoGetFocus,
                   etoShowFocusRect, etoActiveBold, etoActiveItalic);
  TExtTabOptions = set of TExtTabOption;

  TExtButtonType = (ebtClose, ebtAdd, ebtPrev, ebtNext);

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
  TTabMouseEvent = procedure(Sender: TObject; Index: Integer) of object;
  TTabDrawEvent = procedure(Sender: TObject; ACanvas: TCanvas; ARect: TRect;
    IsActive, IsHover: Boolean; var Options: TExtTabStyleOptions; var Skip: Boolean) of object;
  TButtonDrawEvent = procedure(Sender: TObject; ACanvas: TCanvas; ARect: TRect;
    AButtonType: TExtButtonType; ATab: TExtTab; IsActive, IsHover: Boolean; var Skip: Boolean) of object;

  TCustomExtTabCtrl = class;

  TExtButtonImageIndexes = class(TPersistent)
  private
    FOwnerCtrl: TCustomExtTabCtrl;
    FImgIndex: array[0..3] of TImageIndex;
    FSavedIndex: Array[0..3] of TImageIndex;
    FOnChange: TNotifyEvent;
    function GetIndex(Index: Integer): TImageIndex;
    procedure SetIndex(Index: Integer; Value: TImageIndex);
  public
    constructor Create(AOwner: TCustomExtTabCtrl);
    procedure Assign(Source: TPersistent); override;
    procedure Save;
    procedure Restore;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    function GetOwner: TPersistent; override;

    property ScrollPrevIndex: TImageIndex index 0 read GetIndex write SetIndex default -1;
    property ScrollNextIndex: TImageIndex index 1 read GetIndex write SetIndex default -1;
    property AddIndex: TImageIndex index 2 read GetIndex write SetIndex default -1;
    property CloseIndex: TImageIndex index 3 read GetIndex write SetIndex default -1;
  end;

  TExtButtonHints = class(TPersistent)
  private
    FAddHint: String;
    FScrollPrevHint: String;
    FScrollNextHint: String;
    FCloseHint: String;
    FOnChange: TNotifyEvent;

    procedure SetAddHint(AValue: String);
    procedure SetScrollPrevHint(AValue: String);
    procedure SetScrollNextHint(AValue: String);
    procedure SetCloseHint(AValue: String);
  public
    procedure Assign(Source: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property AddHint: String read FAddHint write SetAddHint;
    property ScrollPrevHint: String read FScrollPrevHint write SetScrollPrevHint;
    property ScrollNextHint: String read FScrollNextHint write SetScrollNextHint;
    property CloseHint: String read FCloseHint write SetCloseHint;
  end;

  TExtFontOptions = class(TPersistent)
  private
    FFontSize: Integer;
    FFontColor: TColor;
    FFontStyles: TFontStyles;
    FOnRedraw: TNotifyEvent;

    procedure SetFontSize(AValue: Integer);
    procedure SetFontColor(AValue: TColor);
    procedure SetFontStyles(AValue: TFontStyles);
  protected
    procedure Changed;
  public
    constructor Create;
    procedure Assign(Source: TPersistent); override;
    property OnRedraw: TNotifyEvent read FOnRedraw write FOnRedraw;
  published
    property FontSize: Integer read FFontSize write SetFontSize default 0;
    property FontColor: TColor read FFontColor write SetFontColor default clNone;
    property FontStyles: TFontStyles read FFontStyles write SetFontStyles default [];
  end;

  TExtImagesWidth = class(TPersistent)
  private
    FPrevWidth: Integer;
    FNextWidth: Integer;
    FAddWidth: Integer;
    FCloseWidth: Integer;
    FTabWidth: Integer;

    FOnChange: TNotifyEvent;
    procedure SetWidth(Index, Value: Integer);
  public
    constructor Create;
    procedure Assign(Source: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property PrevWidth: Integer index 0 read FPrevWidth write SetWidth default 0;
    property NextWidth: Integer index 1 read FNextWidth write SetWidth default 0;
    property AddWidth: Integer index 2 read FAddWidth write SetWidth default 0;
    property CloseWidth: Integer index 3 read FCloseWidth write SetWidth default 0;
    property TabsWidth: Integer index 4 read FTabWidth write SetWidth default 0;
  end;

  TExtTab = class(TCollectionItem)
  private
    FCaption: TCaption;
    FColor: TColor;
    FStripeColor: TColor;
    FVisible: Boolean;
    FValue: String;
    FData: TObject;
    FFontOptions: TExtFontOptions;
    FOwnerCtrl: TCustomExtTabCtrl;
    FImage: TBitmap;
    FImageIndex: TImageIndex;
    FHint: String;
    FShowCloseButton: Boolean;
    FTextWidth: Integer;
    FTextHeight: Integer;
    FOnChange: TNotifyEvent;
    FInternalOnChange: TNotifyEvent;
    procedure SetCaption(AValue: TCaption);
    procedure SetColor(AValue: TColor);
    procedure SetStripeColor(AValue: TColor);
    procedure SetVisible(AValue: Boolean);
    procedure SetImage(AValue: TBitmap);
    procedure SetImageIndex(AValue: TImageIndex);
    function GetImage: TBitmap;
    procedure SetShowCloseButton(AValue: Boolean);
    procedure Redraw(Sender: TObject);
  protected
    FBoundRect: TRect;
    function GetDisplayName: String; override;

    procedure DoChange; virtual;
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
    function GetOwner: TPersistent; override;

    property BoundRect: TRect read FBoundRect;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property InternalOnChange: TNotifyEvent read FInternalOnChange write FInternalOnChange;
  published
    property Caption: TCaption read FCaption write SetCaption;
    property Color: TColor read FColor write SetColor default clNone;
    property StripeColor: TColor read FStripeColor write SetStripeColor default clNone;
    property Visible: Boolean read FVisible write SetVisible default True;
    property Value: String read FValue write FValue;
    property Data: TObject read FData write FData;
    property FontOptions: TExtFontOptions read FFontOptions;
    property Image: TBitmap read GetImage write SetImage;
    property ImageIndex: TImageIndex read FImageIndex write SetImageIndex default -1;
    property Hint: String read FHint write FHint;
    property ShowCloseButton: Boolean read FShowCloseButton write SetShowCloseButton default True;
  end;

  TExtTabs = class(TCollection)
  private
    FOwnerCtrl: TCustomExtTabCtrl;
    function GetItems(Index: Integer): TExtTab;
  protected
    procedure Update(Item: TCollectionItem); override;
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TCustomExtTabCtrl);
    function Add(const ACaption: String): TExtTab;
    property Items[Index: Integer]: TExtTab read GetItems; default;
  end;

  TCustomExtTabCtrl = class(TCustomControl)
  private
    FUpdateCount: Integer;
    FLayoutDirty: Boolean;
    FTabSize: Integer;
    FTotalTabsSize: Integer;
    FTabs: TExtTabs;
    FTabIndex: Integer;
    FTabStyle: TExtTabStyle;
    FTabOptions: TExtTabOptions;
    FBtnAdd: TSpeedButton;

    FImages: TCustomImageList;
    FInternalImages: TCustomImageList;    // Copy of FImages with rotated images
    FButtonImageIndexes: TExtButtonImageIndexes;
    FButtonHints: TExtButtonHints;
    FImagesWidth: TExtImagesWidth;
    FBorderColor: TColor;
    FStyleOptions: TExtTabStyleOptions;

    FDragging: Boolean;
    FDragIndex, FDragTargetIndex: Integer;
    FMouseDownPos: TPoint;
    FMouseDownIndex: Integer;

    FTabPosition: TExtTabPosition;
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
    FOnGetFocus: TNotifyEvent;
    FOnLostFocus: TNotifyEvent;
    FOnMouseEnterTab: TTabMouseEvent;
    FOnMouseLeaveTab: TTabMouseEvent;
    FOnDrawTab: TTabDrawEvent;
    FOnDrawButton: TButtonDrawEvent;

    FScrollOffset: Integer;
    FManualScroll: Boolean;
    FHoverTab, FHoverCloseTab: Integer;
    FBtnScrollPrev, FBtnScrollNext: TSpeedButton;

    FAddTabCounter: Integer;
    FImportActive: Boolean;
    FInternalChange: Integer;
    FMinCaptionLen: Integer;
    FMaxCaptionLen: Integer;

    procedure BeginInternalChange;
    procedure EndInternalChange;
    procedure CancelDrag;

    function GetIsUpdating: Boolean;

    procedure SetTabSize(AValue: Integer);
    function IsStoredTabSize: Boolean;
    procedure AddBtnClick(Sender: TObject);
    procedure ScrollPrev(Sender: TObject);
    procedure ScrollNext(Sender: TObject);
    procedure AddBtnPaint(Sender: TObject);
    procedure ScrollBtnPaint(Sender: TObject);

    procedure SetTabStyle(AValue: TExtTabStyle);
    procedure SetTabPosition(AValue: TExtTabPosition);
    procedure SetTabOptions(AValue: TExtTabOptions);
    procedure SetImages(AValue: TCustomImageList);
    procedure SetButtonImageIndexes(AValue: TExtButtonImageIndexes);
    procedure SetButtonHints(AValue: TExtButtonHints);
    procedure SetImagesWidth(AValue: TExtImagesWidth);
    procedure SetBorderColor(AValue: TColor);
    function BuildStyleContext(Tab: TExtTab): TExtTabDrawContext;
    procedure SetTabs(AValue: TExtTabs);
    procedure SetMinCaptionLen(AValue: Integer);
    procedure SetMaxCaptionLen(AValue: Integer);

    procedure SetAddMenu(AValue: TPopupMenu);
    function GetAddMenu: TPopupMenu;

    procedure SetOnDrawTab(AValue: TTabDrawEvent);
    procedure SetOnDrawButton(AValue: TButtonDrawEvent);

    procedure ButtonImagesChanged(Sender: TObject);
    procedure ButtonHintsChanged(Sender: TObject);
    procedure ImagesWidthChanged(Sender: TObject);
    function TabsViewportRect(ShowPrev, ShowNext, ShowAdd: Boolean): TRect; overload;
    function TabsViewportRect: TRect; overload;
    procedure AnchorButtons;
    function GetDisplayCaption(Tab: TExtTab): String;
    function CloseButtonRect(Tab: TExtTab): TRect;
    function MaxScrollOffset: Integer;
    function AxisSize(const R: TRect): Integer;
    procedure GetAxisSpan(const R: TRect; out AStart, AEnd: Integer);
    procedure OffsetToView(var R: TRect; const View: TRect);
    function ViewToContent(const P: TPoint; const View: TRect): TPoint;
    procedure EnsureTabVisible(Index: Integer);
    procedure ScrollTabIntoView(Index: Integer);
    procedure SnapScrollOffset;
    procedure UpdateScrollButtons;
    function GetScale(Value: Integer): Integer;
    function MinUsefulTabSize: Integer;
    function GetIconExtent(AImageIndex, AImageWidth: Integer; IsWidth: Boolean): Integer;

    procedure DrawTabTextAndImage(ACanvas: TCanvas; const R: TRect; Tab: TExtTab; IsActive: Boolean; DefaultFontColor: TColor);
    procedure DrawCloseButton(ACanvas: TCanvas; const R: TRect; Tab: TExtTab; IsActive: Boolean);
    procedure DrawColorStripe(ACanvas: TCanvas; const R: TRect; Tab: TExtTab; Indent: Integer);

    function ResolveColor(AColor: TColor): TColor;
    function InactiveFontColor: TColor;

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
    cDefaultTabSize = 26;

    cContentIndent = 6;
    cTabOverlap = 2;
    cImageSpacing = 6;
    cDragThreshold = 6;

    class function GetControlClassDefaultSize: TSize; override;

    procedure Paint; override;
    procedure Resize; override;
    procedure CalcLayout; virtual;

    procedure SetTabIndex(AValue: Integer); virtual;
    procedure NormalizeState; virtual;

    procedure DrawTab(ACanvas: TCanvas; Index: Integer; ARect: TRect; IsActive: Boolean); virtual;

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
    procedure DblClick; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;

    function TabAtPos(X, Y: Integer): Integer;

    property IsUpdating: Boolean read GetIsUpdating;
    property StyleOptions: TExtTabStyleOptions read FStyleOptions;

    procedure DoEnter; override;
    procedure DoExit; override;

    procedure WMLMGetDlgCode(var Message: TLMessage); message LM_GETDLGCODE;
    procedure CMDesignHitTest(var Message: TLMessage); message CM_DESIGNHITTEST;
    procedure CMShowHintChanged(var Message: TLMessage); message CM_SHOWHINTCHANGED;
    procedure CMFontChanged(var Message: TLMessage); message CM_FONTCHANGED;

    procedure CreateWnd; override;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure CalculatePreferredSize(var PreferredWidth, PreferredHeight: Integer; WithImplicitConstraints: Boolean); override;

    procedure DoAutoAdjustLayout(const AMode: TLayoutAdjustmentPolicy; const AXProportion, AYProportion: Double); override;
    procedure PrepareInternalTabImages(ARotation: Integer); virtual;
    procedure UpdateImages; virtual;
    procedure UpdateBtnImages; virtual;
    procedure UpdateTabSizeForImages; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeginUpdate; virtual;
    procedure EndUpdate; virtual;
    function IsVertical: Boolean;
    function IsHorizontal: Boolean;
    procedure InvalidateLayout;
    function NextVisibleTab(FromIndex: Integer): Integer; virtual;
    function PrevVisibleTab(FromIndex: Integer): Integer; virtual;
    function AddTab(const ACaption: String; AData: TObject = nil): TExtTab; virtual;
    procedure DeleteTab(Index: Integer); virtual;
    procedure ImportFromStrings(Source: TStrings; ClearExisting: Boolean = True); virtual;
    procedure SetDesignTabIndex(AValue: Integer); virtual;
  protected
    property Align;
    property AutoSize;
    property BorderSpacing;
    property Color default clForm;
    property DoubleBuffered;
    property Tabs: TExtTabs read FTabs write SetTabs;
    property TabIndex: Integer read FTabIndex write SetTabIndex default -1;
    property TabSize: Integer read FTabSize write SetTabSize stored IsStoredTabSize;
    property TabStyle: TExtTabStyle read FTabStyle write SetTabStyle default etsFlat;
    property TabOptions: TExtTabOptions read FTabOptions write SetTabOptions
                           default [etoActivateNewTab, etoShowCloseButton,
                                    etoShowAddButton, etoCloseOnMiddleClick,
                                    etoAllowDragReorder, etoGetFocus, etoShowFocusRect];
    property TabPosition: TExtTabPosition read FTabPosition write SetTabPosition default etpTop;

    property ShowHint default True;
    property Font;
    property ParentFont;
    property ParentColor;

    property Images: TCustomImageList read FImages write SetImages;
    property ButtonImageIndexes: TExtButtonImageIndexes read FButtonImageIndexes write SetButtonImageIndexes;
    property ImagesWidth: TExtImagesWidth read FImagesWidth write SetImagesWidth;
    property ButtonHints: TExtButtonHints read FButtonHints write SetButtonHints;
    property BorderColor: TColor read FBorderColor write SetBorderColor default clBtnShadow;

    property AddMenu: TPopupMenu read GetAddMenu write SetAddMenu;

    property MinCaptionLen: Integer read FMinCaptionLen write SetMinCaptionLen default 5;
    property MaxCaptionLen: Integer read FMaxCaptionLen write SetMaxCaptionLen default 25;

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
    property OnGetFocus: TNotifyEvent read FOnGetFocus write FOnGetFocus;
    property OnLostFocus: TNotifyEvent read FOnLostFocus write FOnLostFocus;
    property OnMouseEnterTab: TTabMouseEvent read FOnMouseEnterTab write FOnMouseEnterTab;
    property OnMouseLeaveTab: TTabMouseEvent read FOnMouseLeaveTab write FOnMouseLeaveTab;
    property OnDrawTab: TTabDrawEvent read FOnDrawTab write SetOnDrawTab;
    property OnDrawButton: TButtonDrawEvent read FOnDrawButton write SetOnDrawButton;
  end;

  { TExtTabCtrl }
  TExtTabCtrl = class(TCustomExtTabCtrl)
  published
    property Align;
    property AutoSize;
    property BorderSpacing;
    property Color;
    property DoubleBuffered;
    property Tabs;
    property TabIndex;
    property TabSize;
    property TabStyle;
    property TabOptions;
    property TabPosition;

    property ShowHint;
    property Font;
    property ParentFont;
    property ParentColor;

    property Images;
    property ButtonImageIndexes;
    property ImagesWidth;
    property ButtonHints;
    property BorderColor;

    property AddMenu;

    property MinCaptionLen;
    property MaxCaptionLen;

    property OnTabReordering;
    property OnTabReordered;
    property OnTabCreating;
    property OnTabCreated;
    property OnTabDeleting;
    property OnTabDeleted;
    property OnTabChanging;
    property OnTabChanged;
    property OnTabClick;
    property OnTabDblClick;
    property OnImportTab;
    property OnAddButtonClick;
    property OnGetFocus;
    property OnLostFocus;
    property OnMouseEnterTab;
    property OnMouseLeaveTab;
    property OnDrawTab;
    property OnDrawButton;
  end;

implementation

{ TExtButtonImageIndexes }
constructor TExtButtonImageIndexes.Create(AOwner: TCustomExtTabCtrl);
begin
  FOwnerCtrl := AOwner;
  FillChar(FImgIndex, SizeOf(FImgIndex), $FF);
  FillChar(FSavedIndex, SizeOf(FSavedIndex), $FF);
end;

procedure TExtButtonImageIndexes.Assign(Source: TPersistent);
begin
  if Source is TExtButtonImageIndexes then
  begin
    FImgIndex := TExtButtonImageIndexes(Source).FImgIndex;
    if Assigned(FOnChange) then FOnChange(Self);
  end
  else
    inherited Assign(Source);
end;

function TExtButtonImageIndexes.GetIndex(Index: Integer): TImageIndex;
begin
  Result := FImgIndex[Index];
end;

procedure TExtButtonImageIndexes.Restore;
var
  i: Integer;
begin
  for i := Low(FImgIndex) to High(FImgIndex) do
    FImgIndex[i] := FSavedIndex[i];
end;

procedure TExtButtonImageIndexes.Save;
var
  i: Integer;
begin
  for i := Low(FImgIndex) to High(FImgIndex) do
    FSavedIndex[i] := FImgIndex[i];
end;

procedure TExtButtonImageIndexes.SetIndex(Index: Integer; Value: TImageIndex);
begin
  if GetIndex(Index) <> Value then
  begin
    FImgIndex[Index] := Value;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

function TExtButtonImageIndexes.GetOwner: TPersistent;
begin
  Result := FOwnerCtrl;
end;

{ TExtButtonHints }
procedure TExtButtonHints.SetAddHint(AValue: String);
begin
  if FAddHint <> AValue then
  begin
    FAddHint := AValue;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TExtButtonHints.SetScrollPrevHint(AValue: String);
begin
  if FScrollPrevHint <> AValue then
  begin
    FScrollPrevHint := AValue;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TExtButtonHints.SetScrollNextHint(AValue: String);
begin
  if FScrollNextHint <> AValue then
  begin
    FScrollNextHint := AValue;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TExtButtonHints.SetCloseHint(AValue: String);
begin
  if FCloseHint <> AValue then
  begin
    FCloseHint := AValue;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TExtButtonHints.Assign(Source: TPersistent);
begin
  if Source is TExtButtonHints then
  begin
    FAddHint := TExtButtonHints(Source).AddHint;
    FScrollPrevHint := TExtButtonHints(Source).ScrollPrevHint;
    FScrollNextHint := TExtButtonHints(Source).ScrollNextHint;
    FCloseHint := TExtButtonHints(Source).CloseHint;

    if Assigned(FOnChange) then FOnChange(Self);
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

procedure TExtFontOptions.SetFontColor(AValue: TColor);
begin
  if FFontColor <> AValue then
  begin
    FFontColor := AValue;
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
  FFontColor := clNone;
  FFontStyles := [];
end;

procedure TExtFontOptions.Assign(Source: TPersistent);
begin
  if Source is TExtFontOptions then
  begin
    FFontSize := TExtFontOptions(Source).FontSize;
    FFontColor := TExtFontOptions(Source).FontColor;
    FFontStyles := TExtFontOptions(Source).FontStyles;
    Changed;
  end
  else
    inherited Assign(Source);
end;

{ TExtImagesWidth }
constructor TExtImagesWidth.Create;
begin
  FPrevWidth := 0;
  FNextWidth := 0;
  FAddWidth := 0;
  FCloseWidth := 0;
  FTabWidth := 0;
end;

procedure TExtImagesWidth.Assign(Source: TPersistent);
begin
  if Source is TExtImagesWidth then
  begin
    FPrevWidth := TExtImagesWidth(Source).PrevWidth;
    FNextWidth := TExtImagesWidth(Source).NextWidth;
    FAddWidth := TExtImagesWidth(Source).AddWidth;
    FCloseWidth := TExtImagesWidth(Source).CloseWidth;
    FTabWidth := TExtImagesWidth(Source).TabsWidth;
    if Assigned(FOnChange) then FOnChange(Self);
  end
  else
    inherited Assign(Source);
end;

procedure TExtImagesWidth.SetWidth(Index, Value: Integer);
var
  Ptr: ^Integer;
begin
  Ptr := nil;
  case Index of
    0: Ptr := @FPrevWidth;
    1: Ptr := @FNextWidth;
    2: Ptr := @FAddWidth;
    3: Ptr := @FCloseWidth;
    4: Ptr := @FTabWidth;
  end;
  if Ptr = nil then Exit;
  if Ptr^ <> Value then
  begin
    Ptr^ := Value;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

{ TExtTab }
procedure TExtTab.DoChange;
begin
  if Assigned(FOnChange) then FOnChange(Self);
  if Assigned(FInternalOnChange) then FInternalOnChange(Self);
end;

procedure TExtTab.SetCaption(AValue: TCaption);
begin
  if FCaption <> AValue then
  begin
    FCaption := AValue;
    FTextWidth := -1;
    FTextHeight := -1;
    Changed(False);
    Redraw(Self);
    DoChange;
  end;
end;

procedure TExtTab.SetColor(AValue: TColor);
begin
  if FColor = AValue then Exit;
  FColor := AValue;
  if Assigned(FOwnerCtrl) then
    FOwnerCtrl.Invalidate;
  DoChange;
end;

procedure TExtTab.SetStripeColor(AValue: TColor);
begin
  if FStripeColor = AValue then Exit;
  FStripeColor := AValue;
  if Assigned(FOwnerCtrl) then
    FOwnerCtrl.Invalidate;
  DoChange;
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

    if (etoActiveBold in FOwnerCtrl.FTabOptions) or (etoActiveItalic in FOwnerCtrl.FTabOptions) then
    begin
      FOwnerCtrl.FTabs[OldIndex].FTextWidth := -1;
      if Candidate <> -1 then
        FOwnerCtrl.FTabs[Candidate].FTextWidth := -1;
    end;

    if Candidate <> -1 then
      FOwnerCtrl.ScrollTabIntoView(Candidate);

    FOwnerCtrl.InvalidateLayout;
    if Assigned(FOwnerCtrl.FOnTabChanged) then
      FOwnerCtrl.FOnTabChanged(FOwnerCtrl, Candidate);
    DoChange;
  end
  else
  begin
    FVisible := AValue;
    FOwnerCtrl.InvalidateLayout;
    DoChange;
  end;
end;

function TExtTab.GetImage: TBitmap;
begin
  if FImage = nil then
    FImage := TBitmap.Create;
  Result := FImage;
end;

procedure TExtTab.SetShowCloseButton(AValue: Boolean);
begin
  if FShowCloseButton = AValue then Exit;
  FShowCloseButton := AValue;
  if Assigned(FOwnerCtrl) then
    FOwnerCtrl.InvalidateLayout;
  DoChange;
end;

procedure TExtTab.SetImage(AValue: TBitmap);
begin
  if FImage = AValue then Exit;
  FreeAndNil(FImage);
  FImage := AValue;
  FTextWidth := -1;
  Redraw(Self);
  if Assigned(FOwnerCtrl) then FOwnerCtrl.UpdateTabSizeForImages;
  DoChange;
end;

procedure TExtTab.SetImageIndex(AValue: TImageIndex);
begin
  if FImageIndex = AValue then Exit;
  FImageIndex := AValue;
  FTextWidth := -1;
  FTextHeight := -1;
  Redraw(Self);
  if Assigned(FOwnerCtrl) then
    FOwnerCtrl.UpdateTabSizeForImages;
  DoChange;
end;

procedure TExtTab.Redraw(Sender: TObject);
begin
  if Sender = FFontOptions then
  begin
    FTextWidth := -1;
    FTextHeight := -1;

    DoChange;
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

  if Assigned(ACollection) then
    FOwnerCtrl := TExtTabs(ACollection).FOwnerCtrl
  else
    FOwnerCtrl := nil;
  FFontOptions := TExtFontOptions.Create;
  FFontOptions.OnRedraw := @Redraw;
  FVisible := True;
  FColor := clNone;
  FStripeColor := clNone;
  FImageIndex := -1;
  FTextWidth := -1;
  FTextHeight := -1;
  FShowCloseButton := True;
  // Provide a default caption so new tabs are never empty
  FCaption := 'New Tab ' + IntToStr(Index + 1);
end;

destructor TExtTab.Destroy;
begin
  FImage.Free;
  FFontOptions.Free;
  inherited Destroy;
end;

function TExtTab.GetOwner: TPersistent;
begin
  Result := FOwnerCtrl;
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
    {$IFDEF LCLDesign}
    if (csDesigning in FOwnerCtrl.ComponentState) and Assigned(GlobalDesignHook) then
    begin
      GlobalDesignHook.Modified(FOwnerCtrl);
      GlobalDesignHook.RefreshPropertyValues;
    end;
    {$ENDIF}
  end;
end;

function TExtTabs.GetOwner: TPersistent;
begin
  Result := FOwnerCtrl;
end;

constructor TExtTabs.Create(AOwner: TCustomExtTabCtrl);
begin
  inherited Create(TExtTab);
  FOwnerCtrl := AOwner;
end;

function TExtTabs.Add(const ACaption: String): TExtTab;
begin
  Result := inherited Add as TExtTab;
  Result.Caption := ACaption;
end;

{ TCustomExtTabCtrl }
procedure TCustomExtTabCtrl.BeginInternalChange;
begin
  Inc(FInternalChange);
end;

procedure TCustomExtTabCtrl.EndInternalChange;
begin
  if FInternalChange > 0 then Dec(FInternalChange);
end;

procedure TCustomExtTabCtrl.CancelDrag;
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

procedure TCustomExtTabCtrl.NormalizeState;
var
  Candidate: Integer;
  View: TRect;
  TabStart, TabEnd, ViewSize: Integer;
begin
  CalcLayout;

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

  SnapScrollOffset;

  if HandleAllocated and not FManualScroll and
     (FTabIndex >= 0) and (FTabIndex < FTabs.Count) then
  begin
    View := TabsViewportRect;
    ViewSize := AxisSize(View);
    GetAxisSpan(FTabs[FTabIndex].FBoundRect, TabStart, TabEnd);
    if (TabStart < FScrollOffset) or (TabEnd > FScrollOffset + ViewSize) then
      EnsureTabVisible(FTabIndex);
  end;

  // Resync buttons so Paint's viewport never disagrees with what's on screen
  UpdateScrollButtons;

  // Reset stale hover state
  if (FHoverTab >= FTabs.Count) then FHoverTab := -1;
  if (FHoverCloseTab >= FTabs.Count) then FHoverCloseTab := -1;

  // Cancel drag if indexes are now out of range
  if FDragging and
     ((FDragIndex < 0) or (FDragIndex >= FTabs.Count) or
      (FDragTargetIndex > FTabs.Count)) then
    CancelDrag;
end;

procedure TCustomExtTabCtrl.SnapScrollOffset;
var
  i: Integer;
  R, View: TRect;
  VisSize, ViewEnd, ViewSize: Integer;
  TabStart, TabEnd: Integer;
begin
  if FTabs.Count = 0 then Exit;

  View := TabsViewportRect;
  ViewSize := AxisSize(View);
  ViewEnd  := FScrollOffset + ViewSize;

  for i := 0 to FTabs.Count - 1 do
  begin
    if not FTabs[i].Visible then Continue;

    R := FTabs[i].FBoundRect;
    GetAxisSpan(R, TabStart, TabEnd);

    if (TabStart < FScrollOffset) and (TabEnd > FScrollOffset) then
    begin
      VisSize := TabEnd - FScrollOffset;

      if VisSize < MinUsefulTabSize then
        FScrollOffset := TabEnd - GetScale(cTabOverlap);

      Break;
    end;

    if (TabStart < ViewEnd) and (TabEnd > ViewEnd) then
    begin
      VisSize := ViewEnd - TabStart;

      if VisSize < MinUsefulTabSize then
        FScrollOffset := Max(0, TabStart - ViewSize);

      Break;
    end;
  end;

  if HandleAllocated then
    FScrollOffset := Max(0, Min(FScrollOffset, MaxScrollOffset))
  else
    FScrollOffset := Max(0, FScrollOffset);
end;

// Set an initial size when dropped onto a form by click
class function TCustomExtTabCtrl.GetControlClassDefaultSize: TSize;
begin
  Result.cx := 300;
  Result.cy := 30;
end;

function TCustomExtTabCtrl.NextVisibleTab(FromIndex: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := FromIndex + 1 to FTabs.Count - 1 do
    if FTabs[i].Visible then Exit(i);
end;

function TCustomExtTabCtrl.PrevVisibleTab(FromIndex: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := FromIndex - 1 downto 0 do
    if FTabs[i].Visible then Exit(i);
end;

procedure TCustomExtTabCtrl.SetTabIndex(AValue: Integer);
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
    // If etoActiveBold/Italic is on, the old and new active tabs are
    // measured with different font styles
    if (etoActiveBold in FTabOptions) or (etoActiveItalic in FTabOptions) then
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

    InvalidateLayout;

    FTabIndex := AValue;
    if FTabIndex <> -1 then
      //EnsureTabVisible(FTabIndex);
      ScrollTabIntoView(FTabIndex);
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

procedure TCustomExtTabCtrl.SetTabSize(AValue: Integer);
begin
  if FTabSize <> AValue then
  begin
    FTabSize := AValue;
    InvalidateLayout;

    // If the new size is too small for the current images, grow it back
    UpdateTabSizeForImages;
  end;
end;

function TCustomExtTabCtrl.IsStoredTabSize: Boolean;
begin
  Result := FTabSize <> Scale96ToFont(cDefaultTabSize);
end;

procedure TCustomExtTabCtrl.AddBtnClick(Sender: TObject);
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

procedure TCustomExtTabCtrl.ScrollPrev(Sender: TObject);
var
  i: Integer;
  VisibleStart, TabStart, TabEnd: Integer;
begin
  if FScrollOffset = 0 then Exit;

  FManualScroll := True;

  // Find the first tab that starts before the current scroll position and scroll to show it
  VisibleStart := FScrollOffset;

  for i := FTabs.Count - 1 downto 0 do
  begin
    if not FTabs[i].Visible then Continue;
    GetAxisSpan(FTabs[i].FBoundRect, TabStart, TabEnd);
    if TabStart < VisibleStart then
    begin
      FScrollOffset := TabStart;
      Break;
    end;
  end;
  if FScrollOffset < 0 then FScrollOffset := 0;

  UpdateScrollButtons;
  Invalidate;
end;

procedure TCustomExtTabCtrl.ScrollNext(Sender: TObject);
var
  i: Integer;
  View: TRect;
  ViewSize, VisibleEnd, TabStart, TabEnd: Integer;
begin
  FManualScroll := True;

  View := TabsViewportRect;
  ViewSize := AxisSize(View);
  VisibleEnd := FScrollOffset + ViewSize;

  for i := 0 to FTabs.Count - 1 do
  begin
    if not FTabs[i].Visible then Continue;
    GetAxisSpan(FTabs[i].FBoundRect, TabStart, TabEnd);
    if TabEnd > VisibleEnd then
    begin
      FScrollOffset := TabStart;
      Break;
    end;
  end;
  FScrollOffset := Min(MaxScrollOffset, FScrollOffset);

  UpdateScrollButtons;
  Invalidate;
end;

procedure TCustomExtTabCtrl.AddBtnPaint(Sender: TObject);
var
  Btn: TSpeedButton;
  ImgRes: TScaledImageListResolution;
  ppi, scale: Integer;
  Skip: Boolean;
  SavedPen: TExtPenState;
begin
  Btn := TSpeedButton(Sender);

  // Draw Image from List if available
  if Assigned(FImages) and (FButtonImageIndexes.AddIndex >= 0) then
  begin
    ppi := Font.PixelsPerInch;
    scale := 1;
    ImgRes := FInternalImages.ResolutionForPPI[FImagesWidth.AddWidth, ppi, scale];
    ImgRes.Draw(Btn.Canvas, (Btn.ClientWidth - ImgRes.Width) div 2, (Btn.ClientHeight - ImgRes.Height) div 2, FButtonImageIndexes.AddIndex, gdeNormal);
  end
  else
  begin
    Skip := True;

    // User-supplied drawing
    if Assigned(FOnDrawButton) then
    begin
      SavedPen := SavePen(Btn.Canvas);
      try
        FOnDrawButton(Self, Btn.Canvas, Btn.ClientRect, ebtAdd, nil, False, False, Skip);
      finally
        RestorePen(Btn.Canvas, SavedPen);
      end;
    end;

    // Built-in icon
    if Skip then DrawBtnAdd(Btn.Canvas, Btn.ClientRect);
  end;
end;

procedure TCustomExtTabCtrl.ScrollBtnPaint(Sender: TObject);
var
  Btn: TSpeedButton;
  ImgRes: TScaledImageListResolution;
  ppi, scale: Integer;
  IsNext: Boolean;
  ImgIndex: Integer;
  BtnType: TExtButtonType;
  Skip: Boolean;
  SavedPen: TExtPenState;
begin
  Btn := TSpeedButton(Sender);
  IsNext := (Btn = FBtnScrollNext);
  if IsNext then BtnType := ebtNext else BtnType := ebtPrev;
  ImgIndex := IfThen(IsNext, FButtonImageIndexes.ScrollNextIndex, FButtonImageIndexes.ScrollPrevIndex);

  // Draw Image from List if available
  if Assigned(FImages) and (ImgIndex >= 0) then
  begin
    ppi := Font.PixelsPerInch;
    scale := 1;
    ImgRes := FInternalImages.ResolutionForPPI[IfThen(IsNext, FImagesWidth.NextWidth, FImagesWidth.PrevWidth), ppi, scale];
    ImgRes.Draw(Btn.Canvas, (Btn.ClientWidth - ImgRes.Width) div 2, (Btn.ClientHeight - ImgRes.Height) div 2, ImgIndex, gdeNormal);
  end
  else
  begin
    Skip := True;

    // User-supplied drawing
    if Assigned(FOnDrawButton) then
    begin
      SavedPen := SavePen(Btn.Canvas);
      try
        FOnDrawButton(Self, Btn.Canvas, Btn.ClientRect, BtnType, nil, False, False, Skip);
      finally
        RestorePen(Btn.Canvas, SavedPen);
      end;
    end;

    // Built-in icon
    if Skip then DrawBtnScroll(Btn.Canvas, Btn.ClientRect, IsNext, IsHorizontal);
  end;
end;

procedure TCustomExtTabCtrl.SetTabStyle(AValue: TExtTabStyle);
begin
  if FTabStyle <> AValue then
  begin
    FTabStyle := AValue;
    InvalidateLayout;
  end;
end;

procedure TCustomExtTabCtrl.SetTabPosition(AValue: TExtTabPosition);
var
  WasVertical, WillBeVertical: Boolean;
  W, H: Integer;
begin
  if FTabPosition <> AValue then
  begin
    WasVertical := FTabPosition in [etpLeft, etpRight];
    WillBeVertical := AValue in [etpLeft, etpRight];

    BeginUpdate;
    try
      FTabPosition := AValue;
      FScrollOffset := 0;

      // Process the external images into the internal list
      PrepareInternalTabImages(GetRotationForPosition);

      // When crossing between horizontal and vertical swap Width and Height
      // so the tab strip keeps the same thickness in the new orientation
      if WasVertical <> WillBeVertical then
      begin
        W := Width;
        H := Height;
        SetBounds(Left, Top, H, W);
      end;

      UpdateBtnImages;
      AnchorButtons;

      InvalidateLayout;
      InvalidatePreferredSize;
      if AutoSize then AdjustSize;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TCustomExtTabCtrl.SetTabOptions(AValue: TExtTabOptions);
var
  i: Integer;
  tabChanged: Boolean;
begin
  if FTabOptions = AValue then Exit;
  tabChanged := ([etoRotateTabImages]*AValue <> [etoRotateTabImages]*FTabOptions) or
                ([etoRotateAddImage]*AValue <> [etoRotateAddImage]*FTabOptions);
  FTabOptions := AValue;
  FLayoutDirty := True;

  // etoActiveBold/Italic affects text measurements, reset all caches
  for i := 0 to FTabs.Count - 1 do
  begin
    FTabs[i].FTextWidth := -1;
    FTabs[i].FTextHeight := -1;
  end;

  if tabChanged then
    PrepareInternalTabImages(GetRotationForPosition);

  AnchorButtons;
  UpdateTabSizeForImages;
  Invalidate;
end;

procedure TCustomExtTabCtrl.SetImages(AValue: TCustomImageList);
begin
  if FImages <> AValue then
  begin
    FImages := AValue;
    if Assigned(FImages) then
      FImages.FreeNotification(Self);

    // Process the external images into the internal list
    PrepareInternalTabImages(GetRotationForPosition);

    UpdateBtnImages;
    InvalidateLayout;
  end;
end;

procedure TCustomExtTabCtrl.SetButtonImageIndexes(AValue: TExtButtonImageIndexes);
begin
  FButtonImageIndexes.Assign(AValue);
end;

procedure TCustomExtTabCtrl.SetImagesWidth(AValue: TExtImagesWidth);
begin
  FImagesWidth.Assign(AValue);
end;

procedure TCustomExtTabCtrl.SetBorderColor(AValue: TColor);
begin
  if AValue = FBorderColor then Exit;

  FBorderColor := AValue;
  Invalidate;
end;

procedure TCustomExtTabCtrl.SetMinCaptionLen(AValue: Integer);
var
  i: Integer;
begin
  if AValue < 0 then AValue := 0;
  if FMinCaptionLen = AValue then Exit;
  FMinCaptionLen := AValue;
  // Display text may change length — bust all text-width caches
  for i := 0 to FTabs.Count - 1 do
  begin
    FTabs[i].FTextWidth := -1;
    FTabs[i].FTextHeight := -1;
  end;
  InvalidateLayout;
end;

procedure TCustomExtTabCtrl.SetMaxCaptionLen(AValue: Integer);
var
  i: Integer;
begin
  if AValue < 0 then AValue := 0;
  if FMaxCaptionLen = AValue then Exit;
  FMaxCaptionLen := AValue;
  for i := 0 to FTabs.Count - 1 do
  begin
    FTabs[i].FTextWidth := -1;
    FTabs[i].FTextHeight := -1;
  end;
  InvalidateLayout;
end;

procedure TCustomExtTabCtrl.SetButtonHints(AValue: TExtButtonHints);
begin
  FButtonHints.Assign(AValue);

  if not (csLoading in ComponentState) then
    AnchorButtons;
end;

procedure TCustomExtTabCtrl.SetTabs(AValue: TExtTabs);
begin
  FTabs.Assign(AValue);
end;

function TCustomExtTabCtrl.GetAddMenu: TPopupMenu;
begin
  Result := FBtnAdd.PopupMenu;
end;

procedure TCustomExtTabCtrl.SetOnDrawTab(AValue: TTabDrawEvent);
begin
  if not SameMethod(TMethod(AValue), TMethod(FOnDrawTab)) then
  begin
    FOnDrawTab := AValue;
    Invalidate;
  end;
end;

procedure TCustomExtTabCtrl.SetOnDrawButton(AValue: TButtonDrawEvent);
begin
  if not SameMethod(TMethod(AValue), TMethod(FOnDrawButton)) then
  begin
    FOnDrawButton := AValue;
    // Close button is drawn directly on the tab-strip canvas
    Invalidate;
    // Add and scroll buttons are child TSpeedButtons; invalidate them too
    if Assigned(FBtnAdd) then FBtnAdd.Invalidate;
    if Assigned(FBtnScrollPrev) then FBtnScrollPrev.Invalidate;
    if Assigned(FBtnScrollNext) then FBtnScrollNext.Invalidate;
  end;
end;

procedure TCustomExtTabCtrl.SetAddMenu(AValue: TPopupMenu);
begin
  FBtnAdd.PopupMenu := AValue;
end;

procedure TCustomExtTabCtrl.ButtonImagesChanged(Sender: TObject);
begin
  UpdateBtnImages;
end;

procedure TCustomExtTabCtrl.ButtonHintsChanged(Sender: TObject);
begin
  if Assigned(FBtnAdd) then
  begin
    FBtnAdd.Hint := FButtonHints.AddHint;
    FBtnAdd.ShowHint := ShowHint and (FButtonHints.AddHint <> '');
  end;
  if Assigned(FBtnScrollPrev) then
  begin
    FBtnScrollPrev.Hint := FButtonHints.ScrollPrevHint;
    FBtnScrollPrev.ShowHint := ShowHint and (FButtonHints.ScrollPrevHint <> '');
  end;
  if Assigned(FBtnScrollNext) then
  begin
    FBtnScrollNext.Hint := FButtonHints.ScrollNextHint;
    FBtnScrollNext.ShowHint := ShowHint and (FButtonHints.ScrollNextHint <> '');
  end;
end;

procedure TCustomExtTabCtrl.ImagesWidthChanged(Sender: TObject);
begin
  // Re-trigger the button image extraction
  UpdateBtnImages;
end;

function TCustomExtTabCtrl.TabsViewportRect(ShowPrev, ShowNext, ShowAdd: Boolean): TRect;
var
  Spacing: Integer;
  NeedsSpacing: Boolean;
begin
  Result := ClientRect;

  Spacing := GetScale(cContentIndent);

  case FTabPosition of
    etpTop: Result.Bottom := Result.Top + FTabSize;
    etpBottom: Result.Top := Result.Bottom - FTabSize;
    etpLeft: Result.Right := Result.Left + FTabSize;
    etpRight: Result.Left := Result.Right - FTabSize;
  end;

  NeedsSpacing := False;
  if IsHorizontal then
  begin
    if ShowAdd then
    begin
      Dec(Result.Right, FBtnAdd.Width);
      NeedsSpacing := True;
    end;

    if ShowNext then
    begin
      Dec(Result.Right, FBtnScrollNext.Width);
      NeedsSpacing := True;
    end;

    if NeedsSpacing then Dec(Result.Right, Spacing);

    if ShowPrev then
      Inc(Result.Left, FBtnScrollPrev.Width + Spacing);
  end
  else
  begin
    if ShowAdd then
    begin
      Dec(Result.Bottom, FBtnAdd.Height);
      NeedsSpacing := True;
    end;

    if ShowNext then
    begin
      Dec(Result.Bottom, FBtnScrollNext.Height);
      NeedsSpacing := True;
    end;

    if NeedsSpacing then Dec(Result.Bottom, Spacing);

    if ShowPrev then
      Inc(Result.Top, FBtnScrollPrev.Height + Spacing);
  end;
end;

function TCustomExtTabCtrl.TabsViewportRect: TRect;
var
  ShowPrev, ShowNext, ShowAdd: Boolean;
  ViewNoNext: TRect;
  AvailNoNext: Integer;
begin
  if csDesigning in ComponentState then
  begin
    ShowAdd := True;
    ShowPrev := True;
    ShowNext := True;
  end
  else
  begin
    ShowAdd := etoShowAddButton in FTabOptions;
    ShowPrev := FScrollOffset > 0;

    ViewNoNext := TabsViewportRect(ShowPrev, False, ShowAdd);
    AvailNoNext := AxisSize(ViewNoNext);
    ShowNext := FTotalTabsSize > FScrollOffset + AvailNoNext;
  end;

  Result := TabsViewportRect(ShowPrev, ShowNext, ShowAdd);
end;

// Sets Anchors on the three buttons so the LCL layout engine keeps them
// correctly positioned automatically on every resize
procedure TCustomExtTabCtrl.AnchorButtons;
var
  ScrollPrevW, ScrollPrevH, ScrollNextW, ScrollNextH, AddW, AddH: Integer;
  ShowAdd: Boolean;
  imgBorder, BtnThick: Integer;

  procedure SetAnchorSide(Btn: TSpeedButton; Side: TAnchorKind; Control: TControl; AnchorSide: TAnchorSideReference);
  begin
    Btn.AnchorSide[Side].Control := Control;
    Btn.AnchorSide[Side].Side := AnchorSide;
  end;

begin
  if (csDestroying in ComponentState) or not HandleAllocated then Exit;

  imgBorder := Scale96ToFont(2);

  ScrollPrevW := GetIconExtent(FButtonImageIndexes.ScrollPrevIndex, FImagesWidth.PrevWidth, True);
  ScrollPrevH := GetIconExtent(FButtonImageIndexes.ScrollPrevIndex, FImagesWidth.PrevWidth, False);

  ScrollNextW := GetIconExtent(FButtonImageIndexes.ScrollNextIndex, FImagesWidth.NextWidth, True);
  ScrollNextH := GetIconExtent(FButtonImageIndexes.ScrollNextIndex, FImagesWidth.NextWidth, False);

  AddW := GetIconExtent(FButtonImageIndexes.AddIndex, FImagesWidth.AddWidth, True);
  AddH := GetIconExtent(FButtonImageIndexes.AddIndex, FImagesWidth.AddWidth, False);

  // The Add button is always visible at design time
  ShowAdd := (etoShowAddButton in FTabOptions) or (csDesigning in ComponentState);
  FBtnAdd.Visible := ShowAdd;

  BtnThick := Max(1, FTabSize - 1);

  // Horizontal orientation
  if IsHorizontal then
  begin
    // Scroll-Prev: left edge, full strip height
    if (FTabPosition = etpTop) then
      FBtnScrollPrev.Anchors := [akLeft, akTop]
    else
      FBtnScrollPrev.Anchors := [akLeft, akBottom];
    SetAnchorSide(FBtnScrollPrev, akLeft, Self, asrLeft);
    if (FTabPosition = etpTop) then
    begin
      SetAnchorSide(FBtnScrollPrev, akTop, Self, asrTop);
      FBtnScrollPrev.Anchors := [akLeft, akTop];
    end
    else
    begin
      SetAnchorSide(FBtnScrollPrev, akBottom, Self, asrBottom);
      FBtnScrollPrev.Anchors := [akLeft, akBottom];
    end;
    FBtnScrollPrev.Constraints.MinHeight := BtnThick;
    FBtnScrollPrev.Constraints.MinWidth := 0;
    // Due to anchoring the button is positioned automatically, no need to
    // specify Left and Top.
    FBtnScrollPrev.SetBounds(0, 0, ScrollPrevW, BtnThick);

    // Add: right edge, full strip height
    if (FTabPosition = etpTop) then
      FBtnAdd.Anchors := [akRight, akTop]
    else
      FBtnAdd.Anchors := [akRight, akBottom];
    SetAnchorSide(FBtnAdd, akRight, Self, asrRight);
    if (FTabPosition = etpTop) then
    begin
      SetAnchorSide(FBtnAdd, akTop, Self, asrTop);
      FBtnAdd.Anchors := [akRight, akTop];
    end
    else
    begin
      SetAnchorSide(FBtnAdd, akBottom, Self, asrBottom);
      FBtnAdd.Anchors := [akRight, akBottom];
    end;
    FBtnAdd.Constraints.MinHeight := BtnThick;
    FBtnAdd.Constraints.MinWidth := 0;
    inc(AddW, 2*imgBorder);

    FBtnAdd.SetBounds(0, 0, AddW, BtnThick);

    // Scroll-Next: just left of Add, full strip height
    if (FTabPosition = etpTop) then
    begin
      SetAnchorSide(FBtnScrollNext, akTop, Self, asrTop);
      FBtnScrollNext.Anchors := [akRight, akTop];
    end
    else
    begin
      SetAnchorSide(FBtnScrollNext, akBottom, Self, asrBottom);
      FBtnScrollNext.Anchors := [akRight, akBottom];
    end;
    FBtnScrollNext.Constraints.MinHeight := BtnThick;
    FBtnScrollNext.Constraints.MinWidth := 0;

    if ShowAdd then
    begin
      FBtnScrollNext.AnchorSide[akRight].Control := FBtnAdd;
      FBtnScrollNext.AnchorSide[akRight].Side := asrLeft;
    end
    else
    begin
      FBtnScrollNext.AnchorSide[akRight].Control := Self;
      FBtnScrollNext.AnchorSide[akRight].Side := asrRight;
    end;

    // Due to anchoring the button is positioned automatically, no need to
    // specify Left and Top.
    FBtnScrollNext.SetBounds(0, 0, ScrollNextW, BtnThick);
  end
  else
  // Vertical orientation
  begin
    // Scroll-Prev: top of the strip, full strip width
    if (FTabPosition = etpLeft) then
      FBtnScrollPrev.Anchors := [akLeft, akTop]
    else
      FBtnScrollPrev.Anchors := [akRight, akTop];
    SetAnchorSide(FBtnScrollPrev, akTop, Self, asrTop);
    if (FTabPosition = etpLeft) then
    begin
      SetAnchorSide(FBtnScrollPrev, akLeft, Self, asrLeft);
      FBtnScrollPrev.Anchors := [akLeft, akTop];
    end
    else
    begin
      SetAnchorSide(FBtnScrollPrev, akRight, Self, asrRight);
      FBtnScrollPrev.Anchors := [akRight, akTop];
    end;
    FBtnScrollPrev.Constraints.MinWidth := BtnThick;
    FBtnScrollPrev.Constraints.MinHeight := 0;
    FBtnScrollPrev.SetBounds(0, 0, BtnThick, ScrollPrevH);

    // Add: bottom of the strip, full strip width
    if (FTabPosition = etpLeft) then
      FBtnAdd.Anchors := [akLeft, akBottom]
    else
      FBtnAdd.Anchors := [akRight, akBottom];
    SetAnchorSide(FBtnAdd, akBottom, Self, asrBottom);
    if (FTabPosition = etpLeft) then
    begin
      SetAnchorSide(FBtnAdd, akLeft, Self, asrLeft);
      FBtnAdd.Anchors := [akLeft, akBottom];
    end
    else
    begin
      SetAnchorSide(FBtnAdd, akRight, Self, asrRight);
      FBtnAdd.Anchors := [akRight, akBottom];
    end;
    FBtnAdd.Constraints.MinHeight := 0;
    FBtnAdd.Constraints.MinWidth := BtnThick;
    FBtnAdd.SetBounds(0, 0, BtnThick, AddH + 2*imgBorder);

    // Scroll-Next: just above Add, full strip width
    if (FTabPosition = etpLeft) then
    begin
      SetAnchorSide(FBtnScrollNext, akLeft, Self, asrLeft);
      FBtnScrollNext.Anchors := [akLeft, akBottom];
    end
    else
    begin
      SetAnchorSide(FBtnScrollNext, akRight, Self, asrRight);
      FBtnScrollNext.Anchors := [akRight, akBottom];
    end;
    FBtnScrollNext.Constraints.MinHeight := 0;
    FBtnScrollNext.Constraints.MinWidth := BtnThick;

    if ShowAdd then
    begin
      FBtnScrollNext.AnchorSide[akBottom].Control := FBtnAdd;
      FBtnScrollNext.AnchorSide[akBottom].Side := asrTop;
    end
    else
    begin
      FBtnScrollNext.AnchorSide[akBottom].Control := Self;
      FBtnScrollNext.AnchorSide[akBottom].Side := asrBottom;
    end;

    FBtnScrollNext.SetBounds(0, 0, BtnThick, ScrollNextH);
  end;

  FLayoutDirty := True;
end;

function TCustomExtTabCtrl.IsVertical: Boolean;
begin
  Result := FTabPosition in [etpLeft, etpRight];
end;

function TCustomExtTabCtrl.IsHorizontal: Boolean;
begin
  Result := not IsVertical;
end;

procedure TCustomExtTabCtrl.GetAxisSpan(const R: TRect; out AStart, AEnd: Integer);
begin
  AStart := IfThen(IsHorizontal, R.Left, R.Top);
  AEnd := IfThen(IsHorizontal, R.Right, R.Bottom);
end;

function TCustomExtTabCtrl.AxisSize(const R: TRect): Integer;
begin
  Result := IfThen(IsHorizontal, R.Width, R.Height);
end;

// Translate a tab's logical FBoundRect into screen/view coordinates
procedure TCustomExtTabCtrl.OffsetToView(var R: TRect; const View: TRect);
begin
  if IsHorizontal then
    Types.OffsetRect(R, View.Left - FScrollOffset, View.Top)
  else
    Types.OffsetRect(R, View.Left, View.Top - FScrollOffset);
end;

// Inverse of OffsetToView for a single point
function TCustomExtTabCtrl.ViewToContent(const P: TPoint; const View: TRect): TPoint;
begin
  Result := Point(P.X - View.Left, P.Y - View.Top);
  if IsHorizontal then
    Inc(Result.X, FScrollOffset)
  else
    Inc(Result.Y, FScrollOffset);
end;

function TCustomExtTabCtrl.CloseButtonRect(Tab: TExtTab): TRect;
var
  CloseW, CloseH, M: Integer;
begin
  // Determine dynamic Close Button size
  CloseW := GetIconExtent(FButtonImageIndexes.CloseIndex, FImagesWidth.CloseWidth, True);
  CloseH := GetIconExtent(FButtonImageIndexes.CloseIndex, FImagesWidth.CloseWidth, False);

  M := GetScale(cContentIndent);

  if IsHorizontal then
  begin
    // Horizontal: Positioned at the right end of the tab, vertically centered
    Result.Left := Tab.FBoundRect.Width - CloseW - (M + GetScale(cTabOverlap));
    Result.Top := (Tab.FBoundRect.Height - CloseH) div 2;
    Result.Right := Tab.FBoundRect.Width - (M + GetScale(cTabOverlap));
    Result.Bottom := Result.Top + CloseH;
  end
  else
  begin
    // Vertical: Horizontally centered within the tab strip
    Result.Left := (Tab.FBoundRect.Width - CloseW) div 2;
    Result.Right := Result.Left + CloseW;

    if FTabPosition = etpLeft then
    begin
      // etpLeft: Close button at the top
      Result.Top := M;
      Result.Bottom := M + CloseH;
    end
    else
    begin
      // etpRight: Close button at the bottom
      Result.Bottom := Tab.FBoundRect.Height - (M + GetScale(cTabOverlap));
      Result.Top := Result.Bottom - CloseH;
    end;
  end;
end;

function TCustomExtTabCtrl.TabAtPos(X, Y: Integer): Integer;
var
  i: Integer;
  P: TPoint;
  View: TRect;
begin
  Result := -1;
  View := TabsViewportRect;
  if not PtInRect(View, Point(X, Y)) then Exit;
  P := ViewToContent(Point(X, Y), View);

  for i := 0 to FTabs.Count - 1 do
  begin
    if not FTabs[i].Visible then Continue;
    if PtInRect(FTabs[i].FBoundRect, P) then
      Exit(i);
  end;
end;

function TCustomExtTabCtrl.MaxScrollOffset: Integer;
var
  View: TRect;
begin
  View := TabsViewportRect;
  Result := Max(0, FTotalTabsSize - AxisSize(View));
end;

procedure TCustomExtTabCtrl.EnsureTabVisible(Index: Integer);
var
  R: TRect;
  ShowPrev, ShowNext, ShowAdd: Boolean;
  ViewNoButtons, ViewNoNext, ViewNoPrev, ViewBoth: TRect;
  TabStart, TabEnd, TabExtend, TotalSize, ViewSize: Integer;
begin
  if (Index < 0) or (Index >= FTabs.Count) then Exit;

  if Index = FTabIndex then FManualScroll := False;

  // CalcLayout ensures FBoundRect/FTotalTabsSize are current for the
  // current orientation before we measure anything
  CalcLayout;

  R := FTabs[Index].FBoundRect;
  ShowAdd := (etoShowAddButton in FTabOptions) or (csDesigning in ComponentState);
  ShowPrev := csDesigning in ComponentState;
  ShowNext := csDesigning in ComponentState;
  TotalSize := FTotalTabsSize;

  GetAxisSpan(R, TabStart, TabEnd);
  TabExtend := TabEnd - TabStart;

  // Step 1: does the whole strip fit with no scroll buttons at all?
  ViewNoButtons := TabsViewportRect(ShowPrev, ShowNext, ShowAdd);
  ViewSize := AxisSize(ViewNoButtons);
  if TotalSize <= ViewSize then
  begin
    FScrollOffset := 0;
    UpdateScrollButtons;
    Invalidate;
    Exit;
  end;

  // Step 2: can we avoid ScrollPrev? (offset = 0, only ScrollNext shown)
  ViewNoPrev := TabsViewportRect(ShowPrev, True, ShowAdd);
  ViewSize := AxisSize(ViewNoPrev);
  if (TabStart >= 0) and (TabEnd <= ViewSize) then
  begin
    FScrollOffset := 0;
    UpdateScrollButtons;
    Invalidate;
    Exit;
  end;

  // Step 3: can we avoid ScrollNext? (rightmost tab flush with the
  // no-ScrollNext edge, only ScrollPrev shown)
  ViewNoNext := TabsViewportRect(True, ShowNext, ShowAdd);
  ViewSize := AxisSize(ViewNoNext);
  // Offset that puts the last tab's trailing edge flush with this viewport
  if (TotalSize - ViewSize >= 0) then
  begin
    if (TabStart >= TotalSize - ViewSize) and (TabEnd <= TotalSize) then
    begin
      FScrollOffset := TotalSize - ViewSize;
      UpdateScrollButtons;
      Invalidate;
      Exit;
    end;
  end;

  // Step 4: neither button is avoidable (center the tab in the viewport that
  // has both scroll buttons present)
  ViewBoth := TabsViewportRect(True, True, ShowAdd);
  ViewSize := AxisSize(ViewBoth);

  FScrollOffset := TabStart - (ViewSize - TabExtend) div 2;
  FScrollOffset := Max(0, Min(FScrollOffset, TotalSize - ViewSize));

  UpdateScrollButtons;
  Invalidate;
end;

// "Soft" counterpart to EnsureTabVisible: used whenever the tab strip's
// geometry/button configuration hasn't changed but only the selection
procedure TCustomExtTabCtrl.ScrollTabIntoView(Index: Integer);
var
  R, View: TRect;
  TabStart, TabEnd, ViewSize: Integer;
  OldPrevVisible, OldNextVisible: Boolean;
begin
  if (Index < 0) or (Index >= FTabs.Count) then Exit;

  if Index = FTabIndex then FManualScroll := False;

  // CalcLayout ensures FBoundRect/FTotalTabsSize are current for the
  // current orientation before we measure anything
  CalcLayout;

  R := FTabs[Index].FBoundRect;
  GetAxisSpan(R, TabStart, TabEnd);

  // Use the current viewport rather than recomputing the optimal button configuration
  View := TabsViewportRect;
  ViewSize := AxisSize(View);

  if TabStart < FScrollOffset then
    FScrollOffset := TabStart                  // clipped on the near edge
  else if TabEnd > FScrollOffset + ViewSize then
    FScrollOffset := TabEnd - ViewSize          // clipped on the far edge
  else
    Exit;                                       // already fully visible

  FScrollOffset := Max(0, Min(FScrollOffset, MaxScrollOffset));

  OldPrevVisible := FBtnScrollPrev.Visible;
  OldNextVisible := FBtnScrollNext.Visible;
  UpdateScrollButtons;

  if (FBtnScrollPrev.Visible <> OldPrevVisible) or
     (FBtnScrollNext.Visible <> OldNextVisible) then
  begin
    // The nudge changed the button layout, use the "hard" algorithm
    EnsureTabVisible(Index);
    Exit;
  end;

  Invalidate;
end;

procedure TCustomExtTabCtrl.UpdateScrollButtons;
var
  Can: Boolean;
  NewPrevVis, NewNextVis: Boolean;
  HasChanged: Boolean;
  ViewNoButtons: TRect;
  ShowPrev, ShowNext, ShowAdd: Boolean;
begin
  if (FUpdateCount > 0) or not HandleAllocated then Exit;

  ShowAdd := (etoShowAddButton in FTabOptions) or (csDesigning in ComponentState);
  ShowPrev := csDesigning in ComponentState;
  ShowNext := csDesigning in ComponentState;
  ViewNoButtons := TabsViewportRect(ShowPrev, ShowNext, ShowAdd);
  Can := FTotalTabsSize > (AxisSize(ViewNoButtons));

  NewPrevVis := FScrollOffset > 0;
  NewNextVis := Can and (FScrollOffset < MaxScrollOffset);

  HasChanged := (FBtnScrollPrev.Visible <> NewPrevVis) or
                (FBtnScrollNext.Visible <> NewNextVis);

  if HasChanged then
  begin
    FBtnScrollPrev.Visible := NewPrevVis;
    FBtnScrollNext.Visible := NewNextVis;
    if not Can then FScrollOffset := 0;
    FLayoutDirty := True;
    Invalidate;
  end;
end;

function TCustomExtTabCtrl.GetScale(Value: Integer): Integer;
begin
  Result := Scale96ToFont(Value);
end;

function TCustomExtTabCtrl.MinUsefulTabSize: Integer;
begin
  Result := GetScale(16 + 2*cContentIndent);
end;

function TCustomExtTabCtrl.GetIconExtent(AImageIndex, AImageWidth: Integer; IsWidth: Boolean): Integer;
var
  ppi: Integer;
begin
  if Assigned(FImages) and (AImageIndex > -1) then
  begin
    ppi := Font.PixelsPerInch;
    if IsWidth then
      Result := FInternalImages.WidthForPPI[AImageWidth, ppi]
    else
      Result := FInternalImages.HeightForPPI[AImageWidth, ppi];
  end
  else
    Result := GetScale(16);
end;

procedure TCustomExtTabCtrl.DrawTabTextAndImage(ACanvas: TCanvas; const R: TRect; Tab: TExtTab; IsActive: Boolean; DefaultFontColor: TColor);
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
    if etoActiveBold in FTabOptions then Include(ActiveExtra, fsBold);
    if etoActiveItalic in FTabOptions then Include(ActiveExtra, fsItalic);
    if ActiveExtra <> [] then
      ACanvas.Font.Style := ACanvas.Font.Style + ActiveExtra;
  end;

  if Tab.FFontOptions.FontColor <> clNone then
    ACanvas.Font.Color := Tab.FFontOptions.FontColor
  else
    ACanvas.Font.Color := DefaultFontColor;

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
                  IfThen(FTabPosition = etpLeft, TextRect.Bottom + GetScale(cImageSpacing),
                                                TextRect.Top - GetScale(cImageSpacing) - ImgH));

    DrawTabImage(ACanvas, Tab, ImgPos.X, ImgPos.Y);
  end;

  if IsHorizontal then
    DrawText(ACanvas.Handle, PChar(GetDisplayCaption(Tab)), -1, TextRect,
             DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX)
  else
    DrawRotatedText(ACanvas, GetDisplayCaption(Tab), TextRect, GetRotationForPosition);
end;

procedure TCustomExtTabCtrl.DrawTabImage(ACanvas: TCanvas; Tab: TExtTab; X, Y: Integer);
var
  bmp: TBitmap;
begin
  if HasAnyImage(Tab) then
  begin
    bmp := TBitmap.Create;
    try
      GetBaseTabBitmap(Tab, bmp);
      ACanvas.Draw(X, Y, bmp);
    finally
      bmp.Free;
    end;
  end;
end;

procedure TCustomExtTabCtrl.DrawRotatedText(ACanvas: TCanvas; const S: String; const R: TRect; Degrees: Integer);
var
  SavedOrientation: Integer;
begin
  SavedOrientation := ACanvas.Font.Orientation;
  ACanvas.Font.Orientation := Degrees*10;

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

function TCustomExtTabCtrl.GetRotationForPosition: Integer;
begin
  case FTabPosition of
    etpLeft: Result := 90;
    etpRight: Result := 270;
    else Result := 0;
  end;
end;

function TCustomExtTabCtrl.HasAnyImage(Tab: TExtTab): Boolean;
begin
  Result := (Assigned(FImages) and (Tab.ImageIndex >= 0)) or
            (Assigned(Tab.FImage) and not Tab.FImage.Empty);
end;

function TCustomExtTabCtrl.GetTabImageWidth(Tab: TExtTab): Integer;
begin
  if Assigned(FImages) and (Tab.ImageIndex >= 0) then
    // Use the DPI-aware width
    Result := FInternalImages.WidthForPPI[FImagesWidth.TabsWidth, Font.PixelsPerInch]
  else if Assigned(Tab.FImage) and not Tab.FImage.Empty then
    Result := Tab.FImage.Width
  else
    Result := 0;
end;

function TCustomExtTabCtrl.GetTabImageHeight(Tab: TExtTab): Integer;
begin
  if Assigned(FImages) and (Tab.ImageIndex >= 0) then
    // Use the DPI-aware height
    Result := FInternalImages.HeightForPPI[FImagesWidth.TabsWidth, Font.PixelsPerInch]
  else if Assigned(Tab.FImage) and not Tab.FImage.Empty then
    Result := Tab.FImage.Height
  else
    Result := 0;
end;

function TCustomExtTabCtrl.GetTabTextBounds(ACanvas: TCanvas; const R: TRect; Tab: TExtTab): TRect;
var
  Indent, Spacing, CloseExtend, ImgH: Integer;
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
    TextSize := ACanvas.TextExtent(GetDisplayCaption(Tab));

  Result := R;
  TxtRect := R;
  InflateRect(TxtRect, -Indent, -Indent);

  CloseExtend := GetIconExtent(FButtonImageIndexes.CloseIndex, FImagesWidth.CloseWidth, IsHorizontal);

  if IsHorizontal then
  begin
    // Account for Image
    if HasAnyImage(Tab) then
      Inc(TxtRect.Left, GetTabImageWidth(Tab) + Spacing);

    // Account for Close Button
    if (etoShowCloseButton in FTabOptions) and Tab.ShowCloseButton then
      Dec(TxtRect.Right, CloseExtend + Indent);

    Result.Left := TxtRect.Left + (TxtRect.Width - TextSize.cx) div 2;
    Result.Right := Result.Left + TextSize.cx;
    Result.Top := TxtRect.Top + (TxtRect.Height - TextSize.cy) div 2;
    Result.Bottom := Result.Top + TextSize.cy;
  end
  else
  begin
    if (etoShowCloseButton in FTabOptions) and Tab.ShowCloseButton then
    begin
      if FTabPosition = etpLeft then
        Inc(TxtRect.Top, CloseExtend + Indent)
      else
        Dec(TxtRect.Bottom, CloseExtend + Indent);
    end;

    CX := (TxtRect.Left + TxtRect.Right) div 2;
    if FTabPosition = etpLeft then CY := TxtRect.Bottom else CY := TxtRect.Top;

    if HasAnyImage(Tab) then
    begin
      ImgH := GetTabImageHeight(Tab);
      if FTabPosition = etpLeft then
        CY := TxtRect.Bottom - ImgH - Spacing
      else
        CY := TxtRect.Top + ImgH + Spacing;
    end;

    if FTabPosition = etpLeft then
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

// Get the best matching resolution for the current DPI
procedure TCustomExtTabCtrl.GetBaseTabBitmap(Tab: TExtTab; Dest: TBitmap);
begin
  if Assigned(FImages) and (Tab.ImageIndex >= 0) then
    FInternalImages.ResolutionForPPI[FImagesWidth.TabsWidth, Font.PixelsPerInch, 1].GetBitmap(Tab.ImageIndex, Dest)
  else if Assigned(Tab.FImage) and not Tab.FImage.Empty then
    Dest.Assign(Tab.FImage)
  else
    Dest.Clear;
end;

procedure TCustomExtTabCtrl.DrawCloseButton(ACanvas: TCanvas; const R: TRect; Tab: TExtTab; IsActive: Boolean);
var
  CloseR: TRect;
  imgRes: TScaledImageListResolution;
  scale: Integer = 1;
  ppi: Integer;
  effect: TGraphicsDrawEffect;
  IsHover: Boolean;
  Skip: Boolean;
  SavedPen: TExtPenState;
begin
  if not (etoShowCloseButton in FTabOptions) or not Tab.ShowCloseButton then Exit;

  ppi := Font.PixelsPerInch;
  CloseR := CloseButtonRect(Tab);
  Types.OffsetRect(CloseR, R.Left, R.Top);

  IsHover := (FHoverCloseTab = Tab.Index);
  if IsHover then
    effect := gdeHighlighted
  else
    effect := gdeNormal;

  // Draw Image from List if available
  if Assigned(FImages) and (FButtonImageIndexes.CloseIndex >= 0) then
  begin
    imgRes := FInternalImages.ResolutionForPPI[FImagesWidth.CloseWidth, ppi, scale];
    imgRes.Draw(ACanvas, CloseR.Left + (CloseR.Width - imgRes.Width) div 2,
                CloseR.Top + (CloseR.Height - imgRes.Height) div 2,
                FButtonImageIndexes.CloseIndex, effect);
  end

  else
  begin
    Skip := True;

    // User-supplied drawing
    if Assigned(FOnDrawButton) then
    begin
      SavedPen := SavePen(ACanvas);
      try
        FOnDrawButton(Self, ACanvas, CloseR, ebtClose, Tab, IsActive, IsHover, Skip);
      finally
        RestorePen(ACanvas, SavedPen);
      end;
    end;

    // Built-in icon
    if Skip then DrawBtnClose(ACanvas, CloseR, IsHover);
  end;
end;

procedure TCustomExtTabCtrl.DrawColorStripe(ACanvas: TCanvas; const R: TRect; Tab: TExtTab; Indent: Integer);
var
  IndicatorRect: TRect;
  Thick: Integer;
begin
  if (Tab.StripeColor = clNone) then Exit;

  ACanvas.Brush.Color := Tab.StripeColor;
  ACanvas.Pen.Style := psClear;
  Thick := GetScale(3);

  // Safety catch for extremely narrow tabs
  if (R.Width <= Indent*2) or (R.Height <= Indent*2) then
    Indent := 0;

  case FTabPosition of
    etpTop: IndicatorRect := Rect(R.Left + Indent, R.Top + 1, R.Right - Indent, R.Top + 1 + Thick);
    etpBottom: IndicatorRect := Rect(R.Left + Indent, R.Bottom - 1 - Thick, R.Right - Indent, R.Bottom - 1);
    etpLeft: IndicatorRect := Rect(R.Left + 1, R.Top + Indent, R.Left + 1 + Thick, R.Bottom - Indent);
    etpRight: IndicatorRect := Rect(R.Right - 1 - Thick, R.Top + Indent, R.Right - 1, R.Bottom - Indent);
  end;

  ACanvas.FillRect(IndicatorRect);
  ACanvas.Pen.Style := psSolid;
end;

{ Drawing Handlers }

// Resolves clDefault and other system colors before mixing
function TCustomExtTabCtrl.ResolveColor(AColor: TColor): TColor;
begin
  if AColor = clDefault then
    Result := ColorToRGB(GetDefaultColor(dctBrush))
  else
    Result := ColorToRGB(AColor);
end;

function TCustomExtTabCtrl.InactiveFontColor: TColor;
begin
  Result := BlendColors(ResolveColor(clGrayText), ResolveColor(clWindowText), 0.55);
end;

// Gathers everything a style drawer in ExtTabCtrlStyles needs
function TCustomExtTabCtrl.BuildStyleContext(Tab: TExtTab): TExtTabDrawContext;
begin
  Result.BackgroundColor := Color;
  Result.BorderColor := FBorderColor;
  Result.TabPosition := FTabPosition;
  Result.IsHorizontal := IsHorizontal;
  Result.ActiveFontColor := Font.Color;
  Result.InactiveFontColor := InactiveFontColor;
  Result.ResolveColor := @ResolveColor;
  Result.GetScale := @GetScale;

  Result.TabColor := clNone;
  Result.TabStripeColor := clNone;
  Result.IsHoverTab := False;
  Result.IsBeforeActiveTab := False;
  Result.IsLastTab := False;

  if Assigned(Tab) then
  begin
    Result.TabColor := Tab.Color;
    Result.TabStripeColor := Tab.StripeColor;
    Result.IsHoverTab := (Tab.Index = FHoverTab);
    Result.IsBeforeActiveTab := (Tab.Index = FTabIndex - 1);
    Result.IsLastTab := (Tab.Index = FTabs.Count - 1);
  end;
end;

// Returns the caption as it should appear on the tab
// The original caption is never modified, hints always show the full text
function TCustomExtTabCtrl.GetDisplayCaption(Tab: TExtTab): String;
const
  EllipsisStr = '...';
  TailLen = 5;
var
  S: String;
  HeadLen: Integer;
begin
  S := Tab.Caption;

  // Minimum length: pad with spaces
  if (FMinCaptionLen > 0) and (Length(S) < FMinCaptionLen) then
    S := S + StringOfChar(' ', FMinCaptionLen - Length(S));

  // Maximum length: middle ellipsis
  if (FMaxCaptionLen > 0) and (Length(S) > FMaxCaptionLen) then
  begin
    // Head fills everything left after reserving tail + ellipsis
    HeadLen := Max(1, FMaxCaptionLen - TailLen - Length(EllipsisStr));
    S := Copy(S, 1, HeadLen) + EllipsisStr + Copy(S, Length(S) - TailLen + 1, TailLen);
  end;

  Result := S;
end;

procedure TCustomExtTabCtrl.DrawTab(ACanvas: TCanvas; Index: Integer; ARect: TRect; IsActive: Boolean);
var
  IsHover: Boolean;
  Tab: TExtTab;
  StyleContext: TExtTabDrawContext;
  TabRect: TRect;
  SavedPen: TExtPenState;
  Skip: Boolean;
begin
  Tab := FTabs[Index];
  IsHover := (Index = FHoverTab);
  TabRect := ARect;

  // Sensible defaults; the style procedure (or OnDrawTab) may override them
  FStyleOptions.FontColor := IfThen(IsActive, Font.Color, InactiveFontColor);
  FStyleOptions.Indent := GetScale(2);
  FStyleOptions.ShowStripLine := True;
  Skip := True;

  // Use the custom draw event (if assigned) or the built-in style
  if Assigned(FOnDrawTab) then
  begin
    SavedPen := SavePen(ACanvas);
    try
      FOnDrawTab(Self, ACanvas, TabRect, IsActive, IsHover, FStyleOptions, Skip);
    finally
      RestorePen(ACanvas, SavedPen);
    end;
  end;

  if Skip then
  begin
    StyleContext := BuildStyleContext(Tab);
    case FTabStyle of
      etsButton:
        DrawButtonTabStyle(ACanvas, TabRect, IsActive, StyleContext, FStyleOptions);
      etsDelphi:
        DrawDelphiTabStyle(ACanvas, TabRect, IsActive, StyleContext, FStyleOptions);
      etsMacOS:
        DrawMacOSTabStyle(ACanvas, TabRect, IsActive, StyleContext, FStyleOptions);
      etsFlat:
        DrawFlatTabStyle(ACanvas, TabRect, IsActive, StyleContext, FStyleOptions);
      etsChrome:
        DrawChromeTabStyle(ACanvas, TabRect, IsActive, StyleContext, FStyleOptions);
    end;
  end;

  // Content common to every style: color stripe, image, caption, close button.
  if (Tab.StripeColor <> clNone) then
  begin
    DrawColorStripe(ACanvas, TabRect, Tab, FStyleOptions.Indent);
    ACanvas.Brush.Style := bsClear;
    ACanvas.Pen.Style := psSolid;
  end;

  DrawTabTextAndImage(ACanvas, TabRect, Tab, IsActive, FStyleOptions.FontColor);
  DrawCloseButton(ACanvas, TabRect, Tab, IsActive);
end;

procedure TCustomExtTabCtrl.CalcLayout;
var
  i, Pos, TabLen: Integer;
  TxtExtent, ImgExtent,
  CloseExtent, Padding: Integer;
  ActiveExtra: TFontStyles;
  ImgW, ImgH: Integer;
begin
  if not FLayoutDirty then Exit;
  FLayoutDirty := False;

  Canvas.Font.Assign(Font);
  Pos := 0;
  Padding := GetScale(cContentIndent)*2 + GetScale(cTabOverlap);

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
    if FTabs[i].FFontOptions.FontColor <> clNone then
      Canvas.Font.Color := FTabs[i].FFontOptions.FontColor;
    if FTabs[i].FFontOptions.FontStyles <> [] then
      Canvas.Font.Style := FTabs[i].FFontOptions.FontStyles;

    // Measure text with all styles applied
    if i = FTabIndex then
    begin
      ActiveExtra := [];
      if etoActiveBold in FTabOptions then Include(ActiveExtra, fsBold);
      if etoActiveItalic in FTabOptions then Include(ActiveExtra, fsItalic);
      if ActiveExtra <> [] then
        Canvas.Font.Style := Canvas.Font.Style + ActiveExtra;
    end;

    // Use cached text width and height; measure only when stale
    if FTabs[i].FTextWidth < 0 then
    begin
      FTabs[i].FTextWidth := Canvas.TextWidth(GetDisplayCaption(FTabs[i]));
      FTabs[i].FTextHeight := Canvas.TextHeight(GetDisplayCaption(FTabs[i]));
    end;
    TxtExtent := FTabs[i].FTextWidth;

    ImgExtent := 0;
    ImgW := 0;
    ImgH := 0;

    // Check for ImageList + ImageIndex
    if Assigned(FImages) and (FTabs[i].ImageIndex >= 0) then
    begin
      ImgW := FInternalImages.WidthForPPI[FImagesWidth.TabsWidth, Font.PixelsPerInch];
      ImgH := FInternalImages.HeightForPPI[FImagesWidth.TabsWidth, Font.PixelsPerInch];

      ImgExtent := IfThen(IsHorizontal, ImgW, ImgH) + GetScale(cImageSpacing);
    end
    // Fallback to the standalone TBitmap property
    else if Assigned(FTabs[i].FImage) and not FTabs[i].FImage.Empty then
    begin
      ImgW := FTabs[i].Image.Width;
      ImgH := FTabs[i].Image.Height;

      ImgExtent := IfThen(IsHorizontal, ImgW, ImgH) + GetScale(cImageSpacing);
    end;

    if (etoShowCloseButton in FTabOptions) and FTabs[i].ShowCloseButton then
      CloseExtent := GetIconExtent(FButtonImageIndexes.CloseIndex, FImagesWidth.CloseWidth, IsHorizontal) + GetScale(cContentIndent)
    else
      CloseExtent := 0;

    TabLen := Padding + TxtExtent + ImgExtent + CloseExtent;

    if IsHorizontal then
      FTabs[i].FBoundRect := Rect(Pos, 0, Pos + TabLen, FTabSize)
    else
      FTabs[i].FBoundRect := Rect(0, Pos, FTabSize, Pos + TabLen);

    Pos := Pos + TabLen - GetScale(cTabOverlap);
  end;

  // Restore control-level font after per-tab override passes
  Canvas.Font.Assign(Font);

  FTotalTabsSize := Pos + GetScale(cTabOverlap);
  UpdateScrollButtons;
end;

procedure TCustomExtTabCtrl.Paint;
var
  i: Integer;
  OrgSaveIdx, ClipSaveIdx: Integer;
  R, View, Dummy, TabRect: TRect;
  IndicatorPos, TabStart, TabEnd: Integer;
begin
  if not HandleAllocated then Exit;

  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);

  if FTabs.Count = 0 then Exit;

  CalcLayout;

  View := TabsViewportRect;

  // Draw the strip separator line across the full component edge
  DrawStripLineStyle(Canvas, View, BuildStyleContext(nil), FStyleOptions, ClientWidth, ClientHeight);

  OrgSaveIdx := SaveDC(Canvas.Handle);
  try
    ClipSaveIdx := SaveDC(Canvas.Handle);
    try
      IntersectClipRect(Canvas.Handle, View.Left, View.Top, View.Right, View.Bottom);

      // Draw all tabs in their original places
      for i := 0 to FTabs.Count - 1 do
      begin
        if not FTabs[i].Visible then Continue;
        R := FTabs[i].FBoundRect;
        OffsetToView(R, View);

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

        // Logical position: the leading edge of the target tab, or the
        // trailing edge of the last tab when dropping at the very end
        GetAxisSpan(TabRect, TabStart, TabEnd);
        if FDragTargetIndex = FTabs.Count then
          IndicatorPos := TabEnd
        else
          IndicatorPos := TabStart;

        // Transform logical position to visual position on the tab-flow axis
        IndicatorPos := IndicatorPos - FScrollOffset + IfThen(IsHorizontal, View.Left, View.Top);

        if IsHorizontal then
        begin
          Canvas.MoveTo(IndicatorPos, View.Top);
          Canvas.LineTo(IndicatorPos, View.Bottom);
        end
        else
        begin
          Canvas.MoveTo(View.Left, IndicatorPos);
          Canvas.LineTo(View.Right, IndicatorPos);
        end;

        Canvas.Pen.Width := 1;
      end;

      if Focused and (etoShowFocusRect in FTabOptions) and
         (FTabIndex >= 0) and (FTabIndex < FTabs.Count) then
      begin
        R := FTabs[FTabIndex].FBoundRect;
        OffsetToView(R, View);
        R := GetTabTextBounds(Canvas, R, FTabs[FTabIndex]);
        InflateRect(R, GetScale(2), GetScale(2));
        DrawFocusRect(Canvas.Handle, R);
      end;
    finally
      RestoreDC(Canvas.Handle, ClipSaveIdx);
    end;

    // {TODO} Cocoa keeps drawing the tabs over the space reserved for buttons
    // This is a workaround until the root cause is identified and fixed
    {$IFDEF LCLCocoa}
    Canvas.Brush.Color := Color;
    Canvas.Brush.Style := bsSolid;

    if IsHorizontal then
    begin
      if FTabPosition = etpTop then
      begin
        if View.Left > 0 then
          Canvas.FillRect(Rect(0, 0, View.Left, View.Bottom - 1));
        if View.Right < ClientWidth then
          Canvas.FillRect(Rect(View.Right, 0, ClientWidth, View.Bottom - 1));
      end
      else // etpBottom
      begin
        if View.Left > 0 then
          Canvas.FillRect(Rect(0, View.Top + 1, View.Left, ClientHeight));
        if View.Right < ClientWidth then
          Canvas.FillRect(Rect(View.Right, View.Top + 1, ClientWidth, ClientHeight));
      end;
    end
    else // IsVertical
    begin
      if FTabPosition = etpLeft then
      begin
        if View.Top > 0 then
          Canvas.FillRect(Rect(0, 0, View.Right - 1, View.Top));
        if View.Bottom < ClientHeight then
          Canvas.FillRect(Rect(0, View.Bottom, View.Right - 1, ClientHeight));
      end
      else // etpRight
      begin
        if View.Top > 0 then
          Canvas.FillRect(Rect(View.Left + 1, 0, ClientWidth, View.Top));
        if View.Bottom < ClientHeight then
          Canvas.FillRect(Rect(View.Left + 1, View.Bottom, ClientWidth, ClientHeight));
      end;
    end;
    {$ENDIF}
  finally
    RestoreDC(Canvas.Handle, OrgSaveIdx);
  end;
end;

procedure TCustomExtTabCtrl.Resize;
begin
  inherited Resize;
  if not HandleAllocated then Exit;
  FLayoutDirty := True;
  if FUpdateCount = 0 then
  begin
    CalcLayout;
    NormalizeState;
  end;

  Invalidate;
end;

// Lightweight tab-switch for use at design time and from the component tree
procedure TCustomExtTabCtrl.SetDesignTabIndex(AValue: Integer);
begin
  if (AValue < 0) or (AValue >= FTabs.Count) then Exit;
  if FTabIndex = AValue then Exit;

  FTabIndex := AValue;
  EnsureTabVisible(FTabIndex);

  {$IFDEF LCLDesign}
  if Assigned(GlobalDesignHook) then
  begin
    GlobalDesignHook.Modified(Self);
    // Forces the Object Inspector to reload lists
    GlobalDesignHook.RefreshPropertyValues;
  end;
  {$ENDIF}

  Invalidate;
end;

procedure TCustomExtTabCtrl.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Idx: Integer;
  View, R, CR: TRect;
begin
  if (csDesigning in ComponentState) and (Button in [mbLeft, mbRight]) then
  begin
    {$IFDEF DARWIN}
    if (Button = mbLeft) and (ssCtrl in Shift) then
      Button := mbRight;
    {$ENDIF}

    // Force the Object Inspector to instantly select this component
    {$IFDEF LCLDesign}
    if Assigned(GlobalDesignHook) then
      GlobalDesignHook.SelectOnlyThis(Self);
    {$ENDIF}

    if Button = mbLeft then
    begin
      // Child TSpeedButtons don't receive clicks at design time
      if FBtnScrollPrev.Visible and PtInRect(FBtnScrollPrev.BoundsRect, Point(X, Y)) then
      begin
        ScrollPrev(nil);
        Exit;
      end;
      if FBtnScrollNext.Visible and PtInRect(FBtnScrollNext.BoundsRect, Point(X, Y)) then
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
      {$IFDEF LCLDesign}
      if (Button = mbLeft) and Assigned(GlobalDesignHook) then
        GlobalDesignHook.SelectOnlyThis(Tabs[Idx]);
      {$ENDIF}
    end;

    Exit; // Bypass runtime mouse tracking actions
  end;

  inherited MouseDown(Button, Shift, X, Y);

  Idx := TabAtPos(X, Y);
  FMouseDownPos := Point(X, Y);
  FMouseDownIndex := Idx;

  if Idx = -1 then Exit;

  // Do not process close or middle-click deletes while a drag is in progress
  if FDragging then Exit;

  // Close button click: only on left mouse button
  if (Button = mbLeft) and (etoShowCloseButton in FTabOptions) and
     FTabs[Idx].ShowCloseButton then
  begin
    View := TabsViewportRect;
    CR := CloseButtonRect(FTabs[Idx]);
    R := FTabs[Idx].FBoundRect;

    OffsetToView(R, View);

    Types.OffsetRect(CR, R.Left, R.Top);

    if PtInRect(CR, Point(X, Y)) then
    begin
      DeleteTab(Idx);
      Exit;
    end;
  end;

  // Middle click closes tab
  if (Button = mbMiddle) and (etoCloseOnMiddleClick in FTabOptions) then
  begin
    DeleteTab(Idx);
    Exit;
  end;

  if Button = mbLeft then
  begin
    if etoGetFocus in FTabOptions then SetFocus;
    TabIndex := Idx;
  end;
end;

procedure TCustomExtTabCtrl.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  i, HoverNewTab: Integer;
  TabRect: TRect;
  MousePos, TabStart, TabEnd: Integer;
  View: TRect;
  P: TPoint;
  NewHint, OldHint: String;
  Msg: TLMMouse;
  IsOverCloseBtn: Boolean;
begin
  if csDesigning in ComponentState then
  begin
    if FHoverTab <> -1 then
    begin
      FHoverTab := -1;
      Invalidate;
    end;
    Exit;
  end;

  inherited MouseMove(Shift, X, Y);

  HoverNewTab := TabAtPos(X, Y);
  View := TabsViewportRect;

  // Capture existing hint to detect change
  OldHint := Self.Hint;

  // Is the mouse over the close "x" of the hovered tab?
  IsOverCloseBtn := False;
  if (HoverNewTab <> -1) and (etoShowCloseButton in FTabOptions) and
     FTabs[HoverNewTab].ShowCloseButton then
  begin
    TabRect := FTabs[HoverNewTab].FBoundRect;
    OffsetToView(TabRect, View);

    P := Point(X - TabRect.Left, Y - TabRect.Top);
    IsOverCloseBtn := PtInRect(CloseButtonRect(FTabs[HoverNewTab]), P);
  end;

  if not FDragging then
  begin
    // Update hover state and dynamic hint
    if FHoverTab <> HoverNewTab then
    begin
      // Mouse left the old tab
      if (FHoverTab <> -1) and Assigned(FOnMouseLeaveTab) then
        FOnMouseLeaveTab(Self, FHoverTab);

      // Mouse entered the new tab
      if (HoverNewTab <> -1) and Assigned(FOnMouseEnterTab) then
        FOnMouseEnterTab(Self, HoverNewTab);

      FHoverTab := HoverNewTab;
      Invalidate;
    end;

      if ShowHint then
      begin
        if IsOverCloseBtn and (FButtonHints.CloseHint <> '') then
          NewHint := FButtonHints.CloseHint
        else if (HoverNewTab <> -1) then  // Tab hover
        begin
          // Set hint to Tab.Hint or fallback to Tab.Text
          if FTabs[HoverNewTab].Hint <> '' then
            NewHint := FTabs[HoverNewTab].Hint
          else
            NewHint := FTabs[HoverNewTab].Caption;
        end
        else
          NewHint := '';

        if (NewHint <> OldHint) then
        begin
          Self.Hint := NewHint;

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

    // Close button hover (visual highlight)
    if FHoverCloseTab <> -1 then
    begin
      FHoverCloseTab := -1;
      Invalidate;  // clear the button that was previously highlighted
    end;
    if IsOverCloseBtn then
    begin
      FHoverCloseTab := HoverNewTab;
      Invalidate;
    end;

    // Drag detection
    if (ssLeft in Shift) and (FMouseDownIndex <> -1) and
      (etoAllowDragReorder in FTabOptions) then
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

    P := ViewToContent(Point(X, Y), View);
    MousePos := IfThen(IsHorizontal, P.X, P.Y);

    for i := 0 to FTabs.Count - 1 do
    begin
      if i = FDragIndex then Continue;

      TabRect := FTabs[i].FBoundRect;
      GetAxisSpan(TabRect, TabStart, TabEnd);

      // Check midpoint of the tab in logical space
      if MousePos < (TabStart + TabEnd) div 2 then
      begin
        FDragTargetIndex := i;
        Break;
      end;
    end;
    Invalidate;
  end;
end;

procedure TCustomExtTabCtrl.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Allow: Boolean;
  Idx: Integer;
begin
  if csDesigning in ComponentState then Exit;

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

procedure TCustomExtTabCtrl.MouseLeave;
begin
  inherited MouseLeave;

  if (FHoverTab <> -1) and Assigned(FOnMouseLeaveTab) then
    FOnMouseLeaveTab(Self, FHoverTab);

  FHoverTab := -1;
  FHoverCloseTab := -1;
  Hint := '';
  Invalidate;
end;

function TCustomExtTabCtrl.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
var
  Candidate: Integer;
  LocalPos: TPoint;
begin
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);
  if Result then Exit; // parent already handled it
  if FTabs.Count = 0 then Exit;

  // Only consume the wheel event when the pointer is over the tab strip itself
  LocalPos := ScreenToClient(MousePos);
  if not PtInRect(TabsViewportRect, LocalPos) then Exit;

  if WheelDelta < 0 then
    Candidate := NextVisibleTab(FTabIndex)
  else
    Candidate := PrevVisibleTab(FTabIndex);

  if Candidate <> -1 then
    TabIndex := Candidate;

  Result := True;
end;

procedure TCustomExtTabCtrl.DoEnter;
begin
  inherited DoEnter;
  Invalidate; // repaint to show focus indicator
  if Assigned(FOnGetFocus) then FOnGetFocus(Self);
end;

procedure TCustomExtTabCtrl.DoExit;
begin
  inherited DoExit;
  Invalidate; // repaint to hide focus indicator
  if Assigned(FOnLostFocus) then FOnLostFocus(Self);
end;

procedure TCustomExtTabCtrl.WMLMGetDlgCode(var Message: TLMessage);
begin
  // Only claim arrow keys when the control is allowed to hold focus
  if etoGetFocus in FTabOptions then
    Message.Result := DLGC_WANTARROWS
  else
    Message.Result := 0;
end;

procedure TCustomExtTabCtrl.CMDesignHitTest(var Message: TLMessage);
var
  PCoords: TSmallPoint;
  Pt: TPoint;
begin
  // Extract coordinates from LParam as a TSmallPoint (Lazarus documentation)
  // https://wiki.freepascal.org/Extending_the_IDE#Disabling_the_designer_mouse_handler
  PCoords := TSmallPoint(LongInt(Message.LParam));
  Pt := Point(PCoords.x, PCoords.y);

  // Return Message.Result := 1 if clicking on a visible scroll button or a valid tab
  if (FBtnScrollPrev.Visible and PtInRect(FBtnScrollPrev.BoundsRect, Pt)) or
     (FBtnScrollNext.Visible and PtInRect(FBtnScrollNext.BoundsRect, Pt)) or
     (TabAtPos(Pt.X, Pt.Y) <> -1) then
  begin
    Message.Result := 1; // Overrides the designer mouse handler for this click
  end;

  //inherited;
end;

procedure TCustomExtTabCtrl.DblClick;
var
  Idx: Integer;
begin
  inherited DblClick;
  // Use coordinates from MouseDown to identify which tab was double-clicked
  Idx := TabAtPos(FMouseDownPos.X, FMouseDownPos.Y);
  if (Idx <> -1) and Assigned(FOnTabDblClick) then
    FOnTabDblClick(Self, Idx);
end;

procedure TCustomExtTabCtrl.KeyDown(var Key: Word; Shift: TShiftState);
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

procedure TCustomExtTabCtrl.CreateWnd;
begin
  inherited CreateWnd;
  AnchorButtons;
end;

procedure TCustomExtTabCtrl.Loaded;
begin
  inherited Loaded;

  // Sync hints
  ButtonHintsChanged(Self);

  // Process the external images into the internal list
  PrepareInternalTabImages(GetRotationForPosition);

  UpdateBtnImages;
end;

procedure TCustomExtTabCtrl.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FImages then
    begin
      FInternalImages.Clear;
      FImages := nil;
    end;
    if Assigned(FBtnAdd) and (AComponent = FBtnAdd.PopupMenu) then
      FBtnAdd.PopupMenu := nil;
  end;
end;

procedure TCustomExtTabCtrl.CalculatePreferredSize(var PreferredWidth, PreferredHeight: Integer; WithImplicitConstraints: Boolean);
begin
  // Clamp the control to exactly the tab-strip thickness
  PreferredWidth := IfThen(IsHorizontal, 0, FTabSize);    // user controls width freely when horizontal
  PreferredHeight := IfThen(IsHorizontal, FTabSize, 0);   // user controls height freely when vertical
end;

procedure TCustomExtTabCtrl.CMShowHintChanged(var Message: TLMessage);
begin
  inherited;

  // Sync hints using the central method
  ButtonHintsChanged(Self);
end;

procedure TCustomExtTabCtrl.CMFontChanged(var Message: TLMessage);
begin
  inherited;

  // Rebuild the internal button glyphs
  UpdateBtnImages;
  UpdateImages;
end;

procedure TCustomExtTabCtrl.UpdateImages;
var
  i: Integer;
begin
  // Invalidate all cached text metrics, the new font makes them stale
  for i := 0 to FTabs.Count - 1 do
  begin
    FTabs[i].FTextWidth := -1;
    FTabs[i].FTextHeight := -1;
  end;

  // Re-fetch the proper resolutions from the external image list
  PrepareInternalTabImages(GetRotationForPosition);

  // Reload ButtonImageIndexes from FImages at the new DPI if indices are set
  if Assigned(FImages) then
    ButtonImagesChanged(Self);

  InvalidateLayout;
end;

procedure TCustomExtTabCtrl.UpdateBtnImages;
begin
  // Reset Images
  FBtnAdd.Images := nil;
  FBtnScrollPrev.Images := nil;
  FBtnScrollNext.Images := nil;

  FBtnAdd.Invalidate;
  FBtnScrollPrev.Invalidate;
  FBtnScrollNext.Invalidate;

  // Grow FTabSize if needed so none of the glyphs/images get clipped
  UpdateTabSizeForImages;
end;

procedure TCustomExtTabCtrl.UpdateTabSizeForImages;
var
  ppi: Integer;
  MinStrip: Integer;
  i, ImgExtent: Integer;
  ScrollPrevExtent, ScrollNextExtent, AddExtent: Integer;
begin
  if (csLoading in ComponentState) or (csDestroying in ComponentState) then
    Exit;

  ppi := Font.PixelsPerInch;

  // Start with the scroll/add button glyph sizes
  ScrollPrevExtent := GetIconExtent(FButtonImageIndexes.ScrollPrevIndex, FImagesWidth.PrevWidth, IsVertical);
  ScrollNextExtent := GetIconExtent(FButtonImageIndexes.ScrollNextIndex, FImagesWidth.NextWidth, IsVertical);
  AddExtent := GetIconExtent(FButtonImageIndexes.AddIndex, FImagesWidth.AddWidth, IsVertical);

  MinStrip := Max(Max(ScrollPrevExtent, ScrollNextExtent), AddExtent);

  // Account for per-tab images coming from the shared ImageList
  if Assigned(FImages) then
    MinStrip := Max(MinStrip, IfThen(IsHorizontal,
      FInternalImages.HeightForPPI[FImagesWidth.TabsWidth, ppi],
      FInternalImages.WidthForPPI[FImagesWidth.TabsWidth, ppi]));

  // Account for standalone Tab.Image bitmaps
  for i := 0 to FTabs.Count - 1 do
  begin
    if Assigned(FTabs[i].FImage) and not FTabs[i].FImage.Empty then
    begin
      ImgExtent := IfThen(IsHorizontal, FTabs[i].FImage.Height, FTabs[i].FImage.Width);
      MinStrip := Max(MinStrip, ImgExtent);
    end;
  end;

  // Leave room for the content indent on both sides of the image
  Inc(MinStrip, GetScale(cContentIndent)*2);

  // Grow the tab strip if it is currently too small
  MinStrip := MinStrip div GetScale(1);
  if FTabSize < MinStrip then
  begin
    FTabSize := MinStrip;
    if HandleAllocated then
    begin
      InvalidatePreferredSize;
      if AutoSize then AdjustSize;
    end;
    InvalidateLayout;
  end;
end;

procedure TCustomExtTabCtrl.DoAutoAdjustLayout(const AMode: TLayoutAdjustmentPolicy; const AXProportion, AYProportion: Double);
begin
  inherited;
  if AMode in [lapAutoAdjustWithoutHorizontalScrolling, lapAutoAdjustForDPI] then
  begin
    if IsStoredTabSize then
      FTabSize := round(FTabSize*AXProportion);
    AnchorButtons;
    UpdateTabSizeForImages;
  end;
end;

function TCustomExtTabCtrl.GetIsUpdating: Boolean;
begin
  Result := FUpdateCount > 0;
end;

procedure TCustomExtTabCtrl.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TCustomExtTabCtrl.EndUpdate;
begin
  if FUpdateCount > 0 then Dec(FUpdateCount);
  if FUpdateCount = 0 then
  begin
    InvalidateLayout;
    if FTabIndex >= 0 then
      EnsureTabVisible(FTabIndex)
    else
      NormalizeState;
  end;
end;

procedure TCustomExtTabCtrl.InvalidateLayout;
begin
  FLayoutDirty := True;
  if (FUpdateCount = 0) and HandleAllocated then Invalidate;
end;

function TCustomExtTabCtrl.AddTab(const ACaption: String; AData: TObject): TExtTab;
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

    if etoActivateNewTab in FTabOptions then
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

procedure TCustomExtTabCtrl.DeleteTab(Index: Integer);
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
    // User callback may have mutated collection: revalidate index
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
  begin
    Dec(NewIndex); // shift active index down
    // Fire OnTabChanging so consumers tracking the active index are notified
    Allow := True;
    if Assigned(FOnTabChanging) then
    begin
      FOnTabChanging(Self, OldIndex, NewIndex, Allow);
      if csDestroying in ComponentState then Exit;
      if (Index < 0) or (Index >= FTabs.Count) then Exit;
    end;
    if not Allow then Exit;
  end;

  BeginInternalChange;
  try
    FTabs.Delete(Index);

    if ((etoActiveBold in FTabOptions) or (etoActiveItalic in FTabOptions)) and
       (NewIndex >= 0) and (NewIndex < FTabs.Count) then
    begin
      FTabs[NewIndex].FTextWidth := -1;
      FTabs[NewIndex].FTextHeight := -1;
    end;

    FTabIndex := NewIndex;

    // Cancel any in-progress drag: indexes are now stale
    CancelDrag;

    // Reset hover state: indices may now be stale
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

procedure TCustomExtTabCtrl.ImportFromStrings(Source: TStrings; ClearExisting: Boolean = True);
var
  i: Integer;
  NewTab: TExtTab;
begin
  if not Assigned(Source) then Exit;

  Self.BeginUpdate;
  FImportActive := True;
  try
    if ClearExisting then
    begin
      FTabs.Clear;
      FAddTabCounter := 0;
    end;

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

procedure TCustomExtTabCtrl.PrepareInternalTabImages(ARotation: Integer);
var
  bmp: array of TCustomBitmap = nil;
  widths: Array of Integer = nil;
  i, j: Integer;
  R: TCustomImageListResolution;
begin
  FInternalImages.Clear;

  if FImages = nil then
    exit;

  if IsVertical then
  begin // Vertical layout
    SetLength(bmp, FImages.ResolutionCount);
    SetLength(widths, FImages.ResolutionCount);
    for i := 0 to FImages.ResolutionCount - 1 do
    begin
      bmp[i] := TBitmap.Create;
      widths[i] := FImages.ResolutionByIndex[i].Width;
    end;
    FInternalImages.RegisterResolutions(widths);
    try
      for j := 0 to FImages.Count-1 do
      begin
        for i := 0 to High(bmp) do
        begin
          R := FImages.ResolutionByIndex[i];
          R.GetBitmap(j, bmp[i]);
          if (j = FButtonImageIndexes.AddIndex) then
          begin
            if (etoRotateAddImage in FTabOptions) then
              RotateImage(bmp[i], ARotation);
          end
          else
          if (j = FButtonImageIndexes.ScrollPrevIndex) or (j = FButtonImageIndexes.ScrollNextIndex) then
            RotateImage(bmp[i], 270)
          else
          if etoRotateTabImages in FTabOptions then
            RotateImage(bmp[i], ARotation);
        end;
        FInternalImages.AddMultipleResolutions(bmp);
      end;
    finally
      for i := 0 to High(bmp) do
        bmp[i].Free;
      bmp := nil;
      widths := nil;
    end;
  end
  else // Horizontal layout
    FInternalImages.Assign(FImages);
end;

constructor TCustomExtTabCtrl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  ControlStyle := ControlStyle + [csClickEvents, csDoubleClicks, csOpaque];
  TabStop := True;

  // Provide a proper initial size when dropped onto a form by a  single click
  with GetControlClassDefaultSize do
    SetInitialBounds(0, 0, CX, CY);

  ShowHint := True;
  DoubleBuffered := True;
  FTabs := TExtTabs.Create(Self);
  FTabIndex := -1;
  FTabStyle := etsFlat;
  FTabPosition := etpTop;
  FTabSize := Scale96ToFont(cDefaultTabSize);
  FTabOptions := [etoActivateNewTab, etoShowCloseButton, etoShowAddButton,
                  etoCloseOnMiddleClick, etoAllowDragReorder, etoGetFocus,
                  etoShowFocusRect];
  FMinCaptionLen := 5;
  FMaxCaptionLen := 25;

  FInternalImages := TImageList.Create(self);
  FInternalImages.Scaled := true;

  FButtonImageIndexes := TExtButtonImageIndexes.Create(Self);
  FButtonImageIndexes.OnChange := @ButtonImagesChanged;
  FButtonHints := TExtButtonHints.Create;
  FButtonHints.OnChange := @ButtonHintsChanged;
  FImagesWidth := TExtImagesWidth.Create;
  FImagesWidth.OnChange := @ImagesWidthChanged;
  FBorderColor := clBtnShadow;

  FBtnAdd := TSpeedButton.Create(Self);
  FBtnAdd.Name := 'BtnAdd';  // just for debugging
  FBtnAdd.Parent := Self;
  FBtnAdd.Flat := True;
  FBtnAdd.ParentShowHint := False;
  FBtnAdd.OnClick := @AddBtnClick;
  FBtnAdd.OnPaint := @AddBtnPaint;
  FBtnAdd.BringToFront;

  FBtnScrollPrev := TSpeedButton.Create(Self);
  FBtnScrollPrev.Name := 'BtnScrollPrev';
  FBtnScrollPrev.Parent := Self;
  FBtnScrollPrev.Flat := True;
  FBtnScrollPrev.ParentShowHint := False;
  FBtnScrollPrev.ShowHint := ShowHint;
  FBtnScrollPrev.OnClick := @ScrollPrev;
  FBtnScrollPrev.OnPaint := @ScrollBtnPaint;
  FBtnScrollPrev.BringToFront;

  FBtnScrollNext := TSpeedButton.Create(Self);
  FBtnScrollNext.Name := 'BtnScrollNext';
  FBtnScrollNext.Parent := Self;
  FBtnScrollNext.Flat := True;
  FBtnScrollNext.ParentShowHint := False;
  FBtnScrollNext.ShowHint := ShowHint;
  FBtnScrollNext.OnClick := @ScrollNext;
  FBtnScrollNext.OnPaint := @ScrollBtnPaint;
  FBtnScrollNext.BringToFront;

  FMouseDownIndex := -1;
  FDragIndex := -1;
  FDragTargetIndex := -1;
  FHoverTab := -1;
  FHoverCloseTab := -1;
  FAddTabCounter := 0;
  FImportActive := False;
  FInternalChange := 0;
end;

destructor TCustomExtTabCtrl.Destroy;
begin
  // Cancel any pending hint window that may reference our handle
  Application.CancelHint;
  ShowHint := False;

  // Explicitly free child buttons before their glyph bitmaps are freed
  FreeAndNil(FBtnAdd);
  FreeAndNil(FBtnScrollPrev);
  FreeAndNil(FBtnScrollNext);

  FreeAndNil(FInternalImages);
  FreeAndNil(FButtonImageIndexes);
  FreeAndNil(FButtonHints);
  FreeAndNil(FImagesWidth);

  FreeAndNil(FTabs);

  inherited Destroy;
end;

initialization
  {$I ExtTabCtrl.lrs}

end.
