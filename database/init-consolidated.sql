-- Script para inicializar base de datos consolidada de OfertaYa
-- Esta base de datos contendrá todas las tablas de los microservicios

-- Crear esquemas para separar los datos de cada microservicio
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS subasta;
CREATE SCHEMA IF NOT EXISTS oferta;
CREATE SCHEMA IF NOT EXISTS pedidos;
CREATE SCHEMA IF NOT EXISTS monitoreo;

-- ==================== ESQUEMA AUTH ====================
CREATE TABLE IF NOT EXISTS auth.users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'USER',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS auth.roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);

INSERT INTO auth.roles (name) VALUES ('USER'), ('ADMIN') ON CONFLICT DO NOTHING;

-- ==================== ESQUEMA SUBASTA ====================
CREATE TABLE IF NOT EXISTS subasta.subastas (
    id SERIAL PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    descripcion TEXT,
    precio_inicial DECIMAL(10,2) NOT NULL,
    precio_actual DECIMAL(10,2) NOT NULL,
    fecha_inicio TIMESTAMP NOT NULL,
    fecha_fin TIMESTAMP NOT NULL,
    estado VARCHAR(50) DEFAULT 'ACTIVA',
    usuario_creador_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS subasta.participantes (
    id SERIAL PRIMARY KEY,
    subasta_id INTEGER REFERENCES subasta.subastas(id),
    usuario_id INTEGER,
    fecha_participacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== ESQUEMA OFERTA ====================
CREATE TABLE IF NOT EXISTS oferta.ofertas (
    id SERIAL PRIMARY KEY,
    subasta_id INTEGER NOT NULL,
    usuario_id INTEGER NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    fecha_oferta TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(50) DEFAULT 'ACTIVA'
);

-- ==================== ESQUEMA PEDIDOS ====================
CREATE TABLE IF NOT EXISTS pedidos.pedidos (
    id SERIAL PRIMARY KEY,
    subasta_id INTEGER NOT NULL,
    usuario_comprador_id INTEGER NOT NULL,
    usuario_vendedor_id INTEGER NOT NULL,
    monto_total DECIMAL(10,2) NOT NULL,
    estado VARCHAR(50) DEFAULT 'PENDIENTE',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS pedidos.rastreo (
    id SERIAL PRIMARY KEY,
    pedido_id INTEGER REFERENCES pedidos.pedidos(id),
    estado VARCHAR(100) NOT NULL,
    ubicacion VARCHAR(255),
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    comentarios TEXT
);

-- ==================== ESQUEMA MONITOREO ====================
CREATE TABLE IF NOT EXISTS monitoreo.eventos (
    id SERIAL PRIMARY KEY,
    servicio VARCHAR(100) NOT NULL,
    tipo_evento VARCHAR(100) NOT NULL,
    descripcion TEXT,
    nivel VARCHAR(20) DEFAULT 'INFO',
    correlation_id VARCHAR(100),
    usuario_id INTEGER,
    fecha_evento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

CREATE TABLE IF NOT EXISTS monitoreo.metricas (
    id SERIAL PRIMARY KEY,
    servicio VARCHAR(100) NOT NULL,
    nombre_metrica VARCHAR(100) NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    unidad VARCHAR(20),
    fecha_medicion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== ÍNDICES PARA OPTIMIZACIÓN ====================
CREATE INDEX IF NOT EXISTS idx_users_email ON auth.users(email);
CREATE INDEX IF NOT EXISTS idx_subastas_estado ON subasta.subastas(estado);
CREATE INDEX IF NOT EXISTS idx_subastas_fecha_fin ON subasta.subastas(fecha_fin);
CREATE INDEX IF NOT EXISTS idx_ofertas_subasta_id ON oferta.ofertas(subasta_id);
CREATE INDEX IF NOT EXISTS idx_ofertas_usuario_id ON oferta.ofertas(usuario_id);
CREATE INDEX IF NOT EXISTS idx_pedidos_usuario_comprador ON pedidos.pedidos(usuario_comprador_id);
CREATE INDEX IF NOT EXISTS idx_pedidos_estado ON pedidos.pedidos(estado);
CREATE INDEX IF NOT EXISTS idx_eventos_servicio ON monitoreo.eventos(servicio);
CREATE INDEX IF NOT EXISTS idx_eventos_fecha ON monitoreo.eventos(fecha_evento);
CREATE INDEX IF NOT EXISTS idx_metricas_servicio ON monitoreo.metricas(servicio);
CREATE INDEX IF NOT EXISTS idx_metricas_fecha ON monitoreo.metricas(fecha_medicion);

-- ==================== DATOS DE PRUEBA ====================
-- Insertar usuario de prueba
INSERT INTO auth.users (email, password, role) 
VALUES ('admin@ofertaya.com', '$2a$10$rAM0QZqZqZqZqZqZqZqZqO', 'ADMIN')
ON CONFLICT DO NOTHING;

-- Insertar subasta de prueba
INSERT INTO subasta.subastas (titulo, descripcion, precio_inicial, precio_actual, fecha_inicio, fecha_fin, usuario_creador_id)
VALUES (
    'iPhone 15 Pro Max',
    'iPhone 15 Pro Max en excelente estado, solo 6 meses de uso',
    800.00,
    800.00,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP + INTERVAL '7 days',
    1
) ON CONFLICT DO NOTHING;

-- Insertar evento de monitoreo de prueba
INSERT INTO monitoreo.eventos (servicio, tipo_evento, descripcion, nivel, correlation_id)
VALUES (
    'auth-service',
    'USER_LOGIN',
    'Usuario admin@ofertaya.com inició sesión exitosamente',
    'INFO',
    'test-correlation-id-123'
) ON CONFLICT DO NOTHING;

-- ==================== VISTAS ÚTILES ====================
CREATE OR REPLACE VIEW subasta.subastas_activas AS
SELECT 
    s.*,
    COUNT(o.id) as total_ofertas,
    MAX(o.monto) as oferta_mas_alta
FROM subasta.subastas s
LEFT JOIN oferta.ofertas o ON s.id = o.subasta_id
WHERE s.estado = 'ACTIVA' AND s.fecha_fin > CURRENT_TIMESTAMP
GROUP BY s.id;

CREATE OR REPLACE VIEW monitoreo.resumen_eventos AS
SELECT 
    servicio,
    tipo_evento,
    COUNT(*) as total_eventos,
    DATE_TRUNC('day', fecha_evento) as fecha
FROM monitoreo.eventos
GROUP BY servicio, tipo_evento, DATE_TRUNC('day', fecha_evento)
ORDER BY fecha DESC;

-- ==================== FUNCIONES ÚTILES ====================
CREATE OR REPLACE FUNCTION actualizar_precio_subasta()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE subasta.subastas 
    SET precio_actual = NEW.monto, updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.subasta_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar precio de subasta cuando se hace una oferta
CREATE TRIGGER trigger_actualizar_precio_subasta
    AFTER INSERT ON oferta.ofertas
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_precio_subasta();

-- Función para limpiar eventos antiguos
CREATE OR REPLACE FUNCTION limpiar_eventos_antiguos(dias INTEGER DEFAULT 30)
RETURNS INTEGER AS $$
DECLARE
    registros_eliminados INTEGER;
BEGIN
    DELETE FROM monitoreo.eventos 
    WHERE fecha_evento < CURRENT_TIMESTAMP - INTERVAL '1 day' * dias;
    
    GET DIAGNOSTICS registros_eliminados = ROW_COUNT;
    RETURN registros_eliminados;
END;
$$ LANGUAGE plpgsql;

-- ==================== PERMISOS ====================
-- Crear usuario específico para la aplicación
CREATE USER ofertaya_app WITH PASSWORD 'ofertaya_app_password';

-- Otorgar permisos
GRANT USAGE ON SCHEMA auth, subasta, oferta, pedidos, monitoreo TO ofertaya_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA auth, subasta, oferta, pedidos, monitoreo TO ofertaya_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA auth, subasta, oferta, pedidos, monitoreo TO ofertaya_app;

-- Permitir que el usuario de la aplicación pueda crear nuevas tablas
GRANT CREATE ON SCHEMA auth, subasta, oferta, pedidos, monitoreo TO ofertaya_app;

COMMIT; 