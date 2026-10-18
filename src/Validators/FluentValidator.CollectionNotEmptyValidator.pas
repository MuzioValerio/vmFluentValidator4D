{-----------------------------------------------------------------------------
 Project: FluentValidator
 Unit Name: FluentValidator.CollectionNotEmptyValidator
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
 Purpose: Valida che una collezione (array dinamico o oggetto con proprieta'
          Count, es. TList<T>/TObjectList<T>/TDictionary/TStringList) non
          sia vuota, a prescindere dal tipo generico concreto.
 History:
-----------------------------------------------------------------------------}

unit FluentValidator.CollectionNotEmptyValidator;

interface

uses
  System.Classes, System.SysUtils, System.Rtti,
  FluentValidator.Intf, FluentValidator, FluentValidator.Messages;

type
  TCollectionNotEmptyValidator = class(TBaseValidator)
  protected
    function GetMessageKey: string; override;
  public
    function IsValid(const Value: TValue): Boolean; override;
  end;

implementation

{ TCollectionNotEmptyValidator }

function TCollectionNotEmptyValidator.IsValid(const Value: TValue): Boolean;
var
  Ctx: TRttiContext;
  CountProp: TRttiProperty;
  ObjValue: TObject;
begin
  if Value.IsEmpty then
    Exit(False);

  // Array dinamico di qualsiasi tipo elemento (TArray<T>, qualunque T)
  if Value.IsArray then
    Exit(Value.GetArrayLength > 0);

  // Qualsiasi oggetto collezione che esponga una proprieta' Count
  // (TList<T>, TObjectList<T>, TDictionary<K,V>, TStringList, ecc.,
  // a prescindere dal tipo generico concreto)
  if Value.IsObject then
  begin
    ObjValue := Value.AsObject;

    if not Assigned(ObjValue) then
      Exit(False);

    Ctx := TRttiContext.Create;
    try
      CountProp := Ctx.GetType(ObjValue.ClassType).GetProperty('Count');
      if Assigned(CountProp) then
        Exit(CountProp.GetValue(ObjValue).AsInteger > 0);
    finally
      Ctx.Free;
    end;

    // Oggetto senza proprieta' Count: non e' una collezione riconosciuta,
    // non e' compito di questo validatore esprimersi su di esso.
    Exit(True);
  end;

  // Tipi non-collezione (stringhe, numeri, ecc.): non pertinente per questo validatore.
  Result := True;
end;

function TCollectionNotEmptyValidator.GetMessageKey: string;
begin
  Result := TMsgKey.CollectionNotEmpty;
end;

end.
