part of sortree;

typedef void ChangeHandler<T>(T newValue, T oldValue);

class _DecisionValueSubscription<T> {
  final DecisionValue<T> decisionValue;

  final Object subscriber;

  final ChangeHandler<T> changeHandler;

  _DecisionValueSubscription<T> next;

  _DecisionValueSubscription<T> previous;

  _DecisionValueSubscription(
      this.decisionValue, this.subscriber, this.changeHandler);

  void cancel() {
    if (next != null) {
      next.previous = previous;
    }

    if (previous != null) {
      previous.next = next;
    }

    if (decisionValue._subscriptionsHead == this) {
      decisionValue._subscriptionsHead = next;
    }
  }
}

/// A observable value wrapper that a sort tree can use to decide branching or
/// branch ordering.
abstract class DecisionValue<T> {
  _DecisionValueSubscription<T> _subscriptionsHead;

  /// Returns this [DecisionValue]'s current value.
  T get value;

  /// Adds a subscription for the [observer], calling the [changeHandler] when
  /// the [value] changes.
  void subscribe(Object subscriber, ChangeHandler<T> changeHandler) {
    final subscription =
        new _DecisionValueSubscription<T>(this, subscriber, changeHandler);

    if (_subscriptionsHead != null) {
      _subscriptionsHead.previous = subscription;
    }

    subscription.next = _subscriptionsHead;
    _subscriptionsHead = subscription;
  }

  /// Removes any subscription that currently exist for the [subscriber].
  ///
  /// Returns `true` if a subscription existed, `false` otherwise.
  bool unsubscribe(Object subscriber) {
    // Most of the time there'll be just a single subscriber, maybe a handful
    // at the most, so just looping through a linked list to find the
    // subscription is likely to be fast.
    var subscription = _subscriptionsHead;

    while (subscription != null) {
      if (subscription.subscriber == subscriber) {
        subscription.cancel();

        return true;
      }

      subscription = subscription.next;
    }

    return false;
  }

  void _notifySubscribers(T oldValue, T newValue) {
    var subscription = _subscriptionsHead;

    while (subscription != null) {
      subscription.changeHandler(oldValue, newValue);
      subscription = subscription.next;
    }
  }

  void _handleBranchesChanged(
      {bool firstChanged: false, bool lastChanged: false});
}

/// A [DecisionValue] that never changes.
class StaticValue<T> extends DecisionValue<T> {
  final T value;

  StaticValue(this.value);

  void subscribe(Object subscriber, ChangeHandler<T> changeHandler) {}

  bool unsubscribe(Object subscriber) => false;

  void _handleBranchesChanged(
      {bool firstChanged: false, bool lastChanged: false}) {}
}

/// A [DecisionValue] that may be updated over the course of its lifetime.
class MutableValue<T> extends DecisionValue<T> {
  T _value;

  MutableValue([T initialValue]) : _value = initialValue;

  T get value => _value;

  void set value(T newValue) {
    if (newValue != _value) {
      final oldValue = _value;

      _value = newValue;

      _notifySubscribers(oldValue, newValue);
    }
  }

  void _handleBranchesChanged(
      {bool firstChanged: false, bool lastChanged: false}) {}
}

/// A [DecisionValue] that tracks the sort code of the first branch of its
/// [branchingNode].
class BranchSortCodeFirst extends DecisionValue<num> {
  final num defaultValue;

  final BranchingNode branchingNode;

  _Branches _branches;

  DecisionValue<num> _currentSortCode;

  num _value;

  BranchSortCodeFirst(this.branchingNode, this.defaultValue) {
    _branches = branchingNode._branches;

    if (_branches.isNotEmpty) {
      _currentSortCode = _branches.first._sortCode;
      _value = _currentSortCode.value;

      _currentSortCode.subscribe(this, _handleSortCodeChange);
    } else {
      _value = defaultValue;
    }
  }

  num get value => _value;

  void _handleBranchesChanged(
      {bool firstChanged: false, bool lastChanged: false}) {
    if (firstChanged) {
      final oldValue = value;

      if (_branches.isNotEmpty) {
        _currentSortCode?.unsubscribe(this);

        _currentSortCode = _branches.first._sortCode;
        _value = _currentSortCode.value;

        _currentSortCode.subscribe(this, _handleSortCodeChange);
      } else {
        _value = defaultValue;
      }

      if (_value != oldValue) {
        _notifySubscribers(oldValue, _value);
      }
    }
  }

  void _handleSortCodeChange(num oldValue, num newValue) {
    _value = newValue;
    _notifySubscribers(oldValue, newValue);
  }
}

/// A [DecisionValue] that tracks the sort code of the last branch of its
/// [branchingNode].
class BranchSortCodeLast extends DecisionValue<num> {
  final num defaultValue;

  final BranchingNode branchingNode;

  _Branches _branches;

  DecisionValue<num> _currentSortCode;

  num _value;

  BranchSortCodeLast(this.branchingNode, this.defaultValue) {
    _branches = branchingNode._branches;

    if (_branches.isNotEmpty) {
      _currentSortCode = _branches.last._sortCode;
      _value = _currentSortCode.value;

      _currentSortCode.subscribe(this, _handleSortCodeChange);
    } else {
      _value = defaultValue;
    }
  }

  num get value => _value;

  void _handleBranchesChanged(
      {bool firstChanged: false, bool lastChanged: false}) {
    if (lastChanged) {
      final oldValue = value;

      if (_branches.isNotEmpty) {
        _currentSortCode?.unsubscribe(this);

        _currentSortCode = _branches.last._sortCode;
        _value = _currentSortCode.value;

        _currentSortCode.subscribe(this, _handleSortCodeChange);
      } else {
        _value = defaultValue;
      }

      if (_value != oldValue) {
        _notifySubscribers(oldValue, _value);
      }
    }
  }

  void _handleSortCodeChange(num oldValue, num newValue) {
    _value = newValue;
    _notifySubscribers(oldValue, newValue);
  }
}
