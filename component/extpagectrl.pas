unit ExtPageCtrl;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, LCLType, Types, Math, LResources,
  Contnrs, Forms, ExtCtrls, ImgList, ExtTabCtrl, LMessages
  {$IFDEF LCLDesign}, PropEdits{$ENDIF};

type
  TExtPageCtrl = class;

  TExtPage = class(TCustomControl)
  private
    FPageCtrl: TExtPageCtrl;
    FTab: TExtTab;

    FStripeColor: TColor;
    FValue: String;
    FFontOptions: TExtFontOptions;
    FImage: TBitmap;
    FImageIndex: TImageIndex;
    FPageHint: String;
    FShowCloseButton: Boolean;

    procedure SetStripeColor(AValue: TColor);
    procedure SetTabVisible(AValue: Boolean);
    function GetTabVisible: Boolean;
    procedure SetImage(AValue: TBitmap);
    function GetImage: TBitmap;
    procedure SetImageIndex(AValue: TImageIndex);
    procedure SetShowCloseButton(AValue: Boolean);
    procedure FontOptionsChanged(Sender: TObject);
  protected
    // Intercept caption and colour changes so the paired tab stays in sync
    procedure CMTextChanged(var Message: TLMessage); message CM_TEXTCHANGED;
    procedure CMColorChanged(var Message: TLMessage); message CM_COLORCHANGED;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property Tab: TExtTab read FTab;
  published
    property Caption;
    property StripeColor: TColor read FStripeColor write SetStripeColor default clNone;
    property TabVisible: Boolean read GetTabVisible write SetTabVisible default True;
    property Value: String read FValue write FValue;
    property FontOptions: TExtFontOptions read FFontOptions;
    property Image: TBitmap read GetImage write SetImage;
    property ImageIndex: TImageIndex read FImageIndex write SetImageIndex default -1;
    property PageHint: String read FPageHint write FPageHint;
    property ShowCloseButton: Boolean read FShowCloseButton write SetShowCloseButton default True;

    property Color;
    property Align;
    property BorderWidth;
    property ChildSizing;
    property Enabled;
    property Font;
    property ParentColor default True;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Visible;
  end;

  TExtPageNotifyEvent = procedure(Sender: TObject; APage: TExtPage) of object;
  TExtPageDeletingEvent = procedure(Sender: TObject; APage: TExtPage) of object;

  TExtPageCtrl = class(TExtTabCtrl)
  private
    FPageList: TObjectList;
    FPageIndex: Integer;
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

  published
    property PageIndex: Integer read GetPageIndex write SetPageIndex default -1;

    property OnTabReordered: TTabReorderedEvent read GetOnTabReordered write SetOnTabReordered;
    property OnTabDeleting: TTabIndexAllowEvent read GetOnTabDeleting write SetOnTabDeleting;
    property OnTabDeleted: TNotifyEvent read GetOnTabDeleted write SetOnTabDeleted;
    property OnAddButtonClick: TButtonClickEvent read GetOnAddButtonClick write SetOnAddButtonClick;
  end;

implementation

{ TExtPage }

constructor TExtPage.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csAcceptsControls, csDesignFixedBounds,
                                  csNoDesignVisible, csNoFocus];
  Align := alNone;
  Visible := False;
  Caption := '';
  FStripeColor := clNone;
  FImageIndex := -1;
  FShowCloseButton := True;
  FFontOptions := TExtFontOptions.Create;
  FFontOptions.OnRedraw := @FontOptionsChanged;
end;

destructor TExtPage.Destroy;
begin
  FFontOptions.Free;
  FImage.Free;
  inherited Destroy;
end;

procedure TExtPage.FontOptionsChanged(Sender: TObject);
begin
  if Assigned(FTab) then
  begin
    FTab.FontOptions.Assign(FFontOptions);
    if Assigned(FPageCtrl) then FPageCtrl.Invalidate;
  end;
end;

procedure TExtPage.CMTextChanged(var Message: TLMessage);
begin
  inherited;
  // Caption changed: keep the paired tab caption in sync
  if Assigned(FTab) then FTab.Caption := Caption;
end;

procedure TExtPage.CMColorChanged(var Message: TLMessage);
begin
  inherited;
  if Assigned(FTab) then FTab.Color := Color;
end;

procedure TExtPage.SetStripeColor(AValue: TColor);
begin
  if FStripeColor = AValue then Exit;
  FStripeColor := AValue;
  if Assigned(FTab) then FTab.StripeColor := AValue;
end;

function TExtPage.GetTabVisible: Boolean;
begin
  if Assigned(FTab) then Result := FTab.Visible
  else                    Result := True;
end;

procedure TExtPage.SetTabVisible(AValue: Boolean);
begin
  if Assigned(FTab) then FTab.Visible := AValue;
end;

function TExtPage.GetImage: TBitmap;
begin
  if FImage = nil then FImage := TBitmap.Create;
  Result := FImage;
end;

procedure TExtPage.SetImage(AValue: TBitmap);
begin
  if FImage = AValue then Exit;
  FreeAndNil(FImage);
  FImage := AValue;
  if Assigned(FTab) then FTab.Image := AValue;
end;

procedure TExtPage.SetImageIndex(AValue: TImageIndex);
begin
  if FImageIndex = AValue then Exit;
  FImageIndex := AValue;
  if Assigned(FTab) then FTab.ImageIndex := AValue;
end;

procedure TExtPage.SetShowCloseButton(AValue: Boolean);
begin
  if FShowCloseButton = AValue then Exit;
  FShowCloseButton := AValue;
  if Assigned(FTab) then FTab.ShowCloseButton := AValue;
end;

{ TExtPageCtrl }

constructor TExtPageCtrl.Create(AOwner: TComponent);
begin
  FPageList := TObjectList.Create(False);
  FPageIndex := -1;

  inherited Create(AOwner);

  ControlStyle := ControlStyle + [csAcceptsControls];
  FIsSyncing := False;
  FInLayout := False;

  inherited OnAddButtonClick := @InternalAddButtonClick;
  inherited OnTabReordered := @InternalTabReordered;
  inherited OnTabDeleting := @InternalTabDeleting;
  inherited OnTabDeleted := @InternalTabDeleted;
end;

destructor TExtPageCtrl.Destroy;
begin
  FreeAndNil(FPageList);
  inherited Destroy;
end;

{ Private helpers }

function TExtPageCtrl.GetUniquePageName: String;
var
  I: Integer;
  CompOwner: TComponent;
begin
  CompOwner := Owner;
  if CompOwner = nil then CompOwner := Self;
  I := 1;
  repeat
    Result := 'ExtPage' + IntToStr(I);
    Inc(I);
  until CompOwner.FindComponent(Result) = nil;
end;

function TExtPageCtrl.GetPage(Index: Integer): TExtPage;
begin
  if Assigned(FPageList) and (Index >= 0) and (Index < FPageList.Count) then
    Result := TExtPage(FPageList[Index])
  else
    Result := nil;
end;

function TExtPageCtrl.GetPageCount: Integer;
begin
  if Assigned(FPageList) then
    Result := FPageList.Count
  else
    Result := 0;
end;

function TExtPageCtrl.GetActivePage: TExtPage;
begin
  Result := GetPage(FPageIndex);
end;

function TExtPageCtrl.GetPageIndex: Integer;
begin
  Result := FPageIndex;
end;

procedure TExtPageCtrl.SetPageIndex(AValue: Integer);
var
  OldPage, NewPage: TExtPage;
begin
  if not Assigned(FPageList) then Exit;
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
    OldPage.SendToBack;
    OldPage.Visible := False;
    OldPage.ControlStyle := OldPage.ControlStyle + [csNoDesignVisible];
  end;

  FPageIndex := AValue;

  LayoutPages;

  // Bring to front the new page
  if Assigned(NewPage) then
  begin
    NewPage.Visible := True;
    NewPage.ControlStyle := NewPage.ControlStyle - [csNoDesignVisible];
    NewPage.BringToFront;
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

procedure TExtPageCtrl.SetPages(AValue: TStrings);
begin
  // Intentional no-op: pages are children, not a string list.
end;

function TExtPageCtrl.IndexOfPage(APage: TExtPage): Integer;
begin
  if Assigned(FPageList) then
    Result := FPageList.IndexOf(APage)
  else
    Result := -1;
end;

procedure TExtPageCtrl.LayoutPages;
var
  i, B: Integer;
  P: TExtPage;
  R: TRect;
  TBT: Integer;
begin
  if FInLayout then Exit;
  if not Assigned(FPageList) then Exit;
  FInLayout := True;
  try
    R := ClientRect;
    TBT := TabSize;

    // If the style draws a border, we must inset the page by 1 pixel
    if TabStyle = etsMacOS then B := 0 else B := 1;

    for i := 0 to FPageList.Count - 1 do
    begin
      P := TExtPage(FPageList[i]);
      if P = nil then Continue;

      if i = FPageIndex then
      begin
        // Active page assumes normal boundaries
        case TabPosition of
          etpTop:
            P.SetBounds(R.Left + B, R.Top + TBT, Max(0, R.Width - B*2), Max(0, R.Height - TBT - B));
          etpBottom:
            P.SetBounds(R.Left + B, R.Top + B, Max(0, R.Width - B*2), Max(0, R.Height - TBT - B));
          etpLeft:
            P.SetBounds(R.Left + TBT, R.Top + B, Max(0, R.Width - TBT - B), Max(0, R.Height - B*2));
          etpRight:
            P.SetBounds(R.Left + B, R.Top + B, Max(0, R.Width - TBT - B), Max(0, R.Height - B*2));
        end;
      end
      else // Push inactive pages out of the rendering area
        P.SetBounds(-10000, -10000, 0, 0);
    end;
  finally
    FInLayout := False;
  end;
end;

{ Internal event handlers }

procedure TExtPageCtrl.InternalAddButtonClick(Sender: TObject);
begin
  // If the user assigned a custom handler, call it and let them decide what to do
  if Assigned(FUserOnAddButtonClick) then
    FUserOnAddButtonClick(Sender)
  else
    AddPage('New Page ' + IntToStr(PageCount + 1));
end;

procedure TExtPageCtrl.InternalTabReordered(Sender: TObject; OldIndex, NewIndex: Integer);
begin
  // Keep FPageList in sync when the user drag-reorders a tab.
  if Assigned(FPageList) and
     (OldIndex >= 0) and (OldIndex < FPageList.Count) and
     (NewIndex >= 0) and (NewIndex < FPageList.Count) then
    FPageList.Move(OldIndex, NewIndex);

  FPageIndex := TabIndex;   // TabIndex was updated by TExtTabCtrl already

  // Forward to user handler if one is assigned.
  if Assigned(FUserOnTabReordered) then
    FUserOnTabReordered(Sender, OldIndex, NewIndex);
end;

procedure TExtPageCtrl.InternalTabDeleting(Sender: TObject; Index: Integer; var Allow: Boolean);
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
end;

procedure TExtPageCtrl.InternalTabDeleted(Sender: TObject);
begin
  // The tab has been removed from FTabs by TExtTabCtrl.DeleteTab
  if Assigned(FUserOnTabDeleted) then
    FUserOnTabDeleted(Sender);
end;

{ Forwarding getters/setters for intercepted events }

procedure TExtPageCtrl.SetOnAddButtonClick(AValue: TButtonClickEvent);
begin
  FUserOnAddButtonClick := AValue;
end;

function TExtPageCtrl.GetOnAddButtonClick: TButtonClickEvent;
begin
  Result := FUserOnAddButtonClick;
end;

procedure TExtPageCtrl.SetOnTabReordered(AValue: TTabReorderedEvent);
begin
  FUserOnTabReordered := AValue;
end;

function TExtPageCtrl.GetOnTabReordered: TTabReorderedEvent;
begin
  Result := FUserOnTabReordered;
end;

procedure TExtPageCtrl.SetOnTabDeleting(AValue: TTabIndexAllowEvent);
begin
  FUserOnTabDeleting := AValue;
end;

function TExtPageCtrl.GetOnTabDeleting: TTabIndexAllowEvent;
begin
  Result := FUserOnTabDeleting;
end;

procedure TExtPageCtrl.SetOnTabDeleted(AValue: TNotifyEvent);
begin
  FUserOnTabDeleted := AValue;
end;

function TExtPageCtrl.GetOnTabDeleted: TNotifyEvent;
begin
  Result := FUserOnTabDeleted;
end;

{ Core page management }

function TExtPageCtrl.AddPage(const ACaption: String): TExtPage;
var
  NewTab: TExtTab;
  NewPage: TExtPage;
  CompOwner: TComponent;
begin
  Result := nil;

  FIsSyncing := True;
  try
    NewTab := inherited AddTab(ACaption);
  finally
    FIsSyncing := False;
  end;
  if NewTab = nil then Exit;

  CompOwner := Owner;
  if CompOwner = nil then CompOwner := Self;

  // Roll back the tab we just created if page construction fails
  try
    NewPage := TExtPage.Create(CompOwner);
    NewPage.FPageCtrl := Self;
    NewPage.FTab := NewTab;
    NewPage.Parent := Self;
    NewPage.Visible := False;
    NewPage.ControlStyle := NewPage.ControlStyle + [csNoDesignVisible];

    NewTab.Caption := ACaption;

    if FPageList.IndexOf(NewPage) < 0 then
      FPageList.Add(NewPage);
  except
    FIsSyncing := True;
    try
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

procedure TExtPageCtrl.DeletePage(Index: Integer);
begin
  if (Index < 0) or (not Assigned(FPageList)) or (Index >= FPageList.Count) then Exit;
  inherited DeleteTab(Index);
end;

procedure TExtPageCtrl.MovePage(OldIndex, NewIndex: Integer);
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

function TExtPageCtrl.AddTab(const ACaption: String; AData: TObject): TExtTab;
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

procedure TExtPageCtrl.DeleteTab(Index: Integer);
begin
  DeletePage(Index);
end;

{ InsertControl: redirect component drops to the active page }

procedure TExtPageCtrl.InsertControl(AControl: TControl; Index: Integer);
begin
  if (AControl is TExtPage) or
     not Assigned(FPageList) or
     (csLoading in ComponentState) then
    inherited InsertControl(AControl, Index)
  else if Assigned(ActivePage) then
    AControl.Parent := ActivePage
  else
    inherited InsertControl(AControl, Index);
end;

{ Streaming/designer integration }

procedure TExtPageCtrl.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  // When a TExtPage is freed externally, remove it from our list
  if (Operation = opRemove) and Assigned(FPageList) and (AComponent is TExtPage) then
    FPageList.Remove(AComponent);
end;

procedure TExtPageCtrl.GetChildren(Proc: TGetChildProc; Root: TComponent);
var
  i: Integer;
begin
  if not Assigned(FPageList) then Exit;
  for i := 0 to FPageList.Count - 1 do
    Proc(TComponent(FPageList[i]));
end;

procedure TExtPageCtrl.ShowControl(AControl: TControl);
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
    i := FPageList.Count;

    if Assigned(Tabs) and (i < Tabs.Count) then
      StreamedPage.FTab := Tabs[i]
    else
    begin
      FIsSyncing := True;
      try
        NewTab := inherited AddTab(StreamedPage.Caption);
        StreamedPage.FTab := NewTab;
      finally
        FIsSyncing := False;
      end;
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

{ TExtTabCtrl virtual overrides }

procedure TExtPageCtrl.SetTabIndex(AValue: Integer);
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

procedure TExtPageCtrl.SetDesignTabIndex(AValue: Integer);
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

procedure TExtPageCtrl.NormalizeState;
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
        P.FTab := nil;
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

procedure TExtPageCtrl.Loaded;
var
  i: Integer;
  P: TExtPage;
  TabIdx: Integer;
begin
  inherited Loaded;

  TabIdx := 0;
  for i := 0 to ControlCount - 1 do
    if Controls[i] is TExtPage then
    begin
      P := TExtPage(Controls[i]);
      if FPageList.IndexOf(P) < 0 then
      begin
        if Assigned(Tabs) and (TabIdx < Tabs.Count) then
          P.FTab := Tabs[TabIdx]
        else
        begin
          FIsSyncing := True;
          try
            P.FTab := inherited AddTab(P.Caption);
          finally
            FIsSyncing := False;
          end;
        end;
        P.FPageCtrl := Self;
        P.Visible := False;
        P.ControlStyle := P.ControlStyle + [csNoDesignVisible];
        FPageList.Add(P);
      end;
      Inc(TabIdx);
    end;

  SetPageIndex(TabIndex);
  LayoutPages;
end;

procedure TExtPageCtrl.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Idx: Integer;
begin
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
        Idx := TabAtPos(X, Y);
        if (Idx >= 0) and Assigned(GlobalDesignHook) and Assigned(Page[Idx]) then
          GlobalDesignHook.SelectOnlyThis(Page[Idx]);
      end;
    end;
    {$ENDIF}
  end;
end;

class function TExtPageCtrl.GetControlClassDefaultSize: TSize;
begin
  // Tab strip (default 26 px) + a comfortable page area
  Result.cx := 300;
  Result.cy := 200;
end;

procedure TExtPageCtrl.CalculatePreferredSize(var PreferredWidth, PreferredHeight: Integer; WithImplicitConstraints: Boolean);
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

procedure TExtPageCtrl.Resize;
begin
  inherited Resize;
  // Skip layout while a BeginUpdate/EndUpdate transaction is open
  if IsUpdating then Exit;
  LayoutPages;
end;

procedure TExtPageCtrl.Paint;
var
  R: TRect;
begin
  inherited Paint;

  if TabStyle = etsMacOS then Exit;
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

procedure TExtPageCtrl.EndUpdate;
begin
  inherited EndUpdate;

  if not IsUpdating and Assigned(FPageList) then
    LayoutPages;
end;

initialization
  RegisterClass(TExtPage);
  {$I ExtPageCtrl.lrs}

end.
