unit uDrawBmp;

interface

uses
  Winapi.Windows, Vcl.Graphics;

procedure PaintStretchWidth(dcGround: HDC; bmp: TBitmap; sx, sy, width: Integer);
procedure PaintStretchHeight(dcGround: HDC; bmp: TBitmap; sx, sy, height: Integer);
procedure PaintBitbltWidth(dcGround: HDC; bmp: TBitmap; sx, sy: Integer);

implementation

procedure PaintStretchWidth(dcGround: HDC; bmp: TBitmap; sx, sy, width: Integer);
var
  dc: HDC;
begin
  dc := bmp.Canvas.Handle;
  Winapi.Windows.StretchBlt(dcGround, sx, sy, width, bmp.Height, dc, 0, 0,
    bmp.Width, bmp.Height, SRCCOPY);
end;

procedure PaintStretchHeight(dcGround: HDC; bmp: TBitmap; sx, sy, height: Integer);
var
  dc: HDC;
begin
  dc := bmp.Canvas.Handle;
  Winapi.Windows.StretchBlt(dcGround, sx, sy, bmp.Width, height, dc, 0, 0,
    bmp.Width, bmp.Height, SRCCOPY);
end;

// ex, ey 이 필요 없는 경우(0, 0) 전체 폭/높이로 그대로 출력
procedure PaintBitbltWidth(dcGround: HDC; bmp: TBitmap; sx, sy: Integer);
var
  dc: HDC;
begin
  dc := bmp.Canvas.Handle;
  Winapi.Windows.BitBlt(dcGround, sx, sy, bmp.Width, bmp.Height, dc, 0, 0, SRCCOPY);
end;

end.
