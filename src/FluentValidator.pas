{-----------------------------------------------------------------------------
 Project: FluentValidator
 Unit Name: FluentValidator
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

unit FluentValidator;

interface

uses
  System.SysUtils, System.Generics.Collections, System.Rtti, System.TypInfo,
  FluentValidator.Intf, FluentValidator.Messages;

type
  TAbstractValidator<T> = class abstract(TInterfacedObject, IValidator<T>)
  protected
    FRules: TList<IValidationRule>;
    // Contesto RTTI tenuto in vita per l'intera durata del validatore: mantiene
    // validi i TRttiProperty/TRttiField catturati dai getter RTTI-based.
    FRttiCtx: TRttiContext;
    function AddRule<TProp>(Rule: IRuleBuilderOptions<T, TProp>): IRuleBuilderOptions<T, TProp>;
    // Costruisce un getter che legge la proprieta'/campo `PropertyName` via RTTI.
    function MakeRttiGetter<TProp>(const PropertyName: string): TFunc<T, TProp>;
  public
    constructor Create;
    destructor Destroy; override;

    // Forma con getter esplicito. Usala quando T non e' una classe con RTTI, per
    // valori calcolati, o quando vuoi evitare del tutto la reflection.
    function RuleFor<TProp>(const PropertyName: string; Getter: TFunc<T, TProp>): IRuleBuilderOptions<T, TProp>; overload;
    // Forma RACCOMANDATA: basta il nome della proprieta'/campo, il valore viene
    // letto via RTTI (niente getter-lambda, nessuna duplicazione nome+getter).
    // Un NOME errato fallisce subito, alla definizione della regola (fail-fast);
    // un TIPO incompatibile fra membro e TProp solleva un errore esplicito e
    // leggibile alla prima validazione. Richiede che T sia una classe con RTTI
    // sul membro (i campi/proprieta' public/published lo hanno di default).
    function RuleFor<TProp>(const PropertyName: string): IRuleBuilderOptions<T, TProp>; overload;
    function RuleForEach<TItem>(const PropertyName: string; Getter: TFunc<T, TEnumerable<TItem>>): IRuleBuilderOptions<T, TItem>;
    // Regola sull'intero oggetto: getter identita', per regole di coerenza
    // cross-campo (es. totale documento = somma delle righe) via .Must.
    function RuleForObject(const PropertyName: string): IRuleBuilderOptions<T, T>;
    function Validate(Entity: T): IValidationResult; virtual; abstract;
  end;

  TBaseValidator = class abstract(TInterfacedObject, IPropertyValidator)
  private
    FCustomMessage: string;
    FSeverity: TValidationSeverity;
  protected
    // Chiave del messaggio nel catalogo lingue (FluentValidator.Messages).
    // E' questo che un validatore dichiara al posto del testo: cosi' lo
    // stesso validatore parla tutte le lingue registrate.
    function GetMessageKey: string; virtual;
    // Segnaposto specifici del validatore, in coppie nome/valore:
    //   Result := TValidationMessages.Args(['MaxLength', FMaxLength]);
    // {PropertyName} e' sempre disponibile e non va aggiunto qui. Vengono
    // usati sia dal messaggio di default sia da quello passato a WithMessage.
    function GetMessageArgs: TMessageArgs; virtual;
    // Da sovrascrivere solo per messaggi che non si esprimono con una chiave
    // fissa; nel caso normale basta GetMessageKey / GetMessageArgs.
    function GetDefaultErrorMessage(const PropertyName: string): string; virtual;
  public
    function IsValid(const Value: TValue): Boolean; virtual; abstract;
    function GetErrorMessage(const PropertyName: string): string; virtual;
    procedure SetCustomMessage(const Message: string);
    function GetCustomMessage: string;
    procedure SetSeverity(Severity: TValidationSeverity);
    function GetSeverity: TValidationSeverity; virtual;
  end;

  // Implementazione del RuleBuilder
  TRuleBuilder<T, TProp> = class(TInterfacedObject, IRuleBuilder<T, TProp>,
    IRuleBuilderOptions<T, TProp>, IValidationRule, IValidationRuleWithStop)
  private
    FEntityType: TClass;
    FPropertyName: string;
    FGetter: TFunc<T, TProp>;
    FValidators: TList<IPropertyValidator>;
    FStopOnFirstFailure: Boolean;

    FCurrentCondition: TFunc<T, Boolean>;

    // Validazione nidificata (SetValidator): closure con type-erasure che
    // esegue un IValidator<TProp> sul valore della proprieta'.
    FNestedValidators: TList<TFunc<TValue, IValidationResult>>;

    // Modalita' RuleForEach: quando attiva, FForEachGetter fornisce la
    // collezione e i validatori (FValidators/FNestedValidators) si applicano
    // a ogni elemento.
    FIsForEach: Boolean;
    FForEachGetter: TFunc<T, TEnumerable<TProp>>;

    procedure AddValidator(Validator: IPropertyValidator);
    function ShouldRunValidator(const Validator: IPropertyValidator; Entity: TObject): Boolean;
    function ValidateAllInternal(Entity: TObject; Errors: TList<IValidationError>): Boolean;
    function ValidateSingle(const TypedEntity: T; Entity: TObject; Errors: TList<IValidationError>): Boolean;
    function ValidateForEach(const TypedEntity: T; Entity: TObject; Errors: TList<IValidationError>): Boolean;
    procedure MergeChildErrors(const ChildResult: IValidationResult; const NamePrefix: string;
      Errors: TList<IValidationError>; var AllValid: Boolean);
    function ValidateTyped(Entity: T; out ErrorMessage: string): Boolean;
  public
    constructor Create(EntityType: TClass; const PropertyName: string; Getter: TFunc<T, TProp>);
    constructor CreateForEach(EntityType: TClass; const PropertyName: string; CollectionGetter: TFunc<T, TEnumerable<TProp>>);
    destructor Destroy; override;

    // IRuleBuilder
    function NotNull: IRuleBuilderOptions<T, TProp>;
    function NotEmpty: IRuleBuilderOptions<T, TProp>;
    function Null: IRuleBuilderOptions<T, TProp>;
    function Empty: IRuleBuilderOptions<T, TProp>;
    function PrecisionScale(Precision, Scale: Integer): IRuleBuilderOptions<T, TProp>;
    function Matches(const Pattern: string): IRuleBuilderOptions<T, TProp>;
    function Must(Predicate: TPredicate<TProp>; const ErrorMessage: string): IRuleBuilderOptions<T, TProp>;
    function SetValidator(Validator: IValidator<TProp>): IRuleBuilderOptions<T, TProp>;
    function StartsWithUpperCase: IRuleBuilderOptions<T, TProp>;
    function StartsWithUpperCaseWithMessage(const Message: string): IRuleBuilderOptions<T, TProp>;

    // Added by muzio_dell Date: 25-giu-2026
    function Equal(const Value: string): IRuleBuilderOptions<T, TProp>; overload;
    function Equal(Value: Integer): IRuleBuilderOptions<T, TProp>; overload;
    function NotEqual(const Value: string): IRuleBuilderOptions<T, TProp>; overload;
    function NotEqual(Value: Integer): IRuleBuilderOptions<T, TProp>; overload;
    function MaxLength(MaxLength: Integer): IRuleBuilderOptions<T, TProp>;
    function MinLength(MinLength: Integer): IRuleBuilderOptions<T, TProp>;

    // Validatori Numerici
    function Length(MinLength, MaxLength: Integer): IRuleBuilderOptions<T, TProp>;
    function LessThan(MaxValue: Integer): IRuleBuilderOptions<T, TProp>;
    function LessThanOrEqual(MaxValue: Integer): IRuleBuilderOptions<T, TProp>;
    function GreaterThan(MinValue: Integer): IRuleBuilderOptions<T, TProp>;
    function GreaterThanOrEqual(MinValue: Integer): IRuleBuilderOptions<T, TProp>;
    function InclusiveBetween(MinValue, MaxValue: Integer): IRuleBuilderOptions<T, TProp>;
    function ExclusiveBetween(MinValue, MaxValue: Integer): IRuleBuilderOptions<T, TProp>;

    // Validatori Email avanzati
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

    // IRuleBuilderOptions
    function WithMessage(const Message: string): IRuleBuilderOptions<T, TProp>;
    function StopOnFirstFailure: IRuleBuilderOptions<T, TProp>;
    function Cascade(Mode: TCascadeMode): IRuleBuilderOptions<T, TProp>;
    function WithSeverity(Severity: TValidationSeverity): IRuleBuilderOptions<T, TProp>;

    // IValidationRule
    function Validate(Entity: TObject; out ErrorMessage: string): Boolean; overload;
    function ValidateAll(Entity: TObject; Errors: TList<IValidationError>): Boolean; overload;
    function GetPropertyName: string;

    // IValidationRuleWithStop
    function GetStopOnFirstFailure: Boolean;
    property StopOnFirstFailureEnabled: Boolean read GetStopOnFirstFailure;

  end;

  TValidator<T> = class(TAbstractValidator<T>)
  private
    FGlobalStopOnFirstFailure: Boolean;
  protected
    // Hook chiamato prima del ciclo sulle regole. Restituendo False la
    // validazione si ferma e viene restituito il Result cosi' com'e' (utile
    // p.es. per gestire un'entity nil con un messaggio chiaro invece di
    // un'eccezione RTTI). L'implementazione di default non fa nulla.
    function PreValidate(Entity: T; AResult: IValidationResult): Boolean; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    function Validate(Entity: T): IValidationResult; override;

    // Metodo per abilitare StopOnFirstFailure a livello GLOBALE
    function StopOnFirstFailure: TValidator<T>;
    // Variante esplicita, equivalente: cmStop = StopOnFirstFailure globale.
    function Cascade(Mode: TCascadeMode): TValidator<T>;
  end;

  TValidationError = class(TInterfacedObject, IValidationError)
  private
    FPropertyName: string;
    FErrorMessage: string;
    FSeverity: TValidationSeverity;
  public
    constructor Create(const PropertyName, ErrorMessage: string;
      Severity: TValidationSeverity = svError);
    function GetPropertyName: string;
    function GetErrorMessage: string;
    function GetSeverity: TValidationSeverity;
  end;

  TValidationResult = class(TInterfacedObject, IValidationResult)
  private
    FErrors: TList<IValidationError>;
  public
    constructor Create;
    destructor Destroy; override;
    function GetIsValid: Boolean;
    function GetErrors: TArray<IValidationError>;
    procedure AddError(const PropertyName, ErrorMessage: string); overload;
    procedure AddError(const PropertyName, ErrorMessage: string; Severity: TValidationSeverity); overload;
  end;

implementation

uses
  FluentValidator.Validators,
  FluentValidator.WhenValidator;

{ TBaseValidator }

function TBaseValidator.GetMessageKey: string;
begin
  Result := '';
end;

function TBaseValidator.GetMessageArgs: TMessageArgs;
begin
  Result := nil;
end;

function TBaseValidator.GetDefaultErrorMessage(const PropertyName: string): string;
begin
  Result := TValidationMessages.Build(GetMessageKey, PropertyName, GetMessageArgs);
end;

function TBaseValidator.GetErrorMessage(const PropertyName: string): string;
begin
  if FCustomMessage <> '' then
    Result := TValidationMessages.BuildCustom(FCustomMessage, PropertyName, GetMessageArgs)
  else
    Result := GetDefaultErrorMessage(PropertyName);
end;

procedure TBaseValidator.SetCustomMessage(const Message: string);
begin
  FCustomMessage := Message;
end;

function TBaseValidator.GetCustomMessage: string;
begin
  Result := FCustomMessage;
end;

procedure TBaseValidator.SetSeverity(Severity: TValidationSeverity);
begin
  FSeverity := Severity;
end;

function TBaseValidator.GetSeverity: TValidationSeverity;
begin
  Result := FSeverity;
end;

{ TRuleBuilder<T, TProp> }

constructor TRuleBuilder<T, TProp>.Create(EntityType: TClass; const PropertyName: string; Getter: TFunc<T, TProp>);
begin
  inherited Create;
  FEntityType := EntityType;
  FPropertyName := PropertyName;
  FGetter := Getter;
  FValidators := TList<IPropertyValidator>.Create;
  FNestedValidators := TList<TFunc<TValue, IValidationResult>>.Create;
  FStopOnFirstFailure := False;
  FCurrentCondition := nil;
  FIsForEach := False;
  FForEachGetter := nil;
end;

constructor TRuleBuilder<T, TProp>.CreateForEach(EntityType: TClass; const PropertyName: string;
  CollectionGetter: TFunc<T, TEnumerable<TProp>>);
begin
  Create(EntityType, PropertyName, nil);
  FIsForEach := True;
  FForEachGetter := CollectionGetter;
end;

destructor TRuleBuilder<T, TProp>.Destroy;
begin
  FNestedValidators.Free;
  FValidators.Free;
  inherited;
end;

procedure TRuleBuilder<T, TProp>.AddValidator(Validator: IPropertyValidator);
begin
  if Assigned(FCurrentCondition) then
  begin
    var ConditionalValidator := TWhen.Create(
      function(Entity: TObject): Boolean
      begin
        Result := FCurrentCondition(TValue.From<TObject>(Entity).AsType<T>);
      end,
      Validator
    );
    FValidators.Add(ConditionalValidator);
  end
  else
    FValidators.Add(Validator);
end;

function TRuleBuilder<T, TProp>.ShouldRunValidator(const Validator: IPropertyValidator; Entity: TObject): Boolean;
var
  ConditionalValidator: IConditionalValidator;
begin
  // Se il validatore e' un wrapper When/Unless, la regola interna va eseguita
  // solo se la condizione associata e' verificata sull'intera entity.
  if Supports(Validator, IConditionalValidator, ConditionalValidator) then
    Result := ConditionalValidator.EvaluateCondition(Entity)
  else
    Result := True;
end;

function TRuleBuilder<T, TProp>.NotNull: IRuleBuilderOptions<T, TProp>;
begin
  AddValidator(TNotNull.Create);
  Result := Self;
end;

function TRuleBuilder<T, TProp>.NotEmpty: IRuleBuilderOptions<T, TProp>;
begin
  AddValidator(TNotEmpty.Create);
  Result := Self;
end;

function TRuleBuilder<T, TProp>.Null: IRuleBuilderOptions<T, TProp>;
begin
  AddValidator(TNull.Create);
  Result := Self;
end;

function TRuleBuilder<T, TProp>.Empty: IRuleBuilderOptions<T, TProp>;
begin
  AddValidator(TEmpty.Create);
  Result := Self;
end;

function TRuleBuilder<T, TProp>.PrecisionScale(Precision, Scale: Integer): IRuleBuilderOptions<T, TProp>;
begin
  AddValidator(TPrecisionScale.Create(Precision, Scale));
  Result := Self;
end;

function TRuleBuilder<T, TProp>.Length(MinLength, MaxLength: Integer): IRuleBuilderOptions<T, TProp>;
begin
  AddValidator(TLength.Create(MinLength, MaxLength));
  Result := Self;
end;

function TRuleBuilder<T, TProp>.Equal(const Value: string): IRuleBuilderOptions<T, TProp>;
begin
  AddValidator(TEqual.Create(Value));
  Result := Self;
end;

function TRuleBuilder<T, TProp>.Email: IRuleBuilderOptions<T, TProp>;
begin
  // Comportamento storico invariato: validazione permissiva, vuoto non valido.
  AddValidator(TEmail.Create(False, emSimple));
  Result := Self;
end;

function TRuleBuilder<T, TProp>.EmailAddress(Mode: TEmailMode; AllowEmpty: Boolean): IRuleBuilderOptions<T, TProp>;
begin
  AddValidator(TEmail.Create(AllowEmpty, Mode));
  Result := Self;
end;

function TRuleBuilder<T, TProp>.EmailWithAllowEmpty(AllowEmpty: Boolean): IRuleBuilderOptions<T, TProp>;
begin
  AddValidator(TEmail.Create(AllowEmpty));
  Result := Self;
end;

function TRuleBuilder<T, TProp>.CreditCard: IRuleBuilderOptions<T, TProp>;
begin
  AddValidator(TCreditCard.Create);
  Result := Self;
end;

function TRuleBuilder<T, TProp>.Equal(Value: Integer): IRuleBuilderOptions<T, TProp>;
begin
  AddValidator(TEqual.Create(Value));
  Result := Self;
end;

function TRuleBuilder<T, TProp>.NotEqual(const Value: string): IRuleBuilderOptions<T, TProp>;
begin
  AddValidator(TNotEqual.Create(Value));
  Result := Self;
end;

function TRuleBuilder<T, TProp>.NotEqual(Value: Integer): IRuleBuilderOptions<T, TProp>;
begin
  AddValidator(TNotEqual.Create(Value));
  Result := Self;
end;

function TRuleBuilder<T, TProp>.MaxLength(MaxLength: Integer): IRuleBuilderOptions<T, TProp>;
begin
  AddValidator(TMaxLength.Create(MaxLength));
  Result := Self;
end;

function TRuleBuilder<T, TProp>.MinLength(MinLength: Integer): IRuleBuilderOptions<T, TProp>;
begin
  AddValidator(TMinLength.Create(MinLength));
  Result := Self;
end;

function TRuleBuilder<T, TProp>.LessThan(MaxValue: Integer): IRuleBuilderOptions<T, TProp>;
begin
  AddValidator(TLessThan.Create(MaxValue));
  Result := Self;
end;

function TRuleBuilder<T, TProp>.LessThanOrEqual(MaxValue: Integer): IRuleBuilderOptions<T, TProp>;
begin
  AddValidator(TLessThanOrEqual.Create(MaxValue));
  Result := Self;
end;

function TRuleBuilder<T, TProp>.GreaterThan(MinValue: Integer): IRuleBuilderOptions<T, TProp>;
begin
  AddValidator(TGreaterThan.Create(MinValue));
  Result := Self;
end;

function TRuleBuilder<T, TProp>.GreaterThanOrEqual(MinValue: Integer): IRuleBuilderOptions<T, TProp>;
begin
  AddValidator(TGreaterThanOrEqual.Create(MinValue));
  Result := Self;
end;

function TRuleBuilder<T, TProp>.InclusiveBetween(MinValue, MaxValue: Integer): IRuleBuilderOptions<T, TProp>;
begin
  AddValidator(TInclusiveBetween.Create(MinValue, MaxValue));
  Result := Self;
end;

function TRuleBuilder<T, TProp>.ExclusiveBetween(MinValue, MaxValue: Integer): IRuleBuilderOptions<T, TProp>;
begin
  AddValidator(TExclusiveBetween.Create(MinValue, MaxValue));
  Result := Self;
end;

function TRuleBuilder<T, TProp>.Matches(const Pattern: string): IRuleBuilderOptions<T, TProp>;
begin
  AddValidator(TRegex.Create(Pattern));
  Result := Self;
end;

function TRuleBuilder<T, TProp>.Must(Predicate: TPredicate<TProp>; const ErrorMessage: string): IRuleBuilderOptions<T, TProp>;
var
  WrappedPredicate: TPredicate<TValue>;
begin
  WrappedPredicate := function(Value: TValue): Boolean
  begin
    if Value.IsEmpty then
      Result := Predicate(Default(TProp))
    else
      Result := Predicate(Value.AsType<TProp>);
  end;

  AddValidator(TCustomPredicate.Create(WrappedPredicate, ErrorMessage));
  Result := Self;
end;

function TRuleBuilder<T, TProp>.SetValidator(Validator: IValidator<TProp>): IRuleBuilderOptions<T, TProp>;
begin
  // Type-erasure: la closure cattura l'IValidator<TProp> (interfaccia,
  // reference-counted, quindi tenuta in vita dalla lista) ed esegue la
  // validazione sul valore della proprieta' estratto come TValue.
  if Assigned(Validator) then
    FNestedValidators.Add(
      function(Value: TValue): IValidationResult
      begin
        // Un oggetto nidificato nil non viene validato (come in .NET); usare
        // NotNull separatamente se la presenza dell'oggetto e' obbligatoria.
        if Value.IsObject and (Value.AsObject = nil) then
          Exit(nil);
        Result := Validator.Validate(Value.AsType<TProp>);
      end);
  Result := Self;
end;

function TRuleBuilder<T, TProp>.WithMessage(const Message: string): IRuleBuilderOptions<T, TProp>;
begin
  if FValidators.Count > 0 then
  begin
    var LastValidator := FValidators[FValidators.Count - 1];

    if Supports(LastValidator, IConditionalValidator) then
    begin
      var Conditional := LastValidator as TWhen;
      var InnerValidator := Conditional.GetInnerValidator;
      if Assigned(InnerValidator) then
        InnerValidator.SetCustomMessage(Message);
    end
    else
      LastValidator.SetCustomMessage(Message);
  end;
  Result := Self;
end;

function TRuleBuilder<T, TProp>.WithSeverity(Severity: TValidationSeverity): IRuleBuilderOptions<T, TProp>;
begin
  // Applica la gravita' all'ultimo validatore aggiunto, sbrogliando il wrapper
  // condizionale When/Unless come fa WithMessage.
  if FValidators.Count > 0 then
  begin
    var LastValidator := FValidators[FValidators.Count - 1];

    if Supports(LastValidator, IConditionalValidator) then
    begin
      var Conditional := LastValidator as TWhen;
      var InnerValidator := Conditional.GetInnerValidator;
      if Assigned(InnerValidator) then
        InnerValidator.SetSeverity(Severity);
    end
    else
      LastValidator.SetSeverity(Severity);
  end;
  Result := Self;
end;

function TRuleBuilder<T, TProp>.StopOnFirstFailure: IRuleBuilderOptions<T, TProp>;
begin
  FStopOnFirstFailure := True;
  Result := Self;
end;

function TRuleBuilder<T, TProp>.Cascade(Mode: TCascadeMode): IRuleBuilderOptions<T, TProp>;
begin
  FStopOnFirstFailure := (Mode = cmStop);
  Result := Self;
end;

function TRuleBuilder<T, TProp>.Validate(Entity: TObject; out ErrorMessage: string): Boolean;
var
  EntityValue: TValue;
begin
  EntityValue := TValue.From(Entity);
  Result := ValidateTyped(EntityValue.AsType<T>, ErrorMessage);
end;

function TRuleBuilder<T, TProp>.ValidateAll(Entity: TObject; Errors: TList<IValidationError>): Boolean;
begin
  Result := ValidateAllInternal(Entity, Errors);
end;

function TRuleBuilder<T, TProp>.ValidateAllInternal(Entity: TObject; Errors: TList<IValidationError>): Boolean;
var
  TypedEntity: T;
begin
  TypedEntity := TValue.From<TObject>(Entity).AsType<T>;
  if FIsForEach then
    Result := ValidateForEach(TypedEntity, Entity, Errors)
  else
    Result := ValidateSingle(TypedEntity, Entity, Errors);
end;

procedure TRuleBuilder<T, TProp>.MergeChildErrors(const ChildResult: IValidationResult;
  const NamePrefix: string; Errors: TList<IValidationError>; var AllValid: Boolean);
var
  ChildError: IValidationError;
begin
  if (ChildResult = nil) or ChildResult.IsValid then
    Exit;

  AllValid := False;
  for ChildError in ChildResult.Errors do
    Errors.Add(TValidationError.Create(
      Format('%s.%s', [NamePrefix, ChildError.PropertyName]),
      ChildError.ErrorMessage, ChildError.Severity));
end;

function TRuleBuilder<T, TProp>.ValidateSingle(const TypedEntity: T; Entity: TObject;
  Errors: TList<IValidationError>): Boolean;
var
  Validator: IPropertyValidator;
  Runner: TFunc<TValue, IValidationResult>;
  PropValue: TProp;
  ValueAsTValue: TValue;
begin
  Result := True;

  PropValue := FGetter(TypedEntity);
  TValue.Make(@PropValue, TypeInfo(TProp), ValueAsTValue);

  for Validator in FValidators do
  begin
    if not ShouldRunValidator(Validator, Entity) then
      Continue;

    if not Validator.IsValid(ValueAsTValue) then
    begin
      Result := False;
      Errors.Add(TValidationError.Create(FPropertyName,
        Validator.GetErrorMessage(FPropertyName), Validator.GetSeverity));

      if FStopOnFirstFailure then
        Exit;
    end;
  end;

  // Validazione nidificata (SetValidator): gli errori figli vengono appiattiti
  // con prefisso sul nome della proprieta' padre (es. Sede.CAP).
  for Runner in FNestedValidators do
    MergeChildErrors(Runner(ValueAsTValue), FPropertyName, Errors, Result);
end;

function TRuleBuilder<T, TProp>.ValidateForEach(const TypedEntity: T; Entity: TObject;
  Errors: TList<IValidationError>): Boolean;
var
  Collection: TEnumerable<TProp>;
  Item: TProp;
  ItemValue: TValue;
  Validator: IPropertyValidator;
  Runner: TFunc<TValue, IValidationResult>;
  ElemName: string;
  Index: Integer;
begin
  Result := True;

  if not Assigned(FForEachGetter) then
    Exit;

  Collection := FForEachGetter(TypedEntity);
  if Collection = nil then
    Exit;

  Index := 0;
  for Item in Collection do
  begin
    TValue.Make(@Item, TypeInfo(TProp), ItemValue);
    ElemName := Format('%s[%d]', [FPropertyName, Index]);

    for Validator in FValidators do
    begin
      if not ShouldRunValidator(Validator, Entity) then
        Continue;

      if not Validator.IsValid(ItemValue) then
      begin
        Result := False;
        Errors.Add(TValidationError.Create(ElemName,
          Validator.GetErrorMessage(ElemName), Validator.GetSeverity));

        if FStopOnFirstFailure then
          Break;
      end;
    end;

    // SetValidator per elemento: errori figli prefissati con Prop[i].Sub
    for Runner in FNestedValidators do
      MergeChildErrors(Runner(ItemValue), ElemName, Errors, Result);

    Inc(Index);
  end;
end;

function TRuleBuilder<T, TProp>.GetPropertyName: string;
begin
  Result := FPropertyName;
end;

function TRuleBuilder<T, TProp>.ValidateTyped(Entity: T; out ErrorMessage: string): Boolean;
var
  Validator: IPropertyValidator;
  PropValue: TProp;
  ValueAsTValue: TValue;
  EntityAsObject: TObject;
begin
  // Percorso a messaggio singolo (IValidationRule.Validate); il motore usa
  // ValidateAll. In modalita' RuleForEach non e' applicabile.
  if FIsForEach then
  begin
    ErrorMessage := '';
    Exit(True);
  end;

  EntityAsObject := TValue.From<T>(Entity).AsObject;

  PropValue := FGetter(Entity);
  TValue.Make(@PropValue, TypeInfo(TProp), ValueAsTValue);

  for Validator in FValidators do
  begin
    if not ShouldRunValidator(Validator, EntityAsObject) then
      Continue;

    if not Validator.IsValid(ValueAsTValue) then
    begin
      ErrorMessage := Validator.GetErrorMessage(FPropertyName);
      Exit(False);
    end;
  end;

  Result := True;
  ErrorMessage := '';
end;

function TRuleBuilder<T, TProp>.StartsWithUpperCase: IRuleBuilderOptions<T, TProp>;
begin
  AddValidator(TStartsWithUpperCase.Create);
  Result := Self;
end;

function TRuleBuilder<T, TProp>.StartsWithUpperCaseWithMessage(const Message: string): IRuleBuilderOptions<T, TProp>;
var
  Validator: TStartsWithUpperCase;
begin
  Validator := TStartsWithUpperCase.Create(Message);
  AddValidator(Validator);
  Result := Self;
end;

function TRuleBuilder<T, TProp>.When(Condition: TFunc<T, Boolean>): IRuleBuilderOptions<T, TProp>;
begin
  FCurrentCondition := Condition;
  Result := Self;
end;

function TRuleBuilder<T, TProp>.Unless(Condition: TFunc<T, Boolean>): IRuleBuilderOptions<T, TProp>;
begin
  FCurrentCondition := function(Entity: T): Boolean
  begin
    Result := not Condition(Entity);
  end;
  Result := Self;
end;


function TRuleBuilder<T, TProp>.GetStopOnFirstFailure: Boolean;
begin
  Result := FStopOnFirstFailure;
end;

{-----------------------------------------------------------------------------
  Validatori di enumerazioni
-----------------------------------------------------------------------------}

function TRuleBuilder<T, TProp>.IsInEnum(EnumTypeInfo: PTypeInfo): IRuleBuilderOptions<T, TProp>;
begin
  AddValidator(TEnumVal.Create(EnumTypeInfo));
  Result := Self;
end;

function TRuleBuilder<T, TProp>.IsEnumName(EnumTypeInfo: PTypeInfo; CaseSensitive: Boolean): IRuleBuilderOptions<T, TProp>;
begin
  AddValidator(TEnumName.Create(EnumTypeInfo, CaseSensitive));
  Result := Self;
end;

{-----------------------------------------------------------------------------
  Validatori di collezioni
-----------------------------------------------------------------------------}

function TRuleBuilder<T, TProp>.NotEmptyCollection: IRuleBuilderOptions<T, TProp>;
begin
  AddValidator(TCollectionNotEmpty.Create);
  Result := Self;
end;

{-----------------------------------------------------------------------------
  Validatori di date
-----------------------------------------------------------------------------}

function TRuleBuilder<T, TProp>.MustBeInPast(IncludeToday: Boolean = False): IRuleBuilderOptions<T, TProp>;
begin
  AddValidator(TMustBeInPast.Create(IncludeToday));
  Result := Self;
end;

function TRuleBuilder<T, TProp>.MustBeInFuture(IncludeToday: Boolean = False): IRuleBuilderOptions<T, TProp>;
begin
  AddValidator(TMustBeInFuture.Create(IncludeToday));
  Result := Self;
end;

{ TValidator<T> }

constructor TValidator<T>.Create;
begin
  inherited Create;
  FGlobalStopOnFirstFailure := False;
end;

destructor TValidator<T>.Destroy;
begin
  inherited;
end;

function TValidator<T>.StopOnFirstFailure: TValidator<T>;
begin
  FGlobalStopOnFirstFailure := True;
  Result := Self;
end;

function TValidator<T>.Cascade(Mode: TCascadeMode): TValidator<T>;
begin
  FGlobalStopOnFirstFailure := (Mode = cmStop);
  Result := Self;
end;

function TValidator<T>.PreValidate(Entity: T; AResult: IValidationResult): Boolean;
begin
  Result := True;
end;

function TValidator<T>.Validate(Entity: T): IValidationResult;
begin
  Result := TValidationResult.Create;

  if not PreValidate(Entity, Result) then
    Exit;

  var lAllErrors := TList<IValidationError>.Create;
  try
    var lEntityValue := TValue.From<T>(Entity);

    for var lRule in FRules do
    begin
      // Eseguo la validazione per questa regola
      lRule.ValidateAll(lEntityValue.AsObject, lAllErrors);

      if FGlobalStopOnFirstFailure and (lAllErrors.Count > 0) then
        Break; // Esco dal loop delle regole
    end;

    for var lError in lAllErrors do
      Result.AddError(lError.GetPropertyName, lError.GetErrorMessage, lError.GetSeverity);
  finally
    lAllErrors.Free;
  end;
end;

{ TValidationError }

constructor TValidationError.Create(const PropertyName, ErrorMessage: string;
  Severity: TValidationSeverity);
begin
  inherited Create;
  FPropertyName := PropertyName;
  FErrorMessage := ErrorMessage;
  FSeverity := Severity;
end;

function TValidationError.GetPropertyName: string;
begin
  Result := FPropertyName;
end;

function TValidationError.GetErrorMessage: string;
begin
  Result := FErrorMessage;
end;

function TValidationError.GetSeverity: TValidationSeverity;
begin
  Result := FSeverity;
end;

{ TValidationResult }

constructor TValidationResult.Create;
begin
  inherited Create;
  FErrors := TList<IValidationError>.Create;
end;

destructor TValidationResult.Destroy;
begin
  FErrors.Free;
  inherited;
end;

function TValidationResult.GetIsValid: Boolean;
begin
  Result := FErrors.Count = 0;
end;

function TValidationResult.GetErrors: TArray<IValidationError>;
begin
  Result := FErrors.ToArray;
end;

procedure TValidationResult.AddError(const PropertyName, ErrorMessage: string);
begin
  FErrors.Add(TValidationError.Create(PropertyName, ErrorMessage));
end;

procedure TValidationResult.AddError(const PropertyName, ErrorMessage: string;
  Severity: TValidationSeverity);
begin
  FErrors.Add(TValidationError.Create(PropertyName, ErrorMessage, Severity));
end;

{ TAbstractValidator<T> }

constructor TAbstractValidator<T>.Create;
begin
  inherited Create;
  FRules := TList<IValidationRule>.Create;
end;

destructor TAbstractValidator<T>.Destroy;
begin
  FRules.Free;
  inherited;
end;

function TAbstractValidator<T>.AddRule<TProp>(Rule: IRuleBuilderOptions<T, TProp>): IRuleBuilderOptions<T, TProp>;
begin
  FRules.Add(Rule as IValidationRule);
  Result := Rule;
end;

function TAbstractValidator<T>.RuleFor<TProp>(const PropertyName: string; Getter: TFunc<T, TProp>): IRuleBuilderOptions<T, TProp>;
var
  Rule: TRuleBuilder<T, TProp>;
  EntityType: TClass;
begin
  EntityType := nil;

  {$IFDEF AUTOREFCOUNT}
  if PTypeInfo(TypeInfo(T)).Kind = tkClass then
    EntityType := GetTypeData(TypeInfo(T))^.ClassType;
  {$ELSE}
  if PTypeInfo(TypeInfo(T))^.Kind = tkClass then
    EntityType := GetTypeData(TypeInfo(T))^.ClassType;
  {$ENDIF}

  if EntityType = nil then
    EntityType := TObject;

  Rule := TRuleBuilder<T, TProp>.Create(EntityType, PropertyName, Getter);
  Result := AddRule<TProp>(Rule);
end;

function TAbstractValidator<T>.MakeRttiGetter<TProp>(const PropertyName: string): TFunc<T, TProp>;
var
  RType: TRttiType;
  Prop: TRttiProperty;
  Fld: TRttiField;
  Reader: TFunc<TObject, TValue>;
begin
  RType := FRttiCtx.GetType(TypeInfo(T));
  if RType = nil then
    raise Exception.CreateFmt(
      'RuleFor RTTI: no RTTI available for type "%s"', [string(PTypeInfo(TypeInfo(T)).Name)]);

  // Prima cerca una proprieta', poi (per i modelli a soli campi come TPersona)
  // un campo. Entrambi devono avere RTTI (public/published lo hanno di default).
  Prop := RType.GetProperty(PropertyName);
  if Prop <> nil then
    Reader :=
      function(Obj: TObject): TValue
      begin
        Result := Prop.GetValue(Obj);
      end
  else
  begin
    Fld := RType.GetField(PropertyName);
    if Fld = nil then
      raise Exception.CreateFmt(
        'RuleFor RTTI: property/field "%s" not found on type "%s" ' +
        '(the member needs RTTI)', [PropertyName, string(RType.Name)]);
    Reader :=
      function(Obj: TObject): TValue
      begin
        Result := Fld.GetValue(Obj);
      end;
  end;

  Result :=
    function(Entity: T): TProp
    var
      Obj: TObject;
      V: TValue;
      MemberTypeName: string;
    begin
      Obj := TValue.From<T>(Entity).AsObject;
      if Obj = nil then
        Exit(Default(TProp));
      V := Reader(Obj);
      // Errore di tipo esplicito e leggibile, invece di un EInvalidCast opaco.
      if not V.TryAsType<TProp>(Result) then
      begin
        if V.TypeInfo <> nil then
          MemberTypeName := string(V.TypeInfo.Name)
        else
          MemberTypeName := '<unknown>';
        raise Exception.CreateFmt(
          'RuleFor RTTI: member "%s" is of type %s, which does not match the ' +
          'type declared in the rule', [PropertyName, MemberTypeName]);
      end;
    end;
end;

function TAbstractValidator<T>.RuleFor<TProp>(const PropertyName: string): IRuleBuilderOptions<T, TProp>;
begin
  Result := RuleFor<TProp>(PropertyName, MakeRttiGetter<TProp>(PropertyName));
end;

function TAbstractValidator<T>.RuleForEach<TItem>(const PropertyName: string;
  Getter: TFunc<T, TEnumerable<TItem>>): IRuleBuilderOptions<T, TItem>;
var
  Rule: TRuleBuilder<T, TItem>;
  EntityType: TClass;
begin
  EntityType := nil;

  {$IFDEF AUTOREFCOUNT}
  if PTypeInfo(TypeInfo(T)).Kind = tkClass then
    EntityType := GetTypeData(TypeInfo(T))^.ClassType;
  {$ELSE}
  if PTypeInfo(TypeInfo(T))^.Kind = tkClass then
    EntityType := GetTypeData(TypeInfo(T))^.ClassType;
  {$ENDIF}

  if EntityType = nil then
    EntityType := TObject;

  Rule := TRuleBuilder<T, TItem>.CreateForEach(EntityType, PropertyName, Getter);
  Result := AddRule<TItem>(Rule);
end;

function TAbstractValidator<T>.RuleForObject(const PropertyName: string): IRuleBuilderOptions<T, T>;
begin
  Result := RuleFor<T>(PropertyName,
    function(Entity: T): T
    begin
      Result := Entity;
    end);
end;

end.
