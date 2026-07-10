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
  Winapi.MMSystem,
  Winapi.ShellAPI,
  Winapi.Dwmapi,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
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
    FClickSound: Boolean;
    FCustomLeft: Integer;
    FCustomTop: Integer;
    FHeight: Integer;
    FHotColor: TColor;
    FKeyColor: TColor;
    FKeyTextColor: TColor;
    FLanguage: TSCKeyboardLanguage;
    FMaxLength: Integer;
    FPasswordChar: Char;
    FPosition: TSCKeyboardPosition;
    FPressedColor: TColor;
    FSpecialKeyColor: TColor;
    FSubTextColor: TColor;
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
    /// <summary>키를 클릭할 때 클릭음을 재생할지 여부 (기본 False).
    /// 클릭음은 내부에서 합성한 짧은 사운드로, 별도 리소스나 파일이 필요 없습니다.</summary>
    property ClickSound: Boolean read FClickSound write FClickSound;
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
    /// <summary>입력 가능한 최대 문자 수 (조합 중인 글자 포함). 0 이면 무제한 (기본).
    /// 한도에 도달하면 추가 입력이 무시됩니다.</summary>
    property MaxLength: Integer read FMaxLength write FMaxLength;
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

  // 96DPI 기준 폼 논리 크기 (기본값·스케일 기준). 하단 32px 는 크레딧 표시 영역
  FORM_W = 800;
  FORM_H = 376;

  // 96DPI 기준 최소 논리 크기 (이보다 작으면 키를 조작할 수 없어 보정)
  MIN_FORM_W = 400;
  MIN_FORM_H = 188;

  // 우하단 크레딧 (클릭 시 저장소로 이동)
  CREDIT_TEXT = '@시골프로그래머';
  CREDIT_URL  = 'https://github.com/civilian7/DelphiKeyboard';

  // 기본 색상 팔레트
  COLOR_FORM_BG    = TColor($00EEF0F2);   // 폼 배경 (밝은 웜그레이)
  COLOR_KEY_FACE   = TColor($00FDFDFD);   // 일반 키 면
  COLOR_KEY_SPEC   = TColor($00DDE1E4);   // 특수 키 면
  COLOR_KEY_BORDER = TColor($00C8CCD0);   // 키 테두리
  COLOR_KEY_HOT    = TColor($00F2E8DA);   // 마우스 오버
  COLOR_KEY_DOWN   = TColor($00E0C9A8);   // 눌림
  COLOR_KEY_ON     = TColor($00A8D8F8);   // 토글 활성 (Shift/Caps/한영)
  COLOR_KEY_TEXT   = TColor($00303030);   // 키 글자
  COLOR_KEY_SUB    = TColor($00909498);   // Shift 보조 글자·크레딧

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
    (Left: 12;  Top: 13; Width: 74;  Height: 48), (Left: 578; Top: 13; Width: 48;  Height: 48),
    (Left: 632; Top: 13; Width: 48;  Height: 48), (Left: 686; Top: 13; Width: 48;  Height: 48),
    (Left: 740; Top: 13; Width: 48;  Height: 48),

    (Left: 12;  Top: 75; Width: 48;  Height: 48), (Left: 66;  Top: 75; Width: 48;  Height: 48),
    (Left: 120; Top: 75; Width: 48;  Height: 48), (Left: 174; Top: 75; Width: 48;  Height: 48),
    (Left: 228; Top: 75; Width: 48;  Height: 48), (Left: 282; Top: 75; Width: 48;  Height: 48),
    (Left: 336; Top: 75; Width: 48;  Height: 48), (Left: 390; Top: 75; Width: 48;  Height: 48),
    (Left: 444; Top: 75; Width: 48;  Height: 48), (Left: 498; Top: 75; Width: 48;  Height: 48),
    (Left: 552; Top: 75; Width: 48;  Height: 48), (Left: 606; Top: 75; Width: 48;  Height: 48),
    (Left: 660; Top: 75; Width: 48;  Height: 48), (Left: 714; Top: 75; Width: 74;  Height: 48),

    (Left: 12;  Top: 130; Width: 74;  Height: 48), (Left: 92;  Top: 130; Width: 48;  Height: 48),
    (Left: 146; Top: 130; Width: 48;  Height: 48), (Left: 200; Top: 130; Width: 48;  Height: 48),
    (Left: 254; Top: 130; Width: 48;  Height: 48), (Left: 308; Top: 130; Width: 48;  Height: 48),
    (Left: 362; Top: 130; Width: 48;  Height: 48), (Left: 416; Top: 130; Width: 48;  Height: 48),
    (Left: 470; Top: 130; Width: 48;  Height: 48), (Left: 524; Top: 130; Width: 48;  Height: 48),
    (Left: 578; Top: 130; Width: 48;  Height: 48), (Left: 632; Top: 130; Width: 48;  Height: 48),
    (Left: 686; Top: 130; Width: 48;  Height: 48), (Left: 740; Top: 130; Width: 48;  Height: 48),

    (Left: 12;  Top: 185; Width: 88;  Height: 48), (Left: 106; Top: 185; Width: 48;  Height: 48),
    (Left: 160; Top: 185; Width: 48;  Height: 48), (Left: 214; Top: 185; Width: 48;  Height: 48),
    (Left: 268; Top: 185; Width: 48;  Height: 48), (Left: 322; Top: 185; Width: 48;  Height: 48),
    (Left: 376; Top: 185; Width: 48;  Height: 48), (Left: 430; Top: 185; Width: 48;  Height: 48),
    (Left: 484; Top: 185; Width: 48;  Height: 48), (Left: 538; Top: 185; Width: 48;  Height: 48),
    (Left: 592; Top: 185; Width: 48;  Height: 48), (Left: 646; Top: 185; Width: 48;  Height: 48),
    (Left: 701; Top: 185; Width: 87;  Height: 48),

    (Left: 12;  Top: 240; Width: 115; Height: 48), (Left: 133; Top: 240; Width: 48;  Height: 48),
    (Left: 187; Top: 240; Width: 48;  Height: 48), (Left: 241; Top: 240; Width: 48;  Height: 48),
    (Left: 295; Top: 240; Width: 48;  Height: 48), (Left: 349; Top: 240; Width: 48;  Height: 48),
    (Left: 403; Top: 240; Width: 48;  Height: 48), (Left: 457; Top: 240; Width: 48;  Height: 48),
    (Left: 511; Top: 240; Width: 48;  Height: 48), (Left: 565; Top: 240; Width: 48;  Height: 48),
    (Left: 619; Top: 240; Width: 48;  Height: 48), (Left: 686; Top: 240; Width: 48;  Height: 48),

    (Left: 12;  Top: 296; Width: 74;  Height: 48), (Left: 92;  Top: 296; Width: 74;  Height: 48),
    (Left: 176; Top: 296; Width: 282; Height: 48), (Left: 468; Top: 296; Width: 74;  Height: 48),
    (Left: 548; Top: 296; Width: 74;  Height: 48), (Left: 632; Top: 296; Width: 48;  Height: 48),
    (Left: 686; Top: 296; Width: 48;  Height: 48), (Left: 740; Top: 296; Width: 48;  Height: 48)
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
  // 입력 표시는 별도 에디트 컨트롤 없이 폼이 직접 렌더링한다
  // (확정 문자는 일반 표시, 조합 중 문자는 반전 블록으로 표시)
  TSCVirtualKeyboardForm = class(TForm)
  private
    FCapsLock: Boolean;
    FCaret: Integer;               // 확정 텍스트(FText) 안의 삽입 위치 (0..Length)
    FClearHot: Boolean;
    FClearRect: TRect;
    FClickSound: Boolean;
    FColors: TSCKeyboardColors;
    FComposer: THangulComposer;
    FComposing: string;            // 조합 중인 글자 (캐럿 위치에 반전 표시, 아직 FText 에 없음)
    FCreditHot: Boolean;
    FCreditRect: TRect;
    FHotIndex: Integer;
    FInputRect: TRect;
    FKorean: Boolean;
    FLogicalHeight: Integer;
    FLogicalWidth: Integer;
    FMaxLength: Integer;
    FPasswordChar: Char;
    FPressedIndex: Integer;
    FShift: Boolean;
    FText: string;                 // 확정된 텍스트
    procedure ApplyRoundedCorners;
    function  CaretFromX(AX: Integer): Integer;
    procedure ClearAll;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure CommitComposition;
    procedure DrawInput;
    procedure DrawKey(AIndex: Integer);
    function  GetEditText: string;
    procedure HandleBackspace;
    procedure HandleNavKey(const AVk: Word);
    procedure InputChar(AIndex: Integer);
    procedure InputJamo(const AJamo: Char);
    procedure InsertText(const AText: string);
    function  KeyAtPos(X, Y: Integer): Integer;
    function  KeyScreenRect(AIndex: Integer): TRect;
    function  MaskText(const AText: string): string;
    procedure PressKey(AIndex: Integer);
    function  ScaleMin(AValue: Integer): Integer;
    function  ScaleX(AValue: Integer): Integer;
    function  ScaleY(AValue: Integer): Integer;
    procedure SetColors(const AValue: TSCKeyboardColors);
    procedure SetEditText(const AValue: string);
    procedure SetInputFont;
    function  TotalLength: Integer;
  protected
    procedure ChangeScale(M, D: Integer; isDpiChange: Boolean); override;
    procedure CreateWnd; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(const ALogicalWidth, ALogicalHeight: Integer); reintroduce;
    destructor Destroy; override;
    property ClickSound: Boolean read FClickSound write FClickSound;
    property Colors: TSCKeyboardColors read FColors write SetColors;
    property EditText: string read GetEditText write SetEditText;
    property Korean: Boolean read FKorean write FKorean;
    property MaxLength: Integer read FMaxLength write FMaxLength;
    property PasswordChar: Char read FPasswordChar write FPasswordChar;
  end;

var
  // 합성된 클릭음 WAV (프로세스 수명 동안 유지 — SND_ASYNC 재생 중 해제 방지)
  GClickWav: TBytes;

// 짧은 클릭음을 메모리에서 합성해 비동기 재생한다 (리소스·파일 불필요)
procedure PlayClickSound;
const
  SAMPLE_RATE = 44100;                              // 샘플레이트 (Hz)
  CLICK_MS = 28;                                    // 클릭음 길이 (밀리초)
  DATA_OFFSET = 44;                                 // WAV 헤더 크기
begin
  if Length(GClickWav) = 0 then
  begin
    var LSampleCount := SAMPLE_RATE * CLICK_MS div 1000;
    var LDataSize := LSampleCount * SizeOf(SmallInt);
    SetLength(GClickWav, DATA_OFFSET + LDataSize);

    // RIFF/WAVE 헤더 (PCM 16비트 모노)
    PCardinal(@GClickWav[0])^ := $46464952;                       // 'RIFF'
    PCardinal(@GClickWav[4])^ := DATA_OFFSET - 8 + LDataSize;     // 파일 크기 - 8
    PCardinal(@GClickWav[8])^ := $45564157;                       // 'WAVE'
    PCardinal(@GClickWav[12])^ := $20746D66;                      // 'fmt '
    PCardinal(@GClickWav[16])^ := 16;                             // fmt 청크 크기
    PWord(@GClickWav[20])^ := 1;                                  // PCM
    PWord(@GClickWav[22])^ := 1;                                  // 모노
    PCardinal(@GClickWav[24])^ := SAMPLE_RATE;
    PCardinal(@GClickWav[28])^ := SAMPLE_RATE * SizeOf(SmallInt); // 초당 바이트
    PWord(@GClickWav[32])^ := SizeOf(SmallInt);                   // 블록 정렬
    PWord(@GClickWav[34])^ := 16;                                 // 샘플 비트수
    PCardinal(@GClickWav[36])^ := $61746164;                      // 'data'
    PCardinal(@GClickWav[40])^ := LDataSize;

    // 급감쇠 사인파 — 기계식 키 클릭과 유사한 톤
    for var I := 0 to LSampleCount - 1 do
    begin
      var LTime := I / SAMPLE_RATE;
      var LSample := Round(32767 * 0.32 * Sin(2 * Pi * 1750 * LTime) * Exp(-LTime / 0.005));
      PSmallInt(@GClickWav[DATA_OFFSET + I * SizeOf(SmallInt)])^ := SmallInt(LSample);
    end;
  end;

  PlaySound(PChar(@GClickWav[0]), 0, SND_MEMORY or SND_ASYNC or SND_NODEFAULT);
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
  FColors.Toggled := COLOR_KEY_ON;

  FComposer := THangulComposer.Create;
  FHotIndex := -1;
  FPressedIndex := -1;
  FKorean := True;
  FPasswordChar := #0;

  BorderStyle := bsNone;
  Position := poScreenCenter;
  DoubleBuffered := True;
  Color := FColors.Background;
  Font.Name := 'Segoe UI';
  ClientWidth := ScaleX(FORM_W);
  ClientHeight := ScaleY(FORM_H);
end;

destructor TSCVirtualKeyboardForm.Destroy;
begin
  FreeAndNil(FComposer);
  inherited Destroy;
end;

// 테두리 없는 폼에 둥근 모서리를 적용한다
procedure TSCVirtualKeyboardForm.ApplyRoundedCorners;
const
  DWMWA_WINDOW_CORNER_PREFERENCE = 33;   // Windows 11 (Dwmapi 헤더 미정의 대비 자체 선언)
  DWMWCP_ROUND = 2;
begin
  if not HandleAllocated then
  begin
    Exit;
  end;

  // Windows 11: DWM 이 안티앨리어싱된 둥근 모서리를 그려준다
  var LPreference: Cardinal := DWMWCP_ROUND;
  if Succeeded(DwmSetWindowAttribute(Handle, DWMWA_WINDOW_CORNER_PREFERENCE,
    @LPreference, SizeOf(LPreference))) then
  begin
    Exit;
  end;

  // Windows 10 이하: 윈도우 영역으로 폴백 (SetWindowRgn 에 넘긴 리전은 OS 가 소유하므로 해제 금지)
  var LDiameter := ScaleMin(16);
  SetWindowRgn(Handle, CreateRoundRectRgn(0, 0, Width + 1, Height + 1, LDiameter, LDiameter), True);
end;

// 입력 상자 안의 클릭 X 좌표에서 가장 가까운 캐럿 위치를 구한다
function TSCVirtualKeyboardForm.CaretFromX(AX: Integer): Integer;
begin
  SetInputFont;

  var LDisplay := MaskText(FText);
  var LTarget := AX - (FInputRect.Left + ScaleX(8));
  Result := Length(LDisplay);

  for var I := 1 to Length(LDisplay) do
  begin
    var LPrev := Canvas.TextWidth(Copy(LDisplay, 1, I - 1));
    var LCur := Canvas.TextWidth(Copy(LDisplay, 1, I));
    if LTarget < (LPrev + LCur) div 2 then
    begin
      Result := I - 1;
      Break;
    end;
  end;
end;

procedure TSCVirtualKeyboardForm.ChangeScale(M, D: Integer; isDpiChange: Boolean);
begin
  inherited ChangeScale(M, D, isDpiChange);

  // 키 배치는 매 페인트마다 FCurrentPPI 로 다시 계산하므로 다시 그리기만 하면 된다
  Invalidate;
end;

// 입력된 텍스트와 조합 상태를 모두 지운다 (✕ 버튼)
procedure TSCVirtualKeyboardForm.ClearAll;
begin
  FComposer.Reset;
  FComposing := '';
  FText := '';
  FCaret := 0;
  Invalidate;
end;

procedure TSCVirtualKeyboardForm.CMMouseLeave(var Msg: TMessage);
begin
  inherited;

  if (FHotIndex <> -1) or FCreditHot or FClearHot then
  begin
    FHotIndex := -1;
    FClearHot := False;
    FCreditHot := False;
    Cursor := crDefault;
    Invalidate;
  end;
end;

// 조합 중이던 글자를 확정 텍스트로 옮기고 조합 상태를 초기화한다
procedure TSCVirtualKeyboardForm.CommitComposition;
begin
  if FComposing <> '' then
  begin
    Insert(FComposing, FText, FCaret + 1);
    Inc(FCaret, Length(FComposing));
    FComposing := '';
    Invalidate;
  end;

  FComposer.Reset;
end;

procedure TSCVirtualKeyboardForm.CreateWnd;
begin
  inherited CreateWnd;

  ApplyRoundedCorners;
end;

// 입력 표시 상자를 그린다: 확정 텍스트 + 조합 중 글자(반전) + 캐럿 + 전체 지움(✕) 버튼
procedure TSCVirtualKeyboardForm.DrawInput;
begin
  FInputRect := TRect.Create(ScaleX(100), ScaleY(16), ScaleX(564), ScaleY(60));

  // 상자 배경·테두리
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := clWhite;
  Canvas.Pen.Color := FColors.Border;
  Canvas.Pen.Width := 1;
  Canvas.Rectangle(FInputRect);

  // 전체 지움(✕) 버튼 — 상자 우측
  var LClearSize := ScaleMin(18);
  var LClearLeft := FInputRect.Right - ScaleX(10) - LClearSize;
  var LClearTop := FInputRect.Top + (FInputRect.Height - LClearSize) div 2;
  FClearRect := TRect.Create(LClearLeft, LClearTop, LClearLeft + LClearSize, LClearTop + LClearSize);

  if FClearHot then
  begin
    Canvas.Pen.Color := FColors.KeyText;
  end
  else
  begin
    Canvas.Pen.Color := FColors.SubText;
  end;

  Canvas.Pen.Width := Max(1, ScaleMin(2));
  var LGap := LClearSize div 4;
  Canvas.MoveTo(FClearRect.Left + LGap, FClearRect.Top + LGap);
  Canvas.LineTo(FClearRect.Right - LGap, FClearRect.Bottom - LGap);
  Canvas.MoveTo(FClearRect.Right - LGap, FClearRect.Top + LGap);
  Canvas.LineTo(FClearRect.Left + LGap, FClearRect.Bottom - LGap);
  Canvas.Pen.Width := 1;

  // 텍스트 (암호 모드면 마스킹). 캐럿이 항상 보이도록 넘치면 왼쪽으로 스크롤
  SetInputFont;

  var LBefore := MaskText(Copy(FText, 1, FCaret));
  var LComp := MaskText(FComposing);
  var LAfter := MaskText(Copy(FText, FCaret + 1, MaxInt));

  var LTextLeft := FInputRect.Left + ScaleX(8);
  var LAvail := FClearRect.Left - ScaleX(8) - LTextLeft;
  var LBeforeW := Canvas.TextWidth(LBefore);
  var LCompW := Canvas.TextWidth(LComp);
  var LOffset := Max(0, LBeforeW + LCompW - LAvail);

  var LSaveDC := SaveDC(Canvas.Handle);
  try
    IntersectClipRect(Canvas.Handle, LTextLeft, FInputRect.Top + 1,
      LTextLeft + LAvail + 1, FInputRect.Bottom - 1);

    var LY := FInputRect.Top + (FInputRect.Height - Canvas.TextHeight('가')) div 2;
    var LX := LTextLeft - LOffset;

    // 캐럿 앞 확정 텍스트
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Color := FColors.KeyText;
    Canvas.TextOut(LX, LY, LBefore);
    Inc(LX, LBeforeW);

    if LComp <> '' then
    begin
      // 조합 중 글자는 반전 블록으로 표시 (블록 자체가 캐럿 역할)
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := FColors.KeyText;
      Canvas.Font.Color := clWhite;
      Canvas.TextOut(LX, LY, LComp);
      Inc(LX, LCompW);
      Canvas.Brush.Style := bsClear;
      Canvas.Font.Color := FColors.KeyText;
    end
    else
    begin
      // 조합 중이 아니면 세로선 캐럿
      Canvas.Pen.Color := FColors.KeyText;
      Canvas.MoveTo(LX, FInputRect.Top + ScaleY(7));
      Canvas.LineTo(LX, FInputRect.Bottom - ScaleY(7));
    end;

    // 캐럿 뒤 확정 텍스트
    Canvas.TextOut(LX, LY, LAfter);
  finally
    RestoreDC(Canvas.Handle, LSaveDC);
  end;
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

function TSCVirtualKeyboardForm.GetEditText: string;
begin
  // 조합 중인 글자도 입력된 것으로 취급한다
  Result := FText;
  Insert(FComposing, Result, FCaret + 1);
end;

procedure TSCVirtualKeyboardForm.HandleBackspace;
begin
  if FComposer.IsComposing then
  begin
    // 조합 중이면 자모 단위로 되돌린다
    FComposer.Backspace;
    FComposing := FComposer.Composing;
    Invalidate;
  end
  else
  if FCaret > 0 then
  begin
    Delete(FText, FCaret, 1);
    Dec(FCaret);
    Invalidate;
  end;
end;

// 탐색·삭제 키 처리 (가상 키와 물리 키 공용). 조합 중이던 글자는 먼저 확정된다
procedure TSCVirtualKeyboardForm.HandleNavKey(const AVk: Word);
begin
  CommitComposition;

  case AVk of
    VK_LEFT:
      begin
        FCaret := Max(0, FCaret - 1);
      end;

    VK_RIGHT:
      begin
        FCaret := Min(Length(FText), FCaret + 1);
      end;

    VK_HOME:
      begin
        FCaret := 0;
      end;

    VK_END:
      begin
        FCaret := Length(FText);
      end;

    VK_DELETE:
      begin
        if FCaret < Length(FText) then
        begin
          Delete(FText, FCaret + 1, 1);
        end;
      end;
  end;

  Invalidate;
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
  // 새 글자를 시작할 자리가 없으면 입력을 무시한다
  if (FMaxLength > 0) and not FComposer.IsComposing and (TotalLength >= FMaxLength) then
  begin
    Exit;
  end;

  var LCommitted: string;
  var LComposing := FComposer.Feed(AJamo, LCommitted);

  // 조합 분리로 글자 수가 한도를 넘으면 새로 시작된 조합만 버린다 (기존 조합 확정분은 유지)
  if (FMaxLength > 0) and (Length(FText) + Length(LCommitted) + Length(LComposing) > FMaxLength) then
  begin
    FComposer.Reset;
    LComposing := '';
  end;

  // 확정분은 캐럿 위치의 확정 텍스트로 옮기고, 조합분은 반전 표시용으로 유지
  Insert(LCommitted, FText, FCaret + 1);
  Inc(FCaret, Length(LCommitted));
  FComposing := LComposing;
  Invalidate;
end;

// 캐럿 위치에 텍스트를 삽입한다 (호출 전 조합 확정 필요). MaxLength 초과분은 잘린다
procedure TSCVirtualKeyboardForm.InsertText(const AText: string);
begin
  var LText := AText;
  if FMaxLength > 0 then
  begin
    var LAvail := FMaxLength - TotalLength;
    if LAvail <= 0 then
    begin
      Exit;
    end;

    if Length(LText) > LAvail then
    begin
      SetLength(LText, LAvail);
    end;
  end;

  Insert(LText, FText, FCaret + 1);
  Inc(FCaret, Length(LText));
  Invalidate;
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

// 물리 키보드 탐색·삭제 키 (마우스 전용 도구지만 물리 입력도 보조 지원)
procedure TSCVirtualKeyboardForm.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);

  case Key of
    VK_LEFT, VK_RIGHT, VK_HOME, VK_END, VK_DELETE:
      begin
        HandleNavKey(Key);
      end;
  end;
end;

// 물리 키보드 문자 입력 (조합 오토마타를 거치지 않고 문자 그대로 삽입)
procedure TSCVirtualKeyboardForm.KeyPress(var Key: Char);
begin
  inherited KeyPress(Key);

  if Key = #13 then
  begin
    CommitComposition;
    ModalResult := mrOk;
  end
  else
  if Key = #27 then
  begin
    ModalResult := mrCancel;
  end
  else
  if Key = #8 then
  begin
    HandleBackspace;
  end
  else
  if Key >= ' ' then
  begin
    CommitComposition;
    InsertText(Key);
  end;

  Key := #0;
end;

function TSCVirtualKeyboardForm.KeyScreenRect(AIndex: Integer): TRect;
begin
  Result := TRect.Create(
    ScaleX(KEY_RECTS[AIndex].Left),
    ScaleY(KEY_RECTS[AIndex].Top),
    ScaleX(KEY_RECTS[AIndex].Left + KEY_RECTS[AIndex].Width),
    ScaleY(KEY_RECTS[AIndex].Top + KEY_RECTS[AIndex].Height));
end;

// 암호 모드(PasswordChar 지정)면 문자를 마스킹해서 표시한다
function TSCVirtualKeyboardForm.MaskText(const AText: string): string;
begin
  if FPasswordChar = #0 then
  begin
    Result := AText;
  end
  else
  begin
    Result := StringOfChar(FPasswordChar, Length(AText));
  end;
end;

procedure TSCVirtualKeyboardForm.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);

  if Button <> mbLeft then
  begin
    Exit;
  end;

  // 우하단 크레딧 클릭 → 저장소 페이지 열기
  if FCreditRect.Contains(Point(X, Y)) then
  begin
    ShellExecute(0, 'open', CREDIT_URL, nil, nil, SW_SHOWNORMAL);
    Exit;
  end;

  // 전체 지움(✕) 버튼
  if FClearRect.Contains(Point(X, Y)) then
  begin
    if FClickSound then
    begin
      PlayClickSound;
    end;

    ClearAll;
    Exit;
  end;

  // 입력 상자 클릭 → 캐럿 이동 (조합 중이던 글자는 확정)
  if FInputRect.Contains(Point(X, Y)) then
  begin
    CommitComposition;
    FCaret := CaretFromX(X);
    Invalidate;
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
    // 키 밖(여백 영역)을 잡으면 창 이동
    ReleaseCapture;
    Perform(WM_SYSCOMMAND, SC_MOVE or HTCAPTION, 0);
  end;
end;

procedure TSCVirtualKeyboardForm.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);

  var LIndex := KeyAtPos(X, Y);
  var LCreditHot := FCreditRect.Contains(Point(X, Y));
  var LClearHot := FClearRect.Contains(Point(X, Y));
  if (LIndex <> FHotIndex) or (LCreditHot <> FCreditHot) or (LClearHot <> FClearHot) then
  begin
    FHotIndex := LIndex;
    FClearHot := LClearHot;
    FCreditHot := LCreditHot;
    if FCreditHot or FClearHot then
    begin
      Cursor := crHandPoint;
    end
    else
    begin
      Cursor := crDefault;
    end;

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

  // 입력 표시 상자
  DrawInput;

  // 키
  for var I := 0 to KEY_NUMS - 1 do
  begin
    DrawKey(I);
  end;

  // 우하단 크레딧 (클릭 시 저장소로 이동, 호버 시 밑줄)
  Canvas.Brush.Style := bsClear;
  Canvas.Font.Name := 'Segoe UI';
  Canvas.Font.Color := FColors.SubText;
  Canvas.Font.Height := -ScaleMin(12);
  if FCreditHot then
  begin
    Canvas.Font.Style := [fsUnderline];
  end
  else
  begin
    Canvas.Font.Style := [];
  end;

  var LCreditSize := Canvas.TextExtent(CREDIT_TEXT);
  var LCreditLeft := ClientWidth - ScaleX(14) - LCreditSize.cx;
  var LCreditTop := ScaleY(344) + (ClientHeight - ScaleY(344) - LCreditSize.cy) div 2;
  FCreditRect := TRect.Create(LCreditLeft, LCreditTop, LCreditLeft + LCreditSize.cx, LCreditTop + LCreditSize.cy);
  Canvas.TextOut(LCreditLeft, LCreditTop, CREDIT_TEXT);
  Canvas.Font.Style := [];
end;

procedure TSCVirtualKeyboardForm.PressKey(AIndex: Integer);
begin
  if FClickSound then
  begin
    PlayClickSound;
  end;

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

    vkkHome, vkkEnd, vkkDelete, vkkLeft, vkkRight:
      begin
        var LVk: Word := VK_HOME;
        case KEY_KINDS[AIndex] of
          vkkEnd:    LVk := VK_END;
          vkkDelete: LVk := VK_DELETE;
          vkkLeft:   LVk := VK_LEFT;
          vkkRight:  LVk := VK_RIGHT;
        end;

        HandleNavKey(LVk);
      end;

    vkkInsert, vkkUp, vkkDown:
      begin
        // 한 줄 입력에서는 의미가 없다 — 조합 중이던 글자만 확정
        CommitComposition;
      end;

    vkkCtrl, vkkAlt:
      begin
        // 단독 입력 도구에서는 의미가 없어 동작하지 않는다 (표시용)
      end;
  end;
end;

procedure TSCVirtualKeyboardForm.Resize;
begin
  inherited Resize;

  // DPI 변경 등으로 창 크기가 바뀌면 둥근 모서리 영역을 다시 적용
  ApplyRoundedCorners;
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
  FComposer.Reset;
  FComposing := '';
  FText := AValue;
  if (FMaxLength > 0) and (Length(FText) > FMaxLength) then
  begin
    SetLength(FText, FMaxLength);
  end;

  FCaret := Length(FText);
  Invalidate;
end;

// 입력 표시용 폰트를 캔버스에 설정한다 (그리기·캐럿 좌표 계산 공용)
procedure TSCVirtualKeyboardForm.SetInputFont;
begin
  Canvas.Font.Name := '맑은 고딕';
  Canvas.Font.Height := -ScaleMin(24);
  Canvas.Font.Style := [];
end;

// 현재 입력된 총 글자 수 (조합 중인 글자 포함)
function TSCVirtualKeyboardForm.TotalLength: Integer;
begin
  Result := Length(FText) + Length(FComposing);
end;

{$ENDREGION}

{$REGION 'TSCVirtualKeyboard'}

constructor TSCVirtualKeyboard.Create;
begin
  inherited Create;

  FBackgroundColor := COLOR_FORM_BG;
  FBorderColor := COLOR_KEY_BORDER;
  FClickSound := False;
  FHeight := FORM_H;
  FHotColor := COLOR_KEY_HOT;
  FKeyColor := COLOR_KEY_FACE;
  FKeyTextColor := COLOR_KEY_TEXT;
  FLanguage := klKorean;
  FMaxLength := 0;
  FPasswordChar := #0;
  FPosition := kpScreenCenter;
  FPressedColor := COLOR_KEY_DOWN;
  FSpecialKeyColor := COLOR_KEY_SPEC;
  FSubTextColor := COLOR_KEY_SUB;
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
  LColors.Toggled := FToggledColor;

  var LForm := TSCVirtualKeyboardForm.Create(LWidth, LHeight);
  try
    LForm.ClickSound := FClickSound;
    LForm.Colors := LColors;
    LForm.Korean := FLanguage = klKorean;
    LForm.MaxLength := FMaxLength;
    LForm.PasswordChar := FPasswordChar;
    LForm.EditText := AText;

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
