# GESTR
AplicaciÃ³n Flutter para la gestiÃ³n de ingresos y gastos de autÃ³nomos y pymes. EstÃ¡ orientada al empresario o profesional independiente, sin modos separados para empleados o administradores. El objetivo es ofrecer una experiencia altamente automatizada y modular, permitiendo que cada negocio adapte la app a sus necesidades especÃ­ficas.

## KPIs
- **Gastos automatizados**: porcentaje de gastos capturados mediante escaneo o integraciÃ³n bancaria.
- **Tiempo de registro**: tiempo promedio que un usuario tarda en registrar un gasto.
- **Usuarios activos mensuales**: cantidad de cuentas con actividad cada mes.
- **Integraciones bancarias**: nÃºmero de cuentas bancarias conectadas.
- **MÃ³dulos activos por usuario**: promedio de mÃ³dulos habilitados por tipo de negocio.

## Roadmap
. **AutomatizaciÃ³n de ingresos** mediante conexiÃ³n directa con cuentas bancarias.
2. **DigitalizaciÃ³n integral de gastos** con captura OCR, archivo probatorio y clasificaciÃ³n automÃ¡tica.
3. **MÃ³dulos opcionales** para gestionar clientes, proveedores, productos, servicios, citas, empleados y suscripciones.
4. **Integraciones externas** con software de contabilidad y ERPs mediante API y exportaciones estÃ¡ndar.
5. **Soporte multiplataforma** con aplicaciones mÃ³viles y web sincronizadas.

## Insights de la competencia (N2F)
N2F se orienta a organizaciones con mÃºltiples usuarios (empleados y administradores). Aunque GESTR se centra en el empresario, estas funcionalidades sirven de referencia:
- Escaneo inteligente de recibos y extracciÃ³n automÃ¡tica de datos (fecha, monto, impuestos, moneda).
- Archivo digital con valor probatorio para eliminar el papel.
- GestiÃ³n automÃ¡tica de facturas de proveedores recibidas por correo electrÃ³nico.
- Flujos de aprobaciÃ³n personalizables y paneles para administradores, pensados para equipos con mÃºltiples roles.
- CÃ¡lculo automÃ¡tico de kilometraje e IVA recuperable.
- Exportaciones para contabilidad y reembolsos mediante archivos SEPA.
- Soporte multi-divisa y polÃ­ticas de gasto configurables.
- APIs y servicios web para integrarse con sistemas externos.

## Estado del proyecto
### Checklist de funcionalidades de la app

#### Implementadas
- [x] Arquitectura Flutter modular con capas `app`, `core`, `data` y `domain`.
- [x] Registro manual de ingresos y gastos.
- [x] Escaneo de facturas con OCR que extrae tÃ­tulo, importe, fecha, emisor, receptor y concepto.
- [x] MÃ³dulo de proveedores y productos.
- [x] MÃ³dulo de clientes.
- [x] ConciliaciÃ³n bancaria manual con vinculaciÃ³n de movimientos importados.
- [x] GeneraciÃ³n y comparticiÃ³n de comprobantes PDF con utilidades orientadas a PDF/A.

#### Pendientes
- [ ] MÃ³dulos/widgets de servicios, citas, empleados, analÃ­ticas, opciones, notificaciones y suscripciones.
- [ ] ConexiÃ³n bancaria automÃ¡tica para importar movimientos y comprobantes.
- [ ] Exportaciones contables e integraciÃ³n con ERPs.

- [ ] Panel de KPIs en tiempo real y widgets totalmente configurables.
- [ ] Sistema de suscripciones para activar mÃ³dulos avanzados.
- [ ] Alertas y recordatorios proactivos para gastos incompletos.
- [ ] AnÃ¡lisis predictivo de flujo de caja y recomendaciones.

## ValidaciÃ³n y normalizaciÃ³n PDF/A
- [x] Ejecuta `dart run tool/generate_sample_pdfs.dart` (o `flutter pub run tool/generate_sample_pdfs.dart` si solo estÃ¡ disponible Flutter) para generar comprobantes de ejemplo con los metadatos XMP solicitados al backend.
- [x] Lanza `tool/validate_pdfa.sh` para regenerar los PDFs de muestra y validarlos automÃ¡ticamente con [veraPDF](https://verapdf.org/) dentro de un contenedor Docker.
- [x] La acciÃ³n de GitHub `.github/workflows/pdfa-validate.yml` reutiliza estos scripts para garantizar que siempre exista una verificaciÃ³n PDF/A sin coste adicional durante los PR.

### Checklist de cumplimiento AEAT dentro de la app
- [x] Garantizar soporte en la app para los siguientes formatos de imagen exigidos por la AEAT:
  - [x] PDF/A (ISO 19005)
    - [x] GeneraciÃ³n bÃ¡sica desde la app: PDF 1.4 con fuentes incrustadas (Open Sans vÃ­a el helper `PdfGoogleFonts` de `printing`). Sin cifrado ni elementos interactivos.
    - [x] ValidaciÃ³n PDF/A completa (XMP + OutputIntent/ICC) cubierta mediante el script `tool/validate_pdfa.sh`, que genera comprobantes y los verifica con veraPDF en Docker.
    - [x] NormalizaciÃ³n opcional en backend mediante `PdfAUtils.maybeNormalizeOnBackend`, activada con la variable `PDFA_NORMALIZE_URL` para incrustar metadatos y perfiles ICC cuando estÃ©n disponibles.
  - [x] PNG
    - [x] ConversiÃ³n directa en cliente con `AeatImageSupport.generateAttachments`, que aÃ±ade las variantes PNG al flujo de comparticiÃ³n de facturas y pagos fijos.
  - [x] JPEG 2000
    - [x] Solicitud opcional al backend definido en `AEAT_JPEG2000_URL` para normalizar las imÃ¡genes a JP2 cuando se comparte documentaciÃ³n.
  - [x] TIFF 6.0
    - [x] ExportaciÃ³n local a TIFF 6.0 mediante el paquete `image` dentro de `AeatImageSupport`.
  - [x] PDF 1.4+ con compresiÃ³n sin pÃ©rdida
    - [x] GeneraciÃ³n automÃ¡tica de PDF 1.4 con compresiÃ³n Flate (lossless) para cada comprobante gracias a `AeatImageSupport`.
  - [x] ConservaciÃ³n de formatos originales al subir comprobantes a Firebase Storage, reutilizando la extensiÃ³n y tipo MIME detectados en los repositorios de facturas y pagos fijos.
- [x] Asegurar que la digitalizaciÃ³n mantenga una resoluciÃ³n mÃ­nima de 200 ppp en B/N, color o escala de grises.
- [x] Generar un fichero por factura con sus metadatos
### Plan de firma y almacenamiento
- [ ] Firma electronica por fichero: certificados cualificados (FNMT u otra AC cualificada eIDAS), algoritmo min. SHA-256, sellado de tiempo cualificado (TSA RFC 3161).
- [ ] Formato de firma: PAdES-BES/LTV para PDF; CAdES/XAdES para ficheros no PDF (imágenes/XML) si aplica.
- [ ] Politica de formatos: en app se genera PDF 1.4; en servidor se normaliza opcionalmente a PDF/A (si PDFA_NORMALIZE_URL esta activo) y ese sera el formato oficial a conservar y firmar.
- [ ] Base de datos firmada: huella por registro (hash de campos clave), log apend-only con encadenado (hash del anterior) y sellado periodico; exportables para auditoria.

### Registro de digitalizacion y procedimientos
- [ ] Registro minimo por factura: numero, fecha, emisor (nombre/NIF), receptor (nombre/NIF), base imponible, tipo IVA, cuota IVA, total, referencia de homologacion, usuario y marca de tiempo de digitalizacion.
- [ ] Trazabilidad y logs: altas, consultas, modificaciones, exportaciones y regeneraciones con usuario/fecha y hash del estado.
- [ ] Operacion: calibracion y control de calidad de escaner (muestras por lote), politica de copias de seguridad/restauracion, y control de acceso/roles (evitar alteraciones manuales de imagenes firmadas). (referencia de homologaciÃ³n, marca de tiempo, nombre y versiÃ³n del software en XMP).
- [ ] Firmar electrÃ³nicamente cada fichero de imagen con algoritmos seguros (mÃ­nimo SHA-1, recomendado SHA-256 o superior).
- [ ] Mantener una base de datos firmada con acceso completo, consultas online por campos de libros IVA y opciones de descarga e impresiÃ³n sin demora.

### Checklist de tareas externas (no relacionadas directamente con la app)
- [ ] Presentar la solicitud dirigida al Director del Departamento de InformÃ¡tica Tributaria (procedimiento FZ01) dentro del plazo legal de seis meses.
- [ ] Preparar y presentar la declaraciÃ³n responsable de cumplimiento de la Orden EHA/962/2007 y la ResoluciÃ³n de 24/10/2007.
- [ ] Entregar la documentaciÃ³n tÃ©cnica del sistema (normas, protocolos, seguridad, control, explotaciÃ³n, diseÃ±o de BBDD y sistema de firma electrÃ³nica).
- [ ] Elaborar y mantener un Plan de GestiÃ³n de Calidad (mantenimiento preventivo, pruebas rutinarias, control de dispositivos y reglas de mantenimiento de la BBDD).
- [ ] Obtener un informe de auditorÃ­a informÃ¡tica independiente que certifique el cumplimiento de la Orden y la ResoluciÃ³n.
- [ ] Entregar el software y toda la documentaciÃ³n en soporte digital junto a la solicitud (segÃºn ficha del procedimiento).
- [ ] Presupuestar y contratar la auditorÃ­a informÃ¡tica independiente obligatoria.
- [ ] Prever costes de desarrollo/adecuaciÃ³n del software, certificados cualificados, sellado de tiempo y mantenimiento del Plan de Calidad.

