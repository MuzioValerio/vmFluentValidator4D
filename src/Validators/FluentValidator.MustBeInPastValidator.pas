{-----------------------------------------------------------------------------
 Project: FluentValidator
 Unit Name: FluentValidator.MustBeInPastValidator
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
 Purpose: Validates that a date is in the past
 History:
-----------------------------------------------------------------------------}

unit FluentValidator.MustBeInPastValidator;

interface

uses
  System.Classes, System.Rtti, System.SysUtils,
  FluentValidator.Intf, FluentValidator, FluentValidator.Messages;

type
  TMustBeInPastValidator = class(TBaseValidator)
  private
    FIncludeToday: Boolean;
  protected
    function GetMessageKey: string; override;
  public
    constructor Create(IncludeToday: Boolean = False);
    function IsValid(const Value: TValue): Boolean; override;
  end;

implementation

{ TMustBeInPastValidator }

constructor TMustBeInPastValidator.Create(IncludeToday: Boolean);
begin
  inherited Create;
  FIncludeToday := IncludeToday;
end;

function TMustBeInPastValidator.IsValid(const Value: TValue): Boolean;
var
  DateValue: TDateTime;
begin
  if Value.IsEmpty then
    Exit(False);

  if not Value.IsType<TDateTime> then
    Exit(False);

  DateValue := Value.AsType<TDateTime>;

  // Confronto a livello di giorno di calendario (Trunc azzera l'ora): "oggi" deve
  // avere lo stesso significato indipendentemente dall'orario in cui si valida e
  // dall'eventuale componente ora presente nel valore da validare.
  if FIncludeToday then
    Result := Trunc(DateValue) <= Trunc(Now)
  else
    Result := Trunc(DateValue) < Trunc(Now);
end;

function TMustBeInPastValidator.GetMessageKey: string;
begin
  if FIncludeToday then
    Result := TMsgKey.MustBeInPastOrToday
  else
    Result := TMsgKey.MustBeInPast;
end;

end.
