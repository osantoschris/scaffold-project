# Diretrizes de Comportamento para Assistentes de IA (AGENTS.md)

Este documento estabelece o contrato universal e mandatório de atuação para qualquer assistente ou agente de IA (como agy.cli, Cursor, Windsurf, Claude Code, Aider, GitHub Copilot, etc.) operando neste repositório.

---

## 1. Princípios e Postura
1. **Compreensão Antes da Ação:** Nunca inicie alterações de código sem antes ler o contexto e a arquitetura do projeto.
2. **Foco e Minimalismo:** Trabalhe apenas no escopo estrito solicitado ou definido na tarefa corrente. Não refatore código não relacionado nem crie arquivos desnecessários.
3. **Preservação de Contexto:** Mantenha a documentação viva e sincronizada conforme as regras abaixo.

---

## 2. Fluxo Obrigatório de Trabalho

Toda interação que envolva desenvolvimento, correção de bugs ou refatoração deve seguir rigorosamente os passos a seguir:

```
┌─────────────────────────┐
│ 1. Leitura de Contexto  │ -> docs/CONTEXT.md & docs/ARCHITECTURE.md
└────────────┬────────────┘
             │
┌────────────▼────────────┐
│ 2. Foco na Demanda      │ -> docs/TASKS.md (consultar a tarefa ativa)
└────────────┬────────────┘
             │
┌────────────▼────────────┐
│ 3. Implementação/Testes │ -> src/ e tests/ (código limpo e testável)
└────────────┬────────────┘
             │
┌────────────▼────────────┐
│ 4. Registro & Limpeza   │ -> docs/CHANGELOG.md (registrar entrega)
│                         │ -> docs/TASKS.md (remover tarefa concluída)
└─────────────────────────┘
```

1. **Passo 1 (Contexto):** Leia [docs/CONTEXT.md](file:///docs/CONTEXT.md) para compreender as regras de negócio e [docs/ARCHITECTURE.md](file:///docs/ARCHITECTURE.md) para alinhar a stack e decisões técnicas.
2. **Passo 2 (Foco):** Consulte [docs/TASKS.md](file:///docs/TASKS.md) para identificar o backlog ativo. Execute apenas a tarefa em questão.
3. **Passo 3 (Qualidade):** Garanta que todo novo código tenha testes correspondentes em `tests/` e respeite as convenções do projeto.
4. **Passo 4 (Atualização da Memória do Projeto):**
   - Ao concluir uma entrega, registre os detalhes em [docs/CHANGELOG.md](file:///docs/CHANGELOG.md).
   - Remova ou marque a tarefa finalizada em [docs/TASKS.md](file:///docs/TASKS.md) (para evitar poluir a janela de contexto de futuras sessões).

---

## 3. Restrições e Segurança
- **Segredos e Credenciais:** Jamais versione valores reais em arquivos de código ou documentação. Utilize sempre `.env` (que deve permanecer no `.gitignore`).
- **Arquivos de Configuração de Ferramentas:** Arquivos específicos de IDEs ou IAs (`.cursor/`, `.agy/`, `.windsurf/`) devem permanecer estritamente no `.gitignore` e apontar para este arquivo (`AGENTS.md`).
- **GitOps:** Respeite o fluxo de deploy: ambiente local -> GitHub (SSOT) -> Home Server via Docker Compose.
