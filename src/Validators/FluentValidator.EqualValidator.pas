{-----------------------------------------------------------------------------
 Project: Example2
 Unit Name: FluentValidator.EqualValidator
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

unit FluentValidator.EqualValidator;

interface

uses
  System.Classes, System.SysUtils, System.Rtti,
  FluentValidator.Intf, FluentValidator, FluentValidator.Messages;

type
  TEqualValidator = class(TBaseValidator)
  private
    FComparand: TValue;
  protected
    function GetMessageKey: string; override;
    function GetMessageArgs: TMessageArgs; override;
  public
    constructor Create(const Comparand: TValue); overload;
    constructor Create(const Comparand: string); overload;
    constructor Create(Comparand: Integer); overload;
    function IsValid(const Value: TValue): Boolean; override;
  end;

implementation

{ TEqualValidator }

constructor TEqualValidator.Create(const Comparand: TValue);
begin
  inherited Create;
  FComparand := Comparand;
end;

constructor TEqualValidator.Create(const Comparand: string);
begin
  inherited Create;
  FComparand := TValue.From<string>(Comparand);
end;

constructor TEqualValidator.Create(Comparand: Integer);
begin
  inherited Create;
  FComparand := TValue.From<Integer>(Comparand);
end;

function TEqualValidator.IsValid(const Value: TValue): Boolean;
begin
  if Value.IsEmpty then
    Exit(False);

  if FComparand.IsEmpty then
    Exit(False);

  // Per stringhe
  if Value.IsType<string> and FComparand.IsType<string> then
    Result := Value.AsType<string> = FComparand.AsType<string>
  // Per interi
  else if Value.IsType<Integer> and FComparand.IsType<Integer> then
    Result := Value.AsType<Integer> = FComparand.AsType<Integer>
  else if Value.IsType<Double> and FComparand.IsType<Double> then
    Result := Value.AsType<Double> = FComparand.AsType<Double>
  else if Value.IsType<Boolean> and FComparand.IsType<Boolean> then
    Result := Value.AsType<Boolean> = FComparand.AsType<Boolean>
  else
    Result := Value.ToString = FComparand.ToString;
end;

function TEqualValidator.GetMessageKey: string;
begin
  Result := TMsgKey.Equal;
end;

function TEqualValidator.GetMessageArgs: TMessageArgs;
begin
  Result := TValidationMessages.Args(['ComparisonValue', FComparand.ToString]);
end;

end.
