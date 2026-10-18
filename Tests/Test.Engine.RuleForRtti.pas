{-----------------------------------------------------------------------------
 Project: FluentValidator - Test Suite
 Unit Name: Test.Engine.RuleForRtti
 Purpose: Verifica dell'overload RTTI-based di RuleFor (forma RACCOMANDATA):
          RuleFor<TProp>('NomeProprieta') legge il valore via RTTI, senza dover
          passare il getter-lambda. Avvicina l'ergonomia a quella di .NET
          (RuleFor(x => x.Nome)) eliminando la duplicazione nome+getter.
          Copre anche i due modi di fallimento: nome errato (alla definizione)
          e tipo incompatibile (alla validazione, con messaggio esplicito).
-----------------------------------------------------------------------------}

unit Test.Engine.RuleForRtti;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  FluentValidator.Validators,
  FluentValidator,
  FluentValidator.Intf,
  Test.Fixtures;

type
  [TestFixture]
  TTestRuleForRtti = class
  public
    [Test] procedure LeggeCampoStringa_ValidaNotEmpty;
    [Test] procedure ValoreValido_Passa;
    [Test] procedure LeggeCampoCurrency_PrecisionScale;
    [Test] procedure PiuRegoleRtti_SuProprietaDiverse;
    [Test] procedure NomeInesistente_SollevaEccezioneAllaDefinizione;
    [Test] procedure TipoIncompatibile_SollevaEccezioneChiaraAllaValidazione;
    [Test] procedure EquivaleAlGetterEsplicito;
  end;

implementation

procedure TTestRuleForRtti.LeggeCampoStringa_ValidaNotEmpty;
var V: TValidator<TPersona>; P: TPersona; Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    // Niente getter-lambda: il valore di 'Nome' e' letto via RTTI.
    V.RuleFor<string>('Nome').NotEmpty;
    P := TPersona.Create;
    try
      P.Nome := '';
      Esito := V.Validate(P);
      Assert.IsFalse(Esito.IsValid);
      Assert.AreEqual('Nome', Esito.Errors[0].PropertyName);
    finally P.Free; end;
  finally V.Free; end;
end;

procedure TTestRuleForRtti.ValoreValido_Passa;
var V: TValidator<TPersona>; P: TPersona; Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<string>('Nome').NotEmpty;
    P := TPersona.Create;
    try
      P.Nome := 'Muzio';
      Esito := V.Validate(P);
      Assert.IsTrue(Esito.IsValid);
    finally P.Free; end;
  finally V.Free; end;
end;

procedure TTestRuleForRtti.LeggeCampoCurrency_PrecisionScale;
var V: TValidator<TPersona>; P: TPersona; Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<Currency>('Importo').PrecisionScale(10, 2);
    P := TPersona.Create;
    try
      P.Importo := 12.345; // troppi decimali
      Esito := V.Validate(P);
      Assert.IsFalse(Esito.IsValid);
      Assert.AreEqual('Importo', Esito.Errors[0].PropertyName);
    finally P.Free; end;
  finally V.Free; end;
end;

procedure TTestRuleForRtti.PiuRegoleRtti_SuProprietaDiverse;
var V: TValidator<TPersona>; P: TPersona; Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<string>('Nome').NotEmpty;
    V.RuleFor<Integer>('Eta').GreaterThan(0);
    P := TPersona.Create;
    try
      P.Nome := '';
      P.Eta := -3;
      Esito := V.Validate(P);
      Assert.IsFalse(Esito.IsValid);
      Assert.AreEqual(2, Integer(Length(Esito.Errors)));
    finally P.Free; end;
  finally V.Free; end;
end;

procedure TTestRuleForRtti.NomeInesistente_SollevaEccezioneAllaDefinizione;
var V: TValidator<TPersona>;
begin
  // La risoluzione RTTI avviene al momento della definizione della regola:
  // un nome inesistente fallisce subito, in modo esplicito, non a runtime.
  V := TValidator<TPersona>.Create;
  try
    Assert.WillRaise(
      procedure begin V.RuleFor<string>('CampoCheNonEsiste').NotEmpty; end,
      Exception);
  finally V.Free; end;
end;

procedure TTestRuleForRtti.TipoIncompatibile_SollevaEccezioneChiaraAllaValidazione;
var V: TValidator<TPersona>; P: TPersona;
begin
  // 'Nome' e' una stringa: dichiararlo come <Integer> e' un errore d'uso.
  // La definizione della regola riesce (il nome esiste), ma alla prima
  // validazione si ottiene un'eccezione esplicita, non un cast opaco.
  V := TValidator<TPersona>.Create;
  P := TPersona.Create;
  try
    V.RuleFor<Integer>('Nome').GreaterThan(0);
    P.Nome := 'Muzio';
    Assert.WillRaise(
      procedure begin V.Validate(P); end,
      Exception);
  finally
    P.Free; V.Free;
  end;
end;

procedure TTestRuleForRtti.EquivaleAlGetterEsplicito;
var
  VRtti, VExpl: TValidator<TPersona>;
  P: TPersona;
  EsitoRtti, EsitoExpl: IValidationResult;
begin
  P := TPersona.Create;
  VRtti := TValidator<TPersona>.Create;
  VExpl := TValidator<TPersona>.Create;
  try
    VRtti.RuleFor<string>('Nome').NotEmpty.Length(2, 50);
    VExpl.RuleFor<string>('Nome',
      function(Per: TPersona): string begin Result := Per.Nome; end)
      .NotEmpty.Length(2, 50);

    P.Nome := 'X'; // viola Length(2,50), passa NotEmpty
    EsitoRtti := VRtti.Validate(P);
    EsitoExpl := VExpl.Validate(P);

    Assert.AreEqual(EsitoExpl.IsValid, EsitoRtti.IsValid);
    Assert.AreEqual(Length(EsitoExpl.Errors), Length(EsitoRtti.Errors));
    Assert.AreEqual(EsitoExpl.Errors[0].PropertyName, EsitoRtti.Errors[0].PropertyName);
  finally
    VExpl.Free; VRtti.Free; P.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRuleForRtti);

end.
