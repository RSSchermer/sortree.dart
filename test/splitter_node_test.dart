import 'package:sortree/sortree.dart';
import 'package:test/test.dart';

class TestEntry extends SortTreeEntry {
  final int id;

  final MutableValue<num> opacity = new MutableValue(1.0);

  TestEntry(this.id);

  String toString() => 'TestEntry($id)';
}

void main() {
  group('SplitterNode', () {
    group('with branch order unordered', () {
      final successSortCode = new MutableValue(0);
      final failureSortCode = new MutableValue(0);
      final splitter = new SplitterNode<TestEntry, num>(
          on: (entry) => entry.opacity,
          test: (opacity) => opacity >= 1.0,
          successBranch: new CollectorNode<TestEntry>(
              sortCode: (node) => successSortCode),
          failureBranch: new CollectorNode<TestEntry>(
              sortCode: (node) => failureSortCode),
          sortCode: (node) => new StaticValue(0));

      final entry0 = new TestEntry(0)..opacity.value = 1.0;
      final entry1 = new TestEntry(1)..opacity.value = 0.0;
      final entry2 = new TestEntry(2)..opacity.value = 0.0;
      final entry3 = new TestEntry(3)..opacity.value = 1.0;

      splitter
        ..process(entry0)
        ..process(entry1)
        ..process(entry2)
        ..process(entry3);

      test('iterates over the entries in the correct order', () {
        expect(splitter.toList(), orderedEquals([entry0, entry3, entry1, entry2]));
      });

      group('trying to unlink the success branch', () {
        final successBranch = splitter.successBranch;
        final result = successBranch.unlink();

        test('returns false', () {
          expect(result, isFalse);
        });

        test('does not change the success branch', () {
          expect(splitter.successBranch, equals(successBranch));
        });
      });

      group('trying to unlink the failure branch', () {
        final failureBranch = splitter.failureBranch;
        final result = failureBranch.unlink();

        test('returns false', () {
          expect(result, isFalse);
        });

        test('does not change the success branch', () {
          expect(splitter.failureBranch, equals(failureBranch));
        });
      });

      group('after changing a splitter value', () {
        setUp(() {
          entry0.opacity.value = 0.0;
        });

        tearDown(() {
          entry0.opacity.value = 1.0;
          entry3.unlink();
          splitter.process(entry3);
        });

        test('iterates over the entries in the correct order', () {
          expect(splitter.toList(), orderedEquals([entry3, entry1, entry2, entry0]));
        });
      });

      group('after changing the sort code of the success branch', () {
        setUp(() {
          successSortCode.value = 1;
        });

        tearDown(() {
          successSortCode.value = 0;
        });

        test('iterates over the entries in the correct order', () {
          expect(splitter.toList(), orderedEquals([entry0, entry3, entry1, entry2]));
        });
      });

      group('after changing the sort code of the failure branch', () {
        setUp(() {
          failureSortCode.value = 1;
        });

        tearDown(() {
          failureSortCode.value = 0;
        });

        test('iterates over the entries in the correct order', () {
          expect(splitter.toList(), orderedEquals([entry0, entry3, entry1, entry2]));
        });
      });
    });

    group('with branch order ascending', () {
      final successSortCode = new MutableValue(1);
      final failureSortCode = new MutableValue(0);
      final splitter = new SplitterNode<TestEntry, num>(
          on: (entry) => entry.opacity,
          test: (opacity) => opacity >= 1.0,
          successBranch: new CollectorNode<TestEntry>(
              sortCode: (node) => successSortCode),
          failureBranch: new CollectorNode<TestEntry>(
              sortCode: (node) => failureSortCode),
          sortCode: (node) => new StaticValue(0),
          branchOrder: Order.ascending);

      final entry0 = new TestEntry(0)..opacity.value = 1.0;
      final entry1 = new TestEntry(1)..opacity.value = 0.0;
      final entry2 = new TestEntry(2)..opacity.value = 0.0;
      final entry3 = new TestEntry(3)..opacity.value = 1.0;

      splitter
        ..process(entry0)
        ..process(entry1)
        ..process(entry2)
        ..process(entry3);

      test('iterates over the entries in the correct order', () {
        expect(splitter.toList(), orderedEquals([entry1, entry2, entry0, entry3]));
      });

      group('after changing the sort code of the success branch', () {
        setUp(() {
          successSortCode.value = -1;
        });

        tearDown(() {
          successSortCode.value = 1;
        });

        test('iterates over the entries in the correct order', () {
          expect(splitter.toList(), orderedEquals([entry0, entry3, entry1, entry2]));
        });
      });

      group('after changing the sort code of the failure branch', () {
        setUp(() {
          failureSortCode.value = 2;
        });

        tearDown(() {
          failureSortCode.value = 0;
        });

        test('iterates over the entries in the correct order', () {
          expect(splitter.toList(), orderedEquals([entry0, entry3, entry1, entry2]));
        });
      });
    });

    group('with branch order descending', () {
      final successSortCode = new MutableValue(0);
      final failureSortCode = new MutableValue(1);
      final splitter = new SplitterNode<TestEntry, num>(
          on: (entry) => entry.opacity,
          test: (opacity) => opacity >= 1.0,
          successBranch: new CollectorNode<TestEntry>(
              sortCode: (node) => successSortCode),
          failureBranch: new CollectorNode<TestEntry>(
              sortCode: (node) => failureSortCode),
          sortCode: (node) => new StaticValue(0),
          branchOrder: Order.descending);

      final entry0 = new TestEntry(0)..opacity.value = 1.0;
      final entry1 = new TestEntry(1)..opacity.value = 0.0;
      final entry2 = new TestEntry(2)..opacity.value = 0.0;
      final entry3 = new TestEntry(3)..opacity.value = 1.0;

      splitter
        ..process(entry0)
        ..process(entry1)
        ..process(entry2)
        ..process(entry3);

      test('iterates over the entries in the correct order', () {
        expect(splitter.toList(), orderedEquals([entry1, entry2, entry0, entry3]));
      });

      group('after changing the sort code of the success branch', () {
        setUp(() {
          successSortCode.value = 2;
        });

        tearDown(() {
          successSortCode.value = 0;
        });

        test('iterates over the entries in the correct order', () {
          expect(splitter.toList(), orderedEquals([entry0, entry3, entry1, entry2]));
        });
      });

      group('after changing the sort code of the failure branch', () {
        setUp(() {
          failureSortCode.value = -1;
        });

        tearDown(() {
          failureSortCode.value = 1;
        });

        test('iterates over the entries in the correct order', () {
          expect(splitter.toList(), orderedEquals([entry0, entry3, entry1, entry2]));
        });
      });
    });
  });
}
