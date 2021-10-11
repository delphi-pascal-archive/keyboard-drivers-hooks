unit internal;

{*******************************************************}
{                                                       }
{       internal.pas                                    }
{       Keyboard enhancer's internal definitions        }
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
  Windows, Messages;

type
  TActionFunc = function(Param: PAnsiChar): integer;

  TAction = packed record
    vkCode, scanCode: DWord;
    onKeyDown, silent: boolean;
    func: TActionFunc;
    param: PAnsiChar;
    end;

const
  ACT_ACTION                  = $FF;
  ACT_CREATEPROCESS           = $00;
  ACT_EXIT                    = $01;
  ACT_FLAG                  = $FF00;
  ACT_FLAG_ONKEYDOWN        = $0100;
  ACT_FLAG_SILENT           = $0200;
  ACT_FLAG_BKG              = $0400;

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
  WH_KEYBOARD_LL  = 13;

const
  WM_KB_SUSPEND       = WM_USER + $00;
  WM_KB_RESUME        = WM_USER + $01;
  WM_KB_RELOAD        = WM_USER + $02;

const
  BELOW_NORMAL_PRIORITY_CLASS = $00004000;
  ABOVE_NORMAL_PRIORITY_CLASS = $00008000;

const
  Priorities: array[0..5] of DWord = (
    IDLE_PRIORITY_CLASS,
    BELOW_NORMAL_PRIORITY_CLASS,
    NORMAL_PRIORITY_CLASS,
    ABOVE_NORMAL_PRIORITY_CLASS,
    HIGH_PRIORITY_CLASS,
    REALTIME_PRIORITY_CLASS);

implementation

end.
