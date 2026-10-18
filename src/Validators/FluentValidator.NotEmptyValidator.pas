{-----------------------------------------------------------------------------
 Project: Example2
 Unit Name: FluentValidator.NotEmptyValidator
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

unit FluentValidator.NotEmptyValidator;

interface


uses
  System.Classes, System.SysUtils, System.Rtti, System.TypInfo,
  FluentValidator.Intf, FluentValidator, FluentValidator.Messages;


type
  TNotEmptyValidator = class(TBaseValidator)
  protected
    function GetMessageKey: string; override;
  public
    function IsValid(const Value: TValue): Boolean; override;
  end;

implementation

{ TNotEmptyValidator }

function TNotEmptyValidator.IsValid(const Value: TValue): Boolean;
begin
  if Value.IsEmpty then
    Exit(False);

  if Value.IsType<string> then
    Exit(not Value.AsType<string>.Trim.IsEmpty);

  // Riferimento a oggetto nil = vuoto (vedi nota in TNotNullValidator)
  if Value.IsObject then
    Exit(Value.AsObject <> nil);

  // Per i tipi a valore, il "vuoto" è il valore di default (0), come in
  // FluentValidation .NET ("the default value for value types, e.g. 0 for int")
  if Value.IsOrdinal then
    Exit(Value.AsOrdinal <> 0);

  if Value.TypeInfo.Kind = tkFloat then
    Exit(Value.AsExtended <> 0);

  Result := True;
end;

function TNotEmptyValidator.GetMessageKey: string;
begin
  Result := TMsgKey.NotEmpty;
end;

end.
