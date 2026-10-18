{-----------------------------------------------------------------------------
 Project: FluentValidator
 Unit Name: FluentValidator.NullValidator
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
 Purpose: Opposto di TNotNullValidator. La proprieta' e' valida solo se il
          suo valore e' "nullo" nel senso di TValue vuoto o riferimento a
          oggetto nil. Utile per campi che DEVONO restare non valorizzati in
          determinate condizioni (es. dati non applicabili a un regime
          fiscale), tipicamente in combinazione con .When/.Unless.
 History:
-----------------------------------------------------------------------------}

unit FluentValidator.NullValidator;

interface

uses
  System.SysUtils, System.Rtti,
  FluentValidator.Intf, FluentValidator, FluentValidator.Messages;

type
  TNullValidator = class(TBaseValidator)
  protected
    function GetMessageKey: string; override;
  public
    function IsValid(const Value: TValue): Boolean; override;
  end;

implementation

{ TNullValidator }

function TNullValidator.IsValid(const Value: TValue): Boolean;
begin
  if Value.IsEmpty then
    Exit(True);

  // Coerente con TNotNullValidator (di cui e' l'esatto opposto): un
  // riferimento a oggetto nil conta come "nullo" anche se il TypeInfo resta
  // valido.
  if Value.IsObject then
    Exit(Value.AsObject = nil);

  // Un valore a tipo valore o una stringa (anche '') non e' "nullo".
  Result := False;
end;

function TNullValidator.GetMessageKey: string;
begin
  Result := TMsgKey.Null;
end;

end.
