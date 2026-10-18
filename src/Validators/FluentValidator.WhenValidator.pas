{-----------------------------------------------------------------------------
 Project: FluentValidator
 Unit Name: FluentValidator.WhenValidator
 Copyright (C) 2025-2026 Muzio Valerio
 Author:    Muzio Valerio
 Date:      26-giu-2026

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

 Info:
 Purpose: Applies validation rules conditionally (When/Unless)
 History:
-----------------------------------------------------------------------------}

unit FluentValidator.WhenValidator;

interface

uses
  System.Classes, System.SysUtils, System.Rtti, System.Generics.Collections,
  FluentValidator.Intf, FluentValidator, FluentValidator.Messages;

type
  // Interfaccia per il validatore condizionale
  IConditionalValidator = interface(IPropertyValidator)
    ['{0D800205-BDA4-4984-9E5E-BFE13B05A19D}']
    function EvaluateCondition(const Entity: TObject): Boolean;
  end;

  // Validatore When - esegue la validazione solo se la condizione è vera
  TWhenValidator = class(TBaseValidator, IConditionalValidator)
  private
    FCondition: TFunc<TObject, Boolean>;
    FInnerValidator: IPropertyValidator;
  protected
    function GetMessageKey: string; override;
  public
    constructor Create(Condition: TFunc<TObject, Boolean>; InnerValidator: IPropertyValidator);
    function IsValid(const Value: TValue): Boolean; override;
    // Delega messaggio e gravita' al validatore interno: cosi' .WithMessage /
    // .WithSeverity applicati a una regola condizionale hanno effetto.
    function GetErrorMessage(const PropertyName: string): string; override;
    function GetSeverity: TValidationSeverity; override;
    function EvaluateCondition(const Entity: TObject): Boolean; virtual;
    function GetInnerValidator: IPropertyValidator;
  end;

  // Validatore Unless - esegue la validazione solo se la condizione è falsa
  TUnlessValidator = class(TWhenValidator)
  public
    constructor Create(Condition: TFunc<TObject, Boolean>; InnerValidator: IPropertyValidator);
    function EvaluateCondition(const Entity: TObject): Boolean; override;
  end;

  // Eccezione per errori di validazione condizionale
  EConditionalValidationError = class(Exception);

implementation

{ TWhenValidator }

constructor TWhenValidator.Create(Condition: TFunc<TObject, Boolean>; InnerValidator: IPropertyValidator);
begin
  inherited Create;
  if not Assigned(Condition) then
    raise EConditionalValidationError.Create('Condition cannot be nil');
  if not Assigned(InnerValidator) then
    raise EConditionalValidationError.Create('InnerValidator cannot be nil');

  FCondition := Condition;
  FInnerValidator := InnerValidator;
end;

function TWhenValidator.IsValid(const Value: TValue): Boolean;
begin
  // Il validatore stesso non valida direttamente - delega al validatore interno
  // La validazione effettiva avviene nel contesto del RuleBuilder
  Result := FInnerValidator.IsValid(Value);
end;

function TWhenValidator.EvaluateCondition(const Entity: TObject): Boolean;
begin
  if Assigned(FCondition) then
    Result := FCondition(Entity)
  else
    Result := True;
end;

function TWhenValidator.GetInnerValidator: IPropertyValidator;
begin
  Result := FInnerValidator;
end;

function TWhenValidator.GetErrorMessage(const PropertyName: string): string;
begin
  Result := FInnerValidator.GetErrorMessage(PropertyName);
end;

function TWhenValidator.GetSeverity: TValidationSeverity;
begin
  Result := FInnerValidator.GetSeverity;
end;

function TWhenValidator.GetMessageKey: string;
begin
  Result := TMsgKey.Conditional;
end;

{ TUnlessValidator }

constructor TUnlessValidator.Create(Condition: TFunc<TObject, Boolean>; InnerValidator: IPropertyValidator);
begin
  inherited Create(Condition, InnerValidator);
end;

function TUnlessValidator.EvaluateCondition(const Entity: TObject): Boolean;
begin
  // Inverte la condizione: Unless esegue la validazione quando la condizione è falsa
  Result := not inherited EvaluateCondition(Entity);
end;

end.
