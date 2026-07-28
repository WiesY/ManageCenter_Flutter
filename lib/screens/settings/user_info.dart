import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/bloc/user_profile_bloc.dart';
import 'package:manage_center/models/user_info_model.dart';
import 'package:manage_center/models/role_model.dart';
import 'package:manage_center/theme/app_theme.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<UserProfileBloc>().add(FetchUserProfile());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Личные данные'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<UserProfileBloc>().add(RefreshUserProfile()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<UserProfileBloc>().add(RefreshUserProfile());
          return Future.delayed(const Duration(milliseconds: 300));
        },
        child: BlocBuilder<UserProfileBloc, UserProfileState>(
          builder: (context, state) {
            if (state is UserProfileLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: context.colors.primary,
                ),
              );
            } else if (state is UserProfileLoaded) {
              return _buildUserProfile(state.userInfo);
            } else if (state is UserProfileError) {
              return _buildErrorState(state.error);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildUserProfile(UserInfo userInfo) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Карточка с основной информацией о пользователе
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Аватар пользователя с инициалами
                CircleAvatar(
                  radius: 50,
                  backgroundColor: context.colors.primaryContainer,
                  child: Text(
                    _getAvatar(userInfo.name),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: context.colors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Имя пользователя
                Text(
                  '${userInfo.name.split(' ')[0]} ${_getInitials(userInfo.name)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // ID пользователя
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.colors.outlineVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ID: ${userInfo.id}',
                    style: TextStyle(
                      color: context.colors.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Карточка с информацией о роли
        if (userInfo.role != null) _buildRoleCard(userInfo.role!),

        const SizedBox(height: 16),

        // Карточка с дополнительной информацией
        _buildAdditionalInfoCard(userInfo),
        const SizedBox(height: 80),
      ],
    ),
  );
}

// Функция для получения инициалов из полного имени
String _getInitials(String fullName) {
  if (fullName.isEmpty) return 'U';
  
  List<String> nameParts = fullName.trim().split(' ');
  
  if (nameParts.length == 1) {
    // Если только одно слово, берем первую букву
    return nameParts[0][0].toUpperCase();
  } else if (nameParts.length >= 2) {
    // Если два или больше слов, берем первые буквы первых двух слов
    return '${nameParts[1][0]}. ${nameParts[2][0]}.'.toUpperCase();
  }
  
  return 'U'; // Fallback
}

String _getAvatar(String fullName) {
  if (fullName.isEmpty) return 'U';
  
  List<String> nameParts = fullName.trim().split(' ');
  
  if (nameParts.length == 1) {
    // Если только одно слово, берем первую букву
    return nameParts[0][0].toUpperCase();
  } else if (nameParts.length >= 2) {
    // Если два или больше слов, берем первые буквы первых двух слов
    return '${nameParts[1][0]}${nameParts[2][0]}'.toUpperCase();
  }
  
  return 'U'; // Fallback
}

  Widget _buildRoleCard(Role role) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: context.colors.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Роль в системе',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        role.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ID: ${role.id}',
                    style: TextStyle(
                      color: context.colors.onSecondaryContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            
            const Text(
              'Права доступа:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Список прав доступа
            _buildPermissionItem(
              'Доступ ко всем объектам',
              role.canAccessAllBoilers,
              Icons.home_work,
            ),
            _buildPermissionItem(
              'Управление аккаунтами',
              role.canManageAccounts,
              Icons.manage_accounts,
            ),
            _buildPermissionItem(
              'Управление объектами',
              role.canManageBoilers,
              Icons.business,
            ),
            _buildPermissionItem(
              'Управление параметрами',
              role.canManageParameters,
              Icons.settings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem(String title, bool hasPermission, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: hasPermission ? context.appColors.success : context.colors.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: hasPermission ? context.colors.onSurface : context.colors.onSurfaceVariant,
              ),
            ),
          ),
          Icon(
            hasPermission ? Icons.check_circle : Icons.cancel,
            color: hasPermission ? context.appColors.success : context.colors.error,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard(UserInfo userInfo) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.colors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: context.colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Дополнительная информация',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildInfoRow('Идентификатор пользователя', userInfo.id.toString()),
            _buildInfoRow('Полное имя', userInfo.name),
            _buildInfoRow(
              'Статус роли', 
              userInfo.role != null ? 'Назначена' : 'Не назначена',
              valueColor: userInfo.role != null ? context.appColors.success : context.colors.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: context.colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor ?? context.colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: context.colors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.colors.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<UserProfileBloc>().add(FetchUserProfile()),
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                        shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}