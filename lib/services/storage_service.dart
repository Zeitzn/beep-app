import 'package:shared_preferences/shared_preferences.dart';
import '../models/route_model.dart';

class StorageService {
  static const _key = 'routes';

  Future<void> saveRoutes(List<RouteModel> routes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, RouteModel.listToJson(routes));
  }

  Future<List<RouteModel>> loadRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];
    return RouteModel.listFromJson(jsonString);
  }
}
