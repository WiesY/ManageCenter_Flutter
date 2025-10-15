[Setup]
AppName=АСКП МУПИТ
AppVersion=1.0.1
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
OutputBaseFilename=АСКП_МУПИТ_Setup_v1.0.3
SetupIconFile=lib\assets\icon\icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayIcon={app}\manage_center.exe
VersionInfoVersion=1.0.1.0
VersionInfoCompany=МУПИТ
VersionInfoDescription=Автоматизированная система контроля и управления производством
VersionInfoCopyright=© 2025 МУПИТ
VersionInfoProductName=АСКП МУПИТ
VersionInfoProductVersion=1.0.1

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Создать ярлык на рабочем столе"; GroupDescription: "Дополнительные иконки:"
Name: "quicklaunchicon"; Description: "Создать ярлык в панели быстрого запуска"; GroupDescription: "Дополнительные иконки:"; Flags: unchecked

[Files]
; Основные файлы приложения
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; Visual C++ Redistributable (скачайте и поместите в корень проекта)
Source: "vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall; Check: VCRedistNeedsInstall

[Icons]
Name: "{group}\АСКП МУПИТ"; Filename: "{app}\manage_center.exe"; Comment: "Автоматизированная система контроля и управления производством"
Name: "{group}\Удалить АСКП МУПИТ"; Filename: "{uninstallexe}"
Name: "{autodesktop}\АСКП МУПИТ"; Filename: "{app}\manage_center.exe"; Comment: "Автоматизированная система контроля и управления производством"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\АСКП МУПИТ"; Filename: "{app}\manage_center.exe"; Tasks: quicklaunchicon

[Run]
; Установка Visual C++ Redistributable
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/quiet /norestart"; StatusMsg: "Установка необходимых компонентов Visual C++..."; Check: VCRedistNeedsInstall; Flags: waituntilterminated

; Запуск приложения
Filename: "{app}\manage_center.exe"; Description: "Запустить АСКП МУПИТ"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{localappdata}\manage_center"
Type: filesandordirs; Name: "{app}\logs"
Type: filesandordirs; Name: "{app}\cache"
Type: filesandordirs; Name: "{app}\data\flutter_assets"

[Registry]
Root: HKCU; Subkey: "Software\MUPIT\ASKP"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"
Root: HKCU; Subkey: "Software\MUPIT\ASKP"; ValueType: string; ValueName: "Version"; ValueData: "1.0.1"
Root: HKCU; Subkey: "Software\MUPIT\ASKP"; ValueType: string; ValueName: "AppName"; ValueData: "АСКП МУПИТ"

[Code]
// Проверка необходимости установки Visual C++ Redistributable
function VCRedistNeedsInstall: Boolean;
var
  Version: String;
begin
  Result := True;
  
  // Проверяем Visual C++ 2015-2022 Redistributable
  if RegQueryStringValue(HKLM, 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64', 'Version', Version) then
  begin
    Result := False;
  end
  else if RegQueryStringValue(HKLM, 'SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x64', 'Version', Version) then
  begin
    Result := False;
  end;
  
  if Result then
    Log('Visual C++ Redistributable не найден, будет установлен автоматически')
  else
    Log('Visual C++ Redistributable уже установлен: ' + Version);
end;

// Проверка системных требований
function InitializeSetup(): Boolean;
begin
  Result := True;
  
  // Проверка 64-битной системы
  if not IsWin64 then begin
    MsgBox('Данное приложение требует 64-битную версию Windows.', mbError, MB_OK);
    Result := False;
    Exit;
  end;
  
  // Проверка версии Windows (минимум Windows 10)
  if GetWindowsVersion < $0A000000 then begin
    MsgBox('Данное приложение требует Windows 10 или новее.', mbError, MB_OK);
    Result := False;
  end;
end;

// Сообщения в процессе установки
procedure CurStepChanged(CurStep: TSetupStep);
begin
  case CurStep of
    ssInstall:
      begin
        WizardForm.StatusLabel.Caption := 'Установка файлов приложения...';
      end;
    ssPostInstall:
      begin
        MsgBox('АСКП МУПИТ успешно установлен!' + #13#10 + 
               'Система мониторинга объектов водоснабжения готова к работе.' + #13#10 +
               'Для входа в систему потребуется авторизация.' + #13#10#13#10 +
               'Примечание: При первом запуске может потребоваться настройка Windows Defender.', 
               mbInformation, MB_OK);
      end;
  end;
end;

// Обработка ошибок установки
procedure CurInstallProgressChanged(CurProgress, MaxProgress: Integer);
begin
  // Можно добавить дополнительную логику отслеживания прогресса
end;