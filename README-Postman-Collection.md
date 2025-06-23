# 🚀 OfertaYa - Colección de Postman para ApiGateway

## 📋 Descripción

Esta colección de Postman incluye todos los endpoints disponibles en el **ApiGateway** de OfertaYa, organizados por microservicios. Permite probar fácilmente toda la funcionalidad de la aplicación.

## 🏗️ Arquitectura

El ApiGateway actúa como punto de entrada único para todos los microservicios:

- **🔐 Autenticación** - Registro y login de usuarios
- **🏷️ Subastas** - Gestión de subastas
- **💰 Ofertas** - Gestión de ofertas en subastas
- **📦 Pedidos y Rastreo** - Gestión de pedidos y seguimiento
- **💬 Chat** - Sistema de chat en tiempo real
- **📊 Monitoreo** - Logs y métricas del sistema

## 📥 Instalación

### 1. Importar la Colección

1. Abre **Postman**
2. Haz clic en **"Import"**
3. Selecciona el archivo `OfertaYa-ApiGateway-Postman-Collection.json`
4. La colección se importará automáticamente

### 2. Configurar Variables de Entorno

La colección incluye variables predefinidas que puedes modificar:

| Variable | Valor por Defecto | Descripción |
|----------|-------------------|-------------|
| `base_url` | `http://localhost:8081` | URL base del ApiGateway |
| `token` | (vacío) | Token JWT (se llena automáticamente al hacer login) |
| `subasta_id` | `1` | ID de subasta para pruebas |
| `oferta_id` | `1` | ID de oferta para pruebas |
| `usuario_id` | `1` | ID de usuario para pruebas |
| `tracking_id` | `TRK123456789` | ID de tracking para pruebas |
| `evento_id` | `1` | ID de evento para pruebas |

## 🚀 Flujo de Pruebas Recomendado

### 1. Preparación
```bash
# Asegúrate de que todos los microservicios estén ejecutándose
docker-compose up -d
```

### 2. Secuencia de Pruebas

#### 🔐 Paso 1: Autenticación
1. **Registrar Usuario** - Crea una cuenta nueva
2. **Login Usuario** - Obtén el token JWT (se guarda automáticamente)

#### 🏷️ Paso 2: Subastas
3. **Obtener Recomendaciones** - Ver subastas disponibles
4. **Crear Subasta** - Crea una nueva subasta
5. **Consultar Subasta por ID** - Ver detalles de la subasta creada

#### 💰 Paso 3: Ofertas
6. **Crear Oferta** - Haz una oferta en la subasta
7. **Obtener Ofertas por Subasta** - Ver todas las ofertas
8. **Obtener Mejor Oferta por Subasta** - Ver la oferta más alta

#### 📦 Paso 4: Pedidos
9. **Crear Pedido** - Crea un pedido después de ganar una subasta
10. **Rastrear Pedido** - Consulta el estado del pedido

#### 📊 Paso 5: Monitoreo
11. **Health Check** - Verifica el estado del sistema
12. **Crear Evento de Monitoreo** - Registra un evento de prueba

## 🔧 Configuración Avanzada

### Variables de Entorno Personalizadas

Puedes crear un archivo de entorno en Postman con diferentes configuraciones:

#### Desarrollo Local
```json
{
  "base_url": "http://localhost:8081",
  "environment": "local"
}
```

#### Staging
```json
{
  "base_url": "http://staging-api.ofertaya.com",
  "environment": "staging"
}
```

#### Producción
```json
{
  "base_url": "https://api.ofertaya.com",
  "environment": "production"
}
```

### Scripts Automatizados

La colección incluye scripts que:

- **Pre-request**: Registra cada request en la consola
- **Test**: 
  - Valida respuestas exitosas
  - Guarda automáticamente el token JWT al hacer login
  - Muestra logs informativos

## 📊 Endpoints por Microservicio

### 🔐 Autenticación (`/api/auth`)
- `POST /register` - Registro de usuarios
- `POST /login` - Login y obtención de token

### 🏷️ Subastas (`/api/subasta`)
- `GET /recomendaciones` - Recomendaciones personalizadas
- `POST /agregar` - Crear subasta
- `GET /{id}` - Consultar subasta
- `PUT /{id}` - Modificar subasta
- `PUT /finalizar/{id}` - Finalizar subasta
- `PUT /cancelar/{id}` - Cancelar subasta

### 💰 Ofertas (`/api/ofertas`)
- `GET /{id}` - Obtener oferta por ID
- `GET /usuario` - Ofertas del usuario
- `GET /subasta/{id}` - Ofertas de una subasta
- `GET /subasta/mejor/{id}` - Mejor oferta de una subasta
- `POST /crear` - Crear oferta
- `GET /cancelar/{id}` - Cancelar oferta

### 📦 Pedidos (`/api/pedidos`)
- `POST /crear` - Crear pedido
- `GET /rastrear/{id}` - Rastrear pedido
- `GET /usuario/{id}` - Pedidos del usuario

### 💬 Chat (`/api/chat`)
- `GET /` - Página principal (WebSocket)

### 📊 Monitoreo (`/api/monitoreo`)
- `GET /health` - Health check
- `GET /info` - Información del servicio
- `GET /test` - Endpoint de prueba
- `GET /eventos` - Listar eventos
- `POST /eventos` - Crear evento
- `GET /eventos/{id}` - Obtener evento
- `GET /eventos/servicio/{name}` - Eventos por servicio
- `GET /eventos/nivel/{level}` - Eventos por nivel
- `GET /eventos/usuario/{id}` - Eventos por usuario
- `GET /eventos/fecha` - Eventos por fecha
- `GET /eventos/criticos` - Eventos críticos
- `GET /eventos/recientes` - Eventos recientes

### 📈 Métricas (`/api/metrics`)
- `GET /custom` - Métricas personalizadas

## 🐛 Solución de Problemas

### Error 401 - No autorizado
- Verifica que el token JWT sea válido
- Asegúrate de hacer login primero
- Revisa que el header `Authorization: Bearer {token}` esté presente

### Error 404 - No encontrado
- Verifica que el microservicio esté ejecutándose
- Comprueba que la URL base sea correcta
- Revisa que el ID del recurso exista

### Error 500 - Error interno
- Revisa los logs del microservicio correspondiente
- Verifica la conectividad con la base de datos
- Comprueba la configuración del ApiGateway

### Microservicios no responden
```bash
# Verificar estado de los contenedores
docker-compose ps

# Ver logs del ApiGateway
docker-compose logs api-gateway

# Reiniciar servicios
docker-compose restart
```

## 📝 Notas Importantes

1. **Autenticación**: La mayoría de endpoints requieren autenticación JWT
2. **CORS**: Los endpoints están configurados para `http://localhost:5173`
3. **WebSocket**: El chat usa WebSocket, no HTTP REST
4. **Monitoreo**: Los eventos de monitoreo se registran automáticamente
5. **Variables**: Los IDs de ejemplo pueden no existir en tu base de datos

## 🔄 Actualizaciones

Para actualizar la colección:

1. Exporta la colección actualizada desde Postman
2. Reemplaza el archivo `OfertaYa-ApiGateway-Postman-Collection.json`
3. Comparte la nueva versión con el equipo

## 📞 Soporte

Si encuentras problemas:

1. Revisa los logs del microservicio correspondiente
2. Verifica la configuración del ApiGateway
3. Consulta la documentación de cada microservicio
4. Contacta al equipo de desarrollo

---

**¡Disfruta probando OfertaYa! 🎉** 