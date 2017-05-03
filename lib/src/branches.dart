part of sortree;

/// Represent the branches of a [BranchingNode].
abstract class _Branches extends Iterable<SortTreeNode> {
  /// The [BranchingNode] to which these [_Branches] belong.
  BranchingNode get owner;

  /// The way in which these [_Branches] are sorted.
  Order get sortOrder;

  /// Creates a new [_Branches] instance in which the [SortTreeNode]s are
  /// presented in the given [sortOrder].
  factory _Branches(BranchingNode owner, Order sortOrder) {
    if (sortOrder == Order.ascending) {
      return new _BranchesAscending(owner);
    } else if (sortOrder == Order.descending) {
      return new _BranchesDescending(owner);
    } else {
      return new _UnsortedBranches(owner);
    }
  }

  /// Creates a new [_Branches] instance in which the [SortTreeNode]s are
  /// presented in insertion order.
  factory _Branches.unsorted(BranchingNode owner) = _UnsortedBranches;

  /// Creates a new [_Branches] instance in which the [SortTreeNode]s are
  /// presented in ascending sort code order.
  factory _Branches.ascending(BranchingNode owner) = _BranchesAscending;

  /// Creates a new [_Branches] instance in which the [SortTreeNode]s are
  /// presented in descending sort code order.
  factory _Branches.descending(BranchingNode owner) = _BranchesDescending;

  /// Adds the [node] to these [_Branches].
  ///
  /// Does nothing if the [owner] is already the [node]'s parent.
  ///
  /// Throws a [StateError] if the [node] already has another parent node.
  void add(SortTreeNode node);

  /// Removes the [node] from these [_Branches].
  ///
  /// Returns `true` if the [node] was a branch of the [owner], `false`
  /// otherwise. Leaves the node parentless and without siblings; a root node.
  bool remove(SortTreeNode node);
}

/// Implementation of [_Branches] in which child nodes are sorted by their
/// sort code in ascending order.
///
/// New child nodes are inserted in order. However, changes to sort codes at a
/// later time may degenerate the order of the nodes. Call [sort] to rearrange
/// the nodes in the expected order.
class _BranchesAscending extends IterableBase<SortTreeNode>
    implements _Branches {
  final BranchingNode owner;

  final Order sortOrder = Order.ascending;

  /// Creates a new [AscendingChildNodes] instance for the given [owner].
  _BranchesAscending(this.owner);

  int _length = 0;

  SortTreeNode _first;

  SortTreeNode _last;

  SortTreeNode get first => _first;

  SortTreeNode get last => _last;

  bool get isEmpty => _length == 0;

  bool get isNotEmpty => _length > 0;

  int get length => _length;

  Iterator<SortTreeNode> get iterator => new _BranchIterator(this);

  void add(SortTreeNode node) {
    if (node._parentNode == null) {
      node._parentNode = owner;

      if (isEmpty) {
        _length = 1;
        _first = node;
        _last = node;

        owner._handleBranchesChanged(firstChanged: true, lastChanged: true);
      } else {
        _length++;

        var currentNode = _first;

        while (currentNode != null &&
            currentNode._sortCode.value < node._sortCode.value) {
          currentNode = currentNode._nextSibling;
        }

        if (currentNode == null) {
          _last._nextSibling = node;
          node._previousSibling = _last;
          _last = node;

          owner._handleBranchesChanged(lastChanged: true);
        } else {
          final previousNode = currentNode._previousSibling;

          if (previousNode == null) {
            _first._previousSibling = node;
            node._nextSibling = _first;
            _first = node;

            owner._handleBranchesChanged(firstChanged: true);
          } else {
            currentNode._previousSibling = node;
            node._nextSibling = currentNode;
            node._previousSibling = previousNode;
            previousNode._nextSibling = node;

            owner._handleBranchesChanged();
          }
        }
      }

      node._sortCode.subscribe(this, (oldValue, newValue) {
        if (newValue < oldValue) {
          final previousSibling = node._previousSibling;

          // Check if node is not initial node (which has no previous
          // sibling). If it already is the initial node, then nothing needs
          // to happen (it's already shifted as far forward as it can be).
          if (previousSibling != null) {
            var targetNode = node._previousSibling;

            while (
            targetNode != null && targetNode._sortCode.value > newValue) {
              targetNode = targetNode._previousSibling;
            }

            // If after searching the currentNode is still the previousNode,
            // then the node was already in the right position and does not
            // need to be moved.
            if (targetNode != previousSibling) {
              // Node does in fact need to be moved so excise it
              if (node == _last) {
                previousSibling._nextSibling = null;
                _last = previousSibling;

                owner._handleBranchesChanged(lastChanged: true);
              } else {
                final nextSibling = node._nextSibling;

                previousSibling._nextSibling = nextSibling;
                nextSibling?._previousSibling = previousSibling;
              }

              // And then reinsert it earlier in the chain
              if (targetNode == null) {
                _first._previousSibling = node;
                node._nextSibling = _first;
                node._previousSibling = null;
                _first = node;

                owner._handleBranchesChanged(firstChanged: true);
              } else {
                final nextNode = targetNode._nextSibling;

                targetNode._nextSibling = node;
                node._previousSibling = targetNode;
                node._nextSibling = nextNode;
                nextNode?._previousSibling = node;

                owner._handleBranchesChanged();
              }
            }
          }
        } else if (newValue > oldValue) {
          final nextSibling = node._nextSibling;

          // Check if node is not the final node (which has no next sibling).
          // If it already is the final node, then nothing needs to happen
          // (it's already shifted as far backward as it can be).
          if (nextSibling != null) {
            var targetNode = nextSibling;

            while (targetNode != null &&
                targetNode._sortCode.value < node._sortCode.value) {
              targetNode = targetNode._nextSibling;
            }

            // If after searching the currentNode is still the nextNode, then
            // the node was already in the right position and does not need to
            // be moved.
            if (targetNode != nextSibling) {
              // Node does in fact need to be moved so excise it
              if (node == _first) {
                nextSibling._previousSibling = null;
                _first = nextSibling;

                owner._handleBranchesChanged(firstChanged: true);
              } else {
                final previousSibling = node._previousSibling;

                nextSibling._previousSibling = previousSibling;
                previousSibling?._nextSibling = nextSibling;
              }

              // And then reinsert it later in the chain
              if (targetNode == null) {
                _last._nextSibling = node;
                node._previousSibling = _last;
                node._nextSibling = null;
                _last = node;

                owner._handleBranchesChanged(lastChanged: true);
              } else {
                final previousNode = targetNode._previousSibling;

                targetNode._previousSibling = node;
                node._nextSibling = targetNode;
                node._previousSibling = previousNode;
                previousNode?._nextSibling = node;

                owner._handleBranchesChanged();
              }
            }
          }
        }
      });
    } else if (node._parentNode != owner) {
      throw new StateError('Tried to add a node as a child, but the node '
          'already belongs to a different parent. A node can only be a child '
          'of one parent. Try calling `unlink` on the node before adding it.');
    }
  }

  bool remove(SortTreeNode node) {
    if (node._parentNode == owner) {
      _length--;

      final previous = node._previousSibling;
      final next = node._nextSibling;

      previous?._nextSibling = next;
      next?._previousSibling = previous;

      if (node == _first && node == _last) {
        _first = null;
        _last = null;

        owner._handleBranchesChanged(firstChanged: true, lastChanged: true);
      } else if (node == _first) {
        _first = node._nextSibling;

        owner._handleBranchesChanged(firstChanged: true);
      } else if (node == _last) {
        _last = node._previousSibling;

        owner._handleBranchesChanged(lastChanged: true);
      } else {
        owner._handleBranchesChanged();
      }

      node._parentNode = null;
      node._previousSibling = null;
      node._nextSibling = null;

      node._sortCode.unsubscribe(this);

      return true;
    } else {
      return false;
    }
  }
}

/// Implementation of [_Branches] in which child nodes are sorted by their
/// sort code in ascending order.
///
/// New child nodes are inserted in order. However, changes to sort codes at a
/// later time may degenerate the order of the nodes. Call [sort] to rearrange
/// the nodes in the expected order.
class _BranchesDescending extends IterableBase<SortTreeNode>
    implements _Branches {
  final BranchingNode owner;

  final Order sortOrder = Order.descending;

  /// Creates a new [AscendingChildNodes] instance for the given [owner].
  _BranchesDescending(this.owner);

  int _length = 0;

  SortTreeNode _first;

  SortTreeNode _last;

  SortTreeNode get first => _first;

  SortTreeNode get last => _last;

  bool get isEmpty => _length == 0;

  bool get isNotEmpty => _length > 0;

  int get length => _length;

  Iterator<SortTreeNode> get iterator => new _BranchIterator(this);

  void add(SortTreeNode node) {
    if (node._parentNode == null) {
      node._parentNode = owner;

      if (isEmpty) {
        _length = 1;
        _first = node;
        _last = node;

        owner._handleBranchesChanged(firstChanged: true, lastChanged: true);
      } else {
        _length++;

        var currentNode = _first;

        while (currentNode != null &&
            currentNode._sortCode.value > node._sortCode.value) {
          currentNode = currentNode._nextSibling;
        }

        if (currentNode == null) {
          _last._nextSibling = node;
          node._previousSibling = _last;
          _last = node;

          owner._handleBranchesChanged(lastChanged: true);
        } else {
          final previousNode = currentNode._previousSibling;

          if (previousNode == null) {
            _first._previousSibling = node;
            node._nextSibling = _first;
            _first = node;

            owner._handleBranchesChanged(firstChanged: true);
          } else {
            currentNode._previousSibling = node;
            node._nextSibling = currentNode;
            node._previousSibling = previousNode;
            previousNode._nextSibling = node;

            owner._handleBranchesChanged();
          }
        }
      }

      node._sortCode.subscribe(this, (oldValue, newValue) {
        if (newValue > oldValue) {
          final previousSibling = node._previousSibling;

          // Check if the node is not the initial node (which has no previous
          // sibling). If it already is the initial node, then nothing needs
          // to happen (it's already shifted as far forward as it can be).
          if (previousSibling != null) {
            var targetNode = previousSibling;

            while (targetNode != null &&
                targetNode._sortCode.value < node._sortCode.value) {
              targetNode = targetNode._previousSibling;
            }

            // If after searching the currentNode is still the previousNode,
            // then the node was already in the right position and does not
            // need to be moved.
            if (targetNode != previousSibling) {
              // Node does in fact need to be moved so excise it
              if (node == _last) {
                previousSibling._nextSibling = null;
                _last = previousSibling;

                owner._handleBranchesChanged(lastChanged: true);
              } else {
                final nextSibling = node._nextSibling;

                previousSibling._nextSibling = nextSibling;
                nextSibling?._previousSibling = previousSibling;
              }

              // And then reinsert it earlier in the chain
              if (targetNode == null) {
                _first._previousSibling = node;
                node._nextSibling = _first;
                node._previousSibling = null;
                _first = node;

                owner._handleBranchesChanged(firstChanged: true);
              } else {
                final nextNode = targetNode._nextSibling;

                targetNode._nextSibling = node;
                node._previousSibling = targetNode;
                node._nextSibling = nextNode;
                nextNode?._previousSibling = node;

                owner._handleBranchesChanged();
              }
            }
          }
        } else if (newValue < oldValue) {
          final nextSibling = node._nextSibling;

          // Check if node is not the final node (which has no next sibling).
          // If it already is the final node, then nothing needs to happen
          // (it's already shifted as far backward as it can be).
          if (nextSibling != null) {
            var targetNode = nextSibling;

            while (targetNode != null &&
                targetNode._sortCode.value > node._sortCode.value) {
              targetNode = targetNode._nextSibling;
            }

            // If after searching the currentNode is still the nextNode, then
            // the node was already in the right position and does not need to
            // be moved.
            if (targetNode != nextSibling) {
              // Node does in fact need to be moved so excise it
              if (node == _first) {
                nextSibling._previousSibling = null;
                _first = nextSibling;

                owner._handleBranchesChanged(firstChanged: true);
              } else {
                final previousSibling = node._previousSibling;

                nextSibling._previousSibling = previousSibling;
                previousSibling?._nextSibling = nextSibling;
              }

              // And then reinsert it later in the chain
              if (targetNode == null) {
                _last._nextSibling = node;
                node._previousSibling = _last;
                node._nextSibling = null;
                _last = node;

                owner._handleBranchesChanged(lastChanged: true);
              } else {
                final previousNode = targetNode._previousSibling;

                targetNode._previousSibling = node;
                node._nextSibling = targetNode;
                node._previousSibling = previousNode;
                previousNode?._nextSibling = node;

                owner._handleBranchesChanged();
              }
            }
          }
        }
      });
    } else if (node._parentNode != owner) {
      throw new StateError('Tried to add a node as a child, but the node '
          'already belongs to a different parent. A node can only be a child '
          'of one parent. Try calling `unlink` on the node before adding it.');
    }
  }

  bool remove(SortTreeNode node) {
    if (node._parentNode == owner) {
      _length--;

      final previous = node._previousSibling;
      final next = node._nextSibling;

      previous?._nextSibling = next;
      next?._previousSibling = previous;

      if (node == _first && node == _last) {
        _first = null;
        _last = null;

        owner._handleBranchesChanged(firstChanged: true, lastChanged: true);
      } else if (node == _first) {
        _first = node._nextSibling;

        owner._handleBranchesChanged(firstChanged: true);
      } else if (node == _last) {
        _last = node._previousSibling;

        owner._handleBranchesChanged(lastChanged: true);
      } else {
        owner._handleBranchesChanged();
      }

      node._parentNode = null;
      node._previousSibling = null;
      node._nextSibling = null;

      node._sortCode.unsubscribe(this);

      return true;
    } else {
      return false;
    }
  }
}

/// An implementation of [_Branches] that presents the children in insertion
/// order.
class _UnsortedBranches extends IterableBase<SortTreeNode>
    implements _Branches {
  final BranchingNode owner;

  final Order sortOrder = Order.unordered;

  int _length = 0;

  SortTreeNode _first;

  SortTreeNode _last;

  /// Creates a new [UnsortedChildNodes] instance for the given [owner].
  _UnsortedBranches(this.owner);

  SortTreeNode get first => _first;

  SortTreeNode get last => _last;

  Iterator<SortTreeNode> get iterator => new _BranchIterator(this);

  bool get isEmpty => _length == 0;

  bool get isNotEmpty => _length > 0;

  int get length => _length;

  void add(SortTreeNode node) {
    if (node._parentNode == null) {
      node._parentNode = owner;

      if (isEmpty) {
        _length = 1;
        _first = node;
        _last = node;

        owner._handleBranchesChanged(firstChanged: true, lastChanged: true);
      } else {
        _length++;
        _last._nextSibling = node;
        node._previousSibling = _last;
        node._nextSibling = null;

        _last = node;

        owner._handleBranchesChanged(lastChanged: true);
      }
    } else if (node._parentNode != owner) {
      throw new StateError('Tried to add a node as a child, but the node '
          'already belongs to a different parent. A node can only be a child '
          'of one parent. Try calling `unlink` on the node before adding it.');
    }
  }

  bool remove(SortTreeNode node) {
    if (node._parentNode == owner) {
      _length--;

      final previous = node._previousSibling;
      final next = node._nextSibling;

      previous?._nextSibling = next;
      next?._previousSibling = previous;

      if (node == _first && node == _last) {
        _first == null;
        _last == null;

        owner._handleBranchesChanged(firstChanged: true, lastChanged: true);
      } else if (node == _last) {
        _last = node._previousSibling;

        owner._handleBranchesChanged(lastChanged: true);
      } else if (node == _first) {
        _first = node._nextSibling;

        owner._handleBranchesChanged(firstChanged: true);
      } else {
        owner._handleBranchesChanged();
      }

      node._parentNode = null;
      node._previousSibling = null;
      node._nextSibling = null;

      return true;
    } else {
      return false;
    }
  }
}

class _BranchIterator implements Iterator<SortTreeNode> {
  final _Branches branches;

  SortTreeNode _currentNode;

  _BranchIterator(this.branches);

  SortTreeNode get current => _currentNode;

  bool moveNext() {
    _currentNode =
        _currentNode == null ? branches.first : _currentNode._nextSibling;

    return _currentNode != null;
  }
}
