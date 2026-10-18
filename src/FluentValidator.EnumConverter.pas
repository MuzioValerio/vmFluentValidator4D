{-----------------------------------------------------------------------------
 Project: FluentValidator
 Unit Name: FluentValidator.EnumConverter
 Copyright (C) 2025-2026 Muzio Valerio
 Author:    Muzio Valerio
 Date:      30-giu-2026

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
 Purpose: Utility generiche per conversione enum <-> Integer/string e ricerca
          dell'indice di un valore in un array. Base: contributo di Muzio
          Valerio (UnitEnumConverter), con la correzione descritta sotto su
          StringToEnum<T> per un nome enum non valido.
 History:
   30-giu-2026: StringToEnum<T> ora usa TryStringToEnum<T> internamente e
                solleva EArgumentException se il nome non esiste, invece di
                scrivere silenziosamente -1 come se fosse un valore valido.
-----------------------------------------------------------------------------}

unit FluentValidator.EnumConverter;

interface

uses
  System.SysUtils, System.TypInfo, System.Rtti;

type
  TEnumConverter = class
  public
    class function EnumToInt<T>(const EnumValue: T): Integer;
    class function EnumToString<T>(EnumValue: T): string;

    // Converte una stringa in un valore enum T. Solleva EArgumentException se
    // AName non corrisponde a nessun valore dell'enumerazione: a differenza
    // della versione originale, un nome non valido non viene mai trasformato
    // silenziosamente in un valore enum "casuale".
    class function StringToEnum<T>(const AName: string): T;

    // Variante "safe": restituisce False (senza sollevare eccezioni) se AName
    // non corrisponde a nessun valore dell'enumerazione. Pensata per l'uso
    // nei validatori, dove l'input non è fidato per definizione.
    class function TryStringToEnum<T>(const AName: string; out AValue: T): Boolean;

    class function FindArrayOfStringIndexOf(const aSrc: TArray<string>; const aValue: string): Integer;
    class function FindArrayOfIntIndexOf(const aSrc: TArray<Integer>; const aValue: Integer): Integer;
    class function FindArrayOfExtendedIndexOf(const aSrc: TArray<Extended>; const aValue: Extended): Integer;
    class function FindArrayOfDoubleIndexOf(const aSrc: TArray<Double>; const aValue: Double): Integer;
    class function FindArrayOfSingleIndexOf(const aSrc: TArray<Single>; const aValue: Single): Integer;
  end;

implementation

uses
  System.Math;

{ TEnumConverter }

class function TEnumConverter.EnumToInt<T>(const EnumValue: T): Integer;
begin
  Result := 0;
  Move(EnumValue, Result, SizeOf(EnumValue));
end;

class function TEnumConverter.EnumToString<T>(EnumValue: T): string;
begin
  Result := GetEnumName(TypeInfo(T), EnumToInt(EnumValue));
end;

class function TEnumConverter.TryStringToEnum<T>(const AName: string; out AValue: T): Boolean;
var
  RawValue: Integer;
begin
  RawValue := GetEnumValue(TypeInfo(T), AName);

  // GetEnumValue restituisce -1 se AName non corrisponde a nessun valore
  // dell'enumerazione: qui è l'unico punto in cui questo va intercettato.
  if RawValue = -1 then
    Exit(False);

  AValue := Default(T);
  case SizeOf(T) of
    1: PByte(@AValue)^ := RawValue;
    2: PWord(@AValue)^ := RawValue;
    4: PCardinal(@AValue)^ := RawValue;
  else
    Exit(False); // dimensione enum non supportata (caso anomalo, non dovrebbe verificarsi)
  end;

  Result := True;
end;

class function TEnumConverter.StringToEnum<T>(const AName: string): T;
begin
  if not TryStringToEnum<T>(AName, Result) then
    raise EArgumentException.CreateFmt('"%s" is not a valid value for enumeration %s',
      [AName, PTypeInfo(TypeInfo(T)).Name]);
end;

class function TEnumConverter.FindArrayOfDoubleIndexOf(const aSrc: TArray<Double>; const aValue: Double): Integer;
begin
  Result := -1;
  for var I := Low(aSrc) to High(aSrc) do
  begin
    if SameValue(aValue, aSrc[I]) then
    begin
      Result := I;
      Break;
    end;
  end;
end;

class function TEnumConverter.FindArrayOfExtendedIndexOf(const aSrc: TArray<Extended>; const aValue: Extended): Integer;
begin
  Result := -1;
  for var I := Low(aSrc) to High(aSrc) do
  begin
    if SameValue(aValue, aSrc[I]) then
    begin
      Result := I;
      Break;
    end;
  end;
end;

class function TEnumConverter.FindArrayOfSingleIndexOf(const aSrc: TArray<Single>; const aValue: Single): Integer;
begin
  Result := -1;
  for var I := Low(aSrc) to High(aSrc) do
  begin
    if SameValue(aValue, aSrc[I]) then
    begin
      Result := I;
      Break;
    end;
  end;
end;

class function TEnumConverter.FindArrayOfIntIndexOf(const aSrc: TArray<Integer>; const aValue: Integer): Integer;
begin
  Result := -1;
  for var I := Low(aSrc) to High(aSrc) do
  begin
    if aValue = aSrc[I] then
    begin
      Result := I;
      Break;
    end;
  end;
end;

class function TEnumConverter.FindArrayOfStringIndexOf(const aSrc: TArray<string>; const aValue: string): Integer;
begin
  Result := -1;
  for var I := Low(aSrc) to High(aSrc) do
  begin
    if SameText(aValue, aSrc[I]) then
    begin
      Result := I;
      Break;
    end;
  end;
end;

end.
