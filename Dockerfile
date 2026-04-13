FROM python:3.11-slim
# Imagen base de Python 3.11 versión ligera

WORKDIR /code
# Directorio de trabajo dentro del contenedor

COPY requirements.txt .
# Copia solo requirements primero para aprovechar caché de Docker

RUN pip install -r requirements.txt
# Instala todas las dependencias incluyendo boto3

COPY . .
# Copia el resto del código

CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000"]
# Arranca la API con uvicorn en el puerto 8000, accesible desde fuera del contenedor
