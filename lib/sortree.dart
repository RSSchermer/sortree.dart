/// A tree-like data structure that can be used for efficient, persistent,
/// complex sorting.
library sortree;

import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:quiver/collection.dart';

part 'src/branches.dart';
part 'src/collector_node.dart';
part 'src/decision_value.dart';
part 'src/grouping_node.dart';
part 'src/splitter_node.dart';

typedef DecisionValue<V> DecisionValueResolver<T extends SortTreeEntry, V>(
    T entry);
typedef DecisionValue<num> BranchingNodeSortCodeProvider<
    T extends SortTreeEntry>(BranchingNode<T> node);

/// Enumerates the ways in which a [BranchNode]'s branches may be ordered.
enum Order { ascending, descending, unordered }

/// Abstract base class for the nodes in a sort tree.
abstract class SortTreeNode {
  SortTreeNode _previousSibling;

  SortTreeNode _nextSibling;

  BranchingNode _parentNode;

  DecisionValue<num> _sortCode;

  /// If possible, disconnects this [SortTreeNode] from the tree.
  ///
  /// Returns `true` if this [SortTreeNode] was unlinked successfully, `false`
  /// otherwise.
  ///
  /// If successful, leaves the node parentless and without siblings; a root
  /// node.
  bool unlink();

  void _accept(_SortTreeVisitor visitor);
}

/// A non-terminal node in a sort tree.
///
/// Implements [Iterable] over the [SortTreeEntry]s in its sub-tree. The order
/// is maintained automatically and each iteration should present the entries
/// in the an order that reflects the sorter nodes in this sub-tree.
abstract class BranchingNode<T extends SortTreeEntry> extends SortTreeNode
    implements Iterable<T> {
  _Branches get _branches;

  /// The branches of this [BranchingNode].
  Iterable<SortTreeNode> get branches;

  /// The sort code for this [BranchingNode].
  ///
  /// Used by the parent node to determine the positioning of this
  /// [BranchingNode] amongst its sibling nodes (if it has any).
  DecisionValue<num> get sortCode;

  /// Processes the [entry].
  ///
  /// Passes the [entry] down one of this [BranchingNode]'s branches until
  /// it can be inserted as a terminal leaf node in the sort tree.
  void process(T entry);

  bool _removeBranch(SortTreeNode branch);

  void _cancelSubscriptions(SortTreeEntry entry);

  void _handleBranchesChanged(
      {bool firstChanged: false, bool lastChanged: false});

  void _handleEmptyBranch(BranchingNode<T> branch);
}

/// Base class that entries for a sort tree must extend.
abstract class SortTreeEntry extends SortTreeNode {
  bool unlink() {
    if (_parentNode == null) {
      return false;
    } else {
      _parentNode._cancelSubscriptions(this);

      var parentNode = _parentNode._parentNode;

      while (parentNode != null) {
        parentNode._cancelSubscriptions(this);
        parentNode = parentNode._parentNode;
      }

      return _parentNode._removeBranch(this);
    }
  }

  void _accept(_SortTreeVisitor visitor) {
    visitor.visitSortTreeEntry(this);
  }

  void _reprocess(BranchingNode reentryNode) {
    var parent = _parentNode;

    while (parent != null && parent != reentryNode) {
      parent._cancelSubscriptions(this);
      parent = parent._parentNode;
    }

    unlink();
    reentryNode.process(this);
  }
}

/// Defines an interface for [SortTreeNode] visitors.
abstract class _SortTreeVisitor<T extends SortTreeEntry> {
  /// Visit a [BranchingNode].
  void visitBranchingNode(BranchingNode<T> node);

  /// Visit a terminal [SortTreeEntry].
  void visitSortTreeEntry(T node);
}

class _SortTreeEntryIterator<T extends SortTreeEntry>
    implements Iterator<T>, _SortTreeVisitor<T> {
  final SortTreeNode rootNode;

  T _currentNode = null;

  bool _moveDown = true;

  bool _terminated = false;

  _SortTreeEntryIterator(this.rootNode);

  T get current => _currentNode;

  bool moveNext() {
    (_currentNode ?? rootNode)._accept(this);

    return !_terminated;
  }

  void visitSortTreeEntry(T node) {
    if (_moveDown) {
      _moveDown = false;

      _currentNode = node;
    } else {
      if (node._nextSibling != null) {
        _moveDown = true;

        node._nextSibling._accept(this);
      } else if (node._parentNode != null) {
        node._parentNode._accept(this);
      } else {
        _terminated = true;
      }
    }
  }

  void visitBranchingNode(BranchingNode<T> node) {
    if (_moveDown) {
      final firstChild = node.branches.first;

      if (firstChild != null) {
        firstChild._accept(this);
      } else {
        _moveDown = false;

        node._accept(this);
      }
    } else {
      if (node._nextSibling != null) {
        _moveDown = true;

        node._nextSibling._accept(this);
      } else if (node._parentNode != null) {
        node._parentNode._accept(this);
      } else {
        _terminated = true;
      }
    }
  }
}
