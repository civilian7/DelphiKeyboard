program VirtualKeyboardDemo;

uses
  Vcl.Forms,
  Demo.Main in 'Demo.Main.pas' {frmMain},
  SC.Hangul in '..\src\SC.Hangul.pas',
  SC.VirtualKeyboard in '..\src\SC.VirtualKeyboard.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
