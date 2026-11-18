import 'package:material_ui/material_ui.dart';

Future<void> initAds() async {}

/// En web todavía no se muestran anuncios.
class AdBanner extends StatelessWidget {
  const AdBanner({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
