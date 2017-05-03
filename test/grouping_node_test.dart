import 'package:sortree/sortree.dart';
import 'package:test/test.dart';

class Material {
  final int id;

  Material(this.id);

  String toString() => 'Material($id)';
}

class TestEntry extends SortTreeEntry {
  final int id;

  final MutableValue<Material> material = new MutableValue(null);

  TestEntry(this.id);

  String toString() => 'TestEntry($id)';
}

void main() {
  group('GroupingNode', () {
    final material0 = new Material(0);
    final material1 = new Material(1);
    final material2 = new Material(2);

    group('with branch order unordered', () {
      final entry0 = new TestEntry(0)..material.value = material0;
      final entry1 = new TestEntry(1)..material.value = material1;
      final entry2 = new TestEntry(2)..material.value = material2;
      final entry3 = new TestEntry(3)..material.value = material0;
      final entry4 = new TestEntry(4)..material.value = material1;

      final group0SortCode = new MutableValue(1);
      final group1SortCode = new MutableValue(0);
      final group2SortCode = new MutableValue(2);

      final groupingNode = new GroupingNode<TestEntry, Material>(
          groupBy: (entry) => entry.material,
          makeBranch: (material) {
            if (material == material0) {
              return new CollectorNode<TestEntry>(
                  sortCode: (node) => group0SortCode);
            } else if (material == material1) {
              return new CollectorNode<TestEntry>(
                  sortCode: (node) => group1SortCode);
            } else {
              return new CollectorNode<TestEntry>(
                  sortCode: (node) => group2SortCode);
            }
          },
          sortCode: (node) => new StaticValue(0));

      groupingNode
        ..process(entry0)
        ..process(entry1)
        ..process(entry2)
        ..process(entry3)
        ..process(entry4);

      test('iterates over the entries in the correct order', () {
        expect(groupingNode.toList(), orderedEquals([entry0, entry3, entry1, entry4, entry2]));
      });

      group('after changing the grouping value on an entry', () {
        setUp(() {
          entry3.material.value = material2;
        });

        tearDown(() {
          entry3.material.value = material0;
        });

        test('iterates over the entries in the correct order', () {
          expect(groupingNode.toList(), orderedEquals([entry0, entry1, entry4, entry2, entry3]));
        });
      });

      group('after changing the sort code on one of the branches', () {
        setUp(() {
          group0SortCode.value = 3;
        });

        tearDown(() {
          group0SortCode.value = 1;
        });

        test('the iteration order does not change', () {
          expect(groupingNode.toList(), orderedEquals([entry0, entry3, entry1, entry4, entry2]));
        });
      });
    });

    group('with branch order ascending', () {
      final entry0 = new TestEntry(0)..material.value = material0;
      final entry1 = new TestEntry(1)..material.value = material1;
      final entry2 = new TestEntry(2)..material.value = material2;
      final entry3 = new TestEntry(3)..material.value = material0;
      final entry4 = new TestEntry(4)..material.value = material1;

      final group0SortCode = new MutableValue(1);
      final group1SortCode = new MutableValue(0);
      final group2SortCode = new MutableValue(2);

      final groupingNode = new GroupingNode<TestEntry, Material>(
          groupBy: (entry) => entry.material,
          makeBranch: (material) {
            if (material == material0) {
              return new CollectorNode<TestEntry>(
                  sortCode: (node) => group0SortCode);
            } else if (material == material1) {
              return new CollectorNode<TestEntry>(
                  sortCode: (node) => group1SortCode);
            } else {
              return new CollectorNode<TestEntry>(
                  sortCode: (node) => group2SortCode);
            }
          },
          sortCode: (node) => new StaticValue(0),
          branchOrder: Order.ascending);

      groupingNode
        ..process(entry0)
        ..process(entry1)
        ..process(entry2)
        ..process(entry3)
        ..process(entry4);

      test('iterates over the entries in the correct order', () {
        expect(groupingNode.toList(), orderedEquals([entry1, entry4, entry0, entry3, entry2]));
      });

      group('after changing the sort code for one of the branches', () {
        setUp(() {
          group0SortCode.value = 3;
        });

        tearDown(() {
          group0SortCode.value = 1;
        });

        test('iterates over the entries in the correct order', () {
          expect(groupingNode.toList(), orderedEquals([entry1, entry4, entry2, entry0, entry3]));
        });
      });
    });

    group('with branch order descending', () {
      final entry0 = new TestEntry(0)..material.value = material0;
      final entry1 = new TestEntry(1)..material.value = material1;
      final entry2 = new TestEntry(2)..material.value = material2;
      final entry3 = new TestEntry(3)..material.value = material0;
      final entry4 = new TestEntry(4)..material.value = material1;

      final group0SortCode = new MutableValue(1);
      final group1SortCode = new MutableValue(0);
      final group2SortCode = new MutableValue(2);

      final groupingNode = new GroupingNode<TestEntry, Material>(
          groupBy: (entry) => entry.material,
          makeBranch: (material) {
            if (material == material0) {
              return new CollectorNode<TestEntry>(
                  sortCode: (node) => group0SortCode);
            } else if (material == material1) {
              return new CollectorNode<TestEntry>(
                  sortCode: (node) => group1SortCode);
            } else {
              return new CollectorNode<TestEntry>(
                  sortCode: (node) => group2SortCode);
            }
          },
          sortCode: (node) => new StaticValue(0),
          branchOrder: Order.descending);

      groupingNode
        ..process(entry0)
        ..process(entry1)
        ..process(entry2)
        ..process(entry3)
        ..process(entry4);

      test('iterates over the entries in the correct order', () {
        expect(groupingNode.toList(), orderedEquals([entry2, entry0, entry3, entry1, entry4]));
      });

      group('after changing the sort code for one of the branches', () {
        setUp(() {
          group0SortCode.value = 3;
        });

        tearDown(() {
          group0SortCode.value = 1;
        });

        test('iterates over the entries in the correct order', () {
          expect(groupingNode.toList(), orderedEquals([entry0, entry3, entry2, entry1, entry4]));
        });
      });
    });
  });
}
