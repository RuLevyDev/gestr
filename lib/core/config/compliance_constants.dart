/// Constants and environment-driven values required to comply with AEAT
/// digital bookkeeping rules.
class ComplianceConstants {
  const ComplianceConstants._();

  /// Homologation reference provided by the AEAT.
  static const String homologationReference = String.fromEnvironment(
    'AEAT_HOMOLOGATION_REF',
    defaultValue: 'AEAT-HOMOLOGATION-PENDING',
  );

  /// Software name reported inside generated XMP metadata.
  static const String softwareName = String.fromEnvironment(
    'GESTR_SOFTWARE_NAME',
    defaultValue: 'Gestr App',
  );

  /// Software version reported inside generated XMP metadata.
  static const String softwareVersion = String.fromEnvironment(
    'GESTR_SOFTWARE_VERSION',
    defaultValue: '1.0.0',
  );
}
