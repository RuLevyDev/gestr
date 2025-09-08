import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum Pre303EventType { fetch, setPeriod, refresh }

class Pre303Event extends Equatable {
  final Pre303EventType type;
  final DateTimeRange? range;

  const Pre303Event._(this.type, {this.range});

  const Pre303Event.fetch() : this._(Pre303EventType.fetch);
  const Pre303Event.refresh() : this._(Pre303EventType.refresh);
  const Pre303Event.setPeriod(DateTimeRange range)
    : this._(Pre303EventType.setPeriod, range: range);

  @override
  List<Object?> get props => [type, range];
}
