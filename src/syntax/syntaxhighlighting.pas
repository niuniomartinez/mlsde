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
      Highlighter: TSynCustomHighlighter
    end;



  (* Contains and manages the available syntax highlighters. *)
    TSynManager = class (TObject)
    private
      fDefinitionList: array of THighlighterInfo;
      fNumHighlighters: Integer;

    (* Looks for a highlighter by name and returns its index or -1 if not
       found. *)
      function GetHighlighterIndex (aName: String): Integer;
    (* Looks for a highlighter by extension and returns its index or -1 if not
       found. *)
      function GetExtensionIndex (aExtension: String): Integer;
    (* Clears the list and rebuilds it. *)
      procedure Reset;
    public
    (* Constructor. *)
      constructor Create;
    (* Initializes the manager.

       Can be used to reset or re-initialize. *)
      procedure Initialize;
    (* Returns the highlighter for the given extension. *)
      function GetHighlighterForExt (aExt: String): TSynCustomHighlighter;
    end;

implementation

  uses
    Utils,
    StrUtils, sysutils,
  { Built-in syntax highlighters. }
    SynHighlighterBat, SynHighlighterCpp, SynHighlighterCss, SynHighlighterHTML,
    SynHighlighterIni, SynHighlighterJava, SynHighlighterJScript,
    SynHighlighterPas, SynHighlighterPHP, SynHighlighterSQL,
    synhighlighterunixshellscript, SynHighlighterVB, SynHighlighterXML;



(*
 * Built-in syntax highlighters management.
 ***************************************************************************)
  type
  (* Highlighter information. *)
    TBuiltInHighlighter = record
      Name, Extensions: String;
      HighlighterClass: TSynCustomHighlighterClass;
    end;

  var
  (* List of built-in highlighters.

     This is populated at the initialization section. *)
    BuiltInHighlighters: array [0..13] of TBuiltInHighlighter;

(* Helper to avoid duplicate code. *)
  function CreateBuiltInHighlighter (const aNdx: Integer)
    : TSynCustomHighlighter;
    inline;
  begin
    Result := BuiltInHighlighters[aNdx].HighlighterClass.Create (Nil);
    Result.Name := BuiltInHighlighters[aNdx].Name
  end;



(* Creates a built-in highlighter.

   Note that it will create a new syntax highlighter every time it is requested.

   Returns the reference for the syntax highlighter or Nil if it can't find it.
 *)
  function GetBuiltInHighlighterForExt (aExt: String): TSynCustomHighlighter;
  var
    lNdx, lHighlighterNdx: Integer;
    lExtensions: array of String;
  begin
    for lNdx := Low (BuiltInHighlighters) to High (BuiltInHighlighters) do
    begin
      lExtensions := SplitString (BuiltInHighlighters[lNdx].Extensions, ';');
      lHighlighterNdx := FindString (aExt, lExtensions);
      if lHighlighterNdx >= 0 then
        Exit (CreateBuiltInHighlighter (lNdx))
    end;
    Result := Nil
  end;

  function GetBuiltInHighlighterForName (aName: String): TSynCustomHighlighter;
  var
    lNdx: Integer;
  begin
    aName := LowerCase (aName);
    for lNdx := Low (BuiltInHighlighters) to High (BuiltInHighlighters) do
    begin
      if LowerCase (BuiltInHighlighters[lNdx].Name) = aName then
        Exit (CreateBuiltInHighlighter (lNdx))
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

(* Looks for a highlighter by name. *)
  function TSynManager.GetHighlighterIndex (aName: String): Integer;
  var
    Ndx: Integer;
  begin
    aName := LowerCase (aName);
    for Ndx := Low (fDefinitionList) to fNumHighlighters - 1 do
      if aName = LowerCase (fDefinitionList[Ndx].Name) then
        Exit (Ndx);
  { Not found, so... }
    Result := -1
  end;



(* Looks for a highlighter by extension. *)
  function TSynManager.GetExtensionIndex (aExtension: String): Integer;
  var
    Ndx: Integer;
    lExtensions: array of String;
  begin
    aExtension := LowerCase (aExtension);
    for Ndx := Low (fDefinitionList) to fNumHighlighters - 1 do
    begin
      lExtensions := SplitString (fDefinitionList[Ndx].Extensions, ',');
      Result := FindString (aExtension, lExtensions);
      if Result >= 0 then Exit
    end;
  { Not found, so... }
    Result := -1
  end;



  procedure TSynManager.Reset;

    procedure AddHighlighter (aName, aExtensions: String; aBuiltIn: Boolean);
    begin
    { Does the list need to grow. }
      if fNumHighlighters >= Length (fDefinitionList) then
        SetLength (fDefinitionList, Length (fDefinitionList) + ListGrow);
    { Adds information. }
      fDefinitionList[fNumHighlighters].Name := aName;
      fDefinitionList[fNumHighlighters].Extensions := aExtensions;
      fDefinitionList[fNumHighlighters].BuiltIn := aBuiltIn;
      fDefinitionList[fNumHighlighters].Highlighter := Nil;{Not sure if needed.}
      Inc (fNumHighlighters)
    end;

  var
    Ndx: Integer;
  begin
  { Clear the list. }
    for Ndx := Low (fDefinitionList) to fNumHighlighters - 1 do
      FreeAndNil (fDefinitionList[Ndx].Highlighter);
    fNumHighlighters := 0;
    SetLength (fDefinitionList, MinDefinitionList);
  { Adds built-in highlighters if non overriden. }
    for Ndx := Low (BuiltInHighlighters) to High (BuiltInHighlighters) do
      if Self.GetHighlighterIndex (BuiltInHighlighters[Ndx].Name) < 0 then
        AddHighlighter (
          BuiltInHighlighters[Ndx].Name,
          BuiltInHighlighters[Ndx].Extensions,
          True
        )
  end;



(* Constructor. *)
  constructor TSynManager.Create;
  begin
    inherited Create;
    Self.Reset
  end;



(* Initializes. *)
  procedure TSynManager.Initialize;
  begin
    Self.Reset
  end;



(* Returns the highlighter for the given extension. *)
  function TSynManager.GetHighlighterForExt (aExt: String)
    : TSynCustomHighlighter;
  var
    Ndx: Integer;
  begin
    Ndx := Self.GetExtensionIndex (aExt);
    if Ndx > -1 then
    begin
    { Was the highlighter created yet? }
      if not Assigned (fDefinitionList[Ndx].Highlighter) then
      begin
      { Create the highlighter. }
        if fDefinitionList[Ndx].BuiltIn then
          fDefinitionList[Ndx].Highlighter :=
            GetBuiltInHighlighterForName (fDefinitionList[Ndx].Name)
      { TODO: Create from external definition. }
      end;
    { Returns highlighter reference. }
      Exit (fDefinitionList[Ndx].Highlighter);
    end;
  { No highlighter available. }
    Result := Nil
  end;



(****************************************************************************)

(* Sets information for built-in highlighter. *)
  procedure SetBuiltInHighlighter (
    const aNdx: Integer;
    aName, aExtensions: String;
    aHighlighterClass: TSynCustomHighlighterClass
  );
  begin;
    BuiltInHighlighters[aNdx].Name := Trim (aName);
    BuiltInHighlighters[aNdx].Extensions := LowerCase (Trim (aExtensions));
    BuiltInHighlighters[aNdx].HighlighterClass := aHighlighterClass
  end;

initialization
  SetBuiltInHighlighter ( 0, 'bat',        'bat',            TSynBatSyn);
  SetBuiltInHighlighter ( 1, 'C',          'c;h',            TSynCppSyn);
  SetBuiltInHighlighter ( 2, 'C++',        'cpp,c++,hpp',    TSynCppSyn);
  SetBuiltInHighlighter ( 3, 'CSS',        'css',            TSynCssSyn);
  SetBuiltInHighlighter ( 4, 'HTML',       'htm,html',       TSynHTMLSyn);
  SetBuiltInHighlighter ( 5, 'INI',        'ini',            TSynIniSyn);
  SetBuiltInHighlighter ( 6, 'Java',       'jav',            TSynJavaSyn);
  SetBuiltInHighlighter ( 7, 'JavaScript', 'js',             TSynJScriptSyn);
  SetBuiltInHighlighter ( 8, 'Pascal',     'pas,pp,dpr,lpr', TSynPasSyn);
  SetBuiltInHighlighter ( 9, 'PHP',        'php',            TSynPHPSyn);
  SetBuiltInHighlighter (10, 'UNIX shell', 'sh',        TSynUNIXShellScriptSyn);
  SetBuiltInHighlighter (11, 'VisualBasic','vb',             TSynVBSyn);
  SetBuiltInHighlighter (12, 'SQL',        'sql',            TSynSQLSyn);
  SetBuiltInHighlighter (13, 'XML',        'xml,rss',        TSynXMLSyn)
finalization
  ;
end.

