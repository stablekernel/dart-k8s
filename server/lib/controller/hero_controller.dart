import 'package:heroes/heroes.dart';
import 'package:heroes/model/hero.dart';

class HeroController extends HTTPController {
  @httpGet
  Future<Response> getHeroes({@HTTPQuery('name') String name}) async {
    final query = new Query<Hero>();
    
    if (name != null) {
      query.where.name = whereContainsString(name, caseSensitive: false);
    }

    final heroes = await query.fetch();
    return new Response.ok(heroes);
  }

  @httpGet
  Future<Response> getHero(@HTTPPath('id') int id) async {
    final query = new Query<Hero>()
      ..where.id = id;

    final hero = await query.fetchOne();

    if (hero == null) {
      return new Response.notFound();
    }

    return new Response.ok(hero);
  }

  @httpPost
  Future<Response> createHero(@HTTPBody() Hero hero) async {
    final query = new Query<Hero>()
      ..values = hero;

    hero = await query.insert();
    return new Response.ok(hero);
  }

  @httpPut
  Future<Response> updateHero(@HTTPPath('id') int id, @HTTPBody() Hero hero) async {
    final query = new Query<Hero>()
      ..where.id = id
      ..values = hero;

    hero = await query.updateOne();

    if (hero == null) {
      return new Response.notFound();
    }

    return new Response.ok(hero);
  }

  @httpDelete
  Future<Response> delete(@HTTPPath('id') int id) async {
    final query = new Query<Hero>()
      ..where.id = id;

    final deletedCount = await query.delete();

    if (deletedCount == 0) {
      return new Response.notFound();
    }

    return new Response.ok(null);
  }
}
