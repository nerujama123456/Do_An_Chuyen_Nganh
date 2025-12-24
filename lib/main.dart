// lib/main.dart
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_first_app/screens/appointments/all_appointments_screen.dart';
import 'package:my_first_app/screens/appointments/today_appointments_screen.dart';
import 'package:my_first_app/screens/cashier/cashier_health_cert_screen.dart';
import 'package:my_first_app/screens/cashier/cashier_service_voucher_screen.dart';
import 'package:my_first_app/screens/consulting_rooms/consulting_rooms_screen.dart';
import 'package:my_first_app/screens/home_screen.dart';
import 'package:my_first_app/screens/medical_services/medical_services_screen.dart';
import 'package:my_first_app/screens/medicine_types/medicine_types_screen.dart';
import 'package:my_first_app/screens/medicines/medicines_screen.dart';
import 'package:my_first_app/screens/patients/patients_screen.dart';
import 'package:my_first_app/screens/settings/settings_accounts_screen.dart';
import 'screens/doctors/doctors_screen.dart'; // IMPORT MỚI
import 'package:supabase_flutter/supabase_flutter.dart';


// Import các màn hình cần thiết
import 'screens/auth/login_screen.dart';
import 'screens/health_certs/health_cert_list_screen.dart';
import 'screens/prescriptions/prescription_list_screen.dart';
import 'screens/service_vouchers/service_voucher_list_screen.dart';
import 'screens/auth/role_redirect_screen.dart';
// THAY THẾ CHUỖI NÀY BẰNG CÁC KEY THỰC TẾ CỦA BẠN TỪ SUPABASE
const SUPABASE_URL = 'https://neakqzwpjoudmoythund.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5lYWtxendwam91ZG1veXRodW5kIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTMwMDA4MywiZXhwIjoyMDc2ODc2MDgzfQ.KN4ph-iZANg-9KNb4o4vDRFkv9YlosXRgb5VIwg_BQo';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  await Supabase.initialize(
    url: SUPABASE_URL,
    anonKey: SUPABASE_ANON_KEY,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản Lý Phòng Khám',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // !!! THAY ĐỔI MÀU CHỦ ĐẠO SANG XANH NƯỚC BIỂN NHẠT
        primarySwatch: Colors.lightBlue,
        primaryColor: Colors.lightBlue[600], // Màu chính đậm hơn chút
        scaffoldBackgroundColor: Colors.white, // Nền hơi xám xanh nhạt
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',

        // Thêm các thuộc tính cho AppBar/Card
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.lightBlue[600],
          foregroundColor: Colors.white,
        ),
      ),

      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/redirect': (context) => RoleRedirectScreen(),
        '/home': (context) => HomeScreen(),

        '/prescriptions': (context) => PrescriptionListScreen(),
        '/health_certs': (context) => HealthCertListScreen(),
        '/service_vouchers': (context) => ServiceVoucherListScreen(),
        '/consulting_rooms': (context) => ConsultingRoomsScreen(),
        '/medical_services': (context) => MedicalServicesScreen(),
        '/medicine_types': (context) => MedicineTypesScreen(),
        '/all_appointments': (context) => AllAppointmentsScreen(),
        '/medicines': (context) => MedicinesScreen(),
        '/patients': (context) => PatientsScreen(),
        '/today_appointments': (context) => TodayAppointmentsScreen(),
        '/cashier/health_certs': (context) => CashierHealthCertScreen(),
        '/cashier/service_vouchers': (context) => CashierServiceVoucherScreen(),
        '/settings/accounts': (context) => SettingsAccountsScreen(),
        '/doctors': (context) => DoctorsScreen(),
      },
    );
  }
}