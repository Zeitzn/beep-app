import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/route_model.dart';

class StorageService {
  static const _key = 'routes';
  static const _currentRouteKey = 'current_route';

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

  Future<void> saveCurrentRoute(RouteModel route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentRouteKey, jsonEncode(route.toJson()));
  }

  Future<RouteModel?> loadCurrentRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_currentRouteKey);
    if (jsonString == null) return null;
    return RouteModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  Future<void> clearCurrentRoute() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentRouteKey);
  }
}