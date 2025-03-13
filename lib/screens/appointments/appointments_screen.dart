import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // Importación necesaria para StreamSubscription
import 'package:login_register_app/connection/Appoiment/AppoimentController.dart';
import 'package:login_register_app/values/app_routes.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final AppointmentsController _appointmentsController = AppointmentsController();
  List<Map<String, dynamic>> appointments = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  
  // Stream subscription para escuchar cambios en las citas
  StreamSubscription<List<Map<String, dynamic>>>? _appointmentsSubscription;
  
  void goToHome() {
    Navigator.pushReplacementNamed(context, AppRoutes.homePage); 
  }

  @override
  void initState() {
    super.initState();
    _loadAppointments();
    // Suscribirse a actualizaciones de estado
    _subscribeToAppointmentUpdates();
    // Iniciar actualizaciones periódicas
    _appointmentsController.startPeriodicUpdates();
  }
  
  @override
  void dispose() {
    // Cancelar la suscripción cuando se destruye el widget
    _appointmentsSubscription?.cancel();
    // Asegurarse de liberar los recursos del controlador
    _appointmentsController.dispose();
    super.dispose();
  }
  
  // Método para suscribirse a actualizaciones de estado
  void _subscribeToAppointmentUpdates() {
    _appointmentsSubscription = _appointmentsController.appointmentsStream.listen((updatedAppointments) {
      if (mounted) {
        setState(() {
          appointments = updatedAppointments;
        });
      }
    });
  }
  
  Future<void> _loadAppointments() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final fetchedAppointments = await _appointmentsController.fetchAppointments();
      if (mounted) {
        setState(() {
          appointments = fetchedAppointments;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error al cargar las citas: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Método para actualizar manualmente el estado si es necesario
  Future<void> _refreshAppointments() async {
    return _loadAppointments();
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
                'Mis',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ' Citas',
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
              onPressed: _refreshAppointments,
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
          onRefresh: _refreshAppointments,
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
    
    if (appointments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No tienes citas programadas',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: appointments.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _buildAppointmentCard(appointment);
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final String status = appointment['estado'] ?? 'pendiente';
    
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

    // Colores según el estado
    Color statusColor;
    Color statusBackgroundColor;
    
    switch(status.toLowerCase()) {
      case 'pendiente':
        statusColor = Colors.amber[800]!;
        statusBackgroundColor = Colors.amber.withOpacity(0.2);
        break;
      case 'aceptada':
      case 'confirmada':
        statusColor = Colors.green[800]!;
        statusBackgroundColor = Colors.green.withOpacity(0.2);
        break;
      case 'terminada':
        statusColor = const Color.fromARGB(255, 40, 69, 198);
          statusBackgroundColor = const Color.fromARGB(255, 54, 73, 244).withOpacity(0.2);
      case 'rechazada':
      case 'cancelada':
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