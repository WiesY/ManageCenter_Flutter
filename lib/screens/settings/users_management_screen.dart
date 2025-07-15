import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/bloc/roles_bloc.dart';
import 'package:manage_center/bloc/users_bloc.dart';
import 'package:manage_center/models/role_model.dart';
import 'package:manage_center/models/user_info_model.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Загружаем список при открытии экрана (если есть права)
    context.read<RolesBloc>().add(FetchRoles());
    context.read<UsersBloc>().add(FetchUsers());
  }

  // Placeholder список ролей (fetch из API если нужно)
  // final List<Role> _availableRoles = [
  //   Role(
  //       id: 1,
  //       name: 'Администратор',
  //       canAccessAllBoilers: true,
  //       canManageAccounts: true,
  //       canManageBoilers: true),
  //   Role(
  //       id: 2,
  //       name: 'Менеджер',
  //       canAccessAllBoilers: false,
  //       canManageAccounts: false,
  //       canManageBoilers: true),
  //   // Добавь больше по твоему API
  // ];

  // Проверка прав (возьми из auth_bloc или app_bloc)
  bool get _hasManageRights {
    // Пример: final currentUser = context.read<AuthBloc>().state is AuthSuccess ? (state as AuthSuccess).userInfo : null;
    // return currentUser?.role.canManageAccounts ?? false;
    return true; // Placeholder — замени на реальную проверку
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasManageRights) {
      return Scaffold(
        appBar: AppBar(title: const Text('Управление пользователями')),
        body: const Center(
            child: Text('У вас нет прав на управление пользователями.',
                style: TextStyle(color: Colors.red))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление пользователями'),
        foregroundColor: Colors.white,
        backgroundColor: Colors
            .blue, // Адаптируй под твою primary color (например, Theme.of(context).primaryColor)
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<UsersBloc>().add(FetchUsers()),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Поиск',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                prefixIcon: const Icon(Icons.search),
                fillColor: Colors
                    .grey[200], // Светлый фон для поиска, вписывается в гамму
                filled: true,
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: BlocBuilder<UsersBloc, UsersState>(
              builder: (context, state) {
                if (state is UsersLoading) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Colors
                              .blueAccent)); // Анимация загрузки в твоей гамме
                } else if (state is UsersLoaded) {
                  final filteredUsers = state.users
                      .where((user) =>
                          user.name.toLowerCase().contains(_searchQuery))
                      .toList();
                  if (filteredUsers.isEmpty) {
                    return const Center(
                        child:
                            Text('Нет пользователей или ничего не найдено.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return Dismissible(
                        key: Key(user.id.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors
                              .red, // Красный для delete, вписывается в warning-гамму
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) =>
                            _confirmDelete(context, user),
                        onDismissed: (direction) =>
                            context.read<UsersBloc>().add(DeleteUser(user.id)),
                        child: Card(
                          elevation: 2.0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0)),
                          color: Colors.white, // Белый кард для контраста
                          child: ListTile(
                            title: Text(user.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text('Роль: ${user.role?.name ?? 'Не назначена'}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Colors.blue), // Синий для edit
                              onPressed: () =>
                                  _showUserForm(context, user: user),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                } else if (state is UsersError) {
                  return Center(
                      child: Text('Ошибка: ${state.error}',
                          style: const TextStyle(color: Colors.red)));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserForm(context),
        foregroundColor: Colors.white,
        backgroundColor: Colors.blueAccent, // Адаптируй под accent color
        child: const Icon(Icons.add),
      ),
    );
  }

  // Диалог подтверждения удаления
  Future<bool?> _confirmDelete(BuildContext context, UserInfo user) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Удалить пользователя "${user.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Удалить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  // Диалог формы для создания/обновления
void _showUserForm(BuildContext context, {UserInfo? user}) {
  final isEdit = user != null;
  final loginController = TextEditingController(text: '');
  final nameController = TextEditingController(text: user?.name ?? '');
  final passwordController = TextEditingController(); // Для edit не заполняем
  int? selectedRoleId = user?.role?.id; // Initial value как id (int?), уникальный

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(isEdit ? 'Редактировать пользователя' : 'Добавить пользователя'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'ФИО'),
              ),
              if(!isEdit)
              TextField(
                controller: loginController,
                decoration: const InputDecoration(labelText: 'Логин'),
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: isEdit ? 'Новый пароль (опционально)' : 'Пароль'),
                obscureText: true,
              ),
              BlocBuilder<RolesBloc, RolesState>(
                builder: (context, state) {
                  if (state is RolesLoaded) {
                    if (selectedRoleId == null) {
                      if (isEdit) {
                        // Проверяем, есть ли роль пользователя в списке доступных ролей
                        final userRoleExists = state.roles.any((role) => role.id == user.role?.id);
                        selectedRoleId = userRoleExists ? user.role?.id : null;
                      }
                      // Если роли нет или это создание нового пользователя, выбираем первую доступную
                      selectedRoleId ??= state.roles.isNotEmpty ? state.roles.first.id : null;
                    }
                    return Column(
                      children: [
            
                        if (isEdit && user.role?.id == null)
                        //const SizedBox(height: 12,),
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            margin: const EdgeInsets.only(top: 8.0),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: const Text(
                              'У пользователя не назначена роль. Выберите роль из списка.',
                              style: TextStyle(color: Colors.orange, fontSize: 12),
                            ),
                          ),
                        DropdownButtonFormField<int>(
                          value: selectedRoleId,
                          decoration: const InputDecoration(labelText: 'Роль'),
                          items: state.roles.map((role) => DropdownMenuItem<int>(
                            value: role.id,
                            child: Text(role.name),
                          )).toList(),
                          onChanged: (newId) => selectedRoleId = newId,
                        ),
                      ],
                    );
                  } else if (state is RolesLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is RolesError) {
                    return Column(
                      children: [
                        Text('Ошибка: ${state.error}', style: const TextStyle(color: Colors.red)),
                        TextButton(
                          onPressed: () => context.read<RolesBloc>().add(FetchRoles()),
                          child: const Text('Повторить загрузку'),
                        ),
                      ],
                    );
                  } else {
                    return const Text('Нет данных о ролях');
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              if (nameController.text.isEmpty || (!isEdit && passwordController.text.isEmpty) || selectedRoleId == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Заполните обязательные поля')));
                return;
              }
              final userData = {
                'name': nameController.text,
                if(!isEdit)'login': loginController.text,
                if (passwordController.text.isNotEmpty) 'password': passwordController.text, // Только если не пустой
                'roleId': selectedRoleId, // Теперь напрямую id
                // Добавь другие поля по API (например, boilersAccess)
              };
              if (isEdit) {
                context.read<UsersBloc>().add(UpdateUser(user.id, userData));
              } else {
                context.read<UsersBloc>().add(CreateUser(userData));
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
