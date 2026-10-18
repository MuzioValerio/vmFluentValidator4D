{-----------------------------------------------------------------------------
 Project: FluentValidator
 Unit Name: Validators.TSimpleEmailValidator
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
 Purpose: Mantenuto per retro-compatibilita'. La logica di validazione email
          permissiva vive ora, unificata, in TEmailValidator (Mode = emSimple).
          Questa classe e' una sottoclasse sottile che forza quella modalita',
          cosi' il codice esistente che referenzia TSimpleEmailValidator (o
          l'alias TSimpleEmail / il metodo .Email) continua a funzionare
          identico, senza duplicare la logica.
 History:
   15-lug-2026: svuotata a favore di TEmailValidator(emSimple); marcata
                deprecated. Preferire .Email o .EmailAddress(emSimple).
-----------------------------------------------------------------------------}

unit FluentValidator.SimpleEmailValidator;

interface

uses
  System.Rtti,
  FluentValidator.Intf, FluentValidator, FluentValidator.EmailValidator;

type
  TSimpleEmailValidator = class(TEmailValidator)
  public
    constructor Create;
  end
  {$IFNDEF NO_DEPRECATED_EMAIL}
  deprecated 'Use TEmailValidator with Mode = emSimple, or .Email / .EmailAddress(emSimple)'
  {$ENDIF};

implementation

{ TSimpleEmailValidator }

constructor TSimpleEmailValidator.Create;
begin
  // Comportamento identico allo storico: permissivo, stringa vuota non valida.
  inherited Create(False, emSimple);
end;

end.
