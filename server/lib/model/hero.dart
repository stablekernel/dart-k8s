import '../heroes.dart';

class Hero extends ManagedObject<_Hero> implements _Hero {

}

class _Hero {
  @managedPrimaryKey
  int id;

  @ManagedColumnAttributes(indexed: true)
  String name;
}
