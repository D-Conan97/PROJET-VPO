import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';

class BlacklistScreen extends ConsumerStatefulWidget {
  const BlacklistScreen({super.key});

  @override
  ConsumerState<BlacklistScreen> createState() => _BlacklistScreenState();
}

class _BlacklistScreenState extends ConsumerState<BlacklistScreen> {
  final _nameController = TextEditingController();
  List<Map<String, dynamic>> _blacklist = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlacklist();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadBlacklist() async {
    final supabase = Supabase.instance.client;
    final response = await supabase.from('blacklist').select('*').order('id', ascending: false);
    setState(() {
      _blacklist = response;
      _isLoading = false;
    });
  }

  Future<void> _addToBlacklist() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final supabase = Supabase.instance.client;
    await supabase.from('blacklist').insert({'nom_du_visiteur': name});
    _nameController.clear();
    await _loadBlacklist();
  }

  Future<void> _removeFromBlacklist(int id) async {
    final supabase = Supabase.instance.client;
    await supabase.from('blacklist').delete().eq('id', id);
    await _loadBlacklist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste Noire'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Ajouter un nom...',
                      filled: true,
                      fillColor: AppColors.surfaceLight.withAlpha(128),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: (_) => _addToBlacklist(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addToBlacklist,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _blacklist.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.block, size: 64, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun nom blacklisté',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _blacklist.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _blacklist[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withAlpha(25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person, color: AppColors.error),
                              ),
                              title: Text(
                                item['nom_du_visiteur'] ?? 'Inconnu',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                onPressed: () => _removeFromBlacklist(item['id']),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
