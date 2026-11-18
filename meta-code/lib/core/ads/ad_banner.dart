// En web no se compila el plugin de AdMob, que solo existe para móvil.
export 'ad_banner_stub.dart' if (dart.library.io) 'ad_banner_mobile.dart';
