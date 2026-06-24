# Estrategia de Persistencia — n8n Data Store

## Visión General

La persistencia de sesiones en n8n se maneja a través de **n8n Data Store** (Key-Value) como mecanismo principal, con **mock JSON** como respaldo para desarrollo local. No se requiere base de datos externa en esta fase.

---

## Stack de Persistencia

```
┌─────────────────────────────────────────────┐
│              n8n Workflow                     │
│                                               │
│  ┌───────────────────────────────────────┐   │
│  │         Session Manager (Code Node)    │   │
│  │                                        │   │
│  │  getSession(phone) → session | null    │   │
│  │  saveSession(phone, session) → void    │   │
│  │  deleteSession(phone) → void           │   │
│  └──────────────┬────────────────────────┘   │
│                 │                             │
│        ┌────────┴────────┐                   │
│        ▼                 ▼                    │
│  n8n Data Store    JSON File (dev fallback)  │
│  (producción)       /data/sessions/*.json     │
└─────────────────────────────────────────────┘
```

---

## Modos de Persistencia

### Modo Producción: n8n Data Store

| Aspecto | Detalle |
|---------|---------|
| **Tipo** | Key-Value Store interno de n8n |
| **Clave** | `session:{phone}` (ej: `session:+521234567890`) |
| **Valor** | JSON string del objeto de sesión |
| **TTL** | 30 minutos (sesión expira por inactividad) |
| **Persistencia** | Automática (n8n guarda en su base SQLite interna) |

### Modo Desarrollo: JSON Files

| Aspecto | Detalle |
|---------|---------|
| **Tipo** | Archivos JSON en disco |
| **Ruta** | `/data/sessions/{phone}.json` |
| **Creación** | Al recibir primer mensaje del usuario |
| **Actualización** | En cada transición de estado |
| **Limpieza** | Manual o script de cleanup |

---

## Clave Primaria

```
formato: session:{phone_normalized}
ejemplo: session:+521234567890
```

- **phone_normalized**: Formato E.164 (+52 seguido de 10 dígitos)
- La normalización ocurre en el nodo **Phone Validator**
- Sin normalización → duplicados o sesiones perdidas

---

## Esquema de Sesión

```json
{
  "phone": "+521234567890",
  "name": "Juan Pérez",
  "email": "juan@example.com",
  "state": "WAIT_TICKET",
  "photo_id": "",
  "photo_url": "",
  "participant_id": "part_abc123",
  "purchase_id": "",
  "invoice_ref": "",
  "invoice_data": {},
  "points": 0,
  "retry_count": 0,
  "created_at": "2026-06-24T10:00:00Z",
  "updated_at": "2026-06-24T10:05:00Z"
}
```

### Campos de Control

| Campo | Propósito |
|-------|-----------|
| `retry_count` | Evitar bucles infinitos en errores. Se incrementa en cada error, se resetea al cambiar de estado |
| `created_at` | Útil para estadísticas y para limpiar sesiones abandonadas |
| `updated_at` | Detecta timeouts (si pasó >30 min desde último update) |

---

## Operaciones CRUD

### Crear Sesión
```javascript
function createSession(phone) {
  const session = {
    phone: phone,
    state: 'START',
    name: '',
    email: '',
    participant_id: '',
    photo_id: '',
    photo_url: '',
    purchase_id: '',
    invoice_ref: '',
    invoice_data: {},
    points: 0,
    retry_count: 0,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString()
  };

  // n8n Data Store
  $dataStore.set(`session:${phone}`, JSON.stringify(session), 1800); // TTL 30min

  // JSON fallback (dev)
  writeJSONFile(`/data/sessions/${phone}.json`, session);

  return session;
}
```

### Leer Sesión
```javascript
function getSession(phone) {
  // Intentar Data Store primero
  let sessionStr = $dataStore.get(`session:${phone}`);

  // Fallback a JSON
  if (!sessionStr) {
    sessionStr = readJSONFile(`/data/sessions/${phone}.json`);
  }

  if (!sessionStr) return null;

  const session = JSON.parse(sessionStr);

  // Verificar timeout de 30 minutos
  const now = new Date();
  const updated = new Date(session.updated_at);
  const diffMinutes = (now - updated) / (1000 * 60);

  if (diffMinutes > 30) {
    deleteSession(phone);
    return null;
  }

  return session;
}
```

### Actualizar Sesión
```javascript
function updateSession(phone, updates) {
  const session = getSession(phone);
  if (!session) throw new Error('Session not found');

  // Aplicar actualizaciones parciales
  Object.assign(session, updates, {
    updated_at: new Date().toISOString()
  });

  // Si cambió de estado, resetear retry_count
  if (updates.state && updates.state !== session.state) {
    session.retry_count = 0;
  }

  // Persistir
  $dataStore.set(`session:${phone}`, JSON.stringify(session), 1800);
  writeJSONFile(`/data/sessions/${phone}.json`, session);

  return session;
}
```

### Eliminar Sesión
```javascript
function deleteSession(phone) {
  $dataStore.delete(`session:${phone}`);
  deleteJSONFile(`/data/sessions/${phone}.json`);
}
```

---

## Timeout de Conversación

| Parámetro | Valor |
|-----------|-------|
| **Timeout** | 30 minutos |
| **Detección** | Comparar `updated_at` con timestamp actual |
| **Acción al expirar** | Eliminar sesión + enviar "Tu sesión expiró. Empecemos de nuevo." |
| **TTL en Data Store** | 1800 segundos |

### Flujo de Timeout
```
1. Llega mensaje del usuario
2. Session Manager recupera sesión
3. Calcula diff entre updated_at y now
4. Si diff > 30 min → eliminar sesión → START
5. Si diff <= 30 min → continuar flujo normal
```

---

## Concurrencia

| Situación | Comportamiento |
|-----------|---------------|
| Mismo usuario envía 2 mensajes seguidos | Se procesa el último; el estado es determinístico |
| Mensaje durante llamada API | n8n maneja ejecuciones en serie por workflow; no hay race conditions |
| Dos webhooks simultáneos del mismo usuario | n8n encola; se procesan secuencialmente |

---

## Estrategia para Producción (Futuro)

| Aspecto | Actual (Dev) | Producción |
|---------|-------------|------------|
| Almacenamiento | n8n Data Store + JSON | Redis |
| TTL | 1800s (Data Store) | Redis TTL de 30 min |
| Backup | Archivos JSON | Redis Persistence (RDB/AOF) |
| Escalabilidad | Single node | Redis Cluster |
| Recuperación | Leer archivo JSON | Redis GET |

### Migración a Redis
Cuando se requiera escalar, reemplazar las funciones de persistencia:

```javascript
// En lugar de $dataStore
const redis = require('redis');
const client = redis.createClient({ url: process.env.REDIS_URL });

function getSession(phone) {
  const data = await client.get(`session:${phone}`);
  return data ? JSON.parse(data) : null;
}
```

---

## Resumen de Claves

| Propósito | Clave | TTL |
|-----------|-------|-----|
| Sesión activa | `session:{phone}` | 1800s |
| Backup desarrollo | `/data/sessions/{phone}.json` | N/A |
