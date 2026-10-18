{-----------------------------------------------------------------------------
 Project: FluentValidator - Test Suite
 Unit Name: Test.Core
 Purpose: Test del motore di validazione (TRuleBuilder<T,TProp> / TValidator<T>),
          indipendenti dai singoli validatori built-in:
          - accumulo di piu' regole sulla stessa proprieta'
          - StopOnFirstFailure a livello di singola regola
          - StopOnFirstFailure a livello globale del validatore
          - override del messaggio con WithMessage
          - IValidationResult (IsValid, Errors, AddError)
          - validazione su piu' proprieta' contemporaneamente
-----------------------------------------------------------------------------}

unit Test.Core;

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
  TTestCore = class
  public
    [Test]
    procedure RuleFor_SingolaRegolaValida_NonProduceErrori;
    [Test]
    procedure RuleFor_SingolaRegolaNonValida_ProduceUnErrore;
    [Test]
    procedure RuleFor_PiuRegoleSullaStessaProprieta_SenzaStop_RaccolgonoTuttiGliErrori;
    [Test]
    procedure RuleFor_PiuRegoleSullaStessaProprieta_ConStopOnFirstFailure_SiFermaAllaPrima;
    [Test]
    procedure Validator_StopOnFirstFailureGlobale_SiFermaAllaPrimaRegolaConErrore;
    [Test]
    procedure Validator_SenzaStopGlobale_RaccoglieErroriDaTutteLeRegole;
    [Test]
    procedure WithMessage_SostituisceIlMessaggioDiDefault;
    [Test]
    procedure WithMessage_SenzaOverride_UsaIlMessaggioDiDefaultDelValidatore;
    [Test]
    procedure ValidationResult_QuandoValido_IsValidEVeroEArrayErroriVuoto;
    [Test]
    procedure ValidationResult_ErrorePortaPropertyNameEErrorMessageCorretti;
    [Test]
    procedure RuleFor_SuPiuProprieta_OgnunaContribuisceAgliErroriIndipendentemente;
  end;

implementation

{ TTestCore }

procedure TTestCore.RuleFor_SingolaRegolaValida_NonProduceErrori;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<string>('Nome',
      function(Persona: TPersona): string begin Result := Persona.Nome; end)
      .NotEmpty;

    P := TPersona.Create;
    try
      P.Nome := 'Muzio';
      Esito := V.Validate(P);
      Assert.IsTrue(Esito.IsValid);
      Assert.AreEqual(0, Integer(Length(Esito.Errors)));
    finally
      P.Free;
    end;
  finally
    V.Free;
  end;
end;

procedure TTestCore.RuleFor_SingolaRegolaNonValida_ProduceUnErrore;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<string>('Nome',
      function(Persona: TPersona): string begin Result := Persona.Nome; end)
      .NotEmpty;

    P := TPersona.Create;
    try
      P.Nome := '';
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

procedure TTestCore.RuleFor_PiuRegoleSullaStessaProprieta_SenzaStop_RaccolgonoTuttiGliErrori;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
begin
  // 'Nome' vuoto: viola sia NotEmpty sia Length(2,50) sia StartsWithUpperCase.
  // Senza StopOnFirstFailure, tutte le violazioni sulla stessa proprieta' devono
  // comparire nel risultato.
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<string>('Nome',
      function(Persona: TPersona): string begin Result := Persona.Nome; end)
      .NotEmpty
      .Length(2, 50);

    P := TPersona.Create;
    try
      P.Nome := '';
      Esito := V.Validate(P);
      Assert.IsFalse(Esito.IsValid);
      Assert.AreEqual(2, Integer(Length(Esito.Errors)));
    finally
      P.Free;
    end;
  finally
    V.Free;
  end;
end;

procedure TTestCore.RuleFor_PiuRegoleSullaStessaProprieta_ConStopOnFirstFailure_SiFermaAllaPrima;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<string>('Nome',
      function(Persona: TPersona): string begin Result := Persona.Nome; end)
      .NotEmpty
      .Length(2, 50)
      .StopOnFirstFailure;

    P := TPersona.Create;
    try
      P.Nome := '';
      Esito := V.Validate(P);
      Assert.IsFalse(Esito.IsValid);
      // Con StopOnFirstFailure a livello di regola, solo il primo errore
      // (NotEmpty) deve comparire, non anche quello di Length.
      Assert.AreEqual(1, Integer(Length(Esito.Errors)));
    finally
      P.Free;
    end;
  finally
    V.Free;
  end;
end;

procedure TTestCore.Validator_StopOnFirstFailureGlobale_SiFermaAllaPrimaRegolaConErrore;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
begin
  // Due proprieta' diverse, entrambe non valide. Con StopOnFirstFailure GLOBALE
  // (sul validatore, non sulla singola regola), il ciclo sulle regole si
  // interrompe non appena la prima regola produce almeno un errore: la seconda
  // proprieta' non viene nemmeno valutata.
  V := TValidator<TPersona>.Create.StopOnFirstFailure;
  try
    V.RuleFor<string>('Nome',
      function(Persona: TPersona): string begin Result := Persona.Nome; end)
      .NotEmpty;

    V.RuleFor<string>('Cognome',
      function(Persona: TPersona): string begin Result := Persona.Cognome; end)
      .NotEmpty;

    P := TPersona.Create;
    try
      P.Nome := '';
      P.Cognome := '';
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

procedure TTestCore.Validator_SenzaStopGlobale_RaccoglieErroriDaTutteLeRegole;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<string>('Nome',
      function(Persona: TPersona): string begin Result := Persona.Nome; end)
      .NotEmpty;

    V.RuleFor<string>('Cognome',
      function(Persona: TPersona): string begin Result := Persona.Cognome; end)
      .NotEmpty;

    P := TPersona.Create;
    try
      P.Nome := '';
      P.Cognome := '';
      Esito := V.Validate(P);
      Assert.IsFalse(Esito.IsValid);
      Assert.AreEqual(2, Integer(Length(Esito.Errors)));
    finally
      P.Free;
    end;
  finally
    V.Free;
  end;
end;

procedure TTestCore.WithMessage_SostituisceIlMessaggioDiDefault;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<string>('Nome',
      function(Persona: TPersona): string begin Result := Persona.Nome; end)
      .NotEmpty
      .WithMessage('Il nome e'' obbligatorio');

    P := TPersona.Create;
    try
      P.Nome := '';
      Esito := V.Validate(P);
      Assert.AreEqual('Il nome e'' obbligatorio', Esito.Errors[0].ErrorMessage);
    finally
      P.Free;
    end;
  finally
    V.Free;
  end;
end;

procedure TTestCore.WithMessage_SenzaOverride_UsaIlMessaggioDiDefaultDelValidatore;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<string>('Nome',
      function(Persona: TPersona): string begin Result := Persona.Nome; end)
      .NotEmpty;

    P := TPersona.Create;
    try
      P.Nome := '';
      Esito := V.Validate(P);
      // Il messaggio di default di TNotEmptyValidator contiene il nome
      // proprieta' interpolato via Format.
      Assert.IsTrue(Esito.Errors[0].ErrorMessage.Contains('Nome'));
    finally
      P.Free;
    end;
  finally
    V.Free;
  end;
end;

procedure TTestCore.ValidationResult_QuandoValido_IsValidEVeroEArrayErroriVuoto;
var
  Risultato: TValidationResult;
begin
  Risultato := TValidationResult.Create;
  try
    Assert.IsTrue(Risultato.GetIsValid);
    Assert.AreEqual(0, Integer(Length(Risultato.GetErrors)));
  finally
    Risultato.Free;
  end;
end;

procedure TTestCore.ValidationResult_ErrorePortaPropertyNameEErrorMessageCorretti;
var
  Risultato: TValidationResult;
begin
  Risultato := TValidationResult.Create;
  try
    Risultato.AddError('Email', 'formato non valido');
    Assert.IsFalse(Risultato.GetIsValid);
    Assert.AreEqual(1, Integer(Length(Risultato.GetErrors)));
    Assert.AreEqual('Email', Risultato.GetErrors[0].PropertyName);
    Assert.AreEqual('formato non valido', Risultato.GetErrors[0].ErrorMessage);
  finally
    Risultato.Free;
  end;
end;

procedure TTestCore.RuleFor_SuPiuProprieta_OgnunaContribuisceAgliErroriIndipendentemente;
var
  V: TValidator<TPersona>;
  P: TPersona;
  Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<string>('Nome',
      function(Persona: TPersona): string begin Result := Persona.Nome; end)
      .NotEmpty;

    V.RuleFor<Integer>('Eta',
      function(Persona: TPersona): Integer begin Result := Persona.Eta; end)
      .GreaterThan(0);

    P := TPersona.Create;
    try
      P.Nome := 'Anna';
      P.Eta := -5;
      Esito := V.Validate(P);
      Assert.IsFalse(Esito.IsValid);
      Assert.AreEqual(1, Integer(Length(Esito.Errors)));
      Assert.AreEqual('Eta', Esito.Errors[0].PropertyName);
    finally
      P.Free;
    end;
  finally
    V.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCore);

end.
