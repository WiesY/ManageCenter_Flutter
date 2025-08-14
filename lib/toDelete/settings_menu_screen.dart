// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:manage_center/bloc/auth_bloc.dart';
// import 'package:manage_center/bloc/boilers_bloc.dart';
// import 'package:manage_center/screens/dashboard_screen.dart';
// import 'package:manage_center/screens/settings/users_management_screen.dart';
// import 'package:manage_center/services/api_service.dart';
// import 'package:manage_center/services/storage_service.dart';
// import 'package:manage_center/widgets/custom_bottom_navigation.dart';

// class SettingsScreen extends StatelessWidget {
//   const SettingsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     //final userInfo = (context.read<AuthBloc>().state as AuthSuccess).userInfo;
//     //final canManageBoilers = userInfo.role.canManageBoilers;
//     //final canManageAccounts = userInfo.role.canManageAccounts;
    
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Настройки'),
//         backgroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           _buildSettingsCategory(
//             context,
//             title: 'Профиль',
//             icon: Icons.person,
//             items: [
//               SettingsItem(
//                 title: 'Личные данные',
//                 icon: Icons.account_circle,
//                 onTap: () => _navigateToProfileSettings(context),
//               ),
//               SettingsItem(
//                 title: 'Сменить пароль',
//                 icon: Icons.lock,
//                 onTap: () => _navigateToChangePassword(context),
//               ),
//             ],
//           ),
          
//           if (true) 
//             _buildSettingsCategory(
//               context,
//               title: 'Объекты',
//               icon: Icons.business,
//               items: [
//                 SettingsItem(
//                   title: 'Управление котельными',
//                   icon: Icons.home_work,
//                   onTap: () => _navigateToBoilersManagement(context),
//                 ),
//                 SettingsItem(
//                   title: 'Типы котельных',
//                   icon: Icons.category,
//                   onTap: () => _navigateToBoilerTypes(context),
//                 ),
//                 SettingsItem(
//                   title: 'Районы',
//                   icon: Icons.location_city,
//                   onTap: () => _navigateToDistricts(context),
//                 ),
//               ],
//             ),
          
//           if (true)
//             _buildSettingsCategory(
//               context,
//               title: 'Пользователи',
//               icon: Icons.people,
//               items: [
//                 SettingsItem(
//                   title: 'Управление пользователями',
//                   icon: Icons.manage_accounts,
//                   onTap: () => _navigateToUsersManagement(context),
//                 ),
//                 SettingsItem(
//                   title: 'Роли пользователей',
//                   icon: Icons.admin_panel_settings,
//                   onTap: () => _navigateToRolesManagement(context),
//                 ),
//               ],
//             ),
          
//           _buildSettingsCategory(
//             context,
//             title: 'Система',
//             icon: Icons.settings,
//             items: [
//               SettingsItem(
//                 title: 'Настройки приложения',
//                 icon: Icons.app_settings_alt,
//                 onTap: () => _navigateToAppSettings(context),
//               ),
//               SettingsItem(
//                 title: 'О приложении',
//                 icon: Icons.info,
//                 onTap: () => _navigateToAbout(context),
//               ),
//             ],
//           ),
//         ],
//       ),
//       bottomNavigationBar: CustomBottomNavigation(
//         currentIndex: 3, // Индекс для вкладки настроек
//         onTap: (index) {
//           if (index != 3) {
//             // Навигация на другие экраны в зависимости от индекса
//             switch (index) {
//               case 0:
//             Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => BlocProvider(
//               create: (context) => BoilersBloc(
//                 apiService: context.read<ApiService>(),
//                 storageService: context.read<StorageService>(),
//               )..add(FetchBoilers()),
//               child: const DashboardScreen(),
//             ),
//           ),
//         );
//                 break;
                
//               // case 1:
//               //   Navigator.pushReplacementNamed(context, '/upload');
//               //   break;
//               // case 2:
//               //   Navigator.pushReplacementNamed(context, '/messages');
//               //   break;
//             }
//           }
//         },
//       ),
//     );
//   }

//   Widget _buildSettingsCategory(
//     BuildContext context, {
//     required String title,
//     required IconData icon,
//     required List<SettingsItem> items,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 12.0),
//           child: Row(
//             children: [
//               Icon(icon, color: Colors.blue.shade700),
//               const SizedBox(width: 8),
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         ...items.map((item) => _buildSettingsItem(context, item)),
//         const Divider(height: 32),
//       ],
//     );
//   }

//   Widget _buildSettingsItem(BuildContext context, SettingsItem item) {
//     return ListTile(
//       leading: Container(
//         padding: const EdgeInsets.all(8),
//         decoration: BoxDecoration(
//           color: Colors.blue.shade50,
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Icon(item.icon, color: Colors.blue.shade700),
//       ),
//       title: Text(item.title),
//       trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//       onTap: item.onTap,
//     );
//   }

//   // Методы навигации к различным экранам настроек
//   void _navigateToProfileSettings(BuildContext context) {
//     // Реализация будет добавлена позже
//     _showComingSoonDialog(context, 'Личные данные');
//   }

//   void _navigateToChangePassword(BuildContext context) {
//     // Реализация будет добавлена позже
//     _showComingSoonDialog(context, 'Смена пароля');
//   }

//   void _navigateToBoilersManagement(BuildContext context) {
//     // Реализация будет добавлена позже
//     _showComingSoonDialog(context, 'Управление котельными');
//   }

//   void _navigateToBoilerTypes(BuildContext context) {
//     // Реализация будет добавлена позже
//     _showComingSoonDialog(context, 'Типы котельных');
//   }

//   void _navigateToDistricts(BuildContext context) {
//     // Реализация будет добавлена позже
//     _showComingSoonDialog(context, 'Районы');
//   }

//   void _navigateToUsersManagement(BuildContext context) {
//     Navigator.push(context, MaterialPageRoute(builder: (context) => const UsersManagementScreen()),);
//     // _showComingSoonDialog(context, 'Управление пользователями');
//   }

//   void _navigateToRolesManagement(BuildContext context) {
//     // Реализация будет добавлена позже
//     _showComingSoonDialog(context, 'Роли пользователей');
//   }

//   void _navigateToAppSettings(BuildContext context) {
//     // Реализация будет добавлена позже
//     _showComingSoonDialog(context, 'Настройки приложения');
//   }

//   void _navigateToAbout(BuildContext context) {
//     // Реализация будет добавлена позже
//     _showComingSoonDialog(context, 'О приложении');
//   }

//   void _showComingSoonDialog(BuildContext context, String feature) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(feature),
//         content: const Text('Эта функция будет доступна в ближайшее время.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('ОК'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class SettingsItem {
//   final String title;
//   final IconData icon;
//   final VoidCallback onTap;

//   SettingsItem({
//     required this.title,
//     required this.icon,
//     required this.onTap,
//   });
// }