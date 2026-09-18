# 1. O Objetivo do Gerador
Criar um comando automatizado para inicializar qualquer novo projeto com uma estrutura padronizada contendo:

Código-fonte.
Orquestração local via Docker.
Documentação viva em Markdown.
Diretrizes claras para assistentes e agentes de IA (como agy.cli, Cursor, Windsurf, Claude Code e Aider).

# 2. A Estrutura de Pastas e Papel de Cada Arquivo
Ficou acordada a seguinte árvore padrão para os novos repositórios:
```
[nome-do-projeto]/
├── docs/
│   ├── CONTEXT.md        # O que é o projeto, visão de negócio, personas e regras críticas
│   ├── ARCHITECTURE.md   # Stack tecnológica, portas Docker, volumes e fluxo de deploy
│   ├── TASKS.md          # Backlog ativo, tarefas imediatas e status atual
│   └── CHANGELOG.md      # Histórico cronológico de entregas e versões passadas
├── src/                  # Código-fonte da aplicação
├── tests/                # Testes automatizados
├── AGENTS.md             # Contrato de comportamento universal para qualquer IA
├── docker-compose.yml    # Orquestração local de contêineres
├── Dockerfile            # Construção da imagem da aplicação
├── .env.example          # Modelo de variáveis de ambiente sem credenciais reais
├── .gitignore            # Ignora .env, caches locais e diretórios de IAs (.agy/, .cursor/)
└── README.md             # Ponto de entrada do repositório
```

# 3. Decisões Arquiteturiais Alinhadas
Separação entre Tarefas e Histórico:

TASKS.md cuida exclusivamente do presente/futuro (itens pendentes e em progresso).

CHANGELOG.md cuida exclusivamente do passado.

Motivo: Evitar inchar a janela de contexto das IAs a cada leitura e prevenir conflitos no Git.

Regras Agnósticas para IAs (AGENTS.md):

Mantido na raiz do projeto em formato neutro.

Define o fluxo obrigatório da IA: ler CONTEXT.md e ARCHITECTURE.md antes de implementar, focar apenas na tarefa de TASKS.md e atualizar o CHANGELOG.md ao concluir entregas.

Ferramentas específicas (.agy/, .cursor/, etc.) apenas apontam para ele e ficam no .gitignore.

Fluxo de Trabalho Local vs. Servidor (GitOps simplificado):

Desenvolvimento e testes: No notebook local (usando o SSD para velocidade máxima de indexação da IA e VSCode).

Repositório Central: GitHub como fonte única da verdade (Single Source of Truth).

Produção (Home Server): O servidor apenas puxa a versão validada via git pull e sobe com docker compose up -d.

Universalidade entre Sistemas Operacionais (Windows, Linux e macOS):

Como não existe um formato de script único executado nativamente por padrão em todos os SOs sem pré-requisitos, a estratégia alinhada foi criar um repositório dedicado do scaffold com scripts nativos em cada família:

init.sh para Linux e macOS (POSIX / Bash / Zsh).

init.ps1 para Windows (PowerShell nativo).

Varredura Dinâmica de Python: Ambos os scripts fazem a busca pelos binários instalados na máquina e abrem um menu TUI interativo com as setas do teclado (↑/↓) e ENTER para selecionar a versão desejada.

Fallback amigável: Caso o computador não possua nenhum interpretador Python instalado, o script não trava com erro genérico; ele exibe na tela o comando exato para instalação direta pelo terminal nativo daquele SO (ex: winget no Windows, apt/dnf/pacman no Linux, brew/xcode-select no macOS).