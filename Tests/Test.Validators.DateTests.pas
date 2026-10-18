{-----------------------------------------------------------------------------
 Project: FluentValidator - Test Suite
 Unit Name: Test.Validators.DateTests
 Purpose: Test di non regressione per TMustBeInPastValidator/TMustBeInFutureValidator.
          Prima del fix il confronto avveniva a livello di istante esatto
          (DateValue <= Now) invece che di giorno di
          calendario: per una data pura (ora = 00:00, il caso tipico di
          DataFattura), il comportamento di IncludeToday cambiava in modo
          imprevedibile in base all'orario di esecuzione del test.
          Tutti i test qui sotto usano Trunc(Now) come riferimento "oggi",
          quindi sono deterministici a qualunque ora vengano eseguiti.
-----------------------------------------------------------------------------}

unit Test.Validators.DateTests;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils, System.Rtti,
  FluentValidator.Validators,
  FluentValidator.MustBeInPastValidator,
  FluentValidator.MustBeInFutureValidator,
  FluentValidator;

type
  [TestFixture]
  TTestMustBeInPastValidator = class
  public
    [Test]
    procedure DataPassata_EValida;
    [Test]
    procedure DataFutura_NonEValida;
    [Test]
    // Regression test principale del fix Trunc: "oggi" (stessa data di calendario,
    // qualunque sia l'ora) con IncludeToday=False deve essere considerato NON
    // passato, indipendentemente dall'orario in cui il test viene eseguito.
    procedure DataDiOggi_ConIncludeTodayFalso_NonEValida;
    [Test]
    procedure DataDiOggi_ConIncludeTodayVero_EValida;
    [Test]
    procedure DataDiIeri_ConIncludeTodayFalso_EValida;
    [Test]
    procedure DataDiIeri_ConIncludeTodayVero_EValida;
    [Test]
    procedure TValueVuoto_NonEValido;
    [Test]
    procedure ValoreNonData_NonEValido;
  end;

  [TestFixture]
  TTestMustBeInFutureValidator = class
  public
    [Test]
    procedure DataFutura_EValida;
    [Test]
    procedure DataPassata_NonEValida;
    [Test]
    procedure DataDiOggi_ConIncludeTodayFalso_NonEValida;
    [Test]
    procedure DataDiOggi_ConIncludeTodayVero_EValida;
    [Test]
    procedure DataDiDomani_ConIncludeTodayFalso_EValida;
    [Test]
    procedure DataDiDomani_ConIncludeTodayVero_EValida;
    [Test]
    procedure TValueVuoto_NonEValido;
  end;

implementation

{ TTestMustBeInPastValidator }

procedure TTestMustBeInPastValidator.DataPassata_EValida;
var
  Validatore: TMustBeInPastValidator;
begin
  Validatore := TMustBeInPastValidator.Create(False);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<TDateTime>(Trunc(Now) - 365)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestMustBeInPastValidator.DataFutura_NonEValida;
var
  Validatore: TMustBeInPastValidator;
begin
  Validatore := TMustBeInPastValidator.Create(False);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<TDateTime>(Trunc(Now) + 30)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestMustBeInPastValidator.DataDiOggi_ConIncludeTodayFalso_NonEValida;
var
  Validatore: TMustBeInPastValidator;
begin
  Validatore := TMustBeInPastValidator.Create(False);
  try
    // Trunc(Now): oggi a mezzanotte, stessa data di calendario di "adesso"
    // a prescindere dall'ora corrente.
    Assert.IsFalse(Validatore.IsValid(TValue.From<TDateTime>(Trunc(Now))));
  finally
    Validatore.Free;
  end;
end;

procedure TTestMustBeInPastValidator.DataDiOggi_ConIncludeTodayVero_EValida;
var
  Validatore: TMustBeInPastValidator;
begin
  Validatore := TMustBeInPastValidator.Create(True);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<TDateTime>(Trunc(Now))));
  finally
    Validatore.Free;
  end;
end;

procedure TTestMustBeInPastValidator.DataDiIeri_ConIncludeTodayFalso_EValida;
var
  Validatore: TMustBeInPastValidator;
begin
  Validatore := TMustBeInPastValidator.Create(False);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<TDateTime>(Trunc(Now) - 1)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestMustBeInPastValidator.DataDiIeri_ConIncludeTodayVero_EValida;
var
  Validatore: TMustBeInPastValidator;
begin
  Validatore := TMustBeInPastValidator.Create(True);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<TDateTime>(Trunc(Now) - 1)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestMustBeInPastValidator.TValueVuoto_NonEValido;
var
  Validatore: TMustBeInPastValidator;
begin
  Validatore := TMustBeInPastValidator.Create(False);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.Empty));
  finally
    Validatore.Free;
  end;
end;

procedure TTestMustBeInPastValidator.ValoreNonData_NonEValido;
var
  Validatore: TMustBeInPastValidator;
begin
  Validatore := TMustBeInPastValidator.Create(False);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<string>('non una data')));
  finally
    Validatore.Free;
  end;
end;

{ TTestMustBeInFutureValidator }

procedure TTestMustBeInFutureValidator.DataFutura_EValida;
var
  Validatore: TMustBeInFutureValidator;
begin
  Validatore := TMustBeInFutureValidator.Create(False);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<TDateTime>(Trunc(Now) + 30)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestMustBeInFutureValidator.DataPassata_NonEValida;
var
  Validatore: TMustBeInFutureValidator;
begin
  Validatore := TMustBeInFutureValidator.Create(False);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<TDateTime>(Trunc(Now) - 30)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestMustBeInFutureValidator.DataDiOggi_ConIncludeTodayFalso_NonEValida;
var
  Validatore: TMustBeInFutureValidator;
begin
  Validatore := TMustBeInFutureValidator.Create(False);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<TDateTime>(Trunc(Now))));
  finally
    Validatore.Free;
  end;
end;

procedure TTestMustBeInFutureValidator.DataDiOggi_ConIncludeTodayVero_EValida;
var
  Validatore: TMustBeInFutureValidator;
begin
  Validatore := TMustBeInFutureValidator.Create(True);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<TDateTime>(Trunc(Now))));
  finally
    Validatore.Free;
  end;
end;

procedure TTestMustBeInFutureValidator.DataDiDomani_ConIncludeTodayFalso_EValida;
var
  Validatore: TMustBeInFutureValidator;
begin
  Validatore := TMustBeInFutureValidator.Create(False);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<TDateTime>(Trunc(Now) + 1)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestMustBeInFutureValidator.DataDiDomani_ConIncludeTodayVero_EValida;
var
  Validatore: TMustBeInFutureValidator;
begin
  Validatore := TMustBeInFutureValidator.Create(True);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<TDateTime>(Trunc(Now) + 1)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestMustBeInFutureValidator.TValueVuoto_NonEValido;
var
  Validatore: TMustBeInFutureValidator;
begin
  Validatore := TMustBeInFutureValidator.Create(False);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.Empty));
  finally
    Validatore.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMustBeInPastValidator);
  TDUnitX.RegisterTestFixture(TTestMustBeInFutureValidator);

end.
