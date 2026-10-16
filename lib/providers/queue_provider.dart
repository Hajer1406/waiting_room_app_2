import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waiting_room_app/models/client.dart';

class QueueProvider extends ChangeNotifier {
  final List<Client> _clients = [];
  List<Client> get clients => List.unmodifiable(_clients);

  final SupabaseClient? _supabase;
  RealtimeChannel? _channel;

  QueueProvider({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? _getSafeSupabaseClient() {
    if (_supabase != null) {
      _fetchInitialClients();
      _setupRealtimeSubscription();
    }
  }

  // Constructors for testing
  QueueProvider.forTesting(SupabaseClient supabase) : _supabase = supabase;
  QueueProvider.mock(SupabaseClient supabase) : _supabase = supabase;

  static SupabaseClient? _getSafeSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchInitialClients() async {
    final client = _supabase;
    if (client == null) return;
    try {
      final response = await client
          .from('clients')
          .select()
          .order('created_at', ascending: true);

      _clients.clear();
      for (final item in response) {
        _clients.add(Client.fromMap(item));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching clients: $e');
    }
  }

  void _setupRealtimeSubscription() {
    final client = _supabase;
    if (client == null) return;
    _channel = client
        .channel('public:clients')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'clients',
          callback: (payload) {
            final record = payload.newRecord;
            if (record.isNotEmpty) {
              final newClient = Client.fromMap(record);
              if (!_clients.any((c) => c.id == newClient.id)) {
                _clients.add(newClient);
                _clients.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                notifyListeners();
              }
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'clients',
          callback: (payload) {
            final oldRecord = payload.oldRecord;
            final deletedId = oldRecord['id'];
            if (deletedId != null) {
              _clients.removeWhere((c) => c.id == deletedId);
              notifyListeners();
            }
          },
        )
        .subscribe();
  }

  Future<String?> addClient(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      debugPrint('Cannot add empty client name');
      return 'Client name cannot be empty';
    }

    final client = _supabase;
    if (client == null) {
      _clients.add(Client(
        id: UniqueKey().toString(),
        name: trimmed,
        createdAt: DateTime.now(),
      ));
      notifyListeners();
      return null;
    }

    try {
      final inserted = await client
          .from('clients')
          .insert({'name': trimmed})
          .select()
          .single();

      final newClient = Client.fromMap(inserted);
      if (!_clients.any((c) => c.id == newClient.id)) {
        _clients.add(newClient);
        _clients.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        notifyListeners();
      }
      debugPrint('Client added: $trimmed');
      return null;
    } catch (e) {
      debugPrint('Failed to add client: $e');
      return e.toString();
    }
  }

  Future<String?> removeClient(String id) async {
    final client = _supabase;
    if (client == null) {
      _clients.removeWhere((c) => c.id == id || c.name == id);
      notifyListeners();
      return null;
    }

    try {
      _clients.removeWhere((c) => c.id == id || c.name == id);
      notifyListeners();
      await client.from('clients').delete().eq('id', id);
      debugPrint('Client removed: $id');
      return null;
    } catch (e) {
      debugPrint('Failed to remove client: $e');
      _fetchInitialClients();
      return e.toString();
    }
  }

  Future<String?> nextClient() async {
    if (_clients.isEmpty) {
      debugPrint('Queue is empty!');
      return 'Queue is empty';
    }
    final firstClient = _clients.first;
    final result = await removeClient(firstClient.id);
    debugPrint('Next client: ${firstClient.name}');
    return result;
  }

  @override
  void dispose() {
    final channel = _channel;
    final client = _supabase;
    if (channel != null && client != null) {
      client.removeChannel(channel);
    }
    super.dispose();
  }
}