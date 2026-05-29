# Despliegue AWS — qué subir y qué ejecutar

## ¿Hace falta `git push`?

**Sí, para el código Python** (`api/*.py`). Las instancias API y Worker hacen:

```bash
git clone --depth 1 "${git_repo_url}" restaurant-api
```

Por defecto `git_repo_url` apunta a `https://github.com/mariagil2712/restaurant-api.git`.
Si no haces **push**, las EC2 siguen con el código viejo de GitHub.

Los archivos **`.tpl` / `.sh`** no se clonan solos: Terraform los usa en **user_data**
solo cuando la instancia **arranca por primera vez** (o se recrea).

| Cambio | Push a GitHub | terraform apply | Recrear EC2 / SSH |
|--------|---------------|-----------------|-------------------|
| `api/*.py` | **Sí** | No basta | Rebuild docker o `git pull` en EC2 |
| `install_*.tpl`, `main.tf` | Opcional (referencia) | **Sí** (SSM, user_data en state) | **Recrear** instancia o redeploy manual |
| Solo SSM `connection_uri` | No | **Sí** | No (la API usa `MONGO_URI` del docker run) |

## Por qué POST devuelve 500 en Swagger

1. **RabbitMQ** no accesible desde el contenedor API (`RABBITMQ_HOST` incorrecto o broker caído).
2. Código viejo en EC2 (sin `get_mongo_uri()` / sin manejo de errores).
3. **Worker** parado → POST puede responder 200 pero el plato no aparece (eso no es 500).

Tras el push, en cada EC2 API (SSH):

```bash
cd /home/ec2-user/restaurant-api && git pull
sudo docker build -t restaurant-api:latest .
sudo docker rm -f restaurant-api
# Usa IPs privadas actuales de Mongo y Rabbit:
sudo docker run -d --name restaurant-api --restart unless-stopped -p 8000:8000 \
  -e RABBITMQ_HOST=<IP_PRIVADA_RABBIT> \
  -e RABBITMQ_PORT=5672 \
  -e RABBITMQ_USER=admin \
  -e RABBITMQ_PASSWORD=password123 \
  -e MONGO_URI="mongodb://admin:password123@<IP_PRIVADA_MONGO>:27017/?authSource=admin" \
  restaurant-api:latest
```

URI desde Terraform (lab activo):

```bash
terraform output -raw mongodb_connection_uri
```

## Swagger

- Usa **POST `/dishes/`** (con barra final).
- Body: `{"name":"...","price":10,"ingredients":["..."]}`

## Orden recomendado

1. Lab Vocareum en **verde**.
2. `git push origin main`
3. `cd terraform && terraform apply`
4. SSH: Rabbit arriba, API rebuild, Worker con `MONGO_URI` y `python3 -m api.worker`.
