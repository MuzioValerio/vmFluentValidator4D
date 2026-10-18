program Example2;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  FluentValidator.Validators in '..\src\FluentValidator.Validators.pas',
  FluentValidator in '..\src\FluentValidator.pas',
  FluentValidator.Intf in '..\src\FluentValidator.Intf.pas',
  FluentValidator.CustomPredicateValidator in '..\src\Validators\FluentValidator.CustomPredicateValidator.pas',
  FluentValidator.EqualValidator in '..\src\Validators\FluentValidator.EqualValidator.pas',
  FluentValidator.ExclusiveBetweenValidator in '..\src\Validators\FluentValidator.ExclusiveBetweenValidator.pas',
  FluentValidator.GreaterThanOrEqualValidator in '..\src\Validators\FluentValidator.GreaterThanOrEqualValidator.pas',
  FluentValidator.GreaterThanValidator in '..\src\Validators\FluentValidator.GreaterThanValidator.pas',
  FluentValidator.InclusiveBetweenValidator in '..\src\Validators\FluentValidator.InclusiveBetweenValidator.pas',
  FluentValidator.LengthValidator in '..\src\Validators\FluentValidator.LengthValidator.pas',
  FluentValidator.LessThanOrEqualValidator in '..\src\Validators\FluentValidator.LessThanOrEqualValidator.pas',
  FluentValidator.LessThanValidator in '..\src\Validators\FluentValidator.LessThanValidator.pas',
  FluentValidator.MaxLengthValidator in '..\src\Validators\FluentValidator.MaxLengthValidator.pas',
  FluentValidator.MinLengthValidator in '..\src\Validators\FluentValidator.MinLengthValidator.pas',
  FluentValidator.NotEmptyValidator in '..\src\Validators\FluentValidator.NotEmptyValidator.pas',
  FluentValidator.NotEqualValidator in '..\src\Validators\FluentValidator.NotEqualValidator.pas',
  FluentValidator.NotNullValidator in '..\src\Validators\FluentValidator.NotNullValidator.pas',
  FluentValidator.RegexValidator in '..\src\Validators\FluentValidator.RegexValidator.pas',
  FluentValidator.StartsWithUpperCaseValidator in '..\src\Validators\FluentValidator.StartsWithUpperCaseValidator.pas',
  FluentValidator.EnumValidator in '..\src\Validators\FluentValidator.EnumValidator.pas',
  FluentValidator.CollectionNotEmptyValidator in '..\src\Validators\FluentValidator.CollectionNotEmptyValidator.pas',
  FluentValidator.MustBeInPastValidator in '..\src\Validators\FluentValidator.MustBeInPastValidator.pas',
  FluentValidator.WhenValidator in '..\src\Validators\FluentValidator.WhenValidator.pas',
  FluentValidator.EmailValidator in '..\src\Validators\FluentValidator.EmailValidator.pas',
  FluentValidator.SimpleEmailValidator in '..\src\Validators\FluentValidator.SimpleEmailValidator.pas',
  FluentValidator.MustBeInFutureValidator in '..\src\Validators\FluentValidator.MustBeInFutureValidator.pas';

type
  TCustomer = class
  public
    Name: string;
    SurName: string;
    Age: Integer;
    Email: string;
    Role: string;
  end;

  TCustomerValidator = class(TValidator<TCustomer>)
  public
    constructor Create;
  end;

constructor TCustomerValidator.Create;
begin
  inherited Create;

  // Validazione per Name
  RuleFor<string>('Name',
    function(c: TCustomer): string
    begin
      Result := c.Name;
    end)
    .NotNull
    .NotEmpty
    .MinLength(2)
    .MaxLength(50)
    .NotEqual('Admin')
    .Must(
      function(Name: string): Boolean
      begin
        if Name.Length > 0 then
          Result := not CharInSet(Name[1], ['0'..'9'])
        else
          Result := True;
      end,
      '{PropertyName} must not start with a digit'
    )
    .StartsWithUpperCaseWithMessage('{PropertyName} must start with an uppercase letter');

  // Validazione per SurName
  RuleFor<string>('SurName',
    function(c: TCustomer): string
    begin
      Result := c.SurName;
    end)
    .NotNull
    .NotEmpty
    .MinLength(2)
    .MaxLength(30);

  // Validazione per Age - tutti i validatori numerici in catena.
  // Nota: WithMessage vale solo per l'ULTIMO validatore aggiunto, qui
  // ExclusiveBetween(0, 100): i segnaposto {From}/{To} sono i suoi.
  RuleFor<Integer>('Age',
    function(c: TCustomer): Integer
    begin
      Result := c.Age;
    end)
    .GreaterThan(0)
    .LessThan(150)
    .LessThanOrEqual(100)
    .GreaterThanOrEqual(1)
    .NotEqual(99)
    .InclusiveBetween(1, 120)
    .ExclusiveBetween(0, 100)
    .WithMessage('{PropertyName} must be between {From} and {To} (exclusive)');

  // Regola cross-field: dipende da Age e Role insieme, non dal solo Age.
  // RuleForObject passa al predicato l'intera entita', ed e' il modo corretto
  // di scriverla (niente variabili catturate dai getter).
  RuleForObject('Age')
    .Must(
      function(c: TCustomer): Boolean
      begin
        if c.Role = 'Senior' then
          Result := c.Age >= 63
        else if c.Role = 'Junior' then
          Result := (c.Age >= 18) and (c.Age <= 25)
        else
          Result := (c.Age >= 18) and (c.Age <= 99);
      end,
      '{PropertyName} is not appropriate for the customer role'
    );

  // Validazione per Email (esempio con validatore email - da implementare dopo)
  RuleFor<string>('Email',
    function(c: TCustomer): string
    begin
      Result := c.Email;
    end)
    .NotNull
    .NotEmpty;
end;

var
  Customer: TCustomer;
  Validator: IValidator<TCustomer>;
  Result: IValidationResult;
  Error: IValidationError;

begin
  try
    Validator := TCustomerValidator.Create;

    // Test 1: Tutto valido
    Customer := TCustomer.Create;
    try
      Customer.Name := 'Muzio Valerio';
      Customer.SurName := 'Rossi';
      Customer.Age := 30;
      Customer.Email := 'muzio_valerio@libero.it';
      Customer.Role := 'Standard';

      Result := Validator.Validate(Customer);
      WriteLn('Test 1 - Valido: ', Result.IsValid);
      if not Result.IsValid then
        for Error in Result.Errors do
          WriteLn('  ', Error.PropertyName, ': ', Error.ErrorMessage);
    finally
      Customer.Free;
    end;

    // Test 2: Age fuori range
    Customer := TCustomer.Create;
    try
      Customer.Name := 'Luigi';
      Customer.SurName := 'Verdi';
      Customer.Age := 200;  // Troppo alto!
      Customer.Email := 'luigi@example.com';
      Customer.Role := 'Standard';

      Result := Validator.Validate(Customer);
      WriteLn('Test 2 - Age troppo alto: ', Result.IsValid);
      if not Result.IsValid then
        for Error in Result.Errors do
          WriteLn('  ', Error.PropertyName, ': ', Error.ErrorMessage);
    finally
      Customer.Free;
    end;

    // Test 3: Senior con età non appropriata
    Customer := TCustomer.Create;
    try
      Customer.Name := 'Anna';
      Customer.SurName := 'Bianchi';
      Customer.Age := 40;  // Senior dovrebbe essere > 63
      Customer.Email := 'anna@example.com';
      Customer.Role := 'Senior';

      Result := Validator.Validate(Customer);
      WriteLn('Test 3 - Senior invalido: ', Result.IsValid);
      if not Result.IsValid then
        for Error in Result.Errors do
          WriteLn('  ', Error.PropertyName, ': ', Error.ErrorMessage);
    finally
      Customer.Free;
    end;

    ReadLn;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
