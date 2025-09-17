import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/bloc/auth_bloc.dart';
import 'package:manage_center/bloc/parameter_groups_bloc.dart';
import 'package:manage_center/models/parameter_group_model.dart';

class ParamGroupsManagementScreen extends StatefulWidget {
  const ParamGroupsManagementScreen({super.key});

  @override
  State<ParamGroupsManagementScreen> createState() => _ParamGroupsManagementScreenState();
}

class _ParamGroupsManagementScreenState extends State<ParamGroupsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    // Загружаем группы параметров при открытии
    context.read<ParameterGroupsBloc>().add(FetchParameterGroups());
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
        appBar: AppBar(title: const Text('Управление группами параметров')),
        body: const Center(
          child: Text(
            'У вас нет прав на управление группами параметров.',
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление группами параметров'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue, // Адаптируй под primary color
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ParameterGroupsBloc>().add(FetchParameterGroups()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<ParameterGroupsBloc>().add(FetchParameterGroups());
          return Future.delayed(const Duration(milliseconds: 300));
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Поиск по названию группы',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  prefixIcon: const Icon(Icons.search),
                  fillColor: Colors.grey[200],
                  filled: true,
                ),
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              ),
            ),
            Expanded(
              child: BlocBuilder<ParameterGroupsBloc, ParameterGroupsState>(
                builder: (context, state) {
                  if (state is ParameterGroupsLoadInProgress) {
                    return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                  } else if (state is ParameterGroupsLoadSuccess) {
                    final filteredGroups = state.parameterGroups
                        .where((group) => group.name.toLowerCase().contains(_searchQuery))
                        .toList();
                    if (filteredGroups.isEmpty) {
                      return const Center(child: Text('Нет групп параметров или ничего не найдено.'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: filteredGroups.length,
                      itemBuilder: (context, index) {
                        final group = filteredGroups[index];
                        return Dismissible(
                          key: Key(group.id.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20.0),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) => _confirmDelete(context, group),
                          onDismissed: (direction) => _deleteParameterGroup(group.id),
                          child: Card(
                            elevation: 2.0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                            color: Colors.white,
                            child: ListTile(
                              leading: Icon(group.icon, color: group.color),
                              title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Количество параметров: ${group.parameterIds.length}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showParameterGroupForm(context, group: group),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  } else if (state is ParameterGroupsLoadFailure) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Ошибка: ${state.error}', style: const TextStyle(color: Colors.red)),
                          TextButton(
                            onPressed: () => context.read<ParameterGroupsBloc>().add(FetchParameterGroups()),
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
        onPressed: () => _showParameterGroupForm(context),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Диалог подтверждения удаления
  Future<bool?> _confirmDelete(BuildContext context, ParameterGroup group) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Удалить группу параметров "${group.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  // Метод удаления группы параметров
  void _deleteParameterGroup(int groupId) async {
    try {
      // Вызов события удаления группы параметров
      context.read<ParameterGroupsBloc>().add(DeleteParameterGroup(groupId));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Группа параметров успешно удалена')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении группы параметров: $e')),
      );
    }
  }

  // Диалог формы для создания/обновления группы параметров
  void _showParameterGroupForm(BuildContext context, {ParameterGroup? group}) {
    final isEdit = group != null;
    final nameController = TextEditingController(text: group?.name ?? '');
    
    // Начальные значения для иконки и цвета
    IconData selectedIcon = group?.icon ?? Icons.folder;
    Color selectedColor = group?.color ?? Colors.blue;

    // Список доступных иконок
    final List<IconData> availableIcons = [
      Icons.folder,
      Icons.thermostat,
      Icons.speed,
      Icons.water_drop,
      Icons.height,
      Icons.bolt,
      Icons.settings,
      Icons.analytics,
    ];

    // Список доступных цветов
    final List<Color> availableColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.teal,
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEdit ? 'Редактировать группу параметров' : 'Добавить группу параметров'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Название группы'),
                    ),
                    const SizedBox(height: 16),
                    
                    // Выбор иконки
                    const Text('Выберите иконку:'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: availableIcons.map((icon) {
                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedIcon = icon;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: selectedIcon == icon ? selectedColor.withOpacity(0.3) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selectedIcon == icon ? selectedColor : Colors.grey,
                                width: 1,
                              ),
                            ),
                            child: Icon(icon, color: selectedColor, size: 30),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Выбор цвета
                    const Text('Выберите цвет:'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: availableColors.map((color) {
                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedColor == color ? Colors.black : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
                TextButton(
                  onPressed: () {
                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Название группы обязательно для заполнения')),
                      );
                      return;
                    }
                    
                    if (isEdit) {
                      final updatedGroup = group!.copyWith(
                        name: nameController.text,
                        icon: selectedIcon,
                        color: selectedColor,
                      );
                      _updateParameterGroup(updatedGroup);
                    } else {
                      _createParameterGroup(nameController.text, selectedIcon, selectedColor);
                    }
                    
                    Navigator.pop(context);
                  },
                  child: Text(isEdit ? 'Сохранить' : 'Добавить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Метод создания группы параметров
  void _createParameterGroup(String name, IconData icon, Color color) async {
    try {
      // Вызов события создания группы параметров
      context.read<ParameterGroupsBloc>().add(CreateParameterGroup(name, icon, color));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Группа параметров успешно создана')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при создании группы параметров: $e')),
      );
    }
  }

  // Метод обновления группы параметров
  void _updateParameterGroup(ParameterGroup group) async {
    try {
      // Вызов события обновления группы параметров
      context.read<ParameterGroupsBloc>().add(UpdateParameterGroup(group));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Группа параметров успешно обновлена')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при обновлении группы параметров: $e')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}