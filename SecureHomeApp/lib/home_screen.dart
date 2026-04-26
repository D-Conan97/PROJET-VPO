import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'visitor_card.dart';
import 'theme.dart';
import 'loading_shimmer.dart';
import 'empty_state.dart';
import 'blacklist_screen.dart';
import 'door_animation.dart';
import 'providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Clé combinée (ID + Nom) pour régler le problème de répétition des pop-ups
  String? _lastHandledEventKey; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleVisitorAction(Map<String, dynamic> v, String status) {
    ref.read(visitorsNotifierProvider.notifier).updateStatus(v['id'], status);
    Navigator.pop(context);
  }

  void _showIntruderAlert(Map<String, dynamic> visiteur) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), 
        ),
        backgroundColor: Colors.white,
        child: Container(
          width: 600, 
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40), 
                  const Row(
                    children: [
                      Icon(Icons.visibility, color: Colors.black87, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "DÉTAILS DU VISITEUR",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Supprimer ce visiteur ?'),
                          content: const Text('Cette action effacera la photo de l\'accueil et du tableau de bord. C\'est irréversible.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Supprimer'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          await ref.read(supabaseClientProvider)
                              .from('visiteurs') 
                              .delete()
                              .eq('id', visiteur['id']);
                          if (mounted) Navigator.pop(context);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur lors de la suppression : $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  visiteur['image_url'] ?? '',
                  width: double.infinity,
                  height: 350,
                  fit: BoxFit.cover, 
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 350,
                    color: Colors.grey[200],
                    child: const Icon(Icons.person, size: 100, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text("ACCEPTER"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71), 
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    onPressed: () => _handleVisitorAction(visiteur, 'Accepter'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text("REFUSER"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4C4C), 
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    onPressed: () => _handleVisitorAction(visiteur, 'Refuser'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visitorsAsync = ref.watch(visitorsStreamProvider);
    final blacklistAsync = ref.watch(blacklistProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.door_front_door_outlined),
        title: const Text('SecureHome AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.block, color: AppColors.error),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BlacklistScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: AppColors.warning),
            onPressed: () async {
              final confirm = await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Supprimer tout ?"),
                  content: const Text("Cette action est irréversible."),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Non")),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Oui")),
                  ],
                ),
              );

              if (confirm == true) {
                ref.read(visitorsNotifierProvider.notifier).deleteAll();
              }
            },
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
        children: [
          _buildSurveillance(visitorsAsync, blacklistAsync),
          _buildHistory(visitorsAsync),
        ],
      ),
    );
  }

  Widget _buildSurveillance(AsyncValue visitorsAsync, AsyncValue blacklistAsync) {
    return visitorsAsync.when(
      loading: () => const ShimmerLoading(),
      error: (e, _) => ErrorState(message: e.toString()),
      data: (data) {
        if (data.isEmpty) return const VisitorsEmptyState();

        final rawBlacklist = blacklistAsync.value ?? [];
        final List<String> blacklist = List<String>.from(
          rawBlacklist.map((item) => item.toString())
        );

        final latest = data.first;
        final name = latest['nom_du_visiteur'];
        final status = latest['status'] ?? 'pending';

        // CORRECTION 1 : On sécurise le mot "inconnu" (majuscules/espaces)
        final normalizedName = name?.trim().toLowerCase() ?? 'inconnu';
        final isKnown = normalizedName != 'inconnu';
        final isBlocked = isBlacklisted(name, blacklist);

        // --- CALCUL DE L'ÉTAT DE LA PORTE EN TEMPS RÉEL ---
        bool isDoorOpen = false;
        
        if (isBlocked) {
          isDoorOpen = false; 
          if (status != 'Refuser') {
            Future.microtask(() => ref.read(visitorsNotifierProvider.notifier).updateStatus(latest['id'], 'Refuser'));
          }
        } else if (status == 'Refuser') {
          // CORRECTION 2 : RÈGLE ABSOLUE. Si c'est refusé, on verrouille.
          isDoorOpen = false; 
        } else if (status == 'Accepter') {
          isDoorOpen = true; 
        } else if (isKnown) {
          isDoorOpen = true; 
          if (status != 'Accepter') {
            Future.microtask(() => ref.read(visitorsNotifierProvider.notifier).updateStatus(latest['id'], 'Accepter'));
          }
        }

        // --- GESTION DES NOTIFICATIONS ---
        final currentEventKey = "${latest['id']}_$name";
        if (_lastHandledEventKey != currentEventKey) {
          _lastHandledEventKey = currentEventKey;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (isBlocked) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("⛔ $name est blacklisté"), backgroundColor: AppColors.error),
              );
            } else if (isKnown) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("✅ Accès autorisé: $name"), backgroundColor: AppColors.success),
              );
              if (Navigator.canPop(context)) Navigator.pop(context);
            } else if (status == 'pending') {
              _showIntruderAlert(latest);
            }
          });
        }

        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final visitor = data[i];
                    final visitorName = visitor['nom_du_visiteur'];
                    final isBlockedItem = isBlacklisted(visitorName, blacklist);

                    return AnimatedSwitcher(
                      duration: AppConstants.animationMedium,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: isBlockedItem
                            ? BoxDecoration(
                                border: Border.all(color: AppColors.error, width: 3),
                                borderRadius: BorderRadius.circular(16),
                              )
                            : null,
                        child: Stack(
                          children: [
                            VisitorCard(
                              key: ValueKey(visitor['id']),
                              visiteur: visitor,
                              supabaseClient: ref.read(supabaseClientProvider),
                              onTap: () {
                                _showIntruderAlert(visitor);
                              },
                            ),
                            if (isBlockedItem)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        "BLACKLISTED",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 260,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isDoorOpen ? "ACCÈS OUVERT" : "ACCÈS VERROUILLÉ",
                      style: TextStyle(
                        color: isDoorOpen ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedDoor(isOpen: isDoorOpen),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildHistory(AsyncValue visitorsAsync) {
    return visitorsAsync.when(
      loading: () => const TableShimmerLoading(),
      error: (e, _) => ErrorState(message: e.toString()),
      data: (data) {
        if (data.isEmpty) return const HistoryEmptyState();

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(visitorsStreamProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              width: double.infinity, 
              child: DataTable(
                headingRowHeight: 60,
                dataRowMinHeight: 60,
                dataRowMaxHeight: 60,
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                columns: const [
                  DataColumn(label: Text('Heure')),
                  DataColumn(label: Text('Nom')),
                  DataColumn(label: Text('Statut')),
                  DataColumn(label: Text('Vérification')),
                ],
                rows: data.map<DataRow>((v) {
                  final name = v['nom_du_visiteur'] ?? 'Inconnu';
                  final status = v['status'] ?? 'pending';
                  final isAuto = name != 'Inconnu';

                  Color statusColor;
                  if (status == 'Accepter' || status == 'Terminé') {
                    statusColor = const Color(0xFF2ECC71); 
                  } else if (status == 'Refuser') {
                    statusColor = const Color(0xFFFF4C4C); 
                  } else {
                    statusColor = Colors.orange; 
                  }

                  return DataRow(
                    color: WidgetStateProperty.resolveWith<Color?>((states) {
                      if (status == 'Refuser') {
                        return const Color(0xFFFF4C4C).withOpacity(0.1); 
                      }
                      return null; 
                    }),
                    cells: [
                      DataCell(Text(_formatTime(v['created_at']))),
                      DataCell(Text(name)),
                      DataCell(
                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            Icon(
                              isAuto ? Icons.smart_toy : Icons.person,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isAuto ? 'Auto (IA)' : 'Manuel',
                              style: TextStyle(color: Colors.grey[800]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(String? createdAt) {
    if (createdAt == null) return '--:--';
    try {
      return DateFormat('HH:mm')
          .format(DateTime.parse(createdAt).add(const Duration(hours: 1)));
    } catch (_) {
      return '--:--';
    }
  }
}