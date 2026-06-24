# Entorno de Desarrollo — MCP, OpenCode y Convenciones

## Instalación

### Prerrequisitos

| Herramienta | Versión Mínima | Instalación |
|------------|---------------|-------------|
| Docker | 24+ | `brew install --cask docker` |
| Docker Compose | v2+ | Incluido con Docker Desktop |
| Node.js | 18+ | `brew install node@18` |
| OpenCode | latest | `brew install opencode` |
| Git | 2.30+ | `brew install git` |

### Configuración Inicial

```bash
# Clonar el repositorio
git clone <repo-url> superlikers-ai-automation-challenge
cd superlikers-ai-automation-challenge

# Copiar variables de entorno
cp docker/.env.example docker/.env

# Editar .env con tus API keys
nano docker/.env

# Iniciar n8n
cd docker
docker compose up -d

# Verificar que n8n está corriendo
docker compose ps
# Abrir http://localhost:5678 en el navegador
```

## Configuración de MCP (Model Context Protocol)

El proyecto usa MCP para gestionar workflows de n8n programáticamente desde OpenCode.

### Archivo de Configuración

Crear o editar `~/.config/opencode/opencode.json`:

```json
{
  "mcpServers": {
    "n8n": {
      "command": "n8n-mcp-server",
      "args": ["--url", "http://localhost:5678"],
      "env": {
        "N8N_API_KEY": "tu_n8n_api_key"
      }
    }
  }
}
```

### Generar API Key en n8n

1. Abrir n8n: `http://localhost:5678`
2. Ir a **Settings > API**
3. Crear nueva API Key
4. Copiar la key a `~/.config/opencode/opencode.json`

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

### Variables de Entorno

No versionar `docker/.env`. Cada desarrollador crea la suya desde `docker/.env.example`.

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
