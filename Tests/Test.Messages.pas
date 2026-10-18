{-----------------------------------------------------------------------------
 Project: FluentValidator - Test Suite
 Unit Name: Test.Messages
 Purpose: Test del catalogo messaggi e del registro lingue
          (FluentValidator.Messages / FluentValidator.Language.Italian).

          Coprono le tre cose che possono rompersi in silenzio:
          1) la lingua di default deve essere l'inglese, e l'italiano deve
             restare disponibile riproducendo i messaggi storici;
          2) la risoluzione della cultura (variante regionale, cultura
             sconosciuta, lingua parziale) deve sempre ricadere su qualcosa
             di leggibile, mai su stringa vuota;
          3) WithMessage deve accettare sia i segnaposto nominali nuovi sia
             il Format posizionale storico, perche' il secondo e' gia' usato
             dal codice esistente (vedi Examples/ e Test.Validators.*).

 ATTENZIONE: questi test modificano TValidationLanguages.Culture, che e'
 stato globale di processo. Setup/TearDown la salvano e la ripristinano, se
 no le altre fixture vedrebbero messaggi in una lingua inattesa a seconda
 dell'ordine di esecuzione.
-----------------------------------------------------------------------------}

unit Test.Messages;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  FluentValidator.Validators,
  FluentValidator,
  FluentValidator.Intf,
  FluentValidator.Messages,
  FluentValidator.Language.Italian,
  Test.Fixtures;

type
  // Lingua finta, volutamente incompleta: traduce solo NotEmpty. Serve a
  // verificare che le chiavi mancanti ricadano sull'inglese invece di
  // sparire.
  TLinguaParzialeDiProva = class(TValidationLanguage)
  protected
    procedure FillTemplates; override;
  end;

  [TestFixture]
  TTestMessages = class
  private
    FCultureOriginale: string;
    // Costruisce un validatore su TPersona.Nome con la regola richiesta e
    // restituisce il messaggio del primo errore.
    function PrimoErroreNotEmpty: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Default_LinguaInglese_MessaggioInInglese;
    [Test]
    procedure Culture_Italiano_RiproduceIlMessaggioStorico;
    [Test]
    procedure Culture_ConVarianteRegionale_RicadeSullaLinguaNeutra;
    [Test]
    procedure Culture_Sconosciuta_RicadeSullInglese;
    [Test]
    procedure Culture_Vuota_TornaAlDefaultInglese;
    [Test]
    procedure LinguaParziale_ChiaveMancante_RicadeSullInglese;
    [Test]
    procedure ChiaveSconosciuta_RestituisceLaChiaveStessa;
    [Test]
    procedure SegnapostoDelValidatore_VengonoSostituiti;
    [Test]
    procedure SegnapostoDelValidatore_SonoTradottiInItaliano;
    [Test]
    procedure WithMessage_ConSegnapostoNominali_SostituisceProprietaEArgomenti;
    [Test]
    procedure WithMessage_ConFormatPosizionale_ContinuaAFunzionare;
    [Test]
    procedure WithMessage_ConPercentoLetterale_NonSollevaSeUsaSegnaposto;
    [Test]
    procedure Args_ConValoriInteri_LiConvertePerIlTemplate;
  end;

implementation

const
  CulturaParziale = 'zz';

{ TLinguaParzialeDiProva }

procedure TLinguaParzialeDiProva.FillTemplates;
begin
  Add(TMsgKey.NotEmpty, 'ZZ {PropertyName} ZZ');
  // MaxLength e tutto il resto restano volutamente non tradotti.
end;

{ TTestMessages }

procedure TTestMessages.Setup;
begin
  FCultureOriginale := TValidationLanguages.Culture;
  if not TValidationLanguages.IsRegistered(CulturaParziale) then
    TValidationLanguages.RegisterLanguage(TLinguaParzialeDiProva.Create(CulturaParziale));
end;

procedure TTestMessages.TearDown;
begin
  TValidationLanguages.Culture := FCultureOriginale;
end;

function TTestMessages.PrimoErroreNotEmpty: string;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  P := TPersona.Create;
  try
    V.RuleFor<string>('Nome').NotEmpty;
    P.Nome := '';
    Esito := V.Validate(P);
    Assert.IsFalse(Esito.IsValid);
    Result := Esito.Errors[0].ErrorMessage;
  finally
    P.Free;
    V.Free;
  end;
end;

procedure TTestMessages.Default_LinguaInglese_MessaggioInInglese;
begin
  Assert.AreEqual('en', TValidationLanguages.Culture,
    'La lingua di default della libreria deve essere l''inglese');
  Assert.AreEqual('Nome must not be empty', PrimoErroreNotEmpty);
end;

procedure TTestMessages.Culture_Italiano_RiproduceIlMessaggioStorico;
begin
  TValidationLanguages.Culture := ItalianCulture;
  // Testo identico a quello emesso prima dell'internazionalizzazione.
  Assert.AreEqual('Nome non può essere vuoto', PrimoErroreNotEmpty);
end;

procedure TTestMessages.Culture_ConVarianteRegionale_RicadeSullaLinguaNeutra;
begin
  TValidationLanguages.Culture := 'it-IT';
  Assert.AreEqual('Nome non può essere vuoto', PrimoErroreNotEmpty,
    '"it-IT" deve risolversi sulla lingua neutra "it"');
end;

procedure TTestMessages.Culture_Sconosciuta_RicadeSullInglese;
begin
  TValidationLanguages.Culture := 'de-DE';
  Assert.AreEqual('Nome must not be empty', PrimoErroreNotEmpty,
    'Una cultura non registrata non deve far sparire il messaggio');
end;

procedure TTestMessages.Culture_Vuota_TornaAlDefaultInglese;
begin
  TValidationLanguages.Culture := ItalianCulture;
  TValidationLanguages.Culture := '';
  Assert.AreEqual('en', TValidationLanguages.Culture);
  Assert.AreEqual('Nome must not be empty', PrimoErroreNotEmpty);
end;

procedure TTestMessages.LinguaParziale_ChiaveMancante_RicadeSullInglese;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
begin
  TValidationLanguages.Culture := CulturaParziale;

  // Chiave presente nella lingua parziale.
  Assert.AreEqual('ZZ Nome ZZ', PrimoErroreNotEmpty);

  // Chiave assente: deve arrivare l'inglese, non una stringa vuota.
  V := TValidator<TPersona>.Create;
  P := TPersona.Create;
  try
    V.RuleFor<string>('Nome').MaxLength(3);
    P.Nome := 'Muzio';
    Esito := V.Validate(P);
    Assert.AreEqual('Nome must not exceed 3 characters', Esito.Errors[0].ErrorMessage);
  finally
    P.Free;
    V.Free;
  end;
end;

procedure TTestMessages.ChiaveSconosciuta_RestituisceLaChiaveStessa;
begin
  // Un messaggio nuovo non ancora tradotto in nessuna lingua deve restare
  // riconoscibile invece di risolversi in stringa vuota.
  Assert.AreEqual('ChiaveCheNonEsiste',
    TValidationLanguages.GetTemplate('ChiaveCheNonEsiste'));
end;

procedure TTestMessages.SegnapostoDelValidatore_VengonoSostituiti;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  P := TPersona.Create;
  try
    V.RuleFor<string>('Nome').Length(2, 4);
    P.Nome := 'Muzio';
    Esito := V.Validate(P);
    Assert.AreEqual('Nome must be between 2 and 4 characters long',
      Esito.Errors[0].ErrorMessage);
  finally
    P.Free;
    V.Free;
  end;
end;

procedure TTestMessages.SegnapostoDelValidatore_SonoTradottiInItaliano;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
begin
  TValidationLanguages.Culture := ItalianCulture;
  V := TValidator<TPersona>.Create;
  P := TPersona.Create;
  try
    V.RuleFor<Integer>('Eta').GreaterThan(18);
    P.Eta := 10;
    Esito := V.Validate(P);
    Assert.AreEqual('Eta deve essere maggiore di 18', Esito.Errors[0].ErrorMessage);
  finally
    P.Free;
    V.Free;
  end;
end;

procedure TTestMessages.WithMessage_ConSegnapostoNominali_SostituisceProprietaEArgomenti;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  P := TPersona.Create;
  try
    // I segnaposto del validatore sono disponibili anche in WithMessage.
    V.RuleFor<string>('Nome').MaxLength(3)
      .WithMessage('{PropertyName}: al massimo {MaxLength} caratteri');
    P.Nome := 'Muzio';
    Esito := V.Validate(P);
    Assert.AreEqual('Nome: al massimo 3 caratteri', Esito.Errors[0].ErrorMessage);
  finally
    P.Free;
    V.Free;
  end;
end;

procedure TTestMessages.WithMessage_ConFormatPosizionale_ContinuaAFunzionare;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  P := TPersona.Create;
  try
    // Forma storica: un solo %s, sostituito col nome della proprieta'.
    V.RuleFor<string>('Nome').NotEmpty.WithMessage('Il campo %s e'' obbligatorio');
    P.Nome := '';
    Esito := V.Validate(P);
    Assert.AreEqual('Il campo Nome e'' obbligatorio', Esito.Errors[0].ErrorMessage);
  finally
    P.Free;
    V.Free;
  end;
end;

procedure TTestMessages.WithMessage_ConPercentoLetterale_NonSollevaSeUsaSegnaposto;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  P := TPersona.Create;
  try
    // Con il Format posizionale un % letterale solleva; con i segnaposto
    // nominali no. E' il motivo per cui la forma nuova e' quella consigliata.
    V.RuleFor<Double>('Percentuale').GreaterThan(0)
      .WithMessage('{PropertyName} deve superare lo 0%');
    P.Percentuale := 0;
    Esito := V.Validate(P);
    Assert.AreEqual('Percentuale deve superare lo 0%', Esito.Errors[0].ErrorMessage);
  finally
    P.Free;
    V.Free;
  end;
end;

procedure TTestMessages.Args_ConValoriInteri_LiConvertePerIlTemplate;
begin
  Assert.AreEqual('da 2 a 7',
    TValidationMessages.Render('da {Min} a {Max}',
      TValidationMessages.Args(['Min', 2, 'Max', 7])));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMessages);

end.
