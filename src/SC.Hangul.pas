// 두벌식 한글 조합 오토마타
// OS IME에 의존하지 않고 자모(호환 자모)를 받아 완성형 음절로 조합한다.
unit SC.Hangul;

interface

type
  /// <summary>두벌식 한글 조합 오토마타.
  /// 호환 자모(ㄱ~ㅎ, ㅏ~ㅣ)를 한 글자씩 입력받아 완성형 음절(가~힣)로 조합합니다.
  /// 도깨비불 현상(받침이 다음 음절 초성으로 넘어가는 규칙), 겹받침(ㄳ, ㄵ 등),
  /// 복모음(ㅘ, ㅢ 등) 결합을 모두 처리하며, 조합 중 자모 단위 백스페이스를 지원합니다.</summary>
  THangulComposer = class
  private
    FCho: Integer;
    FJong: Integer;
    FJung: Integer;
    function ComposeText: string;
    function GetIsComposing: Boolean;
  public
    constructor Create;

    /// <summary>조합 중인 글자에서 마지막 자모 하나를 제거합니다.
    /// 겹받침은 홑받침으로, 복모음은 단모음으로 되돌립니다.</summary>
    /// <returns>조합 중이어서 백스페이스를 소비했으면 True, 조합 중이 아니면 False</returns>
    function Backspace: Boolean;

    /// <summary>자모 하나를 입력해 조합을 진행합니다.</summary>
    /// <param name="AJamo">입력 자모 (호환 자모: ㄱ~ㅎ, ㅏ~ㅣ)</param>
    /// <param name="ACommitted">이번 입력으로 확정(더 이상 변하지 않음)된 텍스트. 없으면 빈 문자열</param>
    /// <returns>현재 조합 중인 텍스트 (화면에서 ACommitted 뒤에 이어 표시)</returns>
    function Feed(const AJamo: Char; out ACommitted: string): string;

    /// <summary>조합 상태를 초기화합니다. 조합 중이던 텍스트는 그대로 확정된 것으로 간주합니다.</summary>
    procedure Reset;

    /// <summary>현재 조합 중인 텍스트 (조합 중이 아니면 빈 문자열).</summary>
    property Composing: string read ComposeText;
    /// <summary>현재 글자를 조합 중이면 True.</summary>
    property IsComposing: Boolean read GetIsComposing;
  end;

/// <summary>문자가 두벌식 자판에서 입력 가능한 호환 자모(자음/모음)인지 확인합니다.</summary>
function IsHangulJamo(const AChar: Char): Boolean;

implementation

const
  // 초성 19자 (유니코드 완성형 조합 순서)
  CHOSEONG: array[0..18] of Char = (
    'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ',
    'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'
  );

  // 중성 21자
  JUNGSEONG: array[0..20] of Char = (
    'ㅏ', 'ㅐ', 'ㅑ', 'ㅒ', 'ㅓ', 'ㅔ', 'ㅕ', 'ㅖ', 'ㅗ', 'ㅘ',
    'ㅙ', 'ㅚ', 'ㅛ', 'ㅜ', 'ㅝ', 'ㅞ', 'ㅟ', 'ㅠ', 'ㅡ', 'ㅢ', 'ㅣ'
  );

  // 종성 28자 (인덱스 0 = 받침 없음)
  JONGSEONG: array[0..27] of Char = (
    #0, 'ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ', 'ㄹ', 'ㄺ',
    'ㄻ', 'ㄼ', 'ㄽ', 'ㄾ', 'ㄿ', 'ㅀ', 'ㅁ', 'ㅂ', 'ㅄ', 'ㅅ',
    'ㅆ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'
  );

  HANGUL_BASE = $AC00;   // '가'

function ChoIndex(const AChar: Char): Integer;
begin
  Result := -1;

  for var I := Low(CHOSEONG) to High(CHOSEONG) do
  begin
    if CHOSEONG[I] = AChar then
    begin
      Result := I;
      Break;
    end;
  end;
end;

function JungIndex(const AChar: Char): Integer;
begin
  Result := -1;

  for var I := Low(JUNGSEONG) to High(JUNGSEONG) do
  begin
    if JUNGSEONG[I] = AChar then
    begin
      Result := I;
      Break;
    end;
  end;
end;

function JongIndex(const AChar: Char): Integer;
begin
  Result := -1;

  for var I := 1 to High(JONGSEONG) do
  begin
    if JONGSEONG[I] = AChar then
    begin
      Result := I;
      Break;
    end;
  end;
end;

// 복모음 결합: ㅗ+ㅏ=ㅘ 등. 결합 불가면 #0
function CombineJung(const AFirst, ASecond: Char): Char;
begin
  Result := #0;

  if AFirst = 'ㅗ' then
  begin
    case ASecond of
      'ㅏ': Result := 'ㅘ';
      'ㅐ': Result := 'ㅙ';
      'ㅣ': Result := 'ㅚ';
    end;
  end
  else
  if AFirst = 'ㅜ' then
  begin
    case ASecond of
      'ㅓ': Result := 'ㅝ';
      'ㅔ': Result := 'ㅞ';
      'ㅣ': Result := 'ㅟ';
    end;
  end
  else
  if AFirst = 'ㅡ' then
  begin
    if ASecond = 'ㅣ' then
    begin
      Result := 'ㅢ';
    end;
  end;
end;

// 복모음을 마지막 입력 이전 상태로 되돌림 (백스페이스용). 되돌릴 수 없으면 #0
function ReduceJung(const AJung: Char): Char;
begin
  case AJung of
    'ㅘ', 'ㅙ', 'ㅚ': Result := 'ㅗ';
    'ㅝ', 'ㅞ', 'ㅟ': Result := 'ㅜ';
    'ㅢ':             Result := 'ㅡ';
  else
    Result := #0;
  end;
end;

// 겹받침 결합: ㄱ+ㅅ=ㄳ 등. 결합 불가면 #0
function CombineJong(const AFirst, ASecond: Char): Char;
begin
  Result := #0;

  if AFirst = 'ㄱ' then
  begin
    if ASecond = 'ㅅ' then
    begin
      Result := 'ㄳ';
    end;
  end
  else
  if AFirst = 'ㄴ' then
  begin
    case ASecond of
      'ㅈ': Result := 'ㄵ';
      'ㅎ': Result := 'ㄶ';
    end;
  end
  else
  if AFirst = 'ㄹ' then
  begin
    case ASecond of
      'ㄱ': Result := 'ㄺ';
      'ㅁ': Result := 'ㄻ';
      'ㅂ': Result := 'ㄼ';
      'ㅅ': Result := 'ㄽ';
      'ㅌ': Result := 'ㄾ';
      'ㅍ': Result := 'ㄿ';
      'ㅎ': Result := 'ㅀ';
    end;
  end
  else
  if AFirst = 'ㅂ' then
  begin
    if ASecond = 'ㅅ' then
    begin
      Result := 'ㅄ';
    end;
  end;
end;

// 겹받침 분해: 도깨비불/백스페이스 공용. AJong이 겹받침이면 앞 받침과 뒤 자음을 돌려준다
function SplitJong(const AJong: Char; out AFirst, ASecond: Char): Boolean;
begin
  Result := True;
  AFirst := #0;
  ASecond := #0;

  case AJong of
    'ㄳ': begin AFirst := 'ㄱ'; ASecond := 'ㅅ'; end;
    'ㄵ': begin AFirst := 'ㄴ'; ASecond := 'ㅈ'; end;
    'ㄶ': begin AFirst := 'ㄴ'; ASecond := 'ㅎ'; end;
    'ㄺ': begin AFirst := 'ㄹ'; ASecond := 'ㄱ'; end;
    'ㄻ': begin AFirst := 'ㄹ'; ASecond := 'ㅁ'; end;
    'ㄼ': begin AFirst := 'ㄹ'; ASecond := 'ㅂ'; end;
    'ㄽ': begin AFirst := 'ㄹ'; ASecond := 'ㅅ'; end;
    'ㄾ': begin AFirst := 'ㄹ'; ASecond := 'ㅌ'; end;
    'ㄿ': begin AFirst := 'ㄹ'; ASecond := 'ㅍ'; end;
    'ㅀ': begin AFirst := 'ㄹ'; ASecond := 'ㅎ'; end;
    'ㅄ': begin AFirst := 'ㅂ'; ASecond := 'ㅅ'; end;
  else
    Result := False;
  end;
end;

function IsHangulJamo(const AChar: Char): Boolean;
begin
  // 호환 자모 영역(ㄱ=U+3131 ~ ㅣ=U+3163)
  Result := (AChar >= #$3131) and (AChar <= #$3163);
end;

{$REGION 'THangulComposer'}

constructor THangulComposer.Create;
begin
  inherited Create;
  Reset;
end;

function THangulComposer.Backspace: Boolean;
begin
  Result := IsComposing;

  if not Result then
  begin
    Exit;
  end;

  if FJong > 0 then
  begin
    // 겹받침이면 홑받침으로, 홑받침이면 제거
    var LFirst: Char;
    var LSecond: Char;
    if SplitJong(JONGSEONG[FJong], LFirst, LSecond) then
    begin
      FJong := JongIndex(LFirst);
    end
    else
    begin
      FJong := 0;
    end;
  end
  else
  if FJung >= 0 then
  begin
    // 복모음이면 단모음으로, 단모음이면 제거
    var LReduced := ReduceJung(JUNGSEONG[FJung]);
    if LReduced <> #0 then
    begin
      FJung := JungIndex(LReduced);
    end
    else
    begin
      FJung := -1;
    end;
  end
  else
  begin
    FCho := -1;
  end;
end;

function THangulComposer.ComposeText: string;
begin
  if (FCho >= 0) and (FJung >= 0) then
  begin
    Result := Char(HANGUL_BASE + (FCho * 21 + FJung) * 28 + FJong);
  end
  else
  if FCho >= 0 then
  begin
    Result := CHOSEONG[FCho];
  end
  else
  if FJung >= 0 then
  begin
    Result := JUNGSEONG[FJung];
  end
  else
  begin
    Result := '';
  end;
end;

function THangulComposer.Feed(const AJamo: Char; out ACommitted: string): string;
begin
  ACommitted := '';

  var LChoIdx := ChoIndex(AJamo);
  var LJungIdx := JungIndex(AJamo);

  if LJungIdx >= 0 then
  begin
    // 모음 입력
    if FJong > 0 then
    begin
      // 도깨비불: 받침(겹받침이면 뒤 자음만)이 새 음절의 초성으로 넘어간다
      var LFirst: Char;
      var LSecond: Char;
      var LNewCho: Char;
      if SplitJong(JONGSEONG[FJong], LFirst, LSecond) then
      begin
        LNewCho := LSecond;
        FJong := JongIndex(LFirst);
      end
      else
      begin
        LNewCho := JONGSEONG[FJong];
        FJong := 0;
      end;

      ACommitted := ComposeText;
      FCho := ChoIndex(LNewCho);
      FJung := LJungIdx;
      FJong := 0;
    end
    else
    if FJung >= 0 then
    begin
      // 복모음 결합 시도 (초성 유무와 무관)
      var LCombined := CombineJung(JUNGSEONG[FJung], AJamo);
      if LCombined <> #0 then
      begin
        FJung := JungIndex(LCombined);
      end
      else
      begin
        ACommitted := ComposeText;
        FCho := -1;
        FJung := LJungIdx;
        FJong := 0;
      end;
    end
    else
    begin
      // 초성만 있거나 빈 상태
      FJung := LJungIdx;
    end;
  end
  else
  if LChoIdx >= 0 then
  begin
    // 자음 입력
    if (FCho >= 0) and (FJung >= 0) then
    begin
      if FJong > 0 then
      begin
        // 겹받침 결합 시도
        var LCombined := CombineJong(JONGSEONG[FJong], AJamo);
        if LCombined <> #0 then
        begin
          FJong := JongIndex(LCombined);
        end
        else
        begin
          ACommitted := ComposeText;
          FCho := LChoIdx;
          FJung := -1;
          FJong := 0;
        end;
      end
      else
      begin
        // 받침 시도 (ㄸ/ㅃ/ㅉ 는 받침 불가 → 새 음절)
        var LJongIdx := JongIndex(AJamo);
        if LJongIdx > 0 then
        begin
          FJong := LJongIdx;
        end
        else
        begin
          ACommitted := ComposeText;
          FCho := LChoIdx;
          FJung := -1;
          FJong := 0;
        end;
      end;
    end
    else
    begin
      // 빈 상태·초성만·모음만 → 기존 조합 확정 후 새 초성 시작
      ACommitted := ComposeText;
      FCho := LChoIdx;
      FJung := -1;
      FJong := 0;
    end;
  end
  else
  begin
    // 자모가 아닌 문자: 조합 확정 후 그대로 확정 텍스트에 덧붙임
    ACommitted := ComposeText + AJamo;
    Reset;
  end;

  Result := ComposeText;
end;

function THangulComposer.GetIsComposing: Boolean;
begin
  Result := (FCho >= 0) or (FJung >= 0);
end;

procedure THangulComposer.Reset;
begin
  FCho := -1;
  FJung := -1;
  FJong := 0;
end;

{$ENDREGION}

end.
