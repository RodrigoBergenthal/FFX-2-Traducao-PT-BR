# Segurança e verificação de downloads

## Fonte oficial

Os arquivos de instalação devem ser obtidos somente pela página de Releases deste repositório:

**https://github.com/RodrigoBergenthal/FFX-2-Traducao-PT-BR/releases**

Links diretos da versão mais recente (v1.1.3):

- Instalador Windows: https://github.com/RodrigoBergenthal/FFX-2-Traducao-PT-BR/releases/download/v1.1.3/FFX2-Traducao-PTBR-Setup.exe
- Pacote manual ZIP (v1.1.1): https://github.com/RodrigoBergenthal/FFX-2-Traducao-PT-BR/releases/download/v1.1.1/FFX-2-Traducao-PT-BR-v1.1.1.zip

Não baixe de cópias reenviadas por terceiros em fóruns, Discord ou sites espelho.

## Verificação SHA-256

Cada Release informa nome, tamanho e hash SHA-256. Exemplo para o instalador v1.1.3:

```
999960c686002b4b23e661c8f58b4b5a32d1a8b5716c710ca22937a63cf37a0e
```

No Windows, o hash pode ser conferido pelo PowerShell:

```powershell
Get-FileHash ".\FFX2-Traducao-PTBR-Setup.exe" -Algorithm SHA256
```

No Linux ou Steam Deck:

```bash
sha256sum FFX2-Traducao-PTBR-Setup.exe
sha256sum FFX-2-Traducao-PT-BR-v1.1.1.zip
```

## Instalador sem assinatura digital

O instalador Windows ainda não possui assinatura digital. O SmartScreen pode exibir um aviso. Confirme o hash SHA-256 antes de executar. O pacote manual (ZIP) permanece disponível como alternativa.

## Reporte de problemas de segurança

Se encontrar comportamento suspeito em arquivos obtidos pela Release oficial, abra uma issue descrevendo:

- de onde baixou o arquivo;
- hash SHA-256 calculado localmente;
- comportamento observado (antivírus, SmartScreen, arquivos inesperados).

Não publique links de downloads alternativos na issue.

## Boas práticas

- Faça backup dos saves antes de instalar qualquer mod
- Use apenas o External File Loader incluído no pacote oficial
- Remova arquivos adicionados pelo mod antes de verificar integridade na Steam
- Consulte `LEIA-ME.txt` para instalação, remoção e compatibilidade
