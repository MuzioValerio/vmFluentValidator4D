{-----------------------------------------------------------------------------
 Project: FluentValidator
 Unit Name: FluentValidators.MustBeInFutureValidator
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
 Purpose: Validates that a date is in the future
 History:
-----------------------------------------------------------------------------}

unit FluentValidator.MustBeInFutureValidator;

interface

uses
  System.Classes, System.Rtti, System.SysUtils,
  FluentValidator.Intf, FluentValidator, FluentValidator.Messages;

type
  TMustBeInFutureValidator = class(TBaseValidator)
  private
    FIncludeToday: Boolean;
  protected
    function GetMessageKey: string; override;
  public
    constructor Create(IncludeToday: Boolean = False);
    function IsValid(const Value: TValue): Boolean; override;
  end;

implementation

{ TMustBeInFutureValidator }

constructor TMustBeInFutureValidator.Create(IncludeToday: Boolean);
begin
  inherited Create;
  FIncludeToday := IncludeToday;
end;

function TMustBeInFutureValidator.IsValid(const Value: TValue): Boolean;
var
  DateValue: TDateTime;
begin
  if Value.IsEmpty then
    Exit(False);

  if not Value.IsType<TDateTime> then
    Exit(False);

  DateValue := Value.AsType<TDateTime>;

  // Vedi commento in TMustBeInPastValidator.IsValid: confronto a livello di
  // giorno di calendario, non di istante esatto.
  if FIncludeToday then
    Result := Trunc(DateValue) >= Trunc(Now)
  else
    Result := Trunc(DateValue) > Trunc(Now);
end;

function TMustBeInFutureValidator.GetMessageKey: string;
begin
  if FIncludeToday then
    Result := TMsgKey.MustBeInFutureOrToday
  else
    Result := TMsgKey.MustBeInFuture;
end;

end.
