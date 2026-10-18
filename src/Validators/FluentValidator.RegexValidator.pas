{-----------------------------------------------------------------------------
 Project: FluentValidator
 Unit Name: FluentValidator.RegexValidator
 Copyright (C) 2025-2026 Muzio Valerio
 Author:    Muzio Valerio
 Date:      26-giu-2026

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

unit FluentValidator.RegexValidator;

interface

uses
  System.Classes, System.SysUtils, System.Rtti, System.RegularExpressions,
  FluentValidator.Intf, FluentValidator, FluentValidator.Messages;

type
  TRegexValidator = class(TBaseValidator)
  private
    FPattern: string;
    FRegEx: TRegEx;
  protected
    function GetMessageKey: string; override;
  public
    constructor Create(const Pattern: string);
    function IsValid(const Value: TValue): Boolean; override;
  end;

implementation

{ TRegexValidator }

constructor TRegexValidator.Create(const Pattern: string);
begin
  inherited Create;
  FPattern := Pattern;
  FRegEx := TRegEx.Create(Pattern);
end;

function TRegexValidator.IsValid(const Value: TValue): Boolean;
begin
  if not Value.IsType<string> then
    Exit(False);

  Result := FRegEx.IsMatch(Value.AsType<string>);
end;

function TRegexValidator.GetMessageKey: string;
begin
  Result := TMsgKey.Regex;
end;

end.
