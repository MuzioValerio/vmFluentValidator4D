{-----------------------------------------------------------------------------
 Project: FluentValidator - Test Suite
 Unit Name: Test.Validators.PredicateAndIntegration
 Purpose:
 - Test su TCustomPredicateValidator (white-box) e su .Must (integrazione),
   perche' la logica di "wrapping" da TPredicate<TProp> a TPredicate<TValue>
   (gestione di Value.IsEmpty -> Default(TProp)) vive in TRuleBuilder.Must,
   dentro FluentValidator.pas, non nel validatore stesso.
 - Test di integrazione per .IsInEnum e .NotEmptyCollection passati tramite
   RuleFor<TProp>, per verificare che il PTypeInfo dell'enum e il valore della
   collezione arrivino correttamente al validatore sottostante attraverso
   tutta la catena RuleFor -> TValue.Make -> IsValid.
-----------------------------------------------------------------------------}

unit Test.Validators.PredicateAndIntegration;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils, System.Rtti, System.TypInfo, System.Generics.Collections,
  FluentValidator.Validators,
  FluentValidator.CustomPredicateValidator,
  FluentValidator.EnumValidator,
  FluentValidator.CollectionNotEmptyValidator,
  FluentValidator,
  FluentValidator.Intf,
  Test.Fixtures;

type
  [TestFixture]
  TTestCustomPredicateValidator = class
  public
    [Test]
    procedure PredicatoVero_EValido;
    [Test]
    procedure PredicatoFalso_NonEValido;
    [Test]
    procedure MessaggioPersonalizzato_VieneUsatoComeDefault;
  end;

  [TestFixture]
  TTestMustIntegrazione = class
  public
    [Test]
    procedure Must_ConPredicatoSuInteroSoddisfatto_EValido;
    [Test]
    procedure Must_ConPredicatoSuInteroNonSoddisfatto_NonEValido;
    [Test]
    procedure Must_ConPredicatoSuStringa_RiceveIlValoreEffettivoDellaProprieta;
    [Test]
    // Una proprieta' oggetto nidificata e nil deve poter attraversare .Must
    // senza eccezioni: il predicato deve ricevere correttamente nil (non
    // importa se attraverso Default(TProp) o tramite Value.AsType<TProp>;
    // quel che conta e' che non venga sollevata un'eccezione RTTI).
    procedure Must_SuProprietaOggettoNil_NonSollevaEccezioniERicevDefaultTProp;
  end;

  [TestFixture]
  TTestIsInEnumIntegrazione = class
  public
    [Test]
    procedure IsInEnum_ValoreValido_EValido;
    // Il caso "valore fuori range" e' gia' coperto a livello white-box in
    // Test.Validators.EnumTests (TTestEnumValidator.InteroFuoriRange_NonEValido):
    // qui basta verificare che il valore valido attraversi correttamente
    // tutta la catena RuleFor -> TValue.Make -> IsValid.
  end;

  [TestFixture]
  TTestNotEmptyCollectionIntegrazione = class
  public
    [Test]
    procedure NotEmptyCollection_ListaNonVuota_EValido;
    [Test]
    procedure NotEmptyCollection_ListaVuota_NonEValido;
  end;

implementation

{ TTestCustomPredicateValidator }

procedure TTestCustomPredicateValidator.PredicatoVero_EValido;
var
  Validatore: TCustomPredicateValidator;
begin
  Validatore := TCustomPredicateValidator.Create(
    function(Value: TValue): Boolean begin Result := True; end,
    'errore');
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<Integer>(1)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestCustomPredicateValidator.PredicatoFalso_NonEValido;
var
  Validatore: TCustomPredicateValidator;
begin
  Validatore := TCustomPredicateValidator.Create(
    function(Value: TValue): Boolean begin Result := False; end,
    'errore');
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<Integer>(1)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestCustomPredicateValidator.MessaggioPersonalizzato_VieneUsatoComeDefault;
var
  Validatore: TCustomPredicateValidator;
begin
  Validatore := TCustomPredicateValidator.Create(
    function(Value: TValue): Boolean begin Result := False; end,
    'Valore non accettabile');
  try
    Assert.AreEqual('Valore non accettabile', Validatore.GetErrorMessage('Campo'));
  finally
    Validatore.Free;
  end;
end;

{ TTestMustIntegrazione }

procedure TTestMustIntegrazione.Must_ConPredicatoSuInteroSoddisfatto_EValido;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<Integer>('Eta',
      function(Persona: TPersona): Integer begin Result := Persona.Eta; end)
      .Must(
        function(Eta: Integer): Boolean begin Result := Eta mod 2 = 0; end,
        'L''eta'' deve essere un numero pari');

    P := TPersona.Create;
    try
      P.Eta := 30;
      Esito := V.Validate(P);
      Assert.IsTrue(Esito.IsValid);
    finally
      P.Free;
    end;
  finally
    V.Free;
  end;
end;

procedure TTestMustIntegrazione.Must_ConPredicatoSuInteroNonSoddisfatto_NonEValido;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<Integer>('Eta',
      function(Persona: TPersona): Integer begin Result := Persona.Eta; end)
      .Must(
        function(Eta: Integer): Boolean begin Result := Eta mod 2 = 0; end,
        'L''eta'' deve essere un numero pari');

    P := TPersona.Create;
    try
      P.Eta := 31;
      Esito := V.Validate(P);
      Assert.IsFalse(Esito.IsValid);
      Assert.AreEqual('L''eta'' deve essere un numero pari', Esito.Errors[0].ErrorMessage);
    finally
      P.Free;
    end;
  finally
    V.Free;
  end;
end;

procedure TTestMustIntegrazione.Must_ConPredicatoSuStringa_RiceveIlValoreEffettivoDellaProprieta;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
  ValoreRicevutoDalPredicato: string;
begin
  ValoreRicevutoDalPredicato := '';
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<string>('Nome',
      function(Persona: TPersona): string begin Result := Persona.Nome; end)
      .Must(
        function(Nome: string): Boolean
        begin
          ValoreRicevutoDalPredicato := Nome;
          Result := Nome.Contains('a');
        end,
        'Il nome deve contenere la lettera a');

    P := TPersona.Create;
    try
      P.Nome := 'Marco';
      Esito := V.Validate(P);
      Assert.AreEqual('Marco', ValoreRicevutoDalPredicato);
      Assert.IsTrue(Esito.IsValid);
    finally
      P.Free;
    end;
  finally
    V.Free;
  end;
end;

procedure TTestMustIntegrazione.Must_SuProprietaOggettoNil_NonSollevaEccezioniERicevDefaultTProp;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
  PredicatoEStatoChiamato: Boolean;
begin
  PredicatoEStatoChiamato := False;
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<TIndirizzo>('Indirizzo',
      function(Persona: TPersona): TIndirizzo begin Result := Persona.Indirizzo; end)
      .Must(
        function(Indirizzo: TIndirizzo): Boolean
        begin
          PredicatoEStatoChiamato := True;
          Result := Indirizzo = nil;   // deve arrivare nil, qualunque sia il percorso interno
        end,
        'errore');

    P := TPersona.Create;  // Indirizzo non assegnato (nil) di proposito
    try
      Esito := V.Validate(P);
      Assert.IsTrue(PredicatoEStatoChiamato);
      Assert.IsTrue(Esito.IsValid);
    finally
      P.Free;
    end;
  finally
    V.Free;
  end;
end;

{ TTestIsInEnumIntegrazione }

procedure TTestIsInEnumIntegrazione.IsInEnum_ValoreValido_EValido;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<TStatoOrdine>('Stato',
      function(Persona: TPersona): TStatoOrdine begin Result := Persona.Stato; end)
      .IsInEnum(TypeInfo(TStatoOrdine));

    P := TPersona.Create;
    try
      P.Stato := soConfermato;
      Esito := V.Validate(P);
      Assert.IsTrue(Esito.IsValid);
    finally
      P.Free;
    end;
  finally
    V.Free;
  end;
end;

{ TTestNotEmptyCollectionIntegrazione }

procedure TTestNotEmptyCollectionIntegrazione.NotEmptyCollection_ListaNonVuota_EValido;
var
  V: TValidator<TPersona>;
  P, Amico: TPersona;
  Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<TObjectList<TPersona>>('Amici',
      function(Persona: TPersona): TObjectList<TPersona> begin Result := Persona.Amici; end)
      .NotEmptyCollection;

    P := TPersona.Create;
    Amico := TPersona.Create;
    try
      P.Amici.Add(Amico);
      Esito := V.Validate(P);
      Assert.IsTrue(Esito.IsValid);
    finally
      P.Free;
      Amico.Free;
    end;
  finally
    V.Free;
  end;
end;

procedure TTestNotEmptyCollectionIntegrazione.NotEmptyCollection_ListaVuota_NonEValido;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<TObjectList<TPersona>>('Amici',
      function(Persona: TPersona): TObjectList<TPersona> begin Result := Persona.Amici; end)
      .NotEmptyCollection;

    P := TPersona.Create;
    try
      Esito := V.Validate(P);
      Assert.IsFalse(Esito.IsValid);
    finally
      P.Free;
    end;
  finally
    V.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCustomPredicateValidator);
  TDUnitX.RegisterTestFixture(TTestMustIntegrazione);
  TDUnitX.RegisterTestFixture(TTestIsInEnumIntegrazione);
  TDUnitX.RegisterTestFixture(TTestNotEmptyCollectionIntegrazione);

end.
