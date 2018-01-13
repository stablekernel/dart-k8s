import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_tour_of_heroes/app_component.dart';
import 'package:http/http.dart';
import 'package:http/browser_client.dart';

void main() {
  bootstrap(AppComponent, [
    ROUTER_PROVIDERS,
    // Remove next line in production
//    provide(LocationStrategy, useClass: HashLocationStrategy),
    // Using a real back end?
    // Import browser_client.dart and change the above to:
    provide(Client, useFactory: () => new BrowserClient(), deps: [])
  ]);
}
