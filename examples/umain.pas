unit umain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ExtTabCtrl, LCLIntf, LResources, Menus;

type
  { TForm1 }
  TForm1 = class(TForm)
    cbStyle: TComboBox;
    cbPos: TComboBox;
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
    procedure ExtTabCtrl1TabReordered(Sender: TObject; OldIndex,
      NewIndex: Integer);
    procedure FormCreate(Sender: TObject);

    // Existing event handlers
    procedure ExtTabCtrl1TabChange(Sender: TObject; NewIndex: Integer);
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

  ExtTabCtrl1.Tabs[0].Color := clRed;
  ExtTabCtrl1.Tabs[1].Color := clGreen;

  cbStyle.ItemIndex := Integer(ExtTabCtrl1.TabStyle);
  cbPos.ItemIndex := Integer(ExtTabCtrl1.TabPosition);

  Log('Application started. Keyboard support (Arrows) and Tooltips enabled.');
end;

procedure TForm1.Log(const Msg: string);
begin
  if Assigned(MemoLog) then
    MemoLog.Lines.Add(FormatDateTime('hh:nn:ss.zzz', Now) + ' > ' + Msg);
end;

{ --- New Event Implementations --- }

procedure TForm1.ExtTabCtrl1TabClick(Sender: TObject; Index: Integer);
begin
  Log('EVENT: Single Click on Tab Index: ' + IntToStr(Index) + ' (' + ExtTabCtrl1.Tabs[Index].Caption + ')');
end;

procedure TForm1.ExtTabCtrl1TabDblClick(Sender: TObject; Index: Integer);
begin
  Log('EVENT: Double Click on Tab Index: ' + IntToStr(Index) + ' (' + ExtTabCtrl1.Tabs[Index].Caption + ')');
  // Example action: Rename on double click
  ExtTabCtrl1.Tabs[Index].Caption := InputBox('Rename Tab', 'New name:', ExtTabCtrl1.Tabs[Index].Caption);
end;

procedure TForm1.OnAddClick(Sender: TObject);
begin
  ExtTabCtrl1.AddTab('New Tab ' + IntToStr(ExtTabCtrl1.Tabs.Count + 1));
end;

{ --- Existing Event Handlers --- }

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

procedure TForm1.ExtTabCtrl1TabChange(Sender: TObject; NewIndex: Integer);
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
  ExtTabCtrl1.TabStyle := TTabStyle(cbStyle.ItemIndex);
end;

procedure TForm1.cbPosChange(Sender: TObject);
begin
  ExtTabCtrl1.TabPosition := TTabPosition(cbPos.ItemIndex);
  case ExtTabCtrl1.TabPosition of
    tpTop: ExtTabCtrl1.Align := alTop;
    tpBottom: ExtTabCtrl1.Align := alBottom;
    tpLeft: ExtTabCtrl1.Align := alLeft;
    tpRight: ExtTabCtrl1.Align := alRight;
  end;
  if ExtTabCtrl1.TabPosition in [tpTop, tpBottom] then
    ExtTabCtrl1.Height := 34
  else
    ExtTabCtrl1.Width := 34;
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
  ShowMessage(Format('Tab moved from %d to %d', [OldIndex + 1, NewIndex + 1]));
end;

end.
