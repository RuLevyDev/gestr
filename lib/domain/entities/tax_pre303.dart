class Pre303Summary {
  final double base21;
  final double iva21;
  final double base10;
  final double iva10;
  final double base4;
  final double iva4;
  final double base0;
  final double totalDevengadoBase;
  final double totalDevengadoIva;
  final double totalSoportadoIva; // IVA soportado deducible bruto (antes de prorrata)

  // Prorrata estimada (0..1) y soportado ajustado
  final double prorrata;
  final double soportadoAjustado;

  const Pre303Summary({
    this.base21 = 0,
    this.iva21 = 0,
    this.base10 = 0,
    this.iva10 = 0,
    this.base4 = 0,
    this.iva4 = 0,
    this.base0 = 0,
    this.totalDevengadoBase = 0,
    this.totalDevengadoIva = 0,
    this.totalSoportadoIva = 0,
    this.prorrata = 1.0,
    this.soportadoAjustado = 0,
  });

  double get resultado => totalDevengadoIva - soportadoAjustado;
  double get prorrataPct => prorrata * 100.0;
  double get ajusteProrrata => totalSoportadoIva - soportadoAjustado;
}
