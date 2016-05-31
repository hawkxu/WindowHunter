unit Common;

{$mode objfpc}{$H+}

interface

uses
  Windows, Classes, SysUtils, LCLTranslator;

resourcestring
  RS_ID = 'ID';
  RS_VISIBLE = 'Visible';
  RS_CLASS = 'Class';
  RS_TEXT = 'Text';
  RS_APPLICATION = 'Application';
  RS_VERSION = 'Version: ';

const
  CUR_LOCATE = 1;

function GetSelfVersion: String;

implementation

function GetSelfVersion: String;
var
  iBufferSize: DWORD;
  iDummy: DWORD;
  pBuffer: Pointer;
  pFileInfo: Pointer;
  V1, V2, V3, V4: Word;
begin
  Result := '';
  iBufferSize := GetFileVersionInfoSize(PChar(ParamStr(0)), iDummy);
  if (iBufferSize > 0) then
  begin
    Getmem(pBuffer, iBufferSize);
    try
      // get fixed file info
      GetFileVersionInfo(PChar(ParamStr(0)), 0, iBufferSize, pBuffer);
      VerQueryValue(pBuffer, '\', pFileInfo, iDummy);
      // read version blocks
      V1 := HiWord(PVSFixedFileInfo(pFileInfo)^.dwFileVersionMS);
      V2 := LoWord(PVSFixedFileInfo(pFileInfo)^.dwFileVersionMS);
      V3 := HiWord(PVSFixedFileInfo(pFileInfo)^.dwFileVersionLS);
      V4 := LoWord(PVSFixedFileInfo(pFileInfo)^.dwFileVersionLS);
    finally
      Freemem(pBuffer);
    end;
    // format result string
    Result := Format('%d.%d.%d.%d', [V1, V2, V3, V4]);
  end;
end;

procedure SetDefaultLocale;
var
  SysLang: LANGID;
  PriLang, SecLang: array[0..128] of Char;
  DefLang: String;
BEGIN
  SysLang := GetSystemDefaultLangID;
  GetLocaleInfo(SysLang, LOCALE_SISO639LANGNAME, PriLang, 128);
  GetLocaleInfo(SysLang, LOCALE_SISO3166CTRYNAME, SecLang, 128);
  DefLang := PriLang;
  if (SecLang <> '') then DefLang := DefLang + '_' + SecLang;
  SetDefaultLang(DefLang, '', false);
end;

initialization
  SetDefaultLocale;

end.

