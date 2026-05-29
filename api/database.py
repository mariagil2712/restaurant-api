from pymongo import MongoClient
from api.get_parameter import get_mongo_uri

MONGO_URI = get_mongo_uri()
client = MongoClient(MONGO_URI)
db = client.tarea1_db

dishes_collection = db["dishes"]
tasks_collection = db["tasks"]


def get_dishes_collection():
    return dishes_collection


def get_tasks_collection():
    return tasks_collection
