// sc_vkeyboard.dll C# 사용 예제
// 가상 키보드를 모달로 띄워 한글/영문을 입력받는다 (시스템 IME 상태와 무관하게 한글 조합).
using System.Runtime.InteropServices;
using System.Text;

namespace VKeyboardDemo;

internal static class VirtualKeyboard
{
    public const int Confirmed = 1;   // Enter 로 확정
    public const int Cancelled = 0;   // ESC 로 취소
    public const int Error = -1;      // 잘못된 인자 또는 내부 오류

    public const int LangEnglish = 0;
    public const int LangKorean = 1;

    /// <summary>가상 키보드 창을 모달로 띄우고 입력을 받는다.</summary>
    /// <param name="buffer">입출력 버퍼. 호출 시 초기 텍스트, 확정 시 입력 결과</param>
    /// <param name="bufferSize">버퍼 용량 (문자 수). 1024 권장</param>
    /// <param name="language">처음 열릴 때 입력 언어 (0=영문, 1=한글)</param>
    /// <param name="left">창 좌측 좌표 (화면 픽셀). left/top 모두 -1 이면 화면 중앙</param>
    /// <param name="top">창 상단 좌표 (화면 픽셀)</param>
    /// <param name="width">키보드 폭 (96DPI 기준 논리값). 0 이하면 기본 800</param>
    /// <param name="height">키보드 높이 (96DPI 기준 논리값). 0 이하면 기본 376</param>
    /// <param name="title">예약 인자 (무시됨, ABI 호환용). null 권장</param>
    /// <param name="passwordChar">암호 표시 문자. '\0' 이면 일반 표시</param>
    [DllImport("sc_vkeyboard.dll", CharSet = CharSet.Unicode)]
    public static extern int VKB_Show(
        StringBuilder buffer, int bufferSize,
        int language, int left, int top, int width, int height,
        string? title, char passwordChar);

    /// <summary>키 클릭음 재생 여부 설정 (0=끔 기본). 이후의 VKB_Show 호출부터 적용 (v1.1+).</summary>
    [DllImport("sc_vkeyboard.dll")]
    public static extern void VKB_SetClickSound(int enabled);

    /// <summary>DLL 버전 (상위 바이트 = 메이저, 하위 바이트 = 마이너).</summary>
    [DllImport("sc_vkeyboard.dll")]
    public static extern int VKB_Version();
}

internal static class Program
{
    private static void Main()
    {
        Console.OutputEncoding = Encoding.UTF8;
        Console.WriteLine($"sc_vkeyboard.dll v{VirtualKeyboard.VKB_Version() >> 8}.{VirtualKeyboard.VKB_Version() & 0xFF}");

        VirtualKeyboard.VKB_SetClickSound(1);   // 키 클릭음 켬 (v1.1+)

        var buffer = new StringBuilder(1024);
        buffer.Append("안녕하세요");

        int ret = VirtualKeyboard.VKB_Show(
            buffer, buffer.Capacity,
            VirtualKeyboard.LangKorean,
            left: -1, top: -1,        // 화면 중앙
            width: 0, height: 0,      // 기본 크기 (800×376)
            title: null,              // 예약 인자 (무시됨)
            passwordChar: '\0');

        switch (ret)
        {
            case VirtualKeyboard.Confirmed:
                Console.WriteLine($"입력 결과: {buffer}");
                break;
            case VirtualKeyboard.Cancelled:
                Console.WriteLine("취소됨");
                break;
            default:
                Console.WriteLine($"오류 (코드 {ret})");
                break;
        }
    }
}
