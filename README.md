Windows FON Font Reader Library for Free Pascal & Turbo Pascal
By RetroNick - Code Released Dec 17 - 2025

  Enhanced version with:
  - Text rotation (0°, 90°, 180°, 270°)
  - Vertical text direction
  - BGI-compatible helper functions (OutTextXY, SetTextStyle, SetTextJustify, etc.)

  Supports:
  - Windows 2.x/3.x NE format FON files
  - Both raster (bitmap) and vector (stroke) fonts
  - Scalable rendering for vector fonts

Sample ROMAN.FON
![](https://github.com/retronick2020/fonlibrary/wiki/images/fonlibrary.png)


  Usage:
    uses WinFont, PTCGraph;

    var
      Font: TWinFont;
    begin
      Font := TWinFont.Create;
      if Font.LoadFromFile('ROMAN.FON') then
      begin
        Font.Scale := 2.0;  // Scale factor for vector fonts
        Font.Rotation := rot90;  // Rotate 90 degrees
        Font.DrawText(100, 100, 'Hello World!');
        
        // Or use BGI-style functions
        Font.SetTextJustify(CenterText, CenterText);
        Font.OutTextXY(400, 300, 'Centered Text');
      end;
      Font.Free;
    end;


