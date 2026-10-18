{-----------------------------------------------------------------------------
 Project: FluentValidator - Test Suite
 Unit Name: Test.Validators.EnumTests
 Purpose: Test su TEnumValidator (IsInEnum) e su TEnumConverter
          (EnumToInt/EnumToString/StringToEnum/TryStringToEnum/FindArrayOf*).
          Includono il regression test per il bug bloccante segnalato nel
          changelog (IsEnumValue/IsEnumName non esistono in System.TypInfo) e
          per il bug di StringToEnum<T> che scriveva silenziosamente -1 come
          valore enum "valido" su un nome non trovato.
-----------------------------------------------------------------------------}

unit Test.Validators.EnumTests;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils, System.Rtti, System.TypInfo,
  FluentValidator.Validators,
  FluentValidator.EnumValidator,
  FluentValidator,
  FluentValidator.EnumConverter,
  Test.Fixtures;

type
  [TestFixture]
  TTestEnumValidator = class
  public
    [Test]
    procedure InteroNelRange_EValido;
    [Test]
    procedure InteroFuoriRange_NonEValido;
    [Test]
    procedure StringaConNomeValido_EValida;
    [Test]
    procedure StringaConNomeNonValido_NonEValida;
    [Test]
    // Il fix usa GetEnumValue, che e' case-insensitive: confermiamo questo
    // comportamento esplicitamente (era uno dei requisiti del refactoring,
    // "case-insensitive su una stringa").
    procedure StringaConNomeValidoMaiuscolo_EValida_PerchéCaseInsensitive;
    [Test]
    procedure TValueVuoto_NonEValido;
    [Test]
    procedure ValoreDiTipoNonGestito_NonEValido;
    [Test]
    procedure EnumTypeInfoNil_NonEValido;
  end;

  [TestFixture]
  TTestEnumConverter = class
  public
    [Test]
    procedure EnumToInt_RestituisceLOrdinaleCorretto;
    [Test]
    procedure EnumToString_RestituisceIlNomeCorretto;
    [Test]
    procedure TryStringToEnum_NomeValido_RestituisceTrueEValoreCorretto;
    [Test]
    // Regression test per il bug corretto il 30-giu-2026: un nome non valido
    // deve restituire False, non scrivere silenziosamente -1 nei byte del
    // risultato come se fosse un valore enum legittimo.
    procedure TryStringToEnum_NomeNonValido_RestituisceFalse;
    [Test]
    procedure StringToEnum_NomeValido_RestituisceIlValoreCorretto;
    [Test]
    procedure StringToEnum_NomeNonValido_SollevaEArgumentException;
    [Test]
    procedure FindArrayOfIntIndexOf_TrovaLIndiceCorretto;
    [Test]
    procedure FindArrayOfIntIndexOf_ValoreAssente_RestituisceMenoUno;
    [Test]
    procedure FindArrayOfStringIndexOf_ECaseInsensitive;
    [Test]
    procedure FindArrayOfDoubleIndexOf_TrovaLIndiceCorretto;
  end;

implementation

{ TTestEnumValidator }

procedure TTestEnumValidator.InteroNelRange_EValido;
var
  Validatore: TEnumValidator;
begin
  Validatore := TEnumValidator.Create(TypeInfo(TStatoOrdine));
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<Integer>(Ord(soConfermato))));
  finally
    Validatore.Free;
  end;
end;

procedure TTestEnumValidator.InteroFuoriRange_NonEValido;
var
  Validatore: TEnumValidator;
begin
  Validatore := TEnumValidator.Create(TypeInfo(TStatoOrdine));
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<Integer>(99)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestEnumValidator.StringaConNomeValido_EValida;
var
  Validatore: TEnumValidator;
begin
  Validatore := TEnumValidator.Create(TypeInfo(TStatoOrdine));
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<string>('soSpedito')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestEnumValidator.StringaConNomeNonValido_NonEValida;
var
  Validatore: TEnumValidator;
begin
  Validatore := TEnumValidator.Create(TypeInfo(TStatoOrdine));
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<string>('soInesistente')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestEnumValidator.StringaConNomeValidoMaiuscolo_EValida_PerchéCaseInsensitive;
var
  Validatore: TEnumValidator;
begin
  Validatore := TEnumValidator.Create(TypeInfo(TStatoOrdine));
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<string>('SOSPEDITO')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestEnumValidator.TValueVuoto_NonEValido;
var
  Validatore: TEnumValidator;
begin
  Validatore := TEnumValidator.Create(TypeInfo(TStatoOrdine));
  try
    Assert.IsFalse(Validatore.IsValid(TValue.Empty));
  finally
    Validatore.Free;
  end;
end;

procedure TTestEnumValidator.ValoreDiTipoNonGestito_NonEValido;
var
  Validatore: TEnumValidator;
begin
  // Solo Integer e string sono gestiti: un Double, ad esempio, deve fallire.
  Validatore := TEnumValidator.Create(TypeInfo(TStatoOrdine));
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<Double>(1.0)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestEnumValidator.EnumTypeInfoNil_NonEValido;
var
  Validatore: TEnumValidator;
begin
  Validatore := TEnumValidator.Create(nil);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<Integer>(0)));
  finally
    Validatore.Free;
  end;
end;

{ TTestEnumConverter }

procedure TTestEnumConverter.EnumToInt_RestituisceLOrdinaleCorretto;
begin
  Assert.AreEqual(0, TEnumConverter.EnumToInt<TStatoOrdine>(soBozza));
  Assert.AreEqual(1, TEnumConverter.EnumToInt<TStatoOrdine>(soConfermato));
  Assert.AreEqual(2, TEnumConverter.EnumToInt<TStatoOrdine>(soSpedito));
end;

procedure TTestEnumConverter.EnumToString_RestituisceIlNomeCorretto;
begin
  Assert.AreEqual('soConfermato', TEnumConverter.EnumToString<TStatoOrdine>(soConfermato));
end;

procedure TTestEnumConverter.TryStringToEnum_NomeValido_RestituisceTrueEValoreCorretto;
var
  Valore: TStatoOrdine;
begin
  Assert.IsTrue(TEnumConverter.TryStringToEnum<TStatoOrdine>('soSpedito', Valore));
  Assert.AreEqual(soSpedito, Valore);
end;

procedure TTestEnumConverter.TryStringToEnum_NomeNonValido_RestituisceFalse;
var
  Valore: TStatoOrdine;
begin
  Assert.IsFalse(TEnumConverter.TryStringToEnum<TStatoOrdine>('nonEsiste', Valore));
end;

procedure TTestEnumConverter.StringToEnum_NomeValido_RestituisceIlValoreCorretto;
begin
  Assert.AreEqual(soBozza, TEnumConverter.StringToEnum<TStatoOrdine>('soBozza'));
end;

procedure TTestEnumConverter.StringToEnum_NomeNonValido_SollevaEArgumentException;
begin
  Assert.WillRaise(
    procedure
    begin
      TEnumConverter.StringToEnum<TStatoOrdine>('nonEsiste');
    end,
    EArgumentException);
end;

procedure TTestEnumConverter.FindArrayOfIntIndexOf_TrovaLIndiceCorretto;
var
  Valori: TArray<Integer>;
begin
  Valori := [10, 20, 30];
  Assert.AreEqual(1, TEnumConverter.FindArrayOfIntIndexOf(Valori, 20));
end;

procedure TTestEnumConverter.FindArrayOfIntIndexOf_ValoreAssente_RestituisceMenoUno;
var
  Valori: TArray<Integer>;
begin
  Valori := [10, 20, 30];
  Assert.AreEqual(-1, TEnumConverter.FindArrayOfIntIndexOf(Valori, 99));
end;

procedure TTestEnumConverter.FindArrayOfStringIndexOf_ECaseInsensitive;
var
  Valori: TArray<string>;
begin
  Valori := ['Rosso', 'Verde', 'Blu'];
  Assert.AreEqual(1, TEnumConverter.FindArrayOfStringIndexOf(Valori, 'VERDE'));
end;

procedure TTestEnumConverter.FindArrayOfDoubleIndexOf_TrovaLIndiceCorretto;
var
  Valori: TArray<Double>;
begin
  Valori := [1.1, 2.2, 3.3];
  Assert.AreEqual(2, TEnumConverter.FindArrayOfDoubleIndexOf(Valori, 3.3));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestEnumValidator);
  TDUnitX.RegisterTestFixture(TTestEnumConverter);

end.
