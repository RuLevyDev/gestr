import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:gestr/domain/entities/tax_summary_model.dart';

abstract class SummaryState extends Equatable {
  const SummaryState();
  @override
  List<Object?> get props => [];
}

class SummaryInitial extends SummaryState {}
class SummaryLoading extends SummaryState {}

class SummaryLoaded extends SummaryState {
  final TaxSummary summary;
  final TaxSummary previous;
  final DateTimeRange range;
  const SummaryLoaded({required this.summary, required this.previous, required this.range});

  @override
  List<Object?> get props => [summary, previous, range];
}

class SummaryError extends SummaryState {
  final String message;
  const SummaryError(this.message);
  @override
  List<Object?> get props => [message];
}

