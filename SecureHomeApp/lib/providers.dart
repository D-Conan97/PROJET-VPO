import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final visitorsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  final supabase = ref.watch(supabaseClientProvider);
  return supabase
      .from('visiteurs')
      .stream(primaryKey: ['id'])
      .order('id', ascending: false);
});

final blacklistProvider = FutureProvider<List<String>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);

  try {
    final response = await supabase.from('blacklist').select('nom_du_visiteur');
    return response.map((e) => e['nom_du_visiteur'] as String).toList();
  } catch (e) {
    return [];
  }
});

bool isBlacklisted(String? visitorName, List<String> blacklist) {
  if (visitorName == null || visitorName.isEmpty) return false;
  return blacklist.contains(visitorName);
}

class VisitorsNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final supabase = ref.watch(supabaseClientProvider);
    final response = await supabase
        .from('visiteurs')
        .select()
        .order('id', ascending: false);
    return response;
  }

  Future<void> updateStatus(int id, String status) async {
    final supabase = ref.read(supabaseClientProvider);
    await supabase.from('visiteurs').update({'status': status}).eq('id', id);
    ref.invalidateSelf();
  }

  Future<void> deleteVisitor(int id) async {
    final supabase = ref.read(supabaseClientProvider);
    await supabase.from('visiteurs').delete().eq('id', id);
    ref.invalidateSelf();
  }

  Future<void> deleteAll() async {
    final supabase = ref.read(supabaseClientProvider);
    await supabase.from('visiteurs').delete().gt('id', 0);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final visitorsNotifierProvider =
    AsyncNotifierProvider<VisitorsNotifier, List<Map<String, dynamic>>>(() {
      return VisitorsNotifier();
    });

enum LoadingStatus { initial, loading, loaded, error }

final loadingStatusProvider = StateProvider<LoadingStatus>(
  (ref) => LoadingStatus.initial,
);
