# Estrategia de Observabilidad — n8n WhatsApp Chatbot

## Visión General

Métricas clave para monitorear la salud del sistema, el rendimiento de los flujos y el comportamiento del negocio. Para esta fase de desarrollo, las métricas se recolectan desde los logs y se exponen para dashboards simples.

---

## Stack de Observabilidad

```
┌────────────────────────────────────────────────────────────┐
│                        n8n Workflows                         │
│  ┌──────────────────────────────────────────────────┐       │
│  │           Logger Node (logs estructurados)        │       │
│  └──────────────────────┬───────────────────────────┘       │
│                         │                                    │
│                         ▼                                    │
│  ┌──────────────────────────────────────────────────┐       │
│  │               Archivos JSON / stdout               │       │
│  └──────────────────────┬───────────────────────────┘       │
│                         │                                    │
└─────────────────────────┼────────────────────────────────────┘
                          │
                          ▼
              ┌─────────────────────┐
              │   Parseador de Logs  │
              │   (script Node.js)   │
              └──────────┬──────────┘
                         │
              ┌──────────┴──────────┐
              │                     │
              ▼                     ▼
    ┌─────────────────┐   ┌─────────────────┐
    │  Métricas de     │   │  Dashboard      │
    │  Negocio         │   │  (CLI / JSON)   │
    └─────────────────┘   └─────────────────┘
```

---

## Métricas de Salud del Sistema


### Volumen de Mensajes

| Métrica | Descripción | Fuente |
|---------|-------------|--------|
| `messages_total` | Total de mensajes recibidos | Logs de webhook |
| `messages_by_type` | Desglose por tipo (texto, imagen) | Logs de webhook |
| `messages_by_phone` | Mensajes por usuario | Logs de webhook |
| `messages_per_hour` | Tasa de mensajes por hora | Logs de webhook |

### Estado de Sesiones

| Métrica | Descripción | Fuente |
|---------|-------------|--------|
| `sessions_created` | Nuevas sesiones iniciadas | Logs de session-manager |
| `sessions_active` | Sesiones activas en el período | Logs de session-manager |
| `sessions_expired` | Sesiones expiradas por timeout | Logs de session-manager |
| `sessions_by_state` | Distribución de estados actuales | Logs de session-manager |

### Rendimiento de APIs

| Métrica | Descripción | Fuente |
|---------|-------------|--------|
| `api_latency_ms` | Latencia de cada llamada API | Logs de HTTP Request |
| `api_error_rate` | Tasa de errores por endpoint | Logs de error |
| `api_retry_count` | Número de reintentos por request | Logs de error |
| `api_timeout_rate` | Tasa de timeouts | Logs de error |

### Rendimiento de IA

| Métrica | Descripción | Fuente |
|---------|-------------|--------|
| `ai_latency_ms` | Tiempo de procesamiento de IA | Logs de process-invoice |
| `ai_confidence_avg` | Confianza promedio de OCR | Logs de process-invoice |
| `ai_confidence_distribution` | Distribución de confianza (alta/media/baja) | Logs de process-invoice |
| `ai_error_rate` | Tasa de errores de IA | Logs de error |

---

## Métricas de Negocio

### Conversaciones

| Métrica | Descripción | Fórmula |
|---------|-------------|---------|
| `conversations_started` | Conversaciones iniciadas | Count de sessions_created |
| `conversations_completed` | Flujos completados exitosamente | Count de FINISHED |
| `conversations_abandoned` | Usuarios que abandonaron | started - completed |
| `conversion_rate` | Tasa de finalización | completed / started * 100 |
| `avg_conversation_duration` | Duración promedio | Promedio de FINISHED - START |

### Participantes

| Métrica | Descripción | Fuente |
|---------|-------------|--------|
| `participants_found` | Participantes existentes identificados | Logs de search-participant |
| `participants_registered` | Nuevos registros | Logs de register-participant |
| `participants_new_vs_existing` | Ratio nuevo vs existente | found vs registered |

### Tickets y Facturas

| Métrica | Descripción | Fuente |
|---------|-------------|--------|
| `tickets_uploaded` | Tickets subidos exitosamente | Logs de upload-ticket |
| `tickets_rejected` | Tickets rechazados (formato/tamaño) | Logs de error |
| `invoices_processed` | Facturas procesadas por IA | Logs de process-invoice |
| `invoices_high_confidence` | Facturas con confianza >= 0.7 | Logs de process-invoice |
| `invoices_low_confidence` | Facturas con confianza < 0.7 | Logs de process-invoice |

### Compras y Puntos

| Métrica | Descripción | Fuente |
|---------|-------------|--------|
| `purchases_registered` | Compras registradas | Logs de register-purchase |
| `purchases_duplicate` | Compras duplicadas detectadas | Logs de register-purchase (409) |
| `entries_approved` | Entries aprobados | Logs de accept-entry |
| `total_points_awarded` | Puntos totales otorgados | Suma de puntos en accept-entry |
| `avg_points_per_purchase` | Puntos promedio por compra | total_points / purchases_registered |
| `avg_amount_per_purchase` | Monto promedio por compra | Suma montos / purchases_registered |

---

## Implementación de Métricas

### Recolector de Métricas (Code Node)

```javascript
function emitMetric(name, value, tags = {}) {
  const metric = {
    timestamp: new Date().toISOString(),
    metric: name,
    value: value,
    tags: {
      campaign: process.env.SUPERLIKERS_CAMPAIGN || '3z',
      ...tags
    }
  };

  // Log como métrica (categoría especial)
  log('INFO', 'metric', 'metrics-collector', tags.phone, name, metric);

  // También guardar en archivo de métricas agregadas
  appendToFile('/data/metrics/counters.jsonl', JSON.stringify(metric) + '\n');

  return metric;
}
```

### Uso en Nodos

```javascript
// Al completar un flujo
emitMetric('conversations_completed', 1, {
  phone: session.phone,
  participant_type: session.participant_id ? 'existing' : 'new',
  total_points: session.points
});

// Al procesar una factura
emitMetric('ai_confidence', confidence, {
  phone: phone,
  merchant: invoice_data.merchant_name || 'unknown'
});
```

---

## Dashboard de Métricas (Plan)

### Dashboard de Salud (Operaciones)

| Sección | Métricas |
|---------|----------|
| **Volumen** | messages_total, messages_per_hour |
| **Sesiones** | sessions_active, sessions_by_state |
| **Latencia** | api_latency_avg, ai_latency_avg |
| **Errores** | api_error_rate, ai_error_rate, error_rate_by_type |

### Dashboard de Negocio

| Sección | Métricas |
|---------|----------|
| **Conversiones** | conversion_rate, conversations_completed |
| **Participantes** | participants_new_vs_existing, total_participants |
| **Compras** | purchases_registered, avg_amount_per_purchase |
| **Puntos** | total_points_awarded, avg_points_per_purchase |

---

## Alertas Tempranas

### Alertas Operativas

| Alerta | Condición | Acción |
|--------|-----------|--------|
| API error rate alto | > 10% en 5 minutos | Revisar disponibilidad de Superlikers |
| IA baja confianza sostenida | Promedio < 0.6 en 10 facturas | Revisar prompt o calidad de imágenes |
| Sesiones expiradas anómalas | > 50% de sesiones expiran | Revisar UX del flujo |
| Latencia API elevada | Promedio > 5s en 5 minutos | Investigar cuello de botella |

### Alertas de Negocio

| Alerta | Condición | Acción |
|--------|-----------|--------|
| Caída en conversiones | conversion_rate < 20% | Revisar punto de abandono |
| Cero registros en 1 hora | 0 purchases_registered en 60 min | Investigar fallo general |
| Picos de duplicados | duplicate_rate > 5% | Revisar lógica de detección |

---

## Almacenamiento de Métricas

| Aspecto | Desarrollo | Producción (Futuro) |
|---------|-----------|---------------------|
| Almacenamiento | Archivos JSONL (rotación diaria) | Prometheus + Grafana |
| Retención | 7 días | 30 días |
| Dashboard | Parse script + CLI | Grafana Dashboard |
| Alertas | Manual (revisión de logs) | Alert Manager |
