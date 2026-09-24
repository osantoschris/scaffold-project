<#
.SYNOPSIS
    Inicializador automatizado pos-clone para o Template Repository.
.DESCRIPTION
    Configura o repositorio clonado in-place, substituindo as tags,
    criando o ambiente virtual (.venv), instalando dependencias e
    limpando os proprios scripts de instalacao.
.PARAMETER Name
    Nome do projeto. Se omitido, sera solicitado interativamente no terminal.
.PARAMETER PythonPath
    Caminho absoluto ou binario especifico do Python a ser usado.
.PARAMETER NoVenv
    Se especificado, ignora a criacao automatica do ambiente virtual (.venv).
#>

[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [string]$Name,

    [Parameter()]
    [string]$PythonPath,

    [switch]$NoVenv
)

$ErrorActionPreference = "Stop"

function Write-Header {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " [SETUP] INICIALIZANDO REPOSITORIO MODELO                   " -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Fallback-NoPython {
    Write-Host ""
    Write-Host "[ERRO] Nenhum interpretador Python valido foi encontrado no sistema!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Para instalar o Python nativamente no Windows, execute no terminal:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   winget install Python.Python.3.12" -ForegroundColor Green
    Write-Host ""
    Write-Host "Apos a instalacao, reabra o terminal e execute este script novamente." -ForegroundColor Gray
    Write-Host ""
    exit 1
}

function Find-PythonInstallations {
    $candidates = [System.Collections.Generic.List[string]]::new()

    if (Get-Command py -ErrorAction SilentlyContinue) {
        try {
            $pyLines = py -0p 2>$null
            foreach ($line in $pyLines) {
                if ($line -match '([A-Za-z]:\\[^ ]+python\.exe)') {
                    $candidates.Add($matches[1].Trim())
                }
            }
        } catch {}
    }

    try {
        $wherePaths = where.exe python 2>$null
        if ($wherePaths) {
            foreach ($p in $wherePaths) {
                if ($p -and (Test-Path $p)) {
                    $candidates.Add($p.Trim())
                }
            }
        }
    } catch {}

    $regHives = @("HKCU:\Software\Python\PythonCore", "HKLM:\Software\Python\PythonCore")
    foreach ($hive in $regHives) {
        if (Test-Path $hive) {
            try {
                $versions = Get-ChildItem -Path $hive -ErrorAction SilentlyContinue
                foreach ($ver in $versions) {
                    $installPathKey = Join-Path $ver.PSPath "InstallPath"
                    if (Test-Path $installPathKey) {
                        $item = Get-ItemProperty -Path $installPathKey -ErrorAction SilentlyContinue
                        if ($item -and $item.PSObject.Properties['(default)']) {
                            $baseDir = $item.PSObject.Properties['(default)'].Value
                            if ($baseDir) {
                                $exePath = Join-Path $baseDir "python.exe"
                                if (Test-Path $exePath) {
                                    $candidates.Add($exePath)
                                }
                            }
                        }
                    }
                }
            } catch {}
        }
    }

    $validPythons = [System.Collections.Generic.List[PSCustomObject]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($cand in $candidates) {
        if ([string]::IsNullOrWhiteSpace($cand)) { continue }
        $resolved = [System.IO.Path]::GetFullPath($cand)
        if (-not (Test-Path $resolved)) { continue }
        if ($seen.Contains($resolved)) { continue }

        try {
            $procInfo = New-Object System.Diagnostics.ProcessStartInfo
            $procInfo.FileName = $resolved
            $procInfo.Arguments = "--version"
            $procInfo.RedirectStandardOutput = $true
            $procInfo.RedirectStandardError = $true
            $procInfo.UseShellExecute = $false
            $procInfo.CreateNoWindow = $true

            $proc = [System.Diagnostics.Process]::Start($procInfo)
            $stdout = $proc.StandardOutput.ReadToEnd()
            $stderr = $proc.StandardError.ReadToEnd()
            [void]$proc.WaitForExit(3000)

            if ($proc.ExitCode -eq 0) {
                $verOutput = ($stdout + $stderr).Trim()
                if ($verOutput -match "Python\s+([0-9]+\.[0-9]+(\.[0-9]+)?)") {
                    [void]$seen.Add($resolved)
                    $validPythons.Add([PSCustomObject]@{
                        Path = $resolved
                        Version = $verOutput
                        ShortVersion = $matches[1]
                    })
                }
            }
        } catch {}
    }

    return $validPythons
}

function Select-PythonTUI ($pythonList) {
    if ($pythonList.Count -eq 0) {
        Show-Fallback-NoPython
    }

    if ($pythonList.Count -eq 1) {
        Write-Host "[OK] Detectado 1 interpretador Python:" -ForegroundColor Green
        Write-Host "     $($pythonList[0].Version) -> $($pythonList[0].Path)" -ForegroundColor Gray
        Write-Host ""
        return $pythonList[0]
    }

    if ([Console]::IsInputRedirected -or [Console]::IsOutputRedirected) {
        return $pythonList[0]
    }

    $selectedIndex = 0
    $total = $pythonList.Count

    Write-Host "Selecione a versao do Python para o projeto:" -ForegroundColor Yellow
    Write-Host "(Navegue com as setas [CIMA / BAIXO] e confirme com [ENTER])" -ForegroundColor DarkGray
    Write-Host ""

    $origTop = [Console]::CursorTop
    [Console]::CursorVisible = $false

    try {
        while ($true) {
            [Console]::SetCursorPosition(0, $origTop)

            for ($i = 0; $i -lt $total; $i++) {
                $item = $pythonList[$i]
                if ($i -eq $selectedIndex) {
                    Write-Host " > " -NoNewline -ForegroundColor Cyan
                    Write-Host "[*] $($item.Version.PadRight(15))" -NoNewline -ForegroundColor White -BackgroundColor DarkBlue
                    Write-Host " $($item.Path)" -ForegroundColor Cyan -BackgroundColor DarkBlue
                } else {
                    Write-Host "   " -NoNewline
                    Write-Host "[ ] $($item.Version.PadRight(15))" -NoNewline -ForegroundColor Gray
                    Write-Host " $($item.Path)" -ForegroundColor DarkGray
                }
            }

            $key = [Console]::ReadKey($true)
            if ($key.Key -eq [ConsoleKey]::UpArrow) {
                $selectedIndex--
                if ($selectedIndex -lt 0) { $selectedIndex = $total - 1 }
            }
            elseif ($key.Key -eq [ConsoleKey]::DownArrow) {
                $selectedIndex++
                if ($selectedIndex -ge $total) { $selectedIndex = 0 }
            }
            elseif ($key.Key -eq [ConsoleKey]::Enter) {
                break
            }
        }
    } finally {
        [Console]::CursorVisible = $true
        [Console]::SetCursorPosition(0, $origTop + $total)
        Write-Host ""
    }

    $selected = $pythonList[$selectedIndex]
    Write-Host "[OK] Selecionado: $($selected.Version)" -ForegroundColor Green
    Write-Host "     Caminho: $($selected.Path)" -ForegroundColor DarkGray
    Write-Host ""
    return $selected
}

# ==============================================================================
# INICIO DO FLUXO PRINCIPAL
# ==============================================================================

Write-Header

$projectDir = $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($Name)) {
    # Tenta usar o nome da pasta atual como default
    $defaultName = [System.IO.Path]::GetFileName($projectDir)
    Write-Host "Digite o nome do novo projeto [$defaultName]: " -NoNewline -ForegroundColor Yellow
    $Name = Read-Host
    if ([string]::IsNullOrWhiteSpace($Name)) {
        $Name = $defaultName
    }
}

$slug = ($Name.Trim().ToLower() -replace '[^a-z0-9\-_]', '-').Trim('-')

$selectedPythonObj = $null
if (-not [string]::IsNullOrWhiteSpace($PythonPath)) {
    if (-not (Test-Path $PythonPath)) {
        Write-Host "[ERRO] O caminho especificado para o Python nao existe: $PythonPath" -ForegroundColor Red
        exit 1
    }
    $ver = & $PythonPath --version 2>&1
    $selectedPythonObj = [PSCustomObject]@{
        Path = [System.IO.Path]::GetFullPath($PythonPath)
        Version = $ver.ToString().Trim()
        ShortVersion = if ($ver -match "Python\s+([0-9]+\.[0-9]+)") { $matches[1] } else { "3.12" }
    }
} else {
    Write-Host "[*] Verificando interpretadores Python instalados..." -ForegroundColor Gray
    $pythons = Find-PythonInstallations
    $selectedPythonObj = Select-PythonTUI -pythonList $pythons
}

$pythonVersion = $selectedPythonObj.ShortVersion
$majorMinor = if ($pythonVersion -match '^[0-9]+\.[0-9]+') { $matches[0] } else { "3.12" }

# Atualizar arquivos
Write-Host "[+] Interpolando templates in-place..." -ForegroundColor Cyan

$filesToUpdate = @(
    ".env.example",
    "docker-compose.yml",
    "Dockerfile",
    "docs\CONTEXT.md",
    "docs\ARCHITECTURE.md",
    "docs\TASKS.md",
    "docs\CHANGELOG.md",
    "src\__init__.py",
    "src\main.py",
    "tests\__init__.py",
    "tests\test_main.py"
)

foreach ($relPath in $filesToUpdate) {
    $filePath = Join-Path $projectDir $relPath
    if (Test-Path $filePath) {
        $content = Get-Content -Path $filePath -Raw -Encoding UTF8
        $content = $content.Replace("{{PROJECT_NAME}}", $Name)
        $content = $content.Replace("{{PROJECT_SLUG}}", $slug)
        $content = $content.Replace("{{PROJECT_DESCRIPTION}}", "Projeto inicializado a partir do repositório modelo.")
        $content = $content.Replace("{{PYTHON_VERSION}}", $selectedPythonObj.Version)
        $content = $content.Replace("{{PYTHON_DOCKER_TAG}}", $majorMinor)
        [System.IO.File]::WriteAllText($filePath, $content, [System.Text.Encoding]::UTF8)
        Write-Host "  > $relPath atualizado." -ForegroundColor DarkGreen
    }
}

# 1.1 Gerar o novo README.md final da aplicacao
$appReadmePath = Join-Path $projectDir "README.md"
$appReadmeContent = @"
# $Name

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
- Python $($selectedPythonObj.Version) (ou Docker & Docker Compose)
- Git

### 2. Configuração do Ambiente Local
Ative o ambiente virtual:
- **Windows (PowerShell):**
  \`\`\`powershell
  .\.venv\Scripts\Activate.ps1
  \`\`\`
  *(Caso o PowerShell restrinja scripts, execute: \`.\.venv\Scripts\activate.bat\`)*
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
"@
[System.IO.File]::WriteAllText($appReadmePath, $appReadmeContent, [System.Text.Encoding]::UTF8)
Write-Host "  > README.md da aplicacao gerado." -ForegroundColor DarkGreen


# Criar .env
$envPath = Join-Path $projectDir ".env"
$envExamplePath = Join-Path $projectDir ".env.example"
if ((Test-Path $envExamplePath) -and (-not (Test-Path $envPath))) {
    Copy-Item -Path $envExamplePath -Destination $envPath
    Write-Host "[OK] Arquivo .env gerado." -ForegroundColor Green
}

# Criar venv e instalar dependencias
if (-not $NoVenv) {
    Write-Host ""
    Write-Host "[*] Criando ambiente virtual (.venv)..." -ForegroundColor Cyan
    $venvPath = Join-Path $projectDir ".venv"
    try {
        & $selectedPythonObj.Path -m venv $venvPath
        Write-Host "[OK] Ambiente virtual criado." -ForegroundColor Green

        # Instalar dependencias
        $reqPath = Join-Path $projectDir "requirements.txt"
        if (Test-Path $reqPath) {
            Write-Host "[*] Instalando pacotes do requirements.txt..." -ForegroundColor Cyan
            $pipPath = Join-Path $venvPath "Scripts\pip.exe"
            if (Test-Path $pipPath) {
                & $pipPath install -r $reqPath | Out-Null
                Write-Host "[OK] Dependencias instaladas com sucesso." -ForegroundColor Green
            }
        }

    } catch {
        Write-Host "[!] Falha ao configurar o ambiente virtual: $_" -ForegroundColor Yellow
    }
}

# Limpeza dos scripts de inicializacao
Write-Host ""
Write-Host "[*] Limpando arquivos de instalacao..." -ForegroundColor Cyan
$filesToRemove = @("init.bat", "init.ps1", "init.sh", "TARGET.md", "scaffold_generator_plan.md", "template_repo_plan.md")
foreach ($f in $filesToRemove) {
    $fPath = Join-Path $projectDir $f
    if (Test-Path $fPath) {
        Remove-Item -Path $fPath -Force
        Write-Host "  > Removido $f" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " [SUCESSO] REPOSITORIO '$Name' CONFIGURADO E PRONTO!        " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Proximos passos:" -ForegroundColor Yellow
Write-Host "  1. Ative o ambiente virtual: .\.venv\Scripts\Activate.ps1" -ForegroundColor White
Write-Host "  2. Execute a aplicacao:      python src\main.py" -ForegroundColor White
Write-Host "  3. Consulte as tarefas:      docs\TASKS.md" -ForegroundColor White
Write-Host ""
