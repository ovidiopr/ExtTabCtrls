unit ExtPageCtrl;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, LCLType, Types, Math, LResources,
  Contnrs, Forms, ExtCtrls, ImgList, ExtTabCtrl, ExtTabCtrlStyles
  {$IFDEF LCLDesign}, PropEdits{$ENDIF};

type
  TExtPage = class;

  TBeforeShowExtPageEvent = procedure (ASender: TObject; ANewPage: TExtPage; ANewIndex: Integer) of object;

  TCustomExtPageCtrl = class;

  TExtPage = class(TCustomControl)
  private
    FPageCtrl: TCustomExtPageCtrl;
    FTab: TExtTab;

    FOnBeforeShow: TBeforeShowExtPageEvent;
    function GetPageIndex: Integer;
    function GetTab: TExtTab;

    // Connect the Tab with the Page
    procedure LinkTab(ATab: TExtTab);
    procedure UnlinkTab;

    // Low-level (de)serialization of Tab's data
    procedure ReadTabCaption(Reader: TReader);
    procedure WriteTabCaption(Writer: TWriter);
    procedure ReadTabColor(Reader: TReader);
    procedure WriteTabColor(Writer: TWriter);
    procedure ReadTabStripeColor(Reader: TReader);
    procedure WriteTabStripeColor(Writer: TWriter);
    procedure ReadTabImageIndex(Reader: TReader);
    procedure WriteTabImageIndex(Writer: TWriter);
    procedure ReadTabShowCloseButton(Reader: TReader);
    procedure WriteTabShowCloseButton(Writer: TWriter);
    procedure ReadTabVisible(Reader: TReader);
    procedure WriteTabVisible(Writer: TWriter);
    procedure ReadTabHint(Reader: TReader);
    procedure WriteTabHint(Writer: TWriter);
  protected
    procedure DefineProperties(Filer: TFiler); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property PageIndex: Integer read GetPageIndex;
  published
    property Left stored False;
    property Top stored False;
    property Width stored False;
    property Height stored False;
    property Align stored False;
    property Visible stored False;
    property Caption stored False;

    // We save it "by hand"
    property Tab: TExtTab read GetTab stored False;

    property Color;
    property ChildSizing;
    property Enabled;
    property Font;
    property ParentColor default True;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;

    property OnBeforeShow: TBeforeShowExtPageEvent read FOnBeforeShow write FOnBeforeShow;
  end;

  TExtPageNotifyEvent = procedure(Sender: TObject; APage: TExtPage) of object;
  TExtPageDeletingEvent = procedure(Sender: TObject; APage: TExtPage) of object;

  TCustomExtPageCtrl = class(TCustomExtTabCtrl)
  private
    FPageList: TObjectList;
    FPageIndex: Integer;
    // PageIndex value read from the stream while FPageList is still empty
    FPendingPageIndex: Integer;
    FIsSyncing: Boolean;
    FInLayout: Boolean;

    FOnPageAdded: TExtPageNotifyEvent;
    FOnPageDeleting: TExtPageDeletingEvent;

    // Saved user events that we intercept internally for page sync
    FUserOnAddButtonClick: TButtonClickEvent;
    FUserOnTabReordered: TTabReorderedEvent;
    FUserOnTabDeleting: TTabIndexAllowEvent;
    FUserOnTabDeleted: TNotifyEvent;

    function GetPage(Index: Integer): TExtPage;
    function GetPageCount: Integer;
    function GetActivePage: TExtPage;
    procedure SetPageIndex(AValue: Integer);
    function GetPageIndex: Integer;
    procedure SetPages(AValue: TStrings);

    function GetUniquePageName: String;
    procedure LayoutPages;

    // Internal event handlers wired in constructor
    procedure InternalAddButtonClick(Sender: TObject);
    procedure InternalTabReordered(Sender: TObject; OldIndex, NewIndex: Integer);
    procedure InternalTabDeleting(Sender: TObject; Index: Integer; var Allow: Boolean);
    procedure InternalTabDeleted(Sender: TObject);

    // Forwarding getters/setters for the intercepted events
    procedure SetOnAddButtonClick(AValue: TButtonClickEvent);
    function GetOnAddButtonClick: TButtonClickEvent;
    procedure SetOnTabReordered(AValue: TTabReorderedEvent);
    function GetOnTabReordered: TTabReorderedEvent;
    procedure SetOnTabDeleting(AValue: TTabIndexAllowEvent);
    function GetOnTabDeleting: TTabIndexAllowEvent;
    procedure SetOnTabDeleted(AValue: TNotifyEvent);
    function GetOnTabDeleted: TNotifyEvent;
  protected
    procedure SetTabIndex(AValue: Integer); override;
    procedure NormalizeState; override;
    procedure Loaded; override;
    procedure Resize; override;
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    class function GetControlClassDefaultSize: TSize; override;
    procedure CalculatePreferredSize(var PreferredWidth, PreferredHeight: Integer; WithImplicitConstraints: Boolean); override;

    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
    procedure ShowControl(AControl: TControl); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure EndUpdate; override;

    procedure SetDesignTabIndex(AValue: Integer); override;
    procedure InsertControl(AControl: TControl; Index: Integer); override;

    function AddPage(const ACaption: String): TExtPage; virtual;
    procedure DeletePage(Index: Integer); virtual;
    procedure MovePage(OldIndex, NewIndex: Integer); virtual;

    function AddTab(const ACaption: String; AData: TObject = nil): TExtTab; override;
    procedure DeleteTab(Index: Integer); override;

    function IndexOfPage(APage: TExtPage): Integer;

    property ActivePage: TExtPage read GetActivePage;
    property Page[Index: Integer]: TExtPage read GetPage;
    property PageCount: Integer read GetPageCount;

    property OnPageAdded: TExtPageNotifyEvent read FOnPageAdded write FOnPageAdded;
    property OnPageDeleting: TExtPageDeletingEvent read FOnPageDeleting write FOnPageDeleting;

  protected
    property PageIndex: Integer read GetPageIndex write SetPageIndex default -1;

    property OnTabReordered: TTabReorderedEvent read GetOnTabReordered write SetOnTabReordered;
    property OnTabDeleting: TTabIndexAllowEvent read GetOnTabDeleting write SetOnTabDeleting;
    property OnTabDeleted: TNotifyEvent read GetOnTabDeleted write SetOnTabDeleted;
    property OnAddButtonClick: TButtonClickEvent read GetOnAddButtonClick write SetOnAddButtonClick;
  end;

  { TExtPageCtrl }
  TExtPageCtrl = class(TCustomExtPageCtrl)
  published
    property Align;
    property AutoSize;
    property BorderSpacing;
    property Color;
    property DoubleBuffered;
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

    property PageIndex;

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

{ TExtPage }

constructor TExtPage.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csAcceptsControls, csDesignFixedBounds,
                                  csNoDesignVisible, csNoFocus];
  Align := alClient;
  Visible := False;
  Caption := '';
end;

destructor TExtPage.Destroy;
begin
  UnlinkTab;
  inherited Destroy;
end;

procedure TExtPage.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);

  // Each entry reads/writes as 'Tab.xxx' in the LFM, so it still looks like
  // a normal nested property even though it's manually (de)serialized
  Filer.DefineProperty('Tab.Caption', @ReadTabCaption, @WriteTabCaption, True);
  Filer.DefineProperty('Tab.Color', @ReadTabColor, @WriteTabColor, Tab.Color <> clNone);
  Filer.DefineProperty('Tab.StripeColor', @ReadTabStripeColor, @WriteTabStripeColor, Tab.StripeColor <> clNone);
  Filer.DefineProperty('Tab.ImageIndex', @ReadTabImageIndex, @WriteTabImageIndex, Tab.ImageIndex <> -1);
  Filer.DefineProperty('Tab.ShowCloseButton', @ReadTabShowCloseButton, @WriteTabShowCloseButton, not Tab.ShowCloseButton);
  Filer.DefineProperty('Tab.Visible', @ReadTabVisible, @WriteTabVisible, not Tab.Visible);
  Filer.DefineProperty('Tab.Hint', @ReadTabHint, @WriteTabHint, Tab.Hint <> '');
end;

procedure TExtPage.ReadTabCaption(Reader: TReader);
begin
  Tab.Caption := Reader.ReadString;
end;

procedure TExtPage.WriteTabCaption(Writer: TWriter);
begin
  Writer.WriteString(Tab.Caption);
end;

procedure TExtPage.ReadTabColor(Reader: TReader);
var
  ColorValue: Longint;
begin
  if Reader.NextValue = vaIdent then
  begin
    if not IdentToColor(Reader.ReadIdent, ColorValue) then
      ColorValue := clNone;
    Tab.Color := TColor(ColorValue);
  end
  else
    Tab.Color := TColor(Reader.ReadInteger);
end;

procedure TExtPage.WriteTabColor(Writer: TWriter);
var
  Ident: String;
begin
  if ColorToIdent(Tab.Color, Ident) then
    Writer.WriteIdent(Ident)
  else
    Writer.WriteInteger(Tab.Color);
end;

procedure TExtPage.ReadTabStripeColor(Reader: TReader);
var
  ColorValue: Longint;
begin
  if Reader.NextValue = vaIdent then
  begin
    if not IdentToColor(Reader.ReadIdent, ColorValue) then
      ColorValue := clNone;
    Tab.StripeColor := TColor(ColorValue);
  end
  else
    Tab.StripeColor := TColor(Reader.ReadInteger);
end;

procedure TExtPage.WriteTabStripeColor(Writer: TWriter);
var
  Ident: String;
begin
  if ColorToIdent(Tab.StripeColor, Ident) then
    Writer.WriteIdent(Ident)
  else
    Writer.WriteInteger(Tab.StripeColor);
end;

procedure TExtPage.ReadTabImageIndex(Reader: TReader);
begin
  Tab.ImageIndex := Reader.ReadInteger;
end;

procedure TExtPage.WriteTabImageIndex(Writer: TWriter);
begin
  Writer.WriteInteger(Tab.ImageIndex);
end;

procedure TExtPage.ReadTabShowCloseButton(Reader: TReader);
begin
  Tab.ShowCloseButton := Reader.ReadBoolean;
end;

procedure TExtPage.WriteTabShowCloseButton(Writer: TWriter);
begin
  Writer.WriteBoolean(Tab.ShowCloseButton);
end;

procedure TExtPage.ReadTabVisible(Reader: TReader);
begin
  Tab.Visible := Reader.ReadBoolean;
end;

procedure TExtPage.WriteTabVisible(Writer: TWriter);
begin
  Writer.WriteBoolean(Tab.Visible);
end;

procedure TExtPage.ReadTabHint(Reader: TReader);
begin
  Tab.Hint := Reader.ReadString;
end;

procedure TExtPage.WriteTabHint(Writer: TWriter);
begin
  Writer.WriteString(Tab.Hint);
end;

function TExtPage.GetTab: TExtTab;
begin
  // Lazily create the Tab
  if not Assigned(FTab) then
    FTab := TExtTab.Create(nil);
  Result := FTab;
end;

function TExtPage.GetPageIndex: Integer;
begin
  if Assigned(FPageCtrl) then
    Result := FPageCtrl.IndexOfPage(Self)
  else
    Result := -1;
end;

{ Connect the Tab with the Page }

procedure TExtPage.LinkTab(ATab: TExtTab);
var
  OldTab: TExtTab;
begin
  if FTab = ATab then Exit;

  OldTab := FTab;
  FTab := nil;

  if Assigned(OldTab) then
  begin
    if OldTab.Collection = nil then
    begin
      // OldTab was only a placeholder
      if Assigned(ATab) then
      begin
        ATab.Caption := OldTab.Caption;
        ATab.Color := OldTab.Color;
        ATab.StripeColor := OldTab.StripeColor;
        ATab.ImageIndex := OldTab.ImageIndex;
        ATab.ShowCloseButton := OldTab.ShowCloseButton;
        ATab.Visible := OldTab.Visible;
        ATab.Hint := OldTab.Hint;
      end;
      OldTab.Free;
    end;
    // else: OldTab was a "real" collection-owned tab
  end;

  FTab := ATab;
end;

procedure TExtPage.UnlinkTab;
begin
  if not Assigned(FTab) then Exit;
  if FTab.Collection = nil then
    FTab.Free;
  FTab := nil;
end;

{ TCustomExtPageCtrl }

constructor TCustomExtPageCtrl.Create(AOwner: TComponent);
begin
  FPageList := TObjectList.Create(False);
  FPageIndex := -1;
  FPendingPageIndex := -1;

  inherited Create(AOwner);

  ControlStyle := ControlStyle + [csAcceptsControls];
  FIsSyncing := False;
  FInLayout := False;

  inherited OnAddButtonClick := @InternalAddButtonClick;
  inherited OnTabReordered := @InternalTabReordered;
  inherited OnTabDeleting := @InternalTabDeleting;
  inherited OnTabDeleted := @InternalTabDeleted;
end;

destructor TCustomExtPageCtrl.Destroy;
var
  i: Integer;
begin
  // TExtPage instances are not owned by this control
  if Assigned(FPageList) then
    for i := 0 to FPageList.Count - 1 do
      TExtPage(FPageList[i]).UnlinkTab;

  FreeAndNil(FPageList);
  inherited Destroy;
end;

{ Private helpers }

function TCustomExtPageCtrl.GetUniquePageName: String;
const
  BaseName = 'ExtPage';
var
  ExistingNames: TStringList;
  i, Suffix: Integer;
  OwnerComp: TComponent;
begin
  OwnerComp := Owner;
  if OwnerComp = nil then OwnerComp := Self;

  // Collect all used names
  ExistingNames := TStringList.Create;
  try
    ExistingNames.CaseSensitive := False;
    ExistingNames.Sorted := True;
    ExistingNames.Duplicates := dupIgnore;
    for i := 0 to OwnerComp.ComponentCount - 1 do
      if OwnerComp.Components[i].Name <> '' then
        ExistingNames.Add(OwnerComp.Components[i].Name);

    // Assign a unique name
    Suffix := 1;
    Result := BaseName + IntToStr(Suffix);
    while ExistingNames.IndexOf(Result) >= 0 do
    begin
      Inc(Suffix);
      Result := BaseName + IntToStr(Suffix);
    end;
  finally
    ExistingNames.Free;
  end;
end;

function TCustomExtPageCtrl.GetPage(Index: Integer): TExtPage;
begin
  if Assigned(FPageList) and (Index >= 0) and (Index < FPageList.Count) then
    Result := TExtPage(FPageList[Index])
  else
    Result := nil;
end;

function TCustomExtPageCtrl.GetPageCount: Integer;
begin
  if Assigned(FPageList) then
    Result := FPageList.Count
  else
    Result := 0;
end;

function TCustomExtPageCtrl.GetActivePage: TExtPage;
begin
  Result := GetPage(FPageIndex);
end;

function TCustomExtPageCtrl.GetPageIndex: Integer;
begin
  Result := FPageIndex;
end;

procedure TCustomExtPageCtrl.SetPageIndex(AValue: Integer);
var
  OldPage, NewPage: TExtPage;
begin
  if not Assigned(FPageList) then Exit;

  if csLoading in ComponentState then
  begin
    // Pages haven't been streamed in yet
    FPendingPageIndex := AValue;
    Exit;
  end;

  if (AValue < 0) and (FPageIndex < 0) and (FPageList.Count > 0) then
    AValue := 0;
  if AValue >= FPageList.Count then AValue := FPageList.Count - 1;
  if AValue < -1 then AValue := -1;
  if AValue = FPageIndex then Exit;

  OldPage := GetPage(FPageIndex);
  NewPage := GetPage(AValue);

  // Push the old page to the back of the z-order
  if Assigned(OldPage) then
  begin
    OldPage.ControlStyle := OldPage.ControlStyle + [csNoDesignVisible];
    OldPage.Visible := False;
  end;

  FPageIndex := AValue;

  LayoutPages;

  // Bring to front the new page
  if Assigned(NewPage) then
  begin
    if Assigned(NewPage.FOnBeforeShow) then
      NewPage.FOnBeforeShow(Self, NewPage, FPageIndex); // OnBeforeShow event
    NewPage.Visible := True;
    NewPage.ControlStyle := NewPage.ControlStyle - [csNoDesignVisible];
    NewPage.Align := alClient;
  end;

  if not FIsSyncing then
  begin
    FIsSyncing := True;
    try
      TabIndex := AValue;
    finally
      FIsSyncing := False;
    end;
  end;

  Invalidate;
end;

procedure TCustomExtPageCtrl.SetPages(AValue: TStrings);
begin
  // Intentional no-op: pages are children, not a string list.
end;

function TCustomExtPageCtrl.IndexOfPage(APage: TExtPage): Integer;
begin
  if Assigned(FPageList) then
    Result := FPageList.IndexOf(APage)
  else
    Result := -1;
end;

procedure TCustomExtPageCtrl.LayoutPages;
var
  i, B, TBT: Integer;
  P: TExtPage;
begin
  if FInLayout then Exit;
  if not Assigned(FPageList) then Exit;
  FInLayout := True;
  try
    TBT := TabSize;

    // If the style draws a border/strip line, we must inset the page by 1 pixel
    if StyleOptions.ShowStripLine then B := 1 else B := 0;

    for i := 0 to FPageList.Count - 1 do
    begin
      P := TExtPage(FPageList[i]);
      if P = nil then Continue;

      // Set page boundaries
      P.BorderSpacing.Left := IfThen(TabPosition = etpLeft, TBT, B);
      P.BorderSpacing.Top := IfThen(TabPosition = etpTop, TBT, B);
      P.BorderSpacing.Right := IfThen(TabPosition = etpRight, TBT, B);
      P.BorderSpacing.Bottom := IfThen(TabPosition = etpBottom, TBT, B);
    end;
  finally
    FInLayout := False;
  end;
end;

{ Internal event handlers }

procedure TCustomExtPageCtrl.InternalAddButtonClick(Sender: TObject);
begin
  // If the user assigned a custom handler, call it and let them decide what to do
  if Assigned(FUserOnAddButtonClick) then
    FUserOnAddButtonClick(Sender)
  else
    AddPage('New Page ' + IntToStr(PageCount + 1));
end;

procedure TCustomExtPageCtrl.InternalTabReordered(Sender: TObject; OldIndex, NewIndex: Integer);
begin
  // Keep FPageList in sync when the user drag-reorders a tab.
  if Assigned(FPageList) and
     (OldIndex >= 0) and (OldIndex < FPageList.Count) and
     (NewIndex >= 0) and (NewIndex < FPageList.Count) then
    FPageList.Move(OldIndex, NewIndex);

  FPageIndex := TabIndex;   // TabIndex was updated by TCustomExtTabCtrl already

  // Forward to user handler if one is assigned.
  if Assigned(FUserOnTabReordered) then
    FUserOnTabReordered(Sender, OldIndex, NewIndex);
end;

procedure TCustomExtPageCtrl.InternalTabDeleting(Sender: TObject; Index: Integer; var Allow: Boolean);
var
  DyingPage: TExtPage;
begin
  // Give the page-level observer a chance to cancel first.
  DyingPage := GetPage(Index);
  if Assigned(FOnPageDeleting) and Assigned(DyingPage) then
    FOnPageDeleting(Self, DyingPage);

  // Forward to the user's OnTabDeleting handler (may set Allow := False).
  if Assigned(FUserOnTabDeleting) then
    FUserOnTabDeleting(Sender, Index, Allow);

  // If the deletion is going ahead, detach and release the page
  if Allow and Assigned(DyingPage) then
  begin
    FPageList.Remove(DyingPage);
    DyingPage.UnlinkTab;
    DyingPage.FPageCtrl := nil;
    DyingPage.Parent := nil;
    Application.ReleaseComponent(DyingPage);
  end;
end;

procedure TCustomExtPageCtrl.InternalTabDeleted(Sender: TObject);
begin
  // The tab has been removed from FTabs by TCustomExtTabCtrl.DeleteTab
  if Assigned(FUserOnTabDeleted) then
    FUserOnTabDeleted(Sender);
end;

{ Forwarding getters/setters for intercepted events }

procedure TCustomExtPageCtrl.SetOnAddButtonClick(AValue: TButtonClickEvent);
begin
  FUserOnAddButtonClick := AValue;
end;

function TCustomExtPageCtrl.GetOnAddButtonClick: TButtonClickEvent;
begin
  Result := FUserOnAddButtonClick;
end;

procedure TCustomExtPageCtrl.SetOnTabReordered(AValue: TTabReorderedEvent);
begin
  FUserOnTabReordered := AValue;
end;

function TCustomExtPageCtrl.GetOnTabReordered: TTabReorderedEvent;
begin
  Result := FUserOnTabReordered;
end;

procedure TCustomExtPageCtrl.SetOnTabDeleting(AValue: TTabIndexAllowEvent);
begin
  FUserOnTabDeleting := AValue;
end;

function TCustomExtPageCtrl.GetOnTabDeleting: TTabIndexAllowEvent;
begin
  Result := FUserOnTabDeleting;
end;

procedure TCustomExtPageCtrl.SetOnTabDeleted(AValue: TNotifyEvent);
begin
  FUserOnTabDeleted := AValue;
end;

function TCustomExtPageCtrl.GetOnTabDeleted: TNotifyEvent;
begin
  Result := FUserOnTabDeleted;
end;

{ Core page management }

function TCustomExtPageCtrl.AddPage(const ACaption: String): TExtPage;
var
  NewTab: TExtTab;
  NewPage: TExtPage;
  OwnerComp: TComponent;
begin
  Result := nil;
  NewPage := nil;

  FIsSyncing := True;
  try
    NewTab := inherited AddTab(ACaption);
  finally
    FIsSyncing := False;
  end;
  if NewTab = nil then Exit;

  OwnerComp := Owner;
  if OwnerComp = nil then OwnerComp := Self;

  try
    FIsSyncing := True;
    try
      NewPage := TExtPage.Create(OwnerComp);
      NewPage.FPageCtrl := Self;
      FPageList.Add(NewPage);
      NewPage.Name := GetUniquePageName;
      NewPage.LinkTab(NewTab);
      NewPage.Parent := Self;
      NewPage.Align := alClient;
      NewPage.Visible := False;
      NewPage.ControlStyle := NewPage.ControlStyle + [csNoDesignVisible];
    finally
      FIsSyncing := False;
    end;
  except
    // Roll back both the page and the tab we just created if anything fails
    FIsSyncing := True;
    try
      if Assigned(NewPage) then
      begin
        FPageList.Remove(NewPage);
        NewPage.UnlinkTab;
        NewPage.FPageCtrl := nil;
        NewPage.Parent := nil;
        NewPage.Free;
      end;
      inherited DeleteTab(NewTab.Index);
    finally
      FIsSyncing := False;
    end;
    raise;
  end;

  if (FPageList.Count = 1) and (TabIndex < 0) then
    SetPageIndex(0)
  else if FPageList.Count - 1 = TabIndex then
    SetPageIndex(TabIndex);

  LayoutPages;

  if Assigned(FOnPageAdded) then
    FOnPageAdded(Self, NewPage);

  Result := NewPage;
end;

procedure TCustomExtPageCtrl.DeletePage(Index: Integer);
begin
  if (Index < 0) or (not Assigned(FPageList)) or (Index >= FPageList.Count) then Exit;
  inherited DeleteTab(Index);
end;

procedure TCustomExtPageCtrl.MovePage(OldIndex, NewIndex: Integer);
begin
  if not Assigned(FPageList) then Exit;
  if (OldIndex < 0) or (OldIndex >= FPageList.Count) then Exit;
  if (NewIndex < 0) or (NewIndex >= FPageList.Count) then Exit;
  if OldIndex = NewIndex then Exit;

  // Move the TExtTab item; InternalTabReordered will then move FPageList
  FIsSyncing := True;
  try
    Tabs[OldIndex].Index := NewIndex;
    FPageList.Move(OldIndex, NewIndex);
    FPageIndex := TabIndex;
  finally
    FIsSyncing := False;
  end;
  Invalidate;
end;

{ Compatibility shims }

function TCustomExtPageCtrl.AddTab(const ACaption: String; AData: TObject): TExtTab;
var
  P: TExtPage;
begin
  P := AddPage(ACaption);
  if Assigned(P) then
  begin
    if Assigned(AData) then P.Tab.Data := AData;
    Result := P.Tab;
  end
  else
    Result := nil;
end;

procedure TCustomExtPageCtrl.DeleteTab(Index: Integer);
begin
  DeletePage(Index);
end;

{ InsertControl: redirect component drops to the active page }

procedure TCustomExtPageCtrl.InsertControl(AControl: TControl; Index: Integer);
begin
  if (AControl is TExtPage) or not Assigned(FPageList) or (csLoading in ComponentState) then
    inherited InsertControl(AControl, Index)
  else if Assigned(ActivePage) then
    AControl.Parent := ActivePage
  else
    inherited InsertControl(AControl, Index);
end;

{ Streaming/designer integration }

procedure TCustomExtPageCtrl.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  // When a TExtPage is freed externally, remove it from our list
  if (Operation = opRemove) and Assigned(FPageList) and (AComponent is TExtPage) then
    FPageList.Remove(AComponent);
end;

procedure TCustomExtPageCtrl.GetChildren(Proc: TGetChildProc; Root: TComponent);
var
  i: Integer;
begin
  if not Assigned(FPageList) then Exit;
  for i := 0 to FPageList.Count - 1 do
    Proc(TComponent(FPageList[i]));
end;

procedure TCustomExtPageCtrl.ShowControl(AControl: TControl);
var
  i: Integer;
  Idx: Integer;
  StreamedPage: TExtPage;
  NewTab: TExtTab;
begin
  if not Assigned(FPageList) then
  begin
    inherited ShowControl(AControl);
    Exit;
  end;

  Idx := -1;
  for i := 0 to FPageList.Count - 1 do
    if FPageList[i] = AControl then
    begin
      Idx := i;
      Break;
    end;

  if (Idx = -1) and (AControl is TExtPage) then
  begin
    StreamedPage := TExtPage(AControl);

    FIsSyncing := True;
    try
      NewTab := inherited AddTab(StreamedPage.Name);
      StreamedPage.LinkTab(NewTab);
    finally
      FIsSyncing := False;
    end;

    StreamedPage.FPageCtrl := Self;
    StreamedPage.ControlStyle := StreamedPage.ControlStyle + [csNoDesignVisible];
    FPageList.Add(StreamedPage);
    Idx := FPageList.Count - 1;
  end;

  if Idx <> -1 then
    SetPageIndex(Idx);

  inherited ShowControl(AControl);
end;

{ TCustomExtTabCtrl virtual overrides }

procedure TCustomExtPageCtrl.SetTabIndex(AValue: Integer);
begin
  inherited SetTabIndex(AValue);
  if not Assigned(FPageList) then Exit;
  if not FIsSyncing then
  begin
    FIsSyncing := True;
    try
      SetPageIndex(AValue);
    finally
      FIsSyncing := False;
    end;
  end;
end;

procedure TCustomExtPageCtrl.SetDesignTabIndex(AValue: Integer);
begin
  inherited SetDesignTabIndex(AValue);
  if not Assigned(FPageList) then Exit;
  if not FIsSyncing then
  begin
    FIsSyncing := True;
    try
      SetPageIndex(AValue);
    finally
      FIsSyncing := False;
    end;
  end;
end;

procedure TCustomExtPageCtrl.NormalizeState;
var
  i: Integer;
  Found: Boolean;
  P: TExtPage;
  NewIdx: Integer;
begin
  inherited NormalizeState;
  if not Assigned(FPageList) or not Assigned(Tabs) then Exit;
  if FIsSyncing then Exit;

  FIsSyncing := True;
  try
    // Remove pages that no longer have a corresponding Tab
    i := FPageList.Count - 1;
    while i >= 0 do
    begin
      P := TExtPage(FPageList[i]);
      Found := False;

      // Check if this page's FTab is still in the Tabs list
      if Assigned(P.FTab) then
        if (P.FTab.Collection <> nil) then Found := True;

      if not Found then
      begin
        FPageList.Delete(i);
        P.UnlinkTab;
        P.FPageCtrl := nil;
        P.Parent := nil;
        Application.ReleaseComponent(P);
      end;
      Dec(i);
    end;

    // Clamp FPageIndex to valid range
    NewIdx := TabIndex;
    if NewIdx >= FPageList.Count then NewIdx := FPageList.Count - 1;
    SetPageIndex(NewIdx);

    LayoutPages;
  finally
    FIsSyncing := False;
  end;
end;

procedure TCustomExtPageCtrl.Loaded;
var
  i: Integer;
  P: TExtPage;
begin
  inherited Loaded;

  for i := 0 to ControlCount - 1 do
    if Controls[i] is TExtPage then
    begin
      P := TExtPage(Controls[i]);
      if FPageList.IndexOf(P) < 0 then
      begin
        FIsSyncing := True;
        try
          P.LinkTab(inherited AddTab(P.Name));
        finally
          FIsSyncing := False;
        end;
        P.FPageCtrl := Self;
        P.Visible := False;
        P.ControlStyle := P.ControlStyle + [csNoDesignVisible];
        FPageList.Add(P);
      end;
    end;

  // Apply deferred PageIndex
  SetPageIndex(FPendingPageIndex);
  LayoutPages;
end;

procedure TCustomExtPageCtrl.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Idx: Integer;
begin
  // Hit-test before calling inherited (tabs can be scrolled there)
  Idx := TabAtPos(X, Y);

  inherited MouseDown(Button, Shift, X, Y);

  if (csDesigning in ComponentState) then
  begin
    {$IFDEF LCLDesign}
    {$IFDEF DARWIN}
    if (Button = mbLeft) and (ssCtrl in Shift) then
      Button := mbRight;
    {$ENDIF}

    case Button of
      mbRight: begin
        if Assigned(GlobalDesignHook) then
          GlobalDesignHook.SelectOnlyThis(Self);
      end;
      mbLeft: begin
        if (Idx >= 0) and Assigned(GlobalDesignHook) and Assigned(Page[Idx]) then
          GlobalDesignHook.SelectOnlyThis(Page[Idx]);
      end;
    end;
    {$ENDIF}
  end;
end;

class function TCustomExtPageCtrl.GetControlClassDefaultSize: TSize;
begin
  // Tab strip (default 26 px) + a comfortable page area
  Result.cx := 300;
  Result.cy := 200;
end;

procedure TCustomExtPageCtrl.CalculatePreferredSize(var PreferredWidth, PreferredHeight: Integer; WithImplicitConstraints: Boolean);
var
  i, j: Integer;
  P: TExtPage;
  C: TControl;
  ContentW, ContentH: Integer;
begin
  // Start from the tab-strip preferred size computed by the base class
  inherited CalculatePreferredSize(PreferredWidth, PreferredHeight, WithImplicitConstraints);

  // Add the preferred content area: the smallest rectangle that fits all
  // controls on any page (union across pages so resizing never clips content)
  ContentW := 0;
  ContentH := 0;
  for i := 0 to FPageList.Count - 1 do
  begin
    P := TExtPage(FPageList[i]);
    if P = nil then Continue;
    for j := 0 to P.ControlCount - 1 do
    begin
      C := P.Controls[j];
      ContentW := Max(ContentW, C.Left + C.Width);
      ContentH := Max(ContentH, C.Top + C.Height);
    end;
  end;

  // Pad the content area
  Inc(ContentW, 8);
  Inc(ContentH, 8);

  if IsHorizontal then
    // Tab strip contributes to height; width is free
    Inc(PreferredHeight, ContentH)
  else
    // Tab strip contributes to width; height is free
    Inc(PreferredWidth, ContentW);
end;

procedure TCustomExtPageCtrl.Resize;
begin
  inherited Resize;
  // Skip layout while a BeginUpdate/EndUpdate transaction is open
  if IsUpdating then Exit;
  LayoutPages;
end;

procedure TCustomExtPageCtrl.Paint;
var
  R: TRect;
begin
  inherited Paint;

  if not StyleOptions.ShowStripLine then Exit;
  if (not Assigned(Tabs)) or (Tabs.Count = 0) then Exit;

  R := ClientRect;
  case TabPosition of
    etpTop: R.Top := R.Top + TabSize;
    etpBottom: R.Bottom := R.Bottom - TabSize;
    etpLeft: R.Left := R.Left + TabSize;
    etpRight: R.Right := R.Right - TabSize;
  end;

  Canvas.Pen.Color := BorderColor;
  Canvas.Pen.Width := 1;
  Canvas.Pen.Style := psSolid;

  case TabPosition of
    etpTop:
      // Strip line is the top edge; draw right, bottom, left
      Canvas.Polyline([Point(R.Right - 1, R.Top), Point(R.Right - 1, R.Bottom - 1),
                       Point(R.Left, R.Bottom - 1), Point(R.Left, R.Top)]);
    etpBottom:
      // Strip line is the bottom edge; draw left, top, right
      Canvas.Polyline([Point(R.Left, R.Bottom - 1), Point(R.Left, R.Top),
                       Point(R.Right - 1, R.Top), Point(R.Right - 1, R.Bottom - 1)]);
    etpLeft:
      // Strip line is the left edge; draw top, right, bottom
      Canvas.Polyline([Point(R.Left, R.Top), Point(R.Right - 1, R.Top),
                       Point(R.Right - 1, R.Bottom - 1), Point(R.Left, R.Bottom - 1)]);
    etpRight:
      // Strip line is the right edge; draw top, left, bottom
      Canvas.Polyline([Point(R.Right - 1, R.Top), Point(R.Left, R.Top),
                       Point(R.Left, R.Bottom - 1), Point(R.Right - 1, R.Bottom - 1)]);
  end;
end;

procedure TCustomExtPageCtrl.EndUpdate;
begin
  inherited EndUpdate;

  if not IsUpdating and Assigned(FPageList) then
    LayoutPages;
end;

initialization
  RegisterClass(TExtPage);
  {$I ExtPageCtrl.lrs}

end.
