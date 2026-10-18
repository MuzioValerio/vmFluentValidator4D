{-----------------------------------------------------------------------------
 Project: FluentValidator
 Unit Name: FluentValidator.PrecisionScaleValidator
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
 Purpose: Equivalente di PrecisionScale/ScalePrecision di FluentValidation
          .NET. Verifica che un valore numerico abbia al piu' `Precision`
          cifre totali e al piu' `Scale` cifre decimali (quindi al piu'
          Precision - Scale cifre nella parte intera). Pensato per gli importi
          della fattura elettronica, dove lo SDI impone vincoli precisi sul
          numero di decimali (es. 2 per gli importi, 8 per i prezzi unitari).

          Nota: lavorando su tipi a virgola mobile Delphi (Double/Single/
          Currency), gli zeri decimali finali non sono ricostruibili dal
          valore binario e vengono quindi ignorati (100.00 conta 0 decimali),
          coerentemente con ignoreTrailingZeros = True di .NET.
 History:
-----------------------------------------------------------------------------}

unit FluentValidator.PrecisionScaleValidator;

interface

uses
  System.SysUtils, System.Math, System.Rtti, System.TypInfo,
  FluentValidator.Intf, FluentValidator, FluentValidator.Messages;

type
  TPrecisionScaleValidator = class(TBaseValidator)
  private
    FPrecision: Integer;
    FScale: Integer;
    function TryExtractNumeric(const Value: TValue; out Numeric: Extended): Boolean;
  protected
    function GetMessageKey: string; override;
    function GetMessageArgs: TMessageArgs; override;
  public
    constructor Create(Precision, Scale: Integer);
    function IsValid(const Value: TValue): Boolean; override;
  end;

implementation

{ TPrecisionScaleValidator }

constructor TPrecisionScaleValidator.Create(Precision, Scale: Integer);
begin
  inherited Create;
  if Scale < 0 then
    raise EArgumentException.Create('Scale cannot be negative');
  if Precision <= 0 then
    raise EArgumentException.Create('Precision must be greater than zero');
  if Scale > Precision then
    raise EArgumentException.CreateFmt(
      'Scale (%d) cannot exceed Precision (%d)', [Scale, Precision]);
  FPrecision := Precision;
  FScale := Scale;
end;

function TPrecisionScaleValidator.TryExtractNumeric(const Value: TValue; out Numeric: Extended): Boolean;
begin
  Result := True;
  case Value.TypeInfo.Kind of
    tkInteger, tkInt64:
      Numeric := Value.AsOrdinal;
    tkFloat:
      Numeric := Value.AsExtended;
  else
    begin
      Numeric := 0;
      Result := False;
    end;
  end;
end;

function TPrecisionScaleValidator.IsValid(const Value: TValue): Boolean;
var
  Number, Temp: Extended;
  DecimalDigits, IntegerDigits: Integer;
  IntPart: Int64;
begin
  if Value.IsEmpty then
    Exit(True);

  if not TryExtractNumeric(Value, Number) then
    Exit(False);

  Number := Abs(Number);

  // Conteggio delle cifre decimali effettivamente significative: si moltiplica
  // per 10 finche' la parte frazionaria non si annulla (entro tolleranza),
  // fermandosi comunque a un limite di sicurezza.
  DecimalDigits := 0;
  Temp := Number;
  while (DecimalDigits <= 18) and (Abs(Temp - Round(Temp)) > 1E-9) do
  begin
    Temp := Temp * 10;
    Inc(DecimalDigits);
  end;

  // Cifre della parte intera (0 se il valore assoluto e' < 1).
  IntPart := Trunc(Number);
  if IntPart = 0 then
    IntegerDigits := 0
  else
    IntegerDigits := Length(IntToStr(IntPart));

  Result := (DecimalDigits <= FScale) and
            (IntegerDigits <= (FPrecision - FScale));
end;

function TPrecisionScaleValidator.GetMessageKey: string;
begin
  Result := TMsgKey.PrecisionScale;
end;

function TPrecisionScaleValidator.GetMessageArgs: TMessageArgs;
begin
  Result := TValidationMessages.Args(['ExpectedPrecision', FPrecision, 'ExpectedScale', FScale]);
end;

end.
