# 🚀 Python Scaffold Template

Bem-vindo ao repositório modelo (Template Repository) padronizado!
Este template serve como fundação ágil e robusta para qualquer novo projeto, trazendo já configurados:
- **Ambiente Python Isolado:** Criação automática de `.venv` e dependências.
- **Docker e Orquestração Local:** `Dockerfile` e `docker-compose.yml` otimizados.
- **Documentação Viva:** Estrutura em `docs/` para contexto, arquitetura, backlog ativo e histórico.
- **Padrão Universal para Agentes de IA:** Diretrizes em `AGENTS.md` e pontes prontas (como `.cursorrules`) protegidas via `.gitignore`.

---

## 🛠️ Como usar este Template

1. **Crie seu projeto:** Clique no botão verde **"Use this template"** no topo desta página do GitHub e crie seu novo repositório.
2. **Clone:** Faça o `git clone` do seu repositório recém-criado para sua máquina local.
3. **Inicialize:** Abra o terminal dentro da pasta do projeto clonado e execute o script de inicialização correspondente ao seu Sistema Operacional:

### No Windows (PowerShell)
```powershell
.\init.ps1
```

### No Linux & macOS (Bash/Zsh)
```bash
chmod +x ./init.sh
./init.sh
```

### O que o script fará por você?
- Solicitará o nome do projeto (caso não tenha passado por parâmetro).
- Abrirá um menu interativo elegante para que você selecione qual versão do Python da sua máquina deseja utilizar.
- Renomeará automaticamente os placeholders nos arquivos do repositório para o nome escolhido e a versão do Python selecionada.
- Criará automaticamente um ambiente virtual (`.venv`) usando o Python escolhido.
- Instalará os pacotes listados em `requirements.txt`.
- Criará o arquivo `.env` seguro.
- **Limpeza (Auto-Destruição):** Por fim, ele apagará a si mesmo (`init.ps1`, `init.sh` e afins), deixando o seu repositório perfeitamente limpo, funcional e pronto para codar!
