import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:login_register_app/values/app_routes.dart';
import '../../connection/vehicles/VehiclesController.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({Key? key}) : super(key: key);

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  final VehiclesController _vehicleController = VehiclesController();
  List<Map<String, dynamic>> vehicles = [];
  final List<String> vehicleTypes = ['carro', 'moto', 'camion'];
  
  // Lista predefinida de colores con sus valores hexadecimales
  final List<Map<String, dynamic>> availableColors = [
    {'name': 'Negro', 'color': const Color(0xFF000000)},
    {'name': 'Blanco', 'color': const Color(0xFFFFFFFF)},
    {'name': 'Gris', 'color': const Color(0xFF808080)},
    {'name': 'Plata', 'color': const Color(0xFFC0C0C0)},
    {'name': 'Rojo', 'color': const Color(0xFFFF0000)},
    {'name': 'Azul', 'color': const Color(0xFF0000FF)},
    {'name': 'Verde', 'color': const Color(0xFF008000)},
    {'name': 'Amarillo', 'color': const Color(0xFFFFFF00)},
    {'name': 'Naranja', 'color': const Color(0xFFFFA500)},
    {'name': 'Marrón', 'color': const Color(0xFF8B4513)},
    {'name': 'Beige', 'color': const Color(0xFFF5F5DC)},
  ];
  
  // Rangos para los años de los vehículos
  final List<int> availableYears = List.generate(
    30, // Últimos 30 años
    (index) => DateTime.now().year - index
  );

  late TextEditingController marcaController;
  late TextEditingController modeloController;
  String selectedYear = DateTime.now().year.toString();
  String selectedColor = 'Negro';
  late TextEditingController placaController;

  String selectedType = 'carro';
  String? placaError;
  
  // Variable para controlar si estamos editando o agregando
  bool isEditing = false;
  int? editingVehicleId;

  @override
  void initState() {
    super.initState();
    marcaController = TextEditingController();
    modeloController = TextEditingController();
    placaController = TextEditingController();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    try {
      final fetchedVehicles = await _vehicleController.fetchVehicles();
      setState(() {
        vehicles = fetchedVehicles;
      });
    } catch (e) {
      print('Error al cargar los vehículos: $e');
    }
  }

  void _clearForm() {
    marcaController.clear();
    modeloController.clear();
    placaController.clear();
    setState(() {
      selectedType = 'carro';
      selectedColor = 'Negro';
      selectedYear = DateTime.now().year.toString();
      placaError = null;
      isEditing = false;
      editingVehicleId = null;
    });
  }

  bool _validatePlaca() {
    // Validar formato: tres letras seguidas de tres o cuatro números
    RegExp placaRegex = RegExp(r'^[A-Za-z]{3}[0-9]{3,4}$');
    if (!placaRegex.hasMatch(placaController.text)) {
      setState(() {
        placaError = 'Debe ser una placa válida';
      });
      return false;
    }
    setState(() {
      placaError = null;
    });
    return true;
  }

  Future<void> _saveVehicle() async {
    // Validar la placa antes de continuar
    if (!_validatePlaca()) {
      return;
    }

    final vehicleData = {
      'marca': marcaController.text,
      'modelo': modeloController.text,
      'anio': int.parse(selectedYear),
      'color': selectedColor,
      'placa': placaController.text.toUpperCase(),
      'tipo': selectedType,
    };

    try {
      if (isEditing && editingVehicleId != null) {
        // Actualizar vehículo existente
        await _vehicleController.editVehicle(editingVehicleId!, vehicleData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Vehículo actualizado correctamente'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Registrar nuevo vehículo
        await _vehicleController.registerVehicle(vehicleData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Vehículo agregado correctamente'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      _clearForm();
      _loadVehicles(); // Recargar la lista de vehículos
      
      // Cerrar el BottomSheet
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se pudo guardar el vehículo. Intente nuevamente.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _deleteVehicle(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text('¿Estás seguro de que deseas eliminar este vehículo? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _vehicleController.deleteVehicle(id);
        // Primero actualizamos la lista local
        setState(() {
          vehicles.removeWhere((vehicle) => vehicle['id'] == id);
        });
        
        if (!mounted) return;
        
        // Mostramos el mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Vehículo eliminado correctamente'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        
        // Si hay un error, recargamos la lista completa
        await _loadVehicles();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se pudo eliminar el vehículo. Intente nuevamente.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _editVehicle(Map<String, dynamic> vehicle) async {
    // Cargar los datos del vehículo en el formulario
    setState(() {
      isEditing = true;
      editingVehicleId = vehicle['id'];
      marcaController.text = vehicle['marca'];
      modeloController.text = vehicle['modelo'];
      selectedYear = vehicle['anio'].toString();
      selectedColor = vehicle['color'];
      placaController.text = vehicle['placa'];
      selectedType = vehicle['tipo'];
    });

    // Mostrar el formulario
    _showVehicleFormBottomSheet();
  }

  void _showVehicleFormBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con gradiente
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade900, Colors.blue.shade800],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      isEditing ? Icons.edit : Icons.add_circle_outline,
                      color: Colors.white,
                      size: 30,
                    ),
                    const SizedBox(width: 15),
                    Text(
                      isEditing ? 'Editar Vehículo' : 'Agregar Vehículo',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Formulario
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campos del formulario con mejor diseño
                    _buildTextField(
                      marcaController,
                      'Marca',
                      prefixIcon: Icons.directions_car,
                    ),
                    _buildTextField(
                      modeloController,
                      'Modelo',
                      prefixIcon: Icons.style,
                    ),
                    _buildYearPickerNew(),
                    _buildColorPickerNew(),
                    _buildTextField(
                      placaController,
                      'Placa',
                      prefixIcon: Icons.credit_card,
                      errorText: placaError,
                      onChanged: (val) {
                        if (placaError != null) {
                          _validatePlaca();
                        }
                      },
                      helperText: 'Formato: ABC123 o ABC1234',
                    ),
                    _buildVehicleTypeDropdownNew(),
                    const SizedBox(height: 24),
                    // Botones con mejor diseño
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade200,
                              foregroundColor: Colors.grey.shade800,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveVehicle,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade900,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isEditing ? 'Actualizar' : 'Guardar',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    String? errorText,
    String? helperText,
    IconData? prefixIcon,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: onChanged,
            decoration: InputDecoration(
              errorText: errorText,
              helperText: helperText,
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.blue.shade900) : null,
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade900, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearPickerNew() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Año',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonFormField<String>(
              value: selectedYear,
              icon: Icon(Icons.calendar_today, color: Colors.blue.shade900),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                border: InputBorder.none,
              ),
              items: availableYears.map((year) {
                return DropdownMenuItem(
                  value: year.toString(),
                  child: Text(year.toString()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedYear = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPickerNew() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Color',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonFormField<String>(
              value: selectedColor,
              icon: Icon(Icons.color_lens, color: Colors.blue.shade900),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                border: InputBorder.none,
              ),
              items: availableColors.map((colorInfo) {
                final String colorName = colorInfo['name'] as String;
                final Color colorValue = colorInfo['color'] as Color;
                return DropdownMenuItem<String>(
                  value: colorName,
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: colorValue,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.grey.shade400,
                            width: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(colorName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedColor = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleTypeDropdownNew() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipo de Vehículo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonFormField<String>(
              value: selectedType,
              icon: Icon(Icons.category, color: Colors.blue.shade900),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                border: InputBorder.none,
              ),
              items: vehicleTypes.map((type) {
                IconData icon;
                switch (type) {
                  case 'moto':
                    icon = Icons.motorcycle;
                    break;
                  case 'camion':
                    icon = Icons.local_shipping;
                    break;
                  default:
                    icon = Icons.directions_car;
                }
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(icon, color: Colors.blue.shade900),
                      const SizedBox(width: 12),
                      Text(type.toUpperCase()),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedType = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _getVehicleIcon(String type) {
    switch (type) {
      case 'moto':
        return const Icon(Icons.motorcycle, color: Colors.blueAccent, size: 32);
      case 'camion':
        return const Icon(Icons.local_shipping, color: Colors.blueAccent, size: 32);
      default:
        return const Icon(Icons.directions_car, color: Colors.blueAccent, size: 32);
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              ' Vehículos',
              style: TextStyle(
                color: Colors.orange.shade500,
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
                    // Add logout logic here
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _clearForm(); // Asegurar que se limpie el formulario para un nuevo vehículo
          _showVehicleFormBottomSheet();
        },
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add),
        label: Text(
          'Agregar',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (vehicles.isEmpty) {
      return const Center(
        child: Text(
          'No tienes vehículos registrados',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: vehicles.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final vehicle = vehicles[index];
        return _buildVehicleCard(vehicle);
      },
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _getVehicleIcon(vehicle['tipo']),
        title: Text(
          '${vehicle['marca']} ${vehicle['modelo']}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Text(
              'Año: ${vehicle['anio']} - Placa: ${vehicle['placa']}',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
            ),
            Text(
              'Color: ${vehicle['color']}',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.green),
              onPressed: () => _editVehicle(vehicle),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteVehicle(vehicle['id'].toInt()),
            ),
          ],
        ),
      ),
    );
  }
}