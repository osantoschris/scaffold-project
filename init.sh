#!/usr/bin/env bash
# ==============================================================================
# Inicializador pos-clone para o Template Repository (Linux & macOS)
# ==============================================================================

set -eo pipefail

CLR_RESET="\033[0m"
CLR_CYAN="\033[1;36m"
CLR_GREEN="\033[1;32m"
CLR_YELLOW="\033[1;33m"
CLR_RED="\033[1;31m"
CLR_GRAY="\033[0;90m"
CLR_BG_BLUE="\033[44;37m"

show_header() {
    clear 2>/dev/null || true
    echo -e "${CLR_CYAN}============================================================${CLR_RESET}"
    echo -e "${CLR_CYAN} [SETUP] INICIALIZANDO REPOSITORIO MODELO                   ${CLR_RESET}"
    echo -e "${CLR_CYAN}============================================================${CLR_RESET}"
    echo ""
}

show_fallback_no_python() {
    echo ""
    echo -e "${CLR_RED}[ERRO] Nenhum interpretador Python valido foi encontrado no sistema!${CLR_RESET}"
    echo ""
    echo -e "${CLR_YELLOW}Para instalar o Python nativamente no seu sistema operacional:${CLR_RESET}"
    echo ""
    
    OS="$(uname -s)"
    if [ "$OS" = "Darwin" ]; then
        echo -e "  macOS (Homebrew): ${CLR_GREEN}brew install python${CLR_RESET}"
    elif [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian|pop|mint)
                echo -e "  Debian/Ubuntu: ${CLR_GREEN}sudo apt update && sudo apt install -y python3 python3-venv${CLR_RESET}"
                ;;
            fedora|rhel|centos)
                echo -e "  Fedora/RHEL: ${CLR_GREEN}sudo dnf install -y python3${CLR_RESET}"
                ;;
            arch|manjaro)
                echo -e "  Arch Linux: ${CLR_GREEN}sudo pacman -S python${CLR_RESET}"
                ;;
            *)
                echo -e "  Linux: Instale o pacote ${CLR_GREEN}python3${CLR_RESET} usando o gerenciador de pacotes."
                ;;
        esac
    fi
    echo ""
    exit 1
}

PROJECT_NAME=""
PYTHON_PATH=""
NO_VENV=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        --python)
            PYTHON_PATH="$2"
            shift 2
            ;;
        --no-venv)
            NO_VENV=1
            shift
            ;;
        *)
            if [ -z "$PROJECT_NAME" ]; then
                PROJECT_NAME="$1"
            fi
            shift
            ;;
    esac
done

show_header

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_NAME="$(basename "$PROJECT_DIR")"

if [ -z "$PROJECT_NAME" ]; then
    echo -ne "${CLR_YELLOW}Digite o nome do novo projeto [$DEFAULT_NAME]: ${CLR_RESET}"
    read -r PROJECT_NAME
    if [ -z "$PROJECT_NAME" ]; then
        PROJECT_NAME="$DEFAULT_NAME"
    fi
fi

PROJECT_SLUG=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9\-_]+/-/g' | sed -E 's/^-+|-+$//g')

detect_pythons() {
    local candidates=()
    for bin_name in python3 python python3.13 python3.12 python3.11 python3.10; do
        while IFS= read -r p; do
            [ -n "$p" ] && candidates+=("$p")
        done < <(which -a "$bin_name" 2>/dev/null || true)
    done

    local seen=()
    VALID_PYTHONS=()
    VALID_VERSIONS=()

    for cand in "${candidates[@]}"; do
        [ -x "$cand" ] || continue
        
        local already_seen=0
        for s in "${seen[@]}"; do
            if [ "$s" = "$cand" ]; then
                already_seen=1
                break
            fi
        done
        [ $already_seen -eq 1 ] && continue
        seen+=("$cand")

        local ver
        if ver=$("$cand" --version 2>&1) && [[ "$ver" =~ Python[[:space:]]+([0-9]+\.[0-9]+(\.[0-9]+)?) ]]; then
            VALID_PYTHONS+=("$cand")
            VALID_VERSIONS+=("$ver")
        fi
    done
}

select_python_tui() {
    local total=${#VALID_PYTHONS[@]}
    if [ "$total" -eq 0 ]; then
        show_fallback_no_python
    fi

    if [ "$total" -eq 1 ]; then
        echo -e "${CLR_GREEN}[OK] Detectado 1 interpretador Python:${CLR_RESET}"
        echo -e "     ${VALID_VERSIONS[0]} -> ${CLR_GRAY}${VALID_PYTHONS[0]}${CLR_RESET}"
        echo ""
        SELECTED_PYTHON="${VALID_PYTHONS[0]}"
        SELECTED_VERSION="${VALID_VERSIONS[0]}"
        return
    fi

    if [ ! -t 0 ]; then
        SELECTED_PYTHON="${VALID_PYTHONS[0]}"
        SELECTED_VERSION="${VALID_VERSIONS[0]}"
        return
    fi

    echo -e "${CLR_YELLOW}Selecione a versao do Python para o projeto:${CLR_RESET}"
    echo -e "${CLR_GRAY}(Navegue com as setas [CIMA / BAIXO] e confirme com [ENTER])${CLR_RESET}"
    echo ""

    local selected=0
    tput civis 2>/dev/null || true

    while true; do
        for i in "${!VALID_PYTHONS[@]}"; do
            if [ "$i" -eq "$selected" ]; then
                printf "${CLR_CYAN} > ${CLR_BG_BLUE}[*] %-15s %s${CLR_RESET}\n" "${VALID_VERSIONS[$i]}" "${VALID_PYTHONS[$i]}"
            else
                printf "   ${CLR_GRAY}[ ] %-15s %s${CLR_RESET}\n" "${VALID_VERSIONS[$i]}" "${VALID_PYTHONS[$i]}"
            fi
        done

        IFS= read -rsn1 key
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 -t 0.1 key2
            if [[ $key2 == "[A" ]]; then
                selected=$(( (selected - 1 + total) % total ))
            elif [[ $key2 == "[B" ]]; then
                selected=$(( (selected + 1) % total ))
            fi
        elif [[ $key == "" ]]; then
            break
        fi

        for ((k=0; k<total; k++)); do
            tput cuu1 2>/dev/null || true
            tput el 2>/dev/null || true
        done
    done

    tput cnorm 2>/dev/null || true
    echo ""
    SELECTED_PYTHON="${VALID_PYTHONS[$selected]}"
    SELECTED_VERSION="${VALID_VERSIONS[$selected]}"
    echo -e "${CLR_GREEN}[OK] Selecionado: ${SELECTED_VERSION}${CLR_RESET}"
    echo -e "     Caminho: ${CLR_GRAY}${SELECTED_PYTHON}${CLR_RESET}"
    echo ""
}

if [ -n "$PYTHON_PATH" ]; then
    SELECTED_PYTHON="$PYTHON_PATH"
    SELECTED_VERSION=$("$PYTHON_PATH" --version 2>&1)
else
    echo -e "${CLR_GRAY}[*] Verificando interpretadores Python instalados...${CLR_RESET}"
    detect_pythons
    select_python_tui
fi

if [[ "$SELECTED_VERSION" =~ Python[[:space:]]+([0-9]+\.[0-9]+) ]]; then
    PYTHON_DOCKER_TAG="${BASH_REMATCH[1]}"
else
    PYTHON_DOCKER_TAG="3.12"
fi

# 1. Substituicao de variaveis
echo -e "${CLR_CYAN}[+] Interpolando arquivos in-place...${CLR_RESET}"

FILES_TO_UPDATE=(
    ".env.example"
    "docker-compose.yml"
    "Dockerfile"
    "docs/CONTEXT.md"
    "docs/ARCHITECTURE.md"
    "docs/TASKS.md"
    "docs/CHANGELOG.md"
    "src/__init__.py"
    "src/main.py"
    "tests/__init__.py"
    "tests/test_main.py"
)

for relPath in "${FILES_TO_UPDATE[@]}"; do
    filePath="$PROJECT_DIR/$relPath"
    if [ -f "$filePath" ]; then
        # Usa sed para substituir mantendo backup temporario
        sed -i.bak \
            -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
            -e "s|{{PROJECT_SLUG}}|$PROJECT_SLUG|g" \
            -e "s|{{PROJECT_DESCRIPTION}}|Projeto inicializado a partir do repositorio modelo.|g" \
            -e "s|{{PYTHON_VERSION}}|$SELECTED_VERSION|g" \
            -e "s|{{PYTHON_DOCKER_TAG}}|$PYTHON_DOCKER_TAG|g" \
            "$filePath"
        rm -f "${filePath}.bak"
        echo -e "  > ${CLR_GREEN}$relPath atualizado.${CLR_RESET}"
    fi
done

# 1.1 Gerar o README.md final da aplicacao
cat <<EOF > "$PROJECT_DIR/README.md"
# $PROJECT_NAME

Projeto inicializado a partir do repositório modelo.

---

## 📁 Estrutura do Projeto
- **\`docs/\`**: Documentação viva contendo Contexto, Arquitetura, Tarefas Ativas e Changelog.
- **\`src/\`**: Código-fonte da aplicação.
- **\`tests/\`**: Testes automatizados.
- **\`AGENTS.md\`**: Diretrizes de atuação para assistentes de inteligência artificial.

---

## 🚀 Como Executar

### 1. Pré-requisitos
- Python $SELECTED_VERSION (ou Docker & Docker Compose)
- Git

### 2. Configuração do Ambiente Local
Ative o ambiente virtual:
- **Windows (PowerShell):**
  \`\`\`powershell
  .\\.venv\Scripts\Activate.ps1
  \`\`\`
- **Linux / macOS:**
  \`\`\`bash
  source .venv/bin/activate
  \`\`\`

Instale as dependências:
\`\`\`bash
pip install -r requirements.txt
\`\`\`

Execute a aplicação:
\`\`\`bash
python src/main.py
\`\`\`

---

## 🐳 Execução via Docker
Para construir a imagem e subir a aplicação via contêineres:
\`\`\`bash
docker compose up --build
\`\`\`

---

## 🤖 Trabalhando com Assistentes de IA
Este projeto segue um fluxo padronizado de trabalho com agentes de IA. Antes de iniciar qualquer tarefa com IA, consulte o arquivo \`AGENTS.md\`.
EOF
echo -e "  > ${CLR_GREEN}README.md da aplicacao gerado.${CLR_RESET}"


# 2. Criar .env
if [ -f "$PROJECT_DIR/.env.example" ] && [ ! -f "$PROJECT_DIR/.env" ]; then
    cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/.env"
    echo -e "${CLR_GREEN}[OK] Arquivo .env gerado.${CLR_RESET}"
fi

# 3. Criar .venv e instalar dependencias
if [ "$NO_VENV" -eq 0 ]; then
    echo ""
    echo -e "${CLR_CYAN}[*] Criando ambiente virtual (.venv) com $SELECTED_VERSION...${CLR_RESET}"
    if "$SELECTED_PYTHON" -m venv "$PROJECT_DIR/.venv"; then
        echo -e "${CLR_GREEN}[OK] Ambiente virtual criado.${CLR_RESET}"
        
        if [ -f "$PROJECT_DIR/requirements.txt" ]; then
            echo -e "${CLR_CYAN}[*] Instalando pacotes do requirements.txt...${CLR_RESET}"
            VENV_PIP="$PROJECT_DIR/.venv/bin/pip"
            if [ -x "$VENV_PIP" ]; then
                "$VENV_PIP" install -r "$PROJECT_DIR/requirements.txt" >/dev/null
                echo -e "${CLR_GREEN}[OK] Dependencias instaladas com sucesso.${CLR_RESET}"
            fi
        fi
    else
        echo -e "${CLR_YELLOW}[!] Falha ao configurar o .venv.${CLR_RESET}"
    fi
fi

# 4. Limpeza dos scripts de instalacao
echo ""
echo -e "${CLR_CYAN}[*] Limpando arquivos de instalacao...${CLR_RESET}"
FILES_TO_REMOVE=("init.ps1" "init.sh" "TARGET.md" "scaffold_generator_plan.md" "template_repo_plan.md")
for f in "${FILES_TO_REMOVE[@]}"; do
    if [ -f "$PROJECT_DIR/$f" ]; then
        rm -f "$PROJECT_DIR/$f"
        echo -e "  > ${CLR_GRAY}Removido $f${CLR_RESET}"
    fi
done

echo ""
echo -e "${CLR_GREEN}============================================================${CLR_RESET}"
echo -e "${CLR_GREEN} [SUCESSO] REPOSITORIO '$PROJECT_NAME' CONFIGURADO E PRONTO!${CLR_RESET}"
echo -e "${CLR_GREEN}============================================================${CLR_RESET}"
echo ""
echo -e "${CLR_YELLOW}Proximos passos:${CLR_RESET}"
echo -e "  1. Ative o ambiente virtual: ${CLR_CYAN}source .venv/bin/activate${CLR_RESET}"
echo -e "  2. Execute a aplicacao:      ${CLR_CYAN}python src/main.py${CLR_RESET}"
echo -e "  3. Consulte as tarefas:      ${CLR_CYAN}docs/TASKS.md${CLR_RESET}"
echo ""

# Deleta a si proprio
rm -f "$0" 2>/dev/null || true
