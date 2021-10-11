unit Unit1;

{*******************************************************}
{                                                       }
{       Editor main form                                }
{       for keyboard enhancer                           }
{                                                       }
{       Copyright (c) 2005-2006, Anton A. Drachev       }
{                        911.anton@gmail.com            }
{                                                       }
{       Distributed "AS IS" under BSD-like license      }
{       Full text of license can be found in            }
{       "License.txt" file attached                     }
{                                                       }
{*******************************************************}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ImgList, Registry, XPMan, ExtCtrls, Internal;

type
  TForm1 = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    ListView1: TListView;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Edit1: TEdit;
    Edit2: TEdit;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    Button2: TButton;
    Button3: TButton;
    ComboBox1: TComboBox;
    ExecOptns: TPanel;
    ExitOptns: TPanel;
    ComboBox2: TComboBox;
    Label3: TLabel;
    Edit3: TEdit;
    Label4: TLabel;
    Button5: TButton;
    OpenDialog1: TOpenDialog;
    Button4: TButton;
    Label5: TLabel;
    Label6: TLabel;
    Edit4: TEdit;
    Label7: TLabel;
    ImageList1: TImageList;
    Edit5: TEdit;
    CheckBox3: TCheckBox;
    Button1: TButton;
    Button6: TButton;
    Button7: TButton;
    GroupBox4: TGroupBox;
    CheckBox4: TCheckBox;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    GroupBox5: TGroupBox;
    TrackBar1: TTrackBar;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    procedure Button5Click(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure ListView1SelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure ComboBox2Change(Sender: TObject);
    procedure Edit3Change(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Edit5Enter(Sender: TObject);
    procedure Edit5Exit(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure CheckBox4Click(Sender: TObject);
    procedure ListView1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  autorunStored: string;
  toExec: string;
  tid: dword;
  
type
  KBDLLHOOKSTRUCT = record
    vkCode: DWORD;
    scanCode: DWORD;
    flags: DWORD;
    time: DWORD;
    dwExtraInfo: LongWord;
  end;
  LPKBDLLHOOKSTRUCT = ^KBDLLHOOKSTRUCT;

const
  LLKHF_EXTENDED = (KF_EXTENDED shr 8);
  {$EXTERNALSYM LLKHF_EXTENDED}
  LLKHF_INJECTED = $00000010;
  {$EXTERNALSYM LLKHF_INJECTED}
  LLKHF_ALTDOWN  = (KF_ALTDOWN shr 8);
  {$EXTERNALSYM LLKHF_ALTDOWN}
  LLKHF_UP       = (KF_UP shr 8);
  {$EXTERNALSYM LLKHF_UP}

  WH_KEYBOARD_LL  = 13;

 type TAction = record
    vkCode, scanCode: DWord;
    action: dword;
    param:PChar;
    Hive: PChar;
    end;
    PAction=^TAction;

var
  HOOK: HHOOK;
  AMessage: TMsg;
  Terminated: boolean;
  Reg: TRegistry;

implementation

uses ShellApi, ShlObj, ACtiveX;

function SelectDirectory(const Caption: string; const Root: WideString;
  out Directory: WideString): Boolean;
var
  WindowList: Pointer;
  BrowseInfo: TBrowseInfo;
  Buffer: PChar;
  RootItemIDList, ItemIDList: PItemIDList;
  ShellMalloc: IMalloc;
  IDesktopFolder: IShellFolder;
  Eaten, Flags: LongWord;
  ActiveWindow: HWND;
begin
  Result:=False;
  Directory:='';
  FillChar(BrowseInfo, SizeOf(BrowseInfo), 0);
  if (ShGetMalloc(ShellMalloc) = S_OK) and (ShellMalloc <> nil) then
  begin
    Buffer:=ShellMalloc.Alloc(MAX_PATH);
    try
      RootItemIDList:=nil;
      if Root <> '' then
      begin
        SHGetDesktopFolder(IDesktopFolder);
        IDesktopFolder.ParseDisplayName(0, nil, POleStr(Root), Eaten, RootItemIDList, Flags);
      end;
      with BrowseInfo do
      begin
        hwndOwner:=0;
        pidlRoot:=RootItemIDList;
        pszDisplayName:=Buffer;
        lpszTitle:=PChar(Caption);
        ulFlags:=BIF_RETURNONLYFSDIRS;
      end;
      ActiveWindow:=GetActiveWindow;
      WindowList:=DisableTaskWindows(0);
      try
        ItemIDList:=ShBrowseForFolder(BrowseInfo);
      finally
        EnableTaskWindows(WindowList);
        SetActiveWindow(ActiveWindow);
      end;
      Result:=ItemIDList <> nil;
      if Result then
      begin
        ShGetPathFromIDList(ItemIDList, Buffer);
        ShellMalloc.Free(ItemIDList);
        Directory:=Buffer;
      end;
    finally
      ShellMalloc.Free(Buffer);
    end;
  end;
end;

{$R *.dfm}

function LowLevelKeyboardProc(nCode: integer; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  pkb: LPKBDLLHOOKSTRUCT;
begin
pkb:=LPKBDLLHOOKSTRUCT(lParam);
if wParam = WM_KEYDOWN then begin
Form1.Edit1.Text:=IntToStr(pkb.vkCode);
Form1.Edit2.Text:=IntToStr(pkb.scanCode);
end;
Result:=-1;
end;

resourcestring
  _opendir = 'Select a directory to open';

procedure TForm1.Button5Click(Sender: TObject);
var wd: WideString;
begin
SelectDirectory(_opendir, '' ,wd);
Edit3.Text:=wd;
end;

procedure TForm1.ComboBox1Change(Sender: TObject);
begin
if ComboBox1.ItemIndex = 0 then ExecOptns.BringToFront;
if ComboBox1.ItemIndex = 1 then ExitOptns.BringToFront;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
if OpenDialog1.Execute then begin
  ComboBox2.Text:=OpenDialog1.FileName;
  Edit4.Text:='"'+ComboBox2.Text+'" "'+Edit3.Text+'"';
  end;
end;

procedure TForm1.ListView1SelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
var
  a: PAction;
  i: integer;
begin
if not Selected then begin
  a:=Item.Data;
  a.vkCode:=StrToIntDef(Edit1.Text, 0);
  a.scanCode:=StrToIntDef(Edit2.Text, 0);
  a.action:=0;
  Item.SubItems.Strings[0]:=Edit1.Text + ' / ' + Edit2.Text;
  if ComboBox1.ItemIndex = 0 then begin
    a.action:=0;
    StrPCopy(a.param, Edit4.Text);
    end;
  if ComboBox1.ItemIndex = 1 then a.action:=1;
  if CheckBox1.Checked then a.action:=a.action or ACT_FLAG_SILENT;
  if CheckBox2.Checked then a.action:=a.action or ACT_FLAG_ONKEYDOWN;
  if CheckBox3.Checked then a.action:=a.action or ACT_FLAG_BKG;
  end
else begin
a:=Item.Data;
Edit1.Text:=IntToStr(a.vkCode);
Edit2.Text:=IntToStr(a.scanCode);
Edit4.Text:=a.param;
if 0 = (a.action and 0) then begin
  ComboBox1.ItemIndex:=0;
  i:=Pos(' "', Edit4.Text);
  if i = 0 then i:=Length(Edit4.Text) + 1;
  ComboBox2.Text:=Copy(Edit4.Text, 1, i - 1);
  if Length(ComboBox2.Text) > 0 then if ComboBox2.Text[1]='"' then
    ComboBox2.Text:=Copy(ComboBox2.Text, 2, Length(ComboBox2.Text) - 2);
  Edit3.Text:=Copy(Edit4.Text, i+2, Length(Edit4.Text) - i -2);
  ExecOptns.BringToFront;
  end;
if 1 = (a.action and 1) then begin
  ComboBox1.ItemIndex:=1;
  ExitOptns.BringToFront;
  end;
Edit4.Text:=a.param;
CheckBox1.Checked:=ACT_FLAG_SILENT = (a.action and ACT_FLAG_SILENT);
CheckBox2.Checked:=ACT_FLAG_ONKEYDOWN = (a.action and ACT_FLAG_ONKEYDOWN);
CheckBox3.Checked:=ACT_FLAG_BKG = (a.action and ACT_FLAG_BKG);
end;
end;

resourcestring
  _contact_adm = '(contact your system administrator to disable)';

procedure TForm1.FormCreate(Sender: TObject);
var
  sl: TStringList;
  i: integer;
  a: PAction;
  bin: string;
begin
Application.Title:=Caption;
try
  sl:=TStringList.Create;
  Reg:=TRegistry.Create;
  Reg.RootKey:=HKEY_CURRENT_USER;
  Reg.OpenKey('Software\Imagine\Keyboard', true);
  try
    tid:=Reg.ReadInteger('tid');
    finally
    PostThreadMessage(tid, WM_KB_SUSPEND, 0, 0);
    end;
  toExec:=Reg.ReadString('');
  bin:=ExtractFileName(toExec);
  Reg.CloseKey;
  Reg.Access:=GENERIC_READ;
  Reg.RootKey:=HKEY_LOCAL_MACHINE;
  Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', false);
  sl.Clear;
  Reg.GetValueNames(sl);
  for i:=0 to sl.Count - 1 do
    if Pos(bin, Reg.ReadString(sl.Strings[i])) > 0 then begin
      RadioButton1.Checked:=true;
      CheckBox4.Checked:=true;
      autorunStored:=sl.Strings[i];
      end;
  try
    Reg.Access:=GENERIC_ALL;
    Reg.CloseKey;
    Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', false);
    try Reg.WriteString('try', 'dummy');
      finally Reg.DeleteValue('try'); end;
    except
    CheckBox4.Enabled:=false;
    RadioButton1.Enabled:=false;
    RadioButton2.Enabled:=false;
    Label11.Caption:=_contact_adm;
    end;
  Reg.CloseKey;
  Reg.Access:=GENERIC_ALL;
  Reg.RootKey:=HKEY_CURRENT_USER;
  Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', true);
  sl.Clear;
  Reg.GetValueNames(sl);
  for i:=0 to sl.Count - 1 do
    if Pos(bin, Reg.ReadString(sl.Strings[i])) > 0 then begin
      RadioButton2.Checked:=true;
      CheckBox4.Checked:=true;
      autorunStored:=sl.Strings[i];
      end;
  Reg.CloseKey;
  Reg.OpenKey('Software\Imagine\Keyboard', true);
  try
    TrackBar1.Position:=Reg.ReadInteger('priority');
    except
    TrackBar1.Position:=3;
    Reg.WriteInteger('priority', 3);
    end;
  sl.Clear;
  Reg.GetKeyNames(sl);
  for i:=0 to sl.Count - 1 do begin
    Reg.CloseKey;
    Reg.OpenKey('Software\Imagine\Keyboard\' + sl.Strings[i], true);
    GetMem(a, sizeof(TAction));
    a.vkCode:=Reg.ReadInteger('vkCode');
    a.scanCode:=Reg.ReadInteger('scanCode');
    a.action:=Reg.ReadInteger('action');
    GetMem(a.param, 2048);
    GetMem(a.Hive, 128);
    StrPCopy(a.Hive,sl.Strings[i]);
    StrPCopy(a.param, Reg.ReadString('actionParam'));
    with ListView1.Items.Add do begin
      Caption:=Reg.ReadString('');
      Subitems.Add(IntToStr(a.vkCode) + ' / ' + IntToStr(a.scanCode));
      Subitems.Add(a.Hive);
      Data:=a;
      end;
    end;
  try ListView1.ItemIndex:=0; ListView1.Items[0].Selected:=true; except end;
  Reg.Free;
  except end;
end;

procedure TForm1.Button2Click(Sender: TObject);
var a: PAction;
begin
  GetMem(a, sizeof(TAction));
  a.vkCode:=0;
  a.scanCode:=0;
  a.action:=$300;
  GetMem(a.param, 2048);
  GetMem(a.Hive, 128);
  Randomize;
  StrPCopy(a.Hive,'button{' + IntToStr(GetTickCount)+'}');
  StrPCopy(a.param, '');
  with ListView1.Items.Add do begin
    Caption:='New button';
    Subitems.Add('0 / 0');
    Subitems.Add(a.Hive);
    Data:=a;
    end;
end;

resourcestring
  _fail_sys = 'failed to change System properties'#13#10 +
    'check if you''re in "Administrators" group'#13#10 +
    'or contact your system administrator';

procedure TForm1.Button6Click(Sender: TObject);
var
  i: integer;
  a: PAction;
begin
if ListView1.Items.Count = 1 then begin
  a:=ListView1.Items[0].Data;
  a.vkCode:=StrToIntDef(Edit1.Text, 0);
  a.scanCode:=StrToIntDef(Edit2.Text, 0);
  a.action:=0;
  ListView1.Items[0].SubItems.Strings[0]:=Edit1.Text + ' / ' + Edit2.Text;
  if ComboBox1.ItemIndex = 0 then begin
    a.action:=0;
    StrPCopy(a.param, Edit4.Text);
    end;
  if ComboBox1.ItemIndex = 1 then a.action:=1;
  if CheckBox1.Checked then a.action:=a.action or ACT_FLAG_SILENT;
  if CheckBox2.Checked then a.action:=a.action or ACT_FLAG_ONKEYDOWN;
  if CheckBox3.Checked then a.action:=a.action or ACT_FLAG_BKG;
  end;
try
  i:=ListView1.ItemIndex;
  ListView1.ItemIndex:=ListView1.Items.Count - 1;
  ListView1.ItemIndex:=0;
  ListView1.ItemIndex:=i;
  except end;
Reg:=TRegistry.Create;
Reg.RootKey:=HKEY_CURRENT_USER;
try Reg.DeleteKey('Software\Imagine\Keyboard'); except end;
Reg.OpenKey('Software\Imagine', true);
Reg.OpenKey('Keyboard', true);
try if toExec='' then toExec:=ExpandFileName('kbdmain.exe');
  Reg.WriteString('', toExec); except end;
Reg.WriteInteger('priority', TrackBar1.Position);
Reg.WriteInteger('tid', -1);
try
  Reg.CloseKey;
  Reg.RootKey:=HKEY_LOCAL_MACHINE;
  Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', true);
  Reg.DeleteValue(autorunStored);
  autorunStored:='Keyboard';
  if CheckBox4.Checked and RadioButton1.Checked then
    Reg.WriteString(autorunStored, toExec);
  Reg.CloseKey;
except
  Showmessage(_fail_sys);
  end;
if autorunStored ='' then autorunStored:='Keyboard';
try
  Reg.CloseKey;
  Reg.RootKey:=HKEY_CURRENT_USER;
  Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', true);
  Reg.DeleteValue(autorunStored);
  autorunStored:='Keyboard';
  if CheckBox4.Checked and RadioButton2.Checked then
    Reg.WriteString(autorunStored, toExec);
  Reg.CloseKey;
except end;
for i:=0 to ListView1.Items.Count - 1 do begin
  Reg.CloseKey;
  a:= ListView1.Items[i].Data;
  Reg.OpenKey('Software\Imagine\Keyboard\' + a.Hive, true);
  Reg.WriteInteger('vkCode', a.vkCode);
  Reg.WriteInteger('scanCode', a.scanCode);
  Reg.WriteInteger('action', a.action);
  Reg.WriteString('actionParam', a.param);
  Reg.WriteString('',ListView1.Items[i].Caption);
  end;
PostThreadMessage(tid, WM_KB_RELOAD, 0, 0);
PostThreadMessage(tid, WM_KB_SUSPEND, 0, 0);
Reg.Free;
end;

procedure TForm1.ComboBox2Change(Sender: TObject);
begin
if Pos(' ', ComboBox2.Text) = 0 then Edit4.Text:=ComboBox2.Text else
  Edit4.Text:='"'+ComboBox2.Text+'"';
if Edit3.Text <> '' then Edit4.Text:=Edit4.Text + ' "'+Edit3.Text+'"';
end;

procedure TForm1.Edit3Change(Sender: TObject);
begin
if Pos(' ', ComboBox2.Text) = 0 then Edit4.Text:=ComboBox2.Text else
  Edit4.Text:='"'+ComboBox2.Text+'"';
if Edit3.Text <> '' then Edit4.Text:=Edit4.Text + ' "'+Edit3.Text+'"';
end;

procedure TForm1.Button7Click(Sender: TObject);
begin
Reg:=TRegistry.Create;
Reg.RootKey:=HKEY_CURRENT_USER;
Reg.OpenKey('Software\Imagine', true);
Reg.OpenKey('Keyboard', true);
try if toExec='' then toExec:=ExpandFileName('kbdmain.exe');
  Reg.WriteString('', toExec); except end;
  Reg.Free;
Close;
end;

procedure TForm1.Button3Click(Sender: TObject);
var i: integer;
begin
i:=ListView1.ItemIndex;
try ListView1.Items.Delete(ListView1.ItemIndex); except end;
if i=0 then inc(i);
try ListView1.ItemIndex:=i - 1; except end;
end;

procedure TForm1.Edit5Enter(Sender: TObject);
begin
HOOK:=SetWindowsHookEx(WH_KEYBOARD_LL, @LowLevelKeyboardProc,
    hinstance, 0);
end;

procedure TForm1.Edit5Exit(Sender: TObject);
begin
UnhookWindowsHookEx(HOOK);
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
Button7.Click;
Close;
end;

procedure TForm1.TrackBar1Change(Sender: TObject);
begin
case TrackBar1.Position of
  0: Label9.Caption:='IDLE PRIORITY CLASS';
  1: Label9.Caption:='BELOW NORMAL PRIORITY CLASS';
  2: Label9.Caption:='NORMAL PRIORITY CLASS';
  3: Label9.Caption:='ABOVE NORMAL PRIORITY CLASS';
  4: Label9.Caption:='HIGH PRIORITY CLASS';
  5: Label9.Caption:='REALTIME PRIORITY CLASS';
  end;
end;

procedure TForm1.CheckBox4Click(Sender: TObject);
begin
RadioButton1.Enabled:=CheckBox4.Checked;
RadioButton2.Enabled:=CheckBox4.Checked;
end;

procedure TForm1.ListView1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
if byte(key) = 46 then Button3.Click;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
PostThreadMessage(tid, WM_KB_RESUME, 0, 0);
end;

end.
