{-----------------------------------------------------------------------------
 Project: FluentValidator
 Unit Name: FluentValidator.CustomPredicateValidator
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

unit FluentValidator.CustomPredicateValidator;

interface

uses
  System.Classes, System.SysUtils, System.Rtti,
  FluentValidator.Intf, FluentValidator, FluentValidator.Messages;

type
  TCustomPredicateValidator = class(TBaseValidator)
  private
    FPredicate: TPredicate<TValue>;
  protected
    function GetMessageKey: string; override;
  public
    constructor Create(Predicate: TPredicate<TValue>; const ErrorMessage: string);
    function IsValid(const Value: TValue): Boolean; override;
  end;

implementation

{ TCustomPredicateValidator }

constructor TCustomPredicateValidator.Create(Predicate: TPredicate<TValue>; const ErrorMessage: string);
begin
  inherited Create;
  FPredicate := Predicate;
  if ErrorMessage <> '' then
    SetCustomMessage(ErrorMessage);
end;

function TCustomPredicateValidator.IsValid(const Value: TValue): Boolean;
begin
  Result := FPredicate(Value);
end;

function TCustomPredicateValidator.GetMessageKey: string;
begin
  Result := TMsgKey.Predicate;
end;

end.
