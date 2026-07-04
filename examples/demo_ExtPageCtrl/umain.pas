unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ExtTabCtrl, ExtTabCtrlStyles, ExtPageCtrl;

type

  { TForm1 }

  TForm1 = class(TForm)
    cbRotateNewTabBtn: TCheckBox;
    cbRotateTabIcons: TCheckBox;
    cbShowNewTabBtn: TCheckBox;
    cbUseExternalImages: TCheckBox;
    ExtPage1: TExtPage;
    ExtPage2: TExtPage;
    ExtPage3: TExtPage;
    ExtPageCtrl1: TExtPageCtrl;
    ImageList1: TImageList;
    RadioGroup1: TRadioGroup;
    RadioGroup2: TRadioGroup;
    procedure cbRotateNewTabBtnChange(Sender: TObject);
    procedure cbRotateTabIconsChange(Sender: TObject);
    procedure cbShowNewTabBtnChange(Sender: TObject);
    procedure cbUseExternalImagesChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure RadioGroup1Click(Sender: TObject);
    procedure RadioGroup2Click(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.RadioGroup1Click(Sender: TObject);
begin
  ExtPageCtrl1.TabPosition := TExtTabPosition(RadioGroup1.ItemIndex);
end;

procedure TForm1.RadioGroup2Click(Sender: TObject);
begin
  ExtPageCtrl1.TabStyle := TExtTabStyle(RadioGroup2.ItemIndex);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  RadioGroup1.ItemIndex := Ord(ExtPageCtrl1.TabPosition);
  RadioGroup2.ItemIndex := Ord(ExtPageCtrl1.TabStyle);
  cbShowNewTabBtn.Checked := etoShowAddButton in ExtPageCtrl1.TabOptions;
  cbRotateNewTabBtn.Checked := etoRotateAddImage in ExtPageCtrl1.TabOptions;
  cbUseExternalImages.Checked := ExtPageCtrl1.Images <> nil;
  cbRotateTabIcons.Checked := etoRotateTabImages in ExtPageCtrl1.TabOptions;
end;

procedure TForm1.cbShowNewTabBtnChange(Sender: TObject);
begin
  if cbShowNewTabBtn.Checked then
    ExtPageCtrl1.TabOptions := ExtPageCtrl1.TabOptions + [etoShowAddButton]
  else
    ExtPageCtrl1.TabOptions := ExtPageCtrl1.TabOptions - [etoShowAddButton];
end;

procedure TForm1.cbUseExternalImagesChange(Sender: TObject);
begin
  if cbUseExternalImages.Checked then
    ExtPageCtrl1.Images := ImageList1
  else
    ExtPageCtrl1.Images := nil;
end;

procedure TForm1.cbRotateNewTabBtnChange(Sender: TObject);
begin
  if cbRotateNewTabBtn.Checked then
    ExtPageCtrl1.TabOptions := ExtPageCtrl1.TabOptions + [etoRotateAddImage]
  else
    ExtPageCtrl1.TabOptions := ExtPageCtrl1.TabOptions - [etoRotateAddImage];
end;

procedure TForm1.cbRotateTabIconsChange(Sender: TObject);
begin
  if cbRotateTabIcons.Checked then
    ExtPageCtrl1.TabOptions := ExtPageCtrl1.TabOptions + [etoRotateTabImages]
  else
    ExtPageCtrl1.TabOptions := ExtPageCtrl1.TabOptions - [etoRotateTabImages];
end;

end.

