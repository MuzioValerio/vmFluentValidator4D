{-----------------------------------------------------------------------------
 Project: FluentValidator - Test Suite
 Unit Name: Test.Engine.NestedAndForEach
 Purpose: Test delle funzionalita' di motore che compongono piu' validatori:
          - SetValidator: validazione di un oggetto nidificato con "appiattimento"
            degli errori figli e prefisso sul nome (es. Indirizzo.CAP).
          - RuleForEach: validazione di ogni elemento di una collezione, con
            nome indicizzato (es. Amici[1].Nome), sia con regole inline sia con
            un IValidator<TItem> dedicato via SetValidator.
          - CascadeMode (cmStop/cmContinue) a livello di regola e di validatore.
-----------------------------------------------------------------------------}

unit Test.Engine.NestedAndForEach;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils, System.Generics.Collections,
  FluentValidator.Validators,
  FluentValidator.NotEmptyValidator,
  FluentValidator,
  FluentValidator.Intf,
  Test.Fixtures;

type
  [TestFixture]
  TTestSetValidator = class
  private
    function IndirizzoValidator: IValidator<TIndirizzo>;
  public
    [Test] procedure NidificatoValido_ParentValido;
    [Test] procedure NidificatoNonValido_ErroreConPrefissoSulNome;
    [Test] procedure NidificatoNil_VieneSaltato;
  end;

  [TestFixture]
  TTestRuleForEach = class
  private
    function PersonaValidator: IValidator<TPersona>;
  public
    [Test] procedure RegolaInline_ElementoNonValido_NomeIndicizzato;
    [Test] procedure SetValidatorPerElemento_NomeIndicizzatoConSottoproprieta;
    [Test] procedure CollezioneVuota_EValido;
    [Test] procedure PiuElementiNonValidi_UnErrorePerElemento;
  end;

  [TestFixture]
  TTestCascadeMode = class
  public
    [Test] procedure CascadeStop_PerRegola_SiFermaAlPrimo;
    [Test] procedure CascadeContinue_PerRegola_RaccoglieTutti;
    [Test] procedure CascadeStop_Globale_SiFermaAllaPrimaRegola;
  end;

implementation

{ TTestSetValidator }

function TTestSetValidator.IndirizzoValidator: IValidator<TIndirizzo>;
var
  V: TValidator<TIndirizzo>;
begin
  V := TValidator<TIndirizzo>.Create;
  V.RuleFor<string>('Citta',
    function(I: TIndirizzo): string begin Result := I.Citta; end).NotEmpty;
  V.RuleFor<string>('CAP',
    function(I: TIndirizzo): string begin Result := I.CAP; end).NotEmpty;
  Result := V;
end;

procedure TTestSetValidator.NidificatoValido_ParentValido;
var V: TValidator<TPersona>; P: TPersona; Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<TIndirizzo>('Indirizzo',
      function(Per: TPersona): TIndirizzo begin Result := Per.Indirizzo; end)
      .SetValidator(IndirizzoValidator);
    P := TPersona.Create;
    try
      P.Indirizzo := TIndirizzo.Create;
      P.Indirizzo.Citta := 'Roma';
      P.Indirizzo.CAP := '00100';
      Esito := V.Validate(P);
      Assert.IsTrue(Esito.IsValid);
    finally P.Free; end;
  finally V.Free; end;
end;

procedure TTestSetValidator.NidificatoNonValido_ErroreConPrefissoSulNome;
var V: TValidator<TPersona>; P: TPersona; Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<TIndirizzo>('Indirizzo',
      function(Per: TPersona): TIndirizzo begin Result := Per.Indirizzo; end)
      .SetValidator(IndirizzoValidator);
    P := TPersona.Create;
    try
      P.Indirizzo := TIndirizzo.Create;
      P.Indirizzo.Citta := 'Roma';
      P.Indirizzo.CAP := ''; // viola NotEmpty nel validatore figlio
      Esito := V.Validate(P);
      Assert.IsFalse(Esito.IsValid);
      Assert.AreEqual(1, Integer(Length(Esito.Errors)));
      Assert.AreEqual('Indirizzo.CAP', Esito.Errors[0].PropertyName);
    finally P.Free; end;
  finally V.Free; end;
end;

procedure TTestSetValidator.NidificatoNil_VieneSaltato;
var V: TValidator<TPersona>; P: TPersona; Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<TIndirizzo>('Indirizzo',
      function(Per: TPersona): TIndirizzo begin Result := Per.Indirizzo; end)
      .SetValidator(IndirizzoValidator);
    P := TPersona.Create;
    try
      // Indirizzo non assegnato (nil): la validazione nidificata viene saltata,
      // non solleva eccezioni e non produce errori.
      Esito := V.Validate(P);
      Assert.IsTrue(Esito.IsValid);
    finally P.Free; end;
  finally V.Free; end;
end;

{ TTestRuleForEach }

function TTestRuleForEach.PersonaValidator: IValidator<TPersona>;
var
  V: TValidator<TPersona>;
begin
  V := TValidator<TPersona>.Create;
  V.RuleFor<string>('Nome',
    function(P: TPersona): string begin Result := P.Nome; end).NotEmpty;
  Result := V;
end;

procedure TTestRuleForEach.RegolaInline_ElementoNonValido_NomeIndicizzato;
var V: TValidator<TPersona>; P, A: TPersona; Esito: IValidationResult;
begin
  // Regola inline (NotEmpty) applicata a ogni elemento: un elemento oggetto
  // valido (non nil) passa, un elemento nil no. Il nome dell'errore e'
  // indicizzato: Amici[1].
  V := TValidator<TPersona>.Create;
  try
    V.RuleForEach<TPersona>('Amici',
      function(Per: TPersona): TEnumerable<TPersona> begin Result := Per.Amici; end)
      .NotEmpty;
    P := TPersona.Create;
    A := TPersona.Create;
    try
      P.Amici.Add(A);   // valido (oggetto non nil)
      P.Amici.Add(nil); // Amici[1] -> NotEmpty fallisce su oggetto nil
      Esito := V.Validate(P);
      Assert.IsFalse(Esito.IsValid);
      Assert.AreEqual(1, Integer(Length(Esito.Errors)));
      Assert.AreEqual('Amici[1]', Esito.Errors[0].PropertyName);
    finally A.Free; P.Free; end;
  finally V.Free; end;
end;

procedure TTestRuleForEach.SetValidatorPerElemento_NomeIndicizzatoConSottoproprieta;
var V: TValidator<TPersona>; P, A0, A1: TPersona; Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleForEach<TPersona>('Amici',
      function(Per: TPersona): TEnumerable<TPersona> begin Result := Per.Amici; end)
      .SetValidator(PersonaValidator);
    P := TPersona.Create;
    A0 := TPersona.Create;
    A1 := TPersona.Create;
    try
      A0.Nome := 'Anna';   // valido
      A1.Nome := '';       // viola NotEmpty -> Amici[1].Nome
      P.Amici.Add(A0);
      P.Amici.Add(A1);
      Esito := V.Validate(P);
      Assert.IsFalse(Esito.IsValid);
      Assert.AreEqual(1, Integer(Length(Esito.Errors)));
      Assert.AreEqual('Amici[1].Nome', Esito.Errors[0].PropertyName);
    finally A1.Free; A0.Free; P.Free; end;
  finally V.Free; end;
end;

procedure TTestRuleForEach.CollezioneVuota_EValido;
var V: TValidator<TPersona>; P: TPersona; Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleForEach<TPersona>('Amici',
      function(Per: TPersona): TEnumerable<TPersona> begin Result := Per.Amici; end)
      .SetValidator(PersonaValidator);
    P := TPersona.Create;
    try
      Esito := V.Validate(P); // Amici vuota
      Assert.IsTrue(Esito.IsValid);
    finally P.Free; end;
  finally V.Free; end;
end;

procedure TTestRuleForEach.PiuElementiNonValidi_UnErrorePerElemento;
var V: TValidator<TPersona>; P, A0, A1: TPersona; Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleForEach<TPersona>('Amici',
      function(Per: TPersona): TEnumerable<TPersona> begin Result := Per.Amici; end)
      .SetValidator(PersonaValidator);
    P := TPersona.Create;
    A0 := TPersona.Create;
    A1 := TPersona.Create;
    try
      A0.Nome := ''; // Amici[0].Nome
      A1.Nome := ''; // Amici[1].Nome
      P.Amici.Add(A0);
      P.Amici.Add(A1);
      Esito := V.Validate(P);
      Assert.IsFalse(Esito.IsValid);
      Assert.AreEqual(2, Integer(Length(Esito.Errors)));
      Assert.AreEqual('Amici[0].Nome', Esito.Errors[0].PropertyName);
      Assert.AreEqual('Amici[1].Nome', Esito.Errors[1].PropertyName);
    finally A1.Free; A0.Free; P.Free; end;
  finally V.Free; end;
end;

{ TTestCascadeMode }

procedure TTestCascadeMode.CascadeStop_PerRegola_SiFermaAlPrimo;
var V: TValidator<TPersona>; P: TPersona; Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<string>('Nome',
      function(Per: TPersona): string begin Result := Per.Nome; end)
      .NotEmpty
      .Length(2, 50)
      .Cascade(cmStop);
    P := TPersona.Create;
    try
      P.Nome := '';
      Esito := V.Validate(P);
      Assert.IsFalse(Esito.IsValid);
      Assert.AreEqual(1, Integer(Length(Esito.Errors))); // solo il primo errore
    finally P.Free; end;
  finally V.Free; end;
end;

procedure TTestCascadeMode.CascadeContinue_PerRegola_RaccoglieTutti;
var V: TValidator<TPersona>; P: TPersona; Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<string>('Nome',
      function(Per: TPersona): string begin Result := Per.Nome; end)
      .NotEmpty
      .Length(2, 50)
      .Cascade(cmContinue);
    P := TPersona.Create;
    try
      P.Nome := '';
      Esito := V.Validate(P);
      Assert.IsFalse(Esito.IsValid);
      Assert.AreEqual(2, Integer(Length(Esito.Errors))); // NotEmpty + Length
    finally P.Free; end;
  finally V.Free; end;
end;

procedure TTestCascadeMode.CascadeStop_Globale_SiFermaAllaPrimaRegola;
var V: TValidator<TPersona>; P: TPersona; Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create.Cascade(cmStop);
  try
    V.RuleFor<string>('Nome',
      function(Per: TPersona): string begin Result := Per.Nome; end).NotEmpty;
    V.RuleFor<string>('Cognome',
      function(Per: TPersona): string begin Result := Per.Cognome; end).NotEmpty;
    P := TPersona.Create;
    try
      P.Nome := '';
      P.Cognome := '';
      Esito := V.Validate(P);
      Assert.IsFalse(Esito.IsValid);
      Assert.AreEqual(1, Integer(Length(Esito.Errors)));
      Assert.AreEqual('Nome', Esito.Errors[0].PropertyName);
    finally P.Free; end;
  finally V.Free; end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestSetValidator);
  TDUnitX.RegisterTestFixture(TTestRuleForEach);
  TDUnitX.RegisterTestFixture(TTestCascadeMode);

end.
