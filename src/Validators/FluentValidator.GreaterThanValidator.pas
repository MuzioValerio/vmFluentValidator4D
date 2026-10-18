{-----------------------------------------------------------------------------
 Project: FluentValidator
 Unit Name: FluentValidator.GreaterThanValidator
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
 Purpose:
 History:
-----------------------------------------------------------------------------}

unit FluentValidator.GreaterThanValidator;

interface

uses
  System.SysUtils, System.Rtti,
  FluentValidator.Intf, FluentValidator, FluentValidator.Messages, FluentValidator.NumericComparisonValidator;

type
  TGreaterThanValidator = class(TNumericComparisonValidator)
  private
    FMinValue: Integer;
  protected
    function GetMessageKey: string; override;
    function GetMessageArgs: TMessageArgs; override;
  public
    constructor Create(MinValue: Integer);
  end;

implementation

{ TGreaterThanValidator }

constructor TGreaterThanValidator.Create(MinValue: Integer);
begin
  inherited Create(
    function(const AValue: Double): Boolean
    begin
      Result := AValue > MinValue;
    end);

  FMinValue := MinValue;
end;

function TGreaterThanValidator.GetMessageKey: string;
begin
  Result := TMsgKey.GreaterThan;
end;

function TGreaterThanValidator.GetMessageArgs: TMessageArgs;
begin
  Result := TValidationMessages.Args(['ComparisonValue', FMinValue]);
end;

end.
