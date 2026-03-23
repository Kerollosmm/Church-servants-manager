import 'dart:async';

import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/servant/presentation/bloc/servant_data/servant_data_cubit.dart';
import 'package:church_management_system/features/servant/presentation/widgets/servant_list_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServantListCoordinator extends StatefulWidget {
  const ServantListCoordinator({super.key});

  @override
  State<ServantListCoordinator> createState() => _ServantListCoordinatorState();
}

class _ServantListCoordinatorState extends State<ServantListCoordinator> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    final actor = _currentActorOrNull();
    if (actor != null) {
      context.read<ServantDataCubit>().loadServants(
        actor: actor,
        includeArchived: _showArchived,
      );
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  AuthUser? _currentActorOrNull() {
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) return state.user;
    if (state is AuthDegraded) return state.user;
    return null;
  }

  void _onSearchChanged(AuthUser actor, String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      context.read<ServantDataCubit>().searchServants(
        actor: actor,
        query: value,
        includeArchived: _showArchived,
      );
    });
  }

  void _clearSearch(AuthUser actor) {
    _searchController.clear();
    context.read<ServantDataCubit>().searchServants(
      actor: actor,
      query: '',
      includeArchived: _showArchived,
    );
  }

  Future<void> _refresh(AuthUser actor) async {
    await context.read<ServantDataCubit>().refreshServants(
      actor: actor,
      includeArchived: _showArchived,
    );
  }

  Future<void> _openServantDetail(AuthUser actor, ServantModel servant) async {
    final result = await Navigator.pushNamed(
      context,
      servantDetail,
      arguments: ServantDetailArgs(actor: actor, servant: servant),
    );
    if (!mounted || result != true) return;
    await _refresh(actor);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final actor = switch (authState) {
          AuthAuthenticated() => authState.user,
          AuthDegraded() => authState.user,
          _ => null,
        };

        if (actor == null) {
          return const Scaffold(
            body: Center(child: Text('لم يتم تسجيل الدخول.')),
          );
        }

        return ServantListScaffold(
          actor: actor,
          showArchived: _showArchived,
          searchController: _searchController,
          onToggleArchived: () {
            setState(() => _showArchived = !_showArchived);
            context.read<ServantDataCubit>().loadServants(
              actor: actor,
              includeArchived: _showArchived,
            );
          },
          onRefresh: () => _refresh(actor),
          onSearchChanged: (value) => _onSearchChanged(actor, value),
          onSearchSubmitted: (value) {
            context.read<ServantDataCubit>().searchServants(
              actor: actor,
              query: value,
              includeArchived: _showArchived,
            );
          },
          onClearSearch: () => _clearSearch(actor),
          onOpenServantDetail: (servant) => _openServantDetail(actor, servant),
          onLoadMore: () {
            context.read<ServantDataCubit>().loadMoreServants(
              actor: actor,
              includeArchived: _showArchived,
            );
          },
        );
      },
    );
  }
}
