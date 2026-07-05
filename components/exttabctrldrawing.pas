unit ExtTabCtrlDrawing;

{$mode objfpc}{$H+}

interface

uses
  Classes, Graphics, Types, Math, GraphUtil, LCLIntf, IntfGraphics;

type
  TExtTabPosition = (etpTop, etpBottom, etpLeft, etpRight);

  TExtTabStyle = (etsFlat, etsButton, etsDelphi, etsChrome, etsMacOS);

  { TExtTabStyleOptions }
  // Options to configure the styles
  TExtTabStyleOptions = record
    FontColor: TColor;
    Indent: Integer;
    ShowStripLine: Boolean;
  end;

  TExtTabResolveColorFunc = function(AColor: TColor): TColor of object;
  TExtTabGetScaleFunc = function(AValue: Integer): Integer of object;

  // Everything a style drawer needs
  TExtTabDrawContext = record
    TabColor: TColor;
    TabStripeColor: TColor;
    IsHoverTab: Boolean;
    IsBeforeActiveTab: Boolean;   // This tab immediately precedes the active one
    IsLastTab: Boolean;
    BackgroundColor: TColor;      // Control's own Color, unresolved
    BorderColor: TColor;
    TabPosition: TExtTabPosition;
    IsHorizontal: Boolean;
    ActiveFontColor: TColor;
    InactiveFontColor: TColor;
    ResolveColor: TExtTabResolveColorFunc;
    GetScale: TExtTabGetScaleFunc;
  end;

  TExtPenState = record
    Color: TColor;
    Width: Integer;
    Style: TPenStyle;
    BrushColor: TColor;
    BrushStyle: TBrushStyle;
  end;

const
  // Scroll-arrow (prev/next) glyph colors
  cScrollGlyphColorLight = $009E4320;
  cScrollGlyphColorDark  = $00F79A6D;
  // Add (+) glyph colors
  cAddGlyphColorLight = $00146E20;
  cAddGlyphColorDark  = $005CD66A;
  // Close (x) glyph colors
  cCloseGlyphColorNormal = $004040CC;
  cCloseGlyphColorHover  = clRed;

// Helpers
procedure SwapIntegers(var A, B: Integer);
// Linear blend between two colors (Ratio=0 -> C1, Ratio=1 -> C2)
function BlendColors(C1, C2: TColor; Ratio: Single): TColor;
function SavePen(ACanvas: TCanvas): TExtPenState;
procedure RestorePen(ACanvas: TCanvas; const State: TExtPenState);
function IsDarkMode: Boolean;
procedure RotateImage(Img: TCustomBitmap; Degrees: Integer);

procedure DrawBtnScroll(ACanvas: TCanvas; ARect: TRect; ANext, AHorizontal: Boolean);
procedure DrawBtnAdd(ACanvas: TCanvas; ARect: TRect);
procedure DrawBtnClose(ACanvas: TCanvas; ARect: TRect; IsHover: Boolean);


// Style drawing methods
procedure DrawFlatTabStyle(ACanvas: TCanvas; var R: TRect; IsActive: Boolean;
  const Ctx: TExtTabDrawContext; var Options: TExtTabStyleOptions);
procedure DrawButtonTabStyle(ACanvas: TCanvas; var R: TRect; IsActive: Boolean;
  const Ctx: TExtTabDrawContext; var Options: TExtTabStyleOptions);
procedure DrawDelphiTabStyle(ACanvas: TCanvas; var R: TRect; IsActive: Boolean;
  const Ctx: TExtTabDrawContext; var Options: TExtTabStyleOptions);
procedure DrawChromeTabStyle(ACanvas: TCanvas; var R: TRect; IsActive: Boolean;
  const Ctx: TExtTabDrawContext; var Options: TExtTabStyleOptions);
procedure DrawMacOSTabStyle(ACanvas: TCanvas; var R: TRect; IsActive: Boolean;
  const Ctx: TExtTabDrawContext; var Options: TExtTabStyleOptions);

// Draws the folder-tab separator line along the inner edge of the tab strip
procedure DrawStripLineStyle(ACanvas: TCanvas; const View: TRect; const Ctx: TExtTabDrawContext;
  const Options: TExtTabStyleOptions; AClientWidth, AClientHeight: Integer);

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
  C1 := ColorToRGB(C1); C2 := ColorToRGB(C2);
  R1 := GetRValue(C1); G1 := GetGValue(C1); B1 := GetBValue(C1);
  R2 := GetRValue(C2); G2 := GetGValue(C2); B2 := GetBValue(C2);
  Result := RGB(Round(R1*(1 - Ratio) + R2*Ratio),
                Round(G1*(1 - Ratio) + G2*Ratio),
                Round(B1*(1 - Ratio) + B2*Ratio));
end;

function SavePen(ACanvas: TCanvas): TExtPenState;
begin
  Result.Color := ACanvas.Pen.Color;
  Result.Width := ACanvas.Pen.Width;
  Result.Style := ACanvas.Pen.Style;
  Result.BrushColor := ACanvas.Brush.Color;
  Result.BrushStyle := ACanvas.Brush.Style;
end;

procedure RestorePen(ACanvas: TCanvas; const State: TExtPenState);
begin
  ACanvas.Pen.Color := State.Color;
  ACanvas.Pen.Width := State.Width;
  ACanvas.Pen.Style := State.Style;
  ACanvas.Brush.Color := State.BrushColor;
  ACanvas.Brush.Style := State.BrushStyle;
end;

function IsDarkMode: Boolean;
var
  bkClr, txtClr: TColor;
begin
  bkClr := ColorToRGB(clWindow);
  txtClr := ColorToRGB(clWindowText);
  Result := ColorToGray(txtClr) > ColorToGray(bkClr);
end;

// Degrees are counter-clockwise
procedure RotateImage(Img: TCustomBitmap; Degrees: Integer);
var
  SrcIntf, DestIntf: TLazIntfImage;
  x, y, BPP: Integer;
  SrcPtr, DestPtr: PByte;
  SrcW, SrcH, DestW, DestH: Integer;
  SrcRows, DestRows: array of PByte;
begin
  if Img.Empty or not ((Degrees = 90) or (Degrees = 180) or (Degrees = 270)) then Exit;
  SrcIntf := Img.CreateIntfImage;
  DestIntf := TLazIntfImage.Create(0, 0);
  try
    DestIntf.DataDescription := SrcIntf.DataDescription;
    SrcW := SrcIntf.Width;
    SrcH := SrcIntf.Height;
    if (Degrees = 90) or (Degrees = 270) then
      DestIntf.SetSize(SrcH, SrcW)
    else
      DestIntf.SetSize(SrcW, SrcH);
    DestW := DestIntf.Width;
    DestH := DestIntf.Height;
    BPP := SrcIntf.DataDescription.BitsPerPixel div 8;

    // Direct memory copy for byte-aligned 24/32-bit formats
    if (SrcIntf.DataDescription.BitsPerPixel mod 8 = 0) and (BPP in [3, 4]) then
    begin
      SetLength(SrcRows, SrcH);
      for y := 0 to SrcH - 1 do
        SrcRows[y] := SrcIntf.GetDataLineStart(y);
      SetLength(DestRows, DestH);
      for y := 0 to DestH - 1 do
        DestRows[y] := DestIntf.GetDataLineStart(y);

      case Degrees of
        270: // 90° clockwise: src(x,y) --> dest(row=x, col=DestW-1-y)
          for x := 0 to SrcW - 1 do
          begin
            DestPtr := DestRows[x] + (DestW - 1) * BPP;
            for y := 0 to SrcH - 1 do
            begin
              Move((SrcRows[y] + x * BPP)^, DestPtr^, BPP);
              Dec(DestPtr, BPP);
            end;
          end;
        180: // src(x,y) --> dest(row=DestH-1-y, col=DestW-1-x)
          for y := 0 to SrcH - 1 do
          begin
            SrcPtr := SrcRows[y];
            DestPtr := DestRows[DestH - 1 - y] + (DestW - 1) * BPP;
            for x := 0 to SrcW - 1 do
            begin
              Move(SrcPtr^, DestPtr^, BPP);
              Inc(SrcPtr, BPP);
              Dec(DestPtr, BPP);
            end;
          end;
        90: // 270° clockwise (= 90° CCW): src(x,y) --> dest(row=DestH-1-x, col=y)
          for x := 0 to SrcW - 1 do
          begin
            DestPtr := DestRows[DestH - 1 - x];
            for y := 0 to SrcH - 1 do
            begin
              Move((SrcRows[y] + x * BPP)^, DestPtr^, BPP);
              Inc(DestPtr, BPP);
            end;
          end;
      end;
    end
    else
    begin
      // Safe (but slower) rotation for 1/4/8-bit etc
      case Degrees of
        270:
          for y := 0 to SrcH - 1 do
            for x := 0 to SrcW - 1 do
              DestIntf.Colors[SrcH - 1 - y, x] := SrcIntf.Colors[x, y];
        180:
          for y := 0 to SrcH - 1 do
            for x := 0 to SrcW - 1 do
              DestIntf.Colors[SrcW - 1 - x, SrcH - 1 - y] := SrcIntf.Colors[x, y];
        90:
          for y := 0 to SrcH - 1 do
            for x := 0 to SrcW - 1 do
              DestIntf.Colors[y, SrcW - 1 - x] := SrcIntf.Colors[x, y];
      end;
    end;
    Img.LoadFromIntfImage(DestIntf);
  finally
    SrcIntf.Free;
    DestIntf.Free;
  end;
end;

// Vector icon helpers
// Each helper draws into a TBitmap that is already the correct size

procedure DrawBtnScroll(ACanvas: TCanvas; ARect: TRect; ANext, AHorizontal: Boolean);
var
  ASize, CX, CY, R: Integer;
  P: array[0..2] of TPoint;
  SavedPen: TExtPenState;
begin
  SavedPen := SavePen(ACanvas);

  try
    CX := ARect.Width div 2;
    CY := ARect.Height div 2;
    ASize := Min(ARect.Width, ARect.Height);

    // R determines the scale of the triangle
    R := Max(4, 2*ASize div 5);

    // Mathematically precise 45-degree slope assignments
    if AHorizontal then
    begin
      if ANext then begin // Pointing Right
        P[0] := Point(CX - (R div 2), CY - R);
        P[1] := Point(CX + (R div 2), CY);
        P[2] := Point(CX - (R div 2), CY + R);
      end
      else
      begin // Pointing Left
        P[0] := Point(CX + (R div 2), CY - R);
        P[1] := Point(CX - (R div 2), CY);
        P[2] := Point(CX + (R div 2), CY + R);
      end;
    end
    else
    begin
      if ANext then begin // Pointing Down
        P[0] := Point(CX - R, CY - (R div 2));
        P[1] := Point(CX + R, CY - (R div 2));
        P[2] := Point(CX, CY + (R div 2));
      end
      else
      begin // Pointing Up
        P[0] := Point(CX - R, CY + (R div 2));
        P[1] := Point(CX + R, CY + (R div 2));
        P[2] := Point(CX, CY - (R div 2));
      end;
    end;

    ACanvas.Pen.Color := IfThen(IsDarkMode, cScrollGlyphColorDark, cScrollGlyphColorLight);
    ACanvas.Pen.Width := 1;
    ACanvas.Pen.Style := psSolid;
    ACanvas.Brush.Color := IfThen(IsDarkMode, cScrollGlyphColorLight, cScrollGlyphColorDark);
    ACanvas.Brush.Style := bsSolid;

    ACanvas.Polygon(P);
  finally
    // Restore the original Pen state
    RestorePen(ACanvas, SavedPen);
  end;
end;

procedure DrawBtnAdd(ACanvas: TCanvas; ARect: TRect);
var
  ASize, CX, CY, L, W: Integer;
  P: array[0..11] of TPoint;
  SavedPen: TExtPenState;
begin
  SavedPen := SavePen(ACanvas);

  try
    CX := ARect.Width div 2;
    CY := ARect.Height div 2;

    ASize := Min(ARect.Width, ARect.Height);

    // L = Length of the cross arms from center
    L := 2*ASize div 5;
    // W = Half-thickness of the cross arms (Total thickness will be W*2)
    W := Max(2, ASize div 8);

    // Plot out a thick, symmetrical 12-pointed cross clockwise
    P[0] := Point(CX - W, CY - L);  // Top arm, top-left
    P[1] := Point(CX + W, CY - L);  // Top arm, top-right
    P[2] := Point(CX + W, CY - W);  // Inner corner top-right
    P[3] := Point(CX + L, CY - W);  // Right arm, top-left
    P[4] := Point(CX + L, CY + W);  // Right arm, bottom-left
    P[5] := Point(CX + W, CY + W);  // Inner corner bottom-right
    P[6] := Point(CX + W, CY + L);  // Bottom arm, bottom-right
    P[7] := Point(CX - W, CY + L);  // Bottom arm, bottom-left
    P[8] := Point(CX - W, CY + W);  // Inner corner bottom-left
    P[9] := Point(CX - L, CY + W);  // Left arm, bottom-right
    P[10] := Point(CX - L, CY - W); // Left arm, top-right
    P[11] := Point(CX - W, CY - W); // Inner corner top-left

    ACanvas.Pen.Color := IfThen(IsDarkMode, cAddGlyphColorDark, cAddGlyphColorLight);
    ACanvas.Pen.Width := 1;
    ACanvas.Pen.Style := psSolid;
    ACanvas.Brush.Color := IfThen(IsDarkMode, cAddGlyphColorLight, cAddGlyphColorDark);
    ACanvas.Brush.Style := bsSolid;

    ACanvas.Polygon(P);
  finally
    // Restore the original Pen state
    RestorePen(ACanvas, SavedPen);
  end;
end;

procedure DrawBtnClose(ACanvas: TCanvas; ARect: TRect; IsHover: Boolean);
var
  P: array[0..11] of TPoint;
  D, H, CX, CY: Integer;
  XClr: TColor;
  SavedPen: TExtPenState;
begin
  SavedPen := SavePen(ACanvas);

  try
    CX := ARect.Left + ARect.Width div 2;
    CY := ARect.Top + ARect.Height div 2;
    D := Max(3, (Min(ARect.Width, ARect.Height) - 2) div 3);  // reach from centre
    H := Max(1, D div 3);   // arm half-thickness

    XClr := IfThen(IsHover, cCloseGlyphColorHover, TColor(cCloseGlyphColorNormal));

    // First arm: top-left --> bottom-right (12 vertices, clock-wise)
    P[ 0] := Point(CX - D, CY - D + H);   // left arm, top-left
    P[ 1] := Point(CX - D + H, CY - D);   // left arm, top-right
    P[ 2] := Point(CX, CY - H);           // centre top-right notch
    P[ 3] := Point(CX + D - H, CY - D);   // right arm, top-left
    P[ 4] := Point(CX + D, CY - D + H);   // right arm, top-right
    P[ 5] := Point(CX + H, CY);           // centre right notch
    P[ 6] := Point(CX + D, CY + D - H);   // right arm, bottom-right
    P[ 7] := Point(CX + D - H, CY + D);   // right arm, bottom-left
    P[ 8] := Point(CX, CY + H);           // centre bottom-left notch
    P[ 9] := Point(CX - D + H, CY + D);   // left arm, bottom-right
    P[10] := Point(CX - D, CY + D - H);   // left arm, bottom-left
    P[11] := Point(CX - H, CY);           // centre left notch

    ACanvas.Brush.Color := XClr;
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Pen.Color := XClr;
    ACanvas.Pen.Width := 1;
    ACanvas.Pen.Style := psSolid;
    ACanvas.Polygon(P);
  finally
    // Restore the original Pen state
    RestorePen(ACanvas, SavedPen);
  end;
end;

// End vector icon helpers

{ Style drawers }

procedure DrawFlatTabStyle(ACanvas: TCanvas; var R: TRect; IsActive: Boolean;
  const Ctx: TExtTabDrawContext; var Options: TExtTabStyleOptions);
var
  P: array[0..3] of TPoint;
  BaseClr: TColor;
begin
  Options.FontColor := IfThen(IsActive, Ctx.ActiveFontColor, Ctx.InactiveFontColor);
  Options.Indent := Ctx.GetScale(2);
  Options.ShowStripLine := True;

  // Draw Background
  if IsActive then
  begin
    if Ctx.IsHoverTab then
      ACanvas.Brush.Color := BlendColors(Ctx.ResolveColor(Ctx.BackgroundColor), clHighlight, 0.3)
    else
      ACanvas.Brush.Color := Ctx.BackgroundColor;
  end
  else
  begin
    if (Ctx.TabColor <> clNone) then
      BaseClr := Ctx.ResolveColor(Ctx.TabColor)
    else
      BaseClr := clBtnFace;

    if Ctx.IsHoverTab then
      ACanvas.Brush.Color := BlendColors(BaseClr, clHighlight, 0.2)
    else
      ACanvas.Brush.Color := BaseClr;
  end;
  ACanvas.Brush.Style := bsSolid;
  ACanvas.FillRect(R);

  // Border Logic
  ACanvas.Pen.Color := Ctx.BorderColor;
  case Ctx.TabPosition of
    etpTop: begin
      P[0] := Point(R.Left, R.Bottom - 1);
      P[1] := Point(R.Left, R.Top);
      P[2] := Point(R.Right - 1, R.Top);
      P[3] := Point(R.Right - 1, R.Bottom - 1);
    end;
    etpBottom: begin
      P[0] := Point(R.Left, R.Top);
      P[1] := Point(R.Left, R.Bottom - 1);
      P[2] := Point(R.Right - 1, R.Bottom - 1);
      P[3] := Point(R.Right - 1, R.Top);
    end;
    etpLeft: begin
      P[0] := Point(R.Right - 1, R.Top);
      P[1] := Point(R.Left, R.Top);
      P[2] := Point(R.Left, R.Bottom - 1);
      P[3] := Point(R.Right - 1, R.Bottom - 1);
    end;
    etpRight: begin
      P[0] := Point(R.Left, R.Top);
      P[1] := Point(R.Right - 1, R.Top);
      P[2] := Point(R.Right - 1, R.Bottom - 1);
      P[3] := Point(R.Left, R.Bottom - 1);
    end;
  end;

  if IsActive then ACanvas.Polyline(P) else ACanvas.Polygon(P);
end;

procedure DrawButtonTabStyle(ACanvas: TCanvas; var R: TRect; IsActive: Boolean;
  const Ctx: TExtTabDrawContext; var Options: TExtTabStyleOptions);
var
  BaseClr, LightClr, ShadowClr, BackClr: TColor;
begin
  Options.FontColor := IfThen(IsActive, Ctx.ActiveFontColor, Ctx.InactiveFontColor);
  Options.Indent := Ctx.GetScale(2);
  Options.ShowStripLine := True;

  if (Ctx.TabColor <> clNone) then
  begin
    BaseClr := Ctx.ResolveColor(Ctx.TabColor);
    LightClr := BlendColors(BaseClr, clWhite, 0.4);
    ShadowClr := BlendColors(BaseClr, clBlack, 0.4);
  end
  else
  begin
    BaseClr := clBtnFace;
    LightClr := clBtnHighlight;
    ShadowClr := clBtnShadow;
  end;

  // Determine and Draw Background
  if IsActive then
  begin
    if Ctx.IsHoverTab then
      BackClr := BlendColors(BaseClr, clHighlight, 0.15)
    else
      BackClr := BlendColors(BaseClr, clBlack, 0.05);
  end
  else if Ctx.IsHoverTab then
    BackClr := BlendColors(BaseClr, clHighlight, 0.3)
  else
    BackClr := BaseClr;

  ACanvas.Brush.Color := BackClr;
  ACanvas.Brush.Style := bsSolid;
  ACanvas.FillRect(R);

  // Draw 3D Frame
  if IsActive then
  begin
    // Inverted 3D frame (Shadow on Top/Left, Light on Bottom/Right)
    ACanvas.Pen.Color := ShadowClr;
    ACanvas.Polyline([Point(R.Left, R.Bottom - 1), Point(R.Left, R.Top), Point(R.Right - 1, R.Top)]);
    ACanvas.Pen.Color := LightClr;
    ACanvas.Polyline([Point(R.Right - 1, R.Top), Point(R.Right - 1, R.Bottom - 1), Point(R.Left, R.Bottom - 1)]);

    // Adjust Content Position for "Pressed" effect
    Types.OffsetRect(R, Ctx.GetScale(1), Ctx.GetScale(1));
  end
  else
  begin
    // Standard 3D frame (Light on Top/Left, Shadow on Bottom/Right)
    ACanvas.Pen.Color := LightClr;
    ACanvas.Polyline([Point(R.Left, R.Bottom - 1), Point(R.Left, R.Top), Point(R.Right - 1, R.Top)]);
    ACanvas.Pen.Color := ShadowClr;
    ACanvas.Polyline([Point(R.Right - 1, R.Top), Point(R.Right - 1, R.Bottom - 1), Point(R.Left, R.Bottom - 1)]);
  end;
end;

procedure DrawDelphiTabStyle(ACanvas: TCanvas; var R: TRect; IsActive: Boolean;
  const Ctx: TExtTabDrawContext; var Options: TExtTabStyleOptions);
var
  P: array[0..3] of TPoint;
  S: Integer;
  BaseClr: TColor;
begin
  Options.FontColor := IfThen(IsActive, Ctx.ActiveFontColor, Ctx.InactiveFontColor);
  Options.Indent := Ctx.GetScale(4);
  Options.ShowStripLine := True;

  S := Ctx.GetScale(3); // Angle slant amount

  // Set Colors and draw background
  if IsActive then
  begin
    if Ctx.IsHoverTab then
      ACanvas.Brush.Color := BlendColors(Ctx.ResolveColor(Ctx.BackgroundColor), clHighlight, 0.3)
    else
      ACanvas.Brush.Color := Ctx.BackgroundColor;
  end
  else
  begin
    if (Ctx.TabColor <> clNone) then
      BaseClr := Ctx.ResolveColor(Ctx.TabColor)
    else
      BaseClr := clBtnFace;

    if Ctx.IsHoverTab then
      ACanvas.Brush.Color := BlendColors(BaseClr, clHighlight, 0.2)
    else
      ACanvas.Brush.Color := BaseClr;
  end;

  ACanvas.Pen.Color := Ctx.BorderColor;
  ACanvas.Brush.Style := bsSolid;

  // Define Polygon Points for the tab body
  case Ctx.TabPosition of
    etpTop: begin
      P[0] := Point(R.Left, R.Bottom);
      P[1] := Point(R.Left + S, R.Top);
      P[2] := Point(R.Right - 1 - S, R.Top);
      P[3] := Point(R.Right - 1, R.Bottom);
    end;
    etpBottom: begin
      P[0] := Point(R.Left, R.Top);
      P[1] := Point(R.Left + S, R.Bottom - 1);
      P[2] := Point(R.Right - 1 - S, R.Bottom - 1);
      P[3] := Point(R.Right - 1, R.Top);
    end;
    etpLeft: begin
      P[0] := Point(R.Right, R.Top);
      P[1] := Point(R.Left, R.Top + S);
      P[2] := Point(R.Left, R.Bottom - 1 - S);
      P[3] := Point(R.Right, R.Bottom - 1);
    end;
    etpRight: begin
      P[0] := Point(R.Left, R.Top);
      P[1] := Point(R.Right - 1, R.Top + S);
      P[2] := Point(R.Right - 1, R.Bottom - 1 - S);
      P[3] := Point(R.Left, R.Bottom - 1);
    end;
  end;

  if IsActive then
  begin
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Polygon(P);
    ACanvas.Pen.Color := Ctx.BorderColor;
    ACanvas.Polyline(P);
  end
  else
  begin
    ACanvas.Polygon(P);

    // Draw the shadow line for all the inactive tabs on the side touching the body
    ACanvas.Pen.Color := Ctx.BorderColor;
    case Ctx.TabPosition of
      etpTop: ACanvas.Line(R.Left, R.Bottom - 1, R.Right, R.Bottom - 1);
      etpBottom: ACanvas.Line(R.Left, R.Top, R.Right, R.Top);
      etpLeft: ACanvas.Line(R.Right - 1, R.Top, R.Right - 1, R.Bottom);
      etpRight: ACanvas.Line(R.Left, R.Top, R.Left, R.Bottom);
    end;
  end;
end;

procedure DrawChromeTabStyle(ACanvas: TCanvas; var R: TRect; IsActive: Boolean;
  const Ctx: TExtTabDrawContext; var Options: TExtTabStyleOptions);
var
  Radius: Integer;
  StripeBounds: TRect;
  BaseClr: TColor;
begin
  Options.FontColor := IfThen(IsActive, Ctx.ActiveFontColor, Ctx.InactiveFontColor);
  Options.Indent := Ctx.GetScale(5);
  Options.ShowStripLine := True;

  Radius := Ctx.GetScale(8);

  // Background and hover
  if IsActive then
  begin
    BaseClr := Ctx.ResolveColor(Ctx.BackgroundColor);

    if Ctx.IsHoverTab then
      ACanvas.Brush.Color := BlendColors(BaseClr, clHighlight, 0.2)
    else
      ACanvas.Brush.Color := BaseClr;
    ACanvas.Brush.Style := bsSolid;
  end
  else
  begin
    if (Ctx.TabColor <> clNone) then
      BaseClr := Ctx.ResolveColor(Ctx.TabColor)
    else
      BaseClr := Ctx.ResolveColor(Ctx.BackgroundColor);

    if Ctx.IsHoverTab then
    begin
      // On hover, slide from Tab.Color toward the component background
      // blended with a touch of Highlight
      if Ctx.TabColor <> clNone then
        ACanvas.Brush.Color := BlendColors(BlendColors(Ctx.ResolveColor(Ctx.BackgroundColor), clHighlight, 0.12), BaseClr, 0.25)
      else
        ACanvas.Brush.Color := BlendColors(BaseClr, clHighlight, 0.08);
      ACanvas.Brush.Style := bsSolid;
    end
    else if Ctx.TabColor <> clNone then
    begin
      // At rest: draw with the tab's own color
      ACanvas.Brush.Color := BaseClr;
      ACanvas.Brush.Style := bsSolid;
    end
    else
      ACanvas.Brush.Style := bsClear;
  end;

  // Draw Tab (RoundRect with overlap to square the bottom)
  if IsActive or Ctx.IsHoverTab or (not IsActive and (Ctx.TabColor <> clNone)) then
  begin
    ACanvas.Pen.Color := Ctx.BorderColor;
    case Ctx.TabPosition of
      etpTop:
        ACanvas.RoundRect(R.Left, R.Top, R.Right - 1, R.Bottom + Radius, Radius, Radius);
      etpBottom:
        ACanvas.RoundRect(R.Left, R.Top - Radius, R.Right - 1, R.Bottom, Radius, Radius);
      etpLeft:
        ACanvas.RoundRect(R.Left, R.Top, R.Right + Radius, R.Bottom - 1, Radius, Radius);
      etpRight:
        ACanvas.RoundRect(R.Left - Radius, R.Top, R.Right, R.Bottom - 1, Radius, Radius);
    end;
  end;

  // Draw the shadow line for all but the active tab on the side touching the body
  ACanvas.Pen.Color := IfThen(IsActive, BaseClr, Ctx.BorderColor);
  case Ctx.TabPosition of
    etpTop: ACanvas.Line(R.Left + 1, R.Bottom - 1, R.Right - 1, R.Bottom - 1);
    etpBottom: ACanvas.Line(R.Left + 1, R.Top, R.Right - 1, R.Top);
    etpLeft: ACanvas.Line(R.Right - 1, R.Top + 1, R.Right - 1, R.Bottom - 1);
    etpRight: ACanvas.Line(R.Left, R.Top + 1, R.Left, R.Bottom - 1);
  end;

  // Separators (For inactive non-hovered tabs without their own color border)
  if not IsActive and not Ctx.IsHoverTab and not Ctx.IsBeforeActiveTab and (Ctx.TabColor = clNone) then
  begin
    ACanvas.Pen.Color := Ctx.BorderColor;
    if Ctx.IsHorizontal then
      ACanvas.Line(R.Right - 1, R.Top + Options.Indent, R.Right - 1, R.Bottom - Options.Indent)
    else
      ACanvas.Line(R.Left + Options.Indent, R.Bottom - 1, R.Right - Options.Indent, R.Bottom - 1);
  end;

  // Accent line: use Tab.Color when set, otherwise fall back to clHighlight
  if IsActive and (Ctx.TabStripeColor = clNone) then
  begin
    ACanvas.Pen.Color := IfThen(Ctx.TabColor <> clNone, Ctx.ResolveColor(Ctx.TabColor), clHighlight);
    ACanvas.Pen.Width := Ctx.GetScale(3);

    StripeBounds := R;
    InflateRect(StripeBounds, -Options.Indent, -Options.Indent);

    case Ctx.TabPosition of
      etpTop: ACanvas.Line(StripeBounds.Left, R.Top + 1, StripeBounds.Right, R.Top + 1);
      etpBottom: ACanvas.Line(StripeBounds.Left, R.Bottom - 2, StripeBounds.Right, R.Bottom - 2);
      etpLeft: ACanvas.Line(R.Left + 1, StripeBounds.Top, R.Left + 1, StripeBounds.Bottom);
      etpRight: ACanvas.Line(R.Right - 2, StripeBounds.Top, R.Right - 2, StripeBounds.Bottom);
    end;
    ACanvas.Pen.Width := 1;
  end;
end;

procedure DrawMacOSTabStyle(ACanvas: TCanvas; var R: TRect; IsActive: Boolean;
  const Ctx: TExtTabDrawContext; var Options: TExtTabStyleOptions);
var
  Radius: Integer;
  DrawR: TRect;
  BaseClr: TColor;
begin
  Options.FontColor := IfThen(IsActive, clWindowText, Ctx.InactiveFontColor);
  Options.Indent := Ctx.GetScale(6);
  Options.ShowStripLine := False;

  Radius := Options.Indent;
  DrawR := R;

  // Floating segment effect
  InflateRect(DrawR, -Ctx.GetScale(2), -Ctx.GetScale(2));

  if IsActive then
  begin
    // Active pill: blend component Color with clWindow for the floating look
    if Ctx.TabColor <> clNone then
      BaseClr := BlendColors(Ctx.ResolveColor(Ctx.BackgroundColor), Ctx.ResolveColor(Ctx.TabColor), 0.25)
    else
      BaseClr := Ctx.ResolveColor(Ctx.BackgroundColor);
    if Ctx.IsHoverTab then
      ACanvas.Brush.Color := BlendColors(BlendColors(BaseClr, clWindow, 0.85), clHighlight, 0.2)
    else
      ACanvas.Brush.Color := BlendColors(BaseClr, clWindow, 0.85);
    ACanvas.Pen.Color := BlendColors(BaseClr, clBtnShadow, 0.15);
    ACanvas.RoundRect(DrawR.Left, DrawR.Top, DrawR.Right, DrawR.Bottom, Radius, Radius);
  end
  else
  begin
    if (Ctx.TabColor <> clNone) then
      BaseClr := Ctx.ResolveColor(Ctx.TabColor)
    else
      BaseClr := Ctx.ResolveColor(Ctx.BackgroundColor);

    if Ctx.IsHoverTab then
    begin
      // Hover: blend Tab.Color toward window background
      ACanvas.Brush.Color := BlendColors(BaseClr, clWindow, 0.9);
      ACanvas.Pen.Style := psClear;
      ACanvas.RoundRect(DrawR.Left, DrawR.Top, DrawR.Right, DrawR.Bottom, Radius, Radius);
      ACanvas.Pen.Style := psSolid;
    end
    else if Ctx.TabColor <> clNone then
    begin
      // Non-hover inactive with Tab.Color: draw a subtle tinted pill so the
      // color is visible at rest (more muted than on hover)
      ACanvas.Brush.Color := BlendColors(BaseClr, clWindow, 0.82);
      ACanvas.Pen.Style := psClear;
      ACanvas.RoundRect(DrawR.Left, DrawR.Top, DrawR.Right, DrawR.Bottom, Radius, Radius);
      ACanvas.Pen.Style := psSolid;
    end;

    // Minimalist separators
    if not Ctx.IsLastTab and not Ctx.IsBeforeActiveTab then
    begin
      ACanvas.Pen.Color := BlendColors(Ctx.ResolveColor(Ctx.BackgroundColor), clBlack, 0.05);
      ACanvas.MoveTo(R.Right - 1, R.Top + Ctx.GetScale(7));
      ACanvas.LineTo(R.Right - 1, R.Bottom - Ctx.GetScale(7));
    end;
  end;
end;

procedure DrawStripLineStyle(ACanvas: TCanvas; const View: TRect;
  const Ctx: TExtTabDrawContext; const Options: TExtTabStyleOptions;
  AClientWidth, AClientHeight: Integer);
begin
  if not Options.ShowStripLine then Exit;

  ACanvas.Pen.Color := Ctx.BorderColor;
  ACanvas.Pen.Width := 1;
  ACanvas.Pen.Style := psSolid;

  // Draw the full unbroken line
  case Ctx.TabPosition of
    etpTop: ACanvas.Line(0, View.Bottom - 1, AClientWidth, View.Bottom - 1);
    etpBottom: ACanvas.Line(0, View.Top, AClientWidth, View.Top);
    etpLeft: ACanvas.Line(View.Right - 1, 0, View.Right - 1, AClientHeight);
    etpRight: ACanvas.Line(View.Left, 0, View.Left, AClientHeight);
  end;
end;

end.
