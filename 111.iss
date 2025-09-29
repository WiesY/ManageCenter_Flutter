[Setup]
AppName=АСКП МУПИТ
AppVersion=1.0.0
AppPublisher=МУПИТ
AppPublisherURL=https://mupit.ru
AppSupportURL=https://mupit.ru/support
AppUpdatesURL=https://mupit.ru/updates
DefaultDirName={autopf}\АСКП МУПИТ
DefaultGroupName=АСКП МУПИТ
AllowNoIcons=yes
LicenseFile=
InfoBeforeFile=
InfoAfterFile=
OutputDir=installer_output
OutputBaseFilename=АСКП_МУПИТ_Setup_v1.0.1
SetupIconFile=lib\assets\icon\icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayIcon={app}\manage_center.exe
VersionInfoVersion=1.0.0.7
VersionInfoCompany=МУПИТ
VersionInfoDescription=Автоматизированная система контроля и управления производством
VersionInfoCopyright=© 2025 МУПИТ
VersionInfoProductName=АСКП МУПИТ
VersionInfoProductVersion=1.0.0

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Создать ярлык на рабочем столе"; GroupDescription: "Дополнительные иконки:"
Name: "quicklaunchicon"; Description: "Создать ярлык в панели быстрого запуска"; GroupDescription: "Дополнительные иконки:"; Flags: unchecked

[Files]
; Основной исполняемый файл
Source: "build\windows\x64\runner\Release\manage_center.exe"; DestDir: "{app}"; Flags: ignoreversion

; Основные DLL Flutter
Source: "build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion

; Все плагины (включая local_auth_windows)
Source: "build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion

; Папка data с ресурсами Flutter
Source: "build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

; Все остальные файлы и папки
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "*.exe,*.dll"

[Icons]
Name: "{group}\АСКП МУПИТ"; Filename: "{app}\manage_center.exe"; Comment: "Автоматизированная система контроля и управления производством"
Name: "{group}\Удалить АСКП МУПИТ"; Filename: "{uninstallexe}"
Name: "{autodesktop}\АСКП МУПИТ"; Filename: "{app}\manage_center.exe"; Comment: "Автоматизированная система контроля и управления производством"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\АСКП МУПИТ"; Filename: "{app}\manage_center.exe"; Tasks: quicklaunchicon

[Run]
Filename: "{app}\manage_center.exe"; Description: "Запустить АСКП МУПИТ"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{localappdata}\manage_center"
Type: filesandordirs; Name: "{app}\logs"
Type: filesandordirs; Name: "{app}\cache"
Type: filesandordirs; Name: "{app}\data\flutter_assets"

[Registry]
Root: HKCU; Subkey: "Software\MUPIT\ASKP"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"
Root: HKCU; Subkey: "Software\MUPIT\ASKP"; ValueType: string; ValueName: "Version"; ValueData: "1.0.0"
Root: HKCU; Subkey: "Software\MUPIT\ASKP"; ValueType: string; ValueName: "AppName"; ValueData: "АСКП МУПИТ"

[Code]
function FileExists(FileName: string): Boolean;
begin
  Result := FileExists(FileName);
end;

// Проверка системных требований
function InitializeSetup(): Boolean;
begin
  Result := True;
  // Проверка версии Windows (минимум Windows 10)
  if not IsWin64 then begin
    MsgBox('Данное приложение требует 64-битную версию Windows.', mbError, MB_OK);
    Result := False;
  end;
end;

// Сообщение после установки
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    MsgBox('АСКП МУПИТ успешно установлен!' + #13#10 + 
           'Система управления объектами водоснабжения готова к работе.' + #13#10 +
           'Для входа в систему потребуется авторизация.', mbInformation, MB_OK);
  end;
end;