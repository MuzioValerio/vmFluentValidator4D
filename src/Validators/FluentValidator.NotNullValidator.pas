{-----------------------------------------------------------------------------
 Project: FluentValidator
 Unit Name: FluentValidator.NotNullValidator
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

unit FluentValidator.NotNullValidator;

interface

uses
  System.Classes, System.SysUtils, System.Rtti,
  FluentValidator.Intf, FluentValidator, FluentValidator.Messages;

type
  TNotNullValidator = class(TBaseValidator)
  protected
    function GetMessageKey: string; override;
  public
    function IsValid(const Value: TValue): Boolean; override;
  end;

implementation

{ TNotNullValidator }

function TNotNullValidator.IsValid(const Value: TValue): Boolean;
begin
  if Value.IsEmpty then
    Exit(False);

  // TValue.IsEmpty non rileva un riferimento a oggetto nil: una proprietà
  // oggetto (es. una proprietà nidificata della fattura) ha sempre un
  // TypeInfo valido anche quando il riferimento stesso è nil.
  if Value.IsObject then
    Exit(Value.AsObject <> nil);

  Result := True;
end;

function TNotNullValidator.GetMessageKey: string;
begin
  Result := TMsgKey.NotNull;
end;

end.
