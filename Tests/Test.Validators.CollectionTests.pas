{-----------------------------------------------------------------------------
 Project: FluentValidator - Test Suite
 Unit Name: Test.Validators.CollectionTests
 Purpose: Test di non regressione per TCollectionNotEmptyValidator. Prima del
          fix, riconosceva solo TList<TObject>/TArray<TObject>/TList<string>/
          TArray<string> per match esatto di tipo: qualsiasi altra collezione
          tipizzata (es. TObjectList<TRigaFattura>, il caso reale per le righe
          fattura) passava sempre, anche vuota. Questi test verificano
          l'approccio RTTI generico (array dinamici di qualsiasi tipo elemento,
          e oggetti con proprieta' Count: TList<T>, TObjectList<T>,
          TDictionary<K,V>, TStringList).
-----------------------------------------------------------------------------}

unit Test.Validators.CollectionTests;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils, System.Rtti, System.Classes, System.Generics.Collections,
  FluentValidator.Validators,
  FluentValidator.CollectionNotEmptyValidator,
  FluentValidator,
  Test.Fixtures;

type
  [TestFixture]
  TTestCollectionNotEmptyValidator = class
  public
    [Test]
    procedure TValueVuoto_NonEValido;
    [Test]
    procedure ArrayDinamicoDiInteriNonVuoto_EValido;
    [Test]
    procedure ArrayDinamicoDiInteriVuoto_NonEValido;
    [Test]
    procedure ArrayDinamicoDiStringheNonVuoto_EValido;
    [Test]
    procedure ArrayDinamicoDiDoubleNonVuoto_EValido;
    [Test]
    // Regression test specifico: TObjectList<T> con T diverso da TObject puro
    // (il caso reale "TObjectList<TRigaFattura>" del progetto fatture).
    procedure TObjectListDiEntitaCustomNonVuota_EValido;
    [Test]
    procedure TObjectListDiEntitaCustomVuota_NonEValido;
    [Test]
    procedure TListDiInteriNonVuota_EValido;
    [Test]
    procedure TListDiInteriVuota_NonEValido;
    [Test]
    procedure TDictionaryNonVuoto_EValido;
    [Test]
    procedure TDictionaryVuoto_NonEValido;
    [Test]
    procedure TStringListNonVuota_EValido;
    [Test]
    procedure TStringListVuota_NonEValido;
    [Test]
    procedure OggettoCollezioneNil_NonEValido;
    [Test]
    // Comportamento attuale documentato: un oggetto senza proprieta' Count
    // non e' considerato una collezione, quindi il validatore non si esprime
    // (torna True: "non e' compito di questo validatore giudicarlo").
    procedure OggettoSenzaProprietaCount_TornaValido_ComportamentoAttuale;
  end;

implementation

{ TTestCollectionNotEmptyValidator }

procedure TTestCollectionNotEmptyValidator.TValueVuoto_NonEValido;
var
  Validatore: TCollectionNotEmptyValidator;
begin
  Validatore := TCollectionNotEmptyValidator.Create;
  try
    Assert.IsFalse(Validatore.IsValid(TValue.Empty));
  finally
    Validatore.Free;
  end;
end;

procedure TTestCollectionNotEmptyValidator.ArrayDinamicoDiInteriNonVuoto_EValido;
var
  Validatore: TCollectionNotEmptyValidator;
  Valori: TArray<Integer>;
begin
  Validatore := TCollectionNotEmptyValidator.Create;
  Valori := [1, 2, 3];
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<TArray<Integer>>(Valori)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestCollectionNotEmptyValidator.ArrayDinamicoDiInteriVuoto_NonEValido;
var
  Validatore: TCollectionNotEmptyValidator;
  Valori: TArray<Integer>;
begin
  Validatore := TCollectionNotEmptyValidator.Create;
  Valori := [];
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<TArray<Integer>>(Valori)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestCollectionNotEmptyValidator.ArrayDinamicoDiStringheNonVuoto_EValido;
var
  Validatore: TCollectionNotEmptyValidator;
  Valori: TArray<string>;
begin
  Validatore := TCollectionNotEmptyValidator.Create;
  Valori := ['a', 'b'];
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<TArray<string>>(Valori)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestCollectionNotEmptyValidator.ArrayDinamicoDiDoubleNonVuoto_EValido;
var
  Validatore: TCollectionNotEmptyValidator;
  Valori: TArray<Double>;
begin
  Validatore := TCollectionNotEmptyValidator.Create;
  Valori := [1.1, 2.2];
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<TArray<Double>>(Valori)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestCollectionNotEmptyValidator.TObjectListDiEntitaCustomNonVuota_EValido;
var
  Validatore: TCollectionNotEmptyValidator;
  Lista: TObjectList<TIndirizzo>;
begin
  Validatore := TCollectionNotEmptyValidator.Create;
  Lista := TObjectList<TIndirizzo>.Create(True);
  try
    Lista.Add(TIndirizzo.Create);
    Assert.IsTrue(Validatore.IsValid(TValue.From<TObjectList<TIndirizzo>>(Lista)));
  finally
    Validatore.Free;
    Lista.Free;
  end;
end;

procedure TTestCollectionNotEmptyValidator.TObjectListDiEntitaCustomVuota_NonEValido;
var
  Validatore: TCollectionNotEmptyValidator;
  Lista: TObjectList<TIndirizzo>;
begin
  Validatore := TCollectionNotEmptyValidator.Create;
  Lista := TObjectList<TIndirizzo>.Create(True);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<TObjectList<TIndirizzo>>(Lista)));
  finally
    Validatore.Free;
    Lista.Free;
  end;
end;

procedure TTestCollectionNotEmptyValidator.TListDiInteriNonVuota_EValido;
var
  Validatore: TCollectionNotEmptyValidator;
  Lista: TList<Integer>;
begin
  Validatore := TCollectionNotEmptyValidator.Create;
  Lista := TList<Integer>.Create;
  try
    Lista.Add(1);
    Assert.IsTrue(Validatore.IsValid(TValue.From<TList<Integer>>(Lista)));
  finally
    Validatore.Free;
    Lista.Free;
  end;
end;

procedure TTestCollectionNotEmptyValidator.TListDiInteriVuota_NonEValido;
var
  Validatore: TCollectionNotEmptyValidator;
  Lista: TList<Integer>;
begin
  Validatore := TCollectionNotEmptyValidator.Create;
  Lista := TList<Integer>.Create;
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<TList<Integer>>(Lista)));
  finally
    Validatore.Free;
    Lista.Free;
  end;
end;

procedure TTestCollectionNotEmptyValidator.TDictionaryNonVuoto_EValido;
var
  Validatore: TCollectionNotEmptyValidator;
  Dizionario: TDictionary<string, Integer>;
begin
  Validatore := TCollectionNotEmptyValidator.Create;
  Dizionario := TDictionary<string, Integer>.Create;
  try
    Dizionario.Add('chiave', 1);
    Assert.IsTrue(Validatore.IsValid(TValue.From<TDictionary<string, Integer>>(Dizionario)));
  finally
    Validatore.Free;
    Dizionario.Free;
  end;
end;

procedure TTestCollectionNotEmptyValidator.TDictionaryVuoto_NonEValido;
var
  Validatore: TCollectionNotEmptyValidator;
  Dizionario: TDictionary<string, Integer>;
begin
  Validatore := TCollectionNotEmptyValidator.Create;
  Dizionario := TDictionary<string, Integer>.Create;
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<TDictionary<string, Integer>>(Dizionario)));
  finally
    Validatore.Free;
    Dizionario.Free;
  end;
end;

procedure TTestCollectionNotEmptyValidator.TStringListNonVuota_EValido;
var
  Validatore: TCollectionNotEmptyValidator;
  Lista: TStringList;
begin
  Validatore := TCollectionNotEmptyValidator.Create;
  Lista := TStringList.Create;
  try
    Lista.Add('uno');
    Assert.IsTrue(Validatore.IsValid(TValue.From<TStringList>(Lista)));
  finally
    Validatore.Free;
    Lista.Free;
  end;
end;

procedure TTestCollectionNotEmptyValidator.TStringListVuota_NonEValido;
var
  Validatore: TCollectionNotEmptyValidator;
  Lista: TStringList;
begin
  Validatore := TCollectionNotEmptyValidator.Create;
  Lista := TStringList.Create;
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<TStringList>(Lista)));
  finally
    Validatore.Free;
    Lista.Free;
  end;
end;

procedure TTestCollectionNotEmptyValidator.OggettoCollezioneNil_NonEValido;
var
  Validatore: TCollectionNotEmptyValidator;
  Lista: TStringList;
begin
  Validatore := TCollectionNotEmptyValidator.Create;
  Lista := nil;
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<TStringList>(Lista)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestCollectionNotEmptyValidator.OggettoSenzaProprietaCount_TornaValido_ComportamentoAttuale;
var
  Validatore: TCollectionNotEmptyValidator;
  Obj: TObject;
begin
  Validatore := TCollectionNotEmptyValidator.Create;
  Obj := TObject.Create;
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<TObject>(Obj)));
  finally
    Validatore.Free;
    Obj.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCollectionNotEmptyValidator);

end.
