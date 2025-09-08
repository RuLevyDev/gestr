import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class ChartState extends Equatable {
  const ChartState();
  @override
  List<Object?> get props => [];
}

class ChartInitial extends ChartState {}
class ChartLoading extends ChartState {}

class ChartLoaded extends ChartState {
  final DateTimeRange range;
  final List<String> labels;
  final List<double> income;
  final List<double> expenses;
  final List<double> yoyIncome;
  final List<double> yoyExpenses;
  const ChartLoaded({
    required this.range,
    required this.labels,
    required this.income,
    required this.expenses,
    required this.yoyIncome,
    required this.yoyExpenses,
  });

  @override
  List<Object?> get props => [range, labels, income, expenses, yoyIncome, yoyExpenses];
}

class ChartError extends ChartState {
  final String message;
  const ChartError(this.message);
  @override
  List<Object?> get props => [message];
}

