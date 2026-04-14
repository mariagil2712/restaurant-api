import os

import boto3
from botocore.exceptions import BotoCoreError, ClientError

def get_ssm_parameter(name: str, default: str = None) -> str:
    """
    Consulta un parámetro del Parameter Store de AWS.
    Si no existe, retorna el valor default.
    """
    client = boto3.client("ssm", region_name="us-east-1")
    try:
        response = client.get_parameter(Name=name)
        return response["Parameter"]["Value"]
    except ClientError as e:
        if e.response["Error"]["Code"] == "ParameterNotFound":
            print(f"[WARN] Parámetro '{name}' no encontrado. Usando valor por defecto: '{default}'")
            return default
        print(f"[WARN] Error leyendo '{name}' en SSM ({e}). Usando valor por defecto: '{default}'")
        return default
    except (BotoCoreError, Exception) as e:
        # Evita tumbar la app cuando no hay credenciales IAM o hay fallas temporales de red.
        print(f"[WARN] No fue posible consultar SSM para '{name}' ({e}). Usando valor por defecto: '{default}'")
        return default


def get_rabbitmq_ip() -> str:
    # Lee la IP pública del servidor RabbitMQ desde Parameter Store
    # La ruta coincide con el aws_ssm_parameter definido en main.tf
    env_host = os.getenv("RABBITMQ_HOST")
    if env_host:
        return env_host
    return get_ssm_parameter(
        name="/message-queue/dev/restaurant-api/rabbitmq/public_ip",
        default="localhost"
    )


def get_mongodb_ip() -> str:
    # Lee la IP pública del servidor MongoDB desde Parameter Store
    # La ruta coincide con el aws_ssm_parameter definido en main.tf
    env_uri = os.getenv("MONGO_URI")
    if env_uri:
        return "localhost"
    return get_ssm_parameter(
        name="/message-queue/dev/restaurant-api/mongodb/public_ip",
        default="localhost"
    )