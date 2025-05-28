import 'package:flutter_svg/svg.dart';

class Images {
  Images._();
  static final String assetName = 'assets/images/google_logo.svg';
  static final String logoMateMerge = 'assets/images/matemergelogo.png';
  static final googleLogoSvg = SvgPicture.asset(
    assetName,
    height: 30,
    semanticsLabel: 'Group logo',
  );
}
