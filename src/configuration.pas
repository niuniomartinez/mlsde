unit Configuration;
(*< Implements the base class of the configuration objects. *)
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
    Classes, fgl, IniFiles, Utils,
    sysutils;

  type
  (* @exclude forward declaration. *)
    TConfiguration = class;



  (* Exception raised if a configuration object is missing. *)
    ENoConfigurationObjectFound = class (Exception);



  (* Base class for configuration objects.

     Each part (subsystem) of the IDE should define a class that extends this
     one.

     To make it more efficent, child classes should call the @code(Set*Value)
     methods only if value has really changed. *)
    TCustomConfiguration = class (TObject)
    private
      fOwner: TConfiguration;
      fName: String;
      fChanged: Boolean;
      fObserversSubject: TSubject;
    protected
    (* Returns the requested value. *)
      function GetValue (const aSection, aVariable, aDefault: String): String;
    (* Sets a value. *)
      procedure SetValue (const aSection, aVariable, aValue: String);
    (* Returns the requested integer value. *)
      function GetIntValue  (
        const aSection, aVariable: String;
        const aDefault: Integer
      ): Integer;
    (* Sets an integer value. *)
      procedure SetIntValue (
        const aSection, aVariable: String;
        const aValue: Integer
      );
    (* Returns the requested boolean value. *)
      function GetBoolValue  (
        const aSection, aVariable: String;
        const aDefault: Boolean
      ): Boolean;
    (* Sets a boolean value. *)
      procedure SetBooleanValue (
        const aSection, aVariable: String;
        const aValue: Boolean
      );
    public
    (* Constructor. *)
      constructor Create;
    (* Destructor. *)
      destructor Destroy; override;
    (* Writes help of the supported command line options.

       By default it doesn't do anything. *)
      procedure PrintCommandLineHelp; virtual;
    (* Parses command line options.

       By default it doesn't do anything. *)
      procedure ParseCommandLineOptions; virtual;

    (* Configuration name. *)
      property Name: String read fName write fName;
    (* Observers should register here to know when configuration changes. *)
      property Subject: TSubject read fObserversSubject;
    end;



  (* Contains all the application configuration. *)
    TConfiguration = class (TObject)
    private type
    (* Container for the configuration pieces. *)
      TConfigurationList = specialize TFPGObjectList<TCustomConfiguration>;
    private
      fFile: TIniFile;
      fSectionList: TConfigurationList;

      function GetConfigurationDir: String; inline;
      function GetConfigurationFileName: String; inline;
    (* Same than FindConfig but instead of an exception it returns Nil if can't
       find the object. *)
      function GetSection (aName: String): TCustomConfiguration;
    public
    (* Constructor. *)
      constructor Create;
    (* Destructor. *)
      destructor Destroy; override;
    (* Initializes the configuration.  This (re)loads the configuration file
       and parses the command line options.

       Should be called @italic(before) adding sections.
       @seealso(PrintCommandLineHelp) @seealso(AddSection) *)
      procedure Initialize;
    (* Prints command line help. *)
      procedure PrintCommandLineHelp;
    (* Adds a configuration section to the list. *)
      procedure AddSection (aCfg: TCustomConfiguration; aName: String);
    (* Returns the requested configuration object.  If can't find an object of
       the given name it raises an exception *)
      function FindConfig (aName: String): TCustomConfiguration; inline;
    (* Applies configuration changes. *)
      procedure Apply;

    (* The local configuration directory.

       This can be used to store additional data such as user templates and
       scripts.
       @seealso(ConfigurationFileName) *)
      property ConfigurationDir: String read GetConfigurationDir;
    (* Configuration file name.  It doesn't include path.
       @seealso(ConfigurationDir) *)
      property ConfigurationFileName: String read GetConfigurationFileName;
    end;

implementation

  uses
    Forms;

  resourcestring
    txtHelpUsage  = 'Usage: %s [options]';
    txtHelpWhere  = 'Where options are:';
    txtHelpHelp   = 'Shows this help.';
    txtHelpConfig = 'Tells configuration file to use.';

(*
 * TCustomConfiguration
 ***************************************************************************)

(* Returns value. *)
  function TCustomConfiguration.GetValue
    (const aSection, aVariable, aDefault: String)
    : String;
  begin
    Result := fOwner.fFile.ReadString (aSection, aVariable, aDefault)
  end;



(* Sets a value. *)
  procedure TCustomConfiguration.SetValue
    (const aSection, aVariable, aValue: String);
  begin
    fOwner.fFile.WriteString (aSection, aVariable, aValue);
    fChanged := True
  end;



(* Returns int value. *)
  function TCustomConfiguration.GetIntValue (
    const aSection, aVariable:String;
    const aDefault: Integer
  )
    : Integer;
  begin
    Result := fOwner.fFile.ReadInteger (aSection, aVariable, aDefault)
  end;



(* Sets an int value. *)
  procedure TCustomConfiguration.SetIntValue (
    const aSection, aVariable: String;
    const aValue: Integer
  );
  begin
    fOwner.fFile.WriteInteger (aSection, aVariable, aValue);
    fChanged := True
  end;



(* Returns bool value. *)
  function TCustomConfiguration.GetBoolValue (
    const aSection, aVariable:String;
    const aDefault: Boolean
  )
    : Boolean;
  begin
    Result := fOwner.fFile.ReadBool (aSection, aVariable, aDefault)
  end;



(* Sets a bool value. *)
  procedure TCustomConfiguration.SetBooleanValue (
    const aSection, aVariable: String;
    const aValue: Boolean
  );
  begin
    fOwner.fFile.WriteBool (aSection, aVariable, aValue);
    fChanged := True
  end;



(* Constructor. *)
  constructor TCustomConfiguration.Create;
  begin
    inherited Create;
    fObserversSubject := TSubject.Create (Self)
  end;



(* Destructor. *)
  destructor TCustomConfiguration.Destroy;
  begin
    fObserversSubject.Free;
    inherited Destroy
  end;



(* Command line options.  Does nothing. *)
  procedure TCustomConfiguration.PrintCommandLineHelp; begin end;
  procedure TCustomConfiguration.ParseCommandLineOptions; begin end;



(*
 * TConfiguration
 ***************************************************************************)

  function TConfiguration.GetConfigurationDir: String;
  begin
    Result := IncludeTrailingPathDelimiter (GetAppConfigDir (False))
  end;

  function TConfiguration.GetConfigurationFileName: String;
  begin
    Result := ExtractFileName (GetAppConfigFile (False, False))
  end;



(* Searchs for section *)
  function TConfiguration.GetSection (aName: String): TCustomConfiguration;
  var
    lCfg: TCustomConfiguration;
  begin
    aName := LowerCase (aName);
    for lCfg in fSectionList do if lCfg.Name = aName then Exit (lCfg);
    Result := Nil
  end;



(* Constructor. *)
  constructor TConfiguration.Create;
  begin
    inherited Create;
    fSectionList := TConfigurationList.Create (True)
  end;



(* Destructor. *)
  destructor TConfiguration.Destroy;
  begin
    fSectionList.Free;
    fFile.Free;
    inherited Destroy
  end;



(* (Re)Loads configuration. *)
  procedure TConfiguration.Initialize;
  var
    lFileName: String;
    lConfigSection: TCustomConfiguration;
  begin
  { Load configuration file. }
    lFileName := Application.GetOptionValue ('cfg');
    if lFileName = '' then
      lFileName := Self.GetConfigurationDir + Self.GetConfigurationFileName;
    if fFile <> Nil then
    begin
      Application.Log (etWarning, 'Reloading configuration file.');
      fFile.Free
    end;
    Application.Log (etDebug, 'Loading configuration from "%s".', [lFileName]);
    fFile := TIniFile.Create (lFileName);
  { Parse command line options. }
    for lConfigSection in fSectionList do
      lConfigSection.ParseCommandLineOptions
  end;



(* Prints command line help. *)
  procedure TConfiguration.PrintCommandLinehelp;
  var
    lConfigSection: TCustomConfiguration;
  begin
    WriteLn;
    WriteLn (Format (txtHelpUsage, [ExtractFileName (Application.ExeName)]));
    WriteLn;
    WriteLn (txtHelpWhere);
    WriteLn ('  --cfg=<config_file_paht>:  ', txtHelpConfig);
    WriteLn ('  --help: ', txtHelpHelp);
    for lConfigSection in fSectionList do lConfigSection.PrintCommandLineHelp
  end;



(* Adds a configuration object. *)
  procedure TConfiguration.AddSection (
    aCfg: TCustomConfiguration;
    aName: String
  );
  begin
    if Self.GetSection (aName) = Nil then
    begin
      aCfg.Name := LowerCase (aName);
      aCfg.fOwner := Self;
      fSectionList.Add (aCfg)
    end
  { TODO: Raise if duplicated or just show a message?
          Duplicated sections must be an error! }
  end;



(* Returns the requested configuration object or @nil. *)
  function TConfiguration.FindConfig (aName: String): TCustomConfiguration;
  begin
    Result := Self.GetSection (aName);
    if Result = Nil then
      RAISE ENoConfigurationObjectFound.CreateFmt (
        'Can''t find configuration section "%s".',
        [aName]
      )
  end;



(* Applies configuration. *)
  procedure TConfiguration.Apply;
  var
    lCfg: TCustomConfiguration;
  begin
    for lCfg in fSectionList do
    begin
      if lCfg.fChanged then
      begin
        lCfg.Subject.Notify;
        lCfg.fChanged := False
      end
    end
  end;

end.

