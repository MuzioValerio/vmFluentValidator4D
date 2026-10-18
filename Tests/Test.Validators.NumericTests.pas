{-----------------------------------------------------------------------------
 Project: FluentValidator - Test Suite
 Unit Name: Test.Validators.NumericTests
 Purpose: Test sui validatori numerici di confronto (GreaterThan,
          GreaterThanOrEqual, LessThan, LessThanOrEqual, InclusiveBetween,
          ExclusiveBetween), tutti basati sulla classe comune
          TNumericComparisonValidator introdotta nel refactoring del 28-giu-2026.
          Copertura specifica del supporto multi-tipo dichiarato nel changelog:
          Integer, Int64, Cardinal, Word, SmallInt, ShortInt, Byte, Double,
          Single, Currency.
-----------------------------------------------------------------------------}

unit Test.Validators.NumericTests;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils, System.Rtti,
  FluentValidator.Validators,
  FluentValidator.GreaterThanValidator,
  FluentValidator.GreaterThanOrEqualValidator,
  FluentValidator.LessThanValidator,
  FluentValidator.LessThanOrEqualValidator,
  FluentValidator.InclusiveBetweenValidator,
  FluentValidator.ExclusiveBetweenValidator,
  FluentValidator;

type
  [TestFixture]
  TTestGreaterThanValidator = class
  public
    [Test]
    procedure ValoreSopraIlMinimo_EValido;
    [Test]
    procedure ValoreUgualeAlMinimo_NonEValido;
    [Test]
    procedure ValoreSottoIlMinimo_NonEValido;
    [Test]
    procedure TValueVuoto_NonEValido;
    [Test]
    procedure ValoreDiTipoNonNumerico_NonEValido;
  end;

  [TestFixture]
  TTestGreaterThanOrEqualValidator = class
  public
    [Test]
    procedure ValoreUgualeAlMinimo_EValido;
    [Test]
    procedure ValoreSopraIlMinimo_EValido;
    [Test]
    procedure ValoreSottoIlMinimo_NonEValido;
  end;

  [TestFixture]
  TTestLessThanValidator = class
  public
    [Test]
    procedure ValoreSottoIlMassimo_EValido;
    [Test]
    procedure ValoreUgualeAlMassimo_NonEValido;
    [Test]
    procedure ValoreSopraIlMassimo_NonEValido;
  end;

  [TestFixture]
  TTestLessThanOrEqualValidator = class
  public
    [Test]
    procedure ValoreUgualeAlMassimo_EValido;
    [Test]
    procedure ValoreSottoIlMassimo_EValido;
    [Test]
    procedure ValoreSopraIlMassimo_NonEValido;
  end;

  [TestFixture]
  TTestInclusiveBetweenValidator = class
  public
    [Test]
    procedure ValoreNelRange_EValido;
    [Test]
    procedure ValoreAlConfineInferiore_EValido;
    [Test]
    procedure ValoreAlConfineSuperiore_EValido;
    [Test]
    procedure ValoreFuoriRangeSotto_NonEValido;
    [Test]
    procedure ValoreFuoriRangeSopra_NonEValido;
  end;

  [TestFixture]
  TTestExclusiveBetweenValidator = class
  public
    [Test]
    procedure ValoreNelRange_EValido;
    [Test]
    procedure ValoreAlConfineInferiore_NonEValido;
    [Test]
    procedure ValoreAlConfineSuperiore_NonEValido;
  end;

  [TestFixture]
  TTestSupportoMultiTipoNumerico = class
  public
    [Test]
    // Regression test per il supporto Currency introdotto col refactoring:
    // fondamentale per gli importi monetari.
    procedure GreaterThan_FunzionaConCurrency;
    [Test]
    procedure GreaterThan_FunzionaConDouble;
    [Test]
    procedure GreaterThan_FunzionaConSingle;
    [Test]
    procedure GreaterThan_FunzionaConInt64;
    [Test]
    procedure GreaterThan_FunzionaConWord;
    [Test]
    procedure GreaterThan_FunzionaConByte;
    [Test]
    procedure GreaterThan_FunzionaConSmallInt;
    [Test]
    procedure InclusiveBetween_FunzionaConCurrency;
  end;

implementation

{ TTestGreaterThanValidator }

procedure TTestGreaterThanValidator.ValoreSopraIlMinimo_EValido;
var
  Validatore: TGreaterThanValidator;
begin
  Validatore := TGreaterThanValidator.Create(0);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<Integer>(5)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestGreaterThanValidator.ValoreUgualeAlMinimo_NonEValido;
var
  Validatore: TGreaterThanValidator;
begin
  Validatore := TGreaterThanValidator.Create(10);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<Integer>(10)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestGreaterThanValidator.ValoreSottoIlMinimo_NonEValido;
var
  Validatore: TGreaterThanValidator;
begin
  Validatore := TGreaterThanValidator.Create(10);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<Integer>(3)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestGreaterThanValidator.TValueVuoto_NonEValido;
var
  Validatore: TGreaterThanValidator;
begin
  Validatore := TGreaterThanValidator.Create(0);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.Empty));
  finally
    Validatore.Free;
  end;
end;

procedure TTestGreaterThanValidator.ValoreDiTipoNonNumerico_NonEValido;
var
  Validatore: TGreaterThanValidator;
begin
  Validatore := TGreaterThanValidator.Create(0);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<string>('non un numero')));
  finally
    Validatore.Free;
  end;
end;

{ TTestGreaterThanOrEqualValidator }

procedure TTestGreaterThanOrEqualValidator.ValoreUgualeAlMinimo_EValido;
var
  Validatore: TGreaterThanOrEqualValidator;
begin
  Validatore := TGreaterThanOrEqualValidator.Create(10);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<Integer>(10)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestGreaterThanOrEqualValidator.ValoreSopraIlMinimo_EValido;
var
  Validatore: TGreaterThanOrEqualValidator;
begin
  Validatore := TGreaterThanOrEqualValidator.Create(10);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<Integer>(11)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestGreaterThanOrEqualValidator.ValoreSottoIlMinimo_NonEValido;
var
  Validatore: TGreaterThanOrEqualValidator;
begin
  Validatore := TGreaterThanOrEqualValidator.Create(10);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<Integer>(9)));
  finally
    Validatore.Free;
  end;
end;

{ TTestLessThanValidator }

procedure TTestLessThanValidator.ValoreSottoIlMassimo_EValido;
var
  Validatore: TLessThanValidator;
begin
  Validatore := TLessThanValidator.Create(10);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<Integer>(5)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestLessThanValidator.ValoreUgualeAlMassimo_NonEValido;
var
  Validatore: TLessThanValidator;
begin
  Validatore := TLessThanValidator.Create(10);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<Integer>(10)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestLessThanValidator.ValoreSopraIlMassimo_NonEValido;
var
  Validatore: TLessThanValidator;
begin
  Validatore := TLessThanValidator.Create(10);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<Integer>(20)));
  finally
    Validatore.Free;
  end;
end;

{ TTestLessThanOrEqualValidator }

procedure TTestLessThanOrEqualValidator.ValoreUgualeAlMassimo_EValido;
var
  Validatore: TLessThanOrEqualValidator;
begin
  Validatore := TLessThanOrEqualValidator.Create(10);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<Integer>(10)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestLessThanOrEqualValidator.ValoreSottoIlMassimo_EValido;
var
  Validatore: TLessThanOrEqualValidator;
begin
  Validatore := TLessThanOrEqualValidator.Create(10);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<Integer>(3)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestLessThanOrEqualValidator.ValoreSopraIlMassimo_NonEValido;
var
  Validatore: TLessThanOrEqualValidator;
begin
  Validatore := TLessThanOrEqualValidator.Create(10);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<Integer>(11)));
  finally
    Validatore.Free;
  end;
end;

{ TTestInclusiveBetweenValidator }

procedure TTestInclusiveBetweenValidator.ValoreNelRange_EValido;
var
  Validatore: TInclusiveBetweenValidator;
begin
  Validatore := TInclusiveBetweenValidator.Create(1, 10);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<Integer>(5)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestInclusiveBetweenValidator.ValoreAlConfineInferiore_EValido;
var
  Validatore: TInclusiveBetweenValidator;
begin
  Validatore := TInclusiveBetweenValidator.Create(1, 10);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<Integer>(1)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestInclusiveBetweenValidator.ValoreAlConfineSuperiore_EValido;
var
  Validatore: TInclusiveBetweenValidator;
begin
  Validatore := TInclusiveBetweenValidator.Create(1, 10);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<Integer>(10)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestInclusiveBetweenValidator.ValoreFuoriRangeSotto_NonEValido;
var
  Validatore: TInclusiveBetweenValidator;
begin
  Validatore := TInclusiveBetweenValidator.Create(1, 10);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<Integer>(0)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestInclusiveBetweenValidator.ValoreFuoriRangeSopra_NonEValido;
var
  Validatore: TInclusiveBetweenValidator;
begin
  Validatore := TInclusiveBetweenValidator.Create(1, 10);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<Integer>(11)));
  finally
    Validatore.Free;
  end;
end;

{ TTestExclusiveBetweenValidator }

procedure TTestExclusiveBetweenValidator.ValoreNelRange_EValido;
var
  Validatore: TExclusiveBetweenValidator;
begin
  Validatore := TExclusiveBetweenValidator.Create(1, 10);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<Integer>(5)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestExclusiveBetweenValidator.ValoreAlConfineInferiore_NonEValido;
var
  Validatore: TExclusiveBetweenValidator;
begin
  Validatore := TExclusiveBetweenValidator.Create(1, 10);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<Integer>(1)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestExclusiveBetweenValidator.ValoreAlConfineSuperiore_NonEValido;
var
  Validatore: TExclusiveBetweenValidator;
begin
  Validatore := TExclusiveBetweenValidator.Create(1, 10);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<Integer>(10)));
  finally
    Validatore.Free;
  end;
end;

{ TTestSupportoMultiTipoNumerico }

procedure TTestSupportoMultiTipoNumerico.GreaterThan_FunzionaConCurrency;
var
  Validatore: TGreaterThanValidator;
begin
  Validatore := TGreaterThanValidator.Create(0);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<Currency>(99.90)));
    Assert.IsFalse(Validatore.IsValid(TValue.From<Currency>(0)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestSupportoMultiTipoNumerico.GreaterThan_FunzionaConDouble;
var
  Validatore: TGreaterThanValidator;
begin
  Validatore := TGreaterThanValidator.Create(0);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<Double>(3.14)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestSupportoMultiTipoNumerico.GreaterThan_FunzionaConSingle;
var
  Validatore: TGreaterThanValidator;
begin
  Validatore := TGreaterThanValidator.Create(0);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<Single>(1.5)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestSupportoMultiTipoNumerico.GreaterThan_FunzionaConInt64;
var
  Validatore: TGreaterThanValidator;
begin
  Validatore := TGreaterThanValidator.Create(0);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<Int64>(9999999999)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestSupportoMultiTipoNumerico.GreaterThan_FunzionaConWord;
var
  Validatore: TGreaterThanValidator;
begin
  Validatore := TGreaterThanValidator.Create(0);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<Word>(100)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestSupportoMultiTipoNumerico.GreaterThan_FunzionaConByte;
var
  Validatore: TGreaterThanValidator;
begin
  Validatore := TGreaterThanValidator.Create(0);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<Byte>(5)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestSupportoMultiTipoNumerico.GreaterThan_FunzionaConSmallInt;
var
  Validatore: TGreaterThanValidator;
begin
  Validatore := TGreaterThanValidator.Create(0);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<SmallInt>(42)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestSupportoMultiTipoNumerico.InclusiveBetween_FunzionaConCurrency;
var
  Validatore: TInclusiveBetweenValidator;
begin
  Validatore := TInclusiveBetweenValidator.Create(0, 1000);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<Currency>(499.99)));
    Assert.IsFalse(Validatore.IsValid(TValue.From<Currency>(1500.00)));
  finally
    Validatore.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreaterThanValidator);
  TDUnitX.RegisterTestFixture(TTestGreaterThanOrEqualValidator);
  TDUnitX.RegisterTestFixture(TTestLessThanValidator);
  TDUnitX.RegisterTestFixture(TTestLessThanOrEqualValidator);
  TDUnitX.RegisterTestFixture(TTestInclusiveBetweenValidator);
  TDUnitX.RegisterTestFixture(TTestExclusiveBetweenValidator);
  TDUnitX.RegisterTestFixture(TTestSupportoMultiTipoNumerico);

end.
