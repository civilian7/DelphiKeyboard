// 가상 키보드 컴포넌트
// OS IME에 의존하지 않고 SC.Hangul 의 두벌식 조합 오토마타로 한글을 직접 조합한다.
// 키보드는 벡터로 렌더링하므로 이미지 리소스가 필요 없고, DPI 배율에 맞춰 스케일된다.
unit SC.VirtualKeyboard;

interface

{$REGION 'uses'}
uses
  System.Classes,
  System.SysUtils,
  System.Math,
  System.Types,
  System.UITypes,
  Winapi.Windows,
  Winapi.Messages,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  SC.Hangul;
{$ENDREGION}

type
  TSCKeyboardLanguage = (
    klEnglish,
    klKorean
  );

  TSCKeyboardPosition = (
    kpScreenCenter,     // 화면 중앙
    kpMainFormCenter,   // 메인 폼 중앙
    kpCustom            // CustomLeft/CustomTop 좌표 (화면 픽셀 기준)
  );

  /// <summary>화면 가상 키보드 컴포넌트.
  /// Execute 호출 시 모달 키보드 창을 띄워 마우스 클릭만으로 한글/영문을 입력받습니다.
  /// 한글은 내부 두벌식 조합 오토마타(SC.Hangul)로 직접 조합하므로
  /// 시스템 IME 상태(한/영 모드)와 무관하게 항상 올바르게 조합됩니다.</summary>
  TSCVirtualKeyboard = class
  strict private
    class var FInstance: TSCVirtualKeyboard;
    class destructor Destroy;
    class function GetInstance: TSCVirtualKeyboard; static;
  private
    FBackgroundColor: TColor;
    FBorderColor: TColor;
    FCustomLeft: Integer;
    FCustomTop: Integer;
    FHeight: Integer;
    FHotColor: TColor;
    FKeyColor: TColor;
    FKeyTextColor: TColor;
    FLanguage: TSCKeyboardLanguage;
    FPasswordChar: Char;
    FPosition: TSCKeyboardPosition;
    FPressedColor: TColor;
    FSpecialKeyColor: TColor;
    FSubTextColor: TColor;
    FTitle: string;
    FTitleTextColor: TColor;
    FToggledColor: TColor;
    FWidth: Integer;
  public
    constructor Create;

    /// <summary>가상 키보드 창을 모달로 띄우고 입력을 받습니다. 크기는 Width/Height 프로퍼티를 따릅니다.</summary>
    /// <param name="AText">초기 표시 텍스트. 확인(Enter) 시 입력 결과로 갱신됩니다.</param>
    /// <returns>Enter 로 확정하면 True, ESC 로 취소하면 False (AText 는 변경되지 않음)</returns>
    function Execute(var AText: string): Boolean; overload;

    /// <summary>가상 키보드 창을 지정 크기로 모달로 띄우고 입력을 받습니다.</summary>
    /// <param name="AText">초기 표시 텍스트. 확인(Enter) 시 입력 결과로 갱신됩니다.</param>
    /// <param name="AWidth">키보드 폭 (96DPI 기준 논리값). 0 이하면 Width 프로퍼티 값 사용</param>
    /// <param name="AHeight">키보드 높이 (96DPI 기준 논리값). 0 이하면 Height 프로퍼티 값 사용</param>
    /// <returns>Enter 로 확정하면 True, ESC 로 취소하면 False (AText 는 변경되지 않음)</returns>
    function Execute(var AText: string; const AWidth, AHeight: Integer): Boolean; overload;

    /// <summary>키보드 창의 표시 좌표를 지정하고 Position 을 kpCustom 으로 전환합니다.</summary>
    /// <param name="ALeft">창 좌측 좌표 (화면 픽셀 기준)</param>
    /// <param name="ATop">창 상단 좌표 (화면 픽셀 기준)</param>
    procedure SetCustomPosition(const ALeft, ATop: Integer);

    /// <summary>폼 배경 색상.</summary>
    property BackgroundColor: TColor read FBackgroundColor write FBackgroundColor;
    /// <summary>키 테두리 색상.</summary>
    property BorderColor: TColor read FBorderColor write FBorderColor;
    /// <summary>Position 이 kpCustom 일 때 사용할 창 좌측 좌표 (화면 픽셀 기준).</summary>
    property CustomLeft: Integer read FCustomLeft write FCustomLeft;
    /// <summary>Position 이 kpCustom 일 때 사용할 창 상단 좌표 (화면 픽셀 기준).</summary>
    property CustomTop: Integer read FCustomTop write FCustomTop;
    /// <summary>키보드 높이 (96DPI 기준 논리값, 기본 378). 실제 픽셀 크기는 모니터 DPI 에 따라 추가 스케일됩니다.</summary>
    property Height: Integer read FHeight write FHeight;
    /// <summary>마우스 오버 상태의 키 면 색상.</summary>
    property HotColor: TColor read FHotColor write FHotColor;
    /// <summary>일반(문자) 키 면 색상.</summary>
    property KeyColor: TColor read FKeyColor write FKeyColor;
    /// <summary>키 글자 색상.</summary>
    property KeyTextColor: TColor read FKeyTextColor write FKeyTextColor;
    /// <summary>키보드가 처음 열릴 때의 입력 언어.</summary>
    property Language: TSCKeyboardLanguage read FLanguage write FLanguage;
    /// <summary>입력창의 암호 표시 문자. #0 이면 일반 표시.</summary>
    property PasswordChar: Char read FPasswordChar write FPasswordChar;
    /// <summary>키보드 창 표시 위치 (기본 kpScreenCenter).
    /// kpCustom 이면 CustomLeft/CustomTop 좌표에 표시하되 모니터 작업 영역을 벗어나지 않게 보정합니다.</summary>
    property Position: TSCKeyboardPosition read FPosition write FPosition;
    /// <summary>눌린 키 면 색상.</summary>
    property PressedColor: TColor read FPressedColor write FPressedColor;
    /// <summary>특수 키(ESC, Enter, Shift 등) 면 색상.</summary>
    property SpecialKeyColor: TColor read FSpecialKeyColor write FSpecialKeyColor;
    /// <summary>Shift 보조 글자(키 상단 작은 글자) 색상.</summary>
    property SubTextColor: TColor read FSubTextColor write FSubTextColor;
    /// <summary>키보드 창 좌측 상단에 표시할 제목.</summary>
    property Title: string read FTitle write FTitle;
    /// <summary>제목 글자 색상.</summary>
    property TitleTextColor: TColor read FTitleTextColor write FTitleTextColor;
    /// <summary>토글 활성(Shift/Caps/한영 켜짐) 키 면 색상.</summary>
    property ToggledColor: TColor read FToggledColor write FToggledColor;
    /// <summary>키보드 폭 (96DPI 기준 논리값, 기본 800). 실제 픽셀 크기는 모니터 DPI 에 따라 추가 스케일됩니다.</summary>
    property Width: Integer read FWidth write FWidth;

    /// <summary>전역 싱글톤 인스턴스. 첫 접근 시 생성되고 프로그램 종료 시 자동 해제됩니다.
    /// 별도 생성 없이 TSCVirtualKeyboard.Instance.Execute(...) 형태로 바로 사용할 수 있습니다.
    /// UI 를 다루므로 메인(VCL) 스레드에서만 접근해야 합니다.</summary>
    class property Instance: TSCVirtualKeyboard read GetInstance;
  end;

implementation

const
  KEY_NUMS = 66;

  // 96DPI 기준 폼 논리 크기 (기본값·스케일 기준)
  FORM_W = 800;
  FORM_H = 378;

  // 96DPI 기준 최소 논리 크기 (이보다 작으면 키를 조작할 수 없어 보정)
  MIN_FORM_W = 400;
  MIN_FORM_H = 189;

  // 기본 색상 팔레트
  COLOR_FORM_BG    = TColor($00EEF0F2);   // 폼 배경 (밝은 웜그레이)
  COLOR_KEY_FACE   = TColor($00FDFDFD);   // 일반 키 면
  COLOR_KEY_SPEC   = TColor($00DDE1E4);   // 특수 키 면
  COLOR_KEY_BORDER = TColor($00C8CCD0);   // 키 테두리
  COLOR_KEY_HOT    = TColor($00F2E8DA);   // 마우스 오버
  COLOR_KEY_DOWN   = TColor($00E0C9A8);   // 눌림
  COLOR_KEY_ON     = TColor($00A8D8F8);   // 토글 활성 (Shift/Caps/한영)
  COLOR_KEY_TEXT   = TColor($00303030);   // 키 글자
  COLOR_KEY_SUB    = TColor($00909498);   // Shift 보조 글자
  COLOR_TITLE_TEXT = TColor($00707478);   // 제목

type
  // 컴포넌트 → 키보드 폼 색상 전달용
  TSCKeyboardColors = record
    Background: TColor;
    Border: TColor;
    Hot: TColor;
    KeyFace: TColor;
    KeyText: TColor;
    Pressed: TColor;
    SpecialKey: TColor;
    SubText: TColor;
    TitleText: TColor;
    Toggled: TColor;
  end;
  TSCVKeyKind = (
    vkkChar,
    vkkEsc,
    vkkHome,
    vkkEnd,
    vkkInsert,
    vkkDelete,
    vkkBack,
    vkkTab,
    vkkCaps,
    vkkEnter,
    vkkShift,
    vkkUp,
    vkkDown,
    vkkLeft,
    vkkRight,
    vkkCtrl,
    vkkAlt,
    vkkSpace,
    vkkHanEng
  );

  // 96DPI 기준 키 배치 (Left, Top, Width, Height)
  TSCVKeyRect = record
    Left, Top, Width, Height: Integer;
  end;

const
  KEY_RECTS: array[0..KEY_NUMS - 1] of TSCVKeyRect = (
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

  KEY_KINDS: array[0..KEY_NUMS - 1] of TSCVKeyKind = (
    vkkEsc, vkkHome, vkkEnd, vkkInsert, vkkDelete,
    vkkChar, vkkChar, vkkChar, vkkChar, vkkChar, vkkChar, vkkChar,
    vkkChar, vkkChar, vkkChar, vkkChar, vkkChar, vkkChar, vkkBack,
    vkkTab, vkkChar, vkkChar, vkkChar, vkkChar, vkkChar, vkkChar,
    vkkChar, vkkChar, vkkChar, vkkChar, vkkChar, vkkChar, vkkChar,
    vkkCaps, vkkChar, vkkChar, vkkChar, vkkChar, vkkChar, vkkChar,
    vkkChar, vkkChar, vkkChar, vkkChar, vkkChar, vkkEnter,
    vkkShift, vkkChar, vkkChar, vkkChar, vkkChar, vkkChar, vkkChar,
    vkkChar, vkkChar, vkkChar, vkkChar, vkkUp,
    vkkCtrl, vkkAlt, vkkSpace, vkkHanEng, vkkAlt, vkkLeft, vkkDown, vkkRight
  );

  // 문자 키: 1번째 문자 = 기본, 2번째 문자 = Shift (없으면 영문자는 대문자 규칙 적용)
  KEY_ENG: array[0..KEY_NUMS - 1] of string = (
    '', '', '', '', '',
    '`~', '1!', '2@', '3#', '4$', '5%', '6^', '7&', '8*', '9(', '0)', '-_', '=+', '',
    '', 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[{', ']}', '\|',
    '', 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';:', '''"', '',
    '', 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',<', '.>', '/?', '',
    '', '', '', '', '', '', '', ''
  );

  // 한글 자판 (빈 문자열이면 영문 표와 동일한 키)
  KEY_KOR: array[0..KEY_NUMS - 1] of string = (
    '', '', '', '', '',
    '', '', '', '', '', '', '', '', '', '', '', '', '', '',
    '', 'ㅂㅃ', 'ㅈㅉ', 'ㄷㄸ', 'ㄱㄲ', 'ㅅㅆ', 'ㅛ', 'ㅕ', 'ㅑ', 'ㅐㅒ', 'ㅔㅖ', '', '', '',
    '', 'ㅁ', 'ㄴ', 'ㅇ', 'ㄹ', 'ㅎ', 'ㅗ', 'ㅓ', 'ㅏ', 'ㅣ', '', '', '',
    '', 'ㅋ', 'ㅌ', 'ㅊ', 'ㅍ', 'ㅠ', 'ㅜ', 'ㅡ', '', '', '', '',
    '', '', '', '', '', '', '', ''
  );

  // 특수 키 표기
  KEY_CAPTION: array[0..KEY_NUMS - 1] of string = (
    'ESC', 'Home', 'End', 'Ins', 'Del',
    '', '', '', '', '', '', '', '', '', '', '', '', '', 'Back',
    'Tab', '', '', '', '', '', '', '', '', '', '', '', '', '',
    'Caps', '', '', '', '', '', '', '', '', '', '', '', 'Enter',
    'Shift', '', '', '', '', '', '', '', '', '', '', '↑',
    'Ctrl', 'Alt', 'Space', '한/영', 'Alt', '←', '↓', '→'
  );

type
  // Execute 시점에 동적으로 생성되는 키보드 폼 (CreateNew 로 코드 생성 — dfm 불필요)
  TSCVirtualKeyboardForm = class(TForm)
  private
    FCapsLock: Boolean;
    FColors: TSCKeyboardColors;
    FComposer: THangulComposer;
    FComposeStart: Integer;
    FComposing: string;
    FEdit: TEdit;
    FHotIndex: Integer;
    FKorean: Boolean;
    FLogicalHeight: Integer;
    FLogicalWidth: Integer;
    FPressedIndex: Integer;
    FShift: Boolean;
    FTitle: string;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure CommitComposition;
    procedure DrawKey(AIndex: Integer);
    procedure EditClick(Sender: TObject);
    procedure EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EditKeyPress(Sender: TObject; var Key: Char);
    function  GetEditText: string;
    procedure HandleBackspace;
    procedure InputChar(AIndex: Integer);
    procedure InputJamo(const AJamo: Char);
    procedure InsertText(const AText: string);
    function  KeyAtPos(X, Y: Integer): Integer;
    function  KeyScreenRect(AIndex: Integer): TRect;
    procedure PressKey(AIndex: Integer);
    function  ScaleMin(AValue: Integer): Integer;
    function  ScaleX(AValue: Integer): Integer;
    function  ScaleY(AValue: Integer): Integer;
    procedure SetColors(const AValue: TSCKeyboardColors);
    procedure SetEditText(const AValue: string);
  protected
    procedure ChangeScale(M, D: Integer; isDpiChange: Boolean); override;
    procedure DoShow; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Paint; override;
  public
    constructor Create(const ALogicalWidth, ALogicalHeight: Integer); reintroduce;
    destructor Destroy; override;
    property Colors: TSCKeyboardColors read FColors write SetColors;
    property EditText: string read GetEditText write SetEditText;
    property Korean: Boolean read FKorean write FKorean;
    property Title: string read FTitle write FTitle;
  end;

{$REGION 'TSCVirtualKeyboardForm'}

constructor TSCVirtualKeyboardForm.Create(const ALogicalWidth, ALogicalHeight: Integer);
begin
  inherited CreateNew(nil);

  FLogicalWidth := Max(MIN_FORM_W, ALogicalWidth);
  FLogicalHeight := Max(MIN_FORM_H, ALogicalHeight);

  FColors.Background := COLOR_FORM_BG;
  FColors.Border := COLOR_KEY_BORDER;
  FColors.Hot := COLOR_KEY_HOT;
  FColors.KeyFace := COLOR_KEY_FACE;
  FColors.KeyText := COLOR_KEY_TEXT;
  FColors.Pressed := COLOR_KEY_DOWN;
  FColors.SpecialKey := COLOR_KEY_SPEC;
  FColors.SubText := COLOR_KEY_SUB;
  FColors.TitleText := COLOR_TITLE_TEXT;
  FColors.Toggled := COLOR_KEY_ON;

  FComposer := THangulComposer.Create;
  FComposeStart := -1;
  FHotIndex := -1;
  FPressedIndex := -1;
  FKorean := True;

  BorderStyle := bsNone;
  Position := poScreenCenter;
  DoubleBuffered := True;
  Color := FColors.Background;
  Font.Name := 'Segoe UI';
  ClientWidth := ScaleX(FORM_W);
  ClientHeight := ScaleY(FORM_H);

  FEdit := TEdit.Create(Self);
  FEdit.Parent := Self;
  FEdit.BorderStyle := bsNone;
  FEdit.Color := clWhite;
  FEdit.Font.Name := '맑은 고딕';
  FEdit.Font.Height := -ScaleMin(24);
  FEdit.SetBounds(ScaleX(106), ScaleY(42), ScaleX(452), ScaleY(32));
  FEdit.OnClick := EditClick;
  FEdit.OnKeyDown := EditKeyDown;
  FEdit.OnKeyPress := EditKeyPress;
end;

destructor TSCVirtualKeyboardForm.Destroy;
begin
  FreeAndNil(FComposer);
  inherited Destroy;
end;

procedure TSCVirtualKeyboardForm.ChangeScale(M, D: Integer; isDpiChange: Boolean);
begin
  inherited ChangeScale(M, D, isDpiChange);

  // 키 배치는 매 페인트마다 FCurrentPPI 로 다시 계산하므로 다시 그리기만 하면 된다
  Invalidate;
end;

procedure TSCVirtualKeyboardForm.CMMouseLeave(var Msg: TMessage);
begin
  inherited;

  if FHotIndex <> -1 then
  begin
    FHotIndex := -1;
    Invalidate;
  end;
end;

// 조합 상태만 초기화한다. 조합 중이던 글자는 이미 에디트에 표시되어 있으므로 그대로 확정된다
procedure TSCVirtualKeyboardForm.CommitComposition;
begin
  FComposer.Reset;
  FComposing := '';
  FComposeStart := -1;
end;

procedure TSCVirtualKeyboardForm.DoShow;
begin
  inherited DoShow;

  ActiveControl := FEdit;
  FEdit.SelectAll;
end;

procedure TSCVirtualKeyboardForm.DrawKey(AIndex: Integer);
begin
  var LRect := KeyScreenRect(AIndex);
  var LKind := KEY_KINDS[AIndex];

  // 키 상태별 면 색상
  var LFace := FColors.KeyFace;
  if LKind <> vkkChar then
  begin
    LFace := FColors.SpecialKey;
  end;

  var LToggled :=
    ((LKind = vkkShift) and FShift) or
    ((LKind = vkkCaps) and FCapsLock) or
    ((LKind = vkkHanEng) and FKorean);
  if LToggled then
  begin
    LFace := FColors.Toggled;
  end;

  if AIndex = FHotIndex then
  begin
    LFace := FColors.Hot;
  end;

  if AIndex = FPressedIndex then
  begin
    LFace := FColors.Pressed;
  end;

  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := LFace;
  Canvas.Pen.Color := FColors.Border;
  Canvas.Pen.Width := 1;

  var LRadius := ScaleMin(6);
  Canvas.RoundRect(LRect.Left, LRect.Top, LRect.Right, LRect.Bottom, LRadius, LRadius);

  Canvas.Brush.Style := bsClear;

  if LKind = vkkChar then
  begin
    // 기본/Shift 문자 결정
    var LDef := KEY_ENG[AIndex];
    if FKorean and (KEY_KOR[AIndex] <> '') then
    begin
      LDef := KEY_KOR[AIndex];
    end;

    var LMain := LDef[1];
    var LSub := #0;
    if Length(LDef) > 1 then
    begin
      LSub := LDef[2];
    end;

    // 영문자는 대문자로 표기
    if CharInSet(LMain, ['a'..'z']) then
    begin
      LMain := UpCase(LMain);
    end;

    Canvas.Font.Name := 'Segoe UI';
    Canvas.Font.Color := FColors.KeyText;
    Canvas.Font.Height := -ScaleMin(17);
    Canvas.Font.Style := [];

    var LText: string := LMain;
    var LSize := Canvas.TextExtent(LText);
    if LSub = #0 then
    begin
      // 단일 문자: 중앙 배치
      Canvas.TextOut(
        LRect.Left + (LRect.Width - LSize.cx) div 2,
        LRect.Top + (LRect.Height - LSize.cy) div 2, LText);
    end
    else
    begin
      // Shift 문자는 위쪽에 작게, 기본 문자는 아래쪽에
      Canvas.TextOut(
        LRect.Left + (LRect.Width - LSize.cx) div 2,
        LRect.Top + (LRect.Height div 2) - ScaleY(2), LText);

      Canvas.Font.Color := FColors.SubText;
      Canvas.Font.Height := -ScaleMin(12);
      var LSubText: string := LSub;
      var LSubSize := Canvas.TextExtent(LSubText);
      Canvas.TextOut(
        LRect.Left + (LRect.Width - LSubSize.cx) div 2,
        LRect.Top + ScaleY(5), LSubText);
    end;
  end
  else
  begin
    Canvas.Font.Name := 'Segoe UI';
    Canvas.Font.Color := FColors.KeyText;
    Canvas.Font.Height := -ScaleMin(13);
    Canvas.Font.Style := [];

    var LCaption := KEY_CAPTION[AIndex];
    var LSize := Canvas.TextExtent(LCaption);
    Canvas.TextOut(
      LRect.Left + (LRect.Width - LSize.cx) div 2,
      LRect.Top + (LRect.Height - LSize.cy) div 2, LCaption);
  end;
end;

procedure TSCVirtualKeyboardForm.EditClick(Sender: TObject);
begin
  // 커서 위치가 바뀌면 조합 중이던 글자는 그대로 확정
  CommitComposition;
end;

procedure TSCVirtualKeyboardForm.EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  // 물리 키보드 입력·탐색 키가 들어오면 조합 상태와 어긋나므로 먼저 확정
  CommitComposition;
end;

procedure TSCVirtualKeyboardForm.EditKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    ModalResult := mrOk;
  end
  else
  if Key = #27 then
  begin
    Key := #0;
    ModalResult := mrCancel;
  end;
end;

function TSCVirtualKeyboardForm.GetEditText: string;
begin
  Result := FEdit.Text;
end;

procedure TSCVirtualKeyboardForm.HandleBackspace;
begin
  if FComposer.IsComposing then
  begin
    // 조합 중이면 자모 단위로 되돌린다
    FComposer.Backspace;
    var LComposing := FComposer.Composing;

    var LText := FEdit.Text;
    Delete(LText, FComposeStart + 1, Length(FComposing));
    Insert(LComposing, LText, FComposeStart + 1);
    FEdit.Text := LText;
    FEdit.SelStart := FComposeStart + Length(LComposing);

    FComposing := LComposing;
    if FComposing = '' then
    begin
      FComposeStart := -1;
    end;
  end
  else
  begin
    // 에디트 기본 백스페이스 동작 (선택 영역 삭제 포함)
    FEdit.Perform(WM_CHAR, 8, 0);
  end;
end;

procedure TSCVirtualKeyboardForm.InputChar(AIndex: Integer);
begin
  var LDef := KEY_ENG[AIndex];
  var LKorKey := FKorean and (KEY_KOR[AIndex] <> '');
  if LKorKey then
  begin
    LDef := KEY_KOR[AIndex];
  end;

  // Shift(1회성) / CapsLock 반영해 실제 입력 문자 결정
  var LChar := LDef[1];
  if FShift and (Length(LDef) > 1) then
  begin
    LChar := LDef[2];
  end;

  if CharInSet(LChar, ['a'..'z']) and (FShift xor FCapsLock) then
  begin
    LChar := UpCase(LChar);
  end;

  if FShift then
  begin
    FShift := False;
    Invalidate;
  end;

  if LKorKey and IsHangulJamo(LChar) then
  begin
    InputJamo(LChar);
  end
  else
  begin
    CommitComposition;
    InsertText(LChar);
  end;
end;

procedure TSCVirtualKeyboardForm.InputJamo(const AJamo: Char);
begin
  // 선택 영역이 있으면 먼저 삭제하고 그 자리에서 조합 시작
  if FEdit.SelLength > 0 then
  begin
    CommitComposition;
    FEdit.SelText := '';
  end;

  if FComposeStart < 0 then
  begin
    FComposeStart := FEdit.SelStart;
  end;

  var LCommitted: string;
  var LComposing := FComposer.Feed(AJamo, LCommitted);

  // 화면의 조합 중 글자를 (확정분 + 새 조합분)으로 교체
  var LText := FEdit.Text;
  Delete(LText, FComposeStart + 1, Length(FComposing));
  Insert(LCommitted + LComposing, LText, FComposeStart + 1);
  FEdit.Text := LText;

  FComposeStart := FComposeStart + Length(LCommitted);
  FComposing := LComposing;
  FEdit.SelStart := FComposeStart + Length(FComposing);

  if FComposing = '' then
  begin
    FComposeStart := -1;
  end;
end;

procedure TSCVirtualKeyboardForm.InsertText(const AText: string);
begin
  FEdit.SelText := AText;
end;

function TSCVirtualKeyboardForm.KeyAtPos(X, Y: Integer): Integer;
begin
  Result := -1;

  for var I := 0 to KEY_NUMS - 1 do
  begin
    if KeyScreenRect(I).Contains(Point(X, Y)) then
    begin
      Result := I;
      Break;
    end;
  end;
end;

function TSCVirtualKeyboardForm.KeyScreenRect(AIndex: Integer): TRect;
begin
  Result := TRect.Create(
    ScaleX(KEY_RECTS[AIndex].Left),
    ScaleY(KEY_RECTS[AIndex].Top),
    ScaleX(KEY_RECTS[AIndex].Left + KEY_RECTS[AIndex].Width),
    ScaleY(KEY_RECTS[AIndex].Top + KEY_RECTS[AIndex].Height));
end;

procedure TSCVirtualKeyboardForm.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);

  if Button <> mbLeft then
  begin
    Exit;
  end;

  var LIndex := KeyAtPos(X, Y);
  if LIndex >= 0 then
  begin
    FPressedIndex := LIndex;
    Invalidate;
    PressKey(LIndex);
  end
  else
  begin
    // 키 밖(제목 영역 등)을 잡으면 창 이동
    ReleaseCapture;
    Perform(WM_SYSCOMMAND, SC_MOVE or HTCAPTION, 0);
  end;
end;

procedure TSCVirtualKeyboardForm.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);

  var LIndex := KeyAtPos(X, Y);
  if LIndex <> FHotIndex then
  begin
    FHotIndex := LIndex;
    Invalidate;
  end;
end;

procedure TSCVirtualKeyboardForm.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);

  if FPressedIndex <> -1 then
  begin
    FPressedIndex := -1;
    Invalidate;
  end;
end;

procedure TSCVirtualKeyboardForm.Paint;
begin
  inherited Paint;

  // 제목
  Canvas.Brush.Style := bsClear;
  Canvas.Font.Name := 'Segoe UI';
  Canvas.Font.Color := FColors.TitleText;
  Canvas.Font.Height := -ScaleMin(13);
  Canvas.Font.Style := [fsBold];
  Canvas.TextOut(ScaleX(14), ScaleY(9), FTitle);
  Canvas.Font.Style := [];

  // 입력창 테두리
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := clWhite;
  Canvas.Pen.Color := FColors.Border;
  Canvas.Rectangle(ScaleX(100), ScaleY(36), ScaleX(564), ScaleY(80));

  // 키
  for var I := 0 to KEY_NUMS - 1 do
  begin
    DrawKey(I);
  end;
end;

procedure TSCVirtualKeyboardForm.PressKey(AIndex: Integer);
begin
  case KEY_KINDS[AIndex] of
    vkkChar:
      begin
        InputChar(AIndex);
      end;

    vkkBack:
      begin
        HandleBackspace;
      end;

    vkkEnter:
      begin
        CommitComposition;
        ModalResult := mrOk;
      end;

    vkkEsc:
      begin
        ModalResult := mrCancel;
      end;

    vkkShift:
      begin
        FShift := not FShift;
        Invalidate;
      end;

    vkkCaps:
      begin
        FCapsLock := not FCapsLock;
        Invalidate;
      end;

    vkkHanEng:
      begin
        CommitComposition;
        FKorean := not FKorean;
        Invalidate;
      end;

    vkkSpace:
      begin
        CommitComposition;
        InsertText(' ');
      end;

    vkkTab:
      begin
        CommitComposition;
      end;

    vkkHome, vkkEnd, vkkInsert, vkkDelete, vkkUp, vkkDown, vkkLeft, vkkRight:
      begin
        CommitComposition;

        var LVk: Word := VK_HOME;
        case KEY_KINDS[AIndex] of
          vkkEnd:    LVk := VK_END;
          vkkInsert: LVk := VK_INSERT;
          vkkDelete: LVk := VK_DELETE;
          vkkUp:     LVk := VK_UP;
          vkkDown:   LVk := VK_DOWN;
          vkkLeft:   LVk := VK_LEFT;
          vkkRight:  LVk := VK_RIGHT;
        end;

        FEdit.Perform(WM_KEYDOWN, LVk, 0);
        FEdit.Perform(WM_KEYUP, LVk, 0);
      end;

    vkkCtrl, vkkAlt:
      begin
        // 단독 에디트 입력에서는 의미가 없어 동작하지 않는다 (표시용)
      end;
  end;
end;

// 폰트·radius 등 왜곡되면 안 되는 값은 두 축 중 작은 배율을 따른다
function TSCVirtualKeyboardForm.ScaleMin(AValue: Integer): Integer;
begin
  Result := Min(ScaleX(AValue), ScaleY(AValue));
end;

// 96DPI·기본 폭(FORM_W) 기준 논리값을 요청 폭과 현재 모니터 DPI 로 스케일
function TSCVirtualKeyboardForm.ScaleX(AValue: Integer): Integer;
begin
  Result := MulDiv(AValue, FLogicalWidth * CurrentPPI, FORM_W * 96);
end;

// 96DPI·기본 높이(FORM_H) 기준 논리값을 요청 높이와 현재 모니터 DPI 로 스케일
function TSCVirtualKeyboardForm.ScaleY(AValue: Integer): Integer;
begin
  Result := MulDiv(AValue, FLogicalHeight * CurrentPPI, FORM_H * 96);
end;

procedure TSCVirtualKeyboardForm.SetColors(const AValue: TSCKeyboardColors);
begin
  FColors := AValue;
  Color := FColors.Background;
  Invalidate;
end;

procedure TSCVirtualKeyboardForm.SetEditText(const AValue: string);
begin
  FEdit.Text := AValue;
end;

{$ENDREGION}

{$REGION 'TSCVirtualKeyboard'}

constructor TSCVirtualKeyboard.Create;
begin
  inherited Create;

  FBackgroundColor := COLOR_FORM_BG;
  FBorderColor := COLOR_KEY_BORDER;
  FHeight := FORM_H;
  FHotColor := COLOR_KEY_HOT;
  FKeyColor := COLOR_KEY_FACE;
  FKeyTextColor := COLOR_KEY_TEXT;
  FLanguage := klKorean;
  FPasswordChar := #0;
  FPosition := kpScreenCenter;
  FPressedColor := COLOR_KEY_DOWN;
  FSpecialKeyColor := COLOR_KEY_SPEC;
  FSubTextColor := COLOR_KEY_SUB;
  FTitle := '가상 키보드';
  FTitleTextColor := COLOR_TITLE_TEXT;
  FToggledColor := COLOR_KEY_ON;
  FWidth := FORM_W;
end;

class destructor TSCVirtualKeyboard.Destroy;
begin
  FreeAndNil(FInstance);
end;

function TSCVirtualKeyboard.Execute(var AText: string): Boolean;
begin
  Result := Execute(AText, FWidth, FHeight);
end;

function TSCVirtualKeyboard.Execute(var AText: string; const AWidth, AHeight: Integer): Boolean;
begin
  // 0 이하 파라미터는 프로퍼티 기본값 사용
  var LWidth := AWidth;
  if LWidth <= 0 then
  begin
    LWidth := FWidth;
  end;

  var LHeight := AHeight;
  if LHeight <= 0 then
  begin
    LHeight := FHeight;
  end;

  var LColors: TSCKeyboardColors;
  LColors.Background := FBackgroundColor;
  LColors.Border := FBorderColor;
  LColors.Hot := FHotColor;
  LColors.KeyFace := FKeyColor;
  LColors.KeyText := FKeyTextColor;
  LColors.Pressed := FPressedColor;
  LColors.SpecialKey := FSpecialKeyColor;
  LColors.SubText := FSubTextColor;
  LColors.TitleText := FTitleTextColor;
  LColors.Toggled := FToggledColor;

  var LForm := TSCVirtualKeyboardForm.Create(LWidth, LHeight);
  try
    LForm.Colors := LColors;
    LForm.Korean := FLanguage = klKorean;
    LForm.Title := FTitle;
    LForm.EditText := AText;
    if FPasswordChar <> #0 then
    begin
      LForm.FEdit.PasswordChar := FPasswordChar;
    end;

    // 표시 위치 적용
    case FPosition of
      kpScreenCenter:
        begin
          LForm.Position := poScreenCenter;
        end;

      kpMainFormCenter:
        begin
          LForm.Position := poMainFormCenter;
        end;

      kpCustom:
        begin
          // 지정 좌표가 모니터 작업 영역을 벗어나지 않게 보정
          LForm.Position := poDesigned;
          var LWork := Screen.MonitorFromPoint(Point(FCustomLeft, FCustomTop)).WorkareaRect;
          LForm.Left := Max(LWork.Left, Min(FCustomLeft, LWork.Right - LForm.Width));
          LForm.Top := Max(LWork.Top, Min(FCustomTop, LWork.Bottom - LForm.Height));
        end;
    end;

    Result := LForm.ShowModal = mrOk;
    if Result then
    begin
      AText := LForm.EditText;
    end;
  finally
    LForm.Free;
  end;
end;

class function TSCVirtualKeyboard.GetInstance: TSCVirtualKeyboard;
begin
  if not Assigned(FInstance) then
  begin
    FInstance := TSCVirtualKeyboard.Create;
  end;

  Result := FInstance;
end;

procedure TSCVirtualKeyboard.SetCustomPosition(const ALeft, ATop: Integer);
begin
  FCustomLeft := ALeft;
  FCustomTop := ATop;
  FPosition := kpCustom;
end;

{$ENDREGION}

end.
