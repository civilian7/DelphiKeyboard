// sc_vkeyboard.dll 델파이 사용 예제 (소스 대신 DLL 임포트)
// 실행 파일 옆(또는 PATH)에 sc_vkeyboard.dll 이 있어야 한다
// (64비트: lib\dll\, 32비트: lib\dll\win32\ — 파일명 동일).
program VKeyboardDllDemo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  SC.VKeyboard.Import in '..\..\dll\SC.VKeyboard.Import.pas';

begin
  try
    var LVersion := VKB_Version;
    Writeln(Format('sc_vkeyboard.dll v%d.%d', [LVersion shr 8, LVersion and $FF]));

    // 키 클릭음 켬 (v1.1+)
    VKB_SetClickSound(1);

    // 입출력 버퍼: 호출 시 초기 텍스트, 확정 시 입력 결과
    var LBuffer: array[0..1023] of WideChar;
    StrPLCopy(@LBuffer[0], '안녕하세요', High(LBuffer));

    var LRet := VKB_Show(@LBuffer[0], Length(LBuffer),
      VKB_LANG_KOREAN,
      -1, -1,          // 화면 중앙
      0, 0,            // 기본 크기 (800×396)
      nil,             // 예약 인자 (무시됨)
      #0);             // 일반 표시

    case LRet of
      VKB_CONFIRMED:
        begin
          Writeln('입력 결과: ', PWideChar(@LBuffer[0]));
        end;

      VKB_CANCELLED:
        begin
          Writeln('취소됨');
        end;
    else
      Writeln('오류 (코드 ', LRet, ')');
    end;
  except
    on E: Exception do
    begin
      Writeln('예외: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
