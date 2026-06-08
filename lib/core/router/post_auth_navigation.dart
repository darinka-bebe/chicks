import '../../data/repositories/tutorial_repository.dart';
import 'route_names.dart';

/// Where to go after sign-in — tutorial only once per account.
abstract final class PostAuthNavigation {
  static Future<String> destinationAfterAuth() async {
    final tutorialDone = await TutorialRepository.instance.isCompleted();
    return tutorialDone ? RouteNames.main : RouteNames.tutorial;
  }
}
