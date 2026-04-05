import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'visitor_card.dart';
import 'theme.dart';
import 'loading_shimmer.dart';
import 'empty_state.dart';
import 'providers.dart';
import 'blacklist_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final dynamic supabaseClient;

  const HomeScreen({super.key, this.supabaseClient});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final supabase = Supabase.instance.client;
  int? _lastAlertedId;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
    Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    final wasOffline = _isOffline;
    _isOffline = result.contains(ConnectivityResult.none);

    if (_isOffline != wasOffline && mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      supabase.removeAllChannels();
    } else if (state == AppLifecycleState.resumed) {
      _initConnectivity();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    supabase.removeAllChannels();
    supabase.dispose();
    super.dispose();
  }

  Future<void> _updateVisitorStatus(int id, String status) async {
    await supabase.from('visiteurs').update({'status': status}).eq('id', id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _clearHistory() async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text("⚠️ Tout effacer ?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    "Annuler",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Tout supprimer"),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirm) {
      await supabase.from('visiteurs').delete().gt('id', 0);
    }
  }

  void _showIntruderAlert(Map<String, dynamic> visiteur) { 
    // On enlève la ligne _lastAlertedId car on veut pouvoir cliquer plusieurs fois si besoin
    
    showDialog(
      context: context,
      barrierDismissible: true, // Permet de fermer en cliquant à côté si on a cliqué par erreur
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("⚠️ DÉTECTION EN COURS", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible( // ⬅️ Évite le bug d'affichage jaune et noir !
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  visiteur['image_url'],
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap( // ⬅️ Permet aux boutons de passer à la ligne si l'écran est trop petit
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text("ACCEPTER"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  ),
                  onPressed: () => _updateVisitorStatus(visiteur['id'], 'Accepter'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text("REFUSER"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  ),
                  onPressed: () => _updateVisitorStatus(visiteur['id'], 'Refuser'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SecureHome AI'),
          actions: [
            IconButton(
              icon: const Icon(Icons.block, color: AppColors.error),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BlacklistScreen()),
              ),
              tooltip: "Liste Noire",
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: AppColors.warning),
              onPressed: _clearHistory,
              tooltip: "Vider le tableau de bord",
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.security), text: "Surveillance"),
              Tab(icon: Icon(Icons.history), text: "Tableau de Bord"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [_buildSurveillanceTab(), _buildHistoryTab()],
        ),
      ),
    );
  }

  Widget _buildSurveillanceTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('visiteurs')
          .stream(primaryKey: ['id'])
          .order('id', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerLoading();
        }

        if (snapshot.hasError) {
          return ErrorState(
            message: snapshot.error.toString(),
            onRetry: () => setState(() {}),
          );
        }

        final data = snapshot.data!;

        if (data.isEmpty) {
          return const VisitorsEmptyState();
        }

        // On a supprimé l'apparition automatique du Pop-up ici.
        // Désormais, c'est l'utilisateur qui clique sur la photo !

        return RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: data.length,
            itemBuilder: (context, index) => AnimatedSwitcher(
              duration: AppConstants.animationMedium,
              child: VisitorCard(
                key: ValueKey(data[index]['id']),
                visiteur: data[index],
                supabaseClient: supabase,
                // 👇 LA LIGNE MAGIQUE EST ICI 👇
                onTap: () => _showIntruderAlert(data[index]),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('visiteurs')
          .stream(primaryKey: ['id'])
          .order('id', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const TableShimmerLoading();
        }

        if (snapshot.hasError) {
          return ErrorState(
            message: snapshot.error.toString(),
            onRetry: () => setState(() {}),
          );
        }

        final data = snapshot.data!;

        if (data.isEmpty) {
          return const HistoryEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppColors.surface),
                    columnSpacing: 20,
                    horizontalMargin: 16,
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Heure',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Nom',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Statut',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Vérification',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                    rows: data.map((v) {
                      final nom = v['nom_du_visiteur'] ?? 'Inconnu';
                      final isAuto = nom != 'Inconnu';
                      final status = v['status'] ?? 'pending';
                      final isRefused =
                          status == 'Refuser' || status == 'Terminer';
                      final isFinished =
                          status == 'Accepter' ||
                          status == 'Terminé' ||
                          status == 'Terminer';

                      return DataRow(
                        color: WidgetStateProperty.resolveWith((states) {
                          if (isRefused) {
                            return AppColors.error.withAlpha(25);
                          }
                          return Colors.transparent;
                        }),
                        cells: [
                          DataCell(Text(_formatTime(v['created_at']))),
                          DataCell(Text(nom)),
                          DataCell(
                            Text(
                              status,
                              style: TextStyle(
                                color: isFinished
                                    ? AppColors.success
                                    : isRefused
                                    ? AppColors.error
                                    : AppColors.warning,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isAuto ? Icons.smart_toy : Icons.person,
                                  size: 18,
                                  color: isAuto
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                ),
                                const SizedBox(width: 8),
                                Text(isAuto ? 'Auto (IA)' : 'Manuel'),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatTime(String? createdAt) {
    if (createdAt == null) return '--:--';
    try {
      return DateFormat(
        'HH:mm',
      ).format(DateTime.parse(createdAt).add(const Duration(hours: 1)));
    } catch (_) {
      return '--:--';
    }
  }
}