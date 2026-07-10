// TSCVirtualKeyboard 컴포넌트 데모 메인 폼
unit Demo.Main;

interface

{$REGION 'uses'}
uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  Winapi.Messages,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.Buttons;
{$ENDREGION}

type
  TfrmMain = class(TForm)
    Edit1: TEdit;
    BtnKeyboard: TSpeedButton;
    procedure BtnKeyboardClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

{$REGION 'uses'}
uses
  SC.VirtualKeyboard;
{$ENDREGION}

procedure TfrmMain.BtnKeyboardClick(Sender: TObject);
begin
  var LText: string := Edit1.Text;

  // 싱글톤 사용 (생성/해제 불필요). TSCVirtualKeyboard.Create 로 직접 생성해서 써도 된다
  if TSCVirtualKeyboard.Instance.Execute(LText) then
  begin
    Edit1.Text := LText;
    Edit1.SelStart := Length(LText);
  end;
end;

end.
