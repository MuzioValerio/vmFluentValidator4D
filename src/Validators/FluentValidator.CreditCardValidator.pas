{-----------------------------------------------------------------------------
 Project: FluentValidator
 Unit Name: FluentValidator.CreditCardValidator
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
 Purpose: Equivalente di CreditCard() di FluentValidation .NET. Verifica che
          la stringa possa essere un numero di carta di credito legittimo
          tramite l'algoritmo di Luhn, con la stessa logica dell'originale:
          null/stringa vuota -> valido (usare NotEmpty se la presenza e'
          obbligatoria), spazi e trattini ignorati, qualsiasi carattere non
          numerico -> non valido.
 History:
-----------------------------------------------------------------------------}

unit FluentValidator.CreditCardValidator;

interface

uses
  System.SysUtils, System.Character, System.Rtti,
  FluentValidator.Intf, FluentValidator, FluentValidator.Messages;

type
  TCreditCardValidator = class(TBaseValidator)
  protected
    function GetMessageKey: string; override;
  public
    function IsValid(const Value: TValue): Boolean; override;
  end;

implementation

{ TCreditCardValidator }

function TCreditCardValidator.IsValid(const Value: TValue): Boolean;
var
  S: string;
  I, DigitValue, Checksum: Integer;
  EvenDigit: Boolean;
begin
  // Come in .NET: un valore assente (TValue vuoto) e' considerato valido.
  if Value.IsEmpty then
    Exit(True);

  if not Value.IsType<string> then
    Exit(False);

  S := Value.AsType<string>;
  // Rimuove spazi e trattini di raggruppamento delle cifre.
  S := S.Replace(' ', '').Replace('-', '');

  // Stringa vuota -> checksum 0 -> valido, coerente con l'originale.
  Checksum := 0;
  EvenDigit := False;

  for I := High(S) downto Low(S) do
  begin
    if not S[I].IsDigit then
      Exit(False);

    DigitValue := (Ord(S[I]) - Ord('0'));
    if EvenDigit then
      DigitValue := DigitValue * 2;
    EvenDigit := not EvenDigit;

    while DigitValue > 0 do
    begin
      Checksum := Checksum + (DigitValue mod 10);
      DigitValue := DigitValue div 10;
    end;
  end;

  Result := (Checksum mod 10) = 0;
end;

function TCreditCardValidator.GetMessageKey: string;
begin
  Result := TMsgKey.CreditCard;
end;

end.
