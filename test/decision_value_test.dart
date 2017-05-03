import 'package:sortree/sortree.dart';
import 'package:test/test.dart';

class TestEntry extends SortTreeEntry {
  final int id;

  final MutableValue<num> cameraDistance = new MutableValue(10.0);

  TestEntry(this.id);

  String toString() => 'TestEntry($id)';
}

void main() {
  group('MutableValue', () {

    group('changing the value', () {
      final value = new MutableValue(1);
      final seen = [];

      value.subscribe('a', (oldValue, newValue) {
        seen.add(['a', oldValue, newValue]);
      });

      value.subscribe('b', (oldValue, newValue) {
        seen.add(['b', oldValue, newValue]);
      });

      value.subscribe('c', (oldValue, newValue) {
        seen.add(['c', oldValue, newValue]);
      });

      value.unsubscribe('b');

      value.value = 2;

      test('correctly updates the value', () {
        expect(value.value, equals(2));
      });

      test('notifies all subscribers', () {
        expect(seen, unorderedEquals([
          ['a', 1, 2],
          ['c', 1, 2]
        ]));
      });
    });
  });

  group('BranchSortCodeFirst', () {
    final entry0 = new TestEntry(0)..cameraDistance.value = 10.0;
    final entry1 = new TestEntry(1)..cameraDistance.value = 20.0;
    final entry2 = new TestEntry(2)..cameraDistance.value = 30.0;

    final collectorNode = new CollectorNode<TestEntry>(
        sortBy: (entry) => entry.cameraDistance,
        branchOrder: Order.ascending,
        sortCode: (node) => new BranchSortCodeFirst(node, 100.0));

    collectorNode..process(entry0)..process(entry1)..process(entry2);

    final seen = [];

    collectorNode.sortCode.subscribe('a', (oldValue, newValue) {
      seen.add(['a', oldValue, newValue]);
    });

    collectorNode.sortCode.subscribe('b', (oldValue, newValue) {
      seen.add(['b', oldValue, newValue]);
    });

    collectorNode.sortCode.subscribe('c', (oldValue, newValue) {
      seen.add(['c', oldValue, newValue]);
    });

    collectorNode.sortCode.unsubscribe('b');

    test('has the correct value', () {
      expect(collectorNode.sortCode.value, equals(10.0));
    });

    group('making a change to an entry that does not change the first branch', () {
      setUp(() {
        seen.clear();
        entry2.cameraDistance.value = 40.0;
      });

      tearDown(() {
        entry2.cameraDistance.value = 30.0;
      });

      test('does not change the value', () {
        expect(collectorNode.sortCode.value, equals(10.0));
      });

      test('does not notify any subscribers', () {
        expect(seen, isEmpty);
      });
    });

    group('after a change to the entry that is the current first branch without changing it', () {
      setUp(() {
        seen.clear();
        entry0.cameraDistance.value = 15.0;
      });

      tearDown(() {
        entry0.cameraDistance.value = 10.0;
      });

      test('correctly changes the value', () {
        expect(collectorNode.sortCode.value, equals(15.0));
      });

      test('correctly notifies the subscribers', () {
        expect(seen, unorderedEquals([
          ['a', 10.0, 15.0],
          ['c', 10.0, 15.0]
        ]));
      });
    });

    group('after a change that changes the first branch', () {
      setUp(() {
        seen.clear();
        entry1.cameraDistance.value = 5.0;
      });

      tearDown(() {
        entry1.cameraDistance.value = 20.0;
      });

      test('correctly changes the value', () {
        expect(collectorNode.sortCode.value, equals(5.0));
      });

      test('correctly notifies the subscribers', () {
        expect(seen, unorderedEquals([
          ['a', 10.0, 5.0],
          ['c', 10.0, 5.0]
        ]));
      });
    });

    group('after emptying the branches', () {
      setUp(() {
        entry0.unlink();
        entry1.unlink();
        entry2.unlink();
      });

      tearDown(() {
        collectorNode..process(entry0)..process(entry1)..process(entry2);
      });

      test('sets the value to the default value', () {
        expect(collectorNode.sortCode.value, equals(100.0));
      });
    });
  });

  group('BranchSortCodeLast', () {
    final entry0 = new TestEntry(0)..cameraDistance.value = 10.0;
    final entry1 = new TestEntry(1)..cameraDistance.value = 20.0;
    final entry2 = new TestEntry(2)..cameraDistance.value = 30.0;

    final collectorNode = new CollectorNode<TestEntry>(
        sortBy: (entry) => entry.cameraDistance,
        branchOrder: Order.ascending,
        sortCode: (node) => new BranchSortCodeLast(node, 100.0));

    collectorNode..process(entry0)..process(entry1)..process(entry2);

    final seen = [];

    collectorNode.sortCode.subscribe('a', (oldValue, newValue) {
      seen.add(['a', oldValue, newValue]);
    });

    collectorNode.sortCode.subscribe('b', (oldValue, newValue) {
      seen.add(['b', oldValue, newValue]);
    });

    collectorNode.sortCode.subscribe('c', (oldValue, newValue) {
      seen.add(['c', oldValue, newValue]);
    });

    collectorNode.sortCode.unsubscribe('b');

    test('has the correct value', () {
      expect(collectorNode.sortCode.value, equals(30.0));
    });

    group('making a change to an entry that does not change the first branch', () {
      setUp(() {
        seen.clear();
        entry0.cameraDistance.value = 5.0;
      });

      tearDown(() {
        entry0.cameraDistance.value = 10.0;
      });

      test('does not change the value', () {
        expect(collectorNode.sortCode.value, equals(30.0));
      });

      test('does not notify any subscribers', () {
        expect(seen, isEmpty);
      });
    });

    group('after a change to the entry that is the current last branch without changing it', () {
      setUp(() {
        seen.clear();
        entry2.cameraDistance.value = 25.0;
      });

      tearDown(() {
        entry2.cameraDistance.value = 30.0;
      });

      test('correctly changes the value', () {
        expect(collectorNode.sortCode.value, equals(25.0));
      });

      test('correctly notifies the subscribers', () {
        expect(seen, unorderedEquals([
          ['a', 30.0, 25.0],
          ['c', 30.0, 25.0]
        ]));
      });
    });

    group('after a change that changes the first branch', () {
      setUp(() {
        seen.clear();
        entry1.cameraDistance.value = 35.0;
      });

      tearDown(() {
        entry1.cameraDistance.value = 20.0;
      });

      test('correctly changes the value', () {
        expect(collectorNode.sortCode.value, equals(35.0));
      });

      test('correctly notifies the subscribers', () {
        expect(seen, unorderedEquals([
          ['a', 30.0, 35.0],
          ['c', 30.0, 35.0]
        ]));
      });
    });

    group('after emptying the branches', () {
      setUp(() {
        entry0.unlink();
        entry1.unlink();
        entry2.unlink();
      });

      tearDown(() {
        collectorNode..process(entry0)..process(entry1)..process(entry2);
      });

      test('sets the value to the default value', () {
        expect(collectorNode.sortCode.value, equals(100.0));
      });
    });
  });
}
