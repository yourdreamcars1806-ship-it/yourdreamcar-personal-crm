/// Bundled image paths (see [pubspec.yaml] `flutter.assets`).
abstract final class AppAssets {
  static const String logo = 'assets/images/ydc_logo.png';
  static const String logoRound = 'assets/images/ydc_logo_round.png';
  static const String favicon = 'assets/images/ydc_app_icon.png';
  static const String sampleCarListing = 'assets/images/sample_car_listing.png';

  static const List<String> splashCars = [
    'assets/images/splash_car_sedan.png',
    'assets/images/splash_car_suv.png',
    'assets/images/splash_car_sports.png',
    'assets/images/splash_car_hatch.png',
    'assets/images/splash_car_luxury.png',
  ];
}
