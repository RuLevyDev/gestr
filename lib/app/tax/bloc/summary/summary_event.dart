import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum SummaryEventType { fetch, setPeriod, refresh }

class SummaryEvent extends Equatable {
  final SummaryEventType type;
  final DateTimeRange? range;

  const SummaryEvent._(this.type, {this.range});
  const SummaryEvent.fetch() : this._(SummaryEventType.fetch);
  const SummaryEvent.refresh() : this._(SummaryEventType.refresh);
  const SummaryEvent.setPeriod(DateTimeRange range)
      : this._(SummaryEventType.setPeriod, range: range);

  @override
  List<Object?> get props => [type, range];
}

