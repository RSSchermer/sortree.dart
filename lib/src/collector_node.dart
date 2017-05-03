part of sortree;

typedef DecisionValue<num> EntrySortCodeResolver<T extends SortTreeEntry>(
    T entry);

/// A [BranchingNode] that acts as a collector for [SortTreeEntries] at the
/// bottom of the tree.
///
/// This is always the final [BranchingNode] in a sort (sub-)tree, beyonds this
/// nodes there can only be [SortTreeEntry]s.
///
/// See the documentation for the main constructor for details on how this node
/// is used.
class CollectorNode<T extends SortTreeEntry> extends IterableBase<T>
    implements BranchingNode<T> {
  /// The function that is used to resolve a numerical [DecisionValue] for each
  /// [SortTreeEntry] processed by this [CollectorNode] that is to be used as
  /// that [SortTreeEntry]'s sort code.
  final EntrySortCodeResolver<T> resolveEntrySortCode;

  /// The order in which the [SortTreeEntry]s contained in this [CollectorNode]
  /// are presented based on their sort codes as resolved by applying
  /// [resolveEntrySortCode].
  final Order branchOrder;

  SortTreeNode _previousSibling;

  SortTreeNode _nextSibling;

  BranchingNode _parentNode;

  DecisionValue<num> _sortCode;

  _Branches _branches;

  /// Instantiates a new [CollectorNode].
  ///
  /// The following named argument is required and must be set:
  ///
  /// - [sortCode]: a function that takes this [CollectorNode] and returns a
  ///   numerical [DecisionValue] that can be used to determine this
  ///   [GroupingNode]'s position amongst it sibling nodes (if it has a parent
  ///   node).
  ///
  /// The following named arguments are optional:
  ///
  /// - [sortBy]: function that is used to resolve a numerical [DecisionValue]
  ///   for each [SortTreeEntry] processed by this [CollectorNode] that is to be
  ///   used as that [SortTreeEntry]'s sort code. If omitted, then the entries
  ///   will always be presented in the order in which they were processed.
  /// - [branchOrder]: determines the order in which the entries are presented
  ///   when iterated over. Defaults to [Order.unordered] in which case the
  ///   entries are presented in the order in which they were processed.
  CollectorNode(
      {@required BranchingNodeSortCodeProvider sortCode,
      EntrySortCodeResolver<T> sortBy,
      this.branchOrder: Order.unordered})
      : resolveEntrySortCode = sortBy {
    _branches = new _Branches(this, branchOrder);
    _sortCode = sortCode(this);
  }

  Iterable<SortTreeNode> get branches => _branches;

  Iterator<T> get iterator => new _SortTreeEntryIterator(this);

  DecisionValue<num> get sortCode => _sortCode;

  void process(T entry) {
    if (resolveEntrySortCode != null) {
      entry._sortCode = resolveEntrySortCode(entry);
    } else {
      entry._sortCode = new StaticValue(0);
    }
    _branches.add(entry);
  }

  bool unlink() {
    if (_parentNode == null) {
      return false;
    } else {
      return _parentNode._removeBranch(this);
    }
  }

  void _accept(_SortTreeVisitor visitor) {
    visitor.visitBranchingNode(this);
  }

  bool _removeBranch(SortTreeNode branch) => _branches.remove(branch);

  void _cancelSubscriptions(SortTreeEntry entry) {}

  void _handleBranchesChanged(
      {bool firstChanged: false, bool lastChanged: false}) {
    _sortCode._handleBranchesChanged(
        firstChanged: firstChanged, lastChanged: lastChanged);

    if (_parentNode != null && firstChanged && lastChanged && _branches.isEmpty) {
      _parentNode._handleEmptyBranch(this);
    }
  }

  void _handleEmptyBranch(BranchingNode<T> branch) {}
}
