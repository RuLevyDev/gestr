import 'package:equatable/equatable.dart';
import 'package:gestr/domain/entities/tax_pre303.dart';

abstract class Pre303State extends Equatable {
  const Pre303State();
  @override
  List<Object?> get props => [];
}

class Pre303Initial extends Pre303State {}
class Pre303Loading extends Pre303State {}
class Pre303Loaded extends Pre303State {
  final Pre303Summary pre303;
  const Pre303Loaded(this.pre303);
  @override
  List<Object?> get props => [pre303];
}
class Pre303Error extends Pre303State {
  final String message;
  const Pre303Error(this.message);
  @override
  List<Object?> get props => [message];
}

