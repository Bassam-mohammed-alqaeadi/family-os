import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/policy/web_filter_policy.dart';
import 'package:family_os/core/web_filter/web_filter_engine.dart';

// Safety phase S1: the `*.example` exact-match table left production code. These hosts
// must still classify exactly as before, through the label tokens alone, and the client
// must keep agreeing with the server's `classifyHost` (backend/test/web-filter.test.js).
void main() {
  test(
    'former *.example fixture hosts classify the same through label tokens',
    () {
      const expected = <String, String>{
        'adult.example': WebFilterCategories.adults,
        'gambling.example': WebFilterCategories.gambling,
        'casino.example': WebFilterCategories.gambling,
        'violence.example': WebFilterCategories.violence,
        'social.example': WebFilterCategories.social,
        'games.example': WebFilterCategories.games,
        'streaming.example': WebFilterCategories.streaming,
      };
      expected.forEach((host, category) {
        expect(WebFilterEngine.classifyHost(host), category, reason: host);
      });
    },
  );

  test('ordinary hosts keep their answers', () {
    expect(
      WebFilterEngine.classifyHost('www.netflix.com'),
      WebFilterCategories.streaming,
    );
    expect(
      WebFilterEngine.classifyHost('tiktok.com'),
      WebFilterCategories.social,
    );
    expect(WebFilterEngine.classifyHost('wikipedia.org'), isNull);
    expect(WebFilterEngine.classifyHost(''), isNull);
  });
}
