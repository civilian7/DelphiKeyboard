// sc_vkeyboard.dll — 가상 키보드 네이티브 DLL (32/64비트 공통 소스, stdcall)
// C#, C/C++, Python 등 DLL 을 로드할 수 있는 언어에서 가상 키보드를 사용할 수 있게 한다.
library sc_vkeyboard;

uses
  System.SysUtils,
  SC.Hangul in '..\src\SC.Hangul.pas',
  SC.VirtualKeyboard in '..\src\SC.VirtualKeyboard.pas';

const
  VKB_CONFIRMED = 1;    // Enter 로 확정
  VKB_CANCELLED = 0;    // ESC 로 취소
  VKB_ERROR     = -1;   // 잘못된 인자 또는 내부 오류

  VKB_DLL_VERSION = $0101;  // 1.1

var
  // VKB_SetClickSound 로 설정하는 전역 옵션 (이후 VKB_Show 호출에 적용)
  GClickSound: Boolean = False;

/// <summary>가상 키보드 창을 모달로 띄우고 입력을 받습니다.</summary>
/// <param name="ABuffer">널 종단 유니코드 입출력 버퍼. 호출 시 초기 텍스트, 확정 시 입력 결과가 담깁니다.
/// 결과가 버퍼보다 길면 (ABufferSize - 1) 문자로 잘립니다.</param>
/// <param name="ABufferSize">버퍼 용량 (문자 수, 널 종단 포함). 1024 권장</param>
/// <param name="ALanguage">처음 열릴 때 입력 언어 (0=영문, 1=한글)</param>
/// <param name="ALeft">창 좌측 좌표 (화면 픽셀). ALeft/ATop 모두 -1 이면 화면 중앙</param>
/// <param name="ATop">창 상단 좌표 (화면 픽셀)</param>
/// <param name="AWidth">키보드 폭 (96DPI 기준 논리값). 0 이하면 기본 800</param>
/// <param name="AHeight">키보드 높이 (96DPI 기준 논리값). 0 이하면 기본 396</param>
/// <param name="ATitle">예약 인자 (무시됨). 키보드 창의 제목 표시가 제거되어 더 이상 사용하지 않지만
/// ABI 호환을 위해 유지합니다. nil 전달 권장</param>
/// <param name="APasswordChar">암호 표시 문자. #0 이면 일반 표시</param>
/// <returns>1=확정(VKB_CONFIRMED), 0=취소(VKB_CANCELLED), -1=오류(VKB_ERROR)</returns>
function VKB_Show(ABuffer: PWideChar; ABufferSize: Integer;
  ALanguage, ALeft, ATop, AWidth, AHeight: Integer;
  ATitle: PWideChar; APasswordChar: WideChar): Integer; stdcall;
begin
  Result := VKB_ERROR;

  if (ABuffer = nil) or (ABufferSize <= 1) then
  begin
    Exit;
  end;

  try
    var LKeyboard := TSCVirtualKeyboard.Create;
    try
      if ALanguage = 0 then
      begin
        LKeyboard.Language := klEnglish;
      end
      else
      begin
        LKeyboard.Language := klKorean;
      end;

      if (ALeft = -1) and (ATop = -1) then
      begin
        LKeyboard.Position := kpScreenCenter;
      end
      else
      begin
        LKeyboard.SetCustomPosition(ALeft, ATop);
      end;

      LKeyboard.ClickSound := GClickSound;
      LKeyboard.PasswordChar := APasswordChar;

      var LText: string := ABuffer;
      if LKeyboard.Execute(LText, AWidth, AHeight) then
      begin
        StrPLCopy(ABuffer, LText, ABufferSize - 1);
        Result := VKB_CONFIRMED;
      end
      else
      begin
        Result := VKB_CANCELLED;
      end;
    finally
      LKeyboard.Free;
    end;
  except
    // 예외를 DLL 경계 밖으로 전파할 수 없으므로 결과 코드로 변환한다
    on E: Exception do
    begin
      Result := VKB_ERROR;
    end;
  end;
end;

/// <summary>키 클릭음 재생 여부를 설정합니다. 이후의 VKB_Show 호출부터 적용됩니다.
/// 클릭음은 DLL 내부에서 합성하므로 별도 사운드 파일이 필요 없습니다.</summary>
/// <param name="AEnabled">0=끔(기본), 그 외=켬</param>
procedure VKB_SetClickSound(AEnabled: Integer); stdcall;
begin
  GClickSound := AEnabled <> 0;
end;

/// <summary>DLL 버전을 반환합니다 (상위 바이트 = 메이저, 하위 바이트 = 마이너).</summary>
function VKB_Version: Integer; stdcall;
begin
  Result := VKB_DLL_VERSION;
end;

exports
  VKB_SetClickSound,
  VKB_Show,
  VKB_Version;

begin
end.

