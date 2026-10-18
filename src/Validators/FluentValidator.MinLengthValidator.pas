{-----------------------------------------------------------------------------
 Project: FluentValidator
 Unit Name: FluentValidator.MinLengthValidator
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

unit FluentValidator.MinLengthValidator;

interface

uses
  System.Classes, System.SysUtils, System.Rtti,
  FluentValidator.Intf, FluentValidator, FluentValidator.Messages;

type
  TMinLengthValidator = class(TBaseValidator)
  private
    FMinLength: Integer;
  protected
    function GetMessageKey: string; override;
    function GetMessageArgs: TMessageArgs; override;
  public
    constructor Create(MinLength: Integer);
    function IsValid(const Value: TValue): Boolean; override;
  end;

implementation

{ TMinLengthValidator }

constructor TMinLengthValidator.Create(MinLength: Integer);
begin
  inherited Create;
  FMinLength := MinLength;
end;

function TMinLengthValidator.IsValid(const Value: TValue): Boolean;
begin
  if Value.IsEmpty then
    Exit(False);

  if not Value.IsType<string> then
    Exit(False);

  Result := Value.AsType<string>.Length >= FMinLength;
end;

function TMinLengthValidator.GetMessageKey: string;
begin
  Result := TMsgKey.MinLength;
end;

function TMinLengthValidator.GetMessageArgs: TMessageArgs;
begin
  Result := TValidationMessages.Args(['MinLength', FMinLength]);
end;

end.
