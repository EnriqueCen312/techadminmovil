import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:login_register_app/connection/Home/HomeController.dart';
import '../../connection/auth/AuthController.dart';
import 'dart:convert';
import 'package:login_register_app/utils/helpers/snackbar_helper.dart';
import 'package:login_register_app/values/app_routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final HomeController controller;
  
  // Search and filter variables
  final TextEditingController searchController = TextEditingController();
  bool isSearchVisible = false;
  String? selectedFilter;
  List<String> filterOptions = ['Nombre', 'Dirección'];

  // Añade esta lista de imágenes al inicio de la clase
  final List<String> defaultImages = [
    'assets/images/1.jpg',
    'assets/images/2.jpg',
    'assets/images/3.jpg',
    'assets/images/4.jpg',
    'assets/images/5.jpg',
    'assets/images/descarga.jpeg',
  ];

  // Método auxiliar para obtener la imagen según el índice
  String getImageForIndex(int index) {
    return defaultImages[index % defaultImages.length];
  }

  @override
  void initState() {
    super.initState();
    controller = HomeController();
    _loadWorkshops();
    
    // Add listener to search controller
    searchController.addListener(() {
      _applySearch();
    });
  }
  
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadWorkshops() async {
    try {
      await controller.fetchWorkshops();
      setState(() {});
    } catch (error) {
      print('Error loading workshops: $error');
    }
  }
  
  // Search method to filter workshops based on search text and selected filter
  void _applySearch() {
    setState(() {
      if (searchController.text.isEmpty) {
        controller.resetFilters();
      } else {
        final searchText = searchController.text.toLowerCase();
        
        controller.filterWorkshops((workshop) {
          switch (selectedFilter) {
            case 'Dirección':
              return workshop['direccion'] != null && 
                     workshop['direccion'].toString().toLowerCase().contains(searchText);
            
            case 'Nombre':
            default:
              return workshop['nombre'] != null && 
                     workshop['nombre'].toString().toLowerCase().contains(searchText);
          }
        });
      }
    });
  }
  
  // Method to toggle search visibility
  void _toggleSearch() {
    setState(() {
      isSearchVisible = !isSearchVisible;
      if (!isSearchVisible) {
        searchController.clear();
        controller.resetFilters();
      }
    });
  }

  void _showBookingBottomSheet(Map<String, dynamic> workshop) async {
    setState(() {
      controller.selectWorkshop(workshop);
    });
    
    final userId = await controller.getUserId();
    if (userId != null) {
      final vehicles = await controller.fetchUserVehicles(userId);
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 10,
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // Workshop header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade900,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: workshop['imagenes'] != null && workshop['imagenes'].isNotEmpty
                                  ? Image.memory(
                                      base64Decode(workshop['imagenes'][0]),
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      'assets/images/descarga.jpeg',
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      workshop['nombre'] ?? 'Sin nombre',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      workshop['direccion'] ?? 'No disponible',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Abre: ${workshop['abre']?.toString().substring(0, 5) ?? '08:00'}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              Text(
                                'Cierra: ${workshop['cierra']?.toString().substring(0, 5) ?? '18:00'}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Booking form
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Información de la cita',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Vehicle selection
                            const Text(
                              'Seleccione su vehículo:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  hint: const Text('Seleccionar vehículo'),
                                  value: controller.selectedVehicle,
                                  onChanged: (value) {
                                    setSheetState(() {
                                      controller.setVehicle(value!);
                                    });
                                  },
                                  items: vehicles.map<DropdownMenuItem<String>>((vehicle) {
                                    return DropdownMenuItem<String>(
                                      value: vehicle['id'].toString(),
                                      child: Text('${vehicle['marca']} ${vehicle['modelo']} (${vehicle['placa']})'),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Date selection
                            const Text(
                              'Seleccione fecha:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: controller.selectedDate ?? DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 30)),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: Colors.blue.shade900,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                
                                if (pickedDate != null && pickedDate != controller.selectedDate) {
                                  setSheetState(() {
                                    controller.selectDate(pickedDate);
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      controller.selectedDate == null
                                          ? 'Seleccionar fecha'
                                          : '${controller.selectedDate!.day}/${controller.selectedDate!.month}/${controller.selectedDate!.year}',
                                      style: TextStyle(
                                        color: controller.selectedDate == null ? Colors.grey.shade600 : Colors.black,
                                      ),
                                    ),
                                    Icon(Icons.calendar_today, color: Colors.blue.shade900),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            const Text(
                              'Seleccione hora:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            if (controller.selectedDate == null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Seleccione una fecha primero'),
                              )
                            else if (controller.availableTimeSlots.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('No hay horarios disponibles'),
                              )
                            else
                              SizedBox(
                                height: 50,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: controller.availableTimeSlots.length,
                                  itemBuilder: (context, index) {
                                    final timeSlot = controller.availableTimeSlots[index];
                                    final isSelected = controller.selectedTime != null && 
                                        controller.selectedTime!.hour == timeSlot.hour && 
                                        controller.selectedTime!.minute == timeSlot.minute;
                                    
                                    return GestureDetector(
                                      onTap: () {
                                        setSheetState(() {
                                          controller.selectTime(timeSlot);
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.blue.shade900 : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isSelected ? Colors.blue.shade900 : Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Text(
                                          '${timeSlot.hour.toString().padLeft(2, '0')}:${timeSlot.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.black,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              
                            const SizedBox(height: 24),
                            
                            // Description field
                            const Text(
                              'Descripción del servicio:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Describa el servicio que necesita...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                              onChanged: (value) {
                                controller.setAppointmentDescription(value);
                              },
                            ),
                            
                            const SizedBox(height: 32),
                            
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final result = await controller.bookAppointment(context);
                                  if (result != null && result['success']) {
                                    Navigator.of(context).pop(); // Cierra el modal
                                    Navigator.pushReplacementNamed(context, AppRoutes.appointmentsPage);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(result?['error'] ?? 'Error al agendar la cita'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade900,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 2,
                                ),
                                child: const Text(
                                  'Solicitar cita',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }
  }

  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Column(
          children: [
            Icon(Icons.warning_amber_rounded, size: 50, color: Colors.orange),
            SizedBox(height: 10),
            Text(
              '¿Desea salir?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: const Text(
          '¿Está seguro que desea salir de la aplicación?',
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Salir'),
              ),
            ],
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        final shouldPop = await _showExitConfirmationDialog();
        
        if (shouldPop) {
          SystemNavigator.pop(); // This will close the app
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tech',
                style: TextStyle(
                  color: Colors.orange.shade500,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Administrator',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue.shade900,
          automaticallyImplyLeading: false, // Remove back button
          actions: [
            IconButton(
              icon: Icon(
                isSearchVisible ? Icons.close : Icons.search,
                color: Colors.white
              ),
              onPressed: _toggleSearch,
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
          width: MediaQuery.of(context).size.width * 0.7, // Ancho cuadrado
          height: MediaQuery.of(context).size.height, // Altura completa
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
                      // Aquí iría la lógica para la configuración (de momento vacía)
                    },
                  ),
                  Expanded(child: Container()), // Espacio vacío
                  Divider(color: Colors.white.withOpacity(0.3)),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.white),
                    title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
                    onTap: () async {
                      try{

                        final logOut = AuthController(); 
                        logOut.logout(context);  
                      
                      }catch(e){
                        SnackbarHelper.showSnackBar("Error al cerrar sesión $e");
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // Search bar (conditionally visible)
            if (isSearchVisible)
              Container(
                color: Colors.blue.shade800,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Buscar talleres...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                        prefixIcon: const Icon(Icons.search, color: Colors.white),
                        filled: true,
                        fillColor: Colors.blue.shade700,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      cursorColor: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    // Filter options
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          const SizedBox(width: 4),
                          for (String filter in filterOptions)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(filter),
                                selected: selectedFilter == filter,
                                onSelected: (selected) {
                                  setState(() {
                                    selectedFilter = selected ? filter : null;
                                    _applySearch(); // Apply filter when changed
                                  });
                                },
                                backgroundColor: Colors.blue.shade700,
                                selectedColor: Colors.orange.shade500,
                                labelStyle: TextStyle(
                                  color: selectedFilter == filter 
                                    ? Colors.white 
                                    : Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
            // Workshop list
            Expanded(
              child: controller.getDisplayedWorkshops().isEmpty && controller.workshops.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron talleres',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            searchController.clear();
                            setState(() {
                              selectedFilter = null;
                              controller.resetFilters();
                            });
                          },
                          child: const Text('Limpiar búsqueda'),
                        ),
                      ],
                    ),
                  )
                : controller.workshops.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : ListView.builder(
                      itemCount: controller.getDisplayedWorkshops().length,
                      itemBuilder: (context, index) {
                        final workshop = controller.getDisplayedWorkshops()[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: Colors.black.withOpacity(0.2),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.white, Colors.grey.shade50],
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    image: DecorationImage(
                                      image: workshop['imagenes'] != null && workshop['imagenes'].isNotEmpty
                                          ? MemoryImage(base64Decode(workshop['imagenes'][0]))
                                          : AssetImage(getImageForIndex(index)) as ImageProvider,
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(
                                        Colors.black.withOpacity(0.3),
                                        BlendMode.darken,
                                      ),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                workshop['nombre'] ?? 'Sin nombre',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  shadows: [
                                                    Shadow(
                                                      offset: Offset(0, 1),
                                                      blurRadius: 3.0,
                                                      color: Colors.black54,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.location_on,
                                                    color: Colors.white,
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      workshop['direccion'] ?? 'No disponible',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.white,
                                                        shadows: [
                                                          Shadow(
                                                            offset: Offset(0, 1),
                                                            blurRadius: 2.0,
                                                            color: Colors.black54,
                                                          ),
                                                        ],
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Details and booking button
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              size: 14,
                                              color: Colors.grey.shade700,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${workshop['abre']?.toString().substring(0, 5) ?? '08:00'} - ${workshop['cierra']?.toString().substring(0, 5) ?? '18:00'}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => _showBookingBottomSheet(workshop),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue.shade900,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          elevation: 2,
                                        ),
                                        child: const Text(
                                          'Agendar',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}