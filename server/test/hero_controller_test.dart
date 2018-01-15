import 'dart:math';
import 'harness/app.dart';
import 'package:heroes/model/hero.dart';

Future main() async {
  TestApplication app = new TestApplication();

  Hero hero1;
  Hero hero2;
  int nonexistentId;

  setUp(() async {
    await app.start();

    final query1 = new Query<Hero>()
      ..values.name = "First Hero Name";

    hero1 = await query1.insert();

    final query2 = new Query<Hero>()
      ..values.name = "Another Hero Name";

    hero2 = await query2.insert();

    nonexistentId = max(hero1.id, hero2.id) + 1;
  });

  tearDown(() async {
    await app.stop();

    hero1 = null;
    hero2 = null;
  });

  test("Can return all heroes", () async {
    final response = await app.client.request("/api/heroes").get();

    expect(response, hasResponse(200, unorderedMatches([
      {
        "id": hero1.id,
        "name": hero1.name
      },
      {
        "id": hero2.id,
        "name": hero2.name
      }
    ])));
  });

  test("Can return heroes filtered by name", () async {
    final response = await app.client.request("/api/heroes?name=aNoTHer").get();

    expect(response, hasResponse(200, [
      {
        "id": hero2.id,
        "name": hero2.name
      }
    ]));
  });

  test("Can return hero by ID", () async {
    final response = await app.client.request("/api/heroes/${hero2.id}").get();

    expect(response, hasResponse(200, {
      "id": hero2.id,
      "name": hero2.name
    }));
  });

  test("Doesn't return non-existent heroes", () async {
    final response = await app.client.request("/api/heroes/$nonexistentId").get();

    expect(response, hasStatus(HttpStatus.NOT_FOUND));
  });

  test("Can create hero", () async {
    final newHeroName = "A New Hero Name";

    final request = app.client.request("/api/heroes")
      ..json = {
        "name": newHeroName
      };

    final response = await request.post();

    expect(response, hasResponse(200, {
      "id": greaterThan(0),
      "name": newHeroName
    }));
  });

  test("Can Update a hero", () async {
    final newHeroName = "A New Hero Name";

    final request = app.client.request("/api/heroes/${hero1.id}")
      ..json = {
        "name": newHeroName
      };

    final response = await request.put();

    expect(response, hasResponse(200, {
      "id": hero1.id,
      "name": newHeroName
    }));
  });

  test("Doesn't update non-existent heroes", () async {
    final request = app.client.request("/api/heroes/$nonexistentId")
      ..json = {
        "name": "A New Hero Name"
      };

    final response = await request.put();

    expect(response, hasStatus(HttpStatus.NOT_FOUND));
  });

  test("Can Delete a hero", () async {
    final response = await app.client.request("/api/heroes/${hero1.id}").delete();

    expect(response, hasStatus(200));

    final remainingHeroes = await new Query<Hero>().fetch();

    expect(remainingHeroes.length, 1);
  });

  test("Doesn't delete non-existent heroes", () async {
    final response = await app.client.request("/api/heroes/$nonexistentId").delete();

    expect(response, hasStatus(HttpStatus.NOT_FOUND));
  });
}
