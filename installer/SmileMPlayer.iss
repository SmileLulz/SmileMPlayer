#define MyAppName "SmileMPlayer"
#define MyAppVersion ExecAndGetFirstLine("python", """" + SourcePath + "\get_version.py""", SourcePath)
#define MyAppPublisher "SmileLulz"
#define MyAppURL "https://github.com/SmileLulz/SmileMPlayer"
#define MyAppExeName "SmileMPlayer.exe"

[Setup]
AppId={{c9a78fb8-f358-48d6-890f-5c521b43af88}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}

DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}

OutputDir=..\dist\installer
OutputBaseFilename=SmileMPlayer-{#MyAppVersion}-windows-x64-setup

SetupIconFile=..\data\icons\smilemplayer.ico

UninstallDisplayIcon={app}\{#MyAppExeName}

ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
SetupArchitecture=x64

Compression=lzma2
SolidCompression=yes

WizardStyle=modern

DisableProgramGroupPage=yes
PrivilegesRequired=admin

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"; Flags: unchecked

[Files]
Source: "..\dist\SmileMPlayer\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\SmileMPlayer"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\SmileMPlayer"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch SmileMPlayer"; Flags: nowait postinstall skipifsilent
