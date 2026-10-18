{-----------------------------------------------------------------------------
 Project: FluentValidator
 Unit Name:  FluentValidator.Messages
 Copyright (C) 2025-2026 Muzio Valerio
 Author:    Muzio Valerio
 Date:      01-set-2026

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
   Catalogo dei messaggi di validazione e registro delle lingue.

  L'inglese e' la lingua di default e vive in questa unit, così è sempre
  disponibile anche se non viene registrata nessun'altra lingua. L'italiano
  sta in FluentValidator.Language.Italian.

    // messaggi in italiano
    TValidationLanguages.Culture := 'it';

    // lingua propria, senza toccare la libreria
    TValidationLanguages.RegisterLanguage(TMyFrenchLanguage.Create('fr'));
    TValidationLanguages.Culture := 'fr';

  I segnaposto sono nominali - PropertyName, MaxLength, ... racchiusi in
  parentesi graffe dentro il template - e non posizionali: un traduttore
  puo' riordinarli o ometterli senza rischiare un errore di formattazione
  a runtime. Vedi TEnglishLanguage.FillTemplates per la forma esatta.
  
 History:
  I validatori non contengono piu' il testo del messaggio: dichiarano una
  chiave (TMsgKey.NotNull, TMsgKey.MaxLength, ...) ed eventuali segnaposto.
  Il testo viene risolto qui, nella lingua corrente.
  
-----------------------------------------------------------------------------}
unit FluentValidator.Messages;

interface

uses
  System.SysUtils, System.Variants, System.Generics.Collections, System.SyncObjs;

type
  // Coppia nome/valore per un segnaposto {Nome}.
  TMessageArg = record
    Name: string;
    Value: string;
  end;

  TMessageArgs = TArray<TMessageArg>;

  // Chiavi dei messaggi predefiniti. Sono in un record per non sporcare lo
  // spazio dei nomi globale: si usano come TMsgKey.NotNull.
  TValidationMessageKeys = record
  public const
    // Fallback usato quando un validatore non dichiara nessuna chiave.
    Generic               = 'Generic';

    NotNull               = 'NotNull';
    Null                  = 'Null';
    NotEmpty              = 'NotEmpty';
    Empty                 = 'Empty';
    CollectionNotEmpty    = 'CollectionNotEmpty';

    Length                = 'Length';
    MaxLength             = 'MaxLength';
    MinLength             = 'MinLength';

    Equal                 = 'Equal';
    NotEqual              = 'NotEqual';

    GreaterThan           = 'GreaterThan';
    GreaterThanOrEqual    = 'GreaterThanOrEqual';
    LessThan              = 'LessThan';
    LessThanOrEqual       = 'LessThanOrEqual';
    InclusiveBetween      = 'InclusiveBetween';
    ExclusiveBetween      = 'ExclusiveBetween';
    PrecisionScale        = 'PrecisionScale';

    Regex                 = 'Regex';
    StartsWithUpperCase   = 'StartsWithUpperCase';
    Email                 = 'Email';
    CreditCard            = 'CreditCard';

    MustBeInPast          = 'MustBeInPast';
    MustBeInPastOrToday   = 'MustBeInPastOrToday';
    MustBeInFuture        = 'MustBeInFuture';
    MustBeInFutureOrToday = 'MustBeInFutureOrToday';

    EnumValue             = 'EnumValue';
    EnumValueReceived     = 'EnumValueReceived';
    EnumName              = 'EnumName';
    EnumNameReceived      = 'EnumNameReceived';

    Predicate             = 'Predicate';
    Conditional           = 'Conditional';
  end;

  // Alias breve, e' quello che usano i validatori.
  TMsgKey = TValidationMessageKeys;

  IValidationLanguage = interface
    ['{E31E505B-6959-4BFA-A3DD-8E10C57195FF}']
    function GetCulture: string;
    function TryGetTemplate(const Key: string; out Template: string): Boolean;
  end;

  // Base per una lingua: sottoclasse e riempi i template in FillTemplates
  // usando Add(Key, Template).
  TValidationLanguage = class(TInterfacedObject, IValidationLanguage)
  private
    FCulture: string;
    FTemplates: TDictionary<string, string>;
  protected
    procedure Add(const Key, Template: string);
    // Chiamata dal costruttore: qui la sottoclasse registra i suoi template.
    procedure FillTemplates; virtual; abstract;
  public
    constructor Create(const ACulture: string);
    destructor Destroy; override;
    function GetCulture: string;
    function TryGetTemplate(const Key: string; out Template: string): Boolean;
  end;

  // Registro globale delle lingue. Thread-safe.
  TValidationLanguages = class
  strict private
    class var FLock: TCriticalSection;
    class var FLanguages: TDictionary<string, IValidationLanguage>;
    class var FCulture: string;
    class function GetCulture: string; static;
    class procedure SetCulture(const Value: string); static;
    // 'it-IT' -> 'it'. Restituisce '' se non c'e' parte regionale.
    class function NeutralOf(const ACulture: string): string; static;
    // Da chiamare con FLock gia' preso.
    class function FindLanguage(const ACulture: string): IValidationLanguage; static;
  public
    class constructor Create;
    class destructor Destroy;

    class procedure RegisterLanguage(const Language: IValidationLanguage); static;
    class function IsRegistered(const ACulture: string): Boolean; static;
    class function RegisteredCultures: TArray<string>; static;

    // Template della chiave nella lingua corrente. Se la lingua corrente non
    // ha la chiave si ricade sull'inglese; se manca anche li', sulla chiave
    // stessa (cosi' un messaggio nuovo non ancora tradotto resta
    // riconoscibile invece di sparire).
    class function GetTemplate(const Key: string): string; static;

    // Lingua dei messaggi. Default 'en'. Accetta sia 'it' che 'it-IT'.
    class property Culture: string read GetCulture write SetCulture;
  end;

  TValidationMessages = class
  public
    // Costruisce le coppie nome/valore da una lista alternata nome, valore:
    //   Args(['MinLength', FMinLength, 'MaxLength', FMaxLength])
    class function Args(const NameValuePairs: array of const): TMessageArgs; static;

    // Sostituisce i segnaposto {Nome} presenti in Template.
    class function Render(const Template: string; const AArgs: TMessageArgs): string; static;

    // Messaggio predefinito: risolve Key nella lingua corrente e sostituisce
    // {PropertyName} piu' gli eventuali segnaposto del validatore.
    class function Build(const Key, PropertyName: string;
      const AArgs: TMessageArgs): string; static;

    // Messaggio passato a WithMessage. Accetta due stili:
    //   '{PropertyName} is required'  -> segnaposto nominali
    //   '%s is required'              -> Format posizionale
    // Il secondo e' il comportamento storico ed e' mantenuto per non rompere
    // il codice esistente; il primo e' quello consigliato, perche' non
    // solleva eccezioni se il messaggio contiene un % letterale e perche'
    // da' accesso anche ai segnaposto specifici del validatore.
    class function BuildCustom(const Template, PropertyName: string;
      const AArgs: TMessageArgs): string; static;
  end;

const
  DefaultCulture = 'en';

implementation

type
  // Lingua di default. Sempre linkata: e' il fallback di ogni altra lingua.
  TEnglishLanguage = class(TValidationLanguage)
  protected
    procedure FillTemplates; override;
  end;

function VarRecToStr(const V: TVarRec): string;
begin
  case V.VType of
    vtInteger:       Result := IntToStr(V.VInteger);
    vtInt64:         Result := IntToStr(V.VInt64^);
    vtBoolean:       Result := BoolToStr(V.VBoolean, True);
    vtChar:          Result := string(V.VChar);
    vtWideChar:      Result := V.VWideChar;
    vtExtended:      Result := FloatToStr(V.VExtended^);
    vtCurrency:      Result := CurrToStr(V.VCurrency^);
    vtString:        Result := string(V.VString^);
    vtAnsiString:    Result := string(AnsiString(V.VAnsiString));
    vtWideString:    Result := string(WideString(V.VWideString));
    vtUnicodeString: Result := string(V.VUnicodeString);
    vtPChar:         Result := string(AnsiString(V.VPChar));
    vtPWideChar:     Result := string(V.VPWideChar);
    vtVariant:       Result := VarToStr(V.VVariant^);
    vtObject:        if V.VObject <> nil then
                       Result := V.VObject.ClassName
                     else
                       Result := '';
  else
    Result := '';
  end;
end;

{ TValidationLanguage }

constructor TValidationLanguage.Create(const ACulture: string);
begin
  inherited Create;
  FCulture := ACulture;
  FTemplates := TDictionary<string, string>.Create;
  FillTemplates;
end;

destructor TValidationLanguage.Destroy;
begin
  FTemplates.Free;
  inherited;
end;

procedure TValidationLanguage.Add(const Key, Template: string);
begin
  FTemplates.AddOrSetValue(Key, Template);
end;

function TValidationLanguage.GetCulture: string;
begin
  Result := FCulture;
end;

function TValidationLanguage.TryGetTemplate(const Key: string; out Template: string): Boolean;
begin
  Result := FTemplates.TryGetValue(Key, Template);
end;

{ TEnglishLanguage }

procedure TEnglishLanguage.FillTemplates;
begin
  Add(TMsgKey.Generic,               '{PropertyName} is not valid');

  Add(TMsgKey.NotNull,               '{PropertyName} must not be null');
  Add(TMsgKey.Null,                  '{PropertyName} must be null');
  Add(TMsgKey.NotEmpty,              '{PropertyName} must not be empty');
  Add(TMsgKey.Empty,                 '{PropertyName} must be empty');
  Add(TMsgKey.CollectionNotEmpty,    '{PropertyName} must not be empty');

  Add(TMsgKey.Length,                '{PropertyName} must be between {MinLength} and {MaxLength} characters long');
  Add(TMsgKey.MaxLength,             '{PropertyName} must not exceed {MaxLength} characters');
  Add(TMsgKey.MinLength,             '{PropertyName} must be at least {MinLength} characters long');

  Add(TMsgKey.Equal,                 '{PropertyName} must be equal to {ComparisonValue}');
  Add(TMsgKey.NotEqual,              '{PropertyName} must not be equal to {ComparisonValue}');

  Add(TMsgKey.GreaterThan,           '{PropertyName} must be greater than {ComparisonValue}');
  Add(TMsgKey.GreaterThanOrEqual,    '{PropertyName} must be greater than or equal to {ComparisonValue}');
  Add(TMsgKey.LessThan,              '{PropertyName} must be less than {ComparisonValue}');
  Add(TMsgKey.LessThanOrEqual,       '{PropertyName} must be less than or equal to {ComparisonValue}');
  Add(TMsgKey.InclusiveBetween,      '{PropertyName} must be between {From} and {To} (inclusive)');
  Add(TMsgKey.ExclusiveBetween,      '{PropertyName} must be between {From} and {To} (exclusive)');
  Add(TMsgKey.PrecisionScale,        '{PropertyName} must not have more than {ExpectedPrecision} digits in total ' +
                                     'and {ExpectedScale} decimal digits');

  Add(TMsgKey.Regex,                 '{PropertyName} does not match the required format');
  Add(TMsgKey.StartsWithUpperCase,   '{PropertyName} must start with an uppercase letter');
  Add(TMsgKey.Email,                 '{PropertyName} is not a valid email address');
  Add(TMsgKey.CreditCard,            '{PropertyName} is not a valid credit card number');

  Add(TMsgKey.MustBeInPast,          '{PropertyName} must be in the past');
  Add(TMsgKey.MustBeInPastOrToday,   '{PropertyName} must be in the past or today');
  Add(TMsgKey.MustBeInFuture,        '{PropertyName} must be in the future');
  Add(TMsgKey.MustBeInFutureOrToday, '{PropertyName} must be in the future or today');

  Add(TMsgKey.EnumValue,             '{PropertyName} is not a valid value for the enumeration');
  Add(TMsgKey.EnumValueReceived,     '{PropertyName} is not a valid value for the enumeration ' +
                                     '(received: "{ActualValue}")');
  Add(TMsgKey.EnumName,              '{PropertyName} is not a valid name for the enumeration');
  Add(TMsgKey.EnumNameReceived,      '{PropertyName} is not a valid name for the enumeration ' +
                                     '(received: "{ActualValue}")');

  Add(TMsgKey.Predicate,             'The specified condition was not met for {PropertyName}');
  Add(TMsgKey.Conditional,           'Conditional validation failed for {PropertyName}');
end;

{ TValidationLanguages }

class constructor TValidationLanguages.Create;
begin
  FLock := TCriticalSection.Create;
  FLanguages := TDictionary<string, IValidationLanguage>.Create;
  FCulture := DefaultCulture;
  RegisterLanguage(TEnglishLanguage.Create(DefaultCulture));
end;

class destructor TValidationLanguages.Destroy;
begin
  FLanguages.Free;
  FLock.Free;
end;

class function TValidationLanguages.NeutralOf(const ACulture: string): string;
var
  P: Integer;
begin
  P := ACulture.IndexOf('-');
  if P > 0 then
    Result := ACulture.Substring(0, P)
  else
    Result := '';
end;

class procedure TValidationLanguages.RegisterLanguage(const Language: IValidationLanguage);
begin
  if not Assigned(Language) then
    raise EArgumentNilException.Create('Language cannot be nil');
  FLock.Enter;
  try
    FLanguages.AddOrSetValue(LowerCase(Language.GetCulture), Language);
  finally
    FLock.Leave;
  end;
end;

class function TValidationLanguages.IsRegistered(const ACulture: string): Boolean;
begin
  FLock.Enter;
  try
    Result := FLanguages.ContainsKey(LowerCase(ACulture));
  finally
    FLock.Leave;
  end;
end;

class function TValidationLanguages.RegisteredCultures: TArray<string>;
begin
  FLock.Enter;
  try
    Result := FLanguages.Keys.ToArray;
  finally
    FLock.Leave;
  end;
end;

class function TValidationLanguages.FindLanguage(const ACulture: string): IValidationLanguage;
var
  Neutral: string;
begin
  if FLanguages.TryGetValue(LowerCase(ACulture), Result) then
    Exit;
  Neutral := NeutralOf(LowerCase(ACulture));
  if (Neutral <> '') and FLanguages.TryGetValue(Neutral, Result) then
    Exit;
  Result := nil;
end;

class function TValidationLanguages.GetCulture: string;
begin
  FLock.Enter;
  try
    Result := FCulture;
  finally
    FLock.Leave;
  end;
end;

class procedure TValidationLanguages.SetCulture(const Value: string);
begin
  FLock.Enter;
  try
    if Value = '' then
      FCulture := DefaultCulture
    else
      FCulture := Value;
  finally
    FLock.Leave;
  end;
end;

class function TValidationLanguages.GetTemplate(const Key: string): string;
var
  Language: IValidationLanguage;
  Found: Boolean;
begin
  if Key = '' then
    Exit(GetTemplate(TMsgKey.Generic));

  FLock.Enter;
  try
    Language := FindLanguage(FCulture);
    Found := Assigned(Language) and Language.TryGetTemplate(Key, Result);
    if not Found then
    begin
      // Fallback sull'inglese: una lingua parziale non fa sparire i messaggi.
      Language := FindLanguage(DefaultCulture);
      Found := Assigned(Language) and Language.TryGetTemplate(Key, Result);
    end;
  finally
    FLock.Leave;
  end;

  if not Found then
    Result := Key;
end;

{ TValidationMessages }

class function TValidationMessages.Args(const NameValuePairs: array of const): TMessageArgs;
var
  I, Count: Integer;
begin
  Count := System.Length(NameValuePairs) div 2;
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
  begin
    Result[I].Name := VarRecToStr(NameValuePairs[I * 2]);
    Result[I].Value := VarRecToStr(NameValuePairs[I * 2 + 1]);
  end;
end;

class function TValidationMessages.Render(const Template: string;
  const AArgs: TMessageArgs): string;
var
  Arg: TMessageArg;
begin
  Result := Template;
  for Arg in AArgs do
    if Arg.Name <> '' then
      Result := StringReplace(Result, '{' + Arg.Name + '}', Arg.Value, [rfReplaceAll]);
end;

class function TValidationMessages.Build(const Key, PropertyName: string;
  const AArgs: TMessageArgs): string;
begin
  Result := Render(TValidationLanguages.GetTemplate(Key),
    AArgs + Args(['PropertyName', PropertyName]));
end;

class function TValidationMessages.BuildCustom(const Template, PropertyName: string;
  const AArgs: TMessageArgs): string;
begin
  if Template.Contains('{') then
    Result := Render(Template, AArgs + Args(['PropertyName', PropertyName]))
  else
    // Comportamento storico: un solo argomento posizionale, il nome della
    // proprieta'. Un % letterale qui solleva ancora, esattamente come prima.
    Result := Format(Template, [PropertyName]);
end;

end.
