import boto3
from botocore.exceptions import ClientError

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
        raise # Re-lanza errores inesperados (permisos, red, etc.)


def get_rabbitmq_ip() -> str:
    # Lee la IP pública del servidor RabbitMQ desde Parameter Store
    # La ruta coincide con el aws_ssm_parameter definido en main.tf
    return get_ssm_parameter(
        name="/message-queue/dev/restaurant-api/rabbitmq/public_ip",
        default="localhost"
    )


def get_mongodb_ip() -> str:
    # Lee la IP pública del servidor MongoDB desde Parameter Store
    # La ruta coincide con el aws_ssm_parameter definido en main.tf
    return get_ssm_parameter(
        name="/message-queue/dev/restaurant-api/mongodb/public_ip",
        default="localhost"
    )