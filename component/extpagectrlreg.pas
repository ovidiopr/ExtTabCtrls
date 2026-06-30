unit ExtPageCtrlReg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ExtCtrls, ComponentEditors, PropEdits, PropEditUtils,
  ExtTabCtrl, ExtPageCtrl;

procedure Register;

implementation

{ TExtPageCtrlEditor }

type
  TExtPageCtrlEditor = class(TComponentEditor)
  private
    FHook: TPropertyEditorHook;

    procedure PageAdded(Sender: TObject; APage: TExtPage);
    procedure PageDeleting(Sender: TObject; APage: TExtPage);

    function PageCtrl: TExtPageCtrl;

    procedure RebuildDesignerTabTree(OldIdx, NewIdx: Integer);
  public
    constructor Create(AComponent: TComponent; ADesigner: TComponentEditorDesigner); override;
    destructor Destroy; override;

    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): String; override;
    procedure ExecuteVerb(Index: Integer); override;
  end;

constructor TExtPageCtrlEditor.Create(AComponent: TComponent; ADesigner: TComponentEditorDesigner);
begin
  inherited Create(AComponent, ADesigner);

  PageCtrl.OnPageAdded := @PageAdded;
  PageCtrl.OnPageDeleting := @PageDeleting;

  GetHook(FHook);
end;

destructor TExtPageCtrlEditor.Destroy;
begin
  if Assigned(PageCtrl) then
  begin
    PageCtrl.OnPageAdded := nil;
    PageCtrl.OnPageDeleting := nil;
  end;
  inherited Destroy;
end;

function TExtPageCtrlEditor.PageCtrl: TExtPageCtrl;
begin
  Result := GetComponent as TExtPageCtrl;
end;

procedure TExtPageCtrlEditor.PageAdded(Sender: TObject; APage: TExtPage);
var
  NewName: String;
begin
  // Give the TPage a unique, valid component name so the IDE can stream it
  if Assigned(GetDesigner) then
    NewName := GetDesigner.CreateUniqueComponentName(APage.ClassName)
  else
    NewName := APage.ClassName + '1';

  APage.Name := NewName;

  // Register the page with the designer
  if Assigned(FHook) then
    FHook.PersistentAdded(APage, True);

  Modified;
end;

procedure TExtPageCtrlEditor.PageDeleting(Sender: TObject; APage: TExtPage);
begin
  // Unregister the page from the designer before it is freed
  if Assigned(FHook) then
    FHook.DeletePersistent(TPersistent(APage));
end;

procedure TExtPageCtrlEditor.RebuildDesignerTabTree(OldIdx, NewIdx: Integer);
var
  PC: TExtPageCtrl;
begin
  PC := PageCtrl;
  PC.Tabs[OldIdx].Index := NewIdx;
  PC.PageIndex := NewIdx;

  Designer.Modified;
  if Assigned(GlobalDesignHook) then
  begin
    GlobalDesignHook.RefreshPropertyValues;
    GlobalDesignHook.SelectOnlyThis(PC.Tabs[NewIdx]);
  end;
end;

function TExtPageCtrlEditor.GetVerbCount: Integer;
begin
  Result := 4; // Add Page, Delete Page, Move Left/Up, Move Right/Down
end;

function TExtPageCtrlEditor.GetVerb(Index: Integer): String;
begin
  case Index of
    0: Result := 'Add Page';
    1: Result := 'Delete Page';
    2: if PageCtrl.IsHorizontal then
         Result := 'Move Left'
       else
         Result := 'Move Up';
    3: if PageCtrl.IsHorizontal then
         Result := 'Move Right'
       else
         Result := 'Move Down';
  else
    Result := '';
  end;
end;

procedure TExtPageCtrlEditor.ExecuteVerb(Index: Integer);
var
  PC: TExtPageCtrl;
  TargetIndex: Integer;
begin
  PC := PageCtrl;
  TargetIndex := PC.PageIndex;

  case Index of
    0: // Add Page
      begin
        PC.AddTab('New Page ' + IntToStr(PC.Tabs.Count + 1));
        Designer.Modified;
        Designer.SelectOnlyThisComponent(PC);
      end;

    1: // Delete Page
      begin
        if (TargetIndex >= 0) and (TargetIndex < PC.Tabs.Count) then
        begin
          PC.DeleteTab(TargetIndex);
          Designer.Modified;
          Designer.SelectOnlyThisComponent(PC);
        end;
      end;

    2: // Move Left / Move Up
      begin
        if TargetIndex > 0 then
          RebuildDesignerTabTree(TargetIndex, TargetIndex - 1);
      end;

    3: // Move Right / Move Down
      begin
        if (TargetIndex >= 0) and (TargetIndex < PC.Tabs.Count - 1) then
          RebuildDesignerTabTree(TargetIndex, TargetIndex + 1);
      end;
  end;
end;

{ TPageIndexPropertyEditor }

type
  TPageIndexPropertyEditor = class(TIntegerPropertyEditor)
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: String; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const NewValue: String); override;
  end;

function TPageIndexPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueList, paRevertable];
end;

function TPageIndexPropertyEditor.GetValue: String;
var
  Ctrl: TExtPageCtrl;
begin
  Ctrl := GetComponent(0) as TExtPageCtrl;
  if Assigned(Ctrl) and (Ctrl.PageIndex >= 0) and (Ctrl.PageIndex < Ctrl.Tabs.Count) then
    Result := IntToStr(Ctrl.PageIndex) + ' - ' + Ctrl.Tabs[Ctrl.PageIndex].Caption
  else
    Result := IntToStr(GetOrdValue);
end;

procedure TPageIndexPropertyEditor.GetValues(Proc: TGetStrProc);
var
  Ctrl: TExtPageCtrl;
  i: Integer;
begin
  Ctrl := GetComponent(0) as TExtPageCtrl;
  if not Assigned(Ctrl) then Exit;
  for i := 0 to Ctrl.Tabs.Count - 1 do
    Proc(IntToStr(i) + ' - ' + Ctrl.Tabs[i].Caption);
end;

procedure TPageIndexPropertyEditor.SetValue(const NewValue: String);
var
  Ctrl: TExtPageCtrl;
  Idx: Integer;
  S: String;
begin
  Ctrl := GetComponent(0) as TExtPageCtrl;
  if not Assigned(Ctrl) then Exit;
  // Accept either a plain integer ("2") or the "2 - Caption" format
  S := Trim(NewValue);
  if Pos(' ', S) > 0 then
    S := Copy(S, 1, Pos(' ', S) - 1);
  Idx := StrToIntDef(S, -1);
  Ctrl.PageIndex := Idx;
end;

{ Registration }

procedure Register;
begin
  RegisterComponents('Misc', [TExtPageCtrl]);
  RegisterNoIcon([TExtPage]);
  RegisterComponentEditor(TExtPageCtrl, TExtPageCtrlEditor);

  RegisterPropertyEditor(TypeInfo(Integer), TExtPageCtrl, 'PageIndex', TPageIndexPropertyEditor);
  // Hide the inherited TabIndex property
  RegisterPropertyEditor(TypeInfo(Integer), TExtPageCtrl, 'TabIndex', THiddenPropertyEditor);
end;

end.
