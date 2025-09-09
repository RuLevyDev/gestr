# GESTR
Aplicación Flutter para la gestión de ingresos y gastos de autónomos y pymes. Está orientada al empresario o profesional independiente, sin modos separados para empleados o administradores. El objetivo es ofrecer una experiencia altamente automatizada y modular, permitiendo que cada negocio adapte la app a sus necesidades específicas.

## KPIs
- **Gastos automatizados**: porcentaje de gastos capturados mediante escaneo o integración bancaria.
- **Tiempo de registro**: tiempo promedio que un usuario tarda en registrar un gasto.
- **Usuarios activos mensuales**: cantidad de cuentas con actividad cada mes.
- **Integraciones bancarias**: número de cuentas bancarias conectadas.
- **Módulos activos por usuario**: promedio de módulos habilitados por tipo de negocio.

## Roadmap
1. **Automatización de ingresos** mediante conexión directa con cuentas bancarias.dulos opcionales para gestionar clientes, proveedores, productos, servicios, citas, empleados y suscripciones.
4. **Integraciones externas** con software de contabilidad y ERPs mediante API y exportaciones estándar.
5. **Soporte multiplataforma** con aplicaciones móviles y web sincronizadas.

## Insights de la competencia (N2F)
N2F se orienta a organizaciones con múltiples usuarios (empleados y administradores). Aunque GESTR se centra en el empresario, estas funcionalidades sirven de referencia:
- Escaneo inteligente de recibos y extracción automática de datos (fecha, monto, impuestos, moneda).
- Archivo digital con valor probatorio para eliminar el papel.
- Gestión automática de facturas de proveedores recibidas por correo electrónico.
- Flujos de aprobación personalizables y paneles para administradores, pensados para equipos con múltiples roles.
- Cálculo automático de kilometraje e IVA recuperable.
- Exportaciones para contabilidad y reembolsos mediante archivos SEPA.
- Soporte multi-divisa y políticas de gasto configurables.
- APIs y servicios web para integrarse con sistemas externos.

## Estado del proyecto
### Lo que ya tenemos
- Arquitectura Flutter modular con capas `app`, `core`, `data` y `domain`.
- Registro manual de ingresos y gastos.
- Base para habilitar módulos de clientes, proveedores y productos.
- Escaneo de facturas con OCR que extrae título, importe, fecha, emisor, receptor y concepto.

### Lo que falta
- modulo de proveedores, productos, clientes, servicios , citas,empleados, analytics , opciones , subcripcion
- Conexión bancaria automática para importar movimientos y comprobantes.
- Exportaciones contables e integración con ERPs.

### Ideas adicionales
- Panel de KPIs en tiempo real y widgets configurables.
- Sistema de suscripciones para activar módulos avanzados.
- Alertas y recordatorios proactivos para gastos incompletos.
- Análisis predictivo de flujo de caja y recomendaciones.