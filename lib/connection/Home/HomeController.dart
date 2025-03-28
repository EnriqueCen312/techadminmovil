import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HomeController {
  final SupabaseClient supabase;
  List<Map<String, dynamic>> workshops = [];
  List<Map<String, dynamic>> _filteredWorkshops = []; // Added property
  bool _isFiltering = false; // Added property
  bool isBooking = false;
  Map<String, dynamic>? selectedWorkshop;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? selectedVehicle;
  String? appointmentDescription;
  List<TimeOfDay> availableTimeSlots = [];
  
  // Constructor that initializes Supabase client
  HomeController() : supabase = Supabase.instance.client {
    fetchWorkshops();
  }
  
/*  Future<void> fetchWorkshops() async {
    try {
      final response = await supabase
        .from('talleres')
        .select()
        .or('id.eq.103,id.neq.103')
        .limit(10);

      workshops = List<Map<String, dynamic>>.from(response);
      _filteredWorkshops = List.from(workshops); // Initialize filtered list
      _isFiltering = false; // Reset filtering flag
      return;
    } catch (error) {
      print('Error fetching workshops: $error');
      throw Exception('Failed to fetch workshops');
    }
  }
*/
Future<void> fetchWorkshops() async {
  try {
    // Obtener los primeros 9 talleres
    final firstNineResponse = await supabase
        .from('talleres')
        .select()
        .limit(9);

    // Obtener el taller con id = 103
    final workshop103Response = await supabase
        .from('talleres')
        .select()
        .eq('id', 103)
        .limit(1);

    // Combinar ambos resultados
    workshops = List<Map<String, dynamic>>.from(firstNineResponse);
    workshops.addAll(workshop103Response);

    // Inicializar la lista filtrada
    _filteredWorkshops = List.from(workshops);

    // Resetear la bandera de filtrado
    _isFiltering = false;
    
    return;
  } catch (error) {
    print('Error fetching workshops: $error');
    throw Exception('Failed to fetch workshops');
  }
}

  // Get the workshops that should be displayed (either filtered or all)
  List<Map<String, dynamic>> getDisplayedWorkshops() {
    return _isFiltering ? _filteredWorkshops : workshops;
  }
  
  // Filter workshops based on a predicate function
  void filterWorkshops(bool Function(Map<String, dynamic>) predicate) {
    _filteredWorkshops = workshops.where(predicate).toList();
    _isFiltering = true;
  }
  
  // Reset to show all workshops
  void resetFilters() {
    _filteredWorkshops = List.from(workshops);
    _isFiltering = false;
  }

  Future<int?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      if (userJson != null) {
        final Map<String, dynamic> user = jsonDecode(userJson);
        return user['id'];
      }
      return null;
    } catch (e) {
      print('Error al obtener el ID: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserVehicles(int userId) async {
    final response = await supabase.from('vehiculos').select().eq('usuario_app_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> bookAppointment(BuildContext context) async {
    final userId = await getUserId();
    if (userId != null && selectedDate != null && selectedTime != null && 
        selectedVehicle != null && appointmentDescription != null) {
      try {
        final response = await supabase.from('citas').insert([
          {
            'automovil_id': selectedVehicle,
            'fecha': selectedDate?.toIso8601String(),
            'hora': selectedTime?.format(context),
            'auth_id': userId,
            'taller_id': selectedWorkshop!['id'],
            'estado': 'pendiente',
            'descripcion': appointmentDescription,
          },
        ]);
        
        return {'success': true, 'response': response};
      } catch (e) {
        print('Exception al agendar la cita: $e');
        return {'success': false, 'error': e.toString()};
      }
    } else {
      return {'success': false, 'error': 'Datos incompletos'};
    }
  }

  void generateAvailableTimeSlots() {
    if (selectedDate == null || selectedWorkshop == null) return;
    
    // Parse workshop opening and closing times
    final String opensStr = selectedWorkshop!['abre'] ?? '08:00:00';
    final String closesStr = selectedWorkshop!['cierra'] ?? '18:00:00';
    final int intervalMinutes = selectedWorkshop!['intervalo_minutes'] ?? 30;
    
    final TimeOfDay opens = parseTimeString(opensStr);
    final TimeOfDay closes = parseTimeString(closesStr);
    
    List<TimeOfDay> slots = [];
    
    int currentHour = opens.hour;
    int currentMinute = opens.minute;
    
    while (true) {
      final TimeOfDay timeSlot = TimeOfDay(hour: currentHour, minute: currentMinute);
      slots.add(timeSlot);
      
      currentMinute += intervalMinutes;
      if (currentMinute >= 60) {
        currentHour += currentMinute ~/ 60;
        currentMinute = currentMinute % 60;
      }
      
      if (timeOfDayToMinutes(TimeOfDay(hour: currentHour, minute: currentMinute)) >= timeOfDayToMinutes(closes)) {
        break;
      }
    }
    
    availableTimeSlots = slots;
    
    if (selectedTime != null && !isTimeInSlots(selectedTime!, slots)) {
      selectedTime = null;
    }
  }

  TimeOfDay parseTimeString(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  int timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  bool isTimeInSlots(TimeOfDay time, List<TimeOfDay> slots) {
    final timeMinutes = timeOfDayToMinutes(time);
    return slots.any((slot) => timeOfDayToMinutes(slot) == timeMinutes);
  }
  
  void resetBookingData() {
    isBooking = true;
    selectedDate = null;
    selectedTime = null;
    selectedVehicle = null;
    appointmentDescription = null;
    availableTimeSlots = [];
  }
  
  void selectWorkshop(Map<String, dynamic> workshop) {
    selectedWorkshop = workshop;
    resetBookingData();
  }
  
  void selectDate(DateTime date) {
    selectedDate = date;
    selectedTime = null;
    generateAvailableTimeSlots();
  }
  
  void selectTime(TimeOfDay time) {
    selectedTime = time;
  }
  
  void setVehicle(String vehicleId) {
    selectedVehicle = vehicleId;
  }
  
  void setAppointmentDescription(String description) {
    appointmentDescription = description;
  }
}
