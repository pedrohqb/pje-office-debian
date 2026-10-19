# pje-office-debian

Script que gera um pacote `.deb` nativo do **PJeOffice Pro** para Debian, Ubuntu, Linux Mint e demais distribuições derivadas do Debian (64 bits).

O PJeOffice Pro é o assinador do CNJ usado no PJe (Processo Judicial Eletrônico). Para Linux, o CNJ distribui só um arquivo `.zip`, que traz um Java embutido e não se integra ao sistema. Este script baixa esse `.zip` do servidor oficial, confere a integridade e monta um pacote que:

- aparece no menu de aplicativos, com ícone;
- usa o Java do sistema (Azul Zulu 11) no lugar do Java embutido;
- funciona em ambientes Wayland, inclusive KDE Plasma 6; e
- é instalado, atualizado e removido pelo `apt`, como qualquer outro programa.

**Versão empacotada atualmente**: PJeOffice Pro 2.5.16u.

## Requisitos

- Debian, Ubuntu, Linux Mint ou derivado, em **64 bits (amd64)**.
- Ferramentas usadas na geração do pacote:
  ```
  sudo apt install wget unzip
  ```
  (`dpkg-deb` e `sha256sum` já vêm instalados no sistema.)
- **Azul Zulu 11 (JDK), no pacote `.deb` baixado do site da Azul.** O PJeOffice depende do pacote `zulu-11` e procura o Java em `/usr/lib/jvm/zulu-11-amd64`.

> **Atenção:** o pacote `zulu11-jdk` do repositório APT da Azul **não serve**. Ele tem outro nome e instala o Java em outra pasta (`/usr/lib/jvm/zulu11-ca-amd64`), de modo que o PJeOffice não o encontra. Use o `.deb` avulso, conforme o passo 1 abaixo.

## Instalação

### 1. Instale o Zulu 11

1. Acesse https://www.azul.com/downloads/.
2. Filtre por **Java 11 (LTS)**, **Linux**, **x86 64-bit** e **JDK**.
3. Baixe o arquivo **`.deb`** (o nome é parecido com `zulu11.xx.xx-ca-jdk11.0.xx-linux_amd64.deb`).
4. Na pasta onde o arquivo foi salvo, instale-o:
   ```
   sudo apt install ./zulu11*-linux_amd64.deb
   ```

### 2. Obtenha o pacote do PJeOffice

Há duas formas, e o resultado é o mesmo:

- **Baixar o pacote pronto**: na página de [Releases](https://github.com/pedrohqb/pje-office-debian/releases), baixe o `pje-office_2.5.16u-3_amd64.deb` da versão mais recente.
- **Gerar o pacote você mesmo**, a partir do `.zip` oficial do CNJ:
  ```
  git clone https://github.com/pedrohqb/pje-office-debian.git
  cd pje-office-debian
  bash pje-office-deb.sh
  ```
  Ao final, o arquivo `pje-office_2.5.16u-3_amd64.deb` estará na pasta atual.

### 3. Instale o pacote

Na pasta onde está o `.deb`:

```
sudo apt install ./pje-office_2.5.16u-3_amd64.deb
```

### 4. Abra o PJeOffice

Procure **PJeOffice** no menu de aplicativos ou rode `pjeoffice-pro` no terminal.

## O que o script faz

1. Apaga a pasta `build/` de execuções anteriores.
2. Baixa o `.zip` oficial do PJeOffice Pro de `pje-office.pje.jus.br`.
3. Confere a soma SHA256 do arquivo baixado e para se ela não bater com a esperada.
4. Extrai o programa e remove o Java embutido (`jre/`), o `LEIA-ME.TXT` e o `.gitignore`.
5. Cria o script de inicialização, que usa o Java do Zulu 11 e define `_JAVA_AWT_WM_NONREPARENTING=1` para o programa abrir corretamente em Wayland.
6. Extrai o ícone de dentro do `pjeoffice-pro.jar` e cria o atalho `.desktop`.
7. Gera os arquivos de controle do pacote (dependências `zulu-11` e `bash`, e um `postinst` que atualiza o menu e o cache de ícones).
8. Monta o `.deb` com `dpkg-deb`.

Os arquivos do PJeOffice (inclusive o `pjeoffice-pro.jar`) entram no pacote exatamente como vêm no `.zip` do CNJ, sem nenhuma alteração. O pacote só deixa de fora o Java embutido e acrescenta o script de inicialização, o ícone e o atalho.

## Onde os arquivos ficam

| Caminho | Conteúdo |
| --- | --- |
| `/usr/share/pjeoffice-pro/` | Programa (`pjeoffice-pro.jar`), script de inicialização e atalho |
| `/usr/bin/pjeoffice-pro` | Comando para abrir o programa (link para o script de inicialização) |
| `/usr/share/applications/pje-office.desktop` | Atalho no menu de aplicativos |
| `/usr/share/icons/hicolor/512x512/apps/pjeoffice.png` | Ícone |

## Atualização para uma nova versão do PJeOffice

Quando o CNJ publicar uma versão nova:

1. Baixe o novo `.zip` para Linux e calcule a soma SHA256:
   ```
   sha256sum pjeoffice-pro-vX.Y.Z-linux_x64.zip
   ```
2. No início do `pje-office-deb.sh`, atualize:
   - `VERSAO_PACOTE` com o número da nova versão (o mesmo que aparece no nome do `.zip`);
   - `SOMA_SHA256` com a soma calculada; e
   - `REVISAO_PACOTE`, voltando para `1`.
3. Gere e instale o pacote novamente (passos 2 e 3 da instalação). O `apt` substitui a versão antiga.

Se mudar apenas o empacotamento (e não a versão do PJeOffice), aumente só o `REVISAO_PACOTE`.

## Desinstalação

```
sudo apt remove pje-office
```

O Zulu 11 não é removido junto. Se não for usá-lo para outra coisa, remova-o com `sudo apt remove zulu-11`.

## Solução de problemas

- **Erro de dependência `zulu-11` ao instalar o pacote.** O Zulu 11 não está instalado, ou foi instalado pelo repositório APT da Azul (`zulu11-jdk`). Instale o `.deb` avulso, conforme o passo 1.
- **O PJeOffice não abre e o terminal mostra que `/usr/lib/jvm/zulu-11-amd64/bin/java` não existe.** Mesma causa do item anterior.
- **Erro de soma SHA256 ao gerar o pacote.** O arquivo baixado está corrompido ou o CNJ substituiu o `.zip` daquela versão. Rode o script de novo; se o erro continuar, confira a versão publicada no site do PJeOffice e atualize o script (veja a seção de atualização).
- **Janela em branco ou cinza.** O script de inicialização já define `_JAVA_AWT_WM_NONREPARENTING=1`, que resolve o problema na maioria dos ambientes Wayland. Para ver as mensagens de erro, abra o programa pelo terminal com `pjeoffice-pro`.
- **O token ou cartão do certificado digital não é reconhecido.** O PJeOffice depende do driver (middleware) do token, como SafeSign ou SafeNet, que não faz parte deste pacote. Instale o driver indicado pelo fabricante do seu certificado.

## Veja também

Para ter num só lugar o PJeOffice, os drivers de token e certificado e os demais programas usados por advogados no Linux, inclusive em distribuições que não são derivadas do Debian, veja o [distrobox-adv-br](https://github.com/pedrohqb/distrobox-adv-br).

## Licença

O script está em domínio público, sob a licença [CC0-1.0](LICENSE). O PJeOffice Pro é software do CNJ: os pacotes publicados em Releases trazem os arquivos originais do programa, sem alteração, e a licença CC0 não se aplica a eles.
