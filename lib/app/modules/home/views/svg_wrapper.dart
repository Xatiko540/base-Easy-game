class SvgWrapper {
  final String rawSvg;

  SvgWrapper(this.rawSvg);

  Future<String?> generateLogo() async {
    try {
      return rawSvg;
    } catch (e) {
      return null;
    }
  }
}
