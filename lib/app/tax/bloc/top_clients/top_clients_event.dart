import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum TopClientsEventType { fetch, setPeriod, refresh }

class TopClientsEvent extends Equatable {
  final TopClientsEventType type;
  final DateTimeRange? range;

  const TopClientsEvent._(this.type, {this.range});

  const TopClientsEvent.fetch() : this._(TopClientsEventType.fetch);
  const TopClientsEvent.refresh() : this._(TopClientsEventType.refresh);
  const TopClientsEvent.setPeriod(DateTimeRange range)
    : this._(TopClientsEventType.setPeriod, range: range);

  @override
  List<Object?> get props => [type, range];
}
