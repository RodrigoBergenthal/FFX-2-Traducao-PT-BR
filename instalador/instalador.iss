; Instalador da tradução PT-BR — FINAL FANTASY X-2 HD Remaster (Steam)
; Copia apenas arquivos da tradução para a pasta do jogo, sem alterar dados originais.
;
; Histórico de correções relevantes:
; v1.0 — detecção básica Steam; validação exigia FFX2_Data.vbf na raiz (incorreto).
; v1.1 — pasta padrão corrigida; detecção multi-biblioteca; UX do assistente.
; v1.1.1 — busca inteligente + validação correta do VBF em data\
; v1.1.2 — botão "Buscar jogo automaticamente" estilizado (tema FFX-2)
; v1.1.3 — botão com largura dobrada (994px) para melhor proporção visual
;
; Layout real da instalação Steam (AppID 359870):
;   ...\FINAL FANTASY FFX&FFX-2 HD Remaster\
;     FFX-2.exe          ← marcador da pasta de instalação da tradução
;     FFX.exe
;     data\FFX2_Data.vbf ← arquivo grande; NÃO fica ao lado do exe
;     data\FFX_Data.vbf
;
; Serviço de busca inteligente (BuscarJogoInteligente):
;   1. Registro Windows "Steam App 359870" (InstallLocation)
;   2. libraryfolders.vdf + appmanifest_359870.acf de cada biblioteca
;   3. Varredura de steamapps\common\* em discos C..Z
;   4. Botão "Buscar jogo automaticamente" na tela de pasta
;   Prioridade: candidato com exe + vbf > candidato só com exe

#define MyAppName "Tradução PT-BR - FINAL FANTASY X-2 HD Remaster"
#define MyAppVersion "1.1.3"
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
Source: "assets\btn-buscar-normal.bmp"; Flags: dontcopy
Source: "assets\btn-buscar-hover.bmp"; Flags: dontcopy
Source: "assets\btn-buscar-disabled.bmp"; Flags: dontcopy

[UninstallDelete]
Type: files; Name: "{app}\hook.log"

[Code]
{ ---------------------------------------------------------------------------
  Constantes e estado do assistente
  --------------------------------------------------------------------------- }
const
  NOME_PASTA_JOGO = '{#NomePastaJogo}';
  STEAM_APP_ID = '{#SteamAppId}';
  CHAVE_STEAM_APP = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App {#SteamAppId}';
  CHAVE_STEAM_APP32 = 'SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Steam App {#SteamAppId}';

var
  CaminhoJogoDetectado: String;  { último caminho válido encontrado pela busca }
  JaDetectou: Boolean;           { evita repetir varredura completa na mesma sessão }
  AjudaDirExibida: Boolean;
  BtnBuscarJogo: TBitmapImage;     { botão estilizado "Buscar jogo automaticamente" }
  LblStatusBusca: TNewStaticText;{ feedback da busca na tela de pasta }
  BtnBuscarJogoAtivo: Boolean;   { evita clique duplo durante a varredura }

{ ---------------------------------------------------------------------------
  Validação de pasta — regra: FFX-2.exe na raiz é obrigatório; VBF é desejável
  --------------------------------------------------------------------------- }

function CaminhoVbfNoJogo(const Pasta: String): String;
begin
  { Steam guarda o VBF em data\; alguns espelhos antigos tinham na raiz }
  Result := '';
  if FileExists(Pasta + '\FFX2_Data.vbf') then
    Result := Pasta + '\FFX2_Data.vbf'
  else if FileExists(Pasta + '\data\FFX2_Data.vbf') then
    Result := Pasta + '\data\FFX2_Data.vbf';
end;

function ValidarPastaJogo(const Caminho: String): Boolean;
begin
  { Único requisito rígido: pasta do jogo = onde está FFX-2.exe }
  Result :=
    (Caminho <> '') and
    DirExists(Caminho) and
    FileExists(Caminho + '\FFX-2.exe');
end;

function PastaJogoCompleta(const Caminho: String): Boolean;
begin
  { FFX-2.exe fica na raiz; FFX2_Data.vbf costuma estar em data\ — não bloquear se só o exe existir }
  Result := ValidarPastaJogo(Caminho);
end;

function PastaJogoIdeal(const Caminho: String): Boolean;
begin
  { Candidato preferido na busca: exe presente e dados do jogo localizados }
  Result := ValidarPastaJogo(Caminho) and (CaminhoVbfNoJogo(Caminho) <> '');
end;

{ ---------------------------------------------------------------------------
  Utilitários de caminho e lista de candidatos
  --------------------------------------------------------------------------- }

function NormalizarCaminho(const Caminho: String): String;
begin
  Result := Trim(Caminho);
  if (Length(Result) >= 2) and (Result[1] = '"') and (Result[Length(Result)] = '"') then
    Result := Copy(Result, 2, Length(Result) - 2);
  StringChangeEx(Result, '/', '\', True);
  if (Result <> '') and (Result[Length(Result)] = '\') then
    Delete(Result, Length(Result), 1);
end;

function CandidatoJaListado(const Lista: TArrayOfString; const Caminho: String): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to GetArrayLength(Lista) - 1 do
    if CompareText(NormalizarCaminho(Lista[I]), NormalizarCaminho(Caminho)) = 0 then
    begin
      Result := True;
      Exit;
    end;
end;

procedure AdicionarCandidato(var Lista: TArrayOfString; const Caminho: String);
var
  Normalizado: String;
begin
  Normalizado := NormalizarCaminho(Caminho);
  if ValidarPastaJogo(Normalizado) and not CandidatoJaListado(Lista, Normalizado) then
  begin
    SetArrayLength(Lista, GetArrayLength(Lista) + 1);
    Lista[GetArrayLength(Lista) - 1] := Normalizado;
  end;
end;

function MelhorCandidato(const Lista: TArrayOfString): String;
var
  I: Integer;
  Caminho: String;
begin
  { 1º: pasta ideal (exe + vbf); 2º: aceita só exe para não bloquear instalação }
  Result := '';
  for I := 0 to GetArrayLength(Lista) - 1 do
  begin
    Caminho := NormalizarCaminho(Lista[I]);
    if PastaJogoIdeal(Caminho) then
    begin
      Result := Caminho;
      Exit;
    end;
  end;

  for I := 0 to GetArrayLength(Lista) - 1 do
  begin
    Caminho := NormalizarCaminho(Lista[I]);
    if ValidarPastaJogo(Caminho) then
    begin
      Result := Caminho;
      Exit;
    end;
  end;
end;

{ ---------------------------------------------------------------------------
  Busca local em steamapps\common — lista subpastas até achar FFX-2.exe
  --------------------------------------------------------------------------- }

function BuscarExeEmPastaCommon(const PastaCommon: String): String;
var
  Busca: TFindRec;
  SubPasta: String;
begin
  Result := '';
  if not DirExists(PastaCommon) then
    Exit;

  if ValidarPastaJogo(PastaCommon) then
  begin
    Result := NormalizarCaminho(PastaCommon);
    Exit;
  end;

  if FindFirst(PastaCommon + '\*', Busca) then
  try
    repeat
      if (Busca.Attributes and FILE_ATTRIBUTE_DIRECTORY <> 0) and
         (Busca.Name <> '.') and (Busca.Name <> '..') then
      begin
        SubPasta := NormalizarCaminho(PastaCommon + '\' + Busca.Name);
        if ValidarPastaJogo(SubPasta) then
        begin
          Result := SubPasta;
          Exit;
        end;
      end;
    until not FindNext(Busca);
  finally
    FindClose(Busca);
  end;
end;

{ ---------------------------------------------------------------------------
  Leitura de registro Steam e arquivos VDF/ACF
  --------------------------------------------------------------------------- }

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

{ ---------------------------------------------------------------------------
  Serviço de busca inteligente — orquestra registro, bibliotecas e discos
  --------------------------------------------------------------------------- }

function BuscarEmBibliotecaSteam(const CaminhoBiblioteca: String): String;
var
  Candidatos: TArrayOfString;
  Caminhos: TArrayOfString;
  PastaCommon: String;
  I: Integer;
begin
  { Caminhos conhecidos + varredura de toda a pasta common desta biblioteca }
  Result := '';
  SetArrayLength(Candidatos, 0);

  Caminhos := MontarCaminhosCandidatos(CaminhoBiblioteca);
  for I := 0 to GetArrayLength(Caminhos) - 1 do
    AdicionarCandidato(Candidatos, Caminhos[I]);

  PastaCommon := NormalizarCaminho(CaminhoBiblioteca + '\steamapps\common');
  if DirExists(PastaCommon) then
    AdicionarCandidato(Candidatos, BuscarExeEmPastaCommon(PastaCommon));

  PastaCommon := NormalizarCaminho(CaminhoBiblioteca + '\SteamApps\common');
  if DirExists(PastaCommon) then
    AdicionarCandidato(Candidatos, BuscarExeEmPastaCommon(PastaCommon));

  Result := MelhorCandidato(Candidatos);
  if Result <> '' then
    Log('Busca inteligente (biblioteca): ' + Result);
end;

function BuscarJogoInteligente(): String;
var
  CaminhoSteam: String;
  Bibliotecas: TArrayOfString;
  Candidatos: TArrayOfString;
  Encontrado: String;
  I, D: Integer;
  Raizes: TArrayOfString;
  Candidato: String;
begin
  SetArrayLength(Candidatos, 0);
  Result := '';

  Encontrado := ObterPastaPeloRegistroSteamApp();
  if Encontrado <> '' then
    AdicionarCandidato(Candidatos, Encontrado);

  CaminhoSteam := ObterCaminhoSteam();
  if CaminhoSteam <> '' then
  begin
    LerBibliotecasSteam(CaminhoSteam, Bibliotecas);
    for I := 0 to GetArrayLength(Bibliotecas) - 1 do
    begin
      Encontrado := BuscarEmBibliotecaSteam(Bibliotecas[I]);
      if Encontrado <> '' then
        AdicionarCandidato(Candidatos, Encontrado);
    end;
  end;

  SetArrayLength(Raizes, 6);
  Raizes[0] := '\Program Files (x86)\Steam\steamapps\common';
  Raizes[1] := '\Program Files\Steam\steamapps\common';
  Raizes[2] := '\Steam\steamapps\common';
  Raizes[3] := '\SteamLibrary\steamapps\common';
  Raizes[4] := '\Jogos\Steam\steamapps\common';
  Raizes[5] := '\Games\Steam\steamapps\common';

  for D := 0 to 23 do
    for I := 0 to GetArrayLength(Raizes) - 1 do
    begin
      Candidato := Chr(Ord('C') + D) + ':' + Raizes[I];
      Encontrado := BuscarExeEmPastaCommon(Candidato);
      if Encontrado <> '' then
        AdicionarCandidato(Candidatos, Encontrado);
    end;

  Result := MelhorCandidato(Candidatos);
  if Result <> '' then
  begin
    JaDetectou := True;
    CaminhoJogoDetectado := Result;
    Log('Busca inteligente concluída: ' + Result);
  end;
end;

{ ---------------------------------------------------------------------------
  Ajuste de pasta escolhida manualmente (sobe/desce até achar FFX-2.exe)
  --------------------------------------------------------------------------- }

function EncontrarPastaJogoAPartir(const CaminhoInicial: String): String;
var
  Atual, Filho, Pai: String;
  I: Integer;
begin
  Result := '';
  Atual := NormalizarCaminho(CaminhoInicial);
  if Atual = '' then
    Exit;

  if CompareText(ExtractFileName(Atual), 'data') = 0 then
  begin
    { Usuário selecionou data\ — subir um nível para a raiz do jogo }
    Pai := NormalizarCaminho(ExtractFileDir(Atual));
    if ValidarPastaJogo(Pai) then
    begin
      Result := Pai;
      Exit;
    end;
  end;

  for I := 1 to 6 do
  begin
    if ValidarPastaJogo(Atual) then
    begin
      Result := Atual;
      Exit;
    end;

    Filho := BuscarExeEmPastaCommon(Atual);
    if Filho <> '' then
    begin
      Result := Filho;
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

function DetectarPastaJogo(): String;
begin
  { Entrada única da detecção automática na abertura do instalador }
  if JaDetectou then
  begin
    Result := CaminhoJogoDetectado;
    Exit;
  end;

  Result := BuscarJogoInteligente();
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

{ ---------------------------------------------------------------------------
  UI: botão de busca estilizado, mensagens e eventos do assistente
  --------------------------------------------------------------------------- }

procedure DefinirEstadoBtnBuscar(Habilitado: Boolean);
var
  Arquivo: String;
begin
  BtnBuscarJogoAtivo := Habilitado;
  if not Habilitado then
    Arquivo := 'btn-buscar-disabled.bmp'
  else
    Arquivo := 'btn-buscar-normal.bmp';

  BtnBuscarJogo.Bitmap.LoadFromFile(ExpandConstant('{tmp}\' + Arquivo));
  if Habilitado then
    BtnBuscarJogo.Cursor := crHand
  else
    BtnBuscarJogo.Cursor := crDefault;
end;

function MensagemPastaInvalida(const Caminho: String): String;
var
  Vbf: String;
begin
  if (Caminho = '') or not DirExists(Caminho) then
    Result := 'Essa pasta não existe.'
  else if not FileExists(Caminho + '\FFX-2.exe') then
    Result :=
      'Não achei o arquivo FFX-2.exe aqui.' + #13#10#13#10 +
      'A pasta certa contém FFX-2.exe na raiz.' + #13#10 +
      'O arquivo FFX2_Data.vbf fica em data\ (não precisa estar na mesma pasta do exe).' + #13#10#13#10 +
      'Use o botão "Buscar jogo automaticamente" ou aponte para a pasta aberta pela Steam em Procurar arquivos locais.'
  else
  begin
    Vbf := CaminhoVbfNoJogo(Caminho);
    if Vbf = '' then
      Result :=
        'Encontrei FFX-2.exe, mas não achei FFX2_Data.vbf na raiz nem em data\.' + #13#10#13#10 +
        'Verifique na Steam se o jogo terminou de baixar (Verificar integridade dos arquivos).'
    else
      Result := 'Não encontrei o FFX-2 nesta pasta.';
  end;
end;

procedure BtnBuscarJogoClick(Sender: TObject);
var
  Encontrado, Vbf: String;
begin
  if not BtnBuscarJogoAtivo then
    Exit;

  { Dispara BuscarJogoInteligente e preenche o campo de pasta do assistente }
  DefinirEstadoBtnBuscar(False);
  LblStatusBusca.Caption := 'Procurando FFX-2.exe nas bibliotecas da Steam...';
  LblStatusBusca.Font.Color := $006B8299; { azul oceano — BGR }
  WizardForm.Refresh;

  Encontrado := BuscarJogoInteligente();

  DefinirEstadoBtnBuscar(True);
  if Encontrado <> '' then
  begin
    WizardForm.DirEdit.Text := Encontrado;
    CaminhoJogoDetectado := Encontrado;
    Vbf := CaminhoVbfNoJogo(Encontrado);
    if Vbf <> '' then
    begin
      LblStatusBusca.Caption := 'Jogo encontrado. FFX-2.exe e FFX2_Data.vbf localizados.';
      LblStatusBusca.Font.Color := $003C8CB4; { dourado — BGR }
    end
    else
    begin
      LblStatusBusca.Caption := 'FFX-2.exe encontrado. FFX2_Data.vbf não localizado — confira o download na Steam.';
      LblStatusBusca.Font.Color := $006B8299;
    end;
  end
  else
  begin
    LblStatusBusca.Caption := 'Não encontramos o jogo. Instale o FFX-2 pela Steam ou selecione a pasta manualmente.';
    LblStatusBusca.Font.Color := $004A4AA8; { coral suave — BGR }
  end;
end;

function InitializeSetup(): Boolean;
begin
  CaminhoJogoDetectado := DetectarPastaJogo();
  AjudaDirExibida := False;
  Result := True;
end;

procedure InitializeWizard();
begin
  ExtractTemporaryFile('btn-buscar-normal.bmp');
  ExtractTemporaryFile('btn-buscar-hover.bmp');
  ExtractTemporaryFile('btn-buscar-disabled.bmp');

  BtnBuscarJogoAtivo := True;

  BtnBuscarJogo := TBitmapImage.Create(WizardForm);
  BtnBuscarJogo.Parent := WizardForm.SelectDirPage;
  BtnBuscarJogo.Width := 994;
  BtnBuscarJogo.Height := 48;
  BtnBuscarJogo.Left := WizardForm.DirEdit.Left + (WizardForm.DirEdit.Width - 994) div 2;
  if BtnBuscarJogo.Left < 0 then
    BtnBuscarJogo.Left := 0;
  BtnBuscarJogo.Top := WizardForm.DirEdit.Top + WizardForm.DirEdit.Height + 12;
  BtnBuscarJogo.Stretch := False;
  BtnBuscarJogo.OnClick := @BtnBuscarJogoClick;
  DefinirEstadoBtnBuscar(True);

  LblStatusBusca := TNewStaticText.Create(WizardForm);
  LblStatusBusca.Parent := WizardForm.SelectDirPage;
  LblStatusBusca.AutoSize := True;
  LblStatusBusca.Left := WizardForm.DirEdit.Left;
  LblStatusBusca.Top := BtnBuscarJogo.Top + BtnBuscarJogo.Height + 8;
  LblStatusBusca.Font.Color := $006B8299;
  LblStatusBusca.Caption := 'O instalador procura FFX-2.exe e FFX2_Data.vbf (em data\) nas bibliotecas da Steam.';

  if CaminhoJogoDetectado <> '' then
  begin
    WizardForm.DirEdit.Text := CaminhoJogoDetectado;
    if PastaJogoIdeal(CaminhoJogoDetectado) then
    begin
      LblStatusBusca.Caption := 'Jogo detectado automaticamente.';
      LblStatusBusca.Font.Color := $003C8CB4;
    end
    else
    begin
      LblStatusBusca.Caption := 'FFX-2.exe detectado. Confira se o jogo está completo na Steam.';
      LblStatusBusca.Font.Color := $006B8299;
    end;
  end;
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
        'Escolha a pasta do jogo (onde está FFX-2.exe) ou clique em Buscar jogo automaticamente.' + #13#10#13#10 +
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
        'Dica: use Buscar jogo automaticamente ou Procurar arquivos locais na Steam.',
        mbError, MB_OK);
      Result := False;
    end
    else if not PastaJogoIdeal(CaminhoEscolhido) then
    begin
      if MsgBox(
        'Encontrei FFX-2.exe, mas não localizei FFX2_Data.vbf na raiz nem em data\.' + #13#10#13#10 +
        'A tradução pode instalar, mas o jogo pode não abrir corretamente até você verificar os arquivos na Steam.' + #13#10#13#10 +
        'Deseja continuar mesmo assim?',
        mbConfirmation, MB_YESNO) = IDNO then
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
