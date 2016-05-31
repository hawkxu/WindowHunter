unit Main;

{$mode objfpc}{$H+}

interface

uses
  JwaWindows, Classes, SysUtils, FileUtil, Forms, Controls, Graphics,
  Dialogs, ComCtrls, VirtualTrees, Math, Common;

type

  { TFrmMain }

  TFrmMain = class(TForm)
    ImlMain: TImageList;
    StbMain: TStatusBar;
    TlbMain: TToolBar;
    BtnRefresh: TToolButton;
    ToolButton1: TToolButton;
    BtnHidden: TToolButton;
    VtvWindow: TVirtualStringTree;
    procedure BtnRefreshClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure VtvWindowAfterCellPaint(Sender: TBaseVirtualTree;
      TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
      const CellRect: TRect);
    procedure VtvWindowBeforeItemErase(Sender: TBaseVirtualTree;
      TargetCanvas: TCanvas; Node: PVirtualNode; const ItemRect: TRect;
      var ItemColor: TColor; var EraseAction: TItemEraseAction);
    procedure VtvWindowFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure VtvWindowGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
  private
    procedure ListWindowTree(ParentNode: PVirtualNode; hWindow: HWND);
    { private declarations }
  public
    { public declarations }
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.lfm}

{ TFrmMain }

type
  TWindowData = record
    hWindow: HWND;
    Visible: Boolean;
    szClass: String;
    szTitle: String;
    ExePath: String;
  end;
  PWindowData = ^TWindowData;

procedure TFrmMain.BtnRefreshClick(Sender: TObject);
var
  hWindow: HWND;
begin
  VtvWindow.Clear;
  hWindow := GetWindow(Application.MainFormHandle, GW_HWNDFIRST);
  while (hWindow <> 0) do
  begin
    ListWindowTree(nil, hWindow);
    hWindow := GetWindow(hWindow, GW_HWNDNEXT);
  end;
end;

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  VtvWindow.NodeDataSize:= SizeOf(TWindowData);
  VtvWindow.Header.Columns[0].Text := RS_ID;
  VtvWindow.Header.Columns[1].Text := RS_VISIBLE;
  VtvWindow.Header.Columns[2].Text := RS_CLASS;
  VtvWindow.Header.Columns[3].Text := RS_TEXT;
  VtvWindow.Header.Columns[4].Text := RS_APPLICATION;
  StbMain.Panels[1].Text := RS_VERSION + GetSelfVersion;
end;

procedure TFrmMain.FormResize(Sender: TObject);
begin
  StbMain.Panels[0].Width := StbMain.Width - 150;
end;

procedure TFrmMain.VtvWindowAfterCellPaint(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  const CellRect: TRect);
var
  DrawRect: TRect;
  Checked: UINT;
begin
  if (Column = 1) then
  begin
    DrawRect := CellRect;
    DrawRect.Top := CellRect.Top + (VtvWindow.DefaultNodeHeight - 14 ) div 2;
    DrawRect.Bottom := DrawRect.Top + 13;
    if (PWindowData(Sender.GetNodeData(Node))^.Visible) then
      Checked := BS_FLAT or DFCS_CHECKED
    else
      Checked := BS_FLAT or DFCS_BUTTONCHECK;
    DrawFrameControl(TargetCanvas.Handle, DrawRect, DFC_BUTTON, Checked);
  end;
end;

procedure TFrmMain.VtvWindowBeforeItemErase(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas; Node: PVirtualNode; const ItemRect: TRect;
  var ItemColor: TColor; var EraseAction: TItemEraseAction);
var
  NodeRect: TRect;
  RowIndex: Integer;
begin
  NodeRect := VtvWindow.GetDisplayRect(Node, 0, false);
  NodeRect.Top := NodeRect.Top - VtvWindow.Header.Height;
  RowIndex := Ceil(NodeRect.Top / VtvWindow.DefaultNodeHeight);
  if (Odd(RowIndex)) then
  begin
    ItemColor := $EED0D0;
    EraseAction := eaColor;
  end;
end;

procedure TFrmMain.VtvWindowFreeNode(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
begin
  Finalize(PWindowData(Sender.GetNodeData(Node))^);
end;

procedure TFrmMain.VtvWindowGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: String);
var
  Data: PWindowData;
begin
  Data := Sender.GetNodeData(Node);
  case Column of
    0: CellText := IntToStr(Data^.hWindow);
    1: CellText := '';
    2: CellText := Data^.szClass;
    3: CellText := Data^.szTitle;
    4: CellText := Data^.ExePath;
  end;
end;

procedure TFrmMain.ListWindowTree(ParentNode: PVirtualNode; hWindow: HWND);
var
  szClass: array[0..512] of WideChar;
  szTitle: array[0..512] of WideChar;
  dProcId: DWORD;
  dHandle: THandle;
  ExePath: array[0..512] of WideChar;
  WinData: PWindowData;
  WinNode: PVirtualNode;
begin
  if (not BtnHidden.Down) and (not IsWindowVisible(hWindow)) then Exit;
  GetClassNameW(hWindow, szClass, Length(szClass));
  GetWindowTextW(hWindow, szTitle, Length(szTitle));
  ExePath[0] := #0;
  if (ParentNode = nil) then
  begin
    GetWindowThreadProcessId(hWindow, @dProcId);
    dHandle := OpenProcess(PROCESS_ALL_ACCESS, false, dProcId);
    if (dHandle <> 0) then
    begin
      GetModuleFileNameExW(dHandle, 0, ExePath, Length(ExePath));
      CloseHandle(dHandle);
    end;
  end;
  WinNode := VtvWindow.AddChild(ParentNode);
  VtvWindow.ValidateNode(WinNode, False);
  WinData := VtvWindow.GetNodeData(WinNode);
  WinData^.hWindow := hWindow;
  WinNode^.CheckState := csCheckedNormal;
  WinData^.Visible := IsWindowVisible(hWindow);
  WinData^.szClass := UTF8Encode(WideString(szClass));
  WinData^.szTitle := UTF8Encode(WideString(szTitle));
  WinData^.ExePath := UTF8Encode(WideString(ExePath));

  hWindow := GetWindow(hWindow, GW_CHILD);
  while (hWindow <> 0) do
  begin
    ListWindowTree(WinNode, hWindow);
    hWindow := GetWindow(hWindow, GW_HWNDNEXT);
  end;
end;

end.

