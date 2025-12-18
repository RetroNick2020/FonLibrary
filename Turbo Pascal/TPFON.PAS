{
  TPFON.PAS - Windows FON Font Display Unit for Turbo Pascal

  Compatible with Turbo Pascal 5.0 through 7.1

  There is a Free Pascal compatible version also. Do not use this in Free Pascal

  By RetroNick - Code Released Dec 17 - 2025

  Usage:
    uses Graph, TPFON;

    var F: PFonFont;
    begin
      InitGraph(...);
      F := FON_Create;
      if FON_Load(F, 'ROMAN.FON') then
      begin
        FON_SetColor(F, White);
        FON_SetScale(F, 2);
        FON_DrawText(F, 100, 100, 'Hello World');
      end;
      FON_Destroy(F);
      CloseGraph;
    end;
}

unit TPFON;

interface

uses Graph;

const
  FON_MAX_GLYPHS = 256;
  FON_MAX_STROKES = 128;   { Reduced - most glyphs have < 50 strokes }
  FON_MAX_BITMAP = 128;    { Reduced - most chars < 16x16 }

  FON_TYPE_UNKNOWN = 0;
  FON_TYPE_VECTOR = 1;
  FON_TYPE_RASTER = 2;

  FON_HORIZ = 0;
  FON_VERT = 1;

  FON_CMD_MOVE = 1;
  FON_CMD_LINE = 2;

type
  { Smaller stroke record - 5 bytes }
  TStroke = record
    Cmd: Byte;
    X, Y: Integer;
  end;

  { Glyph record - uses pointers, allocated on demand }
  PStrokeData = ^TStrokeData;
  TStrokeData = array[0..FON_MAX_STROKES-1] of TStroke;

  PBitmapData = ^TBitmapData;
  TBitmapData = array[0..FON_MAX_BITMAP-1] of Byte;

  PGlyph = ^TGlyph;
  TGlyph = record
    Width: Byte;
    Height: Byte;
    Defined: Boolean;
    BitmapWidth: Byte;
    StrokeCount: Byte;
    Bitmap: PBitmapData;
    Strokes: PStrokeData;
  end;
  
  { Glyph table }
  TGlyphTable = array[0..FON_MAX_GLYPHS-1] of TGlyph;
  PGlyphTable = ^TGlyphTable;
  
  PFonFont = ^TFonFont;
  TFonFont = record
    Loaded: Boolean;
    FontType: Byte;
    FontName: string[31];
    Height: Byte;
    Ascent: Byte;
    FirstChar: Byte;
    LastChar: Byte;
    DefaultChar: Byte;
    Scale: Byte;
    Color: Byte;
    Direction: Byte;
    Glyphs: PGlyphTable;
  end;

function FON_Create: PFonFont;
procedure FON_Destroy(F: PFonFont);
function FON_Load(F: PFonFont; FileName: string): Boolean;
procedure FON_SetColor(F: PFonFont; C: Integer);
procedure FON_SetScale(F: PFonFont; S: Integer);
procedure FON_SetDirection(F: PFonFont; Dir: Integer);
procedure FON_DrawChar(F: PFonFont; X, Y: Integer; Ch: Char);
procedure FON_DrawText(F: PFonFont; X, Y: Integer; S: string);
function FON_CharWidth(F: PFonFont; Ch: Char): Integer;
function FON_TextWidth(F: PFonFont; S: string): Integer;
function FON_TextHeight(F: PFonFont): Integer;

implementation

var
  FF: File;
  FBuf: array[0..4095] of Byte;  { Smaller buffer }
  FBufSize: Word;
  FFileSize: LongInt;

function ReadW(Ofs: Word): Word;
begin
  ReadW := Word(FBuf[Ofs]) or (Word(FBuf[Ofs+1]) shl 8);
end;

function ReadDW(Ofs: Word): LongInt;
begin
  ReadDW := LongInt(FBuf[Ofs]) or 
            (LongInt(FBuf[Ofs+1]) shl 8) or
            (LongInt(FBuf[Ofs+2]) shl 16) or
            (LongInt(FBuf[Ofs+3]) shl 24);
end;

procedure SeekRead(Pos: LongInt; Size: Word);
begin
  if Size > 4096 then Size := 4096;
  Seek(FF, Pos);
  BlockRead(FF, FBuf, Size, FBufSize);
end;

function FON_Create: PFonFont;
var
  F: PFonFont;
  I: Integer;
begin
  GetMem(F, SizeOf(TFonFont));
  
  F^.Loaded := False;
  F^.FontType := FON_TYPE_UNKNOWN;
  F^.FontName := '';
  F^.Height := 0;
  F^.Ascent := 0;
  F^.FirstChar := 32;
  F^.LastChar := 127;
  F^.DefaultChar := 32;
  F^.Scale := 1;
  F^.Color := 15;
  F^.Direction := FON_HORIZ;
  
  GetMem(F^.Glyphs, SizeOf(TGlyphTable));
  
  for I := 0 to FON_MAX_GLYPHS - 1 do
  begin
    F^.Glyphs^[I].Width := 0;
    F^.Glyphs^[I].Height := 0;
    F^.Glyphs^[I].Defined := False;
    F^.Glyphs^[I].BitmapWidth := 0;
    F^.Glyphs^[I].StrokeCount := 0;
    F^.Glyphs^[I].Bitmap := nil;
    F^.Glyphs^[I].Strokes := nil;
  end;
  
  FON_Create := F;
end;

procedure FON_Destroy(F: PFonFont);
var
  I: Integer;
begin
  if F = nil then Exit;
  
  if F^.Glyphs <> nil then
  begin
    for I := 0 to FON_MAX_GLYPHS - 1 do
    begin
      if F^.Glyphs^[I].Bitmap <> nil then
        FreeMem(F^.Glyphs^[I].Bitmap, SizeOf(TBitmapData));
      if F^.Glyphs^[I].Strokes <> nil then
        FreeMem(F^.Glyphs^[I].Strokes, SizeOf(TStrokeData));
    end;
    FreeMem(F^.Glyphs, SizeOf(TGlyphTable));
  end;
  
  FreeMem(F, SizeOf(TFonFont));
end;

procedure ClearGlyphs(F: PFonFont);
var
  I: Integer;
begin
  for I := 0 to FON_MAX_GLYPHS - 1 do
  begin
    if F^.Glyphs^[I].Bitmap <> nil then
    begin
      FreeMem(F^.Glyphs^[I].Bitmap, SizeOf(TBitmapData));
      F^.Glyphs^[I].Bitmap := nil;
    end;
    if F^.Glyphs^[I].Strokes <> nil then
    begin
      FreeMem(F^.Glyphs^[I].Strokes, SizeOf(TStrokeData));
      F^.Glyphs^[I].Strokes := nil;
    end;
    F^.Glyphs^[I].Defined := False;
    F^.Glyphs^[I].Width := 0;
    F^.Glyphs^[I].Height := 0;
    F^.Glyphs^[I].BitmapWidth := 0;
    F^.Glyphs^[I].StrokeCount := 0;
  end;
end;

procedure ParseVectorGlyphs(F: PFonFont; FNTOfs: LongInt; CharTableOfs: LongInt; StrokeBase: LongInt);
var
  NumChars: Integer;
  CharOffsets: array[0..127] of Word;  { Reduced size }
  I, J, CharIdx: Integer;
  GlyphOfs, GlyphWidth: Word;
  NextOfs: Word;
  StrokePos, StrokeEnd: LongInt;
  StrokeLen: Word;
  B: Byte;
  DX, DY: Integer;
  CurX, CurY: Integer;
  SC: Integer;
  DataOfs: Integer;
begin
  NumChars := F^.LastChar - F^.FirstChar + 2;
  if NumChars > 127 then NumChars := 127;
  
  { Read character offsets }
  for I := 0 to NumChars - 1 do
  begin
    SeekRead(CharTableOfs + LongInt(I) * 4, 4);
    CharOffsets[I] := ReadW(0);
  end;
  
  for I := 0 to NumChars - 2 do
  begin
    CharIdx := F^.FirstChar + I;
    if (CharIdx < 0) or (CharIdx >= FON_MAX_GLYPHS) then Continue;
    
    SeekRead(CharTableOfs + LongInt(I) * 4, 4);
    GlyphOfs := ReadW(0);
    GlyphWidth := ReadW(2);
    
    F^.Glyphs^[CharIdx].Width := GlyphWidth;
    F^.Glyphs^[CharIdx].Height := F^.Height;
    F^.Glyphs^[CharIdx].Defined := True;
    F^.Glyphs^[CharIdx].StrokeCount := 0;
    
    if GlyphWidth = 0 then Continue;
    
    { Check if has stroke data }
    if (I + 1 < NumChars) and (CharOffsets[I] >= CharOffsets[I + 1]) then
      Continue;
    
    { Find end boundary }
    NextOfs := GlyphOfs;
    for J := I + 1 to NumChars - 1 do
    begin
      if CharOffsets[J] > GlyphOfs then
      begin
        NextOfs := CharOffsets[J];
        Break;
      end;
    end;
    
    if NextOfs <= GlyphOfs then Continue;
    
    StrokePos := StrokeBase + GlyphOfs;
    StrokeEnd := StrokeBase + NextOfs;
    
    if StrokePos >= FFileSize then Continue;
    if StrokeEnd > FFileSize then StrokeEnd := FFileSize;
    
    StrokeLen := StrokeEnd - StrokePos;
    if StrokeLen > 4096 then StrokeLen := 4096;
    
    { Read stroke data first to count }
    SeekRead(StrokePos, StrokeLen);
    
    { Count strokes first }
    SC := 0;
    DataOfs := 0;
    while (DataOfs < StrokeLen) and (SC < FON_MAX_STROKES) do
    begin
      B := FBuf[DataOfs];
      Inc(DataOfs);
      if B = $80 then
      begin
        Inc(DataOfs, 2);
        Inc(SC);
      end
      else
      begin
        Inc(DataOfs);
        Inc(SC);
      end;
    end;
    
    if SC = 0 then Continue;
    if SC > FON_MAX_STROKES then SC := FON_MAX_STROKES;
    
    { Now allocate and parse }
    GetMem(F^.Glyphs^[CharIdx].Strokes, SizeOf(TStrokeData));
    
    SC := 0;
    CurX := 0;
    CurY := 0;
    DataOfs := 0;
    
    while (DataOfs < StrokeLen) and (SC < FON_MAX_STROKES) do
    begin
      B := FBuf[DataOfs];
      Inc(DataOfs);
      
      if B = $80 then
      begin
        if DataOfs + 1 >= StrokeLen then Break;
        
        if FBuf[DataOfs] < 128 then
          DX := FBuf[DataOfs]
        else
          DX := Integer(FBuf[DataOfs]) - 256;
        Inc(DataOfs);
        
        if FBuf[DataOfs] < 128 then
          DY := FBuf[DataOfs]
        else
          DY := Integer(FBuf[DataOfs]) - 256;
        Inc(DataOfs);
        
        CurX := CurX + DX;
        CurY := CurY + DY;
        
        F^.Glyphs^[CharIdx].Strokes^[SC].Cmd := FON_CMD_MOVE;
        F^.Glyphs^[CharIdx].Strokes^[SC].X := CurX;
        F^.Glyphs^[CharIdx].Strokes^[SC].Y := CurY;
        Inc(SC);
      end
      else
      begin
        if FBuf[DataOfs - 1] < 128 then
          DX := FBuf[DataOfs - 1]
        else
          DX := Integer(FBuf[DataOfs - 1]) - 256;
        
        if DataOfs >= StrokeLen then Break;
        
        if FBuf[DataOfs] < 128 then
          DY := FBuf[DataOfs]
        else
          DY := Integer(FBuf[DataOfs]) - 256;
        Inc(DataOfs);
        
        CurX := CurX + DX;
        CurY := CurY + DY;
        
        F^.Glyphs^[CharIdx].Strokes^[SC].Cmd := FON_CMD_LINE;
        F^.Glyphs^[CharIdx].Strokes^[SC].X := CurX;
        F^.Glyphs^[CharIdx].Strokes^[SC].Y := CurY;
        Inc(SC);
      end;
    end;
    
    F^.Glyphs^[CharIdx].StrokeCount := SC;
  end;
end;

procedure ParseRasterGlyphs(F: PFonFont; FNTOfs: LongInt; CharTableOfs: LongInt);
var
  NumChars: Integer;
  I, J, CharIdx: Integer;
  GlyphWidth: Word;
  BitmapOfs: Word;
  BytesPerRow: Integer;
  BitmapSize: Integer;
begin
  NumChars := F^.LastChar - F^.FirstChar + 1;
  
  for I := 0 to NumChars - 1 do
  begin
    CharIdx := F^.FirstChar + I;
    if (CharIdx < 0) or (CharIdx >= FON_MAX_GLYPHS) then Continue;
    
    SeekRead(CharTableOfs + LongInt(I) * 4, 4);
    GlyphWidth := ReadW(0);
    BitmapOfs := ReadW(2);
    
    F^.Glyphs^[CharIdx].Width := GlyphWidth;
    F^.Glyphs^[CharIdx].Height := F^.Height;
    
    if GlyphWidth = 0 then Continue;
    
    BytesPerRow := (GlyphWidth + 7) div 8;
    BitmapSize := BytesPerRow * F^.Height;
    
    if BitmapSize > FON_MAX_BITMAP then
      BitmapSize := FON_MAX_BITMAP;
    
    F^.Glyphs^[CharIdx].BitmapWidth := BytesPerRow;
    
    if FNTOfs + BitmapOfs + BitmapSize > FFileSize then Continue;
    
    GetMem(F^.Glyphs^[CharIdx].Bitmap, SizeOf(TBitmapData));
    FillChar(F^.Glyphs^[CharIdx].Bitmap^, SizeOf(TBitmapData), 0);
    
    SeekRead(FNTOfs + BitmapOfs, BitmapSize);
    
    for J := 0 to BitmapSize - 1 do
      F^.Glyphs^[CharIdx].Bitmap^[J] := FBuf[J];
    
    F^.Glyphs^[CharIdx].Defined := True;
  end;
end;

function FON_Load(F: PFonFont; FileName: string): Boolean;
var
  NEOfs: LongInt;
  ResTableOfs: LongInt;
  AlignShift: Word;
  AlignSize: LongInt;
  TypeID, ResCount: Word;
  ResOfs, ResLen: Word;
  FontOfs, FontLen: LongInt;
  Found: Boolean;
  I: Integer;
  Version: Word;
  FntType: Word;
  CharTableOfs: LongInt;
  StrokeBase: LongInt;
  NumChars: Integer;
  FaceOfs: LongInt;
  NameLen: Integer;
begin
  FON_Load := False;
  if F = nil then Exit;
  
  ClearGlyphs(F);
  F^.Loaded := False;
  
  Assign(FF, FileName);
  {$I-}
  Reset(FF, 1);
  {$I+}
  if IOResult <> 0 then Exit;
  
  FFileSize := FileSize(FF);
  
  { Read MZ header }
  SeekRead(0, 64);
  if FBufSize < 64 then begin Close(FF); Exit; end;
  if (FBuf[0] <> $4D) or (FBuf[1] <> $5A) then begin Close(FF); Exit; end;
  
  NEOfs := ReadDW($3C);
  if NEOfs < 64 then begin Close(FF); Exit; end;
  
  { Read NE header }
  SeekRead(NEOfs, 64);
  if FBufSize < 64 then begin Close(FF); Exit; end;
  if ReadW(0) <> $454E then begin Close(FF); Exit; end;
  
  ResTableOfs := NEOfs + ReadW($24);
  
  SeekRead(ResTableOfs, 2);
  AlignShift := ReadW(0);
  AlignSize := LongInt(1) shl AlignShift;
  
  Seek(FF, ResTableOfs + 2);
  FontOfs := 0;
  FontLen := 0;
  Found := False;
  
  repeat
    BlockRead(FF, FBuf, 8, FBufSize);
    if FBufSize < 8 then Break;
    
    TypeID := ReadW(0);
    if TypeID = 0 then Break;
    
    ResCount := ReadW(2);
    
    for I := 1 to ResCount do
    begin
      BlockRead(FF, FBuf, 12, FBufSize);
      if FBufSize < 12 then Break;
      
      if (TypeID = $8008) or (TypeID = 8) then
      begin
        if not Found then
        begin
          ResOfs := ReadW(0);
          ResLen := ReadW(2);
          FontOfs := LongInt(ResOfs) * AlignSize;
          FontLen := LongInt(ResLen) * AlignSize;
          Found := True;
        end;
      end;
    end;
  until Found or (TypeID = 0);
  
  if not Found then begin Close(FF); Exit; end;
  
  if FontLen > 4096 then FontLen := 4096;
  SeekRead(FontOfs, FontLen);
  if FBufSize < 118 then begin Close(FF); Exit; end;
  
  Version := ReadW(0);
  
  { Face name at offset 105 }
  FaceOfs := ReadDW(105);
  if (FaceOfs > 0) and (FaceOfs < FBufSize) then
  begin
    NameLen := 0;
    I := FaceOfs;
    while (NameLen < 31) and (I < FBufSize) and (FBuf[I] <> 0) do
    begin
      F^.FontName[NameLen + 1] := Chr(FBuf[I]);
      Inc(NameLen);
      Inc(I);
    end;
    F^.FontName[0] := Chr(NameLen);
  end;
  
  FntType := ReadW(66);
  F^.Ascent := ReadW(74);
  F^.Height := ReadW(88);
  F^.FirstChar := FBuf[95];
  F^.LastChar := FBuf[96];
  F^.DefaultChar := FBuf[97] + F^.FirstChar;
  
  if Version = $0100 then
    CharTableOfs := FontOfs + 117
  else
    CharTableOfs := FontOfs + 118;
  
  NumChars := F^.LastChar - F^.FirstChar + 2;
  StrokeBase := CharTableOfs + LongInt(NumChars) * 4;
  
  { Find stroke data start }
  SeekRead(StrokeBase, 128);
  for I := 0 to 99 do
  begin
    if FBuf[I] = $80 then
    begin
      StrokeBase := StrokeBase + I;
      Break;
    end;
  end;
  
  if (FntType and $0001) <> 0 then
  begin
    F^.FontType := FON_TYPE_VECTOR;
    ParseVectorGlyphs(F, FontOfs, CharTableOfs, StrokeBase);
  end
  else
  begin
    F^.FontType := FON_TYPE_RASTER;
    ParseRasterGlyphs(F, FontOfs, CharTableOfs);
  end;
  
  Close(FF);
  F^.Loaded := True;
  FON_Load := True;
end;

procedure FON_SetColor(F: PFonFont; C: Integer);
begin
  if F <> nil then F^.Color := C;
end;

procedure FON_SetScale(F: PFonFont; S: Integer);
begin
  if F = nil then Exit;
  if S < 1 then S := 1;
  if S > 10 then S := 10;
  F^.Scale := S;
end;

procedure FON_SetDirection(F: PFonFont; Dir: Integer);
begin
  if F = nil then Exit;
  if Dir = FON_VERT then
    F^.Direction := FON_VERT
  else
    F^.Direction := FON_HORIZ;
end;

procedure DrawVectorGlyph(F: PFonFont; X, Y: Integer; CharIdx: Integer);
var
  I: Integer;
  CurX, CurY: Integer;
  PX, PY: Integer;
  LastX, LastY: Integer;
  S: Integer;
begin
  if F^.Glyphs^[CharIdx].Strokes = nil then Exit;
  if F^.Glyphs^[CharIdx].StrokeCount = 0 then Exit;
  
  S := F^.Scale;
  LastX := X;
  LastY := Y;
  
  SetColor(F^.Color);
  
  for I := 0 to F^.Glyphs^[CharIdx].StrokeCount - 1 do
  begin
    PX := F^.Glyphs^[CharIdx].Strokes^[I].X;
    PY := F^.Glyphs^[CharIdx].Strokes^[I].Y;
    
    if F^.Direction = FON_VERT then
    begin
      { 90° CW rotation: top of letters point left }
      CurX := X + PY * S;
      CurY := Y - PX * S;
    end
    else
    begin
      CurX := X + PX * S;
      CurY := Y + PY * S;
    end;
    
    case F^.Glyphs^[CharIdx].Strokes^[I].Cmd of
      FON_CMD_MOVE:
        begin
          LastX := CurX;
          LastY := CurY;
        end;
      FON_CMD_LINE:
        begin
          Line(LastX, LastY, CurX, CurY);
          LastX := CurX;
          LastY := CurY;
        end;
    end;
  end;
end;

procedure DrawRasterGlyph(F: PFonFont; X, Y: Integer; CharIdx: Integer);
var
  Row, Col: Integer;
  Plane, ByteIdx, BitIdx: Integer;
  ByteVal: Byte;
  SX, SY: Integer;
  S: Integer;
  GW, GH: Integer;
begin
  if F^.Glyphs^[CharIdx].Bitmap = nil then Exit;
  
  S := F^.Scale;
  GW := F^.Glyphs^[CharIdx].Width;
  GH := F^.Glyphs^[CharIdx].Height;
  
  for Row := 0 to GH - 1 do
  begin
    for Col := 0 to GW - 1 do
    begin
      Plane := Col div 8;
      ByteIdx := Plane * GH + Row;
      BitIdx := 7 - (Col mod 8);
      
      if ByteIdx < FON_MAX_BITMAP then
      begin
        ByteVal := F^.Glyphs^[CharIdx].Bitmap^[ByteIdx];
        
        if (ByteVal and (1 shl BitIdx)) <> 0 then
        begin
          if F^.Direction = FON_VERT then
          begin
            { 90° CW rotation: top of letters point left }
            for SY := 0 to S - 1 do
              for SX := 0 to S - 1 do
                PutPixel(X + Row * S + SX, Y + (GW - 1 - Col) * S + SY, F^.Color);
          end
          else
          begin
            for SY := 0 to S - 1 do
              for SX := 0 to S - 1 do
                PutPixel(X + Col * S + SX, Y + Row * S + SY, F^.Color);
          end;
        end;
      end;
    end;
  end;
end;

procedure FON_DrawChar(F: PFonFont; X, Y: Integer; Ch: Char);
var
  CharIdx: Integer;
begin
  if F = nil then Exit;
  if not F^.Loaded then Exit;
  
  CharIdx := Ord(Ch);
  
  if CharIdx = 32 then Exit;
  
  if (CharIdx < F^.FirstChar) or (CharIdx > F^.LastChar) then
    CharIdx := F^.DefaultChar;
  
  if not F^.Glyphs^[CharIdx].Defined then Exit;
  
  if F^.FontType = FON_TYPE_VECTOR then
    DrawVectorGlyph(F, X, Y, CharIdx)
  else
    DrawRasterGlyph(F, X, Y, CharIdx);
end;

procedure FON_DrawText(F: PFonFont; X, Y: Integer; S: string);
var
  I: Integer;
  CurX, CurY: Integer;
  CharIdx: Integer;
  CharW: Integer;
begin
  if F = nil then Exit;
  if not F^.Loaded then Exit;
  
  CurX := X;
  CurY := Y;
  
  for I := 1 to Length(S) do
  begin
    CharIdx := Ord(S[I]);
    if (CharIdx < F^.FirstChar) or (CharIdx > F^.LastChar) then
      CharIdx := F^.DefaultChar;
    
    if CharIdx <> 32 then
      FON_DrawChar(F, CurX, CurY, S[I]);
    
    CharW := F^.Glyphs^[CharIdx].Width;
    if CharW = 0 then CharW := F^.Height div 2;
    CharW := CharW * F^.Scale;
    
    if F^.Direction = FON_VERT then
      Dec(CurY, CharW)   { Advance upward for vertical text }
    else
      Inc(CurX, CharW);
  end;
end;

function FON_CharWidth(F: PFonFont; Ch: Char): Integer;
var
  CharIdx: Integer;
  W: Integer;
begin
  FON_CharWidth := 0;
  if F = nil then Exit;
  if not F^.Loaded then Exit;
  
  CharIdx := Ord(Ch);
  if (CharIdx < F^.FirstChar) or (CharIdx > F^.LastChar) then
    CharIdx := F^.DefaultChar;
  
  W := F^.Glyphs^[CharIdx].Width;
  if W = 0 then W := F^.Height div 2;
  
  FON_CharWidth := W * F^.Scale;
end;

function FON_TextWidth(F: PFonFont; S: string): Integer;
var
  I, Total: Integer;
begin
  Total := 0;
  if F <> nil then
    for I := 1 to Length(S) do
      Inc(Total, FON_CharWidth(F, S[I]));
  FON_TextWidth := Total;
end;

function FON_TextHeight(F: PFonFont): Integer;
begin
  if (F <> nil) and F^.Loaded then
    FON_TextHeight := F^.Height * F^.Scale
  else
    FON_TextHeight := 0;
end;

end.
