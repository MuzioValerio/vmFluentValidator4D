{-----------------------------------------------------------------------------
 Project: FluentValidator - Test Suite
 Program: FluentValidatorTests
 Purpose: Console runner DUnitX per l'intera suite di test di FluentValidator.
          Separato da Examples/: gli esempi mostrano come si usa la libreria,
          questa suite verifica che si comporti come promesso.

 Per compilare/eseguire da riga di comando (build.ps1 punta alla copia di
 DUnitX inclusa in RAD Studio, quindi non serve installare nulla):
   .\build.ps1
   .\Win32\Debug\FluentValidatorTests.exe --exitbehavior:continue

 Oppure aprire FluentValidatorTests.dproj in RAD Studio e premere F9.

 Opzioni utili da riga di comando (vedi anche il file .dproj):
   --format:nunit       output in formato NUnit XML (FluentValidatorTests.xml)
   --exitbehavior:continue   non attende <Enter> a fine esecuzione (utile in CI)
-----------------------------------------------------------------------------}

program FluentValidatorTests;

{$APPTYPE CONSOLE}

{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ENDIF}
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,

  // ---------------------------------------------------------------------
  // Codice sorgente della libreria sotto test (FluentValidator)
  // ---------------------------------------------------------------------
  FluentValidator.Intf in '..\src\FluentValidator.Intf.pas',
  FluentValidator in '..\src\FluentValidator.pas',
  FluentValidator.Messages in '..\src\FluentValidator.Messages.pas',
  FluentValidator.Language.Italian in '..\src\FluentValidator.Language.Italian.pas',
  FluentValidator.EnumConverter in '..\src\FluentValidator.EnumConverter.pas',
  FluentValidator.Validators in '..\src\FluentValidator.Validators.pas',

  FluentValidator.NotNullValidator in '..\src\Validators\FluentValidator.NotNullValidator.pas',
  FluentValidator.NotEmptyValidator in '..\src\Validators\FluentValidator.NotEmptyValidator.pas',
  FluentValidator.LengthValidator in '..\src\Validators\FluentValidator.LengthValidator.pas',
  FluentValidator.MaxLengthValidator in '..\src\Validators\FluentValidator.MaxLengthValidator.pas',
  FluentValidator.MinLengthValidator in '..\src\Validators\FluentValidator.MinLengthValidator.pas',
  FluentValidator.EqualValidator in '..\src\Validators\FluentValidator.EqualValidator.pas',
  FluentValidator.NotEqualValidator in '..\src\Validators\FluentValidator.NotEqualValidator.pas',
  FluentValidator.RegexValidator in '..\src\Validators\FluentValidator.RegexValidator.pas',
  FluentValidator.NumericComparisonValidator in '..\src\Validators\FluentValidator.NumericComparisonValidator.pas',
  FluentValidator.GreaterThanValidator in '..\src\Validators\FluentValidator.GreaterThanValidator.pas',
  FluentValidator.GreaterThanOrEqualValidator in '..\src\Validators\FluentValidator.GreaterThanOrEqualValidator.pas',
  FluentValidator.LessThanValidator in '..\src\Validators\FluentValidator.LessThanValidator.pas',
  FluentValidator.LessThanOrEqualValidator in '..\src\Validators\FluentValidator.LessThanOrEqualValidator.pas',
  FluentValidator.InclusiveBetweenValidator in '..\src\Validators\FluentValidator.InclusiveBetweenValidator.pas',
  FluentValidator.ExclusiveBetweenValidator in '..\src\Validators\FluentValidator.ExclusiveBetweenValidator.pas',
  FluentValidator.CustomPredicateValidator in '..\src\Validators\FluentValidator.CustomPredicateValidator.pas',
  FluentValidator.StartsWithUpperCaseValidator in '..\src\Validators\FluentValidator.StartsWithUpperCaseValidator.pas',
  FluentValidator.EmailValidator in '..\src\Validators\FluentValidator.EmailValidator.pas',
  FluentValidator.SimpleEmailValidator in '..\src\Validators\FluentValidator.SimpleEmailValidator.pas',
  FluentValidator.WhenValidator in '..\src\Validators\FluentValidator.WhenValidator.pas',
  FluentValidator.MustBeInPastValidator in '..\src\Validators\FluentValidator.MustBeInPastValidator.pas',
  FluentValidator.MustBeInFutureValidator in '..\src\Validators\FluentValidator.MustBeInFutureValidator.pas',
  FluentValidator.CollectionNotEmptyValidator in '..\src\Validators\FluentValidator.CollectionNotEmptyValidator.pas',
  FluentValidator.EnumValidator in '..\src\Validators\FluentValidator.EnumValidator.pas',
  FluentValidator.NullValidator in '..\src\Validators\FluentValidator.NullValidator.pas',
  FluentValidator.EmptyValidator in '..\src\Validators\FluentValidator.EmptyValidator.pas',
  FluentValidator.PrecisionScaleValidator in '..\src\Validators\FluentValidator.PrecisionScaleValidator.pas',
  FluentValidator.EnumNameValidator in '..\src\Validators\FluentValidator.EnumNameValidator.pas',
  FluentValidator.CreditCardValidator in '..\src\Validators\FluentValidator.CreditCardValidator.pas',

  // ---------------------------------------------------------------------
  // Unit di test
  // ---------------------------------------------------------------------
  Test.Fixtures in 'Test.Fixtures.pas',
  Test.Core in 'Test.Core.pas',
  Test.Messages in 'Test.Messages.pas',
  Test.WhenUnless in 'Test.WhenUnless.pas',
  Test.Validators.StringTests in 'Test.Validators.StringTests.pas',
  Test.Validators.NumericTests in 'Test.Validators.NumericTests.pas',
  Test.Validators.DateTests in 'Test.Validators.DateTests.pas',
  Test.Validators.EmailTests in 'Test.Validators.EmailTests.pas',
  Test.Validators.EnumTests in 'Test.Validators.EnumTests.pas',
  Test.Validators.CollectionTests in 'Test.Validators.CollectionTests.pas',
  Test.Validators.PredicateAndIntegration in 'Test.Validators.PredicateAndIntegration.pas',
  Test.Validators.Phase2Tests in 'Test.Validators.Phase2Tests.pas',
  Test.Engine.NestedAndForEach in 'Test.Engine.NestedAndForEach.pas',
  Test.Engine.SeverityAndHooks in 'Test.Engine.SeverityAndHooks.pas',
  Test.Engine.RuleForRtti in 'Test.Engine.RuleForRtti.pas';

var
  Runner: ITestRunner;
  Results: IRunResults;
  Logger: ITestLogger;
  NunitLogger: ITestLogger;

begin
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
  Exit;
{$ENDIF}
  try
    // Verifica e gestisce le opzioni da riga di comando (esce se non valide)
    TDUnitX.CheckCommandLine;

    Runner := TDUnitX.CreateRunner;
    Runner.UseRTTI := True;

    // Logger su console (a meno che non sia stato disattivato da riga di comando)
    if TDUnitX.Options.ConsoleMode <> TDUnitXConsoleMode.Off then
    begin
      Logger := TDUnitXConsoleLogger.Create(TDUnitX.Options.ConsoleMode = TDUnitXConsoleMode.Quiet);
      Runner.AddLogger(Logger);
    end;

    // Logger su file XML in formato NUnit (utile per CI / report)
    NunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    Runner.AddLogger(NunitLogger);

    Runner.FailsOnNoAsserts := False;

    Results := Runner.Execute;
    if not Results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Premere <Invio> per chiudere...');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
end.
