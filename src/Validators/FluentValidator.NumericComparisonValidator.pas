{-----------------------------------------------------------------------------
 Project: FluentValidator
 Unit Name: FluentValidator.NumericComparisonValidator
 Copyright (C) 2025-2026 Muzio Valerio
 Author:    Muzio Valerio
 Date:      28-giu-2026

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
 Purpose: Base class shared by all numeric comparison validators
          (GreaterThan, GreaterThanOrEqual, LessThan, LessThanOrEqual,
          InclusiveBetween, ExclusiveBetween). Centralizes the conversion
          of a TValue to a comparable Double and delegates only the actual
          comparison to a closure supplied by the concrete validator.
 History:
-----------------------------------------------------------------------------}

unit FluentValidator.NumericComparisonValidator;

interface

uses
  System.SysUtils, System.Rtti, System.TypInfo,
  FluentValidator.Intf, FluentValidator;

type
  TNumericComparator = reference to function(const AValue: Double): Boolean;

  TNumericComparisonValidator = class abstract(TBaseValidator)
  strict private
    FComparator: TNumericComparator;
    function TryExtractNumeric(const Value: TValue; out Numeric: Double): Boolean;
  public
    constructor Create(Comparator: TNumericComparator);
    function IsValid(const Value: TValue): Boolean; override;
  end;

implementation

{ TNumericComparisonValidator }

constructor TNumericComparisonValidator.Create(Comparator: TNumericComparator);
begin
  inherited Create;
  FComparator := Comparator;
end;

function TNumericComparisonValidator.TryExtractNumeric(const Value: TValue; out Numeric: Double): Boolean;
begin
  Result := True;

  case Value.TypeInfo.Kind of
    tkInteger, tkInt64:
      // AsOrdinal copre Integer, Cardinal, Word, SmallInt, ShortInt, Byte, Int64
      Numeric := Value.AsOrdinal;
    tkFloat:
      // AsExtended copre Double, Single, Currency
      Numeric := Value.AsExtended;
  else
    begin
      Numeric := 0;
      Result := False;
    end;
  end;
end;

function TNumericComparisonValidator.IsValid(const Value: TValue): Boolean;
var
  Numeric: Double;
begin
  if Value.IsEmpty then
    Exit(False);

  if not TryExtractNumeric(Value, Numeric) then
    Exit(False);

  Result := FComparator(Numeric);
end;

end.
