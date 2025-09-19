class Client {
  final String? id;
  final String name;
  final String? email;
  final String? phone;
  final String? taxId;
  final String? fiscalAddress;
  final String? countryCode; // ISO-3166-1 alpha-2 (e.g., ES)
  final String? idType; // e.g., NIF, NIE, VAT, OTHER

  const Client({
    this.id,
    required this.name,
    this.email,
    this.phone,
    this.taxId,
    this.fiscalAddress,
    this.countryCode,
    this.idType,
  });
}
