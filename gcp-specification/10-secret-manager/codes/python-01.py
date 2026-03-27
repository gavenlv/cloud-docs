# Cloud Functions中使用Secret Manager的示例代码

import os


def main(request):
    db_password = os.environ.get('DB_PASSWORD')
    api_key = os.environ.get('API_KEY')

    if not db_password or not api_key:
        return "Error: Secrets not found", 500

    return {
        "status": "success",
        "secrets_loaded": {
            "db_password": bool(db_password),
            "api_key": bool(api_key)
        }
    }
