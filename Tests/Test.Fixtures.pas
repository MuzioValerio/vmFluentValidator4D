{-----------------------------------------------------------------------------
 Project: FluentValidator - Test Suite
 Unit Name: Test.Fixtures
 Purpose: Entita' di supporto usate dai test di integrazione (RuleFor/TValidator<T>).
          Non sono test in se': definiscono solo i "modelli" su cui le regole
          vengono applicate, in modo analogo a TCustomer in Examples/Example1.dpr.
-----------------------------------------------------------------------------}

unit Test.Fixtures;

interface

uses
  System.SysUtils, System.Generics.Collections;

type
  // Enumerazione usata per i test su IsInEnum / EnumConverter
  TStatoOrdine = (soBozza, soConfermato, soSpedito);

  TIndirizzo = class
  public
    Citta: string;
    CAP: string;
  end;

  // Entita' generica usata dalla maggior parte dei test di integrazione.
  // Copre tutti i tipi che i validatori esistenti devono gestire:
  // string, Integer, Currency, Double, TDateTime, oggetto nidificato (nilable),
  // enumerazione, array dinamico e collezione generica.
  TPersona = class
  public
    Nome: string;
    Cognome: string;
    Eta: Integer;
    Email: string;
    Importo: Currency;
    Percentuale: Double;
    DataNascita: TDateTime;
    Stato: TStatoOrdine;
    Indirizzo: TIndirizzo;          // di proposito non inizializzato: serve per i test NotNull/NotEmpty su nil
    Tags: TArray<string>;
    Numeri: TArray<Double>;
    Amici: TObjectList<TPersona>;   // non possiede gli elementi (Ownership=False): evita doppio Free nei test

    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TPersona }

constructor TPersona.Create;
begin
  inherited Create;
  Amici := TObjectList<TPersona>.Create(False);
end;

destructor TPersona.Destroy;
begin
  Amici.Free;
  Indirizzo.Free;
  inherited;
end;

end.
