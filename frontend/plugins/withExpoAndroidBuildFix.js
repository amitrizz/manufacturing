const {
  withAppBuildGradle,
  withGradleProperties,
  withProjectBuildGradle,
} = require('expo/config-plugins');

const BUNDLE_MARKER = 'standalone APK: embed JS in debug builds';

const GRADLE_MARKER = 'expo-log-box needs expo-modules-core on compile classpath';

const PROJECT_BUILD_GRADLE_APPEND = `
// ${GRADLE_MARKER}
subprojects { subproject ->
  subproject.pluginManager.withPlugin("com.android.library") {
    subproject.afterEvaluate {
      if (subproject.name == "expo-log-box") {
        subproject.dependencies.add(
          "implementation",
          subproject.rootProject.project(":expo-modules-core")
        )
      }
    }
  }
}
`;

/** @type {import('expo/config-plugins').ConfigPlugin} */
function withExpoAndroidBuildFix(config) {
  config = withAppBuildGradle(config, (config) => {
    if (config.modResults.language === 'groovy') {
      let contents = config.modResults.contents;
      if (!contents.includes(BUNDLE_MARKER) && contents.includes('bundleCommand = "export:embed"')) {
        contents = contents.replace(
          'bundleCommand = "export:embed"',
          `bundleCommand = "export:embed"\n    // ${BUNDLE_MARKER}\n    debuggableVariants = []`
        );
        config.modResults.contents = contents;
      }
    }
    return config;
  });

  config = withProjectBuildGradle(config, (config) => {
    if (config.modResults.language === 'groovy') {
      if (!config.modResults.contents.includes(GRADLE_MARKER)) {
        config.modResults.contents += PROJECT_BUILD_GRADLE_APPEND;
      }
    }
    return config;
  });

  config = withGradleProperties(config, (config) => {
    const props = config.modResults;
    const setProp = (key, value) => {
      const idx = props.findIndex((p) => p.type === 'property' && p.key === key);
      if (idx >= 0) {
        props[idx].value = value;
      } else {
        props.push({ type: 'property', key, value });
      }
    };
    setProp('org.gradle.jvmargs', '-Xmx2048m -XX:MaxMetaspaceSize=512m -XX:+HeapDumpOnOutOfMemoryError');
    setProp('org.gradle.workers.max', '2');
    setProp('org.gradle.parallel', 'false');
    setProp('reactNativeArchitectures', 'armeabi-v7a,arm64-v8a');
    setProp('expo.useLegacyPackaging', 'true');
    return config;
  });

  return config;
}

module.exports = withExpoAndroidBuildFix;
