import 'package:flutter_test/flutter_test.dart';
import 'package:waiting_room_app/queue_provider.dart';

void main() {
  test('should remove the first client when nextClient() is called', () {
    final provider = QueueProvider();

    provider.addClient('Client A');
    provider.addClient('Client B');

    provider.nextClient();

    expect(provider.clients.length, 1);
    expect(provider.clients.first, 'Client B');
  });
}