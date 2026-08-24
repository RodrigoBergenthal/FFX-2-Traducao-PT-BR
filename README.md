<h1 align="center">Final Fantasy X-2 HD Remaster — Tradução PT-BR</h1>

<p align="center">
  Projeto gratuito e não oficial de tradução em português do Brasil do
  <strong>FINAL FANTASY X-2 HD Remaster</strong> para Steam, Windows e Steam Deck / Linux.
</p>

## Download (v1.1.3)

| Arquivo | Descrição | Link |
|---------|-----------|------|
| **FFX2-Traducao-PTBR-Setup.exe** | Instalador Windows (recomendado) | [**Baixar**](https://github.com/RodrigoBergenthal/FFX-2-Traducao-PT-BR/releases/download/v1.1.3/FFX2-Traducao-PTBR-Setup.exe) |
| **FFX-2-Traducao-PT-BR-v1.1.1.zip** | Pacote manual (Steam Deck / Linux) | [**Baixar**](https://github.com/RodrigoBergenthal/FFX-2-Traducao-PT-BR/releases/download/v1.1.1/FFX-2-Traducao-PT-BR-v1.1.1.zip) |
| Todas as versões | Histórico completo | [**Releases**](https://github.com/RodrigoBergenthal/FFX-2-Traducao-PT-BR/releases) |

**SHA-256 do instalador v1.1.3:** `999960c686002b4b23e661c8f58b4b5a32d1a8b5716c710ca22937a63cf37a0e`

<p align="center">
  <a href="https://manoxande.github.io/FFX-2-Traducao-PT-BR/"><strong>Site do projeto e tutorial</strong></a>
</p>

> **Aviso:** este projeto não possui vínculo, autorização, patrocínio ou endosso da Square Enix.
> O jogo original e atualizado da Steam é obrigatório.

## Melhorias recentes do instalador (v1.1.1 → v1.1.3)

- **Busca inteligente** da pasta do jogo nas bibliotecas da Steam (registro, `libraryfolders.vdf`, varredura de discos)
- **Validação correta** do `FFX2_Data.vbf` em `data\` (layout real da instalação Steam)
- **Botão estilizado** “Buscar jogo automaticamente” no tema FFX-2 (azul oceano + borda dourada, 994×48 px)
- **Script alternativo** `scripts/instalar-windows.ps1` para instalação sem o assistente gráfico

Baixe somente pelos links acima ou pela página de [Releases](https://github.com/RodrigoBergenthal/FFX-2-Traducao-PT-BR/releases). Confira sempre o hash SHA-256 publicado na Release.

## O que está traduzido

- Roteiro e diálogos dos eventos, com cerca de 35 mil falas
- Falas, popups e tutoriais de batalha
- Menus e descrições de itens, habilidades, acessórios e Grade de Vestes
- Bestiário e telas de sistema do remaster
- DLC Last Mission
- Fonte ajustada para ã e õ nos diálogos

Alguns nomes, rótulos do menu principal e elementos com limitações técnicas permanecem em inglês. Consulte o `LEIA-ME.txt` para os detalhes.

## Como funciona

O jogo verifica a integridade de seus arquivos originais. Este pacote não substitui o arquivo `FFX2_Data.vbf`.

A tradução utiliza o [External File Loader de ffgriever](https://www.nexusmods.com/finalfantasyxx2hdremaster/mods/150), que permite carregar arquivos adicionais a partir de `data/mods`. O pacote adiciona o loader, arquivos de configuração e conteúdos traduzidos.

## Segurança e verificação

- Baixe apenas pela Release oficial deste repositório
- Confira o hash SHA-256 antes de executar
- O instalador do Windows ainda não possui assinatura digital
- Faça backup dos saves antes de instalar qualquer mod
- Consulte [`SECURITY.md`](SECURITY.md) para orientações de verificação e reporte de problemas

## Estrutura do repositório

- `docs/` — site do projeto publicado pelo GitHub Pages
- `instalador/` — código-fonte do instalador Inno Setup
- `scripts/` — utilitários de instalação e empacotamento
- `LEIA-ME.txt` — instruções completas de instalação, remoção e compatibilidade
- `arquivos-do-jogo/` — área local de empacotamento (binários não versionados)

## Licenciamento

A licença deste repositório abrange **somente o código original** criado para o site, instalador e scripts próprios.

Ela não concede direitos sobre:

- FINAL FANTASY X-2 ou materiais pertencentes à Square Enix e demais titulares
- textos, personagens, imagens, marcas e arquivos derivados do jogo
- External File Loader e outros componentes de terceiros
- a tradução como obra derivada do roteiro original

Consulte [`LICENSE`](LICENSE) e [`THIRD-PARTY-NOTICES.md`](THIRD-PARTY-NOTICES.md).

## Créditos

- **External File Loader:** ffgriever
- **Terminologia:** inspirada na tradução do FFX da [Central de Traduções](https://www.centraldetraducoes.net.br/2017/04/traducao-do-final-fantasy-x-hd-remaster-pc.html)
- **Tradução PT-BR:** Carlos Alexandre de Oliveira
- **Processo de trabalho:** engenharia reversa de formatos, ferramentas de tradução assistida por inteligência artificial e revisão humana

## Aviso legal

FINAL FANTASY X-2, seus personagens, textos, imagens e marcas pertencem aos respectivos titulares. Este é um projeto de fã gratuito e não comercial. Não inclui o jogo, não vende acesso e não aceita pagamento condicionado ao download.
