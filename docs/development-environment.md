# Entorno de Desarrollo — MCP, OpenCode y Convenciones

## Prerrequisitos

| Herramienta | Versión Mínima | Instalación |
|------------|---------------|-------------|
| Docker | 24+ | `brew install --cask docker` |
| Docker Compose | v2+ | Incluido con Docker Desktop |
| OpenCode | latest | `brew install opencode` |
| ngrok | latest | `brew install ngrok` |
| Git | 2.30+ | `brew install git` |

## Configuración del Entorno

```bash
# Clonar el repositorio
git clone <repo-url> superlikers-ai-automation-challenge
cd superlikers-ai-automation-challenge

# Copiar variables de entorno
cp docker/.env.example docker/.env

# Editar .env con tus API keys reales
nano docker/.env
```

### Variables de Entorno

| Variable | Descripción |
|----------|-------------|
| `N8N_HOST` | Host donde corre n8n (default: localhost) |
| `N8N_PORT` | Puerto de n8n (default: 5678) |
| `N8N_PROTOCOL` | Protocolo HTTP/HTTPS |
| `WEBHOOK_URL` | URL pública para webhooks (usar ngrok en dev) |
| `N8N_MCP_ACCESS_ENABLED` | Habilita el servidor MCP nativo de n8n |
| `SUPERLIKERS_API_KEY` | API key de Superlikers |
| `SUPERLIKERS_BASE_URL` | URL base de la API de Superlikers |
| `SUPERLIKERS_CAMPAIGN` | ID de campaña activa |
| `OPENAI_API_KEY` | API key de OpenAI |

## Iniciar n8n con Docker Compose

```bash
# Desde la raíz del proyecto
docker compose -f docker/docker-compose.yml up -d

# Verificar que está corriendo
docker compose -f docker/docker-compose.yml ps

# Ver logs
docker compose -f docker/docker-compose.yml logs -f n8n

# Abrir http://localhost:5678 en el navegador
```

### Primer Uso — Creación de Admin

1. Abrir `http://localhost:5678`
2. Completar el formulario de registro (primer usuario = owner/admin)
3. Opcional: configurar autenticación en Settings > Users

## Configuración de MCP (Model Context Protocol)

n8n v2.20.0 incluye un servidor MCP nativo. No es necesario instalar binarios externos.

### Habilitar MCP en n8n

1. Ir a **Settings > MCP** (en la UI de n8n)
2. Activar el toggle **MCP Server**
3. Hacer clic en **Generate Token** para crear un token de acceso
4. Copiar el token generado

### Conectar OpenCode a n8n MCP

Agregar la entrada al archivo `~/.config/opencode/opencode.json`:

```json
{
  "mcp": {
    "n8n": {
      "enabled": true,
      "type": "remote",
      "url": "http://localhost:5678/mcp-server/http",
      "headers": {
        "Authorization": "Bearer <tu_n8n_mcp_token>"
      }
    }
  }
}
```

Reemplazar `<tu_n8n_mcp_token>` con el token generado en n8n.

### Verificar Conexión MCP

```bash
# Probar que el endpoint MCP responde
curl http://localhost:5678/mcp-server/http

# Probar desde OpenCode (una vez configurado)
opencode mcp call n8n list-workflows
```

## Tunnel ngrok para Webhooks de WhatsApp

Los webhooks de WhatsApp requieren una URL pública. En desarrollo, se usa ngrok.

### Instalación

```bash
brew install ngrok
ngrok config add-authtoken <tu_ngrok_token>  # desde https://dashboard.ngrok.com
```

### Iniciar Tunnel

```bash
ngrok http 5678
```

Esto genera una URL como `https://abc123.ngrok.io`. Actualizar en `docker/.env`:

```ini
WEBHOOK_URL=https://abc123.ngrok.io
N8N_HOST=abc123.ngrok.io
N8N_PROTOCOL=https
```

Luego reiniciar n8n para que tome los cambios:

```bash
docker compose -f docker/docker-compose.yml restart n8n
```

### Notas sobre ngrok

- Cada vez que reinicias ngrok, la URL cambia (a menos que tengas un plan con subdominio fijo).
- Debes actualizar `WEBHOOK_URL` en `.env` y reiniciar n8n cada vez.
- Para desarrollo prolongado, considera un servicio de tunnel persistente (ngrok paid, Cloudflare Tunnel, etc.).

## Flujo de Trabajo con SDD

El proyecto sigue **Specification Driven Development (SDD)**:

### Ciclo de Desarrollo

```
 1. /sdd-new "<nombre-del-cambio>"   → Iniciar nuevo cambio
 2. sdd-explore                      → Explorar requerimientos
 3. sdd-propose                      → Crear propuesta
 4. sdd-spec                         → Definir especificaciones
 5. sdd-design                       → Diseñar arquitectura
 6. sdd-tasks                        → Desglosar tareas
 7. sdd-apply                        → Implementar
 8. sdd-verify                       → Verificar implementación
 9. sdd-archive                      → Cerrar cambio
```

### Convenciones del Proyecto

| Aspecto | Convención |
|---------|-----------|
| Commits | Conventional Commits: `feat:`, `fix:`, `docs:`, `chore:` |
| Branching | `feature/<cambio>` basado en `main` |
| Documentación | Markdown en `docs/` |
| Schemas | JSON Schema en `prompts/schemas/` |
| Tests | Plan en `tests/`, ejecución manual por ahora |
| n8n Workflows | Exportar como JSON a `n8n/workflows/` |

### Estructura de Directorios

```
superlikers-ai-automation-challenge/
├── docs/                    # Documentación técnica
│   ├── architecture.md
│   ├── state-machine.md
│   ├── api-contracts.md
│   ├── session-schema.md
│   └── development-environment.md
├── prompts/
│   ├── system/              # Prompts del sistema para cada fase
│   └── schemas/             # JSON schemas de datos
├── n8n/
│   └── workflows/           # Exportaciones de workflows n8n (.json)
├── docker/
│   ├── docker-compose.yml   # Orquestación de servicios
│   └── .env                 # Variables de entorno (no versionar)
├── tests/
│   └── test-plan.md         # Plan de pruebas
└── README.md
```

### Reglas para Commits

```bash
# Formato
<tipo>(<scope>): <descripción>

# Tipos permitidos
feat:     Nueva funcionalidad
fix:      Corrección de bug
docs:     Cambios en documentación
chore:    Mantenimiento, config, build
refactor: Refactorización sin cambio funcional
test:     Pruebas

# Ejemplos
feat(api): add participant search endpoint
docs(architecture): update state machine diagram
chore(docker): add healthcheck to n8n compose
```

### Comandos Útiles

```bash
# Iniciar n8n
docker compose -f docker/docker-compose.yml up -d

# Ver logs
docker compose -f docker/docker-compose.yml logs -f n8n

# Detener
docker compose -f docker/docker-compose.yml down

# Reiniciar
docker compose -f docker/docker-compose.yml restart n8n

# Acceder a n8n shell
docker exec -it superlikers-n8n /bin/sh

# Backup de workflows
docker exec superlikers-n8n n8n export:workflow --all --output=/backup/workflows
```
