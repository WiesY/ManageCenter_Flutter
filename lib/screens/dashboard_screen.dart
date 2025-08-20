// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/bloc/auth_bloc.dart';
import 'package:manage_center/bloc/boilers_bloc.dart';
import 'package:manage_center/models/boiler_list_item_model.dart';
import 'package:manage_center/screens/boiler_detail_screen.dart';
import 'package:manage_center/screens/login_screen.dart';
import 'package:manage_center/screens/settings/settings_menu_screen.dart';
import 'package:manage_center/services/api_service.dart';
import 'package:manage_center/services/storage_service.dart';
import 'package:manage_center/bloc/boiler_detail_bloc.dart';
import 'package:manage_center/widgets/custom_bottom_navigation.dart';

// import 'package:manage_center/screens/Boiler_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы действительно хотите выйти из аккаунта?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(LogoutEvent());
              // Navigator.of(context).pushAndRemoveUntil(
              //     MaterialPageRoute(builder: (context) => const LoginScreen()),
              //     (Route<dynamic> route) =>
              //         false // удаляем все предыдущие экраны
              //     );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Выйти', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Диспетчерская'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<BoilersBloc, BoilersState>(
        builder: (context, state) {
          if (state is BoilersLoadInProgress) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BoilersLoadFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ошибка: ${state.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<BoilersBloc>().add(FetchBoilers()),
                    child: const Text('Попробовать снова'),
                  )
                ],
              ),
            );
          }
          if (state is BoilersLoadSuccess) {
            if (state.boilers.isEmpty) {
              return const Center(child: Text('Список объектов пуст.'));
            }
            return RefreshIndicator(
              // Эта функция будет вызвана, когда пользователь потянет список вниз
              onRefresh: () async {
                await Future.delayed(Durations.short2);
                // Отправляем событие в блок для обновления данных
                context.read<BoilersBloc>().add(FetchBoilers());
                // Мы должны дождаться, пока загрузка завершится.
                // Для этого мы можем "послушать" стрим блока.
                // Это гарантирует, что индикатор будет крутиться, пока данные не загрузятся.
                await context
                    .read<BoilersBloc>()
                    .stream
                    .firstWhere((s) => s is! BoilersLoadInProgress);
              },
              child: state.boilers.isEmpty
                  ? const Center(child: Text('Список объектов пуст.'))
                  // Если список не пуст, строим его
                  : _buildBoilerList(context, state.boilers),
            );
          }
          return const Center(child: Text('Загрузка...'));
        },
      ),
    );
  }

  Widget _buildBoilerList(BuildContext context, List<BoilerListItem> boilers) {
    final boilersByDistrict = <String, List<BoilerListItem>>{};
    for (var boiler in boilers) {
      boilersByDistrict.putIfAbsent(boiler.district.name, () => []).add(boiler);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: boilersByDistrict.length,
      itemBuilder: (context, index) {
        final districtName = boilersByDistrict.keys.elementAt(index);
        final districtBoilers = boilersByDistrict[districtName]!;
        return _buildDistrictSection(context, districtName, districtBoilers);
      },
    );
  }

  Widget _buildDistrictSection(
      BuildContext context, String title, List<BoilerListItem> boilers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: boilers
              .map((boiler) => _buildBoilerCard(context, boiler))
              .toList(),
        ),
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildBoilerCard(BuildContext context, BoilerListItem boiler) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => BoilerDetailBloc(
                apiService: context.read<ApiService>(),
                storageService: context.read<StorageService>(),
              ),
              child: BoilerDetailScreen(
                boilerId: boiler.id,
                boilerName: boiler.name,
                districtName: boiler.district.name,
              ),
            ),
          ),
        );
      },
      child: Container(
        width: 120, // Можно задать ширину для единообразия
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              boiler.name,
              softWrap: true,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Тип: ${boiler.boilerType.name}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}
