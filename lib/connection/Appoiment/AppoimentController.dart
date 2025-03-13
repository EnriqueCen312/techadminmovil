import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppointmentsController {
  final SupabaseClient supabase = Supabase.instance.client;

  // Stream controller para citas
  final _appointmentsStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
  Stream<List<Map<String, dynamic>>> get appointmentsStream => _appointmentsStreamController.stream;

  // Obtener auth ID del usuario autenticado
  Future<int?> _getAuthId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      
      if (userJson != null) {
        final Map<String, dynamic> user = jsonDecode(userJson);
        return user['id'];
      }
      
      return null;
    } catch (e) {
      print('Error obteniendo auth_id: $e');
      return null;
    }
  }

  // Obtener citas del usuario autenticado
  Future<List<Map<String, dynamic>>> fetchAppointments() async {
    try {
      final authId = await _getAuthId();
      if (authId == null) {
        throw Exception('No se encontró usuario autenticado');
      }

      final response = await supabase.from('citas').select('''
            id, 
            fecha, 
            hora, 
            estado, 
            descripcion,
            vehiculos:automovil_id (
              id, 
              marca, 
              modelo, 
              placa
            ),
            talleres:taller_id (
              nombre
            )
          ''').eq('auth_id', authId).order('fecha', ascending: true);

      final List<Map<String, dynamic>> formattedResponse = response.map((item) {
        final vehicleInfo = item['vehiculos'] as Map<String, dynamic>;
        final tallerInfo = item['talleres'] as Map<String, dynamic>;
        return {
          'id': item['id'],
          'fecha': item['fecha'],
          'hora': item['hora'],
          'estado': item['estado'] ?? 'pendiente',
          'descripcion': item['descripcion'] ?? 'Sin descripción',
          'vehiculo': '${vehicleInfo['marca']} ${vehicleInfo['modelo']} - ${vehicleInfo['placa']}',
          'taller': tallerInfo['nombre'],
          'automovil_id': vehicleInfo['id'],
        };
      }).toList();

      // Emitir citas al stream
      _appointmentsStreamController.add(formattedResponse);
      return formattedResponse;
    } catch (e) {
      print('Error al obtener las citas: $e');
      throw Exception('Error al obtener las citas: $e');
    }
  }

  // Actualizar el estado de una cita
  Future<bool> updateAppointmentStatus(int appointmentId, String status) async {
    try {
      await supabase.from('citas').update({
        'estado': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', appointmentId);
      
      await fetchAppointments(); // Refrescar citas
      return true;
    } catch (e) {
      print('Error al actualizar el estado de la cita: $e');
      return false;
    }
  }

  // Obtener vehículos del usuario
  Future<List<Map<String, dynamic>>> getUserVehicles() async {
    try {
      final authId = await _getAuthId();
      if (authId == null) {
        throw Exception('No se encontró usuario autenticado');
      }
      final response = await supabase.from('vehiculos').select('id, marca, modelo, placa').eq('auth_id', authId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error al obtener los vehículos: $e');
      throw Exception('Error al obtener los vehículos: $e');
    }
  }

  // Obtener talleres disponibles
  Future<List<Map<String, dynamic>>> getWorkshops() async {
    try {
      final response = await supabase.from('talleres').select('id, nombre, direccion');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error al obtener los talleres: $e');
      throw Exception('Error al obtener los talleres: $e');
    }
  }

  // Configurar un timer para verificar actualizaciones periódicas
  Timer? _updateTimer;
  void startPeriodicUpdates([Duration duration = const Duration(seconds: 30)]) {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(duration, (_) => fetchAppointments());
  }
  void stopPeriodicUpdates() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  // Liberar recursos
  void dispose() {
    stopPeriodicUpdates();
    _appointmentsStreamController.close();
  }
}
