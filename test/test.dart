import 'dart:collection';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:meta/meta.dart';

const kItteraions = 100000;
const kMax = 24;

void main() {
  ListQueueTest().report(); // 6411.829341317365 us.
  ComplexTest().report(); // 1770.2053973013494 us.
}

class ListQueueTest extends BenchmarkBase {
  ListQueueTest() : super('ListQueue');
  final Queue<A> _queue = ListQueue<A>();

  @override
  void run() {
    for (var i = kItteraions; i > 0; i--) {
      final item = A(i);
      if (_queue.isEmpty) {
        _queue.addFirst(item);
        continue;
      }
      if (_queue.length >= kMax) _queue.removeLast();
      _queue.remove(item);
      _queue.addFirst(item);
    }
    assert(_queue.length == kMax);
  }
}

class ComplexTest extends BenchmarkBase {
  ComplexTest() : super('Complex');
  final Set<int> _set = HashSet<int>();
  final Queue<A> _queue = ListQueue<A>();

  @override
  void run() {
    for (var i = kItteraions; i > 0; i--) {
      final item = A(i);
      if (_queue.isEmpty) {
        _queue.addFirst(item);
        _set.add(i);
        continue;
      }
      if (_set.remove(i)) _queue.remove(item);
      if (_set.length >= kMax) _set.remove(_queue.removeLast().id);
      _queue.addFirst(item);
      _set.add(i);
    }
    assert(_queue.length == _set.length && _queue.length == kMax);
  }
}

@immutable
class A {
  const A(this.id);

  final int id;

  @override
  int get hashCode => id * 1000;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is A && id == other.id;
}
