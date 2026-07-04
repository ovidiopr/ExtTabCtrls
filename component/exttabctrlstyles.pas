unit ExtTabCtrlStyles;

{$mode objfpc}{$H+}

interface

uses
  Classes, Graphics, Types, Math, GraphUtil, LCLIntf;

type
  TExtTabPosition = (etpTop, etpBottom, etpLeft, etpRight);

  TExtTabStyle = (etsFlat, etsButton, etsDelphi, etsChrome, etsMacOS);

  { TExtTabStyleOptions }
  // Options to configure the styles
  TExtTabStyleOptions = class(TPersistent)
  private
    FShowStripLine: Boolean;
    FShowActiveAccentStripe: Boolean;
    FCornerRadius: Integer;
    FOnChange: TNotifyEvent;

    procedure SetShowStripLine(AValue: Boolean);
    procedure SetShowActiveAccentStripe(AValue: Boolean);
    procedure SetCornerRadius(AValue: Integer);
  public
    constructor Create;
    procedure Assign(Source: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    // Whether the full-width/height folder-strip separator line is drawn
    property ShowStripLine: Boolean read FShowStripLine write SetShowStripLine default True;
    // Chrome-style accent line drawn under the active tab
    property ShowActiveAccentStripe: Boolean read FShowActiveAccentStripe write SetShowActiveAccentStripe default True;
    // Corner rounding used by the Chrome/macOS pill shapes
    property CornerRadius: Integer read FCornerRadius write SetCornerRadius default 0;
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
    Options: TExtTabStyleOptions;
  end;

procedure DrawFlatTabStyle(ACanvas: TCanvas; var R: TRect; IsActive: Boolean;
  const Ctx: TExtTabDrawContext; var FontColor: TColor; var Indent: Integer);
procedure DrawButtonTabStyle(ACanvas: TCanvas; var R: TRect; IsActive: Boolean;
  const Ctx: TExtTabDrawContext; var FontColor: TColor; var Indent: Integer);
procedure DrawDelphiTabStyle(ACanvas: TCanvas; var R: TRect; IsActive: Boolean;
  const Ctx: TExtTabDrawContext; var FontColor: TColor; var Indent: Integer);
procedure DrawChromeTabStyle(ACanvas: TCanvas; var R: TRect; IsActive: Boolean;
  const Ctx: TExtTabDrawContext; var FontColor: TColor; var Indent: Integer);
procedure DrawMacOSTabStyle(ACanvas: TCanvas; var R: TRect; IsActive: Boolean;
  const Ctx: TExtTabDrawContext; var FontColor: TColor; var Indent: Integer);

// Draws the folder-tab separator line along the inner edge of the tab strip
procedure DrawStripLineStyle(ACanvas: TCanvas; const View: TRect;
  const Ctx: TExtTabDrawContext; AClientWidth, AClientHeight: Integer);

// Linear blend between two colors (Ratio=0 -> C1, Ratio=1 -> C2)
function BlendColors(C1, C2: TColor; Ratio: Single): TColor;

implementation

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

{ TExtTabStyleOptions }

constructor TExtTabStyleOptions.Create;
begin
  inherited Create;
  FShowStripLine := True;
  FShowActiveAccentStripe := True;
  FCornerRadius := 0;
end;

procedure TExtTabStyleOptions.SetShowStripLine(AValue: Boolean);
begin
  if FShowStripLine <> AValue then
  begin
    FShowStripLine := AValue;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TExtTabStyleOptions.SetShowActiveAccentStripe(AValue: Boolean);
begin
  if FShowActiveAccentStripe <> AValue then
  begin
    FShowActiveAccentStripe := AValue;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TExtTabStyleOptions.SetCornerRadius(AValue: Integer);
begin
  if FCornerRadius <> AValue then
  begin
    FCornerRadius := AValue;
    if Assigned(FOnChange) then FOnChange(Self);
  end;
end;

procedure TExtTabStyleOptions.Assign(Source: TPersistent);
begin
  if Source is TExtTabStyleOptions then
  begin
    FShowStripLine := TExtTabStyleOptions(Source).ShowStripLine;
    FShowActiveAccentStripe := TExtTabStyleOptions(Source).ShowActiveAccentStripe;
    FCornerRadius := TExtTabStyleOptions(Source).CornerRadius;

    if Assigned(FOnChange) then FOnChange(Self);
  end
  else
    inherited Assign(Source);
end;

{ Style drawers }

procedure DrawFlatTabStyle(ACanvas: TCanvas; var R: TRect; IsActive: Boolean;
  const Ctx: TExtTabDrawContext; var FontColor: TColor; var Indent: Integer);
var
  P: array[0..3] of TPoint;
  BaseClr: TColor;
begin
  Indent := 2;
  FontColor := IfThen(IsActive, Ctx.ActiveFontColor, Ctx.InactiveFontColor);

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
  const Ctx: TExtTabDrawContext; var FontColor: TColor; var Indent: Integer);
var
  BaseClr, LightClr, ShadowClr, BackClr: TColor;
begin
  Indent := 2;
  FontColor := IfThen(IsActive, Ctx.ActiveFontColor, Ctx.InactiveFontColor);

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
    ACanvas.Polyline([Point(R.Left, R.Bottom - 1), Point(R.Left, R.Top),
      Point(R.Right - 1, R.Top)]);
    ACanvas.Pen.Color := LightClr;
    ACanvas.Polyline([Point(R.Right - 1, R.Top), Point(R.Right - 1, R.Bottom - 1),
      Point(R.Left, R.Bottom - 1)]);

    // Adjust Content Position for "Pressed" effect
    Types.OffsetRect(R, Ctx.GetScale(1), Ctx.GetScale(1));
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
end;

procedure DrawDelphiTabStyle(ACanvas: TCanvas; var R: TRect; IsActive: Boolean;
  const Ctx: TExtTabDrawContext; var FontColor: TColor; var Indent: Integer);
var
  P: array[0..3] of TPoint;
  S: Integer;
  BaseClr: TColor;
begin
  Indent := 4;
  FontColor := IfThen(IsActive, Ctx.ActiveFontColor, Ctx.InactiveFontColor);

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
  const Ctx: TExtTabDrawContext; var FontColor: TColor; var Indent: Integer);
var
  Radius: Integer;
  StripeBounds: TRect;
  BaseClr: TColor;
begin
  Indent := 5;
  FontColor := IfThen(IsActive, Ctx.ActiveFontColor, Ctx.InactiveFontColor);

  if Ctx.Options.CornerRadius > 0 then
    Radius := Ctx.GetScale(Ctx.Options.CornerRadius)
  else
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
  if IsActive or Ctx.IsHoverTab or
     (not IsActive and (Ctx.TabColor <> clNone)) then
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
  if not IsActive and not Ctx.IsHoverTab and
     not Ctx.IsBeforeActiveTab and (Ctx.TabColor = clNone) then
  begin
    ACanvas.Pen.Color := Ctx.BorderColor;
    if Ctx.IsHorizontal then
      ACanvas.Line(R.Right - 1, R.Top + Ctx.GetScale(6), R.Right - 1, R.Bottom - Ctx.GetScale(6))
    else
      ACanvas.Line(R.Left + Ctx.GetScale(6), R.Bottom - 1, R.Right - Ctx.GetScale(6), R.Bottom - 1);
  end;

  // Accent line: use Tab.Color when set, otherwise fall back to clHighlight
  if IsActive and (Ctx.TabStripeColor = clNone) and Ctx.Options.ShowActiveAccentStripe then
  begin
    ACanvas.Pen.Color := IfThen(Ctx.TabColor <> clNone, Ctx.ResolveColor(Ctx.TabColor), clHighlight);
    ACanvas.Pen.Width := Ctx.GetScale(3);

    StripeBounds := R;
    InflateRect(StripeBounds, -Ctx.GetScale(5), -Ctx.GetScale(5));

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
  const Ctx: TExtTabDrawContext; var FontColor: TColor; var Indent: Integer);
var
  Radius: Integer;
  DrawR: TRect;
  BaseClr: TColor;
begin
  Indent := 6;
  FontColor := IfThen(IsActive, clWindowText, Ctx.InactiveFontColor);

  if Ctx.Options.CornerRadius > 0 then
    Radius := Ctx.GetScale(Ctx.Options.CornerRadius)
  else
    Radius := Ctx.GetScale(6);
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
  const Ctx: TExtTabDrawContext; AClientWidth, AClientHeight: Integer);
begin
  if not Ctx.Options.ShowStripLine then Exit;

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
