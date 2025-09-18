import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/bloc/auth_bloc.dart';
import 'package:manage_center/bloc/roles_bloc.dart';
import 'package:manage_center/models/role_model.dart';

class RolesManagementScreen extends StatefulWidget {
  const RolesManagementScreen({super.key});

  @override
  State<RolesManagementScreen> createState() => _RolesManagementScreenState();
}

class _RolesManagementScreenState extends State<RolesManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Загружаем роли при открытии
    context.read<RolesBloc>().add(FetchRoles());
  }

  // Проверка прав на управление (из AuthBloc)
  bool get _hasManageRights {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      return authState.userInfo.role?.canManageAccounts ?? false;
    }
    return false; // Если не авторизован или нет прав
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasManageRights) {
      return Scaffold(
        appBar: AppBar(title: const Text('Управление ролями')),
        body: const Center(
          child: Text(
            'У вас нет прав на управление ролями.',
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление ролями'),
         foregroundColor: Colors.white,
        backgroundColor: Colors.blue, // Адаптируй под primary color
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<RolesBloc>().add(FetchRoles()),
          ),
        ],
      ),
      body: RefreshIndicator(
    onRefresh: () async {
      context.read<RolesBloc>().add(FetchRoles());
      return Future.delayed(const Duration(milliseconds: 300));
    },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Поиск по названию роли',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  prefixIcon: const Icon(Icons.search),
                  fillColor: Colors.grey[200],
                  filled: true,
                ),
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              ),
            ),
            Expanded(
              child: BlocBuilder<RolesBloc, RolesState>(
                builder: (context, state) {
                  if (state is RolesLoading) {
                    return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                  } else if (state is RolesLoaded) {
                    final filteredRoles = state.roles
                        .where((role) => role.name.toLowerCase().contains(_searchQuery))
                        .toList();
                    if (filteredRoles.isEmpty) {
                      return const Center(child: Text('Нет ролей или ничего не найдено.'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: filteredRoles.length,
                      itemBuilder: (context, index) {
                        final role = filteredRoles[index];
                        return Dismissible(
                          key: Key(role.id.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20.0),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) => _confirmDelete(context, role),
                          onDismissed: (direction) => context.read<RolesBloc>().add(DeleteRole(role.id)),
                          child: Card(
                            elevation: 2.0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                            color: Colors.white,
                            child: ListTile(
                              title: Text(role.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                'Доступ ко всем объектам: ${role.canAccessAllBoilers ? 'Да' : 'Нет'}\n'
                                'Управление аккаунтами: ${role.canManageAccounts ? 'Да' : 'Нет'}\n'
                                'Управление объектами: ${role.canManageBoilers ? 'Да' : 'Нет'}\n'
                                'Управление параметрами: ${role.canManageParameters ? 'Да' : 'Нет'}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showRoleForm(context, role: role),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  } else if (state is RolesError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Ошибка: ${state.error}', style: const TextStyle(color: Colors.red)),
                          TextButton(
                            onPressed: () => context.read<RolesBloc>().add(FetchRoles()),
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
        onPressed: () => _showRoleForm(context),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Диалог подтверждения удаления
  Future<bool?> _confirmDelete(BuildContext context, Role role) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Удалить роль "${role.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  // Диалог формы для создания/обновления роли
  void _showRoleForm(BuildContext context, {Role? role}) {
    final isEdit = role != null;
    final nameController = TextEditingController(text: role?.name ?? '');
    bool canAccessAllBoilers = role?.canAccessAllBoilers ?? false;
    bool canManageAccounts = role?.canManageAccounts ?? false;
    bool canManageBoilers = role?.canManageBoilers ?? false;
    bool canManageParameters = role?.canManageParameters ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) { // Для обновления чекбоксов
            return AlertDialog(
              title: Text(isEdit ? 'Редактировать роль' : 'Добавить роль'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Название роли'),
                    ),
                    SwitchListTile(
                      title: const Text('Доступ ко всем объектам'),
                      value: canAccessAllBoilers,
                      onChanged: (value) => setState(() => canAccessAllBoilers = value),
                      activeColor: Colors.blue,
                    ),
                    SwitchListTile(
                      title: const Text('Управление аккаунтами'),
                      value: canManageAccounts,
                      onChanged: (value) => setState(() => canManageAccounts = value),
                      activeColor: Colors.blue,
                    ),
                    SwitchListTile(
                      title: const Text('Управление объектами'),
                      value: canManageBoilers,
                      onChanged: (value) => setState(() => canManageBoilers = value),
                      activeColor: Colors.blue,
                    ),
                     SwitchListTile(
                      title: const Text('Управление параметрами'),
                      value: canManageParameters,
                      onChanged: (value) => setState(() => canManageParameters = value),
                      activeColor: Colors.blue,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
                TextButton(
                  onPressed: () {
                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Название роли обязательно')));
                      return;
                    }
                    final roleData = {
                      'name': nameController.text,
                      'canAccessAllBoilers': canAccessAllBoilers,
                      'canManageAccounts': canManageAccounts,
                      'canManageBoilers': canManageBoilers,
                      'canManageParameters': canManageParameters,
                    };
                    if (isEdit) {
                      context.read<RolesBloc>().add(UpdateRole(role!.id, roleData));
                    } else {
                      context.read<RolesBloc>().add(CreateRole(roleData));
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
}