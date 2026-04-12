FROM python:3.11-slim
# Imagen base ligera (Python 3.11).

WORKDIR /code

# Copia el código del contexto de build (directorio donde está el Dockerfile).
COPY . .

RUN pip install --no-cache-dir -r requirements.txt

# Puerto de la aplicación (debe coincidir con el target group del ALB :8000 y con docker-compose).
EXPOSE 8000

# Escucha en todas las interfaces para que el ALB y docker-compose puedan enrutar al contenedor.
CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000"]
