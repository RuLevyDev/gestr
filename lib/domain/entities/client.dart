class Client {
  final String? id;
  final String name;
  final String? email;
  final String? phone;
  final String? taxId;
  final String? fiscalAddress;

  const Client({
    this.id,
    required this.name,
    this.email,
    this.phone,
    this.taxId,
    this.fiscalAddress,
  });
}
