part of sortree;

typedef bool SplitterTest<T>(T value);

/// A [BranchingNode] that splits the [SortTreeEntry]s it processes into two
/// branches based on whether or not they past a test function.
///
/// See the documentation of the main constructor for this class for details on
/// how this node is used.
class SplitterNode<T extends SortTreeEntry, V> extends IterableBase<T>
    implements BranchingNode<T> {
  /// A function that takes a [SortTreeEntry] and returns a [DecisionValue] that
  /// can be used to split on.
  final DecisionValueResolver<T, V> resolveDecisionValue;

  /// A test function that takes a splitter value and returns `true` when the
  /// value passes the split test or `false` otherwise.
  final SplitterTest<V> test;

  /// The [BranchingNode] to which entries that pass the [test] are passed on
  /// to.
  final BranchingNode<T> successBranch;

  /// The [BranchingNode] to which entries that fail the [test] are passed on
  /// to.
  final BranchingNode<T> failureBranch;

  final Order branchOrder;

  _Branches _branches;

  SortTreeNode _previousSibling;

  SortTreeNode _nextSibling;

  BranchingNode _parentNode;

  DecisionValue<num> _sortCode;

  final Map<SortTreeEntry, DecisionValue> _entriesDecisionValues = {};

  /// Instantiates a new [SplitterNode].
  ///
  /// Several named arguments are required and must be set:
  ///
  /// - [on]: a function that takes a [SortTreeEntry] and returns a
  ///   [DecisionValue] that can be used to split on.
  /// - [test]: a test function that takes a splitter value and returns `true`
  ///   when the value passes the split test or `false` otherwise.
  /// - [successBranch]: the branch to which entries that pass the [test] are
  ///   passed on to.
  /// - [failureBranch]: the branch to which entries that fail the [test] are
  ///   passed on to.
  /// - [sortCode]: a function that takes this [SplitterNode] and returns a
  ///   numerical [DecisionValue] that can be used to determine this
  ///   [SplitterNode]'s position amongst it sibling nodes (if it has a parent
  ///   node).
  ///
  /// It also takes an optional [branchOrder] argument that determines the order
  /// in which the success branch and the failure branch are presented when
  /// iterated over. Defaults to [Order.unordered] in which case the success
  /// branch is always presented first.
  ///
  /// # Example
  ///
  /// For certain 3D rendering techniques to display translucent objects
  /// correctly, it is necessary to render all opaque objects first and then
  /// render the translucent object from furthest to closest. This example uses
  /// a SplitterNode to split draw calls into 2 branches:
  ///
  /// - The success branch collects the opaque objects that pass the
  ///   opacity test.
  /// - The failure branch collects the translucent objects that fail the
  ///   opacity test. It sorts the translucent objects by camera distance
  ///   in descending order.
  ///
  /// This should achieve the desired render order:
  ///
  ///     var opacitySorter = new SplitterNode(
  ///       on: (entry) => entry.opacity,
  ///       test: (opacity) => opacity >= 1.0,
  ///       successBranch: new CollectorNode(
  ///         sortCode: (node) => new StaticValue(0)
  ///       ),
  ///       failureBranch: new CollectorNode(
  ///         sortBy: (entry) => entry.cameraDistance,
  ///         branchOrder: Order.descending,
  ///         sortCode: (node) => new StaticValue(0)
  ///       ),
  ///       sortCode: (node) => new StaticValue(0)
  ///     );
  ///
  SplitterNode(
      {@required DecisionValueResolver<T, V> on,
      @required SplitterTest<V> test,
      @required BranchingNode<T> this.successBranch,
      @required BranchingNode<T> this.failureBranch,
      @required BranchingNodeSortCodeProvider sortCode,
      this.branchOrder: Order.unordered})
      : resolveDecisionValue = on,
        test = test {
    _branches = new _Branches(this, branchOrder);
    _sortCode = sortCode(this);

    _branches..add(successBranch)..add(failureBranch);
  }

  Iterable<SortTreeNode> get branches => _branches;

  Iterator<T> get iterator => new _SortTreeEntryIterator(this);

  DecisionValue<num> get sortCode => _sortCode;

  void process(T entry) {
    final decisionValue = resolveDecisionValue(entry);

    if (test(decisionValue.value)) {
      successBranch.process(entry);
    } else {
      failureBranch.process(entry);
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

  bool _removeBranch(SortTreeNode branch) => false;

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

  void _handleEmptyBranch(BranchingNode<T> branch) {}
}
