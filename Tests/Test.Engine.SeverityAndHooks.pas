{-----------------------------------------------------------------------------
 Project: FluentValidator - Test Suite
 Unit Name: Test.Engine.SeverityAndHooks
 Purpose: Test della gravita' degli errori e degli hook del motore:
          - WithSeverity (svError / svWarning), inclusa la propagazione dalla
            validazione nidificata e dalle regole condizionali When/Unless.
          - PreValidate: hook virtuale che consente di gestire un'entity nil
            senza eccezioni RTTI.
          - RuleForObject: regola sull'intero oggetto per coerenze cross-campo.
-----------------------------------------------------------------------------}

unit Test.Engine.SeverityAndHooks;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  FluentValidator.Validators,
  FluentValidator,
  FluentValidator.Intf,
  Test.Fixtures;

type
  // Sottoclasse che sfrutta PreValidate per bloccare un'entity nil con un
  // messaggio chiaro invece di far esplodere il getter su un riferimento nil.
  TPersonaValidatorConPreValidate = class(TValidator<TPersona>)
  protected
    function PreValidate(Entity: TPersona; AResult: IValidationResult): Boolean; override;
  end;

  [TestFixture]
  TTestWithSeverity = class
  public
    [Test] procedure Default_EsvError;
    [Test] procedure WithSeverityWarning_ImpostaLaGravita;
    [Test] procedure Warning_RendeComunqueIlRisultatoNonValido;
    [Test] procedure WithSeverity_SuRegolaCondizionale_Propaga;
  end;

  [TestFixture]
  TTestPreValidate = class
  public
    [Test] procedure EntityNil_BloccataConMessaggio_SenzaEccezioni;
    [Test] procedure EntityValida_ProsegueNormalmente;
  end;

  [TestFixture]
  TTestRuleForObject = class
  public
    [Test] procedure CoerenzaCrossCampo_Soddisfatta_EValido;
    [Test] procedure CoerenzaCrossCampo_Violata_NonEValido;
  end;

implementation

{ TPersonaValidatorConPreValidate }

function TPersonaValidatorConPreValidate.PreValidate(Entity: TPersona;
  AResult: IValidationResult): Boolean;
begin
  if Entity = nil then
  begin
    AResult.AddError('Persona', 'La persona non puo'' essere nil');
    Exit(False);
  end;
  Result := True;
end;

{ TTestWithSeverity }

procedure TTestWithSeverity.Default_EsvError;
var V: TValidator<TPersona>; P: TPersona; Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<string>('Nome',
      function(Per: TPersona): string begin Result := Per.Nome; end).NotEmpty;
    P := TPersona.Create;
    try
      P.Nome := '';
      Esito := V.Validate(P);
      Assert.AreEqual(Ord(svError), Ord(Esito.Errors[0].Severity));
    finally P.Free; end;
  finally V.Free; end;
end;

procedure TTestWithSeverity.WithSeverityWarning_ImpostaLaGravita;
var V: TValidator<TPersona>; P: TPersona; Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<string>('Nome',
      function(Per: TPersona): string begin Result := Per.Nome; end)
      .NotEmpty
      .WithSeverity(svWarning);
    P := TPersona.Create;
    try
      P.Nome := '';
      Esito := V.Validate(P);
      Assert.AreEqual(Ord(svWarning), Ord(Esito.Errors[0].Severity));
    finally P.Free; end;
  finally V.Free; end;
end;

procedure TTestWithSeverity.Warning_RendeComunqueIlRisultatoNonValido;
var V: TValidator<TPersona>; P: TPersona; Esito: IValidationResult;
begin
  // Come in .NET: un warning e' comunque una violazione, IsValid = False.
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<string>('Nome',
      function(Per: TPersona): string begin Result := Per.Nome; end)
      .NotEmpty
      .WithSeverity(svWarning);
    P := TPersona.Create;
    try
      P.Nome := '';
      Esito := V.Validate(P);
      Assert.IsFalse(Esito.IsValid);
    finally P.Free; end;
  finally V.Free; end;
end;

procedure TTestWithSeverity.WithSeverity_SuRegolaCondizionale_Propaga;
var V: TValidator<TPersona>; P: TPersona; Esito: IValidationResult;
begin
  // .When aggiunge un wrapper: la gravita' deve comunque arrivare all'errore.
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<string>('Nome',
      function(Per: TPersona): string begin Result := Per.Nome; end)
      .When(function(Per: TPersona): Boolean begin Result := True; end)
      .NotEmpty
      .WithSeverity(svWarning);
    P := TPersona.Create;
    try
      P.Nome := '';
      Esito := V.Validate(P);
      Assert.IsFalse(Esito.IsValid);
      Assert.AreEqual(Ord(svWarning), Ord(Esito.Errors[0].Severity));
    finally P.Free; end;
  finally V.Free; end;
end;

{ TTestPreValidate }

procedure TTestPreValidate.EntityNil_BloccataConMessaggio_SenzaEccezioni;
var V: TPersonaValidatorConPreValidate; Esito: IValidationResult;
begin
  V := TPersonaValidatorConPreValidate.Create;
  try
    V.RuleFor<string>('Nome',
      function(Per: TPersona): string begin Result := Per.Nome; end).NotEmpty;
    Esito := V.Validate(nil);
    Assert.IsFalse(Esito.IsValid);
    Assert.AreEqual(1, Integer(Length(Esito.Errors)));
    Assert.AreEqual('Persona', Esito.Errors[0].PropertyName);
  finally V.Free; end;
end;

procedure TTestPreValidate.EntityValida_ProsegueNormalmente;
var V: TPersonaValidatorConPreValidate; P: TPersona; Esito: IValidationResult;
begin
  V := TPersonaValidatorConPreValidate.Create;
  try
    V.RuleFor<string>('Nome',
      function(Per: TPersona): string begin Result := Per.Nome; end).NotEmpty;
    P := TPersona.Create;
    try
      P.Nome := 'Muzio';
      Esito := V.Validate(P);
      Assert.IsTrue(Esito.IsValid);
    finally P.Free; end;
  finally V.Free; end;
end;

{ TTestRuleForObject }

procedure TTestRuleForObject.CoerenzaCrossCampo_Soddisfatta_EValido;
var V: TValidator<TPersona>; P: TPersona; Esito: IValidationResult;
begin
  // Regola cross-campo: Importo deve essere coerente con Percentuale
  // (qui: Importo = Percentuale * 10), verificabile solo sull'intero oggetto.
  V := TValidator<TPersona>.Create;
  try
    V.RuleForObject('Persona')
      .Must(
        function(Per: TPersona): Boolean
        begin
          Result := Per.Importo = Per.Percentuale * 10;
        end,
        'Importo non coerente con Percentuale');
    P := TPersona.Create;
    try
      P.Percentuale := 5;
      P.Importo := 50;
      Esito := V.Validate(P);
      Assert.IsTrue(Esito.IsValid);
    finally P.Free; end;
  finally V.Free; end;
end;

procedure TTestRuleForObject.CoerenzaCrossCampo_Violata_NonEValido;
var V: TValidator<TPersona>; P: TPersona; Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleForObject('Persona')
      .Must(
        function(Per: TPersona): Boolean
        begin
          Result := Per.Importo = Per.Percentuale * 10;
        end,
        'Importo non coerente con Percentuale');
    P := TPersona.Create;
    try
      P.Percentuale := 5;
      P.Importo := 999;
      Esito := V.Validate(P);
      Assert.IsFalse(Esito.IsValid);
      Assert.AreEqual('Persona', Esito.Errors[0].PropertyName);
    finally P.Free; end;
  finally V.Free; end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWithSeverity);
  TDUnitX.RegisterTestFixture(TTestPreValidate);
  TDUnitX.RegisterTestFixture(TTestRuleForObject);

end.
