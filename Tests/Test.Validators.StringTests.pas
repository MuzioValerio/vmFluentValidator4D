{-----------------------------------------------------------------------------
 Project: FluentValidator - Test Suite
 Unit Name: Test.Validators.StringTests
 Purpose: Test "white-box" diretti sulle classi dei validatori di stringa/
          generici (TNotNullValidator, TNotEmptyValidator, TLengthValidator,
          TMinLengthValidator, TMaxLengthValidator, TEqualValidator,
          TNotEqualValidator, TRegexValidator, TStartsWithUpperCaseValidator).
          Si istanzia il validatore e si chiama IsValid(TValue) direttamente,
          senza passare per RuleFor/TValidator<T>: piu' rapido da isolare e
          mette a nudo esattamente il comportamento del singolo validatore.
-----------------------------------------------------------------------------}

unit Test.Validators.StringTests;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils, System.Rtti,
  FluentValidator.Validators,
  FluentValidator.NotNullValidator,
  FluentValidator.NotEmptyValidator,
  FluentValidator.LengthValidator,
  FluentValidator.MaxLengthValidator,
  FluentValidator.MinLengthValidator,
  FluentValidator.EqualValidator,
  FluentValidator.NotEqualValidator,
  FluentValidator.RegexValidator,
  FluentValidator.StartsWithUpperCaseValidator,
  FluentValidator;

type
  [TestFixture]
  TTestNotNullValidator = class
  public
    [Test]
    procedure StringaNonVuota_EValida;
    [Test]
    procedure StringaVuota_NonENullaPerQuestoValidatore_QuindiValida;
    [Test]
    procedure TValueVuoto_NonValido;
    [Test]
    procedure OggettoAssegnato_EValido;
    [Test]
    // Regression test: prima del fix, TValue.IsEmpty non rilevava un
    // riferimento a oggetto nil (il TypeInfo resta valido), quindi NotNull
    // "passava sempre" per le proprieta' oggetto non assegnate.
    procedure OggettoNil_NonEValido;
  end;

  [TestFixture]
  TTestNotEmptyValidator = class
  public
    [Test]
    procedure StringaNonVuota_EValida;
    [Test]
    procedure StringaVuota_NonEValida;
    [Test]
    procedure StringaDiSoliSpazi_NonEValida;
    [Test]
    procedure OggettoNil_NonEValido;
    [Test]
    procedure OggettoAssegnato_EValido;
    [Test]
    // Regression test: Integer/Currency a 0 deve essere considerato "vuoto",
    // coerentemente con FluentValidation .NET (default value del tipo).
    procedure InteroAZero_NonEValido;
    [Test]
    procedure InteroDiverseDaZero_EValido;
    [Test]
    procedure CurrencyAZero_NonEValido;
    [Test]
    procedure DoubleAZero_NonEValido;
  end;

  [TestFixture]
  TTestLengthValidator = class
  public
    [Test]
    procedure LunghezzaNelRange_EValida;
    [Test]
    procedure LunghezzaSottoIlMinimo_NonEValida;
    [Test]
    procedure LunghezzaSopraIlMassimo_NonEValida;
    [Test]
    procedure LunghezzaAlConfineMinimo_EValida;
    [Test]
    procedure LunghezzaAlConfineMassimo_EValida;
    [Test]
    procedure ValoreNonStringa_NonEValido;
  end;

  [TestFixture]
  TTestMinLengthMaxLengthValidator = class
  public
    [Test]
    procedure MinLength_StringaPiuCorta_NonEValida;
    [Test]
    procedure MinLength_StringaAlMinimo_EValida;
    [Test]
    procedure MinLength_TValueVuoto_NonEValido;
    [Test]
    procedure MaxLength_StringaPiuLunga_NonEValida;
    [Test]
    procedure MaxLength_StringaAlMassimo_EValida;
    [Test]
    // Comportamento attuale: MaxLength su TValue vuoto torna True (non e'
    // compito suo segnalare l'assenza di valore, a differenza di MinLength).
    procedure MaxLength_TValueVuoto_EValido;
  end;

  [TestFixture]
  TTestEqualNotEqualValidator = class
  public
    [Test]
    procedure Equal_StringheUguali_EValido;
    [Test]
    procedure Equal_StringheDiverse_NonEValido;
    [Test]
    procedure Equal_InteriUguali_EValido;
    [Test]
    procedure Equal_InteriDiversi_NonEValido;
    [Test]
    procedure NotEqual_StringheDiverse_EValido;
    [Test]
    procedure NotEqual_StringheUguali_NonEValido;
    [Test]
    // Comportamento attuale, noto come incoerenza (vedi "Comportamenti noti e
    // trappole" nel README):
    // NotEqual su TValue vuoto torna True (valido) invece di seguire la stessa
    // policy "tipo non gestito -> sempre False" applicata altrove. Questo test
    // fissa il comportamento di OGGI: va aggiornato se/quando la policy viene
    // unificata.
    procedure NotEqual_ValoreVuoto_TornaValido_ComportamentoAttuale;
  end;

  [TestFixture]
  TTestRegexValidator = class
  public
    [Test]
    procedure PatternCorrispondente_EValido;
    [Test]
    procedure PatternNonCorrispondente_NonEValido;
    [Test]
    procedure ValoreNonStringa_NonEValido;
    [Test]
    procedure StringaVuota_ConPatternCheRichiedeAlmenoUnCarattere_NonEValida;
  end;

  [TestFixture]
  TTestStartsWithUpperCaseValidator = class
  public
    [Test]
    procedure IniziaConMaiuscolaASCII_EValido;
    [Test]
    procedure IniziaConMinuscola_NonEValido;
    [Test]
    // Regression test per il fix dell'iniziale accentata (TCharacter.IsUpper,
    // locale-aware, al posto del controllo 'A'..'Z' puramente ASCII).
    procedure IniziaConMaiuscolaAccentata_EValido;
    [Test]
    procedure IniziaConMinuscolaAccentata_NonEValido;
    [Test]
    // Comportamento attuale: stringa vuota -> True (nessuna "iniziale" da
    // giudicare). Da combinare di solito con NotEmpty se l'obbligatorieta'
    // va imposta separatamente.
    procedure StringaVuota_EValida;
    [Test]
    procedure ValoreNonStringa_NonEValido;
  end;

implementation

{ TTestNotNullValidator }

procedure TTestNotNullValidator.StringaNonVuota_EValida;
var
  Validatore: TNotNullValidator;
begin
  Validatore := TNotNullValidator.Create;
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<string>('Muzio')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestNotNullValidator.StringaVuota_NonENullaPerQuestoValidatore_QuindiValida;
var
  Validatore: TNotNullValidator;
begin
  // NotNull si occupa solo di "non nil"/"non vuoto in senso TValue", non
  // dell'obbligatorieta' del contenuto: per quello c'e' NotEmpty.
  Validatore := TNotNullValidator.Create;
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<string>('')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestNotNullValidator.TValueVuoto_NonValido;
var
  Validatore: TNotNullValidator;
begin
  Validatore := TNotNullValidator.Create;
  try
    Assert.IsFalse(Validatore.IsValid(TValue.Empty));
  finally
    Validatore.Free;
  end;
end;

procedure TTestNotNullValidator.OggettoAssegnato_EValido;
var
  Validatore: TNotNullValidator;
  Obj: TObject;
begin
  Validatore := TNotNullValidator.Create;
  Obj := TObject.Create;
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<TObject>(Obj)));
  finally
    Validatore.Free;
    Obj.Free;
  end;
end;

procedure TTestNotNullValidator.OggettoNil_NonEValido;
var
  Validatore: TNotNullValidator;
  Obj: TObject;
begin
  Validatore := TNotNullValidator.Create;
  Obj := nil;
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<TObject>(Obj)));
  finally
    Validatore.Free;
  end;
end;

{ TTestNotEmptyValidator }

procedure TTestNotEmptyValidator.StringaNonVuota_EValida;
var
  Validatore: TNotEmptyValidator;
begin
  Validatore := TNotEmptyValidator.Create;
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<string>('Muzio')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestNotEmptyValidator.StringaVuota_NonEValida;
var
  Validatore: TNotEmptyValidator;
begin
  Validatore := TNotEmptyValidator.Create;
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<string>('')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestNotEmptyValidator.StringaDiSoliSpazi_NonEValida;
var
  Validatore: TNotEmptyValidator;
begin
  Validatore := TNotEmptyValidator.Create;
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<string>('   ')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestNotEmptyValidator.OggettoNil_NonEValido;
var
  Validatore: TNotEmptyValidator;
  Obj: TObject;
begin
  Validatore := TNotEmptyValidator.Create;
  Obj := nil;
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<TObject>(Obj)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestNotEmptyValidator.OggettoAssegnato_EValido;
var
  Validatore: TNotEmptyValidator;
  Obj: TObject;
begin
  Validatore := TNotEmptyValidator.Create;
  Obj := TObject.Create;
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<TObject>(Obj)));
  finally
    Validatore.Free;
    Obj.Free;
  end;
end;

procedure TTestNotEmptyValidator.InteroAZero_NonEValido;
var
  Validatore: TNotEmptyValidator;
begin
  Validatore := TNotEmptyValidator.Create;
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<Integer>(0)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestNotEmptyValidator.InteroDiverseDaZero_EValido;
var
  Validatore: TNotEmptyValidator;
begin
  Validatore := TNotEmptyValidator.Create;
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<Integer>(7)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestNotEmptyValidator.CurrencyAZero_NonEValido;
var
  Validatore: TNotEmptyValidator;
begin
  Validatore := TNotEmptyValidator.Create;
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<Currency>(0)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestNotEmptyValidator.DoubleAZero_NonEValido;
var
  Validatore: TNotEmptyValidator;
begin
  Validatore := TNotEmptyValidator.Create;
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<Double>(0.0)));
  finally
    Validatore.Free;
  end;
end;

{ TTestLengthValidator }

procedure TTestLengthValidator.LunghezzaNelRange_EValida;
var
  Validatore: TLengthValidator;
begin
  Validatore := TLengthValidator.Create(2, 10);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<string>('Anna')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestLengthValidator.LunghezzaSottoIlMinimo_NonEValida;
var
  Validatore: TLengthValidator;
begin
  Validatore := TLengthValidator.Create(2, 10);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<string>('A')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestLengthValidator.LunghezzaSopraIlMassimo_NonEValida;
var
  Validatore: TLengthValidator;
begin
  Validatore := TLengthValidator.Create(2, 5);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<string>('Alessandro')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestLengthValidator.LunghezzaAlConfineMinimo_EValida;
var
  Validatore: TLengthValidator;
begin
  Validatore := TLengthValidator.Create(2, 10);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<string>('An')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestLengthValidator.LunghezzaAlConfineMassimo_EValida;
var
  Validatore: TLengthValidator;
begin
  Validatore := TLengthValidator.Create(2, 5);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<string>('Anna1')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestLengthValidator.ValoreNonStringa_NonEValido;
var
  Validatore: TLengthValidator;
begin
  Validatore := TLengthValidator.Create(2, 10);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<Integer>(5)));
  finally
    Validatore.Free;
  end;
end;

{ TTestMinLengthMaxLengthValidator }

procedure TTestMinLengthMaxLengthValidator.MinLength_StringaPiuCorta_NonEValida;
var
  Validatore: TMinLengthValidator;
begin
  Validatore := TMinLengthValidator.Create(5);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<string>('Ciao')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestMinLengthMaxLengthValidator.MinLength_StringaAlMinimo_EValida;
var
  Validatore: TMinLengthValidator;
begin
  Validatore := TMinLengthValidator.Create(4);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<string>('Ciao')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestMinLengthMaxLengthValidator.MinLength_TValueVuoto_NonEValido;
var
  Validatore: TMinLengthValidator;
begin
  Validatore := TMinLengthValidator.Create(4);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.Empty));
  finally
    Validatore.Free;
  end;
end;

procedure TTestMinLengthMaxLengthValidator.MaxLength_StringaPiuLunga_NonEValida;
var
  Validatore: TMaxLengthValidator;
begin
  Validatore := TMaxLengthValidator.Create(5);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<string>('Alessandro')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestMinLengthMaxLengthValidator.MaxLength_StringaAlMassimo_EValida;
var
  Validatore: TMaxLengthValidator;
begin
  Validatore := TMaxLengthValidator.Create(4);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<string>('Ciao')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestMinLengthMaxLengthValidator.MaxLength_TValueVuoto_EValido;
var
  Validatore: TMaxLengthValidator;
begin
  Validatore := TMaxLengthValidator.Create(4);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.Empty));
  finally
    Validatore.Free;
  end;
end;

{ TTestEqualNotEqualValidator }

procedure TTestEqualNotEqualValidator.Equal_StringheUguali_EValido;
var
  Validatore: TEqualValidator;
begin
  Validatore := TEqualValidator.Create('ABC');
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<string>('ABC')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestEqualNotEqualValidator.Equal_StringheDiverse_NonEValido;
var
  Validatore: TEqualValidator;
begin
  Validatore := TEqualValidator.Create('ABC');
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<string>('XYZ')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestEqualNotEqualValidator.Equal_InteriUguali_EValido;
var
  Validatore: TEqualValidator;
begin
  Validatore := TEqualValidator.Create(42);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<Integer>(42)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestEqualNotEqualValidator.Equal_InteriDiversi_NonEValido;
var
  Validatore: TEqualValidator;
begin
  Validatore := TEqualValidator.Create(42);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<Integer>(7)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestEqualNotEqualValidator.NotEqual_StringheDiverse_EValido;
var
  Validatore: TNotEqualValidator;
begin
  Validatore := TNotEqualValidator.Create('ABC');
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<string>('XYZ')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestEqualNotEqualValidator.NotEqual_StringheUguali_NonEValido;
var
  Validatore: TNotEqualValidator;
begin
  Validatore := TNotEqualValidator.Create('ABC');
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<string>('ABC')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestEqualNotEqualValidator.NotEqual_ValoreVuoto_TornaValido_ComportamentoAttuale;
var
  Validatore: TNotEqualValidator;
begin
  Validatore := TNotEqualValidator.Create('ABC');
  try
    Assert.IsTrue(Validatore.IsValid(TValue.Empty));
  finally
    Validatore.Free;
  end;
end;

{ TTestRegexValidator }

procedure TTestRegexValidator.PatternCorrispondente_EValido;
var
  Validatore: TRegexValidator;
begin
  Validatore := TRegexValidator.Create('^[\w\.-]+@[\w\.-]+\.\w+$');
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<string>('test@esempio.it')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestRegexValidator.PatternNonCorrispondente_NonEValido;
var
  Validatore: TRegexValidator;
begin
  Validatore := TRegexValidator.Create('^[\w\.-]+@[\w\.-]+\.\w+$');
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<string>('non-una-email')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestRegexValidator.ValoreNonStringa_NonEValido;
var
  Validatore: TRegexValidator;
begin
  Validatore := TRegexValidator.Create('^\d+$');
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<Integer>(123)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestRegexValidator.StringaVuota_ConPatternCheRichiedeAlmenoUnCarattere_NonEValida;
var
  Validatore: TRegexValidator;
begin
  Validatore := TRegexValidator.Create('^.+$');
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<string>('')));
  finally
    Validatore.Free;
  end;
end;

{ TTestStartsWithUpperCaseValidator }

procedure TTestStartsWithUpperCaseValidator.IniziaConMaiuscolaASCII_EValido;
var
  Validatore: TStartsWithUpperCaseValidator;
begin
  Validatore := TStartsWithUpperCaseValidator.Create;
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<string>('Muzio')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestStartsWithUpperCaseValidator.IniziaConMinuscola_NonEValido;
var
  Validatore: TStartsWithUpperCaseValidator;
begin
  Validatore := TStartsWithUpperCaseValidator.Create;
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<string>('muzio')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestStartsWithUpperCaseValidator.IniziaConMaiuscolaAccentata_EValido;
var
  Validatore: TStartsWithUpperCaseValidator;
begin
  Validatore := TStartsWithUpperCaseValidator.Create;
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<string>('Élise')));
    Assert.IsTrue(Validatore.IsValid(TValue.From<string>('Òscar')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestStartsWithUpperCaseValidator.IniziaConMinuscolaAccentata_NonEValido;
var
  Validatore: TStartsWithUpperCaseValidator;
begin
  Validatore := TStartsWithUpperCaseValidator.Create;
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<string>('élise')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestStartsWithUpperCaseValidator.StringaVuota_EValida;
var
  Validatore: TStartsWithUpperCaseValidator;
begin
  Validatore := TStartsWithUpperCaseValidator.Create;
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<string>('')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestStartsWithUpperCaseValidator.ValoreNonStringa_NonEValido;
var
  Validatore: TStartsWithUpperCaseValidator;
begin
  Validatore := TStartsWithUpperCaseValidator.Create;
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<Integer>(1)));
  finally
    Validatore.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestNotNullValidator);
  TDUnitX.RegisterTestFixture(TTestNotEmptyValidator);
  TDUnitX.RegisterTestFixture(TTestLengthValidator);
  TDUnitX.RegisterTestFixture(TTestMinLengthMaxLengthValidator);
  TDUnitX.RegisterTestFixture(TTestEqualNotEqualValidator);
  TDUnitX.RegisterTestFixture(TTestRegexValidator);
  TDUnitX.RegisterTestFixture(TTestStartsWithUpperCaseValidator);

end.
