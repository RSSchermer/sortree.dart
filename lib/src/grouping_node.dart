part of sortree;

typedef BranchingNode<T> GroupingNodeBranchFactory<T extends SortTreeEntry, V>(
    V value);

/// A [BranchingNode] that groups the [SortTreeEntry]s it processes into
/// branches based on a [DecisionValue].
///
/// See the documentation of the main constructor for this class for details on
/// how this node is used.
class GroupingNode<T extends SortTreeEntry, V> extends IterableBase<T>
    implements BranchingNode<T> {
  /// The function that is used to resolve the [DecisionValue] to branch on.
  final DecisionValueResolver<T, V> resolveDecisionValue;

  /// The function that is used to create new branches for grouping values for
  /// which no branch exists yet.
  final GroupingNodeBranchFactory<T, V> makeBranch;

  /// The order in which the [branches] of this [BranchingNode] are presented
  /// based on their sort codes.
  final Order branchOrder;

  SortTreeNode _previousSibling;

  SortTreeNode _nextSibling;

  BranchingNode _parentNode;

  DecisionValue<num> _sortCode;

  _Branches _branches;

  final Map<SortTreeEntry, DecisionValue> _entriesDecisionValues = {};

  final BiMap<V, BranchingNode<T>> _valuesBranches = new BiMap();

  /// Instantiates a new [GroupingNode].
  ///
  /// Several named arguments are required and must be set:
  ///
  /// - [groupBy]: a function that takes a [SortTreeEntry] and returns a
  ///   [DecisionValue] based on which the entry is assigned to a group.
  /// - [makeBranch]: a function that returns a new [BranchingNode] for a
  ///   [groupBy] value. Is used to create branches for values for which no
  ///   branch currently exists. If a branch already exists for a value, then
  ///   that branch is used.
  /// - [sortCode]: a function that takes this [GroupingNode] and returns a
  ///   numerical [DecisionValue] that can be used to determine this
  ///   [GroupingNode]'s position amongst it sibling nodes (if it has a parent
  ///   node).
  ///
  /// It also takes an optional [branchOrder] argument that determines the order
  /// in which the group branches are presented when iterated over. Defaults to
  /// [Order.unordered] in which case the branches are presented in the order of
  /// their creation.
  ///
  /// # Example
  ///
  /// When rendering, grouping objects that share the same material together
  /// tends to require fewer state changes on the rendering pipeline, leading
  /// to better performance. A [GroupingNode] can be used to achieve this:
  ///
  ///     var materialGrouper = new GroupingNode(
  ///         groupBy: (entry) => entry.material,
  ///         makeBranch: (material) => new CollectorNode(
  ///           sortCode: (node) => new StaticValue(0)
  ///         ),
  ///         sortCode: (node) => new StaticValue(0)
  ///     );
  ///
  GroupingNode(
      {@required DecisionValueResolver<T, V> groupBy,
      @required this.makeBranch,
      @required BranchingNodeSortCodeProvider sortCode,
      this.branchOrder: Order.unordered})
      : resolveDecisionValue = groupBy {
    _branches = new _Branches(this, branchOrder);
    _sortCode = sortCode(this);
  }

  Iterable<SortTreeNode> get branches => _branches;

  Iterator<T> get iterator => new _SortTreeEntryIterator(this);

  DecisionValue<num> get sortCode => _sortCode;

  void process(T entry) {
    final decisionValue = resolveDecisionValue(entry);
    final innerValue = decisionValue.value;
    final branch = _valuesBranches[innerValue];

    if (branch != null) {
      branch.process(entry);
    } else {
      final newBranch = makeBranch(innerValue);

      _branches.add(newBranch);
      _valuesBranches[innerValue] = newBranch;

      newBranch.process(entry);
    }

    decisionValue.subscribe(this, (oldValue, newValue) {
      entry._reprocess(this);
    });

    _entriesDecisionValues[entry] = decisionValue;
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

  bool _removeBranch(SortTreeNode branch) {
    if (branch is BranchingNode<T> && _branches.remove(branch)) {
      branch.forEach(_cancelSubscriptions);
      _valuesBranches.inverse.remove(branch);

      return true;
    } else {
      return false;
    }
  }

  void _cancelSubscriptions(SortTreeEntry entry) {
    final decisionValue = _entriesDecisionValues[entry];

    if (decisionValue != null) {
      decisionValue.unsubscribe(this);
    }
  }

  void _handleBranchesChanged(
      {bool firstChanged: false, bool lastChanged: false}) {
    _sortCode._handleBranchesChanged(
        firstChanged: firstChanged, lastChanged: lastChanged);

    if (_parentNode != null && firstChanged && lastChanged && _branches.isEmpty) {
      _parentNode._handleEmptyBranch(this);
    }
  }

  void _handleEmptyBranch(BranchingNode<T> branch) {
    _removeBranch(branch);
  }
}
