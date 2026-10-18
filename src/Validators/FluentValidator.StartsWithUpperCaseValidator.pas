{-----------------------------------------------------------------------------
 Project: FluentValidator
 Unit Name: CustomValidator
 Copyright (C) 2025-2026 Muzio Valerio
 Author:    Muzio Valerio
 Date:      25-giu-2026

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

 Info:
 Purpose:
 History:
-----------------------------------------------------------------------------}

unit FluentValidator.StartsWithUpperCaseValidator;

interface

uses
  System.SysUtils, System.Rtti, System.Character,
  FluentValidator.Intf, FluentValidator, FluentValidator.Messages;

type
  TStartsWithUpperCaseValidator = class(TBaseValidator)
  protected
    function GetMessageKey: string; override;
  public
    constructor Create(const ErrorMessage: string = '');
    function IsValid(const Value: TValue): Boolean; override;
  end;

implementation

{ TStartsWithUpperCaseValidator }

constructor TStartsWithUpperCaseValidator.Create(const ErrorMessage: string);
begin
  inherited Create;
  if ErrorMessage <> '' then
    SetCustomMessage(ErrorMessage);
end;

function TStartsWithUpperCaseValidator.IsValid(const Value: TValue): Boolean;
var
  StrValue: string;
begin
  if not Value.IsType<string> then
    Exit(False);

  StrValue := Value.AsType<string>;
  if StrValue = '' then
    Exit(True);

  Result := StrValue[1].IsUpper;
end;

function TStartsWithUpperCaseValidator.GetMessageKey: string;
begin
  Result := TMsgKey.StartsWithUpperCase;
end;

end.
