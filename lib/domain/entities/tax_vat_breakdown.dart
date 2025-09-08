class VatBreakdown {
  final double base21;
  final double iva21;
  final double base10;
  final double iva10;
  final double base4;
  final double iva4;
  final double base0; // exentas/0%

  const VatBreakdown({
    this.base21 = 0,
    this.iva21 = 0,
    this.base10 = 0,
    this.iva10 = 0,
    this.base4 = 0,
    this.iva4 = 0,
    this.base0 = 0,
  });

  double get totalBase => base21 + base10 + base4 + base0;
  double get totalIva => iva21 + iva10 + iva4;
}

