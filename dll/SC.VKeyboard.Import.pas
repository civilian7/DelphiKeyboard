// sc_vkeyboard.dll 델파이 임포트 래퍼
// 소스(src\) 대신 DLL 로 가상 키보드를 쓰는 델파이 프로젝트용.
// DLL 이름은 32/64비트 동일 — 32비트는 lib\dll\win32\, 64비트는 lib\dll\ 에 배포된다.
unit SC.VKeyboard.Import;

interface

const
  SC_VKEYBOARD_DLL = 'sc_vkeyboard.dll';   // 32/64 동일명 (폴더로 비트수 구분)

  VKB_CONFIRMED = 1;    // Enter 로 확정
  VKB_CANCELLED = 0;    // ESC 로 취소
  VKB_ERROR     = -1;   // 잘못된 인자 또는 내부 오류

  VKB_LANG_ENGLISH = 0;
  VKB_LANG_KOREAN  = 1;

/// <summary>가상 키보드 창을 모달로 띄우고 입력을 받습니다.</summary>
/// <param name="ABuffer">널 종단 유니코드 입출력 버퍼. 호출 시 초기 텍스트, 확정 시 입력 결과가 담깁니다.
/// 결과가 버퍼보다 길면 (ABufferSize - 1) 문자로 잘립니다.</param>
/// <param name="ABufferSize">버퍼 용량 (문자 수, 널 종단 포함). 1024 권장</param>
/// <param name="ALanguage">처음 열릴 때 입력 언어 (VKB_LANG_ENGLISH / VKB_LANG_KOREAN)</param>
/// <param name="ALeft">창 좌측 좌표 (화면 픽셀). ALeft/ATop 모두 -1 이면 화면 중앙</param>
/// <param name="ATop">창 상단 좌표 (화면 픽셀)</param>
/// <param name="AWidth">키보드 폭 (96DPI 기준 논리값). 0 이하면 기본 800</param>
/// <param name="AHeight">키보드 높이 (96DPI 기준 논리값). 0 이하면 기본 396</param>
/// <param name="ATitle">예약 인자 (무시됨). 제목 표시가 제거되어 사용하지 않지만 ABI 호환을 위해 유지. nil 권장</param>
/// <param name="APasswordChar">암호 표시 문자. #0 이면 일반 표시</param>
/// <returns>VKB_CONFIRMED / VKB_CANCELLED / VKB_ERROR</returns>
function VKB_Show(ABuffer: PWideChar; ABufferSize: Integer;
  ALanguage, ALeft, ATop, AWidth, AHeight: Integer;
  ATitle: PWideChar; APasswordChar: WideChar): Integer; stdcall;

/// <summary>키 클릭음 재생 여부를 설정합니다. 이후의 VKB_Show 호출부터 적용됩니다.</summary>
/// <param name="AEnabled">0=끔(기본), 그 외=켬</param>
procedure VKB_SetClickSound(AEnabled: Integer); stdcall;

/// <summary>DLL 버전을 반환합니다 (상위 바이트 = 메이저, 하위 바이트 = 마이너).</summary>
function VKB_Version: Integer; stdcall;

implementation

function VKB_Show; external SC_VKEYBOARD_DLL;
procedure VKB_SetClickSound; external SC_VKEYBOARD_DLL;
function VKB_Version; external SC_VKEYBOARD_DLL;

end.
