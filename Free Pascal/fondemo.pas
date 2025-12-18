{$MODE OBJFPC}{$H+}
{
  Windows FON Font Reader Demo 

  Demonstrates:
  - Loading and displaying Windows .FON font files (Bitmap and Stroke)
  - Text rotation (0°, 90°, 180°, 270°)
  - Vertical text direction
  - BGI-compatible functions (OutTextXY, SetTextStyle, SetTextJustify, etc.)

  There is a Turbo Pascal compatible version also. Do not try to use this in Turbo Pascal

  By RetroNick - Code Released Dec 17 - 2025
}
program FonDemo;

uses
  PTCGraph, PTCCrt, SysUtils, WinFont;

const
  SCREEN_WIDTH = 800;
  SCREEN_HEIGHT = 600;
  
  // Define colors using RGB565 format for PTCGraph compatibility
  clWhite   = (31 shl 11) or (63 shl 5) or 31;  // RGB565 white
  clBlack   = 0;
  clRed     = (31 shl 11) or (0 shl 5) or 0;    // RGB565 red
  clGreen   = (0 shl 11) or (63 shl 5) or 0;    // RGB565 green
  clBlue    = (0 shl 11) or (0 shl 5) or 31;    // RGB565 blue
  clYellow  = (31 shl 11) or (63 shl 5) or 0;   // RGB565 yellow
  clMagenta = (31 shl 11) or (0 shl 5) or 31;   // RGB565 magenta
  clCyan    = (0 shl 11) or (63 shl 5) or 31;   // RGB565 cyan
  clOrange  = (31 shl 11) or (32 shl 5) or 0;   // RGB565 orange
  clGray    = (16 shl 11) or (32 shl 5) or 16;  // RGB565 gray
  clDarkGray = (8 shl 11) or (16 shl 5) or 8;   // RGB565 dark gray

var
  GD, GM: SmallInt;
  Font: TWinFont;
  Y: Integer;

procedure WaitKey;
begin
  while not KeyPressed do Delay(10);
  ReadKey;
end;

procedure ShowFontInfo;
begin
  SetColor(clWhite);
  OutTextXY(10, 10, 'Windows FON Font Reader Demo');
  OutTextXY(10, 30, '=========================================');

  if Font.Loaded then
  begin
    OutTextXY(10, 60, 'Font loaded successfully!');
    OutTextXY(10, 80, 'Name: ' + Font.FontName);
    OutTextXY(10, 100, 'Copyright: ' + Font.Copyright);
    OutTextXY(10, 120, 'Height: ' + IntToStr(Font.Height));
    OutTextXY(10, 140, 'Ascent: ' + IntToStr(Font.Ascent));
    OutTextXY(10, 160, 'First char: ' + IntToStr(Font.FirstChar));
    OutTextXY(10, 180, 'Last char: ' + IntToStr(Font.LastChar));

    case Font.FontType of
      ftVector: OutTextXY(10, 200, 'Type: Vector (Stroke)');
      ftRaster: OutTextXY(10, 200, 'Type: Raster (Bitmap)');
    else
      OutTextXY(10, 200, 'Type: Unknown');
    end;
  end
  else
  begin
    SetColor(clRed);
    OutTextXY(10, 60, 'Failed to load font!');
    OutTextXY(10, 80, 'Make sure ROMAN.FON is in current directory');
  end;
end;

procedure DemoRotation;
begin
  ClearDevice;
  SetColor(clWhite);
  OutTextXY(10, 10, 'Text Rotation Demo (0, 90, 180, 270 degrees)');
  
  Font.Scale := 2.0;
  
  // Draw crosshairs at center point
  SetColor(clDarkGray);
  Line(400, 0, 400, 600);
  Line(0, 300, 800, 300);
  
  // 0 degrees - normal horizontal
  Font.Color := RGBColor($00FF00);  // Green
  Font.Rotation := rot0;
  Font.DrawText(400, 300, '0 deg');
  
  // 90 degrees clockwise
  Font.Color := RGBColor($FF0000);  // Red
  Font.Rotation := rot90;
  Font.DrawText(400, 300, '90 deg');
  
  // 180 degrees
  Font.Color := RGBColor($0000FF);  // Blue
  Font.Rotation := rot180;
  Font.DrawText(400, 300, '180 deg');
  
  // 270 degrees (90 counter-clockwise)
  Font.Color := RGBColor($FFFF00);  // Yellow
  Font.Rotation := rot270;
  Font.DrawText(400, 300, '270 deg');
  
  // Reset
  Font.Rotation := rot0;
  
  // Labels
  SetColor(clWhite);
  OutTextXY(10, 550, 'Green=0  Red=90  Blue=180  Yellow=270');
  
  SetColor(clYellow);
  OutTextXY(10, SCREEN_HEIGHT - 30, 'Press any key to continue...');
  WaitKey;
end;

procedure DemoRotationCorners;
begin
  ClearDevice;
  SetColor(clWhite);
  OutTextXY(10, 10, 'Rotation at Screen Corners');
  
  Font.Scale := 1.5;
  Font.Color := RGBColor($00FFFF);  // Cyan
  
  // Top-left corner - text going right and down
  Font.Rotation := rot0;
  Font.DrawText(20, 50, 'Top-Left (0 deg)');
  
  Font.Rotation := rot90;
  Font.DrawText(20, 400, 'Vertical (90 deg)');
  
  // Top-right corner
  Font.Rotation := rot180;
  Font.Color := RGBColor($FF00FF);  // Magenta
  Font.DrawText(GetMaxX-10, 50, 'Top-Right (180 deg)');
  
  Font.Rotation := rot270;
  Font.DrawText(GetMaxX-30, GetMaxY-400, 'Vertical (270 deg)');
  
  // Bottom-left corner
  Font.Rotation := rot0;
  Font.Color := RGBColor($FFFF00);  // Yellow
  Font.DrawText(20, GetMaxY-60, 'Bottom-Left (0 deg)');
  
  Font.Rotation := rot270;
  Font.DrawText(80, GetMaxY-250, 'Up (270 deg)');
  
  // Bottom-right corner
  Font.Rotation := rot180;
  Font.Color := RGBColor($00FF00);  // Green
  Font.DrawText(GetMaxX-20, GetMaxY-60, 'Bottom-Right (180 deg)');
  
  Font.Rotation := rot90;
  Font.DrawText(GetMaxX-80, GetMaxY-250, 'Up (90 deg)');
  
  Font.Rotation := rot0;
  
  SetColor(clYellow);
  OutTextXY(10, SCREEN_HEIGHT - 30, 'Press any key to continue...');
  WaitKey;
end;

procedure DemoVerticalText;
begin
  ClearDevice;
  SetColor(clWhite);
  OutTextXY(10, 10, 'Vertical Text Direction Demo');
  
  Font.Scale := 1.5;
  
  // Horizontal text (normal)
  Font.SetTextStyle(HorizDir, 4);  // Use SetTextStyle to set direction properly
  Font.Color := RGBColor($00FF00);  // Green
  Font.DrawText(50, 80, 'Horizontal Text');
  
  // Vertical text using SetTextStyle (BGI compatible)
  // Text starts at bottom position and advances UPWARD
  Font.SetTextStyle(VertDir, 4);
  Font.Color := RGBColor($FF0000);  // Red
  Font.DrawText(50, 400, 'VERTICAL');  // Start low, text goes up
  
  // Vertical text at different positions
  Font.Color := RGBColor($00FFFF);  // Cyan
  Font.DrawText(120, 400, 'TEXT');
  
  Font.Color := RGBColor($FFFF00);  // Yellow
  Font.DrawText(190, 400, 'GOING');
  
  Font.Color := RGBColor($FF00FF);  // Magenta
  Font.DrawText(260, 400, 'UP');
  
  // Reset to horizontal
  Font.SetTextStyle(HorizDir, 4);
  
  SetColor(clWhite);
  OutTextXY(10, 530, 'Vertical direction: characters rotated 90 CCW,');
  OutTextXY(10, 545, 'text advances UPWARD (BGI compatible).');
  
  SetColor(clYellow);
  OutTextXY(10, SCREEN_HEIGHT - 30, 'Press any key to continue...');
  WaitKey;
end;

procedure DemoBGIJustification;
var
  CX, CY: Integer;
begin
  ClearDevice;
  SetColor(clWhite);
  OutTextXY(10, 10, 'BGI Text Justification Demo');
  
  CX := 400;  // Center X
  CY := 200;  // Center Y for first row
  
  Font.Scale := 1.5;
  Font.Rotation := rot0;
  Font.Direction := HorizDir;
  
  // Draw reference point
  SetColor(clGray);
  Line(CX - 10, CY, CX + 10, CY);
  Line(CX, CY - 10, CX, CY + 10);
  
  // Left justified (default)
  Font.SetTextJustify(LeftText, TopText);
  Font.Color := RGBColor($00FF00);  // Green
  Font.OutTextXY(CX, CY, 'Left-Top');
  
  CY := 280;
  SetColor(clGray);
  Line(CX - 10, CY, CX + 10, CY);
  Line(CX, CY - 10, CX, CY + 10);
  
  // Center justified
  Font.SetTextJustify(CenterText, CenterText);
  Font.Color := RGBColor($FF0000);  // Red
  Font.OutTextXY(CX, CY, 'Center-Center');
  
  CY := 360;
  SetColor(clGray);
  Line(CX - 10, CY, CX + 10, CY);
  Line(CX, CY - 10, CX, CY + 10);
  
  // Right justified
  Font.SetTextJustify(RightText, BottomText);
  Font.Color := RGBColor($0000FF);  // Blue
  Font.OutTextXY(CX, CY, 'Right-Bottom');
  
  // Show all 9 combinations in a grid
  CY := 480;
  Font.Scale := 1.0;
  SetColor(clWhite);
  OutTextXY(50, 440, 'All justification combinations (crosshair = anchor point):');
  
  // Three columns at X = 150, 400, 650
  // LeftText, CenterText, RightText
  SetColor(clDarkGray);
  Line(150, CY - 20, 150, CY + 50);
  Line(400, CY - 20, 400, CY + 50);
  Line(650, CY - 20, 650, CY + 50);
  Line(100, CY, 700, CY);
  
  Font.Color := RGBColor($FFFF00);  // Yellow
  Font.SetTextJustify(LeftText, CenterText);
  Font.OutTextXY(150, CY, 'L');
  
  Font.SetTextJustify(CenterText, CenterText);
  Font.OutTextXY(400, CY, 'C');
  
  Font.SetTextJustify(RightText, CenterText);
  Font.OutTextXY(650, CY, 'R');
  
  // Reset justification
  Font.SetTextJustify(LeftText, TopText);
  
  SetColor(clYellow);
  OutTextXY(10, SCREEN_HEIGHT - 30, 'Press any key to continue...');
  WaitKey;
end;

procedure DemoBGITextStyle;
begin
  ClearDevice;
  SetColor(clWhite);
  OutTextXY(10, 10, 'BGI SetTextStyle Demo');
  OutTextXY(10, 30, 'SetTextStyle(Direction, CharSize)');
  
  Y := 80;
  Font.Color := RGBColor($00FF00);  // Green
  
  // Different character sizes (1-10)
  Font.SetTextStyle(HorizDir, 1);
  Font.OutTextXY(50, Y, 'Size 1');
  
  Font.SetTextStyle(HorizDir, 2);
  Y := Y + 30;
  Font.OutTextXY(50, Y, 'Size 2');
  
  Font.SetTextStyle(HorizDir, 4);
  Y := Y + 40;
  Font.OutTextXY(50, Y, 'Size 4 (Default)');
  
  Font.SetTextStyle(HorizDir, 6);
  Y := Y + 50;
  Font.OutTextXY(50, Y, 'Size 6');
  
  Font.SetTextStyle(HorizDir, 8);
  Y := Y + 70;
  Font.OutTextXY(50, Y, 'Size 8');
  
  // Vertical direction - text goes UPWARD from starting position
  Font.Color := RGBColor($FF0000);  // Red
  Font.SetTextStyle(VertDir, 4);
  Font.OutTextXY(550, 450, 'VERTICAL');  // Start low, goes up
  
  Font.SetTextStyle(VertDir, 6);
  Font.OutTextXY(650, 500, 'UP!');  // Start low, goes up
  
  // Reset
  Font.SetTextStyle(HorizDir, 4);
  
  SetColor(clYellow);
  OutTextXY(10, SCREEN_HEIGHT - 30, 'Press any key to continue...');
  WaitKey;
end;

procedure DemoRotatedJustification;
begin
  ClearDevice;
  SetColor(clWhite);
  OutTextXY(10, 10, 'Rotated Text with Justification');
  
  Font.Scale := 1.5;
  
  // Center of screen
  SetColor(clGray);
  Line(400, 0, 400, 600);
  Line(0, 300, 800, 300);
  
  // Center justified text at each rotation
  Font.SetTextJustify(CenterText, CenterText);
  
  // 0 degrees
  Font.Rotation := rot0;
  Font.Color := RGBColor($00FF00);  // Green
  Font.OutTextXY(400, 250, 'Centered 0');
  
  // 90 degrees
  Font.Rotation := rot90;
  Font.Color := RGBColor($FF0000);  // Red
  Font.OutTextXY(450, 300, 'Centered 90');
  
  // 180 degrees
  Font.Rotation := rot180;
  Font.Color := RGBColor($0000FF);  // Blue
  Font.OutTextXY(400, 350, 'Centered 180');
  
  // 270 degrees
  Font.Rotation := rot270;
  Font.Color := RGBColor($FFFF00);  // Yellow
  Font.OutTextXY(350, 300, 'Centered 270');
  
  // Reset
  Font.Rotation := rot0;
  Font.SetTextJustify(LeftText, TopText);
  
  SetColor(clWhite);
  OutTextXY(10, 550, 'All text is center-justified at their anchor points');
  
  SetColor(clYellow);
  OutTextXY(10, SCREEN_HEIGHT - 30, 'Press any key to continue...');
  WaitKey;
end;

procedure DemoScales;
begin
  ClearDevice;
  SetColor(clWhite);
  OutTextXY(10, 10, 'Font Scale Test');

  // Draw at scale 1.0
  Font.Scale := 1.0;
  Font.Color := RGBColor($FFFFFF);  // White
  Font.Rotation := rot0;
  OutTextXY(10, 40, 'Scale 1.0:');
  Font.DrawText(120, 40, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
  Font.DrawText(120, 70, 'abcdefghijklmnopqrstuvwxyz');
  Font.DrawText(120, 100, '0123456789 !@#$%^&*()');

  // Draw at scale 2.0
  Font.Scale := 2.0;
  OutTextXY(10, 140, 'Scale 2.0:');
  Font.DrawText(120, 140, 'Hello World!');
  Font.DrawText(120, 190, '0123456789');

  // Draw at scale 3.0
  Font.Scale := 3.0;
  OutTextXY(10, 240, 'Scale 3.0:');
  Font.DrawText(120, 240, 'ABC 123');

  // Show font info
  Font.Scale := 1.0;
  SetColor(clCyan);
  OutTextXY(10, 360, 'Font: ' + Font.FontName);
  if Font.FontType = ftVector then
    OutTextXY(10, 380, 'Type: Vector (Stroke)')
  else if Font.FontType = ftRaster then
    OutTextXY(10, 380, 'Type: Raster (Bitmap)');
  OutTextXY(10, 400, 'Height: ' + IntToStr(Font.Height));
  OutTextXY(10, 420, 'Ascent: ' + IntToStr(Font.Ascent));

  SetColor(clYellow);
  OutTextXY(10, SCREEN_HEIGHT - 30, 'Press any key to continue...');
  WaitKey;
end;

procedure DemoColors;
var
  Colors: array[0..5] of LongWord;
  ColorNames: array[0..5] of string = ('Red', 'Green', 'Blue', 'Yellow', 'Magenta', 'Cyan');
  I: Integer;
begin
  // Initialize colors using RGBColor helper
  Colors[0] := RGBColor($FF0000);  // Red
  Colors[1] := RGBColor($00FF00);  // Green
  Colors[2] := RGBColor($0000FF);  // Blue
  Colors[3] := RGBColor($FFFF00);  // Yellow
  Colors[4] := RGBColor($FF00FF);  // Magenta
  Colors[5] := RGBColor($00FFFF);  // Cyan

  ClearDevice;
  SetColor(clWhite);
  OutTextXY(10, 10, 'Font in different colors:');

  Font.Scale := 2.0;
  Font.Rotation := rot0;
  Y := 60;

  for I := 0 to 5 do
  begin
    Font.Color := Colors[I];
    Font.DrawText(50, Y, ColorNames[I] + ' Text Sample');
    Y := Y + Round(Font.Height * Font.Scale) + 15;
  end;

  SetColor(clYellow);
  OutTextXY(10, SCREEN_HEIGHT - 30, 'Press any key to continue...');
  WaitKey;
end;

procedure DemoCharSet;
var
  Row, Col: Integer;
  C: Char;
  X: Integer;
begin
  ClearDevice;
  SetColor(clWhite);
  OutTextXY(10, 10, 'Character set (ASCII 32-127):');

  Font.Scale := 1.5;
  Font.Color := RGBColor($00FF00);  // Green
  Font.Rotation := rot0;

  Y := 60;
  for Row := 0 to 5 do
  begin
    X := 50;
    for Col := 0 to 15 do
    begin
      C := Chr(32 + Row * 16 + Col);
      if Ord(C) <= 127 then
        Font.DrawChar(X, Y, C);
      X := X + 45;
    end;
    Y := Y + Round(Font.Height * Font.Scale) + 10;
  end;

  SetColor(clYellow);
  OutTextXY(10, SCREEN_HEIGHT - 30, 'Press any key to continue...');
  WaitKey;
end;

procedure DemoSentences;
begin
  ClearDevice;
  SetColor(clWhite);
  OutTextXY(10, 10, 'Sample text rendering:');

  Font.Scale := 1.0;
  Font.Color := RGBColor($FFFFFF);  // White
  Font.Rotation := rot0;
  Y := 60;
  Font.DrawText(50, Y, 'The quick brown fox jumps over the lazy dog.');

  Y := Y + 40;
  Font.Scale := 1.5;
  Font.Color := RGBColor($00FFFF);  // Cyan
  Font.DrawText(50, Y, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');

  Y := Y + 50;
  Font.Color := RGBColor($FFFF00);  // Yellow
  Font.DrawText(50, Y, 'abcdefghijklmnopqrstuvwxyz');

  Y := Y + 50;
  Font.Scale := 2.0;
  Font.Color := RGBColor($FF8000);  // Orange
  Font.DrawText(50, Y, '0123456789 !@#$%^&*()');

  Y := Y + 70;
  Font.Scale := 3.0;
  Font.Color := RGBColor($FF00FF);  // Magenta
  Font.DrawText(50, Y, 'Vector Font!');

  Y := Y + 100;
  Font.Scale := 4.0;
  Font.Color := RGBColor($00FF00);  // Green
  Font.DrawText(50, Y, 'BIG TEXT');

  SetColor(clYellow);
  OutTextXY(10, SCREEN_HEIGHT - 30, 'Press any key to exit...');
  WaitKey;
end;

begin
  // Create font first so we can enable debug mode
  Font := TWinFont.Create;
  Font.DebugMode := True;  // Enable debug output to console

  // Try to load font before graphics mode
  WriteLn('Loading font...');
  if not Font.LoadFromFile('ROMAN.FON') then
  begin
    // Try alternate fonts
    if not Font.LoadFromFile('COURB.FON') then
      Font.LoadFromFile('MODERN.FON');
  end;

  if Font.Loaded then
    WriteLn('Font loaded successfully: ', Font.FontName)
  else
    WriteLn('Failed to load font');

  WriteLn('Press Enter to start graphics mode...');
  ReadLn;

  // Initialize graphics
  GD := VESA;
  GM := m800x600x32k;
  InitGraph(GD, GM, '');

  if GraphResult <> grOk then
  begin
    WriteLn('Graphics initialization failed!');
    Font.Free;
    Halt(1);
  end;

  // Show font info
  ShowFontInfo;

  if Font.Loaded then
  begin
    SetColor(clYellow);
    OutTextXY(10, SCREEN_HEIGHT - 30, 'Press any key to see demos...');
    WaitKey;

    // Original demos
    DemoScales;
    DemoColors;
    DemoCharSet;
    
    // New rotation and BGI demos
    DemoRotation;
    DemoRotationCorners;
    DemoVerticalText;
    DemoBGIJustification;
    DemoBGITextStyle;
    DemoRotatedJustification;
    
    // Final demo
    DemoSentences;
  end
  else
  begin
    SetColor(clYellow);
    OutTextXY(10, SCREEN_HEIGHT - 30, 'Press any key to exit...');
    WaitKey;
  end;

  // Cleanup
  Font.Free;
  CloseGraph;
end.
