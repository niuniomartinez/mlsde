# Coding Style Guide #

## Introduction ##

This is the _MLSDE Coding Style Guide_.  This is mostly the same style than
the [Embarcadero's Object Pascal Style
Guide](https://edn.embarcadero.com/article/10280) but with some differences;
this document also explains the reasons of these differences.

MLSDE code will follow this Style Guide.  You should follow these conventions
if you want to submit code to the project.

Note that these are conventions based primarily on matters of taste.  I don't
believe they are right and others are wrong.  Please feel free to use any style
as far as it is consistent.



## Source files ##

### Source file naming ###

File names should be lowercase but unit names may be camel-case.  For example
`UserInput` unit saved as `userinput.pas`.


### Source-file organization ###

All units should contain the following elements in the following order:

1. Unit Name
1. Block comment with unit description.
1. Copyright and license block comment.
1. Interface section
1. Implementation
1. A closing end and a period.


## Comments ##

Sources _must_ include comments explaining things (i.e. algorithms, decisions,
use cases, notes...).  Please be as verbose as you can.  Remember that you'll
forget how that code works in a couple of days.  You'll do.  Really.

At least all public objects should have one comment to explain its proposal and use.

The comments should be formatted as explained in _pasdoc_ documentation, so
anybody can create a full internal documentation using it.  Read [pasdoc
documentation](https://github.com/pasdoc/pasdoc/wiki/) for more information.  A
good idea is to write comments while coding to not forgot it.

Use `(*...*)` comments for important information and `{...}` for any other.  Do
not use nested comments because they're a common source of problems.
Deactivate nested comments from your compiler options to be sure.

**Do not use C++ style comments** (`//...`) just because they're ugly.  An
exception may be deactivate code termporally.

Deactivate code using comments only if you'll re-activate it in the future.



## Identifiers ##

Names and identifiers should be descriptive.  Don't be afraid if names get too
long:  modern source editors include _code completion_ utilities that reduce
typing.

So variables, fields, properties and parameters should be nouns.  Methods,
functions and procedures should be imperative verbs or verb phrases.
Enumerations and sets should be adjetives and/or nouns.  Constants, variables
and properties depend on what they contain but mostly nouns.  Types (classes,
records...) should be nouns or adjetives, depending on their purpose.

The use of prefixes (as `T` for types) to distinguish different stuff with same
name would be useful but _Hungarian notation is evil so do not use it,_
***never***.

Some prefixes:

Use prefix `f` for private and protected variables.
Use prefix `a` for parameters.
Use prefix `l` for local variables.

An exception of the Hungarian notation rule is in enumeration types.  In this
case, a prefix can be inserted before each element.  For example:

~~~Pascal
TBitBtnKind = (bkCustom, bkOK, bkCancel, bkHelp,
               bkYes, bkNo, bkClose, bkAbort, bkRetry,
               bkIgnore, bkAll
);
~~~



### Casing ###

Keywords in `lowercase`.

Everything else (constant and variable names, set elements, methods,
properties, etc.) should be `CamelCase`.



## Indentation ##

I use 2-spaces indentation and a tab-character for each 8 spaces.

`begin` and `end` keywords are on the same column in most cases.  Same for
`repeat` and `until`, `case` and `end`, etcetera.

Comments have one less indentation than the code if available.

~~~
(* A good indentation example. *)
  procedure Example (aParm: INTEGER);
  begin
    if aParm = Value then
      DoSomething (Param)
    else begin
      DoElse (Param);
      while aParm > 0 do
      begin
        DoOther (aParm);
        Dec (aParm)
      end
    end;
  { Other more strict way.  It shows also comment indentation. }
    if aParm = Value then
      DoSomething (aParm)
    else
      begin
        DoElse (aParm);
      { This comments the loop. }
        while aParm > 0 do
          begin
            DoOther (aParm);
            Dec (aParm)
          end
      end
  end;
~~~



## Spaces ##

Put spaces before a parenthesis, after a comma and surrounding operators.  This
will make things easer to read.

~~~
(* Space example. *)
  Variable := Origin + SomeFunction (Value, 123 + (456 / Cnt));
{ Compare with this. }
  Variable:=Origin+SomeFunction(Value,123+(456/Cnt));
~~~

Use empty lines to separate logical blocks.  Use 3 empty lines to separate each
`class`, `procedure` or `function` with others so it's easy to find where it
starts and ends.  So do not put more than one empty line to separate code
inside a `begin...end` code block.

~~~
(* This is a function to show how to use empty lines to separate
   logic blocs. *)
  function Example: Boolean;
  begin
    Example := True
  end;



(* This procedure is preceded by 3 empty lines so it's easy to
   find where the previous one finishes and where this one starts. *)
  procedure Other;
  begin
    if Something then
      DoThis;
    DoSometing;

  { The previous line separates a logic block. }
    DoMore
  end;
~~~


## Line length ##

Remember that horizontal scroll is evil and some editors (i. e. Vi) don't allow
it, so avoid it if possible.  You can split long procedure calls or
conditionals or everything else.  Use indentation to help reading.

~~~
(* An example about how to split long lines. *)
  if (AbnormallyLongVariableName <> aVeryLongConstantName)
  and (AbnormallyLongVariableName < OtherConstant)
  then
    ThisProcedureHasALongName (
      AbnormallyLongVariableName,
      AnObject.AnotherVeryLongNameForMethod (
        AnotherObjectWithAVeryLongName.UsefulPropertyToUse
      ),
      LongNameForSomethingElse.ThatsEnough
    );
~~~

## Error handling ##

### On error ###

On functions, return an error state value if possible.  So, check function
results if possible.

If it is not possible to return an error state value (either function or
procedure), then raise an exception.  Use the `Exception` class that fits
better with the error, or define a new one if you think it is worth of.

In any case, document the possible error cases.

### `TRY...EXCEPT` ###

Use this block to fix errors at runtime.  If error cannot be fixed, let it go
down.  So catch the appropriate `Exception` objects and do not catch what isn't
of your interest.

### `TRY...FINALLY` ###

You must use `TRY...FINALLY` blocks to be sure your code will release resources
properly.

## Other ##

Do not use `with...do` very often.  It makes the code harder to understand and
would confuse the compiler too.
