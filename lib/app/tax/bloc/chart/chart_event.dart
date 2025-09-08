import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum ChartEventType { fetch, setPeriod, refresh }

class ChartEvent extends Equatable {
  final ChartEventType type;
  final DateTimeRange? range;
  const ChartEvent._(this.type, {this.range});
  const ChartEvent.fetch() : this._(ChartEventType.fetch);
  const ChartEvent.refresh() : this._(ChartEventType.refresh);
  const ChartEvent.setPeriod(DateTimeRange range)
    : this._(ChartEventType.setPeriod, range: range);

  @override
  List<Object?> get props => [type, range];
}
