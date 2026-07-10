# sc_vkeyboard.dll Python 사용 예제 (ctypes)
# 가상 키보드를 모달로 띄워 한글/영문을 입력받는다 (시스템 IME 상태와 무관하게 한글 조합).
import ctypes
import sys
from pathlib import Path

VKB_CONFIRMED = 1   # Enter 로 확정
VKB_CANCELLED = 0   # ESC 로 취소
VKB_ERROR = -1      # 잘못된 인자 또는 내부 오류

VKB_LANG_ENGLISH = 0
VKB_LANG_KOREAN = 1


def load_dll() -> ctypes.WinDLL:
    """파이썬 프로세스 비트수에 맞는 DLL 을 저장소 배포 폴더에서 로드한다."""
    root = Path(__file__).resolve().parents[2]           # 저장소 루트
    subdir = "" if sys.maxsize > 2**32 else "win32"      # 64비트 / 32비트
    dll_path = root / "lib" / "dll" / subdir / "sc_vkeyboard.dll"
    return ctypes.WinDLL(str(dll_path))                  # WinDLL = stdcall (x86 에서 중요)


def main() -> None:
    vkb = load_dll()
    version = vkb.VKB_Version()
    print(f"sc_vkeyboard.dll v{version >> 8}.{version & 0xFF}")

    vkb.VKB_SetClickSound(1)  # 키 클릭음 켬 (v1.1+)

    # 입출력 버퍼: 호출 시 초기 텍스트, 확정 시 입력 결과
    buffer = ctypes.create_unicode_buffer("안녕하세요", 1024)

    ret = vkb.VKB_Show(
        buffer, 1024,
        VKB_LANG_KOREAN,
        -1, -1,          # 화면 중앙
        0, 0,            # 기본 크기 (800×376)
        None,            # 예약 인자 (무시됨)
        ord("\0"),       # 일반 표시
    )

    if ret == VKB_CONFIRMED:
        print("입력 결과:", buffer.value)
    elif ret == VKB_CANCELLED:
        print("취소됨")
    else:
        print(f"오류 (코드 {ret})")


if __name__ == "__main__":
    main()
