{-----------------------------------------------------------------------------
 Project: FluentValidator
 Unit Name: FluentValidator.EnumNameValidator
 Copyright (C) 2025-2026 Muzio Valerio
 Author:    Muzio Valerio
 Date:      15-lug-2026

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
 Purpose: Equivalente di IsEnumName di FluentValidation .NET. Verifica che una
          stringa corrisponda al nome di un valore dell'enumerazione indicata,
          con confronto sensibile o insensibile alle maiuscole. Distinto da
          IsInEnum (TEnumValidator), che ragiona sul valore ordinale.
 History:
-----------------------------------------------------------------------------}

unit FluentValidator.EnumNameValidator;

interface

uses
  System.SysUtils, System.Rtti, System.TypInfo,
  FluentValidator.Intf, FluentValidator, FluentValidator.Messages;

type
  TEnumNameValidator = class(TBaseValidator)
  private
    FEnumTypeInfo: PTypeInfo;
    FCaseSensitive: Boolean;
    FLastInvalidValue: string;
  protected
    function GetMessageKey: string; override;
    function GetMessageArgs: TMessageArgs; override;
  public
    constructor Create(EnumTypeInfo: PTypeInfo; CaseSensitive: Boolean = False);
    function IsValid(const Value: TValue): Boolean; override;
  end;

implementation

{ TEnumNameValidator }

constructor TEnumNameValidator.Create(EnumTypeInfo: PTypeInfo; CaseSensitive: Boolean);
begin
  inherited Create;
  FEnumTypeInfo := EnumTypeInfo;
  FCaseSensitive := CaseSensitive;
end;

function TEnumNameValidator.IsValid(const Value: TValue): Boolean;
var
  Name: string;
  TypeData: PTypeData;
  I: Integer;
begin
  FLastInvalidValue := '';

  if Value.IsEmpty then
    Exit(False);

  if FEnumTypeInfo = nil then
    Exit(False);

  if not Value.IsType<string> then
    Exit(False);

  Name := Value.AsType<string>;
  TypeData := GetTypeData(FEnumTypeInfo);

  Result := False;
  for I := TypeData.MinValue to TypeData.MaxValue do
  begin
    if FCaseSensitive then
    begin
      if GetEnumName(FEnumTypeInfo, I) = Name then
        Exit(True);
    end
    else
    begin
      if SameText(GetEnumName(FEnumTypeInfo, I), Name) then
        Exit(True);
    end;
  end;

  FLastInvalidValue := Name;
end;

function TEnumNameValidator.GetMessageKey: string;
begin
  if FLastInvalidValue <> '' then
    Result := TMsgKey.EnumNameReceived
  else
    Result := TMsgKey.EnumName;
end;

function TEnumNameValidator.GetMessageArgs: TMessageArgs;
begin
  Result := TValidationMessages.Args(['ActualValue', FLastInvalidValue]);
end;

end.
