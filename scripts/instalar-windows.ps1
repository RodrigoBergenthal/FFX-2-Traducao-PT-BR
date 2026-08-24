#Requires -Version 5.1
<#
.SYNOPSIS
  Copia a tradução PT-BR para a pasta do FINAL FANTASY X-2 HD Remaster (Steam).

.DESCRIPTION
  Alternativa ao Setup.exe quando o SmartScreen bloqueia o instalador.
  Precisa ser executado a partir do repositório, com a pasta arquivos-do-jogo/
  preenchida. Feche o jogo antes de rodar.

  Espelha a lógica do instalador Inno Setup (v1.1.3):
  - pasta válida = contém FFX-2.exe na raiz
  - FFX2_Data.vbf pode estar em data\ (layout padrão da Steam)
#>

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$origem = Join-Path $repoRoot 'arquivos-do-jogo'
$nomePastaJogo = 'FINAL FANTASY FFX&FFX-2 HD Remaster'
$steamAppId = '359870'

if (-not (Test-Path -LiteralPath (Join-Path $origem 'dinput8.dll'))) {
    Write-Host 'ERRO: arquivos-do-jogo/dinput8.dll nao encontrado.' -ForegroundColor Red
    Write-Host 'Este script precisa da pasta arquivos-do-jogo preenchida no repositorio.'
    exit 1
}

# Mínimo para instalar: FFX-2.exe na raiz da pasta escolhida.
function Test-PastaJogoMinima {
    param([string]$Caminho)
    if ([string]::IsNullOrWhiteSpace($Caminho)) { return $false }
    return (Test-Path -LiteralPath (Join-Path $Caminho 'FFX-2.exe'))
}

# Ideal: exe + VBF na raiz ou em data\ (não bloqueia se faltar VBF).
function Test-PastaJogoCompleta {
    param([string]$Caminho)
    if (-not (Test-PastaJogoMinima $Caminho)) { return $false }
    $vbfRaiz = Join-Path $Caminho 'FFX2_Data.vbf'
    $vbfData = Join-Path $Caminho 'data\FFX2_Data.vbf'
    return (Test-Path -LiteralPath $vbfRaiz) -or (Test-Path -LiteralPath $vbfData)
}

function Get-SteamPath {
    $chaves = @(
        @{ Hive = 'HKCU:'; Path = 'Software\Valve\Steam'; Name = 'SteamPath' },
        @{ Hive = 'HKLM:'; Path = 'SOFTWARE\WOW6432Node\Valve\Steam'; Name = 'InstallPath' },
        @{ Hive = 'HKLM:'; Path = 'SOFTWARE\Valve\Steam'; Name = 'InstallPath' }
    )
    foreach ($chave in $chaves) {
        $item = Join-Path $chave.Hive $chave.Path
        if (Test-Path $item) {
            $valor = (Get-ItemProperty $item -ErrorAction SilentlyContinue).$($chave.Name)
            if ($valor) {
                return ($valor -replace '/', '\').TrimEnd('\')
            }
        }
    }
    return $null
}

function Get-BibliotecasSteam {
    param([string]$SteamPath)
    $libs = New-Object System.Collections.Generic.List[string]
    if ($SteamPath) { [void]$libs.Add($SteamPath) }

    $vdf = Join-Path $SteamPath 'steamapps\libraryfolders.vdf'
    if (Test-Path -LiteralPath $vdf) {
        foreach ($linha in Get-Content -LiteralPath $vdf -ErrorAction SilentlyContinue) {
            if ($linha -match '"path"\s+"([^"]+)"') {
                $p = ($Matches[1] -replace '\\\\', '\').TrimEnd('\')
                if ($p -and (Test-Path -LiteralPath $p) -and -not $libs.Contains($p)) {
                    [void]$libs.Add($p)
                }
            }
        }
    }
    return $libs
}

# Busca inteligente: registro Steam App, bibliotecas e caminhos comuns em C..Z.
function Find-PastaJogo {
    $regKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App $steamAppId",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Steam App $steamAppId"
    )
    foreach ($k in $regKeys) {
        if (Test-Path $k) {
            $loc = (Get-ItemProperty $k -ErrorAction SilentlyContinue).InstallLocation
            if (Test-PastaJogoMinima $loc) { return $loc.TrimEnd('\') }
        }
    }

    $steam = Get-SteamPath
    if ($steam) {
        foreach ($lib in Get-BibliotecasSteam $steam) {
            $candidato = Join-Path $lib "steamapps\common\$nomePastaJogo"
            if (Test-PastaJogoMinima $candidato) { return $candidato }
        }
    }

    foreach ($letra in 67..90) {
        $drive = [char]$letra
        foreach ($sufixo in @(
            "\Program Files (x86)\Steam\steamapps\common\$nomePastaJogo",
            "\Program Files\Steam\steamapps\common\$nomePastaJogo",
            "\SteamLibrary\steamapps\common\$nomePastaJogo",
            "\Steam\steamapps\common\$nomePastaJogo",
            "\Jogos\Steam\steamapps\common\$nomePastaJogo"
        )) {
            $candidato = "${drive}:$sufixo"
            if (Test-PastaJogoMinima $candidato) { return $candidato }
        }
    }
    return $null
}

$destino = Find-PastaJogo
if (-not $destino) {
    Write-Host 'Nao encontrei o FFX-2 automaticamente.' -ForegroundColor Yellow
    $destino = Read-Host 'Cole o caminho da pasta do jogo (onde esta FFX-2.exe)'
    $destino = $destino.Trim().Trim('"')
}

if (-not (Test-PastaJogoMinima $destino)) {
    Write-Host "ERRO: pasta invalida: $destino" -ForegroundColor Red
    Write-Host 'A pasta precisa conter FFX-2.exe.'
    exit 1
}

if (-not (Test-PastaJogoCompleta $destino)) {
    Write-Host 'AVISO: FFX2_Data.vbf nao encontrado na raiz nem em data\.' -ForegroundColor Yellow
    Write-Host 'Continuando porque a traducao so precisa do FFX-2.exe na pasta.'
}

$ffx2 = Get-Process -Name 'FFX-2','FFX' -ErrorAction SilentlyContinue
if ($ffx2) {
    Write-Host 'ERRO: feche o FFX / FFX-2 e rode o script de novo.' -ForegroundColor Red
    exit 1
}

Write-Host "Copiando traducao para:`n  $destino"
Copy-Item -Path (Join-Path $origem '*') -Destination $destino -Recurse -Force

$loader = Join-Path $destino 'dinput8.dll'
if (-not (Test-Path -LiteralPath $loader)) {
    Write-Host 'ERRO: dinput8.dll nao apareceu no destino. Verifique o antivírus / quarentena.' -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host 'Traducao copiada. Abra o FFX-2 pela Steam.' -ForegroundColor Green
Write-Host 'Na primeira execucao deve surgir hook.log na pasta do jogo.'
