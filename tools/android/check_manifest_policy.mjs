#!/usr/bin/env node
// Source-level guard for the Google Play monitoring-app declaration (safety phase S1).
//
// Google Play's stalkerware policy requires every version code of a parental-control app
// to carry <meta-data android:name="isMonitoringTool" android:value="child_monitoring" />
// (Play Console Help answer 12955211). The Android Build workflow checks the built APK, but
// that job needs the Firebase secret; this check needs nothing and runs on every native
// change, so the flag cannot disappear silently from a pull request that skips the APK.
import { readFileSync } from 'node:fs';

const path = process.argv[2] ?? 'app/android/app/src/main/AndroidManifest.xml';
const xml = readFileSync(path, 'utf8').replace(/<!--[\s\S]*?-->/g, '');
const application = xml.match(/<application\b[\s\S]*?<\/application>/);
const problems = [];
if (!application) {
  problems.push('no <application> element');
} else {
  const metas = [...application[0].matchAll(/<meta-data\b([^>]*)\/?>/g)].map((m) => m[1]);
  const flag = metas.find((attrs) => /android:name\s*=\s*"isMonitoringTool"/.test(attrs));
  if (!flag) problems.push('isMonitoringTool meta-data is missing inside <application>');
  else if (!/android:value\s*=\s*"child_monitoring"/.test(flag)) {
    problems.push('isMonitoringTool must have android:value="child_monitoring"');
  }
}
if (/android:debuggable\s*=\s*"true"/.test(xml)) problems.push('main manifest forces android:debuggable="true"');

for (const problem of problems) {
  console.error(process.env.GITHUB_ACTIONS ? `::error title=Manifest policy::${problem}` : `✖ ${problem}`);
}
if (problems.length > 0) process.exit(1);
console.log('Manifest policy check passed: isMonitoringTool=child_monitoring declared inside <application>.');
