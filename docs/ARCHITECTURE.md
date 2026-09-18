# {{PROJECT_NAME}} - Arquitetura Técnica

## 1. Stack Tecnológica
- **Linguagem Principal:** Python {{PYTHON_VERSION}}
- **Containerização:** Docker & Docker Compose
- **Testes:** pytest / unittest

## 2. Estrutura de Diretórios
```
{{PROJECT_SLUG}}/
├── docs/             # Documentação viva (Contexto, Arquitetura, Tarefas e Changelog)
├── src/              # Código-fonte da aplicação
├── tests/            # Testes automatizados
├── AGENTS.md         # Contrato universal de diretrizes para IAs
├── docker-compose.yml# Orquestração local de contêineres
├── Dockerfile        # Imagem Docker da aplicação
├── .env.example      # Variáveis de ambiente de exemplo
├── .gitignore        # Padrões de arquivos ignorados
└── README.md         # Ponto de entrada do repositório
```

## 3. Orquestração Docker
- **Serviço principal:** `app`
- **Portas expostas:** `8000:8000` (ajustável conforme necessidade)
- **Volumes montados:**
  - `./src:/app/src` (live reload no ambiente local)
- **Ambiente (`.env`):** Carregado automaticamente via `env_file: .env`.

## 4. Fluxo de Trabalho e GitOps Simplificado
1. **Desenvolvimento Local:**
   - Feito no ambiente local (utilizando SSD para performance de indexação e VSCode/Cursor).
   - Execução e testes locais via terminal ou Docker:
     ```bash
     docker compose up --build
     ```
2. **Repositório Central (GitHub):**
   - Fonte única da verdade (*Single Source of Truth*).
   - Commits claros seguindo *Conventional Commits* (`feat:`, `fix:`, `docs:`).
3. **Deploy em Produção (Home Server):**
   - O servidor obtém a versão validada e sobe os contêineres:
     ```bash
     git pull origin main
     docker compose up -d --build
     ```
