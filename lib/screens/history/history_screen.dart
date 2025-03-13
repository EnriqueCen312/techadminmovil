import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../connection/auth/AuthController.dart';
import 'package:login_register_app/values/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _authController = AuthController();
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> historyAppointments = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  
  void goToHome() {
    Navigator.pushReplacementNamed(context, AppRoutes.homePage);
  }

  @override
  void initState() {
    super.initState();
    _loadHistoryAppointments();
  }
  
  Future<void> _loadHistoryAppointments() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Obtener el ID del usuario actual
      final userId = await _authController.getUserId();
      
      if (userId == null) {
        // Si no hay usuario autenticado, redirigir al login
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }
      
      // Consultar el historial de citas del usuario
      final response = await supabase
          .from('historial_citas')
          .select('''
            *,
            vehiculos:automovil_id (marca, modelo, ano, placa),
            talleres:taller_id (nombre, direccion)
          ''')
          .eq('auth_id', userId)
          .order('fecha', ascending: false)
          .order('hora', ascending: false);
      
      if (mounted) {
        setState(() {
          // Transformar los datos para que coincidan con el formato esperado
          historyAppointments = response.map<Map<String, dynamic>>((item) {
            return {
              'id': item['id'],
              'fecha': item['fecha'],
              'hora': item['hora'],
              'estado': item['estado'],
              'descripcion': item['descripcion'] ?? 'Sin descripción',
              'vehiculo': item['vehiculos'] != null 
                ? '${item['vehiculos']['marca']} ${item['vehiculos']['modelo']} (${item['vehiculos']['ano']}) - ${item['vehiculos']['placa']}'
                : 'Vehículo no especificado',
              'taller': item['talleres'] != null 
                ? item['talleres']['nombre']
                : 'Taller no especificado',
            };
          }).toList();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error al cargar el historial de citas: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _refreshHistoryAppointments() async {
    return _loadHistoryAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        
        Navigator.pushReplacementNamed(context, AppRoutes.homePage);
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Mi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ' Historial',
                style: TextStyle(
                  color: Colors.orange.shade500,
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue.shade900,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refreshHistoryAppointments,
            ),
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
            ),
          ],
        ),
        endDrawer: SizedBox(
          width: MediaQuery.of(context).size.width * 0.7,
          height: MediaQuery.of(context).size.height,
          child: Drawer(
            child: Container(
              color: Colors.blue.shade900,
              child: Column(
                children: [
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Tech',
                                  style: TextStyle(
                                    color: Colors.orange.shade500,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Administrator',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Divider(color: Colors.white.withOpacity(0.3)),
                  ListTile(
                    leading: const Icon(Icons.settings, color: Colors.white),
                    title: const Text('Configuración', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(child: Container()),
                  Divider(color: Colors.white.withOpacity(0.3)),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.white),
                    title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
                    onTap: () async {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _refreshHistoryAppointments,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (historyAppointments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No tienes citas en el historial',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: historyAppointments.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final appointment = historyAppointments[index];
        return _buildHistoryCard(appointment);
      },
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> appointment) {
    final String status = appointment['estado'] ?? 'completada';
    
    // Format date and time for display
    String formattedDate = appointment['fecha'] ?? 'Fecha no disponible';
    String formattedTime = appointment['hora'] ?? 'Hora no disponible';
    
    // Convert fecha format if needed
    try {
      final DateTime date = DateTime.parse(appointment['fecha']);
      formattedDate = DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      // Use original format if parsing fails
    }
    
    // Convert hora format if needed
    try {
      if (appointment['hora'] != null && appointment['hora'].contains(':')) {
        final parts = appointment['hora'].split(':');
        final TimeOfDay time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        formattedTime = time.format(context);
      }
    } catch (e) {
      // Use original format if parsing fails
    }
    
    final String vehicleInfo = appointment['vehiculo'] ?? 'Vehículo no especificado';
    final String description = appointment['descripcion'] ?? 'Sin descripción';
    final String workshopName = appointment['taller'] ?? 'Taller no especificado';

    // Colores según el estado (mayormente serán terminadas o completadas)
    Color statusColor;
    Color statusBackgroundColor;
    
    switch(status.toLowerCase()) {
      case 'completada':
      case 'terminada':
        statusColor = Colors.green[800]!;
        statusBackgroundColor = Colors.green.withOpacity(0.2);
        break;
      case 'cancelada':
      case 'rechazada':
        statusColor = Colors.red[800]!;
        statusBackgroundColor = Colors.red.withOpacity(0.2);
        break;
      default:
        statusColor = Colors.grey[800]!;
        statusBackgroundColor = Colors.grey.withOpacity(0.2);
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedDate,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      formattedTime,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBackgroundColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Workshop
            Row(
              children: [
                const Icon(Icons.business, color: Colors.blueAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    workshopName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Vehicle info
            Row(
              children: [
                const Icon(Icons.directions_car, color: Colors.blueAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    vehicleInfo,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Description
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.description, color: Colors.blueAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}