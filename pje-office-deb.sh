#!/bin/bash

# Script para criar um pacote Debian (.deb) para o PJeOffice

# --- Metadados do Pacote ---
NOME_PACOTE="pje-office"
VERSAO_PACOTE="2.5.16u"
REVISAO_PACOTE="1"
ARQUITETURA_PACOTE="amd64" # Para sistemas Linux de 64 bits
DESCRICAO_PACOTE="O PJeOffice é um software disponibilizado pelo CNJ (Conselho Nacional de Justiça) para assinatura eletrônica de documentos do sistema PJe (Processo Judicial Eletrônico)."
# Dependência para Zulu 11 e Bash. O pacote 'zulu-11' não é padrão nos repositórios do Debian/Ubuntu
DEPENDENCIAS_PACOTE="zulu-11, bash"
URL_FONTE="https://pje-office.pje.jus.br/pro/pjeoffice-pro-v${VERSAO_PACOTE}-linux_x64.zip"
SOMA_SHA256="6087391759c7cba11fb5ef815fe8be91713b46a8607c12eb664a9d9a6882c4c7"

# --- Diretórios ---
DIRETORIO_SCRIPT="$(dirname "$(readlink -f "$0")")"
RAIZ_BUILD="${DIRETORIO_SCRIPT}/build"
DIRETORIO_PACOTE_TEMP="${RAIZ_BUILD}/${NOME_PACOTE}-${VERSAO_PACOTE}" # Diretório temporário para montar o pacote
DIRETORIO_DEBIAN="${DIRETORIO_PACOTE_TEMP}/DEBIAN"
NOME_ARQUIVO_FONTE="pjeoffice-pro-v${VERSAO_PACOTE}-linux_x64.zip"
NOME_DIRETORIO_EXTRAIDO="pjeoffice-pro"

# --- Funções ---

# Função para limpar artefatos de builds anteriores
limpar_build() {
  echo "Limpando artefatos de builds anteriores..."
  rm -rf "${RAIZ_BUILD}"
  rm -f "${NOME_PACOTE}_${VERSAO_PACOTE}-${REVISAO_PACOTE}_${ARQUITETETURA_PACOTE}.deb"
  echo "Limpeza concluída."
}

# Função para baixar e verificar a fonte
baixar_e_verificar() {
  echo "Baixando ${NOME_ARQUIVO_FONTE}..."
  mkdir -p "${RAIZ_BUILD}/source"
  wget -q --show-progress -O "${RAIZ_BUILD}/source/${NOME_ARQUIVO_FONTE}" "${URL_FONTE}" || {
    echo "Erro: Falha ao baixar o arquivo fonte."
    exit 1
  }

  echo "Verificando soma SHA256..."
  echo "${SOMA_SHA256}  ${RAIZ_BUILD}/source/${NOME_ARQUIVO_FONTE}" | sha256sum --check --status || {
    echo "Erro: Soma SHA256 não corresponde para ${NOME_ARQUIVO_FONTE}."
    exit 1
  }
  echo "Download e verificação bem-sucedidos."
}

# Função para preparar os arquivos da aplicação
preparar_aplicacao() {
  echo "Preparando arquivos da aplicação..."

  # Criar a estrutura de diretórios raiz do pacote
  mkdir -p "${DIRETORIO_PACOTE_TEMP}/usr/share"

  # Extrair o arquivo
  echo "Extraindo arquivo..."
  unzip -q "${RAIZ_BUILD}/source/${NOME_ARQUIVO_FONTE}" -d "${RAIZ_BUILD}/source/" || {
    echo "Erro: Falha ao extrair o arquivo fonte."
    exit 1
  }

  # Mover o conteúdo extraído para sua localização final dentro da estrutura do pacote
  mv "${RAIZ_BUILD}/source/${NOME_DIRETORIO_EXTRAIDO}" "${DIRETORIO_PACOTE_TEMP}/usr/share/${NOME_DIRETORIO_EXTRAIDO}" || {
    echo "Erro: Falha ao mover o diretório extraído."
    exit 1
  }

  DIRETORIO_INSTALACAO_APP="${DIRETORIO_PACOTE_TEMP}/usr/share/${NOME_DIRETORIO_EXTRAIDO}"

  # Remover JRE empacotado
  echo "Removendo JRE empacotado..."
  rm -rf "${DIRETORIO_INSTALACAO_APP}/jre"

  # Remover arquivo README não aplicável
  echo "Removendo LEIA-ME.TXT..."
  rm -f "${DIRETORIO_INSTALACAO_APP}/LEIA-ME.TXT"

  # Remover .gitignore
  echo "Removendo .gitignore..."
  rm -f "${DIRETORIO_INSTALACAO_APP}/.gitignore"

  # Criar o script de inicialização
  echo "Criando script de inicialização..."
  install -Dm755 /dev/null "${DIRETORIO_INSTALACAO_APP}/pjeoffice-pro.sh"
  cat << EOF > "${DIRETORIO_INSTALACAO_APP}/pjeoffice-pro.sh"
#!/bin/bash
# Script de inicialização do PJeOffice
echo "Iniciando o PJeOffice!"
# Define o binário java específico do Zulu 11 para amd64
exec /usr/lib/jvm/zulu-11-amd64/bin/java \\
  -XX:+UseG1GC \\
  -XX:MinHeapFreeRatio=3 \\
  -XX:MaxHeapFreeRatio=3 \\
  -Xms20m \\
  -Xmx2048m \\
  -Dpjeoffice_home="/usr/share/pjeoffice-pro/" \\
  -Dffmpeg_home="/usr/share/pjeoffice-pro/" \\
  -Dpjeoffice_looksandfeels="Metal" \\
  -Dcutplayer4j_looksandfeels="Nimbus" \\
  -jar \\
  /usr/share/pjeoffice-pro/pjeoffice-pro.jar
EOF

  # Extrair o ícone 512x512
  echo "Extraindo ícone..."
  mkdir -p "${DIRETORIO_PACOTE_TEMP}/usr/share/icons/hicolor/512x512/apps"
  unzip -p "${DIRETORIO_INSTALACAO_APP}/pjeoffice-pro.jar" 'images/pje-icon-pje-feather.png' > "${DIRETORIO_PACOTE_TEMP}/usr/share/icons/hicolor/512x512/apps/pjeoffice.png" || {
    echo "Erro: Falha ao extrair ícone."
    exit 1
  }

  # Criar o arquivo .desktop
  echo "Criando arquivo .desktop..."
  mkdir -p "${DIRETORIO_PACOTE_TEMP}/usr/share/applications"
  install -Dm644 /dev/null "${DIRETORIO_INSTALACAO_APP}/pje-office.desktop"
  cat << EOF > "${DIRETORIO_INSTALACAO_APP}/pje-office.desktop"
[Desktop Entry]
Encoding=UTF-8
Name=PJeOffice
GenericName=PJeOffice
Exec=/usr/bin/pjeoffice-pro
Type=Application
Terminal=false
Categories=Office;
Comment=PJeOffice
Icon=pjeoffice
StartupWMClass=br-jus-cnj-pje-office-imp-PjeOfficeApp
EOF

  # Criar links simbólicos
  echo "Criando links simbólicos..."
  mkdir -p "${DIRETORIO_PACOTE_TEMP}/usr/bin"
  ln -s "/usr/share/pjeoffice-pro/pjeoffice-pro.sh" "${DIRETORIO_PACOTE_TEMP}/usr/bin/pjeoffice-pro"

  ln -s "/usr/share/pjeoffice-pro/pje-office.desktop" "${DIRETORIO_PACOTE_TEMP}/usr/share/applications/pje-office.desktop"

  # Tornar ffmpeg.exe executável
  echo "Definindo permissões de execução para ffmpeg.exe..."
  chmod +x "${DIRETORIO_INSTALACAO_APP}/ffmpeg.exe"

  echo "Preparação da aplicação concluída."
}

# Função para criar os arquivos de controle do Debian
criar_controles_debian() {
  echo "Criando arquivos de controle do Debian..."
  mkdir -p "${DIRETORIO_DEBIAN}"

  # Criar arquivo control
  cat << EOF > "${DIRETORIO_DEBIAN}/control"
Package: ${NOME_PACOTE}
Version: ${VERSAO_PACOTE}-${REVISAO_PACOTE}
Architecture: ${ARQUITETURA_PACOTE}
Maintainer: Pedro Henrique Quitete Barreto <pedrohqb@gmail.com>
Description: ${DESCRICAO_PACOTE}
Depends: ${DEPENDENCIAS_PACOTE}
EOF
  chmod 644 "${DIRETORIO_DEBIAN}/control"

  # Criar script postinst (para atualizar o banco de dados de desktop)
  cat << EOF > "${DIRETORIO_DEBIAN}/postinst"
#!/bin/bash
set -e
# Atualiza o banco de dados de arquivos .desktop
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database
fi
# Atualiza os caches de ícones, se aplicável
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -q -t /usr/share/icons/hicolor
fi
exit 0
EOF
  chmod 755 "${DIRETORIO_DEBIAN}/postinst"

  echo "Arquivos de controle do Debian criados."
}

# Função para construir o pacote .deb
construir_pacote_deb() {
  echo "Construindo pacote .deb..."
  dpkg-deb --build "${DIRETORIO_PACOTE_TEMP}" "${NOME_PACOTE}_${VERSAO_PACOTE}-${REVISAO_PACOTE}_${ARQUITETURA_PACOTE}.deb" || {
    echo "Erro: Falha ao construir o pacote .deb."
    exit 1
  }
  echo "Pacote ${NOME_PACOTE}_${VERSAO_PACOTE}-${REVISAO_PACOTE}_${ARQUITETURA_PACOTE}.deb criado com sucesso!"
}

# --- Execução Principal do Script ---
set -e # Sai imediatamente se um comando falhar.

limpar_build
baixar_e_verificar
preparar_aplicacao
criar_controles_debian
construir_pacote_deb

echo "Processo de criação do pacote Debian concluído."
