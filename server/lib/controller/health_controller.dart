import 'dart:async';
import 'package:aqueduct/aqueduct.dart';

class HealthController extends HTTPController {
  @httpGet
  Future<Response> getHealth() async {
    return new Response.ok("Status OK");
  }
}