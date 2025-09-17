import 'dart:convert';

import 'package:gestr/core/config/compliance_constants.dart';

/// Builds an XMP metadata packet that satisfies the AEAT requirements for
/// digital invoices.
String buildAeatXmp({
  required String title,
  required String author,
  required String docId,
  String? homologationRef,
  DateTime? timestamp,
  String? softwareName,
  String? softwareVersion,
}) {
  final resolvedTimestamp = (timestamp ?? DateTime.now()).toUtc();
  final isoTimestamp = resolvedTimestamp.toIso8601String();
  final htmlEscape = const HtmlEscape();

  final escapedTitle = htmlEscape.convert(title);
  final escapedAuthor = htmlEscape.convert(author);
  final escapedDocId = htmlEscape.convert(docId);
  final resolvedHomologation =
      (homologationRef != null && homologationRef.isNotEmpty)
          ? homologationRef
          : ComplianceConstants.homologationReference;
  final escapedHomologation = htmlEscape.convert(resolvedHomologation);
  final resolvedSoftwareName =
      (softwareName != null && softwareName.isNotEmpty)
          ? softwareName
          : ComplianceConstants.softwareName;
  final escapedSoftwareName = htmlEscape.convert(resolvedSoftwareName);
  final resolvedSoftwareVersion =
      (softwareVersion != null && softwareVersion.isNotEmpty)
          ? softwareVersion
          : ComplianceConstants.softwareVersion;
  final escapedSoftwareVersion = htmlEscape.convert(resolvedSoftwareVersion);

  return '''<?xpacket begin='\ufeff' id='$escapedDocId'?>
<x:xmpmeta xmlns:x='adobe:ns:meta/'>
  <rdf:RDF xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'>
    <rdf:Description rdf:about=''
      xmlns:dc='http://purl.org/dc/elements/1.1/'
      xmlns:pdf='http://ns.adobe.com/pdf/1.3/'
      xmlns:xmp='http://ns.adobe.com/xap/1.0/'
      xmlns:pdfaid='http://www.aiim.org/pdfa/ns/id/'
      xmlns:gestr='https://gestr.app/ns/aeat/1.0/'>
      <dc:title><rdf:Alt><rdf:li xml:lang='x-default'>$escapedTitle</rdf:li></rdf:Alt></dc:title>
      <dc:creator><rdf:Seq><rdf:li>$escapedAuthor</rdf:li></rdf:Seq></dc:creator>
      <pdf:Producer>$escapedSoftwareName</pdf:Producer>
      <xmp:CreateDate>$isoTimestamp</xmp:CreateDate>
      <xmp:ModifyDate>$isoTimestamp</xmp:ModifyDate>
      <pdfaid:part>1</pdfaid:part>
      <pdfaid:conformance>B</pdfaid:conformance>
      <gestr:HomologationRef>$escapedHomologation</gestr:HomologationRef>
      <gestr:Timestamp>$isoTimestamp</gestr:Timestamp>
      <gestr:SoftwareName>$escapedSoftwareName</gestr:SoftwareName>
      <gestr:SoftwareVersion>$escapedSoftwareVersion</gestr:SoftwareVersion>
    </rdf:Description>
    <rdf:Description rdf:about=''
      xmlns:pdfaExtension='http://www.aiim.org/pdfa/ns/extension/'
      xmlns:pdfaSchema='http://www.aiim.org/pdfa/ns/schema#'
      xmlns:pdfaProperty='http://www.aiim.org/pdfa/ns/property#'>
      <pdfaExtension:schemas>
        <rdf:Bag>
          <rdf:li rdf:parseType='Resource'>
            <pdfaSchema:schema>Gestr AEAT Metadata</pdfaSchema:schema>
            <pdfaSchema:namespaceURI>https://gestr.app/ns/aeat/1.0/</pdfaSchema:namespaceURI>
            <pdfaSchema:prefix>gestr</pdfaSchema:prefix>
            <pdfaSchema:property>
              <rdf:Seq>
                <rdf:li rdf:parseType='Resource'>
                  <pdfaProperty:name>HomologationRef</pdfaProperty:name>
                  <pdfaProperty:valueType>Text</pdfaProperty:valueType>
                  <pdfaProperty:category>external</pdfaProperty:category>
                  <pdfaProperty:description>AEAT homologation reference identifier.</pdfaProperty:description>
                </rdf:li>
                <rdf:li rdf:parseType='Resource'>
                  <pdfaProperty:name>Timestamp</pdfaProperty:name>
                  <pdfaProperty:valueType>Date</pdfaProperty:valueType>
                  <pdfaProperty:category>external</pdfaProperty:category>
                  <pdfaProperty:description>UTC timestamp recording when the document metadata was generated.</pdfaProperty:description>
                </rdf:li>
                <rdf:li rdf:parseType='Resource'>
                  <pdfaProperty:name>SoftwareName</pdfaProperty:name>
                  <pdfaProperty:valueType>Text</pdfaProperty:valueType>
                  <pdfaProperty:category>external</pdfaProperty:category>
                  <pdfaProperty:description>Name of the software producing the document.</pdfaProperty:description>
                </rdf:li>
                <rdf:li rdf:parseType='Resource'>
                  <pdfaProperty:name>SoftwareVersion</pdfaProperty:name>
                  <pdfaProperty:valueType>Text</pdfaProperty:valueType>
                  <pdfaProperty:category>external</pdfaProperty:category>
                  <pdfaProperty:description>Version of the software producing the document.</pdfaProperty:description>
                </rdf:li>
              </rdf:Seq>
            </pdfaSchema:property>
          </rdf:li>
        </rdf:Bag>
      </pdfaExtension:schemas>
    </rdf:Description>
  </rdf:RDF>
</x:xmpmeta>
<?xpacket end='w'?>''';
}
