// https://docs.expo.dev/guides/using-eslint/
const { defineConfig } = require('eslint/config');
const expoConfig = require('eslint-config-expo/flat');

module.exports = defineConfig([
  expoConfig,
  {
    ignores: ['dist/*'],
  },
  {
    rules: {
      // Standard RN pattern: fetch in useEffect on mount / when deps change
      'react-hooks/set-state-in-effect': 'off',
      'import/no-unresolved': [
        'error',
        {
          ignore: ['^@expo/vector-icons$'],
        },
      ],
    },
  },
]);
