{-----------------------------------------------------------------------------
 Project: FluentValidator
 Unit Name: Example1
 Purpose: Quick start. L'esempio piu' piccolo possibile:
            - un'entita' semplice;
            - un validatore che dichiara le regole nel costruttore, con la
              forma RTTI di RuleFor (solo il nome del membro, niente getter);
            - la stampa del risultato e il cambio di lingua dei messaggi.
          Per gli scenari avanzati (When/Unless, oggetti nidificati,
          collezioni, severita') vedi Example2 ed Example3.
-----------------------------------------------------------------------------}

program Example1;

{$APPTYPE CONSOLE}

{$R *.res}

// Le unit si risolvono dallo unit search path del progetto (..\src e
// ..\src\Validators): e' lo stesso modo in cui la libreria va consumata a
// livello sorgente in un progetto qualsiasi.
uses
  System.SysUtils,
  FluentValidator.Intf,
  FluentValidator,
  FluentValidator.Messages,
  FluentValidator.Validators;

type
  TCustomer = class
  public
    Name: string;
    Surname: string;
    Age: Integer;
    Email: string;
  end;

  TCustomerValidator = class(TValidator<TCustomer>)
  public
    constructor Create;
  end;

constructor TCustomerValidator.Create;
begin
  inherited Create;

  // Forma raccomandata di RuleFor: basta il nome della proprieta'/campo, il
  // valore viene letto via RTTI. Un nome sbagliato solleva subito, qui, invece
  // di produrre un errore di validazione fuorviante a runtime.
  RuleFor<string>('Name')
    .NotEmpty
    .Length(2, 50);

  RuleFor<string>('Surname')
    .NotEmpty
    .Length(2, 50);

  // WithMessage con segnaposto nominali: {PropertyName} e' sempre disponibile,
  // {From} e {To} li fornisce InclusiveBetween. E' la forma consigliata.
  RuleFor<Integer>('Age')
    .InclusiveBetween(18, 120)
    .WithMessage('{PropertyName} must be between {From} and {To} years');

  RuleFor<string>('Email')
    .NotEmpty
    .EmailAddress(emStrict);
end;

procedure Report(const Title: string; const AResult: IValidationResult);
var
  Error: IValidationError;
begin
  WriteLn(Title, ' -> IsValid = ', BoolToStr(AResult.IsValid, True));
  for Error in AResult.Errors do
    WriteLn('    ', Error.PropertyName, ': ', Error.ErrorMessage);
  WriteLn;
end;

procedure Run;
var
  Validator: IValidator<TCustomer>;
  Customer: TCustomer;
begin
  // Stile "interfaccia": IValidator<T> e' reference-counted, non va liberato.
  Validator := TCustomerValidator.Create;

  Customer := TCustomer.Create;
  try
    Customer.Name := 'Mario';
    Customer.Surname := 'Rossi';
    Customer.Age := 42;
    Customer.Email := 'mario.rossi@example.com';
    Report('Valid customer', Validator.Validate(Customer));
  finally
    Customer.Free;
  end;

  Customer := TCustomer.Create;
  try
    Customer.Name := 'M';                 // troppo corto
    Customer.Surname := '';               // vuoto
    Customer.Age := 7;                    // fuori dall'intervallo
    Customer.Email := 'not-an-address';   // email non valida
    Report('Invalid customer (default culture: en)', Validator.Validate(Customer));

    // I messaggi predefiniti sono tradotti: basta cambiare la cultura.
    // I messaggi passati a WithMessage restano quelli scritti a mano.
    TValidationLanguages.Culture := 'it';
    try
      Report('Invalid customer (culture: it)', Validator.Validate(Customer));
    finally
      TValidationLanguages.Culture := DefaultCulture;
    end;
  finally
    Customer.Free;
  end;
end;

begin
  try
    Run;
  except
    on E: Exception do
      WriteLn(E.ClassName, ': ', E.Message);
  end;
  WriteLn('Press ENTER to exit...');
  ReadLn;
end.
