{-----------------------------------------------------------------------------
 Project: FluentValidator - Test Suite
 Unit Name: Test.WhenUnless
 Purpose: Test di NON REGRESSIONE per i bug piu' insidiosi corretti nel motore:
          1) "When/Unless non avevano alcun effetto" (la condizione non veniva
             mai valutata) -> ora deve esserlo, in entrambe le direzioni.
          2) GUID duplicato fra IConditionalValidator e IPropertyValidator,
             che rendeva ambiguo Supports() per QUALSIASI validatore, non solo
             per When/Unless -> un validatore non condizionale deve continuare
             a funzionare normalmente quando e' mescolato con uno condizionale
             nella stessa catena di regole.
          3) Semantica "sticky" di FCurrentCondition, documentata ma non
             "risolta" di proposito (cambierebbe l'API): una volta chiamato
             .When(...)/.Unless(...), la condizione resta attiva per TUTTE le
             regole successive ALLA SUA chiamata nella stessa RuleFor, non solo
             per la regola immediatamente seguente. Questo test fissa il
             comportamento ATTUALE: se in futuro si decide di cambiarlo,
             questo test andra' aggiornato consapevolmente, non per errore.

 IMPORTANTE SULL'ORDINE DI CHIAMATA (vedi FluentValidator.pas, AddValidator):
 .When/.Unless impostano FCurrentCondition, ma NON avvolgono retroattivamente
 i validatori GIA' aggiunti alla catena: solo i validatori aggiunti DOPO la
 chiamata a .When/.Unless vengono avvolti in un TWhen/TUnless. La forma
 corretta per condizionare una regola e' quindi:
     .When(condizione).NotEmpty        // NotEmpty viene condizionata
 e NON:
     .NotEmpty.When(condizione)        // NotEmpty e' GIA' stata aggiunta,
                                        // quindi NON viene condizionata
 Questo e' anche il pattern usato in Examples/Example3_VerificaModifiche.dpr
 (".When(...).Equal(0)").
-----------------------------------------------------------------------------}

unit Test.WhenUnless;

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
  TTestWhenUnless = class
  public
    [Test]
    procedure When_ConCondizioneVera_LaRegolaVieneEseguita;
    [Test]
    procedure When_ConCondizioneFalsa_LaRegolaVieneSaltata;
    [Test]
    procedure Unless_ConCondizioneVera_LaRegolaVieneSaltata;
    [Test]
    procedure Unless_ConCondizioneFalsa_LaRegolaVieneEseguita;
    [Test]
    procedure When_LaCondizioneRiceveLEntitaCorretta_NonSoltantoLaProprieta;
    [Test]
    procedure ValidatoreNonCondizionale_MescolatoConWhen_ContinuaAFunzionareNormalmente;
    [Test]
    procedure ValidatoreAggiuntoPrimaDelWhen_NonVieneMaiCondizionato;
    [Test]
    procedure When_ComportamentoSticky_SiApplicaAncheAlleRegoleSuccessiveNellaStessaCatena;
    [Test]
    procedure When_NonInfluenzaUnaRuleForDiversaPerUnaAltraProprieta;
  end;

implementation

{ TTestWhenUnless }

procedure TTestWhenUnless.When_ConCondizioneVera_LaRegolaVieneEseguita;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<string>('Email',
      function(Persona: TPersona): string begin Result := Persona.Email; end)
      .When(function(Persona: TPersona): Boolean begin Result := Persona.Eta >= 18; end)
      .NotEmpty;

    P := TPersona.Create;
    try
      P.Eta := 30;     // condizione vera -> la regola NotEmpty deve essere applicata
      P.Email := '';
      Esito := V.Validate(P);
      Assert.IsFalse(Esito.IsValid, 'Con condizione vera, NotEmpty deve fallire su email vuota');
    finally
      P.Free;
    end;
  finally
    V.Free;
  end;
end;

procedure TTestWhenUnless.When_ConCondizioneFalsa_LaRegolaVieneSaltata;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<string>('Email',
      function(Persona: TPersona): string begin Result := Persona.Email; end)
      .When(function(Persona: TPersona): Boolean begin Result := Persona.Eta >= 18; end)
      .NotEmpty;

    P := TPersona.Create;
    try
      P.Eta := 10;     // condizione falsa -> la regola NotEmpty NON deve essere applicata
      P.Email := '';
      Esito := V.Validate(P);
      Assert.IsTrue(Esito.IsValid,
        'Con condizione falsa, NotEmpty non deve essere valutata anche se la email e'' vuota');
    finally
      P.Free;
    end;
  finally
    V.Free;
  end;
end;

procedure TTestWhenUnless.Unless_ConCondizioneVera_LaRegolaVieneSaltata;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    // Unless(cond) == When(not cond): se Stato e' soBozza, la validazione
    // dell'importo non si applica (un ordine in bozza puo' non avere ancora un importo).
    V.RuleFor<Currency>('Importo',
      function(Persona: TPersona): Currency begin Result := Persona.Importo; end)
      .Unless(function(Persona: TPersona): Boolean begin Result := Persona.Stato = soBozza; end)
      .GreaterThan(0);

    P := TPersona.Create;
    try
      P.Stato := soBozza;
      P.Importo := 0;
      Esito := V.Validate(P);
      Assert.IsTrue(Esito.IsValid, 'In bozza, GreaterThan(0) non deve essere valutata');
    finally
      P.Free;
    end;
  finally
    V.Free;
  end;
end;

procedure TTestWhenUnless.Unless_ConCondizioneFalsa_LaRegolaVieneEseguita;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<Currency>('Importo',
      function(Persona: TPersona): Currency begin Result := Persona.Importo; end)
      .Unless(function(Persona: TPersona): Boolean begin Result := Persona.Stato = soBozza; end)
      .GreaterThan(0);

    P := TPersona.Create;
    try
      P.Stato := soConfermato;   // non e' una bozza -> Unless(False) -> la regola SI applica
      P.Importo := 0;
      Esito := V.Validate(P);
      Assert.IsFalse(Esito.IsValid, 'Se confermato, GreaterThan(0) deve essere valutata e fallire su 0');
    finally
      P.Free;
    end;
  finally
    V.Free;
  end;
end;

procedure TTestWhenUnless.When_LaCondizioneRiceveLEntitaCorretta_NonSoltantoLaProprieta;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
  CondizioneVistaConEta: Integer;
begin
  // Verifica che la closure passata a .When riceva l'intera entity (TPersona),
  // non un valore derivato dalla sola proprieta' sotto regola: leggiamo un
  // campo (Eta) diverso da quello validato (Email) dentro la condizione.
  CondizioneVistaConEta := -1;
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<string>('Email',
      function(Persona: TPersona): string begin Result := Persona.Email; end)
      .When(
        function(Persona: TPersona): Boolean
        begin
          CondizioneVistaConEta := Persona.Eta;
          Result := Persona.Eta >= 18;
        end)
      .NotEmpty;

    P := TPersona.Create;
    try
      P.Eta := 42;
      P.Email := 'qualcosa@esempio.it';
      Esito := V.Validate(P);
      Assert.AreEqual(42, CondizioneVistaConEta);
    finally
      P.Free;
    end;
  finally
    V.Free;
  end;
end;

procedure TTestWhenUnless.ValidatoreNonCondizionale_MescolatoConWhen_ContinuaAFunzionareNormalmente;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
begin
  // Regression test specifico per il bug del GUID duplicato: una regola su
  // un'ALTRA proprieta', completamente non condizionale, deve continuare a
  // funzionare correttamente anche quando nel validatore e' presente (su
  // un'altra regola) un validatore condizionale (TWhen). Se il GUID fosse
  // ancora duplicato, Supports(Validator, IConditionalValidator, ...) sarebbe
  // ambiguo per QUALSIASI IPropertyValidator, comportamento indefinito incluso.
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<string>('Email',
      function(Persona: TPersona): string begin Result := Persona.Email; end)
      .When(function(Persona: TPersona): Boolean begin Result := Persona.Eta >= 18; end)
      .NotEmpty;

    V.RuleFor<string>('Nome',
      function(Persona: TPersona): string begin Result := Persona.Nome; end)
      .NotEmpty;   // nessuna condizione: deve sempre essere valutata

    P := TPersona.Create;
    try
      P.Eta := 10;          // condizione del primo gruppo falsa: Email non valutata
      P.Email := '';
      P.Nome := '';         // ma Nome deve comunque fallire NotEmpty
      Esito := V.Validate(P);
      Assert.IsFalse(Esito.IsValid);
      Assert.AreEqual(1, Integer(Length(Esito.Errors)));
      Assert.AreEqual('Nome', Esito.Errors[0].PropertyName);
    finally
      P.Free;
    end;
  finally
    V.Free;
  end;
end;

procedure TTestWhenUnless.ValidatoreAggiuntoPrimaDelWhen_NonVieneMaiCondizionato;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
begin
  // NotNull viene aggiunto PRIMA che .When sia chiamato sulla stessa catena:
  // FCurrentCondition non era ancora impostata quando NotNull e' stato
  // aggiunto, quindi NotNull non deve mai essere wrappato in un TWhen, a
  // prescindere dalla condizione impostata dopo di lui per le regole successive.
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<string>('Nome',
      function(Persona: TPersona): string begin Result := Persona.Nome; end)
      .NotNull
      .When(function(Persona: TPersona): Boolean begin Result := False; end)
      .NotEmpty;

    P := TPersona.Create;
    try
      P.Nome := '';   // NotNull passa (stringa vuota non e' nil; aggiunto prima
                       // del When, quindi sempre valutato). NotEmpty fallirebbe,
                       // ma e' "dopo" il When con condizione sempre falsa,
                       // quindi viene saltata.
      Esito := V.Validate(P);
      Assert.IsTrue(Esito.IsValid,
        'NotNull (prima del When) passa comunque; NotEmpty (dopo, sotto When falso) viene saltata');
    finally
      P.Free;
    end;
  finally
    V.Free;
  end;
end;

procedure TTestWhenUnless.When_ComportamentoSticky_SiApplicaAncheAlleRegoleSuccessiveNellaStessaCatena;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
begin
  // Comportamento ATTUALE e DOCUMENTATO (vedi "Comportamenti noti e trappole"
  // nel README):
  // FCurrentCondition non viene azzerata dopo il primo uso, quindi sia
  // NotEmpty sia Length(2,50), entrambe aggiunte DOPO .When in questa stessa
  // catena, ereditano la stessa condizione (qui sempre falsa).
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<string>('Nome',
      function(Persona: TPersona): string begin Result := Persona.Nome; end)
      .When(function(Persona: TPersona): Boolean begin Result := False; end)
      .NotEmpty
      .Length(2, 50);   // eredita la stessa condizione (sempre falsa) di NotEmpty

    P := TPersona.Create;
    try
      P.Nome := '';   // violerebbe sia NotEmpty sia Length(2,50)
      Esito := V.Validate(P);
      // Se la condizione fosse correttamente "sticky" (comportamento attuale),
      // sia NotEmpty sia Length(2,50) vengono saltate perche' la condizione e'
      // sempre falsa.
      Assert.IsTrue(Esito.IsValid,
        'Comportamento sticky attuale: la condizione del When si propaga anche a Length');
    finally
      P.Free;
    end;
  finally
    V.Free;
  end;
end;

procedure TTestWhenUnless.When_NonInfluenzaUnaRuleForDiversaPerUnaAltraProprieta;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
begin
  // FCurrentCondition e' un campo di istanza del singolo TRuleBuilder (uno per
  // ogni chiamata RuleFor): una condizione impostata in una RuleFor non deve
  // in alcun modo "fuoriuscire" verso un'altra RuleFor, anche se chiamata
  // immediatamente dopo sullo stesso TValidator<T>.
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<string>('Nome',
      function(Persona: TPersona): string begin Result := Persona.Nome; end)
      .When(function(Persona: TPersona): Boolean begin Result := False; end)
      .NotEmpty;

    V.RuleFor<string>('Cognome',
      function(Persona: TPersona): string begin Result := Persona.Cognome; end)
      .NotEmpty;   // RuleFor diversa: non deve essere condizionata dal When sopra

    P := TPersona.Create;
    try
      P.Nome := '';      // condizione falsa -> NotEmpty su Nome saltata
      P.Cognome := '';   // nessuna condizione -> NotEmpty su Cognome deve fallire
      Esito := V.Validate(P);
      Assert.IsFalse(Esito.IsValid);
      Assert.AreEqual(1, Integer(Length(Esito.Errors)));
      Assert.AreEqual('Cognome', Esito.Errors[0].PropertyName);
    finally
      P.Free;
    end;
  finally
    V.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWhenUnless);

end.
