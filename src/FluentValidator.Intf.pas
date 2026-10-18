{-----------------------------------------------------------------------------
 Project: FluentValidator
 Unit Name: FluentValidator.Intf
 Copyright (C) 2025-2026 Muzio Valerio
 Author:    Muzio Valerio
 Date:      25-giu-2026

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

unit FluentValidator.Intf;

interface

uses
  System.SysUtils, System.Generics.Collections, System.Rtti, System.TypInfo;

type
  // Forward declarations
  IRuleBuilderOptions<T, TProp> = interface;
  IValidationRule = interface;
  IValidationResult = interface;
  IValidationError = interface;
  IValidator<T> = interface;

  // Modalita' di cascata: se una regola con piu' validatori sulla stessa
  // proprieta' debba fermarsi al primo errore (cmStop) o raccoglierli tutti
  // (cmContinue). Equivalente di CascadeMode di FluentValidation .NET.
  TCascadeMode = (cmContinue, cmStop);

  // Gravita' di un errore di validazione. svError = bloccante (default),
  // svWarning = avviso non bloccante. Utile p.es. per distinguere gli errori
  // che bloccano l'invio SDI dai semplici avvisi. Come in FluentValidation
  // .NET, la presenza di errori (di qualunque gravita') rende comunque
  // IsValid = False: sta al consumatore filtrare i soli svError.
  TValidationSeverity = (svError, svWarning);

  // Modalita' di validazione email:
  //  - emSimple: controllo permissivo (c'e' una '@' non ai bordi e un '.' dopo),
  //    equivalente al default AspNetCoreCompatible di FluentValidation .NET;
  //  - emStrict: controllo strutturale severo di parte locale e dominio.
  TEmailMode = (emSimple, emStrict);

  // 1. Validatore base come interfaccia
  IPropertyValidator = interface
  ['{8E4F2D1A-3B5C-4E7F-9A1B-2C3D4E5F6A7B}']
  function IsValid(const Value: TValue): Boolean;
  function GetErrorMessage(const PropertyName: string): string;
  procedure SetCustomMessage(const Message: string);
  function GetCustomMessage: string;
  procedure SetSeverity(Severity: TValidationSeverity);
  function GetSeverity: TValidationSeverity;
end;

  // 2. Interfaccia per type erasure (nasconde il TProp)
  IValidationRule = interface
    ['{F9E8D7C6-B5A4-4938-8F7E-6D5C4B3A2F1E}']
    function Validate(Entity: TObject; out ErrorMessage: string): Boolean; overload;
    function ValidateAll(Entity: TObject; Errors: TList<IValidationError>): Boolean; overload;
    function GetPropertyName: string;
  end;

  // 3. Builder principale che accumula le regole
  IRuleBuilder<T, TProp> = interface
    ['{A1B2C3D4-E5F6-4A7B-8C9D-0E1F2A3B4C5D}']
    // Validatori di base
    function NotNull: IRuleBuilderOptions<T, TProp>;
    function NotEmpty: IRuleBuilderOptions<T, TProp>;
    function Null: IRuleBuilderOptions<T, TProp>;
    function Empty: IRuleBuilderOptions<T, TProp>;
    function Matches(const Pattern: string): IRuleBuilderOptions<T, TProp>;
    function Must(Predicate: TPredicate<TProp>; const ErrorMessage: string): IRuleBuilderOptions<T, TProp>;
    function PrecisionScale(Precision, Scale: Integer): IRuleBuilderOptions<T, TProp>;

    // Validazione nidificata: applica un IValidator<TProp> alla proprieta'
    // (oggetto complesso) e "appiattisce" gli errori figli nel risultato padre
    // con prefisso sul nome (es. CedentePrestatore.Sede.CAP).
    function SetValidator(Validator: IValidator<TProp>): IRuleBuilderOptions<T, TProp>;
    
    // Validatori custom (esempi)
    function StartsWithUpperCase: IRuleBuilderOptions<T, TProp>;
    function StartsWithUpperCaseWithMessage(const Message: string): IRuleBuilderOptions<T, TProp>;

    // Validatori stringa
    function Equal(const Value: string): IRuleBuilderOptions<T, TProp>; overload;
    function Equal(Value: Integer): IRuleBuilderOptions<T, TProp>; overload;
    function NotEqual(const Value: string): IRuleBuilderOptions<T, TProp>; overload;
    function NotEqual(Value: Integer): IRuleBuilderOptions<T, TProp>; overload;
    function MaxLength(MaxLength: Integer): IRuleBuilderOptions<T, TProp>;
    function MinLength(MinLength: Integer): IRuleBuilderOptions<T, TProp>;
    function Length(MinLength, MaxLength: Integer): IRuleBuilderOptions<T, TProp>;

    // Validatori Email.
    //  .Email                 -> permissivo (emSimple), stringa vuota NON valida
    //  .EmailWithAllowEmpty   -> severo (emStrict), stringa vuota valida se AllowEmpty
    //  .EmailAddress          -> scelta esplicita di modalita' e AllowEmpty
    function Email: IRuleBuilderOptions<T, TProp>;
    function EmailWithAllowEmpty(AllowEmpty: Boolean): IRuleBuilderOptions<T, TProp>;
    function EmailAddress(Mode: TEmailMode = emSimple; AllowEmpty: Boolean = False): IRuleBuilderOptions<T, TProp>;

    // Carta di credito (algoritmo di Luhn)
    function CreditCard: IRuleBuilderOptions<T, TProp>;

    // Validatori di enumerazioni
    function IsInEnum(EnumTypeInfo: PTypeInfo): IRuleBuilderOptions<T, TProp>;
    function IsEnumName(EnumTypeInfo: PTypeInfo; CaseSensitive: Boolean = False): IRuleBuilderOptions<T, TProp>;

    // Validatori di collezioni
    function NotEmptyCollection: IRuleBuilderOptions<T, TProp>;

    // Validatori di date
    function MustBeInPast(IncludeToday: Boolean = False): IRuleBuilderOptions<T, TProp>;
    function MustBeInFuture(IncludeToday: Boolean = False): IRuleBuilderOptions<T, TProp>;

    // Validatori condizionali
    function When(Condition: TFunc<T, Boolean>): IRuleBuilderOptions<T, TProp>;
    function Unless(Condition: TFunc<T, Boolean>): IRuleBuilderOptions<T, TProp>;

    // Validatori numerici
    function LessThan(MaxValue: Integer): IRuleBuilderOptions<T, TProp>;
    function LessThanOrEqual(MaxValue: Integer): IRuleBuilderOptions<T, TProp>;
    function GreaterThan(MinValue: Integer): IRuleBuilderOptions<T, TProp>;
    function GreaterThanOrEqual(MinValue: Integer): IRuleBuilderOptions<T, TProp>;
    function InclusiveBetween(MinValue, MaxValue: Integer): IRuleBuilderOptions<T, TProp>;
    function ExclusiveBetween(MinValue, MaxValue: Integer): IRuleBuilderOptions<T, TProp>;
  end;

  // 4. Builder options (permette anche di settare messaggi custom)
  IRuleBuilderOptions<T, TProp> = interface(IRuleBuilder<T, TProp>)
    ['{F1E2D3C4-B5A6-4978-8F9E-0D1C2B3A4F5E}']
    function WithMessage(const Message: string): IRuleBuilderOptions<T, TProp>;
    function StopOnFirstFailure: IRuleBuilderOptions<T, TProp>;
    // Come StopOnFirstFailure, ma esplicito e simmetrico: cmStop equivale a
    // StopOnFirstFailure, cmContinue e' il comportamento di default.
    function Cascade(Mode: TCascadeMode): IRuleBuilderOptions<T, TProp>;
    // Imposta la gravita' dell'ultima regola aggiunta (default svError).
    function WithSeverity(Severity: TValidationSeverity): IRuleBuilderOptions<T, TProp>;
  end;

  // 5. Validator per l'entity
  IValidator<T> = interface
    ['{C5D4E3F2-A1B2-4C3D-9E8F-7A6B5C4D3E2F}']
    function Validate(Entity: T): IValidationResult;
  end;

  // 6. Risultato validazione
  IValidationError = interface
    ['{D6E5F4A3-B2C1-4D5E-9F8A-7B6C5D4E3F2A}']
    function GetPropertyName: string;
    function GetErrorMessage: string;
    function GetSeverity: TValidationSeverity;
    property PropertyName: string read GetPropertyName;
    property ErrorMessage: string read GetErrorMessage;
    property Severity: TValidationSeverity read GetSeverity;
  end;

  IValidationResult = interface
    ['{E7F6A5B4-C3D2-4E5F-8A9B-6C7D5E4F3A2B}']
    function GetIsValid: Boolean;
    function GetErrors: TArray<IValidationError>;
    procedure AddError(const PropertyName, ErrorMessage: string); overload;
    procedure AddError(const PropertyName, ErrorMessage: string; Severity: TValidationSeverity); overload;
    property IsValid: Boolean read GetIsValid;
    property Errors: TArray<IValidationError> read GetErrors;
  end;

  IValidationRuleWithStop = interface(IValidationRule)
    ['{CD6EB63D-064D-4AD4-9098-2A29F6E944A7}']
    function GetStopOnFirstFailure: Boolean;
    property StopOnFirstFailureEnabled: Boolean read GetStopOnFirstFailure;
  end;

implementation

end.