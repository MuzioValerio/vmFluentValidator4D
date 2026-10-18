{-----------------------------------------------------------------------------
 Project: FluentValidator
 Unit Name: FluentValidator.Validators
 Copyright (C) 2025-2026 Muzio Valerio
 Author:    Muzio Valerio
 Date:      25-giu-2026

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
 Purpose: Convenience unit that aggregates all built-in validators
 Note: This unit is optional - you can still use individual validator units
 History:
-----------------------------------------------------------------------------}

unit FluentValidator.Validators;

interface

// ============================================================================
// Built-in validators - all available in one place for convenience
// ============================================================================

// Core
uses
  FluentValidator.Intf,
  FluentValidator,

  // Messaggi e lingue. FluentValidator.Language.Italian e' elencata qui solo
  // per essere linkata: si autoregistra in initialization, cosi'
  // TValidationLanguages.Culture := 'it' funziona senza altre uses.
  FluentValidator.Messages,
  FluentValidator.Language.Italian,

  // String validators
  FluentValidator.NotNullValidator,
  FluentValidator.NotEmptyValidator,
  FluentValidator.LengthValidator,
  FluentValidator.MaxLengthValidator,
  FluentValidator.MinLengthValidator,
  FluentValidator.EqualValidator,
  FluentValidator.NotEqualValidator,
  FluentValidator.RegexValidator,

  // Numeric validators
  FluentValidator.GreaterThanValidator,
  FluentValidator.GreaterThanOrEqualValidator,
  FluentValidator.LessThanValidator,
  FluentValidator.LessThanOrEqualValidator,
  FluentValidator.InclusiveBetweenValidator,
  FluentValidator.ExclusiveBetweenValidator,

  // Custom/Predicate validators
  FluentValidator.CustomPredicateValidator,

  // Example custom validators
  FluentValidator.StartsWithUpperCaseValidator,

  // Email validators
  FluentValidator.EmailValidator,
  FluentValidator.SimpleEmailValidator,

  FluentValidator.WhenValidator,
  FluentValidator.MustBeInPastValidator,
  FluentValidator.MustBeInFutureValidator,
  FluentValidator.CollectionNotEmptyValidator,
  FluentValidator.EnumConverter,
  FluentValidator.EnumValidator,

  // Phase 2 - validatori aggiuntivi
  FluentValidator.NullValidator,
  FluentValidator.EmptyValidator,
  FluentValidator.PrecisionScaleValidator,
  FluentValidator.EnumNameValidator,
  FluentValidator.CreditCardValidator;

// ============================================================================
// Optional: Type aliases for commonly used validators
// This can make the code more concise
// ============================================================================

type
  // String validators
  TNotNull = TNotNullValidator;
  TNotEmpty = TNotEmptyValidator;
  TLength = TLengthValidator;
  TMaxLength = TMaxLengthValidator;
  TMinLength = TMinLengthValidator;
  TRegex = TRegexValidator;
  TEqual = TEqualValidator;
  TNotEqual = TNotEqualValidator;

  // Numeric validators
  TGreaterThan = TGreaterThanValidator;
  TGreaterThanOrEqual = TGreaterThanOrEqualValidator;
  TLessThan = TLessThanValidator;
  TLessThanOrEqual = TLessThanOrEqualValidator;
  TInclusiveBetween = TInclusiveBetweenValidator;
  TExclusiveBetween = TExclusiveBetweenValidator;

  TCustomPredicate = TCustomPredicateValidator;

  TStartsWithUpperCase = TStartsWithUpperCaseValidator;

  // Email validators
  TEmail = TEmailValidator;
  // TSimpleEmailValidator e' deprecata: l'alias resta per compatibilita' e ne
  // eredita la deprecazione, ma la sua sola dichiarazione non deve produrre un
  // warning in ogni progetto che usa la libreria.
  {$WARN SYMBOL_DEPRECATED OFF}
  TSimpleEmail = TSimpleEmailValidator
    deprecated 'Use TEmail with Mode = emSimple, or .Email / .EmailAddress(emSimple)';
  {$WARN SYMBOL_DEPRECATED DEFAULT}

  TWhen = TWhenValidator;
  TUnless = TUnlessValidator;
  TMustBeInPast = TMustBeInPastValidator;
  TMustBeInFuture = TMustBeInFutureValidator;
  TCollectionNotEmpty = TCollectionNotEmptyValidator;
  TEnumVal = TEnumValidator;

  // Phase 2 - validatori aggiuntivi
  TNull = TNullValidator;
  TEmpty = TEmptyValidator;
  TPrecisionScale = TPrecisionScaleValidator;
  TEnumName = TEnumNameValidator;
  TCreditCard = TCreditCardValidator;

implementation

end.