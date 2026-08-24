; Instalador da tradução PT-BR — FINAL FANTASY X-2 HD Remaster (Steam)
; Copia apenas arquivos da tradução para a pasta do jogo, sem alterar dados originais.
;
; Falhas comuns da v1.0 que esta revisão corrige:
; - pasta padrão em Program Files (o jogo está em steamapps\common)
; - detecção só no registro 32-bit / biblioteca padrão da Steam
; - validação rígida: escolher steamapps\common ou uma subpasta falhava
; - texto do assistente falava em "destino da tradução", não na pasta do jogo
; - AppendDefaultDirName criava uma subpasta extra quando o nome tinha "&"

#define MyAppName "Tradução PT-BR - FINAL FANTASY X-2 HD Remaster"
#define MyAppVersion "1.1"
#define MyAppPublisher "Carlos Alexandre de Oliveira"
#define NomePastaJogo "FINAL FANTASY FFX&FFX-2 HD Remaster"
#define SteamAppId "359870"

[Setup]
AppId={{C4E8A1F3-9B2D-4F6E-A7C0-3D5E8B1F9A2C}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={code:DirPadrao}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequired=admin
UninstallFilesDir={commonappdata}\FFX2-Traducao-PTBR
UninstallDisplayName={#MyAppName}
WizardStyle=modern
WizardImageFile=assets\wizard-imagem.bmp
WizardSmallImageFile=assets\wizard-logo.bmp
SetupIconFile=assets\icone.ico
Compression=lzma2
SolidCompression=yes
OutputDir=saida
OutputBaseFilename=FFX2-Traducao-PTBR-Setup
UsePreviousAppDir=no
AppendDefaultDirName=no
DirExistsWarning=no
EnableDirDoesntExistWarning=no
SetupLogging=yes
UsedUserAreasWarning=no
ChangesAssociations=no
AllowNoIcons=yes
AlwaysShowDirOnReadyPage=yes
DisableWelcomePage=no
CloseApplications=no
RestartIfNeededByRun=no
MinVersion=6.1sp1

[Languages]
Name: "portuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Messages]
SetupWindowTitle=Instalar tradução PT-BR do FFX-2
WelcomeLabel1=Tradução PT-BR do FINAL FANTASY X-2
WelcomeLabel2=Este assistente adiciona a tradução ao jogo já instalado pela Steam. Ele não inclui o FFX-2 e não substitui FFX2_Data.vbf.%n%nNa próxima tela, escolha a pasta do jogo — a que contém o arquivo FFX-2.exe.%n%nO Windows vai pedir permissão de administrador porque a pasta da Steam costuma estar em Program Files.
WizardSelectDir=Pasta do jogo
SelectDirLabel3=Selecione a pasta de instalação do FINAL FANTASY X/X-2 HD Remaster (onde está o FFX-2.exe).%n%nCaminho típico:%nC:\Program Files (x86)\Steam\steamapps\common\FINAL FANTASY FFX&FFX-2 HD Remaster%n%nDica: Steam > clique com o botão direito no jogo > Gerenciar > Procurar arquivos locais.
SelectDirBrowseLabel=Clique em Procurar e aponte para a pasta do jogo:
ReadyLabel2a=Os arquivos da tradução serão copiados para a pasta acima, ao lado do FFX-2.exe.
FinishedHeadingLabel=Tradução instalada
FinishedLabelNoIcons=A tradução foi copiada para a pasta do jogo. Abra o FFX-2 pela Steam.

[Files]
Source: "..\arquivos-do-jogo\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[UninstallDelete]
Type: files; Name: "{app}\hook.log"

[Code]
const
  NOME_PASTA_JOGO = '{#NomePastaJogo}';
  STEAM_APP_ID = '{#SteamAppId}';
  CHAVE_STEAM_APP = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App {#SteamAppId}';
  CHAVE_STEAM_APP32 = 'SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Steam App {#SteamAppId}';

var
  CaminhoJogoDetectado: String;
  JaDetectou: Boolean;
  AjudaDirExibida: Boolean;

function ValidarPastaJogo(const Caminho: String): Boolean;
begin
  Result :=
    (Caminho <> '') and
    DirExists(Caminho) and
    FileExists(Caminho + '\FFX-2.exe');
end;

function PastaJogoCompleta(const Caminho: String): Boolean;
begin
  Result := ValidarPastaJogo(Caminho) and FileExists(Caminho + '\FFX2_Data.vbf');
end;

function NormalizarCaminho(const Caminho: String): String;
begin
  Result := Trim(Caminho);
  if (Length(Result) >= 2) and (Result[1] = '"') and (Result[Length(Result)] = '"') then
    Result := Copy(Result, 2, Length(Result) - 2);
  StringChangeEx(Result, '/', '\', True);
  if (Result <> '') and (Result[Length(Result)] = '\') then
    Delete(Result, Length(Result), 1);
end;

function ExtrairStringsAspas(const Linha: String): TArrayOfString;
var
  I, Inicio: Integer;
  Dentro: Boolean;
  Lista: TArrayOfString;
begin
  SetArrayLength(Lista, 0);
  Dentro := False;
  Inicio := 0;

  for I := 1 to Length(Linha) do
  begin
    if Linha[I] = '"' then
    begin
      if not Dentro then
        Inicio := I + 1
      else
      begin
        SetArrayLength(Lista, GetArrayLength(Lista) + 1);
        Lista[GetArrayLength(Lista) - 1] := Copy(Linha, Inicio, I - Inicio);
      end;
      Dentro := not Dentro;
    end;
  end;

  Result := Lista;
end;

function ExtrairValorVDF(const Linha, Chave: String): String;
var
  Partes: TArrayOfString;
begin
  Result := '';
  if Pos('"' + LowerCase(Chave) + '"', LowerCase(Linha)) = 0 then
    Exit;

  Partes := ExtrairStringsAspas(Linha);
  if GetArrayLength(Partes) >= 2 then
  begin
    if CompareText(Partes[0], Chave) = 0 then
      Result := Partes[1]
    else if StrToIntDef(Partes[0], -1) >= 0 then
      Result := Partes[1];
  end;

  StringChangeEx(Result, '\\', '\', True);
end;

function BibliotecaJaListada(const Bibliotecas: TArrayOfString; const Caminho: String): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to GetArrayLength(Bibliotecas) - 1 do
    if CompareText(NormalizarCaminho(Bibliotecas[I]), NormalizarCaminho(Caminho)) = 0 then
    begin
      Result := True;
      Exit;
    end;
end;

procedure AdicionarBiblioteca(var Bibliotecas: TArrayOfString; const Caminho: String);
var
  Normalizado: String;
begin
  Normalizado := NormalizarCaminho(Caminho);
  if (Normalizado <> '') and DirExists(Normalizado) and
     not BibliotecaJaListada(Bibliotecas, Normalizado) then
  begin
    SetArrayLength(Bibliotecas, GetArrayLength(Bibliotecas) + 1);
    Bibliotecas[GetArrayLength(Bibliotecas) - 1] := Normalizado;
  end;
end;

function LerTextoArquivo(const Arquivo: String; var Texto: String): Boolean;
var
  Linhas: TArrayOfString;
  I: Integer;
begin
  Result := False;
  Texto := '';
  if not FileExists(Arquivo) then
    Exit;
  if not LoadStringsFromFile(Arquivo, Linhas) then
    Exit;
  for I := 0 to GetArrayLength(Linhas) - 1 do
    Texto := Texto + Linhas[I] + #10;
  Result := True;
end;

function ConsultarRegistroTexto(const Raiz: Integer; const Subchave, Nome: String; var Valor: String): Boolean;
begin
  Result := RegQueryStringValue(Raiz, Subchave, Nome, Valor);
  if Result then
    Valor := NormalizarCaminho(Valor);
end;

function ObterCaminhoSteam(): String;
var
  Valor: String;
begin
  Result := '';

  if ConsultarRegistroTexto(HKEY_CURRENT_USER, 'Software\Valve\Steam', 'SteamPath', Valor) then
    Result := Valor
  else if ConsultarRegistroTexto(HKEY_LOCAL_MACHINE, 'SOFTWARE\WOW6432Node\Valve\Steam', 'InstallPath', Valor) then
    Result := Valor
  else if ConsultarRegistroTexto(HKEY_LOCAL_MACHINE, 'SOFTWARE\Valve\Steam', 'InstallPath', Valor) then
    Result := Valor;

  if (Result = '') and IsWin64 then
  begin
    if ConsultarRegistroTexto(HKCU64, 'Software\Valve\Steam', 'SteamPath', Valor) then
      Result := Valor
    else if ConsultarRegistroTexto(HKLM64, 'SOFTWARE\Valve\Steam', 'InstallPath', Valor) then
      Result := Valor;
  end;

  if Result <> '' then
    Log('Steam encontrado no registro: ' + Result);
end;

function ObterPastaPeloRegistroSteamApp(): String;
var
  Valor: String;
begin
  Result := '';

  if ConsultarRegistroTexto(HKEY_LOCAL_MACHINE, CHAVE_STEAM_APP, 'InstallLocation', Valor) and
     ValidarPastaJogo(Valor) then
    Result := Valor
  else if ConsultarRegistroTexto(HKEY_LOCAL_MACHINE, CHAVE_STEAM_APP32, 'InstallLocation', Valor) and
     ValidarPastaJogo(Valor) then
    Result := Valor
  else if IsWin64 and ConsultarRegistroTexto(HKLM64, CHAVE_STEAM_APP, 'InstallLocation', Valor) and
     ValidarPastaJogo(Valor) then
    Result := Valor;

  if Result <> '' then
    Log('Pasta do jogo via registro Steam App: ' + Result);
end;

procedure LerBibliotecasSteam(const CaminhoSteam: String; var Bibliotecas: TArrayOfString);
var
  ArquivoVDF, Texto, CaminhoLib: String;
  Linhas: TArrayOfString;
  Partes: TArrayOfString;
  I: Integer;
begin
  SetArrayLength(Bibliotecas, 0);
  AdicionarBiblioteca(Bibliotecas, CaminhoSteam);

  ArquivoVDF := CaminhoSteam + '\steamapps\libraryfolders.vdf';
  if not FileExists(ArquivoVDF) then
    Exit;

  if LoadStringsFromFile(ArquivoVDF, Linhas) then
  begin
    for I := 0 to GetArrayLength(Linhas) - 1 do
    begin
      CaminhoLib := ExtrairValorVDF(Linhas[I], 'path');
      if CaminhoLib = '' then
      begin
        { Formato antigo do VDF: "1" "D:\SteamLibrary" (sem chave "path") }
        Partes := ExtrairStringsAspas(Linhas[I]);
        if (GetArrayLength(Partes) >= 2) and (StrToIntDef(Partes[0], -1) >= 0) and
           ((Pos('\', Partes[1]) > 0) or (Pos('/', Partes[1]) > 0) or (Pos(':', Partes[1]) > 0)) then
        begin
          CaminhoLib := Partes[1];
          StringChangeEx(CaminhoLib, '\\', '\', True);
        end;
      end;
      if CaminhoLib <> '' then
        AdicionarBiblioteca(Bibliotecas, CaminhoLib);
    end;
  end
  else if LerTextoArquivo(ArquivoVDF, Texto) then
    Log('libraryfolders.vdf existe, mas não pôde ser lido linha a linha.');
end;

function LerInstallDirDoManifest(const CaminhoBiblioteca: String): String;
var
  Manifesto: String;
  Linhas: TArrayOfString;
  I: Integer;
begin
  Result := '';
  Manifesto := CaminhoBiblioteca + '\steamapps\appmanifest_' + STEAM_APP_ID + '.acf';
  if not FileExists(Manifesto) then
    Exit;

  if LoadStringsFromFile(Manifesto, Linhas) then
    for I := 0 to GetArrayLength(Linhas) - 1 do
    begin
      Result := ExtrairValorVDF(Linhas[I], 'installdir');
      if Result <> '' then
        Exit;
    end;
end;

function MontarCaminhosCandidatos(const CaminhoBiblioteca: String): TArrayOfString;
var
  Candidatos: TArrayOfString;
  InstallDir: String;
  Total: Integer;
begin
  SetArrayLength(Candidatos, 2);
  Candidatos[0] := CaminhoBiblioteca + '\steamapps\common\' + NOME_PASTA_JOGO;
  Candidatos[1] := CaminhoBiblioteca + '\SteamApps\common\' + NOME_PASTA_JOGO;
  Total := 2;

  InstallDir := LerInstallDirDoManifest(CaminhoBiblioteca);
  if (InstallDir <> '') and (CompareText(InstallDir, NOME_PASTA_JOGO) <> 0) then
  begin
    SetArrayLength(Candidatos, Total + 2);
    Candidatos[Total] := CaminhoBiblioteca + '\steamapps\common\' + InstallDir;
    Candidatos[Total + 1] := CaminhoBiblioteca + '\SteamApps\common\' + InstallDir;
  end;

  Result := Candidatos;
end;

function PrimeiroCandidatoValido(const Candidatos: TArrayOfString): String;
var
  I: Integer;
  Caminho: String;
begin
  Result := '';
  for I := 0 to GetArrayLength(Candidatos) - 1 do
  begin
    Caminho := NormalizarCaminho(Candidatos[I]);
    if ValidarPastaJogo(Caminho) then
    begin
      Result := Caminho;
      Exit;
    end;
  end;
end;

function EncontrarPastaJogoAPartir(const CaminhoInicial: String): String;
var
  Atual, Filho: String;
  I: Integer;
begin
  Result := '';
  Atual := NormalizarCaminho(CaminhoInicial);
  if Atual = '' then
    Exit;

  for I := 1 to 6 do
  begin
    if ValidarPastaJogo(Atual) then
    begin
      Result := Atual;
      Exit;
    end;

    Filho := Atual + '\' + NOME_PASTA_JOGO;
    if ValidarPastaJogo(Filho) then
    begin
      Result := Filho;
      Exit;
    end;

    Filho := Atual + '\steamapps\common\' + NOME_PASTA_JOGO;
    if ValidarPastaJogo(Filho) then
    begin
      Result := Filho;
      Exit;
    end;

    Filho := Atual + '\Steam\steamapps\common\' + NOME_PASTA_JOGO;
    if ValidarPastaJogo(Filho) then
    begin
      Result := Filho;
      Exit;
    end;

    Atual := ExtractFileDir(Atual);
    if (Atual = '') or (Length(Atual) < 2) then
      Break;
  end;
end;

function DetectarPorDrivesComuns(): String;
var
  Raizes: TArrayOfString;
  I, D: Integer;
  Candidato: String;
begin
  Result := '';
  SetArrayLength(Raizes, 6);
  Raizes[0] := '\Program Files (x86)\Steam\steamapps\common\' + NOME_PASTA_JOGO;
  Raizes[1] := '\Program Files\Steam\steamapps\common\' + NOME_PASTA_JOGO;
  Raizes[2] := '\Steam\steamapps\common\' + NOME_PASTA_JOGO;
  Raizes[3] := '\SteamLibrary\steamapps\common\' + NOME_PASTA_JOGO;
  Raizes[4] := '\Jogos\Steam\steamapps\common\' + NOME_PASTA_JOGO;
  Raizes[5] := '\Games\Steam\steamapps\common\' + NOME_PASTA_JOGO;

  for D := 0 to 23 do
  begin
    for I := 0 to GetArrayLength(Raizes) - 1 do
    begin
      Candidato := Chr(Ord('C') + D) + ':' + Raizes[I];
      if ValidarPastaJogo(Candidato) then
      begin
        Result := Candidato;
        Log('Pasta do jogo via varredura de discos: ' + Result);
        Exit;
      end;
    end;
  end;
end;

function DetectarPastaJogo(): String;
var
  CaminhoSteam: String;
  Bibliotecas: TArrayOfString;
  I: Integer;
begin
  if JaDetectou then
  begin
    Result := CaminhoJogoDetectado;
    Exit;
  end;

  JaDetectou := True;
  Result := '';

  Result := ObterPastaPeloRegistroSteamApp();
  if Result = '' then
  begin
    CaminhoSteam := ObterCaminhoSteam();
    if CaminhoSteam <> '' then
    begin
      LerBibliotecasSteam(CaminhoSteam, Bibliotecas);
      for I := 0 to GetArrayLength(Bibliotecas) - 1 do
      begin
        Result := PrimeiroCandidatoValido(MontarCaminhosCandidatos(Bibliotecas[I]));
        if Result <> '' then
          Break;
      end;
    end;
  end;

  if Result = '' then
    Result := DetectarPorDrivesComuns();

  if Result = '' then
  begin
    Result := EncontrarPastaJogoAPartir(ExpandConstant('{commonpf32}\Steam'));
    if Result = '' then
      Result := EncontrarPastaJogoAPartir(ExpandConstant('{pf32}\Steam'));
  end;

  CaminhoJogoDetectado := Result;
  if Result <> '' then
    Log('Pasta do jogo detectada: ' + Result)
  else
    Log('Pasta do jogo NÃO detectada automaticamente.');
end;

function DirPadrao(Param: String): String;
begin
  Result := DetectarPastaJogo();
  if Result = '' then
    Result := ExpandConstant('{commonpf32}\Steam\steamapps\common\') + NOME_PASTA_JOGO;
end;

function ProcessoEmExecucao(const NomeProcesso: String): Boolean;
var
  CodigoSaida: Integer;
begin
  Result := False;
  if Exec('cmd.exe',
    '/C tasklist /FI "IMAGENAME eq ' + NomeProcesso + '" | find /I "' + NomeProcesso + '"',
    '', SW_HIDE, ewWaitUntilTerminated, CodigoSaida) then
    Result := (CodigoSaida = 0);
end;

function PastaEstaVazia(const Caminho: String): Boolean;
var
  Busca: TFindRec;
begin
  Result := True;
  if not DirExists(Caminho) then
    Exit;

  if FindFirst(Caminho + '\*', Busca) then
  try
    repeat
      if (Busca.Name <> '.') and (Busca.Name <> '..') then
      begin
        Result := False;
        Break;
      end;
    until not FindNext(Busca);
  finally
    FindClose(Busca);
  end;
end;

procedure RemoverPastaSeVazia(const Caminho: String);
begin
  if DirExists(Caminho) and PastaEstaVazia(Caminho) then
    RemoveDir(Caminho);
end;

procedure RemoverPastasVaziasRecursivo(const Caminho: String);
var
  Busca: TFindRec;
  SubPasta: String;
begin
  if not DirExists(Caminho) then
    Exit;

  if FindFirst(Caminho + '\*', Busca) then
  try
    repeat
      if (Busca.Attributes and FILE_ATTRIBUTE_DIRECTORY <> 0) and
         (Busca.Name <> '.') and (Busca.Name <> '..') then
      begin
        SubPasta := Caminho + '\' + Busca.Name;
        RemoverPastasVaziasRecursivo(SubPasta);
      end;
    until not FindNext(Busca);
  finally
    FindClose(Busca);
  end;

  RemoverPastaSeVazia(Caminho);
end;

function MensagemPastaInvalida(const Caminho: String): String;
begin
  if (Caminho = '') or not DirExists(Caminho) then
    Result := 'Essa pasta não existe.'
  else if not FileExists(Caminho + '\FFX-2.exe') then
    Result :=
      'Não achei o arquivo FFX-2.exe aqui.' + #13#10#13#10 +
      'Você provavelmente selecionou uma pasta acima ou abaixo da pasta do jogo.' + #13#10 +
      'A pasta certa contém FFX-2.exe e FFX2_Data.vbf lado a lado.'
  else if not FileExists(Caminho + '\FFX2_Data.vbf') then
    Result :=
      'Achei o FFX-2.exe, mas falta o FFX2_Data.vbf.' + #13#10#13#10 +
      'Isso costuma significar que o jogo ainda não terminou de baixar. ' +
      'Na Steam, use "Verificar integridade dos arquivos" e tente de novo.'
  else
    Result := 'Não encontrei o FFX-2 nesta pasta.';
end;

function InitializeSetup(): Boolean;
begin
  CaminhoJogoDetectado := DetectarPastaJogo();
  AjudaDirExibida := False;
  Result := True;
end;

procedure InitializeWizard();
begin
  if CaminhoJogoDetectado <> '' then
    WizardForm.DirEdit.Text := CaminhoJogoDetectado;
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = wpSelectDir then
  begin
    if CaminhoJogoDetectado <> '' then
      WizardForm.DirEdit.Text := CaminhoJogoDetectado
    else if not AjudaDirExibida then
    begin
      WizardForm.SelectDirLabel.Caption :=
        'Não encontramos o jogo automaticamente.' + #13#10#13#10 +
        'Clique em Procurar e escolha a pasta que contém FFX-2.exe.' + #13#10#13#10 +
        'Steam > botão direito em "FINAL FANTASY X/X-2 HD Remaster" >' + #13#10 +
        'Gerenciar > Procurar arquivos locais.';
      AjudaDirExibida := True;
    end;
  end
  else if CurPageID = wpFinished then
  begin
    WizardForm.FinishedLabel.Caption :=
      'Instalação concluída.' + #13#10#13#10 +
      'Abra o jogo pela Steam e escolha FFX-2. Os diálogos e menus traduzidos devem aparecer.' + #13#10#13#10 +
      'Um arquivo hook.log vai surgir na pasta do jogo na primeira execução. Isso é normal: confirma que o loader arrancou.' + #13#10#13#10 +
      'Se o jogo continuar em inglês, confira se dinput8.dll está na mesma pasta do FFX-2.exe e se o antivírus não o colocou em quarentena.' + #13#10#13#10 +
      'Steam Deck / Linux (Proton): este instalador Windows não cobre essa plataforma. Use o pacote ZIP e adicione' + #13#10 +
      'WINEDLLOVERRIDES=dinput8=n,b %command%' + #13#10 +
      'nas opções de inicialização da Steam.';
  end;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  CaminhoEscolhido, CaminhoCorrigido: String;
begin
  Result := True;

  if CurPageID = wpSelectDir then
  begin
    CaminhoEscolhido := NormalizarCaminho(WizardForm.DirEdit.Text);
    CaminhoCorrigido := EncontrarPastaJogoAPartir(CaminhoEscolhido);

    if CaminhoCorrigido <> '' then
    begin
      if CompareText(CaminhoCorrigido, CaminhoEscolhido) <> 0 then
      begin
        Log('Pasta ajustada de "' + CaminhoEscolhido + '" para "' + CaminhoCorrigido + '"');
        WizardForm.DirEdit.Text := CaminhoCorrigido;
        CaminhoEscolhido := CaminhoCorrigido;
      end;
    end;

    if not PastaJogoCompleta(CaminhoEscolhido) then
    begin
      MsgBox(
        MensagemPastaInvalida(CaminhoEscolhido) + #13#10#13#10 +
        'Dica: na Steam, clique com o botão direito no jogo > Gerenciar > Procurar arquivos locais.',
        mbError, MB_OK);
      Result := False;
    end;
  end;
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  Result := '';
  NeedsRestart := False;

  if ProcessoEmExecucao('FFX-2.exe') or ProcessoEmExecucao('FFX.exe') then
    Result :=
      'O jogo ou o launcher parece estar aberto.' + #13#10#13#10 +
      'Feche o FINAL FANTASY X/X-2 e tente novamente.';
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  Pasta: String;
begin
  if CurStep = ssPostInstall then
  begin
    Pasta := ExpandConstant('{app}');
    if not FileExists(Pasta + '\dinput8.dll') then
      MsgBox(
        'A cópia do loader falhou: dinput8.dll não está na pasta do jogo.' + #13#10#13#10 +
        'O Windows Defender (ou outro antivírus) às vezes coloca esse arquivo em quarentena, porque ele é um loader de mods.' + #13#10#13#10 +
        'Libere o arquivo na quarentena, ou use a instalação manual pelo ZIP da Release.',
        mbError, MB_OK)
    else if not DirExists(Pasta + '\data\mods') then
      MsgBox(
        'Os arquivos traduzidos não apareceram em data\mods.' + #13#10#13#10 +
        'Tente a instalação manual pelo ZIP da Release.',
        mbError, MB_OK);
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  PastaJogo: String;
begin
  if CurUninstallStep = usPostUninstall then
  begin
    PastaJogo := ExpandConstant('{app}');
    RemoverPastasVaziasRecursivo(PastaJogo + '\data\mods');
    RemoverPastasVaziasRecursivo(PastaJogo + '\modules');
  end;
end;
