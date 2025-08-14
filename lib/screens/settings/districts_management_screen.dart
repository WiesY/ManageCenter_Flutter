import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/bloc/auth_bloc.dart';
import 'package:manage_center/bloc/districts_bloc.dart';
import 'package:manage_center/models/district_model.dart';

class DistrictsManagementScreen extends StatefulWidget {
  const DistrictsManagementScreen({super.key});

  @override
  State<DistrictsManagementScreen> createState() => _DistrictsManagementScreenState();
}

class _DistrictsManagementScreenState extends State<DistrictsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Загружаем районы при открытии
    context.read<DistrictsBloc>().add(FetchDistricts());
  }

  // Проверка прав на управление (из AuthBloc)
  bool get _hasManageRights {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      return authState.userInfo.role?.canManageBoilers ?? false;
    }
    return false; // Если не авторизован или нет прав
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasManageRights) {
      return Scaffold(
        appBar: AppBar(title: const Text('Управление районами')),
        body: const Center(
          child: Text(
            'У вас нет прав на управление районами.',
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление районами'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue, // Адаптируй под primary color
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<DistrictsBloc>().add(FetchDistricts()),
          ),
        ],
      ),
      body: RefreshIndicator(
    onRefresh: () async {
      context.read<DistrictsBloc>().add(FetchDistricts());
      return Future.delayed(const Duration(milliseconds: 300));
    },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Поиск по названию района',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  prefixIcon: const Icon(Icons.search),
                  fillColor: Colors.grey[200],
                  filled: true,
                ),
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              ),
            ),
            Expanded(
              child: BlocBuilder<DistrictsBloc, DistrictsState>(
                builder: (context, state) {
                  if (state is DistrictsLoading) {
                    return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                  } else if (state is DistrictsLoaded) {
                    final filteredDistricts = state.districts
                        .where((district) => district.name.toLowerCase().contains(_searchQuery))
                        .toList();
                    if (filteredDistricts.isEmpty) {
                      return const Center(child: Text('Нет районов или ничего не найдено.'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: filteredDistricts.length,
                      itemBuilder: (context, index) {
                        final district = filteredDistricts[index];
                        return Dismissible(
                          key: Key(district.id.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20.0),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) => _confirmDelete(context, district),
                          onDismissed: (direction) => context.read<DistrictsBloc>().add(DeleteDistrict(district.id)),
                          child: Card(
                            elevation: 2.0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                            color: Colors.white,
                            child: ListTile(
                              title: Text(district.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showDistrictForm(context, district: district),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  } else if (state is DistrictsError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Ошибка: ${state.error}', style: const TextStyle(color: Colors.red)),
                          TextButton(
                            onPressed: () => context.read<DistrictsBloc>().add(FetchDistricts()),
                            child: const Text('Повторить'),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDistrictForm(context),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Диалог подтверждения удаления
  Future<bool?> _confirmDelete(BuildContext context, District district) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Удалить район "${district.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  // Диалог формы для создания/обновления района
  void _showDistrictForm(BuildContext context, {District? district}) {
    final isEdit = district != null;
    final nameController = TextEditingController(text: district?.name ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Редактировать район' : 'Добавить район'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Название района'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            TextButton(
              onPressed: () {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Название района обязательно')));
                  return;
                }
                final districtData = {
                  'name': nameController.text,
                };
                if (isEdit) {
                  context.read<DistrictsBloc>().add(UpdateDistrict(district!.id, districtData));
                } else {
                  context.read<DistrictsBloc>().add(CreateDistrict(districtData));
                }
                Navigator.pop(context);
              },
              child: Text(isEdit ? 'Сохранить' : 'Добавить'),
            ),
          ],
        );
      },
    );
  }
}