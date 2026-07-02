unit ExtPageCtrlReg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ExtCtrls, Controls, ComponentEditors, PropEdits,
  PropEditUtils, ExtTabCtrl, ExtPageCtrl;

procedure Register;

implementation

{ TExtPageCtrlEditor }

type
  TExtPageCtrlEditor = class(TComponentEditor)
  public
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): String; override;
    procedure ExecuteVerb(Index: Integer); override;
  end;

function TExtPageCtrlEditor.GetVerbCount: Integer;
begin
  Result := 4; // Add Page, Delete Page, Move Left/Up, Move Right/Down
end;

function TExtPageCtrlEditor.GetVerb(Index: Integer): String;
var
  PageCtrl: TExtPageCtrl;
begin
  PageCtrl := TExtPageCtrl(Component);

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
  PageControl: TExtPageCtrl;
  TargetIndex: Integer;
  CurrentPage, NewPage: TExtPage;
  CurrentTab: TExtTab;

  procedure RebuildDesignerTabTree(Ctrl: TExtPageCtrl; OldIdx, NewIdx: Integer);
  begin
    Ctrl.Tabs[OldIdx].Index := NewIdx;
    Ctrl.PageIndex := NewIdx;

    Designer.Modified;
    if Assigned(GlobalDesignHook) then
    begin
      GlobalDesignHook.RefreshPropertyValues;
      GlobalDesignHook.SelectOnlyThis(Ctrl);
    end;
  end;

begin
  PageControl := TExtPageCtrl(Component);
  TargetIndex := PageControl.PageIndex;

  case Index of
    0: // Add Page
      begin
        NewPage := PageControl.AddPage('New Page ' + IntToStr(PageControl.Tabs.Count + 1));
        Designer.Modified;
        if Assigned(NewPage) and Assigned(GlobalDesignHook) then
        begin
          GlobalDesignHook.PersistentAdded(NewPage, True);
          Exit;
        end;
      end;

    1: // Delete Page
      begin
        if (TargetIndex >= 0) and (TargetIndex < PageControl.Tabs.Count) then
        begin
          CurrentPage := PageControl.Page[TargetIndex];
          // DeletePersistent removes the node; DeletePage is not needed
          if Assigned(GlobalDesignHook) then
          begin
            CurrentTab := CurrentPage.Tab;
            GlobalDesignHook.DeletePersistent(TPersistent(CurrentTab));
            GlobalDesignHook.DeletePersistent(TPersistent(CurrentPage));
          end;
          //PageControl.DeletePage(TargetIndex);
        end;
      end;

    2: // Move Left / Move Up
      begin
        if TargetIndex > 0 then
          RebuildDesignerTabTree(PageControl, TargetIndex, TargetIndex - 1);
      end;

    3: // Move Right / Move Down
      begin
        if (TargetIndex >= 0) and (TargetIndex < PageControl.Tabs.Count - 1) then
          RebuildDesignerTabTree(PageControl, TargetIndex, TargetIndex + 1);
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
  Idx, P: Integer;
  S: String;
begin
  Ctrl := GetComponent(0) as TExtPageCtrl;
  if not Assigned(Ctrl) then Exit;
  // Accept either a plain integer ("2") or the "2 - Caption" format
  S := Trim(NewValue);
  P := Pos('-', S);
  if P > 0 then S := Trim(Copy(S, 1, P - 1));
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
  // Hide the inherited properties that we don't need
  RegisterPropertyEditor(TypeInfo(Integer), TExtPageCtrl, 'TabIndex', THiddenPropertyEditor);
  RegisterPropertyEditor(TypeInfo(Integer), TExtPage, 'Left', THiddenPropertyEditor);
  RegisterPropertyEditor(TypeInfo(Integer), TExtPage, 'Top', THiddenPropertyEditor);
  RegisterPropertyEditor(TypeInfo(Integer), TExtPage, 'Width', THiddenPropertyEditor);
  RegisterPropertyEditor(TypeInfo(Integer), TExtPage, 'Height', THiddenPropertyEditor);
  RegisterPropertyEditor(TypeInfo(Boolean), TExtPage, 'Visible', THiddenPropertyEditor);
  RegisterPropertyEditor(TypeInfo(TAlign), TExtPage, 'Align', THiddenPropertyEditor);
  RegisterPropertyEditor(TypeInfo(TCaption), TExtPage, 'Caption', THiddenPropertyEditor);
end;

end.
