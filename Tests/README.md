# FluentValidator - Suite di test DUnitX

Suite di test automatizzati per il motore e i validatori built-in di `FluentValidator`,
separata da `Examples/`. Non richiede modifiche al codice in `src/`: legge le unit esistenti
tramite path relativi (`..\src\...`), esattamente come fanno gli esempi.

Per la documentazione della libreria vedi il [README in italiano](../README.it.md) oppure il
[README in inglese](../README.md).

## Prerequisiti

1. **Delphi 10.4 Sydney o successivo**, come la libreria. La suite e' verificata su Delphi 13
   Florence e su Delphi 12 Athens (Community Edition); per 11 Alexandria e 10.4 Sydney la
   compatibilita' deriva dall'analisi dei sorgenti (vedi "Versioni di Delphi" nel
   [README principale](../README.it.md#versioni-di-delphi)).
2. **DUnitX**. Non serve installarlo: sia `build.ps1` sia `FluentValidatorTests.dproj`
   compilano contro la copia inclusa in RAD Studio (`$(BDS)\source\DUnitX`). Se preferisci una
   copia tua, puoi comunque installarlo dal **GetIt Package Manager** (`Tools` -> `GetIt
   Package Manager`, cerca "DUnitX") o clonarlo da <https://github.com/VSoftTechnologies/DUnitX>.

## Compilare ed eseguire

### Da riga di comando (modo canonico)

```powershell
.\build.ps1                    # Win32 (default)
.\Win32\Debug\FluentValidatorTests.exe --exitbehavior:continue

.\build.ps1 -Platform Win64    # oppure Win64
.\Win64\Debug\FluentValidatorTests.exe --exitbehavior:continue
```

Le piattaforme accettate sono `Win32` (default), `Win64` e `Linux64`; l'output finisce sempre
in `.\<Piattaforma>\Debug`. Linux64 compila tutte le unit ma il link richiede l'SDK Linux
deployato dalla IDE, e non e' mai stato eseguito end-to-end.

`build_tests.bat` e' l'equivalente cmd (aggiunge `-$O- -$W+ -$R+ -$Q+ -v`) e prende la
piattaforma come primo argomento (`build_tests.bat Win64`). Entrambi rigenerano
`FluentValidatorTests.res` da `FluentValidatorTests.rc` con `brcc32` se manca: il `.res` non e'
sotto controllo di versione, quindi la prima build dopo un clone se lo ricrea da sola.

Gli script puntano a `Studio\37.0` (Delphi 13 Florence). Con un'altra versione aggiorna la
variabile `$BDS` in testa a `build.ps1` (o `BDS` in `build_tests.bat`): `Studio\23.0` per 12
Athens, `Studio\22.0` per 11 Alexandria, `Studio\21.0` per 10.4 Sydney. La **Community
Edition** non include il compilatore a riga di comando: in quel caso usa la IDE (sotto).

Il flag `--exitbehavior:continue` evita l'attesa di un tasto a fine esecuzione (utile in CI).
Aggiungendo `--format:nunit` viene generato anche un report XML compatibile NUnit.

### Eseguire un singolo test o una singola fixture

`--run` accetta o un `Fixture.FullName.TestName` esatto, o un prefisso del nome completo della
fixture (nome completo = `<unit>.<classe>`):

```powershell
# un singolo metodo di test
.\Win32\Debug\FluentValidatorTests.exe --run:Test.Core.TTestCore.WithMessage_SostituisceIlMessaggioDiDefault --exitbehavior:continue
# una fixture / un'intera unit (match per prefisso)
.\Win32\Debug\FluentValidatorTests.exe --run:Test.WhenUnless.TTestWhenUnless --exitbehavior:continue
```

La suite non definisce categorie DUnitX, quindi `--include:` / `--exclude:` qui non servono.

### Da RAD Studio

Apri `FluentValidatorTests.dproj` e premi F9: non c'e' nulla da configurare. Il progetto trova
DUnitX in `$(BDS)\source\DUnitX` e le unit della libreria tramite le clausole `in '..\src\...'`
del `.dpr`. Lo stesso `.dproj` compila anche da MSBuild, in Debug e in Release.

`{$IFDEF TESTINSIGHT}` passa al runner TestInsight; `{$IFDEF CI}` sopprime il "premi INVIO"
finale.

## Struttura della suite

| File | Cosa copre |
|---|---|
| `Test.Fixtures.pas` | Entita' di supporto (`TPersona`, `TStatoOrdine`, `TIndirizzo`) usate dai test di integrazione. Non contiene test. |
| `Test.Core.pas` | Motore: `RuleFor`, accumulo di piu' regole sulla stessa proprieta', `StopOnFirstFailure` a livello di regola e globale, `WithMessage`, `IValidationResult`. |
| `Test.Messages.pas` | Catalogo dei messaggi e registro delle lingue: chiavi, segnaposto nominali, cambio di `Culture`, fallback (regionale -> neutra -> inglese -> chiave), e i **due stili** di `WithMessage` (nominale e posizionale). |
| `Test.WhenUnless.pas` | **Non-regressione** per il bug "`When`/`Unless` senza effetto" e per il bug del GUID duplicato di `IConditionalValidator`. Documenta anche la semantica "sticky" attuale di `.When`. |
| `Test.Engine.RuleForRtti.pas` | La forma RTTI di `RuleFor`: risoluzione di proprieta' e campi, fail-fast sul nome inesistente, errore esplicito sul tipo incompatibile. |
| `Test.Engine.NestedAndForEach.pas` | `SetValidator` (nidificati, errori con prefisso `Padre.Figlio`), `RuleForEach` (nome indicizzato, inline e con `IValidator<TItem>`), `CascadeMode`. |
| `Test.Engine.SeverityAndHooks.pas` | `WithSeverity` (incl. propagazione da nidificati e `When`), `PreValidate` (entity nil), `RuleForObject` (coerenze cross-campo). |
| `Test.Validators.StringTests.pas` | `NotNull`, `NotEmpty`, `Length`, `MinLength`, `MaxLength`, `Equal`, `NotEqual`, `Regex`, `StartsWithUpperCase`. |
| `Test.Validators.NumericTests.pas` | `GreaterThan(OrEqual)`, `LessThan(OrEqual)`, `InclusiveBetween`, `ExclusiveBetween`, incluso il supporto multi-tipo (Currency/Double/Single/Int64/Word/Byte/SmallInt). |
| `Test.Validators.DateTests.pas` | **Non-regressione** per il fix `Trunc()` di `MustBeInPast`/`MustBeInFuture` (confronto per giorno di calendario, deterministico a qualunque ora venga eseguito il test). |
| `Test.Validators.EmailTests.pas` | `TEmailValidator` nelle due modalita' (`emSimple`/`emStrict`) e `TSimpleEmailValidator`. |
| `Test.Validators.EnumTests.pas` | `TEnumValidator` (`IsInEnum`) e `TEnumConverter` (incluso il fix di `StringToEnum<T>` su nome non valido). |
| `Test.Validators.CollectionTests.pas` | **Non-regressione** per `TCollectionNotEmptyValidator` generalizzato via RTTI (array dinamici di qualsiasi tipo, `TList<T>`, `TObjectList<T>`, `TDictionary`, `TStringList`). |
| `Test.Validators.PredicateAndIntegration.pas` | `Must`/`TCustomPredicateValidator`, piu' alcuni test di integrazione per `IsInEnum`/`NotEmptyCollection` passati tramite `RuleFor`. |
| `Test.Validators.Phase2Tests.pas` | `Null`, `Empty`, `PrecisionScale`, `IsEnumName` (white-box + integrazione via `RuleFor`). |

## Convenzioni adottate

- **White-box dove conviene**: per i singoli validatori si istanzia direttamente la classe (es.
  `TNotNullValidator.Create`) e si chiama `IsValid(TValue)`, senza passare per
  `RuleFor`/`TValidator<T>`. E' piu' rapido da isolare e mette a nudo esattamente il
  comportamento del validatore.
- **Integrazione dove serve**: per ogni comportamento che vive nel motore
  (`TRuleBuilder<T,TProp>`/`TAbstractValidator<T>`) — `When`/`Unless`, `StopOnFirstFailure`,
  `WithMessage`, il wrapping di `Must` — si usa `TValidator<TPersona>` direttamente (senza
  bisogno di sottoclassarlo: lo si istanzia e si chiama `RuleFor` inline nel test).
- **Nomi dei metodi in italiano**, nella forma `Scenario_Condizione_RisultatoAtteso`.
- **Lifetime**: i test tengono un riferimento di classe `TValidator<T>` e fanno
  `try..finally Free`; gli esempi usano invece `IValidator<T>` refcounted. I due idiomi non vanno
  mescolati sulla stessa istanza.
- **Ordine di `.When`/`.Unless`**: la regola da condizionare va aggiunta *dopo* la chiamata a
  `.When`/`.Unless`, non prima (vedi il commento in testa a `Test.WhenUnless.pas` per il perche').
- **Fixture condivise**: in `Test.Fixtures.pas`, `TPersona.Indirizzo` e' volutamente non
  inizializzato (serve ai test `NotNull`/`NotEmpty` su `nil`) e `Amici` e' un `TObjectList` non
  proprietario, per evitare doppi `Free`.
- Alcuni test fissano **comportamenti attuali noti come "da rivedere"** (es. `NotEqual` che torna
  `True` su valore vuoto, invece di seguire la policy "tipo non gestito -> sempre `False`"). Sono
  commentati esplicitamente come tali: se decidi di unificare quella policy, sono i test da
  aggiornare consapevolmente, non un sintomo di una regressione. Il riepilogo di queste scelte e'
  nella sezione "Comportamenti noti e trappole" del README principale.

## Stato attuale

**249 test, tutti verdi**, zero leak segnalati dal memory leak monitor di DUnitX.

| Delphi | Piattaforma | Come | Esito |
|---|---|---|---|
| 13 Florence (`Studio\37.0`) | Win32 e Win64 | `build.ps1` (`dcc32` / `dcc64`) e MSBuild sul `.dproj` | 249 verdi |
| 12 Athens Community Edition | Win32 | IDE (F9 sul `.dproj`) | 249 verdi |
| 11 Alexandria, 10.4 Sydney | — | — | non ancora eseguita |
| Linux64 | — | compila con `dcclinux64`, link non provato | non eseguita |
