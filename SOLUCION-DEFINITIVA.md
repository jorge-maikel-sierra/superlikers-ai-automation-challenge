# 🎯 SOLUCIÓN DEFINITIVA - Activar Workflow Correcto

## 🔴 PROBLEMA ROOT CAUSE

Tienes MÚLTIPLES workflows con el nombre "Participant Onboarding v1" en n8n.

Cuando importaste el archivo `participant-onboarding-v2-IMPORT.json`, n8n lo creó con el nombre "Participant Onboarding v1" (porque ese es el nombre que tiene en el JSON).

Ahora tienes workflows duplicados y el que está ACTIVO es el viejo (el incorrecto).

---

## ✅ SOLUCIÓN INMEDIATA (2 opciones)

### OPCIÓN A: Renombrar y Activar el Correcto (RECOMENDADA)

1. **Ir a n8n**: http://localhost:5678

2. **Ver lista de workflows**:
   - Click en "Workflows" (menú lateral)
   - Verás VARIOS workflows llamados "Participant Onboarding v1"

3. **Identificar el CORRECTO (el más reciente)**:
   - Ordenar por "Last Updated" (más reciente primero)
   - El workflow correcto fue creado hace unos minutos
   - O busca el que tiene **fecha de creación más reciente**

4. **Abrir el workflow más reciente** y verificar:
   - Debe tener **39 nodos**
   - Debe tener un nodo llamado **"Image Size Validator"**
   - El nodo "Search Participant" debe tener **method: GET**
   
5. **Renombrarlo**:
   - Click en el nombre del workflow (arriba)
   - Cambiar a: **"Participant Onboarding v2 CORRECTO"**
   - Guardar (Ctrl+S o Cmd+S)

6. **DESACTIVAR todos los workflows viejos**:
   - Volver a la lista de workflows
   - Para cada "Participant Onboarding v1" (los viejos):
     - Abrirlos
     - Toggle "Active" → OFF
     - Guardar

7. **ACTIVAR el workflow renombrado**:
   - Abrir "Participant Onboarding v2 CORRECTO"
   - Toggle "Active" → ON
   - Confirmar que dice "Workflow activated"

8. **Verificar**:
   ```bash
   curl -X POST "http://localhost:5678/webhook/whatsapp" -d '{"test":1}'
   ```
   Debe responder 200 OK (NO 404)

---

### OPCIÓN B: Editar el Archivo y Re-importar

1. **Editar el archivo v2-IMPORT.json**:
   
   Abrir: `n8n/workflows/participant-onboarding-v2-IMPORT.json`
   
   Buscar la línea (cerca del inicio):
   ```json
   "name": "Participant Onboarding v1",
   ```
   
   Cambiar por:
   ```json
   "name": "Participant Onboarding v2 CORRECTED",
   ```
   
   Guardar el archivo

2. **Importar de nuevo en n8n**:
   - Menú → Import from file
   - Seleccionar el archivo modificado
   - Importar

3. **Activarlo**:
   - Ahora será fácil identificarlo (se llama "v2 CORRECTED")
   - Toggle "Active" → ON

4. **Desactivar todos los "v1"**

---

### OPCIÓN C: Configurar Manualmente el v1 Activo

Si no puedes hacer A ni B, podemos configurar manualmente cada nodo del v1 que ya está activo.

Te paso los comandos exactos para cada nodo. ¿Quieres que te los dé?

---

## 🧪 VERIFICACIÓN POST-ACTIVACIÓN

Una vez que el workflow correcto esté activo:

```bash
# Test de verificación
curl -X POST "http://localhost:5678/webhook/whatsapp" \
  -H "Content-Type: application/json" \
  -d '{
    "entry": [{
      "changes": [{
        "value": {
          "messages": [{
            "from": "+573001234567",
            "type": "text",
            "text": {"body": "Hola"}
          }]
        }
      }]
    }]
  }'
```

**Resultado esperado**: 
- Status: 200 OK
- O respuesta JSON (NO 404)

Luego ir a n8n → Executions → Debe haber una ejecución nueva.

---

## 📊 DEBUGGING: Cómo Identificar el Workflow Correcto

En n8n UI, para cada workflow "Participant Onboarding v1":

| Check | Workflow CORRECTO (v2) | Workflow INCORRECTO (v1) |
|-------|------------------------|--------------------------|
| **Nodos totales** | 39 nodos | 38 nodos |
| **Nodo "Image Size Validator"** | ✅ Existe | ❌ No existe |
| **Search Participant → method** | GET | POST o vacío |
| **Register Participant → body** | Configurado (largo) | Vacío o null |
| **Process Invoice → model** | "gpt-4o" visible | Vacío |
| **Fecha creación** | Más reciente | Más antigua |

---

## ⚠️ SI SIGUES TENIENDO 404

Si después de activar el workflow correcto SIGUES viendo 404, significa que:

1. El workflow NO está realmente activo (revisar toggle)
2. El nodo "WhatsApp Webhook" tiene un path incorrecto
3. n8n necesita reiniciarse:
   ```bash
   docker compose -f docker/docker-compose.yml restart n8n
   ```

Espera 30 segundos y vuelve a probar el curl.

---

## 🎯 PRÓXIMO PASO

Una vez que confirmes que el curl NO da 404, avísame y continuaré con las pruebas exhaustivas del flujo completo.

**Lo que necesito de ti**:
- [ ] "El curl ahora responde 200 OK"
- [ ] "Sigue dando 404, pero ya renombré/activé el correcto"
- [ ] "No encuentro ningún workflow con 39 nodos"
- [ ] "Voy a usar la opción B (editar archivo)"
- [ ] "Dame la opción C (configurar manualmente)"

---

**Creado**: 25 de junio de 2026, 00:35
