import os

import boto3
from botocore.exceptions import BotoCoreError, ClientError

SSM_PREFIX = os.getenv(
    "SSM_PARAMETER_PREFIX", "/message-queue/dev/restaurant-api"
)

DEFAULT_LOCAL_MONGO_URI = "mongodb://admin:admin123@localhost:27017/"


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
        print(f"[WARN] No fue posible consultar SSM para '{name}' ({e}). Usando valor por defecto: '{default}'")
        return default


def get_mongo_uri() -> str:
    """
    Endpoint de MongoDB como URL completa (MONGO_URI).

    Prioridad: env MONGO_URI > SSM connection_uri > IP privada SSM > IP pública SSM > local.
    """
    env_uri = os.getenv("MONGO_URI")
    if env_uri:
        return env_uri

    ssm_uri = get_ssm_parameter(
        name=f"{SSM_PREFIX}/mongodb/connection_uri",
        default=None,
    )
    if ssm_uri:
        return ssm_uri

    private_ip = get_ssm_parameter(
        name=f"{SSM_PREFIX}/mongodb/private_ip",
        default=None,
    )
    if private_ip and private_ip != "localhost":
        return _build_mongo_uri(private_ip)

    public_ip = get_ssm_parameter(
        name=f"{SSM_PREFIX}/mongodb/public_ip",
        default="localhost",
    )
    if public_ip and public_ip != "localhost":
        return _build_mongo_uri(public_ip)

    return os.getenv("MONGO_URI", DEFAULT_LOCAL_MONGO_URI)


def _build_mongo_uri(host: str) -> str:
    user = os.getenv("MONGO_USER", "admin")
    password = os.getenv("MONGO_PASSWORD", "password123")
    port = os.getenv("MONGO_PORT", "27017")
    auth_source = os.getenv("MONGO_AUTH_SOURCE", "admin")
    return f"mongodb://{user}:{password}@{host}:{port}/?authSource={auth_source}"


def get_rabbitmq_ip() -> str:
    env_host = os.getenv("RABBITMQ_HOST")
    if env_host:
        return env_host
    private = get_ssm_parameter(
        name=f"{SSM_PREFIX}/rabbitmq/private_ip",
        default=None,
    )
    if private and private != "localhost":
        return private
    return get_ssm_parameter(
        name=f"{SSM_PREFIX}/rabbitmq/public_ip",
        default="localhost",
    )


def get_mongodb_ip() -> str:
    """Compatibilidad: host extraído de MONGO_URI si está en entorno."""
    env_uri = os.getenv("MONGO_URI")
    if env_uri:
        return "localhost"
    uri = get_mongo_uri()
    if "@" in uri and "://" in uri:
        host_part = uri.split("@", 1)[1]
        return host_part.split("/")[0].split(":")[0]
    return "localhost"
