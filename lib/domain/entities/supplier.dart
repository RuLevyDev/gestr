class Supplier {
  final String? id;
  final String name;
  final String? email;
  final String? phone;
  final String? taxId;
  final String? fiscalAddress;

  const Supplier({
    this.id,
    required this.name,
    this.email,
    this.phone,
    this.taxId,
    this.fiscalAddress,
  });
}
