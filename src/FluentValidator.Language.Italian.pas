{-----------------------------------------------------------------------------
 Project: FluentValidator
 Unit Name:  FluentValidator.Language.Italian
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
 Purpose: Traduzione italiana dei messaggi di validazione. Riproduce alla lettera i
  messaggi che la libreria emetteva prima dell'internazionalizzazione, cosi'
  chi la usava in italiano ritrova gli stessi testi con una riga:

    TValidationLanguages.Culture := 'it';

  L'unit si autoregistra in initialization ed e' linkata da
  FluentValidator.Validators, quindi non serve aggiungerla alle uses.

  Da usare come modello per una lingua nuova: sottoclasse
  TValidationLanguage, riempi FillTemplates e registrala.
 History:
-----------------------------------------------------------------------------}

unit FluentValidator.Language.Italian;

interface

uses
  FluentValidator.Messages;

type
  TItalianLanguage = class(TValidationLanguage)
  protected
    procedure FillTemplates; override;
  end;

const
  ItalianCulture = 'it';

implementation

{ TItalianLanguage }

procedure TItalianLanguage.FillTemplates;
begin
  Add(TMsgKey.Generic,               '{PropertyName} non è valido');

  Add(TMsgKey.NotNull,               '{PropertyName} non può essere nullo');
  Add(TMsgKey.Null,                  '{PropertyName} deve essere nullo');
  Add(TMsgKey.NotEmpty,              '{PropertyName} non può essere vuoto');
  Add(TMsgKey.Empty,                 '{PropertyName} deve essere vuoto');
  Add(TMsgKey.CollectionNotEmpty,    '{PropertyName} non può essere vuoto');

  Add(TMsgKey.Length,                '{PropertyName} deve avere lunghezza tra {MinLength} e {MaxLength} caratteri');
  Add(TMsgKey.MaxLength,             '{PropertyName} non può superare {MaxLength} caratteri');
  Add(TMsgKey.MinLength,             '{PropertyName} deve avere almeno {MinLength} caratteri');

  Add(TMsgKey.Equal,                 '{PropertyName} deve essere uguale a {ComparisonValue}');
  Add(TMsgKey.NotEqual,              '{PropertyName} non deve essere uguale a {ComparisonValue}');

  Add(TMsgKey.GreaterThan,           '{PropertyName} deve essere maggiore di {ComparisonValue}');
  Add(TMsgKey.GreaterThanOrEqual,    '{PropertyName} deve essere maggiore o uguale a {ComparisonValue}');
  Add(TMsgKey.LessThan,              '{PropertyName} deve essere minore di {ComparisonValue}');
  Add(TMsgKey.LessThanOrEqual,       '{PropertyName} deve essere minore o uguale a {ComparisonValue}');
  Add(TMsgKey.InclusiveBetween,      '{PropertyName} deve essere compreso tra {From} e {To} (inclusi)');
  Add(TMsgKey.ExclusiveBetween,      '{PropertyName} deve essere compreso tra {From} e {To} (esclusi)');
  Add(TMsgKey.PrecisionScale,        '{PropertyName} non deve avere più di {ExpectedPrecision} cifre in totale ' +
                                     'e {ExpectedScale} cifre decimali');

  Add(TMsgKey.Regex,                 '{PropertyName} non corrisponde al formato richiesto');
  Add(TMsgKey.StartsWithUpperCase,   '{PropertyName} deve iniziare con lettera maiuscola');
  Add(TMsgKey.Email,                 '{PropertyName} non è un indirizzo email valido');
  Add(TMsgKey.CreditCard,            '{PropertyName} non è un numero di carta di credito valido');

  Add(TMsgKey.MustBeInPast,          '{PropertyName} deve essere nel passato');
  Add(TMsgKey.MustBeInPastOrToday,   '{PropertyName} deve essere nel passato o oggi');
  Add(TMsgKey.MustBeInFuture,        '{PropertyName} deve essere nel futuro');
  Add(TMsgKey.MustBeInFutureOrToday, '{PropertyName} deve essere nel futuro o oggi');

  Add(TMsgKey.EnumValue,             '{PropertyName} non è un valore valido per l''enumerazione');
  Add(TMsgKey.EnumValueReceived,     '{PropertyName} non è un valore valido per l''enumerazione ' +
                                     '(ricevuto: "{ActualValue}")');
  Add(TMsgKey.EnumName,              '{PropertyName} non è un nome valido per l''enumerazione');
  Add(TMsgKey.EnumNameReceived,      '{PropertyName} non è un nome valido per l''enumerazione ' +
                                     '(ricevuto: "{ActualValue}")');

  Add(TMsgKey.Predicate,             'Validazione fallita per {PropertyName}');
  Add(TMsgKey.Conditional,           'Validazione condizionale fallita per {PropertyName}');
end;

initialization
  TValidationLanguages.RegisterLanguage(TItalianLanguage.Create(ItalianCulture));

end.
