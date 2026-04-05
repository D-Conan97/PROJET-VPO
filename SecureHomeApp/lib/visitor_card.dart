import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';

class VisitorCard extends StatelessWidget {
  final Map<String, dynamic> visiteur; // ✅ Remplacé 'visuel' par 'visiteur'
  final dynamic supabaseClient;
  final VoidCallback? onTap;

  const VisitorCard({
    super.key,
    required this.visiteur, // ✅ Remplacé 'visual' par 'visiteur'
    this.supabaseClient,
    this.onTap,
  });

  dynamic get supabase => supabaseClient ?? Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = visiteur['image_url'];
    final String status = visiteur['status'] ?? 'pending';

    final bool isAccepted =
        status == 'Accepter' || status == 'Terminé' || status == 'Terminer';
    final bool isRefused = status == 'Refuser';
    final statusColor = isAccepted
        ? AppColors.success
        : isRefused
        ? AppColors.error
        : AppColors.warning;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: statusColor.withAlpha(50),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 👇 Ajout du GestureDetector pour cliquer sur la photo
                  GestureDetector(
                    onTap: status == 'pending' ? onTap : null, // Cliquable uniquement si "pending"
                    child: (imageUrl != null && imageUrl.isNotEmpty)
                        ? Image.network(
                            imageUrl,
                            height: 400,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.card.withAlpha(0),
                          AppColors.surface.withAlpha(230),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  visiteur['nom_du_visiteur'] ?? 'Inconnu',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: statusColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isAccepted
                                  ? Icons.check_circle
                                  : isRefused
                                  ? Icons.cancel
                                  : Icons.pending,
                              color: statusColor,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () async {
                    bool? confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: const Text("Supprimer ?"),
                        content: const Text(
                          "Voulez-vous supprimer cette photo ?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Non"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              "Oui",
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await supabase
                          .from('visiteurs')
                          .delete()
                          .eq('id', visiteur['id']);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 350,
      color: AppColors.surface,
      child: const Center(
        child: Icon(Icons.person, size: 100, color: AppColors.textMuted),
      ),
    );
  }
}