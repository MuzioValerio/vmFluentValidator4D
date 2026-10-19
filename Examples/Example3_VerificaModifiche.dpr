{-----------------------------------------------------------------------------
 Project: FluentValidator
 Unit Name: Example3_VerificaModifiche
 Purpose: Verifica end-to-end di tutte le correzioni applicate a FluentValidator
          (sessioni del 28-29 giugno 2026). Ogni sezione isola una correzione
          specifica e dichiara il risultato atteso, per poterla confrontare
          rapidamente con l'output a console.
-----------------------------------------------------------------------------}

program Example3_VerificaModifiche;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Rtti,
  System.TypInfo,
  FluentValidator.Intf,
  FluentValidator,
  FluentValidator.Messages,
  FluentValidator.Validators,
  FluentValidator.EnumConverter;

type
  TRegimeFiscale = (rfOrdinario, rfForfettario, rfMinimi);

  TCedentePrestatore = class
  public
    Denominazione: string;
  end;

  TRigaFattura = class
  public
    Descrizione: string;
    Quantita: Integer;
    PrezzoUnitario: Currency;
  end;

  TFatturaTestata = class
  public
    NomeCliente: string;
    PartitaIVA: string;
    Email: string;
    DataEmissione: TDateTime;
    Importo: Currency;
    RegimeFiscale: TRegimeFiscale;
    ScontoPercentuale: Integer;
    CedentePrestatore: TCedentePrestatore;
    Righe: TObjectList<TRigaFattura>;
    constructor Create;
    destructor Destroy; override;
  end;

  TFatturaTestataValidator = class(TValidator<TFatturaTestata>)
  public
    constructor Create;
  end;

constructor TFatturaTestata.Create;
begin
  inherited Create;
  Righe := TObjectList<TRigaFattura>.Create(True);
end;

destructor TFatturaTestata.Destroy;
begin
  Righe.Free;
  CedentePrestatore.Free;
  inherited;
end;

constructor TFatturaTestataValidator.Create;
begin
  inherited Create;

  // Verifica fix NotNull su proprietà oggetto nil
  RuleFor<TCedentePrestatore>('CedentePrestatore',
    function(F: TFatturaTestata): TCedentePrestatore
    begin
      Result := F.CedentePrestatore;
    end)
    .NotNull;

  // Verifica fix StartsWithUpperCase (lettere accentate)
  RuleFor<string>('NomeCliente',
    function(F: TFatturaTestata): string
    begin
      Result := F.NomeCliente;
    end)
    .NotEmpty
    .StartsWithUpperCase;

  // Verifica fix NotEmpty su Currency = 0 + supporto Currency nei validatori numerici
  RuleFor<Currency>('Importo',
    function(F: TFatturaTestata): Currency
    begin
      Result := F.Importo;
    end)
    .NotEmpty
    .GreaterThan(0);

  RuleFor<string>('PartitaIVA',
    function(F: TFatturaTestata): string
    begin
      Result := F.PartitaIVA;
    end)
    .Length(11, 11);

  RuleFor<string>('Email',
    function(F: TFatturaTestata): string
    begin
      Result := F.Email;
    end)
    .Email;

  // Verifica fix CollectionNotEmpty generalizzato (TObjectList<TRigaFattura>, non TObject)
  RuleFor<TObjectList<TRigaFattura>>('Righe',
    function(F: TFatturaTestata): TObjectList<TRigaFattura>
    begin
      Result := F.Righe;
    end)
    .NotEmptyCollection;

  // Verifica fix Trunc su MustBeInPast (deterministico per "oggi")
  RuleFor<TDateTime>('DataEmissione',
    function(F: TFatturaTestata): TDateTime
    begin
      Result := F.DataEmissione;
    end)
    .MustBeInPast(False);

  // Verifica fix When (e indirettamente il fix del GUID duplicato): la regola
  // si deve applicare solo se RegimeFiscale = rfForfettario
  RuleFor<Integer>('ScontoPercentuale',
    function(F: TFatturaTestata): Integer
    begin
      Result := F.ScontoPercentuale;
    end)
    .When(
      function(F: TFatturaTestata): Boolean
      begin
        Result := F.RegimeFiscale = rfForfettario;
      end)
    .Equal(0)
    .WithMessage('In regime forfettario non sono ammessi sconti (%s deve essere 0)');
end;

// ----------------------------------------------------------------------------
// Helper di stampa
// ----------------------------------------------------------------------------

procedure StampaEsito(const Descrizione: string; AttesoValido, OttenutoValido: Boolean);
const
  Esiti: array[Boolean] of string = ('NO', 'SI');
begin
  Write(Descrizione, ' -> atteso: ', Esiti[AttesoValido], ', ottenuto: ', Esiti[OttenutoValido]);
  if AttesoValido = OttenutoValido then
    WriteLn('  [OK]')
  else
    WriteLn('  [DIFFORME - controllare]');
end;

procedure StampaErrori(const Result: IValidationResult);
var
  Error: IValidationError;
begin
  if not Result.IsValid then
    for Error in Result.Errors do
      WriteLn('    ', Error.PropertyName, ': ', Error.ErrorMessage);
end;

// ----------------------------------------------------------------------------
// PARTE A - Verifiche isolate sui singoli validatori (chiamata diretta a IsValid)
// ----------------------------------------------------------------------------

procedure VerificheIsolate;
var
  NotNullValidator: TNotNull;
  NotEmptyValidator: TNotEmpty;
  CollectionValidator: TCollectionNotEmpty;
  EnumValidator: TEnumVal;
  PastValidator: TMustBeInPast;
  FutureValidator: TMustBeInFuture;
  UpperCaseValidator: TStartsWithUpperCase;
  NilCedente: TCedentePrestatore;
  ListaIntInt: TObjectList<TRigaFattura>;
  ArrayDouble: TArray<Double>;
  Oggi: TDateTime;
begin
  WriteLn('=== PARTE A - Verifiche isolate sui singoli validatori ===');
  WriteLn;

  // --- Fix NotNull: riferimento a oggetto nil ---
  NilCedente := nil;
  NotNullValidator := TNotNull.Create;
  try
    StampaEsito('NotNull su oggetto nil', False,
      NotNullValidator.IsValid(TValue.From<TCedentePrestatore>(NilCedente)));
  finally
    NotNullValidator.Free;
  end;

  // --- Fix NotEmpty: Integer/Currency a zero e oggetto nil ---
  NotEmptyValidator := TNotEmpty.Create;
  try
    StampaEsito('NotEmpty su Integer = 0', False,
      NotEmptyValidator.IsValid(TValue.From<Integer>(0)));
    StampaEsito('NotEmpty su Integer = 5', True,
      NotEmptyValidator.IsValid(TValue.From<Integer>(5)));
    StampaEsito('NotEmpty su Currency = 0', False,
      NotEmptyValidator.IsValid(TValue.From<Currency>(0)));
    StampaEsito('NotEmpty su stringa solo spazi', False,
      NotEmptyValidator.IsValid(TValue.From<string>('   ')));
    StampaEsito('NotEmpty su oggetto nil', False,
      NotEmptyValidator.IsValid(TValue.From<TCedentePrestatore>(NilCedente)));
  finally
    NotEmptyValidator.Free;
  end;
  WriteLn;

  // --- Fix CollectionNotEmpty: generalizzazione RTTI (non solo TList<TObject>) ---
  CollectionValidator := TCollectionNotEmpty.Create;
  try
    ListaIntInt := TObjectList<TRigaFattura>.Create(True);
    try
      StampaEsito('CollectionNotEmpty su TObjectList<TRigaFattura> vuota', False,
        CollectionValidator.IsValid(TValue.From<TObjectList<TRigaFattura>>(ListaIntInt)));

      ListaIntInt.Add(TRigaFattura.Create);
      StampaEsito('CollectionNotEmpty su TObjectList<TRigaFattura> con 1 elemento', True,
        CollectionValidator.IsValid(TValue.From<TObjectList<TRigaFattura>>(ListaIntInt)));
    finally
      ListaIntInt.Free;
    end;

    SetLength(ArrayDouble, 0);
    StampaEsito('CollectionNotEmpty su TArray<Double> vuoto', False,
      CollectionValidator.IsValid(TValue.From<TArray<Double>>(ArrayDouble)));

    SetLength(ArrayDouble, 3);
    StampaEsito('CollectionNotEmpty su TArray<Double> con 3 elementi', True,
      CollectionValidator.IsValid(TValue.From<TArray<Double>>(ArrayDouble)));
  finally
    CollectionValidator.Free;
  end;
  WriteLn;

  // --- Fix EnumValidator: IsEnumValue/IsEnumName non esistevano, ora compila ---
  EnumValidator := TEnumVal.Create(TypeInfo(TRegimeFiscale));
  try
    StampaEsito('IsInEnum su Integer valido (Ord(rfMinimi))', True,
      EnumValidator.IsValid(TValue.From<Integer>(Ord(rfMinimi))));
    StampaEsito('IsInEnum su Integer fuori range (99)', False,
      EnumValidator.IsValid(TValue.From<Integer>(99)));
    StampaEsito('IsInEnum su stringa valida case-insensitive (''RFFORFETTARIO'')', True,
      EnumValidator.IsValid(TValue.From<string>('RFFORFETTARIO')));
    StampaEsito('IsInEnum su stringa inesistente', False,
      EnumValidator.IsValid(TValue.From<string>('NonEsiste')));
  finally
    EnumValidator.Free;
  end;
  WriteLn;

  // --- Fix Trunc su MustBeInPast/MustBeInFuture: deterministico per "oggi" ---
  Oggi := Trunc(Now); // data pura, ora = 00:00, indipendentemente da quando si esegue il test
  PastValidator := TMustBeInPast.Create(False);
  try
    StampaEsito('MustBeInPast(IncludeToday=False) su data di oggi', False,
      PastValidator.IsValid(TValue.From<TDateTime>(Oggi)));
  finally
    PastValidator.Free;
  end;

  PastValidator := TMustBeInPast.Create(True);
  try
    StampaEsito('MustBeInPast(IncludeToday=True) su data di oggi', True,
      PastValidator.IsValid(TValue.From<TDateTime>(Oggi)));
  finally
    PastValidator.Free;
  end;

  FutureValidator := TMustBeInFuture.Create(False);
  try
    StampaEsito('MustBeInFuture(IncludeToday=False) su data di oggi', False,
      FutureValidator.IsValid(TValue.From<TDateTime>(Oggi)));
  finally
    FutureValidator.Free;
  end;

  FutureValidator := TMustBeInFuture.Create(True);
  try
    StampaEsito('MustBeInFuture(IncludeToday=True) su data di oggi', True,
      FutureValidator.IsValid(TValue.From<TDateTime>(Oggi)));
  finally
    FutureValidator.Free;
  end;
  WriteLn;

  // --- Fix StartsWithUpperCase: lettere accentate ---
  UpperCaseValidator := TStartsWithUpperCase.Create;
  try
    StampaEsito('StartsWithUpperCase su ''Élise''', True,
      UpperCaseValidator.IsValid(TValue.From<string>('Élise')));
    StampaEsito('StartsWithUpperCase su ''Òscar''', True,
      UpperCaseValidator.IsValid(TValue.From<string>('Òscar')));
    StampaEsito('StartsWithUpperCase su ''mario'' (minuscolo)', False,
      UpperCaseValidator.IsValid(TValue.From<string>('mario')));
  finally
    UpperCaseValidator.Free;
  end;
  WriteLn;

  // --- TEnumConverter (contributo di Muzio, integrato con il fix su nome non valido) ---
  WriteLn('TEnumConverter.EnumToString(rfForfettario) = ', TEnumConverter.EnumToString<TRegimeFiscale>(rfForfettario));

  var ValoreConvertito: TRegimeFiscale;
  StampaEsito('TryStringToEnum su nome valido (''rfMinimi'')', True,
    TEnumConverter.TryStringToEnum<TRegimeFiscale>('rfMinimi', ValoreConvertito));
  StampaEsito('TryStringToEnum su nome NON valido (''NonEsiste'')', False,
    TEnumConverter.TryStringToEnum<TRegimeFiscale>('NonEsiste', ValoreConvertito));

  try
    TEnumConverter.StringToEnum<TRegimeFiscale>('NonEsiste');
    WriteLn('StringToEnum su nome non valido -> atteso: eccezione, ottenuto: NESSUNA  [DIFFORME - controllare]');
  except
    on E: EArgumentException do
      WriteLn('StringToEnum su nome non valido -> atteso: eccezione, ottenuto: ', E.ClassName, '  [OK]');
  end;
  WriteLn;
end;

// ----------------------------------------------------------------------------
// PARTE B - Scenario end-to-end realistico (RuleFor completo, come nel progetto)
// ----------------------------------------------------------------------------

procedure ScenarioEndToEnd;
var
  Validator: IValidator<TFatturaTestata>;
  Fattura: TFatturaTestata;
  Result: IValidationResult;
begin
  WriteLn('=== PARTE B - Scenario end-to-end (TFatturaTestataValidator) ===');
  WriteLn;

  Validator := TFatturaTestataValidator.Create;

  // Caso 1: fattura completamente valida
  Fattura := TFatturaTestata.Create;
  try
    Fattura.CedentePrestatore := TCedentePrestatore.Create;
    Fattura.NomeCliente := 'Élise Dupont';
    Fattura.Importo := 150.00;
    Fattura.PartitaIVA := '12345678901';
    Fattura.Email := 'cliente@example.com';
    Fattura.RegimeFiscale := rfOrdinario;
    Fattura.ScontoPercentuale := 10; // ammesso: regime ordinario, When non si applica
    Fattura.DataEmissione := Trunc(Now) - 1; // ieri
    Fattura.Righe.Add(TRigaFattura.Create);

    Result := Validator.Validate(Fattura);
    StampaEsito('Caso 1 - fattura valida', True, Result.IsValid);
    StampaErrori(Result);
  finally
    Fattura.Free;
  end;
  WriteLn;

  // Caso 2: CedentePrestatore non assegnato (fix NotNull su oggetto nil)
  Fattura := TFatturaTestata.Create;
  try
    Fattura.NomeCliente := 'Mario Rossi';
    Fattura.Importo := 100.00;
    Fattura.PartitaIVA := '12345678901';
    Fattura.Email := 'mario@example.com';
    Fattura.DataEmissione := Trunc(Now) - 1;
    Fattura.Righe.Add(TRigaFattura.Create);
    // Fattura.CedentePrestatore resta nil

    Result := Validator.Validate(Fattura);
    StampaEsito('Caso 2 - CedentePrestatore nil', False, Result.IsValid);
    StampaErrori(Result);
  finally
    Fattura.Free;
  end;
  WriteLn;

  // Caso 3: Importo a zero (fix NotEmpty su Currency = 0) + righe vuote
  // (fix CollectionNotEmpty generalizzato su TObjectList<TRigaFattura>)
  Fattura := TFatturaTestata.Create;
  try
    Fattura.CedentePrestatore := TCedentePrestatore.Create;
    Fattura.NomeCliente := 'Mario Rossi';
    Fattura.Importo := 0;
    Fattura.PartitaIVA := '12345678901';
    Fattura.Email := 'mario@example.com';
    Fattura.DataEmissione := Trunc(Now) - 1;
    // Fattura.Righe resta vuota

    Result := Validator.Validate(Fattura);
    StampaEsito('Caso 3 - Importo zero e righe vuote', False, Result.IsValid);
    StampaErrori(Result);
  finally
    Fattura.Free;
  end;
  WriteLn;

  // Caso 4: DataEmissione = oggi, con MustBeInPast(IncludeToday=False)
  // (fix Trunc: deve fallire sempre, a prescindere dall'orario di esecuzione)
  Fattura := TFatturaTestata.Create;
  try
    Fattura.CedentePrestatore := TCedentePrestatore.Create;
    Fattura.NomeCliente := 'Mario Rossi';
    Fattura.Importo := 100.00;
    Fattura.PartitaIVA := '12345678901';
    Fattura.Email := 'mario@example.com';
    Fattura.DataEmissione := Trunc(Now); // oggi, ora 00:00
    Fattura.Righe.Add(TRigaFattura.Create);

    Result := Validator.Validate(Fattura);
    StampaEsito('Caso 4 - DataEmissione = oggi', False, Result.IsValid);
    StampaErrori(Result);
  finally
    Fattura.Free;
  end;
  WriteLn;

  // Caso 5: regime forfettario con sconto > 0 (la regola Equal(0) DEVE applicarsi:
  // verifica il fix When + indirettamente il fix del GUID duplicato)
  Fattura := TFatturaTestata.Create;
  try
    Fattura.CedentePrestatore := TCedentePrestatore.Create;
    Fattura.NomeCliente := 'Mario Rossi';
    Fattura.Importo := 100.00;
    Fattura.PartitaIVA := '12345678901';
    Fattura.Email := 'mario@example.com';
    Fattura.DataEmissione := Trunc(Now) - 1;
    Fattura.Righe.Add(TRigaFattura.Create);
    Fattura.RegimeFiscale := rfForfettario;
    Fattura.ScontoPercentuale := 5; // non ammesso in regime forfettario

    Result := Validator.Validate(Fattura);
    StampaEsito('Caso 5 - sconto non ammesso in regime forfettario', False, Result.IsValid);
    StampaErrori(Result);
  finally
    Fattura.Free;
  end;
  WriteLn;

  // Caso 6: stesso sconto (5), ma regime ordinario: la regola Equal(0) NON deve
  // applicarsi (When con condizione falsa). Prima del fix, .When non aveva alcun
  // effetto e questa regola sarebbe sempre stata eseguita.
  Fattura := TFatturaTestata.Create;
  try
    Fattura.CedentePrestatore := TCedentePrestatore.Create;
    Fattura.NomeCliente := 'Mario Rossi';
    Fattura.Importo := 100.00;
    Fattura.PartitaIVA := '12345678901';
    Fattura.Email := 'mario@example.com';
    Fattura.DataEmissione := Trunc(Now) - 1;
    Fattura.Righe.Add(TRigaFattura.Create);
    Fattura.RegimeFiscale := rfOrdinario;
    Fattura.ScontoPercentuale := 5; // ammesso: il When non si applica in regime ordinario

    Result := Validator.Validate(Fattura);
    StampaEsito('Caso 6 - sconto ammesso in regime ordinario (When inattivo)', True, Result.IsValid);
    StampaErrori(Result);
  finally
    Fattura.Free;
  end;
  WriteLn;
end;

begin
  try
    VerificheIsolate;
    ScenarioEndToEnd;
    WriteLn;
  except
    on E: Exception do
    begin
      WriteLn(E.ClassName, ': ', E.Message);
      ReadLn;
    end;
  end;
  WriteLn('Premi INVIO per uscire...');
  ReadLn;
end.
