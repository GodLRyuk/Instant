import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

Future<Map<String, String>> getCurrentAddress() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception("Location services are disabled");
  }

  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception("Location permissions are permanently denied");
  }

  Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  List<Placemark> placemarks = await placemarkFromCoordinates(
    position.latitude,
    position.longitude,
  );

  final place = placemarks.first;

  return {
    "fullAddress": "${place.street}, ${place.subLocality}, ${place.locality}",
    "city": place.locality ?? "",
    "state": place.administrativeArea ?? "",
    "pincode": place.postalCode ?? "",
    "lat": position.latitude.toString(), // ✅ NEW
    "lng": position.longitude.toString(),
  };
}
