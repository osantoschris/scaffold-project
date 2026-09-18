# Imagem base Python slim
FROM python:{{PYTHON_DOCKER_TAG}}-slim

# Evita que o Python gere arquivos .pyc e força saída não bufferizada (ótimo para logs em tempo real no Docker)
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

WORKDIR /app

# Instalação das dependências
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Cópia do código-fonte e testes
COPY src/ ./src/
COPY tests/ ./tests/

# Comando de execução padrão
CMD ["python", "src/main.py"]
