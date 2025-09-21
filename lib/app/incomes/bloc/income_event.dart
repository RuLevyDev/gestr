import 'package:equatable/equatable.dart';
import 'package:gestr/domain/entities/income.dart';

enum IncomeEventType { fetch, refresh, create, delete, getById }

class IncomeEvent extends Equatable {
  final IncomeEventType type;
  final Income? income;
  final String? id;
  final String? voidReason;

  const IncomeEvent._(this.type, {this.income, this.id, this.voidReason});
  const IncomeEvent.fetch() : this._(IncomeEventType.fetch);
  const IncomeEvent.refresh() : this._(IncomeEventType.refresh);
  const IncomeEvent.create(Income income)
    : this._(IncomeEventType.create, income: income);
  const IncomeEvent.delete(String id, {String? voidReason})
    : this._(IncomeEventType.delete, id: id, voidReason: voidReason);
  const IncomeEvent.getById(String id)
    : this._(IncomeEventType.getById, id: id);

  @override
  List<Object?> get props => [type, income, id, voidReason];
}
