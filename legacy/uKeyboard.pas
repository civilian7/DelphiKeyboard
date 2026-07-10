unit uKeyboard;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.AppEvnts;

const
  WM_USER_ENTER = WM_USER + 1102;

type
  TfrmKeyboard = class(TForm)
    edKeyboard: TEdit;
    Button2: TButton;
    ApplicationEvents1: TApplicationEvents;
    procedure FormPaint(Sender: TObject);
    procedure ApplicationEvents1Message(var Msg: tagMSG; var Handled: Boolean);
    procedure FormShow(Sender: TObject);
    procedure edKeyboardKeyPress(Sender: TObject; var Key: Char);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { Private declarations }
    bmpKeyboard: TBitmap;
    procedure WMEnter(var Msg: TMessage); message WM_USER_ENTER;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ShowKeyboard(asStr: string): Integer;
  end;

var
  frmKeyboard: TfrmKeyboard;

implementation

uses
  uDrawBmp, Vcl.Imaging.GIFImg;

{$R *.dfm}
{$R Image.res}    // Image.rc를 컴파일한 리소스 (GIF_KEYBOARD 포함, 하단 안내 참고)

const
  KEY_NUMS = 66;

type
  // 원본 C++ 코드는 RECT를 {left, top, width, height} 형태로 재사용했습니다.
  // 혼동을 피하기 위해 필드 이름을 명확히 한 레코드로 변환했습니다(동작은 동일).
  TKeyRect = record
    Left, Top, Width, Height: Integer;
  end;

var
  // 영문 자판 표기
  asKeyEng: array[0..KEY_NUMS - 1] of string = (
    'ESC', 'HOME', 'END', 'INSERT', 'DELETE',
    '~`', '!1', '@2', '#3', '$4', '%5', '^6', '&7', '*8', '(9', ')0', '_-', '+=', '<-',
    'TAB', 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{[', '}]', '|\',
    'Caps Lock', 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':;', '"' + '''', 'Enter',
    'Shift', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<,', '>.', '?/', 'Up',
    'Ctrl', 'Alt', 'SPACE', '한/영', 'ALT', 'Left', 'Down', 'Right'
  );

  // 한글 자판 표기
  asKeyHan: array[0..KEY_NUMS - 1] of string = (
    'ESC', 'HOME', 'END', 'INSERT', 'DELETE',
    '~`', '!1', '@2', '#3', '$4', '%5', '^6', '&7', '*8', '(9', ')0', '_-', '+=', '<-',
    'TAB', 'ㅃㅂ', 'ㅉㅈ', 'ㄸㄷ', 'ㄲㄱ', 'ㅆㅅ', 'ㅛ', 'ㅕ', 'ㅑ', 'ㅒㅐ', 'ㅖㅔ', '{[', '}]', '|\',
    'Caps Lock', 'ㅁ', 'ㄴ', 'ㅇ', 'ㄹ', 'ㅎ', 'ㅗ', 'ㅓ', 'ㅏ', 'ㅣ', ':;', '"' + '''', 'Enter',
    'Shift', 'ㅋ', 'ㅌ', 'ㅊ', 'ㅍ', 'ㅠ', 'ㅜ', 'ㅡ', '<,', '>.', '?/', 'Up',
    'Ctrl', 'Alt', 'SPACE', '한/영', 'ALT', 'Left', 'Down', 'Right'
  );

  // {Left, Top, Width, Height} - 33_0_5, 95_5_14, 155_19_14, 205_33_13, 260_46_12, 316_58_8
  rtPS: array[0..KEY_NUMS - 1] of TKeyRect = (
    (Left: 12;  Top: 33;  Width: 74;  Height: 48), (Left: 578; Top: 33;  Width: 48;  Height: 48),
    (Left: 632; Top: 33;  Width: 48;  Height: 48), (Left: 686; Top: 33;  Width: 48;  Height: 48),
    (Left: 740; Top: 33;  Width: 48;  Height: 48),

    (Left: 12;  Top: 95;  Width: 48;  Height: 48), (Left: 66;  Top: 95;  Width: 48;  Height: 48),
    (Left: 120; Top: 95;  Width: 48;  Height: 48), (Left: 174; Top: 95;  Width: 48;  Height: 48),
    (Left: 228; Top: 95;  Width: 48;  Height: 48), (Left: 282; Top: 95;  Width: 48;  Height: 48),
    (Left: 336; Top: 95;  Width: 48;  Height: 48), (Left: 390; Top: 95;  Width: 48;  Height: 48),
    (Left: 444; Top: 95;  Width: 48;  Height: 48), (Left: 498; Top: 95;  Width: 48;  Height: 48),
    (Left: 552; Top: 95;  Width: 48;  Height: 48), (Left: 606; Top: 95;  Width: 48;  Height: 48),
    (Left: 660; Top: 95;  Width: 48;  Height: 48), (Left: 714; Top: 95;  Width: 74;  Height: 48),

    (Left: 12;  Top: 150; Width: 74;  Height: 48), (Left: 92;  Top: 150; Width: 48;  Height: 48),
    (Left: 146; Top: 150; Width: 48;  Height: 48), (Left: 200; Top: 150; Width: 48;  Height: 48),
    (Left: 254; Top: 150; Width: 48;  Height: 48), (Left: 308; Top: 150; Width: 48;  Height: 48),
    (Left: 362; Top: 150; Width: 48;  Height: 48), (Left: 416; Top: 150; Width: 48;  Height: 48),
    (Left: 470; Top: 150; Width: 48;  Height: 48), (Left: 524; Top: 150; Width: 48;  Height: 48),
    (Left: 578; Top: 150; Width: 48;  Height: 48), (Left: 632; Top: 150; Width: 48;  Height: 48),
    (Left: 686; Top: 150; Width: 48;  Height: 48), (Left: 740; Top: 150; Width: 48;  Height: 48),

    (Left: 12;  Top: 205; Width: 88;  Height: 48), (Left: 106; Top: 205; Width: 48;  Height: 48),
    (Left: 160; Top: 205; Width: 48;  Height: 48), (Left: 214; Top: 205; Width: 48;  Height: 48),
    (Left: 268; Top: 205; Width: 48;  Height: 48), (Left: 322; Top: 205; Width: 48;  Height: 48),
    (Left: 376; Top: 205; Width: 48;  Height: 48), (Left: 430; Top: 205; Width: 48;  Height: 48),
    (Left: 484; Top: 205; Width: 48;  Height: 48), (Left: 538; Top: 205; Width: 48;  Height: 48),
    (Left: 592; Top: 205; Width: 48;  Height: 48), (Left: 646; Top: 205; Width: 48;  Height: 48),
    (Left: 701; Top: 205; Width: 87;  Height: 48),

    (Left: 12;  Top: 260; Width: 115; Height: 48), (Left: 133; Top: 260; Width: 48;  Height: 48),
    (Left: 187; Top: 260; Width: 48;  Height: 48), (Left: 241; Top: 260; Width: 48;  Height: 48),
    (Left: 295; Top: 260; Width: 48;  Height: 48), (Left: 349; Top: 260; Width: 48;  Height: 48),
    (Left: 403; Top: 260; Width: 48;  Height: 48), (Left: 457; Top: 260; Width: 48;  Height: 48),
    (Left: 511; Top: 260; Width: 48;  Height: 48), (Left: 565; Top: 260; Width: 48;  Height: 48),
    (Left: 619; Top: 260; Width: 48;  Height: 48), (Left: 686; Top: 260; Width: 48;  Height: 48),

    (Left: 12;  Top: 316; Width: 74;  Height: 48), (Left: 92;  Top: 316; Width: 74;  Height: 48),
    (Left: 176; Top: 316; Width: 282; Height: 48), (Left: 468; Top: 316; Width: 74;  Height: 48),
    (Left: 548; Top: 316; Width: 74;  Height: 48), (Left: 632; Top: 316; Width: 48;  Height: 48),
    (Left: 686; Top: 316; Width: 48;  Height: 48), (Left: 740; Top: 316; Width: 48;  Height: 48)
  );

  KeyValue: array[0..KEY_NUMS - 1] of Byte = (
    VK_ESCAPE, VK_HOME, VK_END, VK_INSERT, VK_DELETE,
    Ord('`'), Ord('1'), Ord('2'), Ord('3'), Ord('4'), Ord('5'), Ord('6'), Ord('7'), Ord('8'),
    Ord('9'), Ord('0'), Ord('-'), Ord('='), VK_BACK,
    VK_TAB, Ord('q'), Ord('w'), Ord('e'), Ord('r'), Ord('t'), Ord('y'), Ord('u'), Ord('i'),
    Ord('o'), Ord('p'), Ord('['), Ord(']'), Ord('\'),
    VK_CAPITAL, Ord('a'), Ord('s'), Ord('d'), Ord('f'), Ord('g'), Ord('h'), Ord('j'), Ord('k'),
    Ord('l'), Ord(';'), Ord(''''), VK_RETURN,
    VK_SHIFT, Ord('z'), Ord('x'), Ord('c'), Ord('v'), Ord('b'), Ord('n'), Ord('m'), Ord(','),
    Ord('.'), Ord('/'), VK_UP,
    VK_CONTROL, VK_MENU, Ord(' '), $15, VK_MENU, VK_LEFT, VK_DOWN, VK_RIGHT
  );

  IsVkKey: array[0..KEY_NUMS - 1] of Byte = (
    1, 1, 1, 1, 1,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
    1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
    1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
    1, 1, 0, 1, 1, 1, 1, 1
  );

var
  iKeyPos: Integer = -1;
  hMouseHookS: HHOOK = 0;
  bDownShift: Boolean;

//------------------------------------------------------------------------------

function GetIndexXY(X, Y: Integer): Integer;
var
  iRet, i: Integer;
begin
  iRet := -1;

  if (32 < Y) and (Y < (33 + 47)) then
  begin
    i := 0;
    while i < 5 do
    begin
      if (rtPS[i].Left < X) and (X < (rtPS[i].Left + rtPS[i].Width)) then
      begin
        iRet := i;
        Break;
      end;
      Inc(i);
    end;
  end
  else if (94 < Y) and (Y < (95 + 47)) then
  begin
    i := 5;
    while i < 5 + 14 do
    begin
      if (rtPS[i].Left < X) and (X < (rtPS[i].Left + rtPS[i].Width)) then
      begin
        iRet := i;
        Break;
      end;
      Inc(i);
    end;
  end
  else if (154 < Y) and (Y < (155 + 47)) then
  begin
    i := 19;
    while i < 19 + 14 do
    begin
      if (rtPS[i].Left < X) and (X < (rtPS[i].Left + rtPS[i].Width)) then
      begin
        iRet := i;
        Break;
      end;
      Inc(i);
    end;
  end
  else if (204 < Y) and (Y < (205 + 47)) then
  begin
    i := 33;
    while i < 33 + 13 do
    begin
      if (rtPS[i].Left < X) and (X < (rtPS[i].Left + rtPS[i].Width)) then
      begin
        iRet := i;
        Break;
      end;
      Inc(i);
    end;
  end
  else if (259 < Y) and (Y < (260 + 47)) then
  begin
    i := 46;
    while i < 46 + 12 do
    begin
      if (rtPS[i].Left < X) and (X < (rtPS[i].Left + rtPS[i].Width)) then
      begin
        iRet := i;
        Break;
      end;
      Inc(i);
    end;
  end
  else if (315 < Y) and (Y < (316 + 47)) then
  begin
    i := 58;
    while i < 58 + 8 do
    begin
      if (rtPS[i].Left < X) and (X < (rtPS[i].Left + rtPS[i].Width)) then
      begin
        iRet := i;
        Break;
      end;
      Inc(i);
    end;
  end;

  Result := iRet;
end;

// keybd_event는 스캔코드를 항상 0으로 보내기 때문에, 두벌식 한글 IME가 물리키를 구분하지 못해
// 자음/모음이 조합되지 않고 낱개로 입력되는 문제가 생길 수 있습니다.
// SendInput + MapVirtualKey로 실제 하드웨어 스캔코드를 채워서 보내면 IME가 정상적으로 조합합니다.
procedure SendVKey(vk: Byte; keyUp: Boolean);
var
  Input1: TInput;
begin
  FillChar(Input1, SizeOf(Input1), 0);
  Input1.Itype := INPUT_KEYBOARD;
  Input1.ki.wVk := vk;
  Input1.ki.wScan := MapVirtualKey(vk, MAPVK_VK_TO_VSC);
  if keyUp then
    Input1.ki.dwFlags := KEYEVENTF_KEYUP
  else
    Input1.ki.dwFlags := 0;
  Input1.ki.time := 0;
  Input1.ki.dwExtraInfo := 0;
  SendInput(1, Input1, SizeOf(TInput));
end;

function MouseHookS(nCode: Integer; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  point: TPoint;
  pm: PMouseHookStruct;
  iRet: Integer;
  vk: SmallInt;
begin
  iRet := -1;

  if nCode >= 0 then
  begin
    case wParam of
      WM_LBUTTONDOWN:
        begin
          pm := PMouseHookStruct(lParam);
          point := pm.pt;

          iRet := GetIndexXY(point.X - frmKeyboard.Left, point.Y - frmKeyboard.Top);

          if iRet <> -1 then
          begin
            iKeyPos := iRet;
            frmKeyboard.Invalidate;

            if KeyValue[iRet] = VK_RETURN then
            begin
              vk := VkKeyScanA(AnsiChar(Byte(VK_RETURN)));
              SendVKey(Byte(vk), False);
              SendVKey(Byte(vk), True);

              Result := 1;
              Exit;
            end;

            if (KeyValue[iRet] = VK_SHIFT) and (IsVkKey[iRet] = 1) then
            begin
              bDownShift := not bDownShift;
              Result := 1;
              Exit;
            end;
            //--------------------------------------------------------------------------

            if IsVkKey[iRet] = 1 then
            begin
              if bDownShift then
                SendVKey(VK_SHIFT, False);

              SendVKey(KeyValue[iRet], False);
              SendVKey(KeyValue[iRet], True);

              if bDownShift then
                SendVKey(VK_SHIFT, True);

              bDownShift := False;

              Result := 1;
              Exit;
            end
            else
            begin
              if bDownShift then
                SendVKey(VK_SHIFT, False);

              vk := VkKeyScanA(AnsiChar(KeyValue[iRet]));
              SendVKey(Byte(vk), False);
              SendVKey(Byte(vk), True);

              if bDownShift then
                SendVKey(VK_SHIFT, True);

              bDownShift := False;

              Result := 1;
              Exit;
            end;
          end;
        end;

      WM_LBUTTONUP:
        ; // 원본과 동일하게 별도 처리 없음

      WM_MOUSEMOVE:
        begin
          pm := PMouseHookStruct(lParam);
          point := pm.pt;

          iRet := GetIndexXY(point.X - frmKeyboard.Left, point.Y - frmKeyboard.Top);

          if iRet <> -1 then
          begin
            if iKeyPos <> iRet then
            begin
              iKeyPos := iRet;
              frmKeyboard.Invalidate;
            end;
          end;
        end;
    end;
  end;

  Result := CallNextHookEx(hMouseHookS, nCode, wParam, lParam);
end;

procedure InstallMouseHookS;
begin
  if hMouseHookS = 0 then
    hMouseHookS := SetWindowsHookEx(WH_MOUSE, @MouseHookS, 0, GetCurrentThreadId);
end;

procedure UnInstallMouseHookS;
begin
  if hMouseHookS <> 0 then
  begin
    UnhookWindowsHookEx(hMouseHookS);
    hMouseHookS := 0;
  end;
end;

//------------------------------------------------------------------------------

constructor TfrmKeyboard.Create(AOwner: TComponent);
var
  rc: TResourceStream;
  tmp: TGIFImage;
begin
  inherited Create(AOwner);

  DoubleBuffered := True;
  bDownShift := False;

  bmpKeyboard := TBitmap.Create;

  rc := TResourceStream.Create(HInstance, 'GIF_KEYBOARD', RT_RCDATA);
  try
    tmp := TGIFImage.Create;
    try
      tmp.LoadFromStream(rc);
      bmpKeyboard.Assign(tmp.Bitmap);
    finally
      tmp.Free;
    end;
  finally
    rc.Free;
  end;
end;

destructor TfrmKeyboard.Destroy;
begin
  bmpKeyboard.Free;
  inherited Destroy;
end;

procedure TfrmKeyboard.FormPaint(Sender: TObject);
begin
  if Assigned(bmpKeyboard) then
  begin
    PaintBitbltWidth(Canvas.Handle, bmpKeyboard, 0, 0);

    if iKeyPos <> -1 then
    begin
      Canvas.Brush.Style := bsClear;
      Canvas.Pen.Color := $00FF4D4D;
      Canvas.Pen.Width := 1;
      Canvas.RoundRect(rtPS[iKeyPos].Left, rtPS[iKeyPos].Top,
        rtPS[iKeyPos].Left + rtPS[iKeyPos].Width, rtPS[iKeyPos].Top + rtPS[iKeyPos].Height, 6, 6);
      Canvas.Pen.Color := $00FF6D6D;
      Canvas.RoundRect(rtPS[iKeyPos].Left + 1, rtPS[iKeyPos].Top + 1,
        rtPS[iKeyPos].Left + rtPS[iKeyPos].Width - 1, rtPS[iKeyPos].Top + rtPS[iKeyPos].Height - 1, 4, 4);
      Canvas.RoundRect(rtPS[iKeyPos].Left + 1, rtPS[iKeyPos].Top + 1,
        rtPS[iKeyPos].Left + rtPS[iKeyPos].Width - 1, rtPS[iKeyPos].Top + rtPS[iKeyPos].Height - 1, 5, 5);
    end;
  end;
end;

procedure TfrmKeyboard.WMEnter(var Msg: TMessage);
begin
  ModalResult := 1;
end;

procedure TfrmKeyboard.ApplicationEvents1Message(var Msg: tagMSG; var Handled: Boolean);
begin
  if (Msg.message = WM_KEYUP) and (Msg.wParam = $00E5) then
    Handled := True;
end;

function TfrmKeyboard.ShowKeyboard(asStr: string): Integer;
begin
  edKeyboard.Text := asStr;
  edKeyboard.SelectAll;

  bDownShift := False;

  InstallMouseHookS;

  Result := ShowModal;

  UnInstallMouseHookS;
end;

procedure TfrmKeyboard.FormShow(Sender: TObject);
begin
  edKeyboard.SetFocus;
end;

procedure TfrmKeyboard.edKeyboardKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    ModalResult := 1;
  end
  else if Key = #27 then
  begin
    Key := #0;
    ModalResult := 2;
  end;
end;

procedure TfrmKeyboard.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  ReleaseCapture;
  Perform(WM_SYSCOMMAND, $F012, 0);
end;

end.
