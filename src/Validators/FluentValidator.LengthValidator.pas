{-----------------------------------------------------------------------------
 Project: FluentValidator
 Unit Name: FluentValidator.LengthValidator
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

unit FluentValidator.LengthValidator;

interface

uses
  System.Classes, System.SysUtils, System.Rtti,
  FluentValidator.Intf, FluentValidator, FluentValidator.Messages;

type
  TLengthValidator = class(TBaseValidator)
  private
    FMinLength, FMaxLength: Integer;
  protected
    function GetMessageKey: string; override;
    function GetMessageArgs: TMessageArgs; override;
  public
    constructor Create(MinLength, MaxLength: Integer);
    function IsValid(const Value: TValue): Boolean; override;
  end;

implementation

{ TLengthValidator }

constructor TLengthValidator.Create(MinLength, MaxLength: Integer);
begin
  inherited Create;
  FMinLength := MinLength;
  FMaxLength := MaxLength;
end;

function TLengthValidator.IsValid(const Value: TValue): Boolean;
begin
  if not Value.IsType<string> then
    Exit(False);

  var StrValue := Value.AsType<string>;
  Result := (StrValue.Length >= FMinLength) and (StrValue.Length <= FMaxLength);
end;

function TLengthValidator.GetMessageKey: string;
begin
  Result := TMsgKey.Length;
end;

function TLengthValidator.GetMessageArgs: TMessageArgs;
begin
  Result := TValidationMessages.Args(['MinLength', FMinLength, 'MaxLength', FMaxLength]);
end;

end.
