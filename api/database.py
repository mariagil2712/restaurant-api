import os
from pymongo import MongoClient
from api.get_parameter import get_mongodb_ip

def get_mongo_uri() -> str:
    # Obtiene la IP de MongoDB desde Parameter Store (AWS)
    # En local si falla SSM, usa la variable de entorno o el default
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