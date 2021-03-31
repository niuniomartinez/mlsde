UNIT BAScript;
(*<Implements a general-purpose, stack based, interpretor.
 *)
(*
  Copyright (c) 2006, 2014-2016 Guillermo Martínez J.

  This software is provided 'as-is', without any express or implied
  warranty. In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
    claim that you wrote the original software. If you use this software
    in a product, an acknowledgment in the product documentation would be
    appreciated but is not required.

    2. Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.

    3. This notice may not be removed or altered from any source
    distribution.
 *)

INTERFACE

  USES
    contnrs, sysutils;

  CONST
  (* Major version identifier. *)
    BAS_MAJOR_V = 2;
  (* Minor version identifier.  If lesser than zero then it's a beta or apha
    version. *)
    BAS_MINOR_V	= -1;
  (* Full version identifier.  If lesser than zero then it's a beta or alpha
    version. *)
    BAS_VERSION = -2.1;
  (* If @false then the library is a production version. *)
    BAS_IS_BETA = BAS_MINOR_V < 0;
  (* Version identification to be displayed in splash screens, credits, etc. *)
    BAS_VERSION_STR = '2.alpha3';

  (* Value used as FALSE. *)
    BAS_FALSE = 0;
  (* Value used as TRUE. *)
    BAS_TRUE = NOT BAS_FALSE;


  TYPE
  (* To identify data types. @seealso(TBasValue) *)
    TBasDataType = (
    (* No data. *)
      bdtVoid,
    (* 32bit signed integer. *)
      bdtInteger,
    (* Character string.  Text. *)
      bdtString
    );



  (* List of possible errors.
    @seealso(BasException) *)
    TBasErrors = (
    (* No error. *)
      bseNoError = 0,
    (* The given string cannot be used as a variable or method name. *)
      bseBadName,
    (* The given data isn't in the correct data type. *)
      bseTypeMismatch,

    (* No context available. *)
      bseNoContext,
    (* The data stack is empty. *)
      bseEmptyDataStack,
    (* The data stack is full. *)
      bseFullDataStack,
    (* There are other object (variable, label...) with same name. *)
      bseDuplicateDefinition,
    (* End of source found. *)
      bseEndSource,
    (* Illegal character in stream. *)
      bseIllegalCharStream,
    (* Division by zero. *)
      bseDivisionByZero,
    (* IF without FI. *)
      bseIFWithoutFI,
    (* Can't find the requested label. *)
      bseNoLabel,
    (* The code stack is empty. *)
      bseEmptyCodeStack,
    (* The code stack is full. *)
      bseFullCodeStack,
    (* Can't find the requested hosted method. *)
      bseNoMethod,
    (* Can't find the requested variable. *)
      bseNoVariable,
    (* Operation not implemented. *)
      bseNotImplemented,
    (* Unkown operation. *)
      bseUnknownOperation
    );



  (* Stores a value. @seealso(TBasVariable) *)
    TBasValue = CLASS (TObject)
    PRIVATE
      fDataType: TBasDataType;
      fisInteger: INTEGER;
      fisString: STRING;

      FUNCTION getAsInteger: INTEGER; INLINE;
      PROCEDURE setAsInteger (aValue: INTEGER); INLINE;
      FUNCTION getAsString: STRING; INLINE;
      PROCEDURE setAsString (aValue: STRING); INLINE;
    PUBLIC
    (* Creates a void value. *)
      CONSTRUCTOR Create;
    (* Copyes from value. *)
      PROCEDURE Assign (CONST aValue: TBasValue); INLINE;
    (* Assigns to VOID. *)
      PROCEDURE SetVoid; INLINE;
    (* Returns the data type. *)
      PROPERTY DataType: TBasDataType READ fDataType;
    (* To access to the value as an integer.  If @link(DataType) is
      @code(bdtString) this may return any value. @seealso(asString) *)
      PROPERTY asInteger: INTEGER READ getAsInteger WRITE setAsInteger;
    (* To access to the value as a string. @seealso(asInteger) *)
      PROPERTY asString: STRING READ getAsString WRITE setAsString;
    END;



  (* A variable inside the BAScript program. *)
    TBasVariable = CLASS (TBasValue)
    PRIVATE
      fName: STRING;
    PUBLIC
    (* Constructor. *)
      CONSTRUCTOR Create (aName: STRING);

    (* The variable name. *)
      PROPERTY Name: STRING READ fName;
    END;



  (* Manages a list of variables. *)
    TBasVarList = CLASS (TObject)
    PRIVATE
      fVarList: TFPObjectList;

      FUNCTION getCount: INTEGER;
      FUNCTION getVariable (Ndx: INTEGER): TBasVariable; INLINE;
    PUBLIC
    (* Constructor. *)
      CONSTRUCTOR Create;
    (* Destructor. *)
      DESTRUCTOR Destroy; OVERRIDE;
    (* Adds a new variable to the list.  If there's a variable with same name,
      it raises a @link(BasException) of type @code(bseDuplicateDefinition).
      @returns(The variable index.) @seealso(IndexOf) @seealso(DeleteVariable)
     *)
      FUNCTION CreateVariable (aName: STRING): INTEGER;
    (* Searchs the requested variable. @seealso(CreateVariable)
      @returns(The variable index or (-1) if variable doesn't exists.) *)
      FUNCTION IndexOf (aName: STRING): INTEGER;
    (* Removes and destroys the variable from the list.
      @seealso(CreateVariable) @seealso(IndexOf) @seealso(Clear) *)
      PROCEDURE DeleteVariable (Ndx: INTEGER); INLINE;
    (* Destroys all variables from the list. *)
      PROCEDURE Clear;

    (* Number of variables in the list.  Note that it may include removed
      variables. *)
      PROPERTY Count: INTEGER READ getCount;
    (* Indexed access to the variables of the list.  The index is zero based,
      i.e., runs from 0 (zero) to @link(Count)-1. *)
      PROPERTY Variables[Ndx: INTEGER]: TBasVariable READ getVariable; DEFAULT;
    END;



  (* Manages a stack of LONGINTs. *)
    TBasStack = CLASS (TObject)
    PRIVATE
      fStack: ARRAY OF LONGINT;
      fTop: INTEGER;

      FUNCTION getStackSize: INTEGER; INLINE;
    PROTECTED
    (* Changes the stack size.  Note that assigning a value will clear the
      current data. *)
      PROCEDURE setStackSize (CONST aSize: INTEGER); VIRTUAL;
    PUBLIC
    (* Creates the stack. *)
      CONSTRUCTOR Create (aSize: INTEGER); VIRTUAL;
    (* Pushes a 32 bit signed integer. *)
      PROCEDURE Push (aValue: LONGINT); VIRTUAL;
    (* Pops a 32 bit signed integer. *)
      FUNCTION Pop: LONGINT; VIRTUAL;
    (* Duplicates top. *)
      PROCEDURE DUP; INLINE;
    (* Swap top values. *)
      PROCEDURE SWAP; INLINE;
    (* Rotates top 3 values. *)
      PROCEDURE ROT;
    (* Discards top value. *)
      PROCEDURE DROP; INLINE;
    (* Clears the stack. *)
      PROCEDURE Clear; INLINE;
    (* Adds the content of another stack to this one. *)
      PROCEDURE Add (aStack: TBasStack); VIRTUAL;
    (* Assign the content of another stack to this one.  It also modifyes the
      size and the top place. *)
      PROCEDURE Assign (aStack: TBasStack); VIRTUAL;
    (* Checks if stack is empty. *)
      FUNCTION IsEmpty: BOOLEAN; INLINE;
    (* Checks if stack is full. *)
      FUNCTION IsFull: BOOLEAN; INLINE;

    (* The stack size.  Note that assigning a value will clear the current
      data. *)
      PROPERTY Size: INTEGER READ getStackSize WRITE setStackSize;
    END;



  (* Manages the BAScript data stack.  Difference with @link(TBasStack) is
    that this stack manages the data type of stacked data.

    To know how the data is stacked read the BAScript language reference. *)
    TBasDataStack = CLASS (TBasStack)
    PRIVATE
      fTypesStack: ARRAY OF TBasDataType;

    (* Returns the data type of the top of the stack. *)
      FUNCTION getDataType: TBasDataType; INLINE;
    PROTECTED
    (* Changes the stack size.  Note that assigning a value will clear the
      current data. *)
      PROCEDURE setStackSize (CONST aSize: INTEGER); OVERRIDE;
    PUBLIC
    (* Creates the stack. *)
      CONSTRUCTOR Create (aSize: INTEGER); OVERRIDE;
    (* Pushes a 32 bit signed integer. *)
      PROCEDURE Push (aValue: LONGINT); OVERRIDE;
    (* Pushes a string. *)
      PROCEDURE PushString (aString: STRING);
    (* Pushes a value. *)
      PROCEDURE PushValue (aValue: TBasValue);
    (* Pops a string. *)
      FUNCTION PopString: STRING;
    (* Pops a value. *)
      PROCEDURE PopValue (aValue: TBasValue);
    (* Adds the content of another stack to this one. *)
      PROCEDURE Add (aStack: TBasDataStack); OVERLOAD; VIRTUAL;
    (* Assign the content of another stack to this one.  It also may modify the
      size and the top place. *)
      PROCEDURE Assign (aStack: TBasDataStack); OVERLOAD; VIRTUAL;

    (* The data type of the top of the stack. *)
      PROPERTY TopDataType: TBasDataType READ getDataType;
    END;



  (* @exclude Forward declaration of TBasContext. *)
    TBasContext = CLASS;



  (* Reference to a hosted method. @seealso(TBasMethodList) *)
    TBasMethodReference = PROCEDURE (Context: TBasContext); CDECL;



  (* @exclude Stores the pointers to the hosted methods.  Internal use only. *)
    TBasHostedMethod = RECORD
      Name: STRING;
      Method: TBasMethodReference;
    END;



  (* List of hosted methods.  Methods are called by BAScript word
    @code(CALL:<name>). @seealso(TBasInterpretor) *)
    TBasMethodList = CLASS (TObject)
    PRIVATE
      fMethodList: ARRAY OF TBasHostedMethod;

      FUNCTION getMethod (CONST Ndx: INTEGER): TBasMethodReference; INLINE;
    PUBLIC
    (* Adds method to the list.  Overwrites if method yet exists.
      @seealso(Remove) @seealso(Method) *)
      PROCEDURE Add (aName: STRING; aMethod: TBasMethodReference);
    (* Removes the method from the list. *)
      PROCEDURE Remove (aName: STRING);
    (* Removes ALL methods from the list. *)
      PROCEDURE Clear;
    (* Searchs the requested method. @seealso(Method)
       @returns(The method index or (-1) if it doesn't exists.) *)
      FUNCTION IndexOf (aName: STRING): INTEGER;

    (* Allows direct access to methods. @seealso(IndexOf) *)
      PROPERTY Method[Ndx: INTEGER]: TBasMethodReference READ getMethod; DEFAULT;
    END;



  (* An execution context.  Stores the data-stack, the variable list, and the
    method list used by the scripts. @seealso(TBasInterpretor) *)
    TBasContext = CLASS (TObject)
    PRIVATE
      fDataStack: TBasDataStack;
      fVarList: TBasVarList;
      fMethodList: TBasMethodList;
    PUBLIC
    (* Constructor. *)
      CONSTRUCTOR Create (CONST aStackSize: INTEGER);
    (* Destructor. *)
      DESTRUCTOR Destroy; OVERRIDE;

    (* Access to the data stack. *)
      PROPERTY DataStack: TBasDataStack READ fDataStack;
    (* Access to the variable list. *)
      PROPERTY Variables: TBasVarList READ fVarList;
    (* Access to the method list. *)
      PROPERTY MethodList: TBasMethodList READ fMethodList;
    END;



  CONST (* @exclude Symbol identifers used internally by the scanner. *)
  (* @exclude Unknown. *)
    BSY_NONE = 0;
  (* @exclude An INTEGER value. *)
    BSY_INTEGER = 1;
  (* @exclude A constant string. *)
    BSY_STRING = 2;
  (* @exclude A label. *)
    BSY_LABEL = 3;
  (* @exclude A BAScript II operator. *)
    BSY_OPERATOR = 4;

  TYPE
  (* Scanner used by the interpretor.  It's for internal use only but may be
    you can use it. *)
    TBasScanner = CLASS (TObject)
    PRIVATE
      fSource: ANSISTRING; fsPos: INTEGER; Character: CHAR;
      fSymbol: STRING; fSymbolId: INTEGER;

      PROCEDURE setSource (CONST aSource: ANSISTRING);
    (* Helper to get  the next character. *)
      PROCEDURE NextChar; INLINE;
    PUBLIC
    (* Extracts next symbol.  Stores it in @link(Symbol) and @link(SymbolId).
      @seealso(Source) *)
      PROCEDURE GetSymbol;
    (* @return(@true if it's beyond the end the source, @false otherwise.) *)
      FUNCTION EOF: BOOLEAN; INLINE;
    (* @return(Current source line.) *)
      FUNCTION LineNum: INTEGER;

    (* Access to the source.  Note that setting will reinitialize the scanner. *)
      PROPERTY Source: ANSISTRING READ fSource WRITE setSource;
    (* The last symbol extracted. @seealso(SymbolId) *)
      PROPERTY Symbol: STRING READ fSymbol;
    (* Last symbol identificator. @seealso(Symbol) *)
      PROPERTY SymbolId: INTEGER READ fSymbolId;
    END;



  (* @exclude Stores the address of a label.  For internal use only. *)
    TBasLabel = RECORD
      Name: STRING;
      Addr: INTEGER;
    END;



  (* An interpretor to execute BAScript scripts.

    The interpretor needs a context, that stores methods, data stack and script
    variables.  You can change the context in any moment, for  example to
    emulate object-oriented programming (by using a different context for each
    object). *)
    TBasInterpretor = CLASS (TObject)
    PRIVATE
      fIdentifier: STRING;
      fContext: TBasContext;
      fFreeContext: BOOLEAN;
      fScanner: TBasScanner;
      fLabelList: ARRAY OF TBasLabel;
      fReturnStack: TBasStack;
      fAutoCreteVars: BOOLEAN;

      FUNCTION GetLineNum: INTEGER; INLINE;
    (* Arithmetic operations. *)
      PROCEDURE Arithmetic;
    (* Bit arithmetic operations. *)
      PROCEDURE BitArithmetic;
    (* Bool arithmetic operations.  Actually only <=, >= and <>... *)
      PROCEDURE BOOLArithmetic;
    PROTECTED
    (* Changes the current contexty by the given one.  Note that if @link(OwnContext)
      is @true it will destroy the current context before to assign the new one.
      @seealso(Context) *)
      PROCEDURE SetContext (aContext: TBasContext);
    (* Implements the BAScript's Dot operator.  By default, does an on-screen
      output using Pascal's @code(WriteLn). *)
      PROCEDURE Dot; VIRTUAL;
    (* Calls the requested method.  If it doesn't exists, it raises a
      @link(BasRuntimeError). *)
      PROCEDURE CallMethod (CONST aName: STRING); // INLINE;
    PUBLIC
    (* Constructor.  You should provide a context, even if you'll change it
       later. @seealso(SetScript) @seealso(Reset) *)
      CONSTRUCTOR Create (aContext: TBasContext; CONST aFreeContext: BOOLEAN = FALSE);
    (* Frees resources.  @seealso(OwnContext) *)
      DESTRUCTOR Destroy; OVERRIDE;
    (* Sets the script program that will be executed by the interpretor.

      This method will call method @link(Reset) after preparing the script.
      @seealso(Reset) @seealso(Run) @seealso(Context) *)
      PROCEDURE SetScript (CONST aScript: ANSISTRING); VIRTUAL;
    (* Resets the interpretor.

      This method will reset the program counter and the return stack, but it
      will keep the variables and the data stack. @seealso(SetScript) *)
      PROCEDURE Reset; VIRTUAL;
    (* Executes or continues the script.
      @seealso(SetScript) @seealso(Reset) @seealso(RunStep) @seealso(Context) *)
      PROCEDURE Run; INLINE;
    (* Executes next command of the current script and stops.

      Note that it doesn't check some critical stuff (such as the current
      context). @seealso(Run) *)
      PROCEDURE RunStep;
    (* Returns the internal identification of the given label or @(-1@) if
      label doesn't exists.  @seealso(DoGoto) @seealso(GotoLabel) *)
      FUNCTION LabelId (aLabel: STRING): INTEGER;
    (* Changes current program position to the label, identifying the label by
      it's numeric identifier.

      Note that this method doesn't executes any code.  You must call
      @link(Run) or @link(RunStep) to execute the script.
      @seealso(LabelId) @seealso(GotoLabel)
      @param(aLabelId Identifier of label, as returned by @code(LabelId).) *)
      PROCEDURE DoGoto (CONST aLabelId: INTEGER); INLINE;
    (* Changes current program position to the label.

      Note that this method doesn't executes any code.  You must call
      @link(Run) or @link(RunStep) to execute the script.
      @seealso(DoGoto) @param(aLabel Label.) *)
      PROCEDURE GotoLabel (CONST aLabel: STRING); INLINE;

    (* A string that can be used to identify the interpretor.  I.E. the script
      file name. *)
      PROPERTY Name: STRING READ fIdentifier WRITE fIdentifier;
    (* Context used by the virtual machine.  Note that if @link(OwnContext) is
      @true it will destroy the current context before to assign the new one.
      @seealso(Run)
     *)
      PROPERTY Context: TBasContext READ fContext WRITE setContext;
    (* Set to @true to create variables automathically or @false to raise a
      @link(BasRuntimeError) if the requested variable doesn't exist.  Default
      is @true. @seealso(Context) *)
      PROPERTY AutoCreateVars: BOOLEAN READ fAutoCreteVars WRITE fAutoCreteVars;
    (* If @true, the context will be destroyed when not needed.
      @seealso(Context) *)
      PROPERTY OwnContext: BOOLEAN READ fFreeContext WRITE fFreeContext;
    (* The return address stack.  By default its size is 128, which is enough
      for most scripts but you may want to make it bigger to have more address
      or make it smaller to save memory. @seealso(Reset) *)
      PROPERTY ReturnStack: TBasStack READ fReturnStack;
    (* The current line in execution. @seealso(SetScript) *)
      PROPERTY LineNum: INTEGER READ GetLineNum;
    END;



  (* Generic BAScript exception. @seealso(BasRuntimeError) *)
    BasException = CLASS (Exception)
    PRIVATE
      fError: TBasErrors;
    PUBLIC
    (* Constructs a new exception object of the given error type. *)
      CONSTRUCTOR Create (bsdError: TBasErrors); OVERLOAD;
    (* Error identifier. *)
      PROPERTY ErrorType: TBasErrors READ fError;
    END;




  (* Exception raised while running a BAScript program. @seealso(BasException) *)
    BasRuntimeError = CLASS (BasException)
    PRIVATE
      fInterpretor: TBasInterpretor;
    PUBLIC
    (* Constructs a new exception object of the given error message. *)
      CONSTRUCTOR Create (MsgError: STRING; aInterpretor: TBasInterpretor); OVERLOAD;
    (* Constructs a new exception object of the given error type. *)
      CONSTRUCTOR Create (bsdError: TBasErrors; aInterpretor: TBasInterpretor); OVERLOAD;
    (* Reference to the interpretor. *)
      PROPERTY InterpretorRef: TBasInterpretor READ fInterpretor;
    END;



(* Given a name, returns it in a normalised way, so it can be used as object
   name, such as variable or method.

   If given name cannot be normalised, it will raise a @link(BasException).

   To be normalised, the given string must consist of a letter, dot or
   underscore, followed by a combination of letters, numbers, dots, hyphens or
   underscores.
 *)
  FUNCTION NormalizeName (CONST aName: STRING): STRING;

IMPLEMENTATION

(*
 * TBasValue
 ****************************************************************************)

  FUNCTION TBasValue.getAsInteger: INTEGER;
  BEGIN
    IF fDataType = bdtInteger THEN EXIT (fisInteger);
    RESULT := $7FFFFFFF * -1;
  END;



  PROCEDURE TBasValue.setAsInteger (aValue: INTEGER);
  BEGIN
    fDataType := bdtInteger;
    fisString := '';
    fisInteger := aValue
  END;



  FUNCTION TBasValue.getAsString: STRING;
  BEGIN
    CASE fDataType  OF
      bdtInteger: getAsString := IntToStr (fisInteger);
      bdtString:  getAsString := fisString;
      ELSE        getAsString := '';
    END
  END;



  PROCEDURE TBasValue.setAsString (aValue: STRING);
  BEGIN
    fDataType := bdtString;
    fisString := aValue
  END;



(* Creates a void value. *)
  CONSTRUCTOR TBasValue.Create;
  BEGIN
    INHERITED Create;
    fDataType := bdtVoid
  END;



(* Assigns another value. *)
  PROCEDURE TBasValue.Assign (CONST aValue: TBasValue);
  BEGIN
    fDataType := aValue.fDataType;
    fisInteger := aValue.fisInteger;
    fisString := aValue.fisString
  END;



(* Assigns to VOID. *)
  PROCEDURE TBasValue.SetVoid;
  BEGIN
    fDataType := bdtVoid;
    fisString := ''
  END;



(*
 * TBasVariable
 ****************************************************************************)

(* Constructor. *)
  CONSTRUCTOR TBasVariable.Create (aName: STRING);
  BEGIN
    INHERITED Create;
    fName := NormalizeName (aName)
  END;



(*
 * TBasVarList
 ****************************************************************************)

  FUNCTION TBasVarList.getCount: INTEGER;
  BEGIN
    getCount := fVarList.Count
  END;



  FUNCTION TBasVarList.getVariable (Ndx: INTEGER): TBasVariable;
  BEGIN
    getVariable := TBasVariable (fVarList.Items[Ndx])
  END;



(* Constructor. *)
  CONSTRUCTOR TBasVarList.Create;
  BEGIN
    INHERITED Create;
    fVarList := TFPObjectList.Create (TRUE)
  END;



(* Destructor. *)
  DESTRUCTOR TBasVarList.Destroy;
  BEGIN
    fVarList.Free;
    INHERITED Destroy
  END;



(* Adds a new variable to the list. *)
  FUNCTION TBasVarList.CreateVariable (aName: STRING): INTEGER;
  BEGIN
    IF SELF.IndexOf (aName) >= 0 THEN
      RAISE BasException.Create (bseDuplicateDefinition);
    CreateVariable := fVarList.Add (TBasVariable.Create (aName))
  END;



(* Searchs the requested variable. *)
  FUNCTION TBasVarList.IndexOf (aName: STRING): INTEGER;
  VAR
    Ndx: INTEGER;
  BEGIN
    aName := NormalizeName (aName);
    FOR Ndx := 0 TO (fVarList.Count - 1) DO
      IF fVarList.Items[Ndx] <> NIL THEN
	IF SELF.Variables[Ndx].Name = aName THEN
	  EXIT (Ndx);
    IndexOf := -1
  END;



(* Removes the variable from the list. *)
  PROCEDURE TBasVarList.DeleteVariable (Ndx: INTEGER);
  BEGIN
    fVarList.Delete (Ndx)
  END;



(* Destroys all variables from the list. *)
  PROCEDURE TBasVarList.Clear;
  BEGIN
    fVarList.Clear
  END;



(*
 * TBasStack
 ****************************************************************************)

  FUNCTION TBasStack.getStackSize: INTEGER;
  BEGIN
    getStackSize := Length (fStack)
  END;



  PROCEDURE TBasStack.setStackSize (CONST aSize: INTEGER);
  BEGIN
    SetLength (fStack, aSize);
    fTop := LOW (fStack)
  END;



(* Constructor. *)
  CONSTRUCTOR TBasStack.Create (aSize: INTEGER);
  BEGIN
    INHERITED Create;
    SetLength (fStack, aSize);
    fTop := LOW (fStack)
  END;


(* Pushes value. *)
  PROCEDURE TBasStack.Push (aValue: LONGINT);
  BEGIN
    IF fTop <= HIGH (fStack) THEN
    BEGIN
      fStack[fTop] := aValue;
      INC (fTop)
    END
    ELSE
      RAISE BasException.Create (bseFullDataStack)
  END;



(* Pops a 32 bit signed integer. *)
  FUNCTION TBasStack.Pop: INTEGER;
  BEGIN
    IF fTop > LOW (fStack) THEN
    BEGIN
      DEC (fTop);
      RESULT := fStack[fTop]
    END
    ELSE
      RAISE BasException.Create (bseEmptyDataStack)
  END;



(* Duplicates top. *)
  PROCEDURE TBasStack.DUP;
  BEGIN
    IF fTop > LOW (fStack) THEN
      SELF.Push (fStack[fTop - 1])
    ELSE
      RAISE BasException.Create (bseEmptyDataStack)
  END;



(* Swap top values. *)
  PROCEDURE TBasStack.SWAP;
  VAR
    V1, V2: LONGINT;
  BEGIN
    V1 := SELF.Pop; V2 := SELF.Pop;
    SELF.Push (V1); SELF.Push (V2)
  END;



(* Rotates top 3 values. *)
  PROCEDURE TBasStack.ROT;
  VAR
    V1, V2, V3: LONGINT;
  BEGIN
    V1 := SELF.Pop; V2 := SELF.Pop; V3 := SELF.Pop;
    SELF.Push (V1); SELF.Push (v3); SELF.Push (V2)
  END;



(* Discards top value. *)
  PROCEDURE TBasStack.DROP;
  BEGIN
    IF fTop > LOW (fStack) THEN
      DEC (fTop)
    ELSE
      RAISE BasException.Create (bseEmptyDataStack)
  END;



(* Clears the stack. *)
  PROCEDURE TBasStack.Clear;
  BEGIN
    fTop := LOW (fStack)
  END;



(* Adds the content of another stack to this one. *)
  PROCEDURE TBasStack.Add (aStack: TBasStack);
  VAR
    Ndx: INTEGER;
  BEGIN
    FOR Ndx := LOW (aStack.fStack) TO (aStack.fTop - 1) DO
      SELF.Push (aStack.fStack[Ndx])
  END;



(* Assign the content of another stack to this one. *)
  PROCEDURE TBasStack.Assign (aStack: TBasStack);
  BEGIN
    SELF.setStackSize (aStack.getStackSize);
    SELF.Add (aStack)
  END;



(* Checks if stack is empty. *)
  FUNCTION TBasStack.IsEmpty: BOOLEAN;
  BEGIN
    IsEmpty := fTop = LOW (fStack)
  END;



(* Checks if stack is full. *)
  FUNCTION TBasStack.IsFull: BOOLEAN;
  BEGIN
    IsFull := fTop > HIGH (fStack)
  END;



(*
 * TBasDataStack
 ****************************************************************************)

  FUNCTION TBasDataStack.getDataType: TBasDataType;
  BEGIN
    IF fTop > LOW (fStack) THEN EXIT (fTypesStack[fTop - 1]);
    getDataType := bdtVoid
  END;



  PROCEDURE TBasDataStack.setStackSize (CONST aSize: INTEGER);
  BEGIN
    INHERITED setStackSize (aSize);
    SetLength (fTypesStack, aSize)
  END;



(* Constructor. *)
  CONSTRUCTOR TBasDataStack.Create (aSize: INTEGER);
  BEGIN
    INHERITED Create (aSize);
    SetLength (fTypesStack, aSize)
  END;



(* Pushes value. *)
  PROCEDURE TBasDataStack.Push (aValue: LONGINT);
  BEGIN
    INHERITED Push (aValue);
    fTypesStack[fTop - 1] := bdtInteger
  END;



  PROCEDURE TBasDataStack.PushString (aString: STRING);
  VAR
    Ndx: INTEGER;
  BEGIN
    FOR Ndx := Length (aString) DOWNTO 1 DO
      SELF.Push (ORD (aString[Ndx]));
    SELF.Push (Length (aString));
    fTypesStack[fTop - 1] := bdtString
  END;



  PROCEDURE TBasDataStack.PushValue (aValue: TBasValue);
  BEGIN
    IF aValue.DataType = bdtInteger THEN
      SELF.Push (aValue.asInteger)
    ELSE IF aValue.DataType = bdtString THEN
      SELF.PushString (aValue.asString)
  END;



(* Pops a string. *)
  FUNCTION TBasDataStack.PopString: STRING;
  VAR
    Lng, Ndx: INTEGER;
  BEGIN
    Lng := SELF.Pop;
    PopString := StringOfChar (' ', Lng);
    FOR Ndx := 1 TO Length (PopString) DO
      PopString[Ndx] := CHAR (SELF.Pop AND $000000FF);
  END;



(* Pops a value. *)
  PROCEDURE TBasDataStack.PopValue (aValue: TBasValue);
  BEGIN
    CASE getDataType OF
      bdtInteger: aValue.asInteger := SELF.Pop;
      bdtString:  aValue.asString := SELF.PopString;
      ELSE        aValue.SetVoid;
    END
  END;



(* Adds the content of another stack to this one. *)
  PROCEDURE TBasDataStack.Add (aStack: TBasDataStack);
  VAR
    Ndx: INTEGER;
  BEGIN
    FOR Ndx := LOW (aStack.fStack) TO (aStack.fTop - 1) DO
    BEGIN
      SELF.Push (aStack.fStack[Ndx]);
      fTypesStack[fTop - 1] := aStack.fTypesStack[fTop - 1]
    END
  END;



(* Assign the content of another stack to this one.  It also may modify the
  size and the top place. *)
  PROCEDURE TBasDataStack.Assign (aStack: TBasDataStack);
  BEGIN
    SELF.setStackSize (aStack.getStackSize);
    SELF.Add (aStack)
  END;



(*
 * TBasMethodList
 ****************************************************************************)

  FUNCTION TBasMethodList.getMethod (CONST Ndx: INTEGER): TBasMethodReference;
  BEGIN
    IF (LOW (fMethodList) > Ndx) OR (Ndx > HIGH (fMethodList)) THEN
      RAISE BasException.Create (bseNoMethod);
    IF fMethodList[Ndx].Method = NIL THEN
      RAISE BasException.Create (bseNoMethod);
    getMethod := fMethodList[Ndx].Method
  END;



(* Adds method to the list.  Overwrites if method yet exists. *)
  PROCEDURE TBasMethodList.Add (aName: STRING; aMethod: TBasMethodReference);
  VAR
    Ndx, FreeItem: INTEGER;
  BEGIN
    aName := NormalizeName (aName); FreeItem := -1;
    FOR Ndx := LOW (fMethodList) TO HIGH (fMethodList) DO
    BEGIN
      IF (FreeItem < 0) AND (fMethodList[Ndx].Name = '') THEN
	FreeItem := Ndx
      ELSE IF fMethodList[Ndx].Name = aName THEN
      BEGIN
	fMethodList[Ndx].Method := aMethod;
	EXIT
      END
    END;
    IF FreeItem < 0 THEN
    BEGIN
      FreeItem := Length (fMethodList);
      SetLength (fMethodList, FreeItem + 1)
    END;
    fMethodList[FreeItem].Name := aName;
    fMethodList[FreeItem].Method := aMethod
  END;



(* Removes the method from the list. *)
  PROCEDURE TBasMethodList.Remove (aName: STRING);
  VAR
    Ndx: INTEGER;
  BEGIN
    aName := NormalizeName (aName);
    FOR Ndx := LOW (fMethodList) TO HIGH (fMethodList) DO
    BEGIN
      IF fMethodList[Ndx].Name = aName THEN
      BEGIN
	fMethodList[Ndx].Name := '';
	EXIT
      END
    END
  END;



(* Removes ALL methods from the list. *)
  PROCEDURE TBasMethodList.Clear;
  BEGIN
    SetLength (fMethodList, 0)
  END;



(* Returns the requested method or -1 if it doesn't exists. *)
  FUNCTION TBasMethodList.IndexOf (aName: STRING): INTEGER;
  VAR
    Ndx: INTEGER;
  BEGIN
    aName := NormalizeName (aName);
    FOR Ndx := LOW (fMethodList) TO HIGH (fMethodList) DO
      IF fMethodList[Ndx].Name = aName THEN
	EXIT (Ndx);
    IndexOf := -1
  END;



(*
 * TBasContext
 ****************************************************************************)

(* Constructor. *)
  CONSTRUCTOR TBasContext.Create (CONST aStackSize: INTEGER);
  BEGIN
    INHERITED Create;
    fDataStack := TBasDataStack.Create (aStackSize);
    fVarList   := TBasVarList.Create;
    fMethodList := TBasMethodList.Create
  END;



(* Destructor. *)
  DESTRUCTOR TBasContext.Destroy;
  BEGIN
    fDataStack.Free;
    fVarList.Free;
    fMethodList.Free;
    INHERITED Destroy
  END;



(*
 * TBasScanner
 ****************************************************************************)

  PROCEDURE TBasScanner.setSource (CONST aSource: ANSISTRING);
  BEGIN
    fSource := aSource; fsPos := 1; Character := ' ';
    fSymbol := ''; fSymbolId := BSY_NONE
  END;



(* Helper to get a character. *)
  PROCEDURE TBasScanner.NextChar;
  BEGIN
    IF fsPos <= Length (fSource) THEN
    BEGIN
      Character := fSource[fsPos]; INC (fsPos)
    END
    ELSE
      Character := #0
  END;



(* Extract the next symbol.  Stores the information in @link(Symbol) and
  @link(SymbolId). *)
  PROCEDURE TBasScanner.GetSymbol;

  (* Skips white spaces, line jumps and comments. *)
    PROCEDURE SkipSpaces;
    BEGIN
      WHILE (fsPos <= Length (fSource))
      AND (Character <= ' ') DO
	SELF.NextChar;
      IF Character = ';' THEN
      BEGIN
	REPEAT
	  SELF.NextChar
	UNTIL Character < ' ';
	SkipSpaces
      END
    END;



  (* Gets a quoted string as a single token. *)
    PROCEDURE GetString;
    VAR
      Marker: CHAR;
    BEGIN
      Marker := Character;
      SELF.NextChar;
      fSymbolId := BSY_STRING; fSymbol := '';
      WHILE (Character <> Marker) { AND (Character >= ' ') } DO
      BEGIN
	fSymbol := fSymbol + Character;
	SELF.NextChar
      END;
      IF Character < ' ' THEN RAISE BasException.Create (bseIllegalCharStream);
      SELF.NextChar
    END;



    PROCEDURE GetToken;
    BEGIN
      fSymbol := '';
      WHILE (Character > ' ') DO
      BEGIN
	fSymbol := fSymbol + Upcase (Character);
	SELF.NextChar
      END
    END;

  BEGIN
    SkipSpaces;
    CASE Character OF
    '"', '''' :
      GetString;
    '0' .. '9', '-':
      BEGIN
	GetToken;
	fSymbolId := BSY_INTEGER
      END;
    ':':
      BEGIN
	SELF.NextChar; { Jump the marker ":". }
	GetToken;
	fSymbolId := BSY_LABEL
      END;
    ELSE
      BEGIN
	GetToken;
	IF fSymbol <> '' THEN
	  fSymbolId := BSY_OPERATOR
	ELSE
	  fSymbolId := BSY_NONE
      END;
    END;
{ TODO: Debugger
WriteLn (' --> "', fSymbol, '" (', fSymbolId, ')');
}
  END;



(* @return(@true) if it's beyond the end the source, @false otherwise.) *)
  FUNCTION TBasScanner.EOF: BOOLEAN;
  BEGIN
    EOF := fsPos > Length (fSource)
  END;



(* @return(Current source line.) *)
  FUNCTION TBasScanner.LineNum: INTEGER;
  VAR
    Ndx: INTEGER;
  BEGIN
    Ndx := 1; LineNum := 1;
    WHILE Ndx < fsPos DO
    BEGIN
      IF fSource[Ndx] = #10 THEN INC (LineNum);
      INC (Ndx)
    END;
  { If current position is a line-feed, then roll back because it counted one
    line more than the actual line. }
    IF fSource[Ndx - 1] = #10 THEN DEC (LineNum)
  END;



(*
 * TBasInterpretor
 ****************************************************************************)

  FUNCTION TBasInterpretor.GetLineNum: INTEGER;
  BEGIN
    GetLineNum := fScanner.LineNum
  END;



(* Arithmetic operations. *)
  PROCEDURE TBasInterpretor.Arithmetic;
  VAR
    V1, V2: LONGINT;
  BEGIN
    V1 := fContext.fDataStack.Pop;
    IF (fScanner.Symbol[1] IN ['/', '\', '%']) AND (V1 = 0) THEN
      RAISE BasRuntimeError.Create (bseDivisionByZero, SELF);
    V2 := fContext.fDataStack.Pop;
    CASE fScanner.Symbol OF
      '+': fContext.fDataStack.Push (V2 + V1);
      '-': fContext.fDataStack.Push (V2 - V1);
      '*': fContext.fDataStack.Push (V2 * V1);
      '/', '\': fContext.fDataStack.Push (V2 DIV V1);
      '%': fContext.fDataStack.Push (V2 MOD V1);
    END
  END;



(* Arithmetic operations. *)
  PROCEDURE TBasInterpretor.BitArithmetic;
  VAR
    V1, V2, R: LONGINT;

  BEGIN
    V1 := fContext.fDataStack.Pop;
    V2 := fContext.fDataStack.Pop;
    CASE fScanner.Symbol OF
      '=': IF V2 = V1 THEN R := BAS_TRUE ELSE R := BAS_FALSE;
      '<': IF V2 < V1 THEN R := BAS_TRUE ELSE R := BAS_FALSE;
      '>': IF V2 > V1 THEN R := BAS_TRUE ELSE R := BAS_FALSE;
      '&': R := V2 AND V1;
      '|': R := V2 OR V1;
      '^': R := V2 XOR V1;
      ELSE R := 0;
    END;
    fContext.fDataStack.Push (R)
  END;



(* Bool operations. *)
  PROCEDURE TBasInterpretor.BOOLArithmetic;
  VAR
    V1, V2, R: LONGINT;
  BEGIN
    V1 := fContext.fDataStack.Pop;
    V2 := fContext.fDataStack.Pop;
    R := 0;
    IF fScanner.Symbol = '<>' THEN IF V2 <> V1 THEN R := BAS_TRUE ELSE R := BAS_FALSE;
    IF fScanner.Symbol = '<=' THEN IF V2 <= V1 THEN R := BAS_TRUE ELSE R := BAS_FALSE;
    IF fScanner.Symbol = '>=' THEN IF V2 >= V1 THEN R := BAS_TRUE ELSE R := BAS_FALSE;
    fContext.fDataStack.Push (R)
  END;



  PROCEDURE TBasInterpretor.setContext (aContext: TBasContext);
  BEGIN
    IF fFreeContext THEN FreeAndNil (fContext);
    fContext := aContext
  END;



(* Dot operator. *)
  PROCEDURE TBasInterpretor.Dot;
  BEGIN
    CASE fContext.fDataStack.TopDataType OF
      bdtInteger: WriteLn (fContext.fDataStack.Pop);
      bdtString:  WriteLn (fContext.fDataStack.PopString);
      ELSE        WriteLn (fContext.fDataStack.Pop);
    END
  END;



(* Calls the requested method.  @error(Raises a @link(BasRuntimeError) *)
  PROCEDURE TBasInterpretor.CallMethod (CONST aName: STRING);
  VAR
    NdxMethod: INTEGER;
    TheMethod: TBasMethodReference;
  BEGIN
    NdxMethod := fContext.fMethodList.IndexOf (aName);
    IF NdxMethod < 0 THEN RAISE BasRuntimeError.Create (bseNoMethod, SELF);
    TheMethod := fContext.fMethodList[NdxMethod];
    TheMethod (fContext)
  END;



(* Constructor. *)
  CONSTRUCTOR TBasInterpretor.Create (aContext: TBasContext; CONST aFreeContext: BOOLEAN);
  BEGIN
    INHERITED Create;
    fContext := aContext;
    fFreeContext := aFreeContext;
    fScanner := TBasScanner.Create;
    fReturnStack := TBasStack.Create (128);
    fAutoCreteVars := TRUE
  END;



(* Destructor. *)
  DESTRUCTOR TBasInterpretor.Destroy;
  BEGIN
    IF fFreeContext THEN fContext.Free;
    fReturnStack.Free;
    fScanner.Free;
    INHERITED Destroy
  END;



(* Sets the script program that will be executed by the interpretor. *)
  PROCEDURE TBasInterpretor.SetScript (CONST aScript: ANSISTRING);
  VAR
    Ndx: INTEGER;
  BEGIN
    fScanner.Source := aScript;
  { Look for labels. }
    Ndx := 0;
    REPEAT
      fScanner.GetSymbol;
      IF fScanner.SymbolId = BSY_LABEL THEN
      BEGIN
	SetLength (fLabelList, Ndx + 1);
	fLabelList[Ndx].Name := fScanner.Symbol;
	fLabelList[Ndx].Addr := fScanner.fsPos;
	INC (Ndx)
      END
    UNTIL fScanner.EOF;
  { Reset interpretor. }
    SELF.Reset
  END;



(* Resets the interpretor. *)
  PROCEDURE TBasInterpretor.Reset;
  BEGIN
    fScanner.fsPos := 1;
    fReturnStack.Clear
  END;



(* Executes or continues the script. @seealso(RunStep) *)
  PROCEDURE TBasInterpretor.Run;
  BEGIN
    IF fContext = NIL THEN
      RAISE BasRuntimeError.Create (bseNoContext, SELF);
    WHILE NOT fScanner.EOF DO SELF.RunStep
  END;



(* Executes one single step of the script. *)
  PROCEDURE TBasInterpretor.RunStep;
  VAR
    Ndx: INTEGER;

  (* The "IF". *)
    PROCEDURE CommandIF; INLINE;
    BEGIN
      IF fContext.fDataStack.Pop = BAS_FALSE THEN
      BEGIN
	Ndx := 1;
	REPEAT
	  fScanner.GetSymbol;
	  IF (Ndx = 1)
	  AND ((fScanner.Symbol = 'ELSE') OR (fScanner.Symbol = 'FI')) THEN
	    Ndx := 0
	  ELSE IF fScanner.Symbol = 'IF' THEN
	    INC (Ndx)
	  ELSE IF fScanner.Symbol = 'FI' THEN
	    DEC (Ndx)
	UNTIL fScanner.EOF OR (Ndx = 0);
	IF Ndx > 0 THEN RAISE BasRuntimeError.Create (bseIFWithoutFI, SELF)
      END;
    END;

  (* The "ELSE". *)
    PROCEDURE CommandELSE; INLINE;
    BEGIN
      Ndx := 1;
      REPEAT
	fScanner.GetSymbol;
	IF (Ndx = 1)
	AND ((fScanner.Symbol = 'ELSE') OR (fScanner.Symbol = 'FI')) THEN
	  Ndx := 0
	ELSE IF fScanner.Symbol = 'IF' THEN
	  INC (Ndx)
	ELSE IF fScanner.Symbol = 'FI' THEN
	  DEC (Ndx)
      UNTIL fScanner.EOF OR (Ndx = 0);
      IF Ndx > 0 THEN RAISE BasRuntimeError.Create (bseIFWithoutFI, SELF)
    END;

    PROCEDURE LastChance;
    BEGIN
      Ndx := fContext.fVarList.IndexOf (fScanner.Symbol);
      IF Ndx < 0 THEN RAISE BasRuntimeError.Create (bseUnknownOperation, SELF);
      fContext.fDataStack.PushValue (fContext.fVarList.Variables[Ndx])
    END;

  (* Helper to push return addresses. *)
    PROCEDURE PushReturnAddr (CONST aAddr: INTEGER); INLINE;
    BEGIN
      IF NOT SELF.fReturnStack.IsFull THEN
	SELF.fReturnStack.Push (aAddr)
      ELSE
	RAISE BasRuntimeError.Create (bseFullCodeStack, SELF)
    END;

  (* Helper to push label on return stack. *)
    PROCEDURE PushLabel; INLINE;
    BEGIN
      Ndx := LabelId (Copy (fScanner.Symbol, 3, Length (fScanner.Symbol)));
      IF Ndx < 0 THEN RAISE BasRuntimeError.Create (bseNoLabel, SELF);
      PushReturnAddr (fLabelList[Ndx].Addr)
    END;

  VAR
    VName: STRING;
  BEGIN
    TRY
{ TODO: Debugger
    Write ('@', SELF.GetLineNum);
}
      fScanner.GetSymbol;
      CASE fScanner.SymbolId OF
      BSY_INTEGER:
	fContext.fDataStack.Push (StrToInt(fScanner.Symbol));
      BSY_STRING:
	fContext.fDataStack.PushString (fScanner.Symbol);
      BSY_OPERATOR:
	IF (Length (fScanner.Symbol) > 1)
	AND (fScanner.Symbol[1] IN ['#', '%', '$', '&', '?']) THEN
	BEGIN
	  VName := Copy (fScanner.Symbol, 2, Length (fScanner.Symbol));
	  Ndx := fContext.fVarList.IndexOf (VName);
	  IF Ndx < 0 THEN
          BEGIN
	    IF fAutoCreteVars THEN
	      Ndx := fContext.fVarList.CreateVariable (VName)
	    ELSE
	      RAISE BasRuntimeError.Create (bseNoVariable, SELF)
          END;
	  CASE fScanner.Symbol[1] OF
	  '#':
	    fContext.fVarList.Variables[Ndx].asInteger := fContext.fDataStack.Pop;
	  '$':
	    fContext.fVarList.Variables[Ndx].asString := fContext.fDataStack.PopString;
	  '?':
	    fContext.fDataStack.PopValue (fContext.fVarList.Variables[Ndx]);
          ELSE
            RAISE BasRuntimeError.Create (bseNotImplemented, SELF);
	  END
	END
	ELSE CASE Length (fScanner.Symbol) OF
	1:
	  IF fScanner.Symbol[1] IN ['+', '-', '*', '/', '\', '%'] THEN
	    SELF.Arithmetic
	  ELSE IF fScanner.Symbol[1] IN ['=', '<', '>', '&', '|', '^'] THEN
	    SELF.BitArithmetic
	  ELSE IF fScanner.Symbol[1] = '.' THEN
	    SELF.Dot
	  ELSE IF fScanner.Symbol[1] = '@' THEN
	    PushReturnAddr (fScanner.fsPos)
	  ELSE
	    LastChance;
	2:
	  IF fScanner.Symbol[1] IN ['<', '>'] THEN
	    SELF.BOOLArithmetic
	  ELSE IF fScanner.Symbol = 'IF' THEN
	    CommandIF
	  ELSE IF fScanner.Symbol = 'FI' THEN
	  BEGIN { Ignore } END
	  ELSE
	    LastChance;
	3:
	  IF fScanner.Symbol = 'NOT' THEN
	    fContext.fDataStack.Push (NOT fContext.fDataStack.Pop)
	  ELSE IF fScanner.Symbol = 'DUP' THEN
	    fContext.fDataStack.DUP
	  ELSE IF fScanner.Symbol = 'ROT' THEN
	    fContext.fDataStack.ROT
	  ELSE IF fScanner.Symbol = 'RET' THEN
	  BEGIN
	    IF NOT SELF.fReturnStack.IsEmpty THEN
	      fScanner.fsPos := fReturnStack.Pop
	    ELSE
	      RAISE BasRuntimeError.Create (bseEmptyCodeStack, SELF)
	  END
	  ELSE IF LeftStr (fScanner.Symbol, 2) = '@:' THEN
	    PushLabel
	  ELSE
	    LastChance;
	4:
          IF fScanner.Symbol = 'DROP' THEN
            fContext.fDataStack.DROP
	  ELSE IF fScanner.Symbol = 'SWAP' THEN
	  fContext.fDataStack.SWAP
	  ELSE IF fScanner.Symbol = 'NORT' THEN
	  BEGIN
	    IF NOT SELF.fReturnStack.IsEmpty THEN
	      fReturnStack.DROP
	    ELSE
	      RAISE BasRuntimeError.Create (bseEmptyCodeStack, SELF)
	  END
	  ELSE IF fScanner.Symbol = 'ELSE' THEN
	    CommandELSE
	  ELSE IF LeftStr (fScanner.Symbol, 2) = '@:' THEN
	    PushLabel
	  ELSE
	    LastChance;
	ELSE
	  IF LeftStr (fScanner.Symbol, 2) = '@:' THEN
	    PushLabel
	  ELSE IF LeftStr (fScanner.Symbol, 4) = 'SUB:' THEN
	  BEGIN
	    PushReturnAddr (fScanner.fsPos);
	    SELF.GotoLabel (
	      Copy (fScanner.fSymbol, 5, Length (fScanner.fSymbol))
	    )
	  END
	  ELSE IF LeftStr (fScanner.Symbol, 5) = 'GOTO:' THEN
	    SELF.GotoLabel (
	      Copy (fScanner.fSymbol, 6, Length (fScanner.fSymbol))
	    )
	  ELSE IF LeftStr (fScanner.Symbol, 5) = 'CALL:' THEN
	    SELF.CallMethod (
	      Copy (fScanner.fSymbol, 6, Length (fScanner.fSymbol))
	    )
	  ELSE
	    LastChance;
	END
      END;
    EXCEPT
      ON Error: BasRuntimeError DO RAISE;
      ON Error: Exception DO RAISE BasRuntimeError.Create (Error.Message, SELF)
    END;
  END;



(* Returns the internal identification of the given label or @(-1@) if
  label doesn't exists. *)
  FUNCTION TBasInterpretor.LabelId (aLabel: STRING): INTEGER;
  VAR
    Ndx: INTEGER;
  BEGIN
    aLabel := NormalizeName (aLabel);
    FOR Ndx := LOW (fLabelList) TO HIGH (fLabelList) DO
      IF fLabelList[Ndx].Name = aLabel THEN
	EXIT (Ndx);
    LabelId := -1
  END;



(* Changes current program position to the label, identifying the label by
  it's numeric identifier. *)
  PROCEDURE TBasInterpretor.DoGoto (CONST aLabelId: INTEGER);
  BEGIN
    fScanner.fsPos := fLabelList[aLabelId].Addr
  END;



(* Changes current program position to the label. *)
  PROCEDURE TBasInterpretor.GotoLabel (CONST aLabel: STRING);
  VAR
    Ndx: INTEGER;
  BEGIN
    Ndx := LabelId (aLabel);
    IF Ndx < 0 THEN RAISE BasRuntimeError.Create (bseNoLabel, SELF);
    SELF.DoGoto (Ndx)
  END;



(*
 * BasException
 ****************************************************************************)

  CONSTRUCTOR BasException.Create (bsdError: TBasErrors);
  CONST
    ErrorStringList: ARRAY [0..17] OF STRING = (
     'No error',
     'Bad object name',
     'Type mismatch',
     'No context available',
     'Empty data stack',
     'Full data stack',
     'Duplicate definition',
     'End of source',
     'Illegal character in stream',
     'Division by zero',
     'IF without FI',
     'Can''t find requested label',
     'Empty code stack',
     'Full code stack',
     'Can''t find requested hosted method',
     'Can''t find requested variable',
     'Not implemented feature',
     'Unknown Operation'
   );
  BEGIN
    INHERITED Create (ErrorStringList [ORD (bsdError)]);
    fError := bsdError
  END;




(*
 * BasRuntimeError
 ****************************************************************************)

  CONSTRUCTOR BasRuntimeError.Create (MsgError: STRING; aInterpretor: TBasInterpretor);
  BEGIN
    INHERITED Create (MsgError);
    fInterpretor := aInterpretor
  END;

  CONSTRUCTOR BasRuntimeError.Create (bsdError: TBasErrors; aInterpretor: TBasInterpretor);
  BEGIN
    INHERITED Create (bsdError);
    fInterpretor := aInterpretor
  END;



(*****************************************************************************)

(* Given a name, returns it in a normalised way, so it can be used as object
   name, such as variable or method.

   If given name cannot be normalised, will raise a @link(BasException).
 *)
  FUNCTION NormalizeName (CONST aName: STRING): STRING;
  VAR
    Chr: INTEGER;
  BEGIN
    IF aName = '' THEN
      RAISE BasException.Create (bseBadName);
    IF aName[1] IN ['0'..'9', '-'] THEN RAISE BasException.Create (bseBadName);
    NormalizeName := UpperCase (aName);
    FOR Chr := 1 TO Length (NormalizeName) DO
      IF NOT (NormalizeName[Chr] IN ['A'..'Z', '0'..'9', '-', '_', '.']) THEN
        RAISE BasException.Create (bseBadName)
  END;

END.
