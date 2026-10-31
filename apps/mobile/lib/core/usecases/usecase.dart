import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../error/failures.dart';

abstract interface class UseCase<Result, Params> {
  Future<Either<Failure, Result>> call(Params params);
}

final class NoParams extends Equatable {
  const NoParams();
  @override
  List<Object?> get props => [];
}
