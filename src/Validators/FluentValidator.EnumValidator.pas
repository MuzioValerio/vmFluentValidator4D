{-----------------------------------------------------------------------------
 Project: FluentValidator
 Unit Name: FluentValidator.EnumValidator
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
   30-giu-2026: messaggio d'errore arricchito col valore effettivo ricevuto,
                tramite FluentValidator.EnumConverter (GetEnumValue per la
                ricerca per nome, invariato nella sostanza rispetto a prima).
-----------------------------------------------------------------------------}

unit FluentValidator.EnumValidator;

interface

uses
  System.Rtti, System.TypInfo,
  FluentValidator.Intf, FluentValidator, FluentValidator.Messages, FluentValidator.EnumConverter;

type
  TEnumValidator = class(TBaseValidator)
  private
    FEnumTypeInfo: PTypeInfo;
    FLastInvalidValue: string;
  protected
    function GetMessageKey: string; override;
    function GetMessageArgs: TMessageArgs; override;
  public
    constructor Create(EnumTypeInfo: PTypeInfo);
    function IsValid(const Value: TValue): Boolean; override;
  end;

implementation

uses
  System.SysUtils;

{ TEnumValidator }

constructor TEnumValidator.Create(EnumTypeInfo: PTypeInfo);
begin
  inherited Create;
  FEnumTypeInfo := EnumTypeInfo;
end;

function TEnumValidator.IsValid(const Value: TValue): Boolean;
var
  EnumValue: Integer;
  TypeData: PTypeData;
begin
  FLastInvalidValue := '';

  if Value.IsEmpty then
    Exit(False);

  if FEnumTypeInfo = nil then
    Exit(False);

  // Supporta il valore enum vero e proprio (tkEnumeration), un Integer, o una
  // stringa. Value.IsOrdinal copre sia gli Integer sia i valori enum: quando
  // IsInEnum viene usato via RuleFor<TEnum>, il TValue contiene il tipo enum
  // (non un Integer), quindi occorre AsOrdinal e non AsType<Integer>.
  if Value.IsOrdinal then
  begin
    EnumValue := Value.AsOrdinal;
    TypeData := GetTypeData(FEnumTypeInfo);
    Result := (EnumValue >= TypeData.MinValue) and (EnumValue <= TypeData.MaxValue);
    if not Result then
      FLastInvalidValue := EnumValue.ToString;
  end
  else if Value.IsType<string> then
  begin
    Result := GetEnumValue(FEnumTypeInfo, Value.AsType<string>) <> -1;
    if not Result then
      FLastInvalidValue := Value.AsType<string>;
  end
  else
    Result := False;
end;

function TEnumValidator.GetMessageKey: string;
begin
  if FLastInvalidValue <> '' then
    Result := TMsgKey.EnumValueReceived
  else
    Result := TMsgKey.EnumValue;
end;

function TEnumValidator.GetMessageArgs: TMessageArgs;
begin
  Result := TValidationMessages.Args(['ActualValue', FLastInvalidValue]);
end;

end.
