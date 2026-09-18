import os
import sys
from dotenv import load_dotenv

# Carrega variáveis de ambiente do arquivo .env
load_dotenv()


def get_welcome_message() -> str:
    app_name = os.getenv("APP_NAME", "{{PROJECT_NAME}}")
    environment = os.getenv("ENVIRONMENT", "development")
    return f"🚀 {app_name} iniciado com sucesso no ambiente [{environment}]!"


def main() -> None:
    message = get_welcome_message()
    print(message)


if __name__ == "__main__":
    main()
