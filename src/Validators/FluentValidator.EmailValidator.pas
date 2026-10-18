{-----------------------------------------------------------------------------
 Project: FluentValidator
 Unit Name: FluentValidator.EmailValidator
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
 Purpose: Validatore email unificato. Un solo validatore parametrizzato per
          modalita' (emSimple/emStrict) e AllowEmpty, che copre sia il caso
          permissivo (ex TSimpleEmailValidator) sia quello strutturale severo.
          Rispecchia il modello di FluentValidation .NET (un solo
          EmailAddress() con EmailValidationMode) senza rompere l'API esistente:
          `.Email` resta permissivo, `.EmailWithAllowEmpty` resta severo.
 History:
   15-lug-2026: unificazione non distruttiva di TEmailValidator e
                TSimpleEmailValidator dietro un unico validatore parametrizzato.
-----------------------------------------------------------------------------}

unit FluentValidator.EmailValidator;

interface

uses
  System.Rtti, System.SysUtils, System.StrUtils,
  FluentValidator.Intf, FluentValidator, FluentValidator.Messages;

type
  TEmailValidator = class(TBaseValidator)
  private
    FAllowEmpty: Boolean;
    FMode: TEmailMode;
    function IsValidSimple(const StrValue: string): Boolean;
    function IsValidStrict(const StrValue: string): Boolean;
    function IsValidLocalPart(const LocalPart: string): Boolean;
    function IsValidDomainPart(const DomainPart: string): Boolean;
    function HasAlphaNumeric(const Str: string): Boolean;
  protected
    function GetMessageKey: string; override;
  public
    // Default emStrict: preserva il comportamento storico di
    // TEmailValidator.Create(AllowEmpty) usato da .EmailWithAllowEmpty.
    constructor Create(AllowEmpty: Boolean = False; Mode: TEmailMode = emStrict);
    function IsValid(const Value: TValue): Boolean; override;
  end;

implementation

{ TEmailValidator }

constructor TEmailValidator.Create(AllowEmpty: Boolean; Mode: TEmailMode);
begin
  inherited Create;
  FAllowEmpty := AllowEmpty;
  FMode := Mode;
end;

function TEmailValidator.IsValid(const Value: TValue): Boolean;
var
  StrValue: string;
begin
  // Verifica che il valore sia una stringa
  if not Value.IsType<string> then
    Exit(False);

  StrValue := Value.AsType<string>;

  // Gestione stringa vuota (unica per entrambe le modalita')
  if StrValue.Trim.IsEmpty then
    Exit(FAllowEmpty);

  case FMode of
    emSimple: Result := IsValidSimple(StrValue);
  else
    Result := IsValidStrict(StrValue);
  end;
end;

function TEmailValidator.IsValidSimple(const StrValue: string): Boolean;
var
  AtPos: Integer;
begin
  // Logica permissiva (ex TSimpleEmailValidator, ispirata ad ASP.NET Core):
  // una '@' non ai bordi e un '.' con almeno un carattere fra '@' e punto.
  AtPos := Pos('@', StrValue);
  Result := (AtPos > 1) and
            (AtPos < Length(StrValue)) and
            (PosEx('.', StrValue, AtPos + 1) > AtPos + 1);
end;

function TEmailValidator.IsValidStrict(const StrValue: string): Boolean;
var
  AtPos: Integer;
  DotPos: Integer;
begin
  // 1. Deve contenere '@' in una posizione valida (non all'inizio e non alla fine)
  AtPos := Pos('@', StrValue);
  if (AtPos <= 1) or (AtPos >= Length(StrValue)) then
    Exit(False);

  // 2. Deve contenere un punto dopo la '@'
  DotPos := PosEx('.', StrValue, AtPos + 1);
  if DotPos = 0 then
    Exit(False);

  // 3. Il punto deve essere in una posizione valida (non subito dopo @ e non alla fine)
  if (DotPos = AtPos + 1) or (DotPos = Length(StrValue)) then
    Exit(False);

  // 4.1 La parte locale (prima della @) deve essere valida
  if not IsValidLocalPart(Copy(StrValue, 1, AtPos - 1)) then
    Exit(False);

  // 4.2 La parte dominio (dopo la @) deve essere valida
  if not IsValidDomainPart(Copy(StrValue, AtPos + 1)) then
    Exit(False);

  Result := True;
end;

function TEmailValidator.GetMessageKey: string;
begin
  Result := TMsgKey.Email;
end;

{$REGION 'Utility functions'}

function TEmailValidator.IsValidLocalPart(const LocalPart: string): Boolean;
var
  I: Integer;
  C: Char;
begin
  // La parte locale non può essere vuota
  if LocalPart.Trim.IsEmpty then
    Exit(False);

  // Controlla caratteri validi nella parte locale
  for I := 1 to Length(LocalPart) do
  begin
    C := LocalPart[I];
    // Caratteri consentiti: lettere, numeri, ., _, %, +, -
    if not (CharInSet(C, ['A'..'Z', 'a'..'z', '0'..'9', '.', '_', '%', '+', '-'])) then
      Exit(False);
  end;

  // Non può iniziare o finire con un punto
  if (LocalPart[1] = '.') or (LocalPart[Length(LocalPart)] = '.') then
    Exit(False);

  // Non può contenere due punti consecutivi
  if Pos('..', LocalPart) > 0 then
    Exit(False);

  Result := True;
end;

function TEmailValidator.IsValidDomainPart(const DomainPart: string): Boolean;
var
  I: Integer;
  C: Char;
  HasDot: Boolean;
  Segment: string;
begin
  // La parte dominio non può essere vuota
  if DomainPart.Trim.IsEmpty then
    Exit(False);

  // Controlla caratteri validi nella parte dominio
  HasDot := False;
  for I := 1 to Length(DomainPart) do
  begin
    C := DomainPart[I];
    // Caratteri consentiti: lettere, numeri, ., -
    if not (CharInSet(C, ['A'..'Z', 'a'..'z', '0'..'9', '.', '-'])) then
      Exit(False);

    if C = '.' then
      HasDot := True;
  end;

  // Deve avere almeno un punto
  if not HasDot then
    Exit(False);

  // Non può iniziare o finire con un punto
  if (DomainPart[1] = '.') or (DomainPart[Length(DomainPart)] = '.') then
    Exit(False);

  // Non può contenere due punti consecutivi
  if Pos('..', DomainPart) > 0 then
    Exit(False);

  // Verifica che ogni segmento sia valido
  for Segment in SplitString(DomainPart, '.') do
  begin
    // Segmento non può essere vuoto
    if Segment.Trim.IsEmpty then
      Exit(False);

    // Segmento non può iniziare o finire con un trattino
    if (Segment[1] = '-') or (Segment[Length(Segment)] = '-') then
      Exit(False);

    // Segmento deve contenere almeno un carattere alfanumerico
    if not HasAlphaNumeric(Segment) then
      Exit(False);
  end;

  Result := True;
end;

function TEmailValidator.HasAlphaNumeric(const Str: string): Boolean;
var
  I: Integer;
begin
  for I := 1 to Length(Str) do
  begin
    if CharInSet(Str[I], ['A'..'Z', 'a'..'z', '0'..'9']) then
      Exit(True);
  end;
  Result := False;
end;

{$ENDREGION}

end.
