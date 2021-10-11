program kbdmain;

{*******************************************************}
{                                                       }
{       kbdmain                                         }
{       Keyboard enhancer's main executable             }
{                                                       }
{       Copyright (c) 2005, Anton A. Drachev            }
{                        911.anton@gmail.com            }
{                                                       }
{       Distributed "AS IS" under BSD-like license      }
{       Full text of license can be found in            }
{       "License.txt" file attached                     }
{                                                       }
{*******************************************************}

uses
  Windows, Messages, internal;

{$R Editor.res}

var
  Actions: array of TAction;
  ActionCount: integer;
  running: boolean;
  HOOK: HHOOK;

// Actions
function FUNC_CreateProcess(Param: PAnsiChar): integer;
var
  Si : TStartupInfo;
  PrI : TProcessInformation;
begin
FillChar(Si, SizeOf(Si), 0);
Si.cb:=SizeOf(Si);
CreateProcess(nil, Param, nil, nil, false,
  CREATE_DEFAULT_ERROR_MODE, nil, nil, Si, PrI);
CloseHandle(PrI.hProcess);
CloseHandle(PrI.hThread);
Result:=0;
end;

function FUNC_CreateBkgProcess(Param: PAnsiChar): integer;
var
  Si : TStartupInfo;
  PrI : TProcessInformation;
begin
FillChar(Si, SizeOf(Si), 0);
Si.cb:=SizeOf(Si);
Si.dwFlags:=STARTF_USESHOWWINDOW;
Si.wShowWindow:=0;
CreateProcess(nil, Param, nil, nil, false,
  CREATE_DEFAULT_ERROR_MODE, nil, nil, Si, PrI);
CloseHandle(PrI.hProcess);
CloseHandle(PrI.hThread);
Result:=0;
end;

function FUNC_Exit(Param: PAnsiChar): integer;
begin
ExitProcess(0);
Result:=0;
end;

// Keyboard Hook
function LowLevelKeyboardProc(nCode: integer; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  pkb: LPKBDLLHOOKSTRUCT;
  i: byte;
begin
try
  pkb:=LPKBDLLHOOKSTRUCT(lParam);
  for i:=ActionCount downto 0 do begin
    if pkb.scanCode = Actions[i].scanCode then
      if pkb.vkCode = Actions[i].vkCode then begin
        if Actions[i].silent then Result:=-1
          else Result:=CallNextHookEx(HOOK, nCode, wParam, lParam);
        if not (((wParam = WM_KEYDOWN) or (wParam = WM_SYSKEYDOWN)) xor Actions[i].onKeyDown) then begin
          Actions[i].func(Actions[i].param);
          Exit;
          end;
        end;
      end;
  Result:=CallNextHookEx(HOOK, nCode, wParam, lParam);
except
  Result:=CallNextHookEx(HOOK, nCode, wParam, lParam);
  MessageBeep(MB_ICONSTOP);
  end;
end;  

procedure RunEditor;
begin
  FUNC_CreateProcess('editor.exe');
  ExitProcess(0);
end;

// Init
procedure Init;
var
  subkey, key: HKEY;
  name: PAnsiChar;
  i, namesz: DWord;
  vals: array of VALENT;
  Temp: THandle;
begin
RegOpenKeyEx(HKEY_CURRENT_USER, 'Software\Imagine\Keyboard', 0, KEY_READ or KEY_WRITE, key);
if key = 0 then RunEditor;
try
  RegQueryValueEx(key, 'tid', nil, nil, @i, @namesz);
finally
  PostThreadMessage(i, WM_QUIT, 0, 0);
end;
i:=GetCurrentThreadId;
RegSetValueEx(key, 'tid', 0, REG_DWORD, @i, 4);
namesz:=256;
GetMem(name, namesz);
GetModuleFileName(hInstance, name, namesz);
RegSetValueEx(key, '', 0, REG_SZ, name, namesz);
RegCloseKey(key);
RegOpenKeyEx(HKEY_CURRENT_USER, 'Software\Imagine\Keyboard', 0, KEY_READ, key);
RegQueryValueEx(key, 'priority', nil, nil, @i, @namesz);
RegQueryInfoKey(key, nil, nil, nil, @ActionCount, nil, nil, nil, nil, nil, nil, nil);
if i > 5 then i:=3;
temp:=OpenProcess(GENERIC_ALL, false, GetCurrentProcessId);
SetPriorityClass(temp, Priorities[i]);
CloseHandle(temp);
if ActionCount = 0 then RunEditor;
SetLength(Actions, ActionCount);
Dec(ActionCount);
namesz:=256;
setLength(vals, 4);
vals[0].ve_valuename:='vkCode';
vals[1].ve_valuename:='scanCode';
vals[2].ve_valuename:='action';
vals[3].ve_valuename:='actionParam';
for i:=0 to ActionCount do begin
  namesz:=256;
  RegEnumKeyEx(key, i, name, namesz, nil, nil, nil, nil);
  RegOpenKeyEx(key, name, 0, KEY_READ, subkey);
  namesz:=256;
  RegQueryMultipleValues(subkey, vals[0], 4, name, namesz);
  Actions[i].vkCode:=PDWORD(vals[0].ve_valueptr)^;
  Actions[i].scanCode:=PDWORD(vals[1].ve_valueptr)^;
  GetMem(Actions[i].param, vals[3].ve_valuelen + 1);
  MoveMemory(Actions[i].param, PAnsiChar(vals[3].ve_valueptr), vals[3].ve_valuelen);
  Actions[i].param[vals[3].ve_valuelen]:=Char(0);
  Actions[i].onKeyDown:=(PDWORD(vals[2].ve_valueptr)^ and ACT_FLAG_ONKEYDOWN) = ACT_FLAG_ONKEYDOWN;
  Actions[i].silent:=(PDWORD(vals[2].ve_valueptr)^ and ACT_FLAG_SILENT) = ACT_FLAG_SILENT;
  case PDWORD(vals[2].ve_valueptr)^ and ACT_ACTION of
    ACT_CREATEPROCESS: begin
      if (PDWORD(vals[2].ve_valueptr)^ and ACT_FLAG_BKG) = ACT_FLAG_BKG then
        Actions[i].func:=FUNC_CreateBkgProcess else
        Actions[i].func:=FUNC_CreateProcess;
      end;
    ACT_EXIT: Actions[i].func:=FUNC_Exit;
    end;
  RegCloseKey(subkey);
  end;
FreeMemory(PAnsiChar(vals[3].ve_valueptr));
FreeMem(name, 256);
RegCloseKey(key);
end;

// Messages
function ProcessMessage: boolean;
var
  AMessage: TMsg;
begin
Result:=False;
if PeekMessage(AMessage, INVALID_HANDLE_VALUE, 0, 0, PM_REMOVE) then
  begin
  Result:=True;
    case AMessage.message of
      WM_QUIT: running:=false;
      WM_KB_SUSPEND: begin
        if HOOK <> 0 then UnhookWindowsHookEx(HOOK);
        HOOK:=0;
        end;
      WM_KB_RESUME: begin
        if HOOK <> 0 then UnhookWindowsHookEx(HOOK);
        HOOK:=SetWindowsHookEx(WH_KEYBOARD_LL, @LowLevelKeyboardProc,
          hinstance, 0);
        end;
      WM_KB_RELOAD: begin
        if HOOK <> 0 then UnhookWindowsHookEx(HOOK);
        Init;
        HOOK:=SetWindowsHookEx(WH_KEYBOARD_LL, @LowLevelKeyboardProc,
          hinstance, 0);
        end;
    end;
  end;
end;

// Main
begin
try
  Init;
  HOOK:=SetWindowsHookEx(WH_KEYBOARD_LL, @LowLevelKeyboardProc,
    hinstance, 0);
  except ExitProcess(0) end;
running:=true;
while running do if not ProcessMessage then WaitMessage;
if HOOK <> 0 then UnhookWindowsHookEx(HOOK);
end. 
