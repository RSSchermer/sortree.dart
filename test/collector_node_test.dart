import 'package:sortree/sortree.dart';
import 'package:test/test.dart';

class TestEntry extends SortTreeEntry {
  final int id;

  final MutableValue<num> cameraDistance = new MutableValue(10.0);

  TestEntry(this.id);

  String toString() => 'TestEntry($id)';
}

void main() {
  group('CollectorNode', () {
    group('with branch order unordered', () {
      final entry0 = new TestEntry(0)..cameraDistance.value = 20.0;
      final entry1 = new TestEntry(1)..cameraDistance.value = 10.0;
      final entry2 = new TestEntry(2)..cameraDistance.value = 30.0;

      final collectorNode = new CollectorNode<TestEntry>(
          sortBy: (entry) => entry.cameraDistance,
          sortCode: (node) => new StaticValue(0));

      collectorNode..process(entry0)..process(entry1)..process(entry2);

      test('iterates over the entries in the correct order', () {
        expect(collectorNode.toList(), orderedEquals([entry0, entry1, entry2]));
      });

      group('after changing a sort value', () {
        setUp(() {
          entry1.cameraDistance.value = 40.0;
        });

        tearDown(() {
          entry1.cameraDistance.value = 10.0;
        });

        test('iterates over the entries in the correct order', () {
          expect(collectorNode.toList(), orderedEquals([entry0, entry1, entry2]));
        });
      });
    });

    group('with branch order ascending', () {
      final entry0 = new TestEntry(0)..cameraDistance.value = 20.0;
      final entry1 = new TestEntry(1)..cameraDistance.value = 10.0;
      final entry2 = new TestEntry(2)..cameraDistance.value = 30.0;

      final collectorNode = new CollectorNode<TestEntry>(
          sortBy: (entry) => entry.cameraDistance,
          branchOrder: Order.ascending,
          sortCode: (node) => new StaticValue(0));

      collectorNode..process(entry0)..process(entry1)..process(entry2);

      test('iterates over the entries in the correct order', () {
        expect(collectorNode.toList(), orderedEquals([entry1, entry0, entry2]));
      });

      group('after changing a sort value', () {
        setUp(() {
          entry1.cameraDistance.value = 40.0;
        });

        tearDown(() {
          entry1.cameraDistance.value = 10.0;
        });

        test('iterates over the entries in the correct order', () {
          expect(collectorNode.toList(), orderedEquals([entry0, entry2, entry1]));
        });
      });
    });

    group('with branch order descending', () {
      final entry0 = new TestEntry(0)..cameraDistance.value = 20.0;
      final entry1 = new TestEntry(1)..cameraDistance.value = 10.0;
      final entry2 = new TestEntry(2)..cameraDistance.value = 30.0;

      final collectorNode = new CollectorNode<TestEntry>(
          sortBy: (entry) => entry.cameraDistance,
          branchOrder: Order.descending,
          sortCode: (node) => new StaticValue(0));

      collectorNode..process(entry0)..process(entry1)..process(entry2);

      test('iterates over the entries in the correct order', () {
        expect(collectorNode.toList(), orderedEquals([entry2, entry0, entry1]));
      });

      group('after changing a sort value', () {
        setUp(() {
          entry1.cameraDistance.value = 40.0;
        });

        tearDown(() {
          entry1.cameraDistance.value = 10.0;
        });

        test('iterates over the entries in the correct order', () {
          expect(collectorNode.toList(), orderedEquals([entry1, entry2, entry0]));
        });
      });
    });
  });
}
