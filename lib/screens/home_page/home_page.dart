import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../connection/Home/HomeController.dart';
import '../../connection/auth/AuthController.dart';
import '../../utils/helpers/snackbar_helper.dart';
import '../../utils/helpers/navigation_helper.dart';
import '../../widgets/workshop_card.dart';
import '../../widgets/booking_form.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/workshop_search_bar.dart';
import '../../widgets/no_results_found.dart';
import '../../widgets/exit_confirmation_dialog.dart';

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
              return BookingForm(
                workshop: workshop,
                vehicles: vehicles,
                onVehicleSelected: (value) => setSheetState(() => controller.setVehicle(value)),
                onDateSelected: (date) => setSheetState(() => controller.selectDate(date)),
                onTimeSelected: (time) => setSheetState(() => controller.selectTime(time)),
                onDescriptionChanged: controller.setAppointmentDescription,
                onBookingSubmitted: () async {
                  final result = await controller.bookAppointment(context);
                  if (result != null && result['success']) {
                    Navigator.of(context).pop(); // Cierra el bottom sheet
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('¡Cita creada con éxito!'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result?['error'] ?? 'Error al agendar la cita'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                selectedDate: controller.selectedDate,
                selectedTime: controller.selectedTime,
                selectedVehicle: controller.selectedVehicle,
                availableTimeSlots: controller.availableTimeSlots,
              );
            },
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await ExitConfirmationDialog.show(context);
        if (shouldPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: CustomAppBar(
          isSearchVisible: isSearchVisible,
          onSearchToggle: _toggleSearch,
          onMenuPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
        ),
        endDrawer: const AppDrawer(),
        body: Column(
          children: [
            if (isSearchVisible)
              WorkshopSearchBar(
                searchController: searchController,
                selectedFilter: selectedFilter,
                filterOptions: filterOptions,
                onFilterSelected: (filter) {
                  setState(() {
                    selectedFilter = filter;
                    _applySearch();
                  });
                },
                onSearch: _applySearch,
              ),
            
            Expanded(
              child: controller.getDisplayedWorkshops().isEmpty && controller.workshops.isNotEmpty
                ? NoResultsFound(
                    onClearSearch: () {
                      searchController.clear();
                      setState(() {
                        selectedFilter = null;
                        controller.resetFilters();
                      });
                    },
                  )
                : controller.workshops.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : ListView.builder(
                      itemCount: controller.getDisplayedWorkshops().length,
                      itemBuilder: (context, index) {
                        final workshop = controller.getDisplayedWorkshops()[index];
                        return WorkshopCard(
                          workshop: workshop,
                          index: index,
                          defaultImages: defaultImages,
                          onBookingPressed: _showBookingBottomSheet,
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