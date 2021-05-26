unit SyntaxHighlighting;
(*<Manages syntax highlighting.

   This unit includes built-in highlighters (courtesy of SynEdit).  This way
   the IDE will highlight some common languages even if no definition files are
   arailable.  Note that these highlighters will be overriden by custom
   definitions. *)
(*
  Copyright (c) 2018-2021 Guillermo Martínez J.

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

interface

  uses
    MLSDEHighlighter,
    SynEditHighlighter;

  type
  (* Contains the description of the syntax highlighters. *)
    THighlighterInfo = record
    (* Highlighter's name. *)
      Name,
    (* Extensions (comma separated). *)
      Extensions: String;
    (* Used internally to know if it is a built-in one or not. *)
      BuiltIn: Boolean;
    (* Reference to the highlighter.  It may be @nil. *)
      Highlighter: TMLSDEHighlighter
    end;



  (* Contains and manages the available syntax highlighters. *)
    TSynManager = class (TObject)
    private
      fHighlightStyle: TMLSDEHighlightStyle;
      fDefinitionList: array of THighlighterInfo;
      fNumHighlighters: Integer;

      function GetHighlighterInfo (const Ndx: Integer): THighlighterInfo;
        inline;

    (* Removes all definitions. *)
      procedure Clear;
    (* Looks for a highlighter by name and returns its index or -1 if not found.
     *)
      function GetLanguageIndex (aLanguage: String): Integer;
    (* Looks for a highlighter by extension and returns its index or -1 if not
       found. *)
      function GetExtensionIndex (aExtension: String): Integer;
    (* Returns the highlighter for the given index.

       May return Nil. *)
      function GetHighlighter (const aNdx: Integer): TMLSDEHighlighter; inline;
    public
    (* Constructor. *)
      constructor Create;
    (* Destructor. *)
      destructor Destroy; override;
    (* Initializes the manager.

       Can be used to reset or re-initialize. *)
      procedure Initialize;
    (* Returns the highlighter for the given language. *)
      function GetHighlighter (aLanguage: String): TMLSDEHighlighter;
    (* Returns the highlighter for the given extension. *)
      function GetHighlighterForExt (aExt: String): TMLSDEHighlighter;

    (* Reference to the highlight style. *)
      property Style: TMLSDEHighlightStyle read fHighlightStyle;
    (* How many highlighters available. *)
      property Count: Integer read fNumHighlighters;
    (* Access to the highligthers information.
       @seealso(GetHighlighterForExt) *)
      property Highlighters[Ndx: Integer]: THighlighterInfo
        read GetHighlighterInfo;
    end;

implementation

  uses
    Utils,
    StrUtils, sysutils,
  { Built-in syntax highlighters. }
    MLSDEHighlighterINI, MLSDEHighlighterMLSDE;



(*
 * Built-in syntax highlighters.
 ***************************************************************************)
  type
  (* Built in highlighter information. *)
    TBuiltInHighlighter = record
      Name, Extensions: String;
      HighlighterClass: TMLSDEHighlighterClass
    end;

  var
  (* List of built-in highlighters.

     This is populated at the initialization section. *)
    BuiltInHighlighters: array [0..1] of TBuiltInHighlighter = (
      (Name: 'INI'; Extensions: 'ini'; HighlighterClass: TMLSDEINISyn),
      (Name: 'Syntax definition file';
       Extensions: 'sld';
       HighlighterClass: TMLSDESyntaxDefinitionSyn
      )
    );



 (* Creates a built-in highlighter. *)
  function GetBuiltInHighlighter (aName: String): TMLSDEHighlighter;
  var
    Ndx: Integer;
  begin
    aName := LowerCase (aName);
    for Ndx := Low (BuiltInHighlighters) to High (BuiltInHighlighters) do
      if LowerCase (BuiltInHighlighters[Ndx].Name) = aName then
      begin
        Result := BuiltInHighlighters[Ndx].HighlighterClass.Create (Nil);
        Result.Language := BuiltInHighlighters[Ndx].Name;
        Exit
      end;
    Result := Nil
  end;



(*
 * TSynManager
 ***************************************************************************)

  const
  (* Minimal size for the syntax description list. *)
    MinDefinitionList = 16;
  (* How much the lists grows when needed. *)
    ListGrow = 4;

  function TSynManager.GetHighlighterInfo (const Ndx: Integer)
    : THighlighterInfo;
  begin
    if Ndx >= fNumHighlighters then
      raise ERangeError.Create ('Index out of range.');
    Result := fDefinitionList[Ndx]
  end;



(* Removes definitions. *)
  procedure TSynManager.Clear;
  var
    Ndx: Integer;
  begin
  { Destroy highlighters (if any). }
    if fNumHighlighters > 0 then
      for Ndx := 0 to fNumHighlighters - 1 do
        if Assigned (fDefinitionList[Ndx].Highlighter) then
          FreeAndNil (fDefinitionList[Ndx].Highlighter);
    fNumHighlighters := 0;
  { Reserve space for definition list.

    First time, it reserves for the minimal, but later (when opening new
    project) it reserves for all them as it knows how many they are. }
    SetLength (fDefinitionList, 0);
    if fNumHighlighters > 0 then
      SetLength (fDefinitionList, fNumHighlighters)
    else
      SetLength (fDefinitionList, MinDefinitionList)
  end;



(* Looks for a highlighter. *)
  function TSynManager.GetLanguageIndex (aLanguage: String): Integer;
  var
    Ndx: Integer;
  begin
    aLanguage := LowerCase (aLanguage);
    for Ndx := Low (fDefinitionList) to fNumHighlighters - 1 do
    begin
      if LowerCase (fDefinitionList[Ndx].Name) = aLanguage then Exit (Ndx)
    end;
  { Not found, so... }
    Result := -1
  end;



(* Looks for a highlighter by extension. *)
  function TSynManager.GetExtensionIndex (aExtension: String): Integer;
  var
    Ndx, lExt: Integer;
    lExtensions: array of String;
  begin
    aExtension := LowerCase (aExtension);
    for Ndx := Low (fDefinitionList) to fNumHighlighters - 1 do
    begin
      lExtensions := SplitString (fDefinitionList[Ndx].Extensions, ',');
      lExt := FindString (aExtension, lExtensions);
      if lExt >= 0 then Exit (Ndx)
    end;
  { Not found, so... }
    Result := -1
  end;



(* Returns highlighter. *)
  function TSynManager.GetHighlighter (const aNdx: Integer): TMLSDEHighlighter;
  begin
    if (-1 < aNdx) and (aNdx < fNumHighlighters) then
    begin
    { Was the highlighter created yet? }
      if not Assigned (fDefinitionList[aNdx].Highlighter) then
      begin
      { Create the highlighter. }
        if fDefinitionList[aNdx].BuiltIn then
          fDefinitionList[aNdx].Highlighter :=
            GetBuiltInHighlighter (fDefinitionList[aNdx].Name);
      { TODO: Create from external definition. }
        if Assigned (fDefinitionList[aNdx].Highlighter) then
          fDefinitionList[aNdx].Highlighter.Style := fHighlightStyle
      end;
    { Returns highlighter reference. }
      Exit (fDefinitionList[aNdx].Highlighter);
    end;
  { No highlighter available. }
    Result := Nil
  end;



(* Constructor. *)
  constructor TSynManager.Create;
  begin
    inherited Create;
    fHighlightStyle := TMLSDEHighlightStyle.Create;
    fNumHighlighters := 0
  end;



(* Destructor. *)
  destructor TSynManager.Destroy;
  begin
    Self.Clear;
    fHighlightStyle.Free;
    inherited Destroy
  end;



(* Initializes. *)
  procedure TSynManager.Initialize;

  { I know, this is not the most efficient way to do it (insert first, then
    order by Bubble-Sort); I should use direct insertion (faster than insert
    first; then order by Quick-Sort) but I'm not in the mood right now. }

    function HighlighterExists (aName: String): Boolean;
    var
      Ndx: Integer;
    begin
      aName := LowerCase (aName);
      for Ndx := Low (fDefinitionList) to fNumHighlighters - 1 do
        if LowerCase (fDefinitionList[Ndx].Name) = aName then
          Exit (True);
      Result := False
    end;

    procedure AddHighlighter (aName, aExtensions: String; aBuiltIn: Boolean);
    begin
    { Does the list need to grow? }
      if fNumHighlighters >= Length (fDefinitionList) then
        SetLength (fDefinitionList, Length (fDefinitionList) + ListGrow);
    { Adds information. }
      fDefinitionList[fNumHighlighters].Name := aName;
      fDefinitionList[fNumHighlighters].Extensions := aExtensions;
      fDefinitionList[fNumHighlighters].BuiltIn := aBuiltIn;
      fDefinitionList[fNumHighlighters].Highlighter := Nil;
      Inc (fNumHighlighters)
    end;

    procedure OrderList;
    var
      Ndx: Integer;
      lOrdered: Boolean;
      lTmp: THighlighterInfo;
    begin
      if fNumHighlighters < 3 then Exit; { TODO: Remove in production. }
    { Let's do it the wrong way (bubble sort). }
      lOrdered := True;
      repeat
        for Ndx := Low (fDefinitionList) to fNumHighlighters - 2 do
          if LowerCase (fDefinitionList[Ndx].Name) > LowerCase (fDefinitionList[Ndx + 1].Name)
          then begin
            lTmp := fDefinitionList[Ndx];
            fDefinitionList[Ndx] := fDefinitionList[Ndx + 1];
            fDefinitionList[Ndx + 1] := lTmp;
            lOrdered := False
          end;
      until lOrdered
    end;

  var
    Ndx: Integer;
  begin
  { Removes old list (if any). }
    Self.Clear;
  { Adds built-in highlighters if not overriden. }
    for Ndx := Low (BuiltInHighlighters) to High (BuiltInHighlighters) do
      if not HighlighterExists (BuiltInHighlighters[Ndx].Name) then
        AddHighlighter (
          BuiltInHighlighters[Ndx].Name,
          BuiltInHighlighters[Ndx].Extensions,
          True
        );
  { Order by name. }
    OrderList
  end;



(* Returns the highlighter for the given language. *)
  function TSynManager.GetHighlighter (aLanguage: String): TMLSDEHighlighter;
  begin
    Result := Self.GetHighlighter (Self.GetLanguageIndex (aLanguage))
  end;



(* Returns the highlighter for the given extension. *)
  function TSynManager.GetHighlighterForExt (aExt: String): TMLSDEHighlighter;
  begin
    Result := Self.GetHighlighter (Self.GetExtensionIndex (aExt))
  end;

end.

