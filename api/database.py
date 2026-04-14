import os
from pymongo import MongoClient
from api.get_parameter import get_mongodb_ip

def get_mongo_uri() -> str:
    # Prioriza MONGO_URI si llega por entorno (por ejemplo desde user_data + docker run).
    env_mongo_uri = os.getenv("MONGO_URI")
    if env_mongo_uri:
        return env_mongo_uri

    # Si no existe variable de entorno, intenta resolver vía SSM y luego fallback local.
    mongo_ip = get_mongodb_ip()
    if mongo_ip == "localhost":
        return os.getenv("MONGO_URI", "mongodb://admin:admin123@localhost:27017/")
    return f"mongodb://admin:password123@{mongo_ip}:27017/?authSource=admin"

MONGO_URI = get_mongo_uri()
client = MongoClient(MONGO_URI)
# Seleccionar la base de datos
db = client.tarea1_db

# Colecciones para la API de platos y tasks
dishes_collection = db["dishes"]
tasks_collection = db["tasks"]

def get_dishes_collection():
    return dishes_collection

def get_tasks_collection():
    return tasks_collection