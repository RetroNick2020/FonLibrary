{
  FONDEMO.PAS - Demo for TPFON unit
  Turbo Pascal 5.0 - 7.1

  There is a Free Pascal compatible version also. Do not use this in Free Pascal

  By RetroNick - Code Released Dec 17 - 2025
}

program FonDemo;

uses Crt, Graph, TPFON;

var
  GD, GM: Integer;
  Font: PFonFont;
  ErrCode: Integer;

procedure WaitKey;
begin
  while not KeyPressed do;
  ReadKey;
end;

procedure ShowInfo;
begin
  ClearDevice;
  SetColor(White);
  OutTextXY(10, 10, 'TPFON - Windows FON Font Demo');
  OutTextXY(10, 25, '=============================');

  if Font^.Loaded then
  begin
    OutTextXY(10, 50, 'Font: ' + Font^.FontName);
(*   OutTextXY(10, 65, 'Copyright: ' + Font^.Copyright^);*)
    if Font^.FontType = FON_TYPE_VECTOR then
      OutTextXY(10, 80, 'Type: Vector (Stroke)')
    else
      OutTextXY(10, 80, 'Type: Raster (Bitmap)');
    SetColor(Yellow);
    OutTextXY(10, 110, 'Press any key for demos...');
  end
  else
  begin
    SetColor(LightRed);
    OutTextXY(10, 50, 'Font not loaded!');
  end;
  WaitKey;
end;

procedure DemoScales;
begin
  ClearDevice;
  SetColor(White);
  OutTextXY(10, 10, 'Scale Demo');

  FON_SetColor(Font, LightGreen);

  FON_SetScale(Font, 1);
  FON_DrawText(Font, 50, 40, 'Scale 1: ABCDEFGHIJKLMNOP');

  FON_SetScale(Font, 2);
  FON_DrawText(Font, 50, 80, 'Scale 2: Hello World');

  FON_SetScale(Font, 3);
  FON_DrawText(Font, 50, 140, 'Scale 3: Testing');

  FON_SetScale(Font, 4);
  FON_SetColor(Font, Yellow);
  FON_DrawText(Font, 50, 220, 'Scale 4');

  FON_SetScale(Font, 5);
  FON_SetColor(Font, LightRed);
  FON_DrawText(Font, 50, 320, 'BIG!');

  SetColor(Yellow);
  OutTextXY(10, 450, 'Press any key...');
  WaitKey;
end;

procedure DemoColors;
begin
  ClearDevice;
  SetColor(White);
  OutTextXY(10, 10, 'Color Demo');

  FON_SetScale(Font, 2);

  FON_SetColor(Font, Blue);
  FON_DrawText(Font, 50, 50, 'Blue Text');

  FON_SetColor(Font, Green);
  FON_DrawText(Font, 50, 90, 'Green Text');

  FON_SetColor(Font, Cyan);
  FON_DrawText(Font, 50, 130, 'Cyan Text');

  FON_SetColor(Font, Red);
  FON_DrawText(Font, 50, 170, 'Red Text');

  FON_SetColor(Font, Magenta);
  FON_DrawText(Font, 50, 210, 'Magenta Text');

  FON_SetColor(Font, Yellow);
  FON_DrawText(Font, 50, 250, 'Yellow Text');

  FON_SetColor(Font, White);
  FON_DrawText(Font, 50, 290, 'White Text');

  SetColor(Yellow);
  OutTextXY(10, 450, 'Press any key...');
  WaitKey;
end;

procedure DemoVertical;
begin
  ClearDevice;
  SetColor(White);
  OutTextXY(10, 10, 'Vertical Text Demo');

  FON_SetScale(Font, 2);

  FON_SetDirection(Font, FON_HORIZ);
  FON_SetColor(Font, LightGreen);
  FON_DrawText(Font, 50, 50, 'Horizontal');

  FON_SetDirection(Font, FON_VERT);
  FON_SetColor(Font, LightCyan);
  FON_DrawText(Font, 50, 420, 'VERTICAL');

  FON_SetColor(Font, Yellow);
  FON_DrawText(Font, 100, 420, 'TEXT');

  FON_SetColor(Font, LightMagenta);
  FON_DrawText(Font, 150, 420, 'DEMO');

  FON_SetDirection(Font, FON_HORIZ);

  SetColor(Yellow);
  OutTextXY(10, 450, 'Press any key...');
  WaitKey;
end;

procedure DemoCharSet;
var
  Row, Col, X, Y: Integer;
  Ch: Char;
begin
  ClearDevice;
  SetColor(White);
  OutTextXY(10, 10, 'Character Set (ASCII 32-127)');

  FON_SetScale(Font, 1);
  FON_SetDirection(Font, FON_HORIZ);
  FON_SetColor(Font, LightGreen);

  Y := 40;
  for Row := 0 to 5 do
  begin
    X := 30;
    for Col := 0 to 15 do
    begin
      Ch := Chr(32 + Row * 16 + Col);
      if Ord(Ch) <= 127 then
        FON_DrawChar(Font, X, Y, Ch);
      Inc(X, 35);
    end;
    Inc(Y, Font^.Height + 8);
  end;

  SetColor(Yellow);
  OutTextXY(10, 450, 'Press any key...');
  WaitKey;
end;

procedure DemoSentences;
begin
  ClearDevice;
  SetColor(White);
  OutTextXY(10, 10, 'Sample Text');

  FON_SetDirection(Font, FON_HORIZ);

  FON_SetScale(Font, 1);
  FON_SetColor(Font, White);
  FON_DrawText(Font, 30, 40, 'The quick brown fox jumps over the lazy dog.');

  FON_SetScale(Font, 2);
  FON_SetColor(Font, LightCyan);
  FON_DrawText(Font, 30, 80, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');

  FON_SetColor(Font, Yellow);
  FON_DrawText(Font, 30, 130, 'abcdefghijklmnopqrstuvwxyz');

  FON_SetColor(Font, LightMagenta);
  FON_DrawText(Font, 30, 180, '0123456789 !@#$%^&*()');

  FON_SetScale(Font, 3);
  FON_SetColor(Font, LightGreen);
  FON_DrawText(Font, 30, 250, 'Windows Font!');

  FON_SetScale(Font, 4);
  FON_SetColor(Font, LightRed);
  FON_DrawText(Font, 30, 330, 'BIG TEXT');

  SetColor(Yellow);
  OutTextXY(10, 450, 'Press any key to exit...');
  WaitKey;
end;

begin
  ClrScr;
  WriteLn('TPFON Demo');
  WriteLn;

  Font := FON_Create;

  WriteLn('Loading font...');
  if not FON_Load(Font, 'ROMAN.FON') then
    if not FON_Load(Font, 'MODERN.FON') then
      if not FON_Load(Font, 'SCRIPT.FON') then
       if not  FON_Load(Font, 'COURB.FON') then
          if not FON_Load(Font, 'HELVB.FON') then
             WriteLn('No fonts found!');

  if Font^.Loaded then
    WriteLn('Loaded: ', Font^.FontName)
  else
    WriteLn('No font loaded!');

  WriteLn;
  WriteLn('Press any key...');
  WaitKey;

  GD := Detect;
  InitGraph(GD, GM, '');
  ErrCode := GraphResult;

  if ErrCode <> grOk then
  begin
    WriteLn('Graphics error: ', GraphErrorMsg(ErrCode));
    FON_Destroy(Font);
    Halt(1);
  end;

  ShowInfo;

  if Font^.Loaded then
  begin
    DemoScales;
    DemoColors;
    DemoVertical;
    DemoCharSet;
    DemoSentences;
  end;

  CloseGraph;
  FON_Destroy(Font);
  WriteLn('Done.');
end.
