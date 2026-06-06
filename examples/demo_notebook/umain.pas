unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ValEdit,
  StdCtrls, ExtDlgs, Interfaces, ExtTabCtrl;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    CmbTabStyle: TComboBox;
    ExtTabCtrl1: TExtTabCtrl;
    Image1: TImage;
    LblTabStyle: TLabel;
    Notebook1: TNotebook;
    OpenPictureDialog1: TOpenPictureDialog;
    Panel2: TPanel;
    PgSettings: TPage;
    PgInfo: TPage;
    PgImage: TPage;
    Panel1: TPanel;
    ValueListEditor1: TValueListEditor;
    procedure Button1Click(Sender: TObject);
    procedure CmbTabStyleChange(Sender: TObject);
    procedure ExtTabCtrl1TabChanged(Sender: TObject; NewIndex: Integer);
    procedure ExtTabCtrl1TabCreating(Sender: TObject; var ACaption: String; var Data: TObject; var Allow: Boolean);
    procedure ExtTabCtrl1TabDeleting(Sender: TObject; Index: Integer; var Allow: Boolean);
    procedure ExtTabCtrl1TabReordered(Sender: TObject; OldIndex, NewIndex: Integer);
    procedure FormCreate(Sender: TObject);
  private
    procedure LoadImage(const AFileName: String);
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  ExtTabCtrl1.AutoSize := True;
  CmbTabStyle.ItemIndex := ord(ExtTabCtrl1.TabStyle);
end;

procedure TForm1.ExtTabCtrl1TabChanged(Sender: TObject; NewIndex: Integer);
begin
  if (NewIndex >= 0) and (NewIndex < Notebook1.PageCount) then
    Notebook1.PageIndex := NewIndex;
end;

procedure TForm1.ExtTabCtrl1TabCreating(Sender: TObject; var ACaption: String; var Data: TObject; var Allow: Boolean);
begin
  Notebook1.Pages.Add(ACaption);
  Allow := True;
end;

procedure TForm1.ExtTabCtrl1TabDeleting(Sender: TObject; Index: Integer; var Allow: Boolean);
begin
  if (Index >= 0) and (Index < Notebook1.PageCount) then
  begin
    Notebook1.Pages.Delete(Index);
    Allow := True;
  end;
end;

procedure TForm1.ExtTabCtrl1TabReordered(Sender: TObject; OldIndex, NewIndex: Integer);
begin
  if (OldIndex >= 0) and (OldIndex < Notebook1.PageCount) and
     (NewIndex >= 0) and (NewIndex < Notebook1.PageCount) then
    Notebook1.Pages.Move(OldIndex, NewIndex);
end;

procedure TForm1.CmbTabStyleChange(Sender: TObject);
begin
  ExtTabCtrl1.TabStyle := TTabStyle(CmbTabStyle.ItemIndex);
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  if OpenPictureDialog1.Execute then
    LoadImage(OpenPictureDialog1.FileName);
end;

procedure TForm1.LoadImage(const AFileName: String);
begin
  Image1.Picture.LoadFromFile(AFileName);
  if Lowercase(ExtractFileExt(AFileName)) = '.ico' then
    Image1.Picture.Icon.Current := 0;
  ValueListEditor1.Clear;
  ValueListEditor1.InsertRow('FileName', ExtractFileName(AFileName), true);
  ValueListEditor1.InsertRow('Path', ExtractFileDir(ExpandFileName(AFileName)), true);
  ValueListEditor1.InsertRow('Width', IntToStr(Image1.Picture.Width), true);
  ValueListEditor1.InsertRow('Height', IntToStr(Image1.Picture.Height), true);
  ValueListEditor1.Row := 1;
end;

end.

