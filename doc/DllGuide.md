# sc_vkeyboard.dll 사용 가이드 (C ABI)

C ABI(FFI)를 지원하는 모든 언어에서 가상 키보드를 사용할 수 있습니다.
**미리 빌드된 DLL 이 저장소에 포함**되어 있으므로 Delphi 컴파일러 없이 바로 사용합니다.

| 비트수 | 경로 | 파일명 |
|---|---|---|
| 64비트 (x64) | `lib\dll\` | `sc_vkeyboard.dll` |
| 32비트 (x86) | `lib\dll\win32\` | `sc_vkeyboard.dll` (동일 파일명, 폴더로 구분) |

호출 프로세스의 비트수와 DLL 비트수가 일치해야 합니다.
DLL 은 실행 파일 옆이나 PATH 에 두면 됩니다.

## ABI 규약

- **호출 규약**: `stdcall` (x64 에서는 단일 규약이라 구분 무의미, x86 에서는 반드시 stdcall 지정)
- **문자열**: UTF-16LE 널 종단 (`wchar_t*` — Windows 네이티브 유니코드)
- **정수**: 32비트 `int`
- **예외**: DLL 경계를 넘지 않음 — 모든 오류는 반환 코드(-1)로 변환됨
- **스레딩**: 함수 내부에서 자체 모달 메시지 루프를 돌리므로 콘솔 앱에서도 호출 가능.
  창을 띄우는 함수이므로 UI 스레드(또는 메인 스레드)에서 호출 권장

## 함수 레퍼런스

```c
// C 선언
#include <wchar.h>

// 가상 키보드를 모달로 띄우고 입력을 받는다.
// buffer: 널 종단 UTF-16 입출력 버퍼 — 호출 시 초기 텍스트, 확정 시 입력 결과.
//         결과가 길면 (bufferSize - 1) 문자로 잘린다. 1024자 권장.
// 반환: 1=Enter 확정, 0=ESC 취소, -1=오류
int __stdcall VKB_Show(
    wchar_t* buffer,        // 입출력 버퍼
    int      bufferSize,    // 버퍼 용량 (문자 수, 널 종단 포함)
    int      language,      // 0=영문, 1=한글
    int      left,          // 창 좌측 (화면 픽셀). left/top 모두 -1 = 화면 중앙
    int      top,           // 창 상단 (화면 픽셀)
    int      width,         // 키보드 폭 (96DPI 논리값). 0 이하 = 기본 800
    int      height,        // 키보드 높이 (96DPI 논리값). 0 이하 = 기본 376
    const wchar_t* title,   // 예약 인자 (무시됨, ABI 호환용 유지). NULL 권장
    wchar_t  passwordChar); // 암호 표시 문자. L'\0' = 일반 표시

// 키 클릭음 재생 여부 설정 (0=끔 기본, 그 외=켬). 이후의 VKB_Show 호출부터 적용.
// 클릭음은 DLL 내부에서 합성하므로 별도 사운드 파일이 필요 없다. (v1.1+)
void __stdcall VKB_SetClickSound(int enabled);

// DLL 버전. 상위 바이트 = 메이저, 하위 바이트 = 마이너 (0x0101 = v1.1)
int __stdcall VKB_Version(void);
```

> v1.1 변경: 키보드 창의 제목 표시가 제거되어 `title` 은 예약 인자가 되었습니다
> (기존 호출 코드는 수정 없이 동작). `VKB_SetClickSound` 가 추가되었습니다.

## 언어별 예제

### C / C++

```c
#include <windows.h>
#include <stdio.h>

typedef int (__stdcall *PVKB_Show)(wchar_t*, int, int, int, int, int, int, const wchar_t*, wchar_t);

int main(void)
{
    HMODULE lib = LoadLibraryW(L"sc_vkeyboard.dll");
    PVKB_Show VKB_Show = (PVKB_Show)GetProcAddress(lib, "VKB_Show");

    wchar_t buffer[1024] = L"안녕하세요";
    if (VKB_Show(buffer, 1024, 1, -1, -1, 0, 0, NULL, L'\0') == 1)
    {
        wprintf(L"입력 결과: %s\n", buffer);
    }

    FreeLibrary(lib);
    return 0;
}
```

### C# (P/Invoke) — 전체 예제는 `demos\csharp\`

```csharp
using System.Runtime.InteropServices;
using System.Text;

[DllImport("sc_vkeyboard.dll", CharSet = CharSet.Unicode)]
static extern int VKB_Show(StringBuilder buffer, int bufferSize,
    int language, int left, int top, int width, int height,
    string? title, char passwordChar);

var buffer = new StringBuilder("안녕하세요", 1024);
if (VKB_Show(buffer, buffer.Capacity, 1, -1, -1, 0, 0, null, '\0') == 1)
{
    Console.WriteLine($"입력 결과: {buffer}");
}
```

### Python (ctypes)

```python
import ctypes

vkb = ctypes.WinDLL("sc_vkeyboard.dll")   # WinDLL = stdcall (x86 에서 중요)

buffer = ctypes.create_unicode_buffer("안녕하세요", 1024)
ret = vkb.VKB_Show(buffer, 1024, 1, -1, -1, 0, 0, None, ord("\0"))

if ret == 1:
    print("입력 결과:", buffer.value)
```

### Delphi (임포트 래퍼) — 전체 예제는 `demos\delphi_dll\`

```pascal
uses
  SC.VKeyboard.Import;   // dll\SC.VKeyboard.Import.pas

var LBuffer: array[0..1023] of WideChar;
StrPLCopy(@LBuffer[0], '안녕하세요', High(LBuffer));

if VKB_Show(@LBuffer[0], Length(LBuffer), VKB_LANG_KOREAN,
  -1, -1, 0, 0, nil, #0) = VKB_CONFIRMED then
begin
  ShowMessage(PWideChar(@LBuffer[0]));
end;
```

### 그 외 언어 (일반 지침)

FFI 로 다음만 맞추면 어느 언어든 사용할 수 있습니다:

1. **stdcall** 호출 규약 지정 (x86 필수, x64 무관)
2. 문자열 파라미터는 **UTF-16 널 종단** 포인터로 전달
   (Node.js `koffi` 의 `str16`, Rust `widestring`, Java JNA 의 `WString` 등)
3. `buffer` 는 **쓰기 가능한** 1024자 버퍼로 할당 (확정 시 결과가 덮어써짐)
4. 반환 코드 판정: `1` 확정 / `0` 취소 / `-1` 오류

## 재빌드 (선택)

DLL 을 다시 빌드하려면 Delphi 13(Studio 37.0) 이 필요합니다:

```
cd dll
dcc64.exe sc_vkeyboard.dpr -U"...\lib\win64\release" -E..\lib\dll -N..\lib\dll
dcc32.exe sc_vkeyboard.dpr -U"...\lib\win32\release" -E..\lib\dll\win32 -N..\lib\dll\win32
```
