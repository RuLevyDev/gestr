import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum VatEventType { fetch, setPeriod, refresh }

class VatEvent extends Equatable {
  final VatEventType type;
  final DateTimeRange? range;

  const VatEvent._(this.type, {this.range});

  const VatEvent.fetch() : this._(VatEventType.fetch);
  const VatEvent.refresh() : this._(VatEventType.refresh);
  const VatEvent.setPeriod(DateTimeRange range)
    : this._(VatEventType.setPeriod, range: range);

  @override
  List<Object?> get props => [type, range];
}
