unit umain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ExtTabCtrl, ExtTabCtrlStyles, LCLIntf, LResources, Menus, Types, Math;

type
  { TForm1 }
  TForm1 = class(TForm)
    cbStyle: TComboBox;
    cbPos: TComboBox;
    chbCustomAddButton: TCheckBox;
    chbCustomCloseButtons: TCheckBox;
    chbCustomScrollButtons: TCheckBox;
    ExtTabCtrl1: TExtTabCtrl;
    GroupBox1: TGroupBox;
    ImageList1: TImageList;
    lblStyle: TLabel;
    lblPos: TLabel;
    MemoLog: TMemo;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    PopupMenu1: TPopupMenu;
    procedure chbCustomButtonChange(Sender: TObject);
    procedure ExtTabCtrl1DrawButton(Sender: TObject; ACanvas: TCanvas; ARect: TRect;
      AButtonType: TExtButtonType; ATab: TExtTab; IsActive, IsHover: Boolean; var Skip: Boolean);
    procedure ExtTabCtrl1DrawTab(Sender: TObject; ACanvas: TCanvas; ARect: TRect;
      IsActive, IsHover: Boolean; var Options: TExtTabStyleOptions; var Skip: Boolean);
    procedure ExtTabCtrl1ImportTab(Sender: TObject; Tab: TExtTab; AObject: TObject);
    procedure ExtTabCtrl1TabReordered(Sender: TObject; OldIndex, NewIndex: Integer);
    procedure FormCreate(Sender: TObject);

    // Existing event handlers
    procedure ExtTabCtrl1TabChanged(Sender: TObject; NewIndex: Integer);
    procedure ExtTabCtrl1TabReordering(Sender: TObject; OldIndex, NewIndex: Integer; var Allow: Boolean);
    procedure ExtTabCtrl1TabCreating(Sender: TObject; var ACaption: string; var Data: TObject; var Allow: Boolean);
    procedure ExtTabCtrl1TabCreated(Sender: TObject);
    procedure ExtTabCtrl1TabChanging(Sender: TObject; OldIndex, NewIndex: Integer; var Allow: Boolean);
    procedure ExtTabCtrl1TabDeleting(Sender: TObject; Index: Integer; var Allow: Boolean);
    procedure ExtTabCtrl1TabDeleted(Sender: TObject);
    procedure cbStyleChange(Sender: TObject);
    procedure cbPosChange(Sender: TObject);

    procedure ExtTabCtrl1TabClick(Sender: TObject; Index: Integer);
    procedure ExtTabCtrl1TabDblClick(Sender: TObject; Index: Integer);
    procedure OnAddClick(Sender: TObject);
  private
    procedure Log(const Msg: string);
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  // Set Focus to enable keyboard support testing immediately
  ExtTabCtrl1.TabStop := True;

  // Initial tabs
  ExtTabCtrl1.AddTab('Lazarus');
  ExtTabCtrl1.AddTab('FreePascal');
  ExtTabCtrl1.AddTab('Standalone');

  ExtTabCtrl1.Tabs[0].StripeColor := clRed;
  ExtTabCtrl1.Tabs[1].StripeColor := clGreen;
  ExtTabCtrl1.Tabs[2].StripeColor := clBlue;

  cbStyle.ItemIndex := Integer(ExtTabCtrl1.TabStyle);
  cbPos.ItemIndex := Integer(ExtTabCtrl1.TabPosition);

  ExtTabCtrl1.ShowHint := True;
  ExtTabCtrl1.ButtonHints.AddHint := 'Add a tab';

  Log('Application started. Keyboard support (Arrows) and Tooltips enabled.');
end;

procedure TForm1.Log(const Msg: string);
begin
  if Assigned(MemoLog) then
    MemoLog.Lines.Add(FormatDateTime('hh:nn:ss.zzz', Now) + ' > ' + Msg);
end;

procedure TForm1.ExtTabCtrl1TabClick(Sender: TObject; Index: Integer);
begin
  Log('Single Click on Tab Index: ' + IntToStr(Index) + ' (' + ExtTabCtrl1.Tabs[Index].Caption + ')');
end;

procedure TForm1.ExtTabCtrl1TabDblClick(Sender: TObject; Index: Integer);
begin
  Log('Double Click on Tab Index: ' + IntToStr(Index) + ' (' + ExtTabCtrl1.Tabs[Index].Caption + ')');
  // Example action: Rename on double click
  ExtTabCtrl1.Tabs[Index].Caption := InputBox('Rename Tab', 'New name:', ExtTabCtrl1.Tabs[Index].Caption);
end;

procedure TForm1.OnAddClick(Sender: TObject);
begin
  ExtTabCtrl1.AddTab('New Tab ' + IntToStr(ExtTabCtrl1.Tabs.Count + 1));
end;

procedure TForm1.ExtTabCtrl1TabCreating(Sender: TObject; var ACaption: string; var Data: TObject; var Allow: Boolean);
var
  NewName: string;
begin
  NewName := InputBox('New Tab', 'Enter tab name:', ACaption);
  if NewName <> '' then
  begin
    ACaption := NewName;
    Allow := True;
    Log('Creating tab: ' + ACaption);
  end
  else
    Allow := False;
end;

procedure TForm1.ExtTabCtrl1TabCreated(Sender: TObject);
begin
  Log('Tab created successfully.');
end;

procedure TForm1.ExtTabCtrl1TabChanging(Sender: TObject; OldIndex, NewIndex: Integer; var Allow: Boolean);
begin
  Log(Format('Changing from index %d to %d', [OldIndex, NewIndex]));
  Allow := True;
end;

procedure TForm1.ExtTabCtrl1TabChanged(Sender: TObject; NewIndex: Integer);
begin
  if (NewIndex >= 0) and (NewIndex < ExtTabCtrl1.Tabs.Count) then
    Log('Active tab is now: ' + ExtTabCtrl1.Tabs[NewIndex].Caption);
end;

procedure TForm1.ExtTabCtrl1TabDeleting(Sender: TObject; Index: Integer; var Allow: Boolean);
var
  TabName: string;
begin
  TabName := ExtTabCtrl1.Tabs[Index].Caption;
  Allow := MessageDlg('Confirm', 'Close "' + TabName + '"?', mtConfirmation, [mbYes, mbNo], 0) = mrYes;
  if Allow then
    Log('Deleting tab: ' + TabName);
end;

procedure TForm1.ExtTabCtrl1TabDeleted(Sender: TObject);
begin
  Log('Tab deleted.');
end;

procedure TForm1.cbStyleChange(Sender: TObject);
begin
  if (cbStyle.ItemIndex >= 0) and (cbStyle.ItemIndex <= Ord(etsMacOS)) then
    ExtTabCtrl1.TabStyle := TExtTabStyle(cbStyle.ItemIndex)
  else
    ExtTabCtrl1.Invalidate;
end;

procedure TForm1.cbPosChange(Sender: TObject);
begin
  ExtTabCtrl1.BeginUpdate;
  try
    ExtTabCtrl1.TabPosition := TExtTabPosition(cbPos.ItemIndex);
    case ExtTabCtrl1.TabPosition of
      etpTop:  ExtTabCtrl1.Align := alTop;
      etpBottom: ExtTabCtrl1.Align := alBottom;
      etpLeft: ExtTabCtrl1.Align := alLeft;
      etpRight: ExtTabCtrl1.Align := alRight;
    end;
  finally
    ExtTabCtrl1.EndUpdate;
  end;
end;

procedure TForm1.ExtTabCtrl1TabReordering(Sender: TObject; OldIndex, NewIndex: Integer; var Allow: Boolean);
var
  Msg: string;
begin
  Msg := Format('Are you sure you want to move this tab from position %d to %d?',
                [OldIndex + 1, NewIndex + 1]); // +1 makes it human-readable (1-based)

  Allow := MessageDlg('Confirm Reorder', Msg, mtConfirmation, [mbYes, mbNo], 0) = mrYes;
  if Allow then
    Log(Format('User confirmed: Tab moved from %d to %d', [OldIndex, NewIndex]))
  else
    Log(Format('User cancelled: Reorder from %d to %d blocked', [OldIndex, NewIndex]));
end;

procedure TForm1.ExtTabCtrl1TabReordered(Sender: TObject; OldIndex, NewIndex: Integer);
begin
  Log(Format('Tab moved from %d to %d', [OldIndex + 1, NewIndex + 1]));
end;

procedure TForm1.ExtTabCtrl1ImportTab(Sender: TObject; Tab: TExtTab; AObject: TObject);
var
  Ptr: Pointer;
begin
  Ptr := Pointer(AObject);
  if PtrUInt(Ptr) < $FFFF then
  begin
    Tab.Value := IntToStr(PtrUInt(Ptr));
    Log(Format('New tab imported, containing an integer (%s)', [Tab.Value]))
  end
  else
  begin
    Tab.Data := AObject;
    Log('New tab imported, containing an object')
  end;
end;

procedure TForm1.ExtTabCtrl1DrawTab(Sender: TObject; ACanvas: TCanvas; ARect: TRect;
  IsActive, IsHover: Boolean; var Options: TExtTabStyleOptions; var Skip: Boolean);
const
  // XP-style palette
  ClrActiveBase   = $0030AD39; // active tab: green
  ClrInactiveBase = $00D28E25; // inactive tab: blue
  ClrHoverBase    = $00F0A030; // inactive tab, hovered: lighter blue
  ClrShadow       = $00804000; // dark edge shadow
var
  Horizontal: Boolean;
  BaseClr, OuterClr, InnerClr, GlowClr: TColor;
  StartClr, StopClr: TColor;

  // Simple linear blend between two colours (Ratio 0 = C1, 1 = C2)
  function Blend(C1, C2: TColor; Ratio: Single): TColor;
  var
    R1, G1, B1, R2, G2, B2: Byte;
  begin
    C1 := ColorToRGB(C1);
    C2 := ColorToRGB(C2);
    R1 := GetRValue(C1); G1 := GetGValue(C1); B1 := GetBValue(C1);
    R2 := GetRValue(C2); G2 := GetGValue(C2); B2 := GetBValue(C2);
    Result := RGB(Round(R1*(1 - Ratio) + R2*Ratio),
                  Round(G1*(1 - Ratio) + G2*Ratio),
                  Round(B1*(1 - Ratio) + B2*Ratio));
  end;

begin
  if cbStyle.ItemIndex <= Ord(etsMacOS) then Exit;

  // tpTop/tpBottom -> wide tabs, gradient runs top-to-bottom.
  // tpLeft/tpRight -> tall tabs, gradient runs left-to-right.
  Horizontal := (Sender as TExtTabCtrl).IsHorizontal;

  // Pick the base color for this state
  if IsActive then
    BaseClr := ClrActiveBase
  else if IsHover then
    BaseClr := ClrHoverBase
  else
    BaseClr := ClrInactiveBase;

  OuterClr := Blend(BaseClr, clWhite, 0.35); // glossy highlight
  InnerClr := Blend(BaseClr, clBlack, 0.10); // slightly deeper base tone

  if IsActive then
  begin
    StartClr := InnerClr;
    StopClr  := Blend(BaseClr, clWhite, 0.20);
  end
  else
  begin
    StartClr := OuterClr;
    StopClr  := InnerClr;
  end;

  ACanvas.Brush.Style := bsSolid;
  if Horizontal then
    ACanvas.GradientFill(ARect, StartClr, StopClr, gdVertical)
  else
    ACanvas.GradientFill(ARect, StartClr, StopClr, gdHorizontal);

  // 3D bevel with a consistent top-left light source
  // Raised tabs get highlight on Top+Left and shadow on Bottom+Right
  // The active tab is pressed in, so the bevel is inverted
  if IsActive then
  begin
    ACanvas.Pen.Color := ClrShadow;
    ACanvas.Line(ARect.Left, ARect.Top, ARect.Right, ARect.Top);
    ACanvas.Line(ARect.Left, ARect.Top, ARect.Left, ARect.Bottom);

    ACanvas.Pen.Color := Blend(BaseClr, clWhite, 0.5);
    ACanvas.Line(ARect.Right - 1, ARect.Top, ARect.Right - 1, ARect.Bottom);
    ACanvas.Line(ARect.Left, ARect.Bottom - 1, ARect.Right, ARect.Bottom - 1);

    GlowClr := Blend(BaseClr, clWhite, 0.6);
    ACanvas.Pen.Color := GlowClr;
    ACanvas.Frame(ARect.Left, ARect.Top, ARect.Right - 1, ARect.Bottom - 1);
  end
  else
  begin
    ACanvas.Pen.Color := clWhite;
    ACanvas.Line(ARect.Left, ARect.Top, ARect.Right, ARect.Top);
    ACanvas.Line(ARect.Left, ARect.Top, ARect.Left, ARect.Bottom);

    ACanvas.Pen.Color := ClrShadow;
    ACanvas.Line(ARect.Right - 1, ARect.Top, ARect.Right - 1, ARect.Bottom);
    ACanvas.Line(ARect.Left, ARect.Bottom - 1, ARect.Right, ARect.Bottom - 1);
  end;

  // XP taskbar buttons use white text in every state
  Options.FontColor := clWhite;
  Options.Indent := 2;
  Options.ShowStripLine := True;
  Skip := False;
end;

procedure TForm1.ExtTabCtrl1DrawButton(Sender: TObject; ACanvas: TCanvas;
  ARect: TRect; AButtonType: TExtButtonType; ATab: TExtTab; IsActive, IsHover: Boolean;
  var Skip: Boolean);
var
  CX, CY, D: Integer;
  IsVert: Boolean;
  FGColor: TColor;
  BgColor: TColor;
  Pts: array[0..2] of TPoint;
  APosition: TExtTabPosition;
begin
  APosition := (Sender as TExtTabCtrl).TabPosition;

  CX := (ARect.Left + ARect.Right) div 2;
  CY := (ARect.Top + ARect.Bottom) div 2;

  // Leave a 3-pixel margin on each side so the icon never touches the edge
  D := (Min(ARect.Width, ARect.Height) div 2) - 3;
  if D < 2 then D := 2;

  // tpLeft / tpRight means the strip runs top-to-bottom; arrows flip 90°
  IsVert := APosition in [etpLeft, etpRight];

  // Colors
  if IsHover then
  begin
    FGColor := clHighlightText;
    BgColor := clHighlight;
  end
  else
  begin
    FGColor := clBtnText;
    BgColor := clBtnFace;   // used only for the close-button hover circle
  end;

  // Per-button drawing
  ACanvas.Pen.Style  := psSolid;
  ACanvas.Brush.Style := bsSolid;

  case AButtonType of
    // Close "x"
    ebtClose: begin
      if not chbCustomCloseButtons.Checked then
      begin
        Skip := True;
        Exit;
      end;

      // Subtle filled circle on hover so the X has a visual target
      if IsHover then
      begin
        ACanvas.Brush.Color := BgColor;
        ACanvas.Pen.Color := BgColor;
        ACanvas.Pen.Width := 1;
        ACanvas.Ellipse(ARect.Left + 1, ARect.Top + 1, ARect.Right - 1, ARect.Bottom - 1);
      end;

      // Two crossing lines form the X
      ACanvas.Pen.Color := FGColor;
      ACanvas.Pen.Width := 2;
      {$IFDEF LCLCocoa}
      ACanvas.Line(CX - D, CY - D, CX + D + 1, CY + D + 1);
      ACanvas.Line(CX + D, CY - D, CX - D - 1, CY + D + 1);
      {$ELSE}
      ACanvas.Line(CX - D, CY - D, CX + D, CY + D);
      ACanvas.Line(CX + D, CY - D, CX - D, CY + D);
      {$ENDIF}

      Skip := False;
    end;

    // Add "+"
    ebtAdd: begin
      if not chbCustomAddButton.Checked then
      begin
        Skip := True;
        Exit;
      end;

      ACanvas.Pen.Color := FGColor;
      ACanvas.Pen.Width := 3;

      {$IFDEF LCLCocoa}
      ACanvas.Line(CX - D, CY, CX + D + 1, CY);
      ACanvas.Line(CX, CY - D, CX, CY + D + 1);
      {$ELSE}
      ACanvas.Line(CX - D, CY, CX + D, CY);
      ACanvas.Line(CX, CY - D, CX, CY + D);
      {$ENDIF}

      Skip := False;
    end;

    // Scroll prev (left / up)
    ebtPrev: begin
      if not chbCustomScrollButtons.Checked then
      begin
        Skip := True;
        Exit;
      end;

      ACanvas.Pen.Color := FGColor;
      ACanvas.Pen.Width := 1;
      ACanvas.Brush.Color := FGColor;

      if not IsVert then
      begin
        // Left-pointing triangle
        Pts[0] := Point(CX - D, CY);
        Pts[1] := Point(CX + D, CY - D);
        Pts[2] := Point(CX + D, CY + D);
      end
      else
      begin
        // Up-pointing triangle
        Pts[0] := Point(CX, CY - D);
        Pts[1] := Point(CX + D, CY + D);
        Pts[2] := Point(CX - D, CY + D);
      end;
      ACanvas.Polygon(Pts);

      Skip := False;
    end;

    // Scroll next (right / down)
    ebtNext: begin
      if not chbCustomScrollButtons.Checked then
      begin
        Skip := True;
        Exit;
      end;

      ACanvas.Pen.Color := FGColor;
      ACanvas.Pen.Width := 1;
      ACanvas.Brush.Color := FGColor;

      if not IsVert then
      begin
        // Right-pointing triangle
        Pts[0] := Point(CX + D, CY);
        Pts[1] := Point(CX - D, CY - D);
        Pts[2] := Point(CX - D, CY + D);
      end
      else
      begin
        // Down-pointing triangle
        Pts[0] := Point(CX, CY + D);
        Pts[1] := Point(CX - D, CY - D);
        Pts[2] := Point(CX + D, CY - D);
      end;
      ACanvas.Polygon(Pts);

      Skip := False;
    end;
  end; // case
end;

procedure TForm1.chbCustomButtonChange(Sender: TObject);
begin
  ExtTabCtrl1.Invalidate;
end;

end.
