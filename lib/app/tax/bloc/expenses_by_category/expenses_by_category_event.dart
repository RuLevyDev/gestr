import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum ExpensesByCategoryEventType { fetch, setPeriod, refresh }

class ExpensesByCategoryEvent extends Equatable {
  final ExpensesByCategoryEventType type;
  final DateTimeRange? range;

  const ExpensesByCategoryEvent._(this.type, {this.range});

  const ExpensesByCategoryEvent.fetch()
      : this._(ExpensesByCategoryEventType.fetch);
  const ExpensesByCategoryEvent.refresh()
      : this._(ExpensesByCategoryEventType.refresh);
  const ExpensesByCategoryEvent.setPeriod(DateTimeRange range)
      : this._(ExpensesByCategoryEventType.setPeriod, range: range);

  @override
  List<Object?> get props => [type, range];
}
