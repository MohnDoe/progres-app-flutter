// lib/core/usecases/usecase.dart
import 'package:dartz/dartz.dart'; // For Either
import 'package:equatable/equatable.dart';
import 'package:progres/src/core/errors/failures.dart';

/// Abstract class for Use Cases.
///
/// [Type] is the success type of the use case.
/// [Params] is the type of the parameters it takes.
abstract class Usecase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// A simple class to represent that a use case takes no parameters.
class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}

// Example of Params class if needed:
// class ConcreteParams extends Equatable {
//   final int id;
//   final String query;

//   const ConcreteParams({required this.id, required this.query});

//   @override
//   List<Object> get props => [id, query];
// }
