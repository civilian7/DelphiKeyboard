# 가상 키보드 컴포넌트 (TSCVirtualKeyboard)

마우스 클릭만으로 한글/영문을 입력받는 VCL 가상 키보드입니다.
한글은 내부 **두벌식 조합 오토마타**로 직접 조합하므로 시스템 IME 상태(한/영 모드)와
무관하게 항상 올바르게 조합됩니다. 상세한 원인 분석·설계·검증 내용은
[doc/HangulComposition.md](doc/HangulComposition.md) 참고.

![가상 키보드](doc/screenshot.png)

## 폴더 구조

```
DelphiKeyboard\
  src\      SC.Hangul.pas            두벌식 조합 오토마타 (THangulComposer) — UI 무관, 단독 재사용 가능
            SC.VirtualKeyboard.pas   TSCVirtualKeyboard 컴포넌트 + 키보드 폼 (벡터 렌더링, DPI 스케일)
  dll\      sc_vkeyboard.dpr         네이티브 DLL 프로젝트 (stdcall exports)
            SC.VKeyboard.Import.pas  DLL 사용 델파이 프로젝트용 임포트 래퍼
  lib\dll\  sc_vkeyboard.dll         64비트 DLL (32비트는 lib\dll\win32\ — 동일 파일명)
  demos\    delphi_native\           델파이 데모 — 소스(src\) 직접 사용 (VirtualKeyboardDemo.dpr)
            delphi_dll\              델파이 데모 — DLL 임포트 사용 (VKeyboardDllDemo.dpr)
            csharp\                  C# 사용 예제 (net8.0 콘솔)
  bin\      빌드 산출물 (VirtualKeyboardDemo.exe)
  doc\      HangulComposition.md     한글 조합 문제 원인 분석·오토마타 설계·검증
            DllGuide.md              DLL 사용 가이드 (C ABI — 언어별 예제)
            screenshot.png           키보드 화면 캡처
  legacy\   구 IME 의존 구현 (uKeyboard.pas 등) — 참고용 보존, 프로젝트에서 제외됨
```

키보드 폼은 IDE 설계 폼이 아니라 컴포넌트가 `CreateNew` 로 런타임에 동적 생성하는
폼이므로 `.dfm` 이 없습니다 (VCL 내장 다이얼로그와 같은 패턴). 다른 프로젝트에서는
`src\` 의 유닛 2개만 추가하면 이미지·dfm 리소스 배포 없이 재사용할 수 있습니다.

## 사용법

싱글톤으로 바로 사용합니다 (생성/해제 불필요, 첫 접근 시 생성·종료 시 자동 해제).

```pascal
uses
  SC.VirtualKeyboard;

procedure TfrmMain.BtnKeyboardClick(Sender: TObject);
begin
  var LText: string := Edit1.Text;

  if TSCVirtualKeyboard.Instance.Execute(LText) then   // Enter 확정 시 True
  begin
    Edit1.Text := LText;
  end;
end;
```

`TSCVirtualKeyboard.Create` 로 별도 인스턴스를 만들어 써도 됩니다 (일반 클래스 —
컴포넌트 팔레트 등록 불필요).

### 표시 위치·크기 지정

```pascal
// 화면 중앙(기본) / 메인 폼 중앙
TSCVirtualKeyboard.Instance.Position := kpMainFormCenter;

// 지정 좌표 (화면 픽셀 기준, 모니터 작업 영역을 벗어나면 자동 보정)
TSCVirtualKeyboard.Instance.SetCustomPosition(100, 400);

// 크기: 프로퍼티(96DPI 기준 논리값, 기본 800×378)로 지정하거나
TSCVirtualKeyboard.Instance.Width := 1200;
TSCVirtualKeyboard.Instance.Height := 567;

// Execute 파라미터로 그때그때 지정 (0 이하 = 프로퍼티 값 사용)
TSCVirtualKeyboard.Instance.Execute(LText, 1200, 567);
```

크기를 바꾸면 키 배치·글꼴이 전부 비례 스케일됩니다 (최소 400×189 보정,
모니터 DPI 배율은 추가로 적용).

### 색상 지정

```pascal
TSCVirtualKeyboard.Instance.BackgroundColor := $00202020;   // 다크 테마 예시
TSCVirtualKeyboard.Instance.KeyColor := $00383838;
TSCVirtualKeyboard.Instance.KeyTextColor := $00E0E0E0;
```

### 프로퍼티

| 프로퍼티 | 설명 |
|---|---|
| `Language` | 처음 열릴 때 입력 언어 (`klKorean` 기본 / `klEnglish`) |
| `PasswordChar` | 입력창 암호 표시 문자 (`#0` = 일반 표시) |
| `Position` | 표시 위치 (`kpScreenCenter` 기본 / `kpMainFormCenter` / `kpCustom`) |
| `CustomLeft` / `CustomTop` | `kpCustom` 일 때 창 좌표 (화면 픽셀 기준) |
| `Width` / `Height` | 키보드 크기 (96DPI 기준 논리값, 기본 800×378) |
| `Title` | 키보드 창 좌측 상단 제목 (기본 '가상 키보드') |
| `BackgroundColor` | 폼 배경 색상 |
| `KeyColor` / `SpecialKeyColor` | 일반 키 / 특수 키 면 색상 |
| `KeyTextColor` / `SubTextColor` | 키 글자 / Shift 보조 글자 색상 |
| `BorderColor` | 키 테두리 색상 |
| `HotColor` / `PressedColor` / `ToggledColor` | 마우스 오버 / 눌림 / 토글 활성 키 면 색상 |
| `TitleTextColor` | 제목 글자 색상 |

### 키보드 동작

- **한/영**: 한글/영문 전환 (조합 중이던 글자는 확정)
- **Shift**: 1회성 (다음 키에만 적용 — ㅂ→ㅃ, ㅐ→ㅒ, a→A, 1→!)
- **Caps**: 영문 대소문자 토글
- **Enter** 확정 / **ESC** 취소, 키 밖 영역 드래그로 창 이동
- 물리 키보드로도 입력 가능 (물리 입력 시 조합 중 글자는 자동 확정)

## 네이티브 DLL (다른 언어에서 사용)

C#, C/C++, Python 등 C ABI(FFI)를 지원하는 언어에서는 `sc_vkeyboard.dll` 로 가상 키보드를
사용합니다. 32/64비트 모두 **동일 파일명**이며 폴더로 구분합니다
(64비트 `lib\dll\`, 32비트 `lib\dll\win32\`).

> Delphi 는 상용 라이선스가 필요하므로 **미리 빌드된 DLL 을 저장소에 포함해 배포**합니다 —
> Delphi 없이 DLL 만으로 사용할 수 있습니다. 언어별 상세 사용법(C/C++, C#, Python,
> Delphi, 일반 FFI 지침)은 **[doc/DllGuide.md](doc/DllGuide.md)** 참고.

### Exports (stdcall)

```c
// 1=Enter 확정, 0=ESC 취소, -1=오류. buffer 는 널 종단 유니코드 입출력 버퍼(1024자 권장)
int VKB_Show(wchar_t* buffer, int bufferSize,
             int language,          // 0=영문, 1=한글
             int left, int top,     // 둘 다 -1 이면 화면 중앙 (화면 픽셀)
             int width, int height, // 96DPI 기준 논리값, 0 이하 = 기본 800×378
             const wchar_t* title,  // NULL = 기본 제목
             wchar_t passwordChar); // L'\0' = 일반 표시

int VKB_Version(); // 상위 바이트 = 메이저, 하위 바이트 = 마이너
```

### C# 예제 (`demos\csharp\`)

```csharp
[DllImport("sc_vkeyboard.dll", CharSet = CharSet.Unicode)]
static extern int VKB_Show(StringBuilder buffer, int bufferSize,
    int language, int left, int top, int width, int height,
    string? title, char passwordChar);

var buffer = new StringBuilder("안녕하세요", 1024);
if (VKB_Show(buffer, buffer.Capacity, 1, -1, -1, 0, 0, "가상 키보드", '\0') == 1)
{
    Console.WriteLine($"입력 결과: {buffer}");
}
```

실행: `cd demos\csharp && dotnet run` (net8.0, x64 — 빌드 시 DLL 이 출력 폴더로 자동 복사됨)

### 델파이에서 DLL 사용 (`demos\delphi_dll\`)

소스(`src\`) 대신 DLL 을 쓰려면 `dll\SC.VKeyboard.Import.pas` 를 uses 에 추가하고
`VKB_Show` 를 호출하면 됩니다 (DLL 이름 상수는 32/64 공통, IFDEF 불필요).
콘솔 예제 `demos\delphi_dll\VKeyboardDllDemo.dpr` 참고 — 실행 파일 옆에
`sc_vkeyboard.dll` 이 있어야 합니다.

### DLL 빌드

```
cd dll
dcc64.exe sc_vkeyboard.dpr -U"...\lib\win64\release" -E..\lib\dll -N..\lib\dll
dcc32.exe sc_vkeyboard.dpr -U"...\lib\win32\release" -E..\lib\dll\win32 -N..\lib\dll\win32
```

## 빌드

Win64 가 기본 타깃입니다. 산출물은 폴더로 비트수를 구분합니다 (64비트 `bin\`, 32비트 `bin\win32\`).

```
cd demos\delphi_native

:: Win64 (기본)
dcc64.exe VirtualKeyboardDemo.dpr -U"C:\Program Files (x86)\Embarcadero\Studio\37.0\lib\win64\release" -E..\..\bin -N..\..\bin

:: Win32 (필요 시)
dcc32.exe VirtualKeyboardDemo.dpr -U"C:\Program Files (x86)\Embarcadero\Studio\37.0\lib\win32\release" -E..\..\bin\win32 -N..\..\bin\win32
```

또는 Delphi IDE 에서 `demos\delphi_native\VirtualKeyboardDemo.dpr` 을 열어 빌드
(32비트는 Project Manager 에서 Windows 32-bit 플랫폼 추가).
소스는 비트수 무관 공통이라 IFDEF 분기가 없습니다.
DLL 임포트 데모(`demos\delphi_dll\VKeyboardDllDemo.dpr`)도 같은 방식으로 빌드합니다.

> High-DPI: 키 배치·글꼴은 96DPI 기준 논리값을 `CurrentPPI` 로 스케일합니다.
> 프로젝트 옵션에서 DPI awareness 를 **PerMonitorV2** 로 설정하세요.

## 변경 이력

### 2026-07-10

- **한글 조합 문제 근본 해결**: OS IME 의존(SendInput 키 주입)을 제거하고 두벌식 조합
  오토마타(`SC.Hangul.pas`)를 내장. 상세는 [doc/HangulComposition.md](doc/HangulComposition.md)
- **재사용 가능한 클래스로 재구성**: `TSCVirtualKeyboard` (일반 클래스 — `TObject` 상속,
  컴포넌트 팔레트 등록 불필요). GIF 리소스·전역 마우스 훅 제거, 벡터 렌더링 전환
- **싱글톤 지원**: `TSCVirtualKeyboard.Instance.Execute(...)` — 생성/해제 없이 사용,
  프로그램 종료 시 자동 해제
- **표시 위치 지정**: `Position` (`kpScreenCenter`/`kpMainFormCenter`/`kpCustom`),
  `SetCustomPosition(ALeft, ATop)` — 모니터 작업 영역 자동 보정
- **크기 지정**: `Width`/`Height` 프로퍼티 또는 `Execute(AText, AWidth, AHeight)` 파라미터
  (96DPI 기준 논리값, 기본 800×378). 키 배치·글꼴 비례 스케일
- **색상 커스터마이징**: 배경·키·글자·테두리·상태(오버/눌림/토글) 등 색상 10종 프로퍼티화
- **폴더 재구성**: `src\` / `demos\` / `bin\`(+`win32\`) / `doc\` / `legacy\`,
  데모를 `Project1` → `VirtualKeyboardDemo` 로 변경
- **네이티브 DLL**: `sc_vkeyboard.dll` (32/64비트, stdcall `VKB_Show`/`VKB_Version`) 과
  델파이 임포트 래퍼 추가. 미리 빌드된 DLL 을 `lib\dll\` 에 포함해 배포 (Delphi 불필요)
- **다국어 샘플·가이드**: 데모를 `delphi_native\`(소스 사용) / `delphi_dll\`(DLL 사용) /
  `csharp\` 로 분리, C ABI 사용 가이드(`doc\DllGuide.md`) 추가

## 라이선스

[MIT License](LICENSE). 단, `legacy\` 폴더는 아래 출처의 커뮤니티 공유 소스를 포팅한
참고용 보존본으로, 원저작자의 별도 라이선스 명시가 없어 MIT 적용 대상에서 제외합니다.

## 출처 (원저작자)

`legacy\` 의 구 구현은 볼랜드포럼 컴포넌트 게시판에 공유된
"[한/영 입력 가능한 가상 키보드 입니다.](http://cbuilder.borlandforum.com/impboard/impboard.dll?action=read&db=component&no=836)"
(godson2, 2021-12-30) 의 C++Builder 소스를 Delphi 로 포팅한 것입니다.
해당 글은 **박영목** 님의 원작 소스를 C++Builder 11 에서 사용 가능하도록
손본 것이라고 밝히고 있습니다.
현재의 `src\` 구현(조합 오토마타·벡터 렌더링)은 키 배치 좌표 테이블 외에는
전면 재작성되었습니다.
