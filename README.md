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
### Checklist de funcionalidades de la app

#### Implementadas
- [x] Arquitectura Flutter modular con capas `app`, `core`, `data` y `domain`.
- [x] Registro manual de ingresos y gastos.
- [x] Escaneo de facturas con OCR que extrae título, importe, fecha, emisor, receptor y concepto.
- [x] Módulo de proveedores y productos.
- [x] Módulo de clientes.

#### Pendientes
- [ ] Módulos/widgets de servicios, citas, empleados, analíticas, opciones, notificaciones y suscripciones.
- [ ] Conexión bancaria automática para importar movimientos y comprobantes.
- [ ] Exportaciones contables e integración con ERPs.

- [ ] Panel de KPIs en tiempo real y widgets configurables.
- [ ] Sistema de suscripciones para activar módulos avanzados.
- [ ] Alertas y recordatorios proactivos para gastos incompletos.
- [ ] Análisis predictivo de flujo de caja y recomendaciones.

## Validación y normalización PDF/A
- [ ]Ejecuta `dart run tool/generate_sample_pdfs.dart` (o `flutter pub run tool/generate_sample_pdfs.dart` si solo está disponible Flutter) para generar comprobantes de ejemplo con los metadatos XMP solicitados al backend.
- [ ] Lanza `tool/validate_pdfa.sh` para regenerar los PDFs de muestra y validarlos automáticamente con [veraPDF](https://verapdf.org/) dentro de un contenedor Docker.
- [ ] La acción de GitHub `.github/workflows/pdfa-validate.yml` reutiliza estos scripts para garantizar que siempre exista una verificación PDF/A sin coste adicional durante los PR.
### Checklist de cumplimiento AEAT dentro de la app
- [x] Garantizar soporte en la app para los siguientes formatos de imagen exigidos por la AEAT:
  - [x] PDF/A (ISO 19005)
    - Generación básica desde la app: PDF 1.4 con fuentes incrustadas (Open Sans vía PdfGoogleFonts). Sin cifrado ni elementos interactivos.
    - Nota: Validación PDF/A completa (XMP + OutputIntent/ICC) pendiente de integrar con herramienta externa (p.ej., veraPDF) o servicio backend de normalización.
  - [ ] PNG
  - [ ] JPEG 2000
  - [ ] TIFF 6.0
  - [ ] PDF 1.4+ con compresión sin pérdida
- [ ] Asegurar que la digitalización mantenga una resolución mínima de 200 ppp en B/N, color o escala de grises.
- [ ] Generar un fichero por factura con sus metadatos (referencia de homologación, marca de tiempo, nombre y versión del software en XMP).
- [ ] Firmar electrónicamente cada fichero de imagen con algoritmos seguros (mínimo SHA-1, recomendado SHA-256 o superior).
- [ ] Mantener una base de datos firmada con acceso completo, consultas online por campos de libros IVA y opciones de descarga e impresión sin demora.

### Checklist de tareas externas (no relacionadas directamente con la app)
- [ ] Presentar la solicitud dirigida al Director del Departamento de Informática Tributaria (procedimiento FZ01) dentro del plazo legal de seis meses.
- [ ] Preparar y presentar la declaración responsable de cumplimiento de la Orden EHA/962/2007 y la Resolución de 24/10/2007.
- [ ] Entregar la documentación técnica del sistema (normas, protocolos, seguridad, control, explotación, diseño de BBDD y sistema de firma electrónica).
- [ ] Elaborar y mantener un Plan de Gestión de Calidad (mantenimiento preventivo, pruebas rutinarias, control de dispositivos y reglas de mantenimiento de la BBDD).
- [ ] Obtener un informe de auditoría informática independiente que certifique el cumplimiento de la Orden y la Resolución.
- [ ] Entregar el software y toda la documentación en soporte digital junto a la solicitud (según ficha del procedimiento).
- [ ] Presupuestar y contratar la auditoría informática independiente obligatoria.
- [ ] Prever costes de desarrollo/adecuación del software, certificados cualificados, sellado de tiempo y mantenimiento del Plan de Calidad.
