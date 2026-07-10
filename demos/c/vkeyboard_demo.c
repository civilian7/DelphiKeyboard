// sc_vkeyboard.dll C/C++ 사용 예제 (LoadLibrary / GetProcAddress — 임포트 라이브러리 불필요)
// 가상 키보드를 모달로 띄워 한글/영문을 입력받는다 (시스템 IME 상태와 무관하게 한글 조합).
//
// 빌드 (MSVC):  cl /W4 vkeyboard_demo.c /Fe:..\..\bin\vkeyboard_demo_c.exe
// 빌드 (MinGW): gcc -Wall -municode vkeyboard_demo.c -o ..\..\bin\vkeyboard_demo_c.exe
// 실행 파일 옆(또는 PATH)에 sc_vkeyboard.dll 필요 (64비트: lib\dll\, 32비트: lib\dll\win32\)
#include <windows.h>
#include <stdio.h>
#include <fcntl.h>
#include <io.h>

#define VKB_CONFIRMED  1    // Enter 로 확정
#define VKB_CANCELLED  0    // ESC 로 취소
#define VKB_ERROR     -1    // 잘못된 인자 또는 내부 오류

#define VKB_LANG_ENGLISH 0
#define VKB_LANG_KOREAN  1

typedef int(__stdcall *PVKB_Show)(
    wchar_t *buffer,        // 입출력 버퍼 (호출 시 초기 텍스트, 확정 시 입력 결과)
    int bufferSize,         // 버퍼 용량 (문자 수, 널 종단 포함)
    int language,           // 0=영문, 1=한글
    int left, int top,      // 둘 다 -1 이면 화면 중앙 (화면 픽셀)
    int width, int height,  // 96DPI 기준 논리값, 0 이하 = 기본 800×376
    const wchar_t *title,   // 예약 인자 (무시됨, ABI 호환용) — NULL 권장
    wchar_t passwordChar);  // L'\0' = 일반 표시

typedef void(__stdcall *PVKB_SetClickSound)(int enabled);   // 키 클릭음 (0=끔 기본, v1.1+)

typedef int(__stdcall *PVKB_Version)(void);

int wmain(void)
{
    _setmode(_fileno(stdout), _O_U16TEXT);   // 콘솔 한글 출력

    HMODULE lib = LoadLibraryW(L"sc_vkeyboard.dll");
    if (lib == NULL)
    {
        wprintf(L"sc_vkeyboard.dll 로드 실패 (실행 파일 옆에 DLL 을 두세요)\n");
        return 1;
    }

    PVKB_Show vkbShow = (PVKB_Show)GetProcAddress(lib, "VKB_Show");
    PVKB_Version vkbVersion = (PVKB_Version)GetProcAddress(lib, "VKB_Version");
    if (vkbShow == NULL || vkbVersion == NULL)
    {
        wprintf(L"export 를 찾을 수 없습니다\n");
        FreeLibrary(lib);
        return 1;
    }

    int version = vkbVersion();
    wprintf(L"sc_vkeyboard.dll v%d.%d\n", version >> 8, version & 0xFF);

    // 키 클릭음 켬 (v1.1+ — 구버전 DLL 은 export 가 없을 수 있으므로 NULL 확인)
    PVKB_SetClickSound vkbSetClickSound = (PVKB_SetClickSound)GetProcAddress(lib, "VKB_SetClickSound");
    if (vkbSetClickSound != NULL)
    {
        vkbSetClickSound(1);
    }

    wchar_t buffer[1024] = L"안녕하세요";
    int ret = vkbShow(buffer, 1024,
                      VKB_LANG_KOREAN,
                      -1, -1,     // 화면 중앙
                      0, 0,       // 기본 크기 (800×376)
                      NULL,       // 예약 인자 (무시됨)
                      L'\0');     // 일반 표시

    switch (ret)
    {
    case VKB_CONFIRMED:
        wprintf(L"입력 결과: %s\n", buffer);
        break;
    case VKB_CANCELLED:
        wprintf(L"취소됨\n");
        break;
    default:
        wprintf(L"오류 (코드 %d)\n", ret);
        break;
    }

    FreeLibrary(lib);
    return 0;
}
