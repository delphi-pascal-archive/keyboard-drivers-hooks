program Editor;

{*******************************************************}
{                                                       }
{       Editor's main program file                      }
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

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
