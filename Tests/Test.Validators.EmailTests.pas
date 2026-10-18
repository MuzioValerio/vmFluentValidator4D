{-----------------------------------------------------------------------------
 Project: FluentValidator - Test Suite
 Unit Name: Test.Validators.EmailTests
 Purpose: Test sui due validatori email presenti (TSimpleEmailValidator e'
          deprecato: TEmailValidator con Mode = emSimple lo sostituisce):
          - TEmailValidator (validazione "avanzata", usata da .EmailWithAllowEmpty)
          - TSimpleEmailValidator (validazione semplificata, usata da .Email)
          Questi test documentano anche le differenze di comportamento fra i
          due, utili per decidere come consolidarli in futuro senza perdere
          casi gia' gestiti correttamente da uno dei due.
-----------------------------------------------------------------------------}

unit Test.Validators.EmailTests;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils, System.Rtti,
  FluentValidator.Validators,
  FluentValidator.EmailValidator,
  FluentValidator.SimpleEmailValidator,
  FluentValidator,
  FluentValidator.Intf,
  Test.Fixtures;

type
  [TestFixture]
  TTestEmailValidator = class
  public
    [Test]
    procedure EmailValida_EValida;
    [Test]
    procedure SenzaChiocciola_NonEValida;
    [Test]
    procedure ChiocciolaAllInizio_NonEValida;
    [Test]
    procedure ChiocciolaAllaFine_NonEValida;
    [Test]
    procedure SenzaPuntoNelDominio_NonEValida;
    [Test]
    procedure PuntoSubitoDopoLaChiocciola_NonEValida;
    [Test]
    procedure DuePuntiConsecutiviNellaParteLocale_NonEValida;
    [Test]
    procedure DuePuntiConsecutiviNelDominio_NonEValida;
    [Test]
    procedure ParteLocaleInizianteConPunto_NonEValida;
    [Test]
    procedure DominioTerminanteConTrattino_NonEValida;
    [Test]
    procedure StringaVuota_ConAllowEmptyFalso_NonEValida;
    [Test]
    procedure StringaVuota_ConAllowEmptyVero_EValida;
    [Test]
    procedure ValoreNonStringa_NonEValido;
    [Test]
    procedure EmailConSottoDominioEPlus_EValida;
  end;

  [TestFixture]
  TTestSimpleEmailValidator = class
  public
    [Test]
    procedure EmailValida_EValida;
    [Test]
    procedure SenzaChiocciola_NonEValida;
    [Test]
    procedure StringaVuota_NonEValida;
    [Test]
    procedure ValoreNonStringa_NonEValido;
  end;

  // Test dell'unificazione (15-lug-2026): un solo TEmailValidator parametrizzato
  // per Mode, con .Email (emSimple) e .EmailWithAllowEmpty/.EmailAddress a
  // scegliere il rigore. Il discriminante usato e' 'ma..rio@...' (doppio punto
  // nella parte locale): accettato in emSimple, rifiutato in emStrict.
  [TestFixture]
  TTestEmailUnificato = class
  public
    [Test]
    procedure Unificato_ModeSimple_AccettaFormatoLasco;
    [Test]
    procedure Unificato_ModeStrict_RifiutaFormatoLasco;
    [Test]
    procedure SimpleEmailValidator_Residuo_RestaLasco;
    [Test]
    procedure EmailAddress_Strict_RifiutaViaRuleFor;
    [Test]
    procedure Email_Simple_AccettaViaRuleFor;
  end;

implementation

{ TTestEmailValidator }

procedure TTestEmailValidator.EmailValida_EValida;
var
  Validatore: TEmailValidator;
begin
  Validatore := TEmailValidator.Create(False);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<string>('mario.rossi@esempio.it')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestEmailValidator.SenzaChiocciola_NonEValida;
var
  Validatore: TEmailValidator;
begin
  Validatore := TEmailValidator.Create(False);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<string>('marioesempio.it')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestEmailValidator.ChiocciolaAllInizio_NonEValida;
var
  Validatore: TEmailValidator;
begin
  Validatore := TEmailValidator.Create(False);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<string>('@esempio.it')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestEmailValidator.ChiocciolaAllaFine_NonEValida;
var
  Validatore: TEmailValidator;
begin
  Validatore := TEmailValidator.Create(False);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<string>('mario@')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestEmailValidator.SenzaPuntoNelDominio_NonEValida;
var
  Validatore: TEmailValidator;
begin
  Validatore := TEmailValidator.Create(False);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<string>('mario@esempiocom')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestEmailValidator.PuntoSubitoDopoLaChiocciola_NonEValida;
var
  Validatore: TEmailValidator;
begin
  Validatore := TEmailValidator.Create(False);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<string>('mario@.it')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestEmailValidator.DuePuntiConsecutiviNellaParteLocale_NonEValida;
var
  Validatore: TEmailValidator;
begin
  Validatore := TEmailValidator.Create(False);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<string>('ma..rio@esempio.it')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestEmailValidator.DuePuntiConsecutiviNelDominio_NonEValida;
var
  Validatore: TEmailValidator;
begin
  Validatore := TEmailValidator.Create(False);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<string>('mario@esempio..it')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestEmailValidator.ParteLocaleInizianteConPunto_NonEValida;
var
  Validatore: TEmailValidator;
begin
  Validatore := TEmailValidator.Create(False);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<string>('.mario@esempio.it')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestEmailValidator.DominioTerminanteConTrattino_NonEValida;
var
  Validatore: TEmailValidator;
begin
  Validatore := TEmailValidator.Create(False);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<string>('mario@esempio-.it')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestEmailValidator.StringaVuota_ConAllowEmptyFalso_NonEValida;
var
  Validatore: TEmailValidator;
begin
  Validatore := TEmailValidator.Create(False);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<string>('')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestEmailValidator.StringaVuota_ConAllowEmptyVero_EValida;
var
  Validatore: TEmailValidator;
begin
  Validatore := TEmailValidator.Create(True);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<string>('')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestEmailValidator.ValoreNonStringa_NonEValido;
var
  Validatore: TEmailValidator;
begin
  Validatore := TEmailValidator.Create(False);
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<Integer>(123)));
  finally
    Validatore.Free;
  end;
end;

procedure TTestEmailValidator.EmailConSottoDominioEPlus_EValida;
var
  Validatore: TEmailValidator;
begin
  Validatore := TEmailValidator.Create(False);
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<string>('mario.rossi+fattura@mail.esempio.co.it')));
  finally
    Validatore.Free;
  end;
end;

{ TTestSimpleEmailValidator }

procedure TTestSimpleEmailValidator.EmailValida_EValida;
var
  Validatore: TSimpleEmailValidator;
begin
  Validatore := TSimpleEmailValidator.Create;
  try
    Assert.IsTrue(Validatore.IsValid(TValue.From<string>('mario.rossi@esempio.it')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestSimpleEmailValidator.SenzaChiocciola_NonEValida;
var
  Validatore: TSimpleEmailValidator;
begin
  Validatore := TSimpleEmailValidator.Create;
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<string>('marioesempio.it')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestSimpleEmailValidator.StringaVuota_NonEValida;
var
  Validatore: TSimpleEmailValidator;
begin
  // A differenza di TEmailValidator, TSimpleEmailValidator non ha un parametro
  // AllowEmpty: la stringa vuota e' sempre non valida.
  Validatore := TSimpleEmailValidator.Create;
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<string>('')));
  finally
    Validatore.Free;
  end;
end;

procedure TTestSimpleEmailValidator.ValoreNonStringa_NonEValido;
var
  Validatore: TSimpleEmailValidator;
begin
  Validatore := TSimpleEmailValidator.Create;
  try
    Assert.IsFalse(Validatore.IsValid(TValue.From<Integer>(123)));
  finally
    Validatore.Free;
  end;
end;

{ TTestEmailUnificato }

procedure TTestEmailUnificato.Unificato_ModeSimple_AccettaFormatoLasco;
var V: TEmailValidator;
begin
  V := TEmailValidator.Create(False, emSimple);
  try
    Assert.IsTrue(V.IsValid(TValue.From<string>('ma..rio@esempio.it')));
  finally V.Free; end;
end;

procedure TTestEmailUnificato.Unificato_ModeStrict_RifiutaFormatoLasco;
var V: TEmailValidator;
begin
  V := TEmailValidator.Create(False, emStrict);
  try
    Assert.IsFalse(V.IsValid(TValue.From<string>('ma..rio@esempio.it')));
  finally V.Free; end;
end;

procedure TTestEmailUnificato.SimpleEmailValidator_Residuo_RestaLasco;
var V: TSimpleEmailValidator;
begin
  // La sottoclasse deprecata delega a emSimple: comportamento invariato.
  V := TSimpleEmailValidator.Create;
  try
    Assert.IsTrue(V.IsValid(TValue.From<string>('ma..rio@esempio.it')));
  finally V.Free; end;
end;

procedure TTestEmailUnificato.EmailAddress_Strict_RifiutaViaRuleFor;
var V: TValidator<TPersona>; P: TPersona; Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<string>('Email',
      function(Per: TPersona): string begin Result := Per.Email; end)
      .EmailAddress(emStrict);
    P := TPersona.Create;
    try
      P.Email := 'ma..rio@esempio.it';
      Esito := V.Validate(P);
      Assert.IsFalse(Esito.IsValid);
    finally P.Free; end;
  finally V.Free; end;
end;

procedure TTestEmailUnificato.Email_Simple_AccettaViaRuleFor;
var V: TValidator<TPersona>; P: TPersona; Esito: IValidationResult;
begin
  V := TValidator<TPersona>.Create;
  try
    V.RuleFor<string>('Email',
      function(Per: TPersona): string begin Result := Per.Email; end)
      .Email;
    P := TPersona.Create;
    try
      P.Email := 'ma..rio@esempio.it';
      Esito := V.Validate(P);
      Assert.IsTrue(Esito.IsValid);
    finally P.Free; end;
  finally V.Free; end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestEmailValidator);
  TDUnitX.RegisterTestFixture(TTestSimpleEmailValidator);
  TDUnitX.RegisterTestFixture(TTestEmailUnificato);

end.
