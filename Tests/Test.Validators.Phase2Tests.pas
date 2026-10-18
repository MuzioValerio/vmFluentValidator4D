{-----------------------------------------------------------------------------
 Project: FluentValidator - Test Suite
 Unit Name: Test.Validators.Phase2Tests
 Purpose: Test dei validatori aggiunti nella seconda fase del porting:
          - TNullValidator (.Null)      opposto di NotNull
          - TEmptyValidator (.Empty)    opposto di NotEmpty
          - TPrecisionScaleValidator (.PrecisionScale)  cifre/decimali importi
          - TEnumNameValidator (.IsEnumName)  nome enum, case sensitive/insensitive
          Test white-box diretti sulle classi + alcuni test di integrazione via
          RuleFor/TValidator<T>, nello stile del resto della suite.
-----------------------------------------------------------------------------}

unit Test.Validators.Phase2Tests;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils, System.Rtti, System.TypInfo,
  FluentValidator.Validators,
  FluentValidator.NullValidator,
  FluentValidator.EmptyValidator,
  FluentValidator.PrecisionScaleValidator,
  FluentValidator.EnumNameValidator,
  FluentValidator.CreditCardValidator,
  FluentValidator,
  FluentValidator.Intf,
  Test.Fixtures;

type
  [TestFixture]
  TTestNullValidator = class
  public
    [Test] procedure TValueVuoto_EValido;
    [Test] procedure OggettoNil_EValido;
    [Test] procedure OggettoAssegnato_NonEValido;
    [Test] procedure StringaVuota_NonEValida;
    [Test] procedure StringaConTesto_NonEValida;
  end;

  [TestFixture]
  TTestEmptyValidator = class
  public
    [Test] procedure StringaVuota_EValida;
    [Test] procedure StringaDiSoliSpazi_EValida;
    [Test] procedure StringaConTesto_NonEValida;
    [Test] procedure InteroAZero_EValido;
    [Test] procedure InteroDiversoDaZero_NonEValido;
    [Test] procedure CurrencyAZero_EValida;
    [Test] procedure OggettoNil_EValido;
    [Test] procedure OggettoAssegnato_NonEValido;
  end;

  [TestFixture]
  TTestPrecisionScaleValidator = class
  public
    [Test] procedure NelLimite_EValido;
    [Test] procedure DecimaliInEccesso_NonEValido;
    [Test] procedure CifreIntereInEccesso_NonEValido;
    [Test] procedure ValoreMinoreDiUno_ContaZeroCifreIntere_EValido;
    [Test] procedure InteroPuro_EValido;
    [Test] procedure ValoreNegativo_TrattatoInModulo_EValido;
    [Test] procedure ZeriDecimaliFinaliIgnorati_EValido;
    [Test] procedure ValoreNonNumerico_NonEValido;
    [Test] procedure ParametriIncoerenti_SollevanoEccezione;
  end;

  [TestFixture]
  TTestEnumNameValidator = class
  public
    [Test] procedure NomeEsatto_EValido;
    [Test] procedure NomeAltroCaseInsensitive_EValido;
    [Test] procedure NomeAltroCaseSensitive_NonEValido;
    [Test] procedure NomeEsattoCaseSensitive_EValido;
    [Test] procedure NomeInesistente_NonEValido;
    [Test] procedure ValoreNonStringa_NonEValido;
  end;

  [TestFixture]
  TTestCreditCardValidator = class
  public
    [Test] procedure NumeroValido_EValido;
    [Test] procedure NumeroValidoConSpaziETrattini_EValido;
    [Test] procedure NumeroNonValido_NonEValido;
    [Test] procedure ContieneCaratteriNonNumerici_NonEValido;
    [Test] procedure StringaVuota_EValida;
    [Test] procedure ValoreNonStringa_NonEValido;
  end;

  [TestFixture]
  TTestPhase2Integrazione = class
  public
    [Test] procedure PrecisionScale_SuCurrencyValida_ViaRuleFor;
    [Test] procedure PrecisionScale_SuCurrencyConTroppiDecimali_ViaRuleFor;
    [Test] procedure Empty_SuStringaObbligatoriamenteVuota_ViaRuleFor;
  end;

implementation

{ TTestNullValidator }

procedure TTestNullValidator.TValueVuoto_EValido;
var V: TNullValidator;
begin
  V := TNullValidator.Create;
  try
    Assert.IsTrue(V.IsValid(TValue.Empty));
  finally V.Free; end;
end;

procedure TTestNullValidator.OggettoNil_EValido;
var V: TNullValidator; O: TIndirizzo;
begin
  V := TNullValidator.Create;
  try
    O := nil;
    Assert.IsTrue(V.IsValid(TValue.From<TIndirizzo>(O)));
  finally V.Free; end;
end;

procedure TTestNullValidator.OggettoAssegnato_NonEValido;
var V: TNullValidator; O: TIndirizzo;
begin
  V := TNullValidator.Create;
  O := TIndirizzo.Create;
  try
    Assert.IsFalse(V.IsValid(TValue.From<TIndirizzo>(O)));
  finally O.Free; V.Free; end;
end;

procedure TTestNullValidator.StringaVuota_NonEValida;
var V: TNullValidator;
begin
  V := TNullValidator.Create;
  try
    // '' non e' "nullo" (coerente con NotNull che la considera valida)
    Assert.IsFalse(V.IsValid(TValue.From<string>('')));
  finally V.Free; end;
end;

procedure TTestNullValidator.StringaConTesto_NonEValida;
var V: TNullValidator;
begin
  V := TNullValidator.Create;
  try
    Assert.IsFalse(V.IsValid(TValue.From<string>('Muzio')));
  finally V.Free; end;
end;

{ TTestEmptyValidator }

procedure TTestEmptyValidator.StringaVuota_EValida;
var V: TEmptyValidator;
begin
  V := TEmptyValidator.Create;
  try Assert.IsTrue(V.IsValid(TValue.From<string>(''))); finally V.Free; end;
end;

procedure TTestEmptyValidator.StringaDiSoliSpazi_EValida;
var V: TEmptyValidator;
begin
  V := TEmptyValidator.Create;
  try Assert.IsTrue(V.IsValid(TValue.From<string>('   '))); finally V.Free; end;
end;

procedure TTestEmptyValidator.StringaConTesto_NonEValida;
var V: TEmptyValidator;
begin
  V := TEmptyValidator.Create;
  try Assert.IsFalse(V.IsValid(TValue.From<string>('x'))); finally V.Free; end;
end;

procedure TTestEmptyValidator.InteroAZero_EValido;
var V: TEmptyValidator;
begin
  V := TEmptyValidator.Create;
  try Assert.IsTrue(V.IsValid(TValue.From<Integer>(0))); finally V.Free; end;
end;

procedure TTestEmptyValidator.InteroDiversoDaZero_NonEValido;
var V: TEmptyValidator;
begin
  V := TEmptyValidator.Create;
  try Assert.IsFalse(V.IsValid(TValue.From<Integer>(5))); finally V.Free; end;
end;

procedure TTestEmptyValidator.CurrencyAZero_EValida;
var V: TEmptyValidator;
begin
  V := TEmptyValidator.Create;
  try Assert.IsTrue(V.IsValid(TValue.From<Currency>(0))); finally V.Free; end;
end;

procedure TTestEmptyValidator.OggettoNil_EValido;
var V: TEmptyValidator; O: TIndirizzo;
begin
  V := TEmptyValidator.Create;
  try
    O := nil;
    Assert.IsTrue(V.IsValid(TValue.From<TIndirizzo>(O)));
  finally V.Free; end;
end;

procedure TTestEmptyValidator.OggettoAssegnato_NonEValido;
var V: TEmptyValidator; O: TIndirizzo;
begin
  V := TEmptyValidator.Create;
  O := TIndirizzo.Create;
  try Assert.IsFalse(V.IsValid(TValue.From<TIndirizzo>(O)));
  finally O.Free; V.Free; end;
end;

{ TTestPrecisionScaleValidator }

procedure TTestPrecisionScaleValidator.NelLimite_EValido;
var V: TPrecisionScaleValidator;
begin
  V := TPrecisionScaleValidator.Create(5, 2); // max 3 intere + 2 decimali
  try Assert.IsTrue(V.IsValid(TValue.From<Currency>(123.45))); finally V.Free; end;
end;

procedure TTestPrecisionScaleValidator.DecimaliInEccesso_NonEValido;
var V: TPrecisionScaleValidator;
begin
  V := TPrecisionScaleValidator.Create(5, 2);
  try Assert.IsFalse(V.IsValid(TValue.From<Double>(12.345))); finally V.Free; end;
end;

procedure TTestPrecisionScaleValidator.CifreIntereInEccesso_NonEValido;
var V: TPrecisionScaleValidator;
begin
  V := TPrecisionScaleValidator.Create(5, 2);
  try Assert.IsFalse(V.IsValid(TValue.From<Currency>(1234.5))); finally V.Free; end;
end;

procedure TTestPrecisionScaleValidator.ValoreMinoreDiUno_ContaZeroCifreIntere_EValido;
var V: TPrecisionScaleValidator;
begin
  V := TPrecisionScaleValidator.Create(2, 2); // 0 intere + 2 decimali
  try Assert.IsTrue(V.IsValid(TValue.From<Double>(0.99))); finally V.Free; end;
end;

procedure TTestPrecisionScaleValidator.InteroPuro_EValido;
var V: TPrecisionScaleValidator;
begin
  V := TPrecisionScaleValidator.Create(5, 2);
  try Assert.IsTrue(V.IsValid(TValue.From<Integer>(100))); finally V.Free; end;
end;

procedure TTestPrecisionScaleValidator.ValoreNegativo_TrattatoInModulo_EValido;
var V: TPrecisionScaleValidator;
begin
  V := TPrecisionScaleValidator.Create(5, 2);
  try Assert.IsTrue(V.IsValid(TValue.From<Currency>(-123.45))); finally V.Free; end;
end;

procedure TTestPrecisionScaleValidator.ZeriDecimaliFinaliIgnorati_EValido;
var V: TPrecisionScaleValidator;
begin
  // 100.00 su Currency: gli zeri finali non sono ricostruibili dal valore
  // binario, quindi contano 0 decimali -> valido anche con scale 0.
  V := TPrecisionScaleValidator.Create(3, 0);
  try Assert.IsTrue(V.IsValid(TValue.From<Currency>(100.00))); finally V.Free; end;
end;

procedure TTestPrecisionScaleValidator.ValoreNonNumerico_NonEValido;
var V: TPrecisionScaleValidator;
begin
  V := TPrecisionScaleValidator.Create(5, 2);
  try Assert.IsFalse(V.IsValid(TValue.From<string>('abc'))); finally V.Free; end;
end;

procedure TTestPrecisionScaleValidator.ParametriIncoerenti_SollevanoEccezione;
begin
  Assert.WillRaise(
    procedure begin TPrecisionScaleValidator.Create(2, 5).Free; end,
    EArgumentException);
end;

{ TTestEnumNameValidator }

procedure TTestEnumNameValidator.NomeEsatto_EValido;
var V: TEnumNameValidator;
begin
  V := TEnumNameValidator.Create(TypeInfo(TStatoOrdine));
  try Assert.IsTrue(V.IsValid(TValue.From<string>('soConfermato'))); finally V.Free; end;
end;

procedure TTestEnumNameValidator.NomeAltroCaseInsensitive_EValido;
var V: TEnumNameValidator;
begin
  V := TEnumNameValidator.Create(TypeInfo(TStatoOrdine), False);
  try Assert.IsTrue(V.IsValid(TValue.From<string>('SOCONFERMATO'))); finally V.Free; end;
end;

procedure TTestEnumNameValidator.NomeAltroCaseSensitive_NonEValido;
var V: TEnumNameValidator;
begin
  V := TEnumNameValidator.Create(TypeInfo(TStatoOrdine), True);
  try Assert.IsFalse(V.IsValid(TValue.From<string>('SOCONFERMATO'))); finally V.Free; end;
end;

procedure TTestEnumNameValidator.NomeEsattoCaseSensitive_EValido;
var V: TEnumNameValidator;
begin
  V := TEnumNameValidator.Create(TypeInfo(TStatoOrdine), True);
  try Assert.IsTrue(V.IsValid(TValue.From<string>('soConfermato'))); finally V.Free; end;
end;

procedure TTestEnumNameValidator.NomeInesistente_NonEValido;
var V: TEnumNameValidator;
begin
  V := TEnumNameValidator.Create(TypeInfo(TStatoOrdine));
  try Assert.IsFalse(V.IsValid(TValue.From<string>('soInesistente'))); finally V.Free; end;
end;

procedure TTestEnumNameValidator.ValoreNonStringa_NonEValido;
var V: TEnumNameValidator;
begin
  V := TEnumNameValidator.Create(TypeInfo(TStatoOrdine));
  try Assert.IsFalse(V.IsValid(TValue.From<Integer>(1))); finally V.Free; end;
end;

{ TTestCreditCardValidator }

procedure TTestCreditCardValidator.NumeroValido_EValido;
var V: TCreditCardValidator;
begin
  V := TCreditCardValidator.Create;
  try Assert.IsTrue(V.IsValid(TValue.From<string>('4111111111111111'))); finally V.Free; end;
end;

procedure TTestCreditCardValidator.NumeroValidoConSpaziETrattini_EValido;
var V: TCreditCardValidator;
begin
  V := TCreditCardValidator.Create;
  try Assert.IsTrue(V.IsValid(TValue.From<string>('4111-1111 1111-1111'))); finally V.Free; end;
end;

procedure TTestCreditCardValidator.NumeroNonValido_NonEValido;
var V: TCreditCardValidator;
begin
  V := TCreditCardValidator.Create;
  try Assert.IsFalse(V.IsValid(TValue.From<string>('4111111111111112'))); finally V.Free; end;
end;

procedure TTestCreditCardValidator.ContieneCaratteriNonNumerici_NonEValido;
var V: TCreditCardValidator;
begin
  V := TCreditCardValidator.Create;
  try Assert.IsFalse(V.IsValid(TValue.From<string>('4111-abcd-1111-1111'))); finally V.Free; end;
end;

procedure TTestCreditCardValidator.StringaVuota_EValida;
var V: TCreditCardValidator;
begin
  // Coerente con .NET: assenza di valore -> valido; usare NotEmpty se serve.
  V := TCreditCardValidator.Create;
  try Assert.IsTrue(V.IsValid(TValue.From<string>(''))); finally V.Free; end;
end;

procedure TTestCreditCardValidator.ValoreNonStringa_NonEValido;
var V: TCreditCardValidator;
begin
  V := TCreditCardValidator.Create;
  try Assert.IsFalse(V.IsValid(TValue.From<Integer>(4111))); finally V.Free; end;
end;

{ TTestPhase2Integrazione }

procedure TTestPhase2Integrazione.PrecisionScale_SuCurrencyValida_ViaRuleFor;
var V: TValidator<TPersona>; P: TPersona; Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<Currency>('Importo',
      function(Persona: TPersona): Currency begin Result := Persona.Importo; end)
      .PrecisionScale(10, 2);
    P := TPersona.Create;
    try
      P.Importo := 1234.56;
      Esito := V.Validate(P);
      Assert.IsTrue(Esito.IsValid);
    finally P.Free; end;
  finally V.Free; end;
end;

procedure TTestPhase2Integrazione.PrecisionScale_SuCurrencyConTroppiDecimali_ViaRuleFor;
var V: TValidator<TPersona>; P: TPersona; Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<Currency>('Importo',
      function(Persona: TPersona): Currency begin Result := Persona.Importo; end)
      .PrecisionScale(10, 2);
    P := TPersona.Create;
    try
      P.Importo := 12.345;
      Esito := V.Validate(P);
      Assert.IsFalse(Esito.IsValid);
      Assert.AreEqual('Importo', Esito.Errors[0].PropertyName);
    finally P.Free; end;
  finally V.Free; end;
end;

procedure TTestPhase2Integrazione.Empty_SuStringaObbligatoriamenteVuota_ViaRuleFor;
var V: TValidator<TPersona>; P: TPersona; Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<string>('Cognome',
      function(Persona: TPersona): string begin Result := Persona.Cognome; end)
      .Empty;
    P := TPersona.Create;
    try
      P.Cognome := 'NonVuoto';
      Esito := V.Validate(P);
      Assert.IsFalse(Esito.IsValid);
    finally P.Free; end;
  finally V.Free; end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestNullValidator);
  TDUnitX.RegisterTestFixture(TTestEmptyValidator);
  TDUnitX.RegisterTestFixture(TTestPrecisionScaleValidator);
  TDUnitX.RegisterTestFixture(TTestEnumNameValidator);
  TDUnitX.RegisterTestFixture(TTestCreditCardValidator);
  TDUnitX.RegisterTestFixture(TTestPhase2Integrazione);

end.
