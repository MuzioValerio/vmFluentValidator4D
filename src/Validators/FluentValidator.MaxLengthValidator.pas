{-----------------------------------------------------------------------------
 Project: Example2
 Unit Name: FluentValidator.MaxLengthValidator
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

unit FluentValidator.MaxLengthValidator;

interface

uses
  System.Classes, System.SysUtils, System.Rtti,
  FluentValidator.Intf, FluentValidator, FluentValidator.Messages;

type
  TMaxLengthValidator = class(TBaseValidator)
  private
    FMaxLength: Integer;
  protected
    function GetMessageKey: string; override;
    function GetMessageArgs: TMessageArgs; override;
  public
    constructor Create(MaxLength: Integer);
    function IsValid(const Value: TValue): Boolean; override;
  end;

implementation

{ TMaxLengthValidator }

constructor TMaxLengthValidator.Create(MaxLength: Integer);
begin
  inherited Create;
  FMaxLength := MaxLength;
end;

function TMaxLengthValidator.IsValid(const Value: TValue): Boolean;
begin
  if Value.IsEmpty then
    Exit(True);

  if not Value.IsType<string> then
    Exit(False);

  Result := Value.AsType<string>.Length <= FMaxLength;
end;

function TMaxLengthValidator.GetMessageKey: string;
begin
  Result := TMsgKey.MaxLength;
end;

function TMaxLengthValidator.GetMessageArgs: TMessageArgs;
begin
  Result := TValidationMessages.Args(['MaxLength', FMaxLength]);
end;

end.
