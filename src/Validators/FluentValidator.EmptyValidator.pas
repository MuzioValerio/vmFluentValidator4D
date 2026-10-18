{-----------------------------------------------------------------------------
 Project: FluentValidator
 Unit Name: FluentValidator.EmptyValidator
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
 Purpose: Opposto di TNotEmptyValidator. La proprieta' e' valida solo se il
          suo valore e' "vuoto": TValue vuoto, stringa vuota o di soli spazi,
          riferimento a oggetto nil, oppure valore di default per i tipi a
          valore (0 per ordinali e float), coerentemente con la semantica di
          Empty() in FluentValidation .NET.
 History:
-----------------------------------------------------------------------------}

unit FluentValidator.EmptyValidator;

interface

uses
  System.SysUtils, System.Rtti, System.TypInfo,
  FluentValidator.Intf, FluentValidator, FluentValidator.Messages;

type
  TEmptyValidator = class(TBaseValidator)
  protected
    function GetMessageKey: string; override;
  public
    function IsValid(const Value: TValue): Boolean; override;
  end;

implementation

{ TEmptyValidator }

function TEmptyValidator.IsValid(const Value: TValue): Boolean;
begin
  if Value.IsEmpty then
    Exit(True);

  if Value.IsType<string> then
    Exit(Value.AsType<string>.Trim.IsEmpty);

  if Value.IsObject then
    Exit(Value.AsObject = nil);

  if Value.IsOrdinal then
    Exit(Value.AsOrdinal = 0);

  if Value.TypeInfo.Kind = tkFloat then
    Exit(Value.AsExtended = 0);

  // Tipo non gestito: non lo consideriamo "vuoto".
  Result := False;
end;

function TEmptyValidator.GetMessageKey: string;
begin
  Result := TMsgKey.Empty;
end;

end.
