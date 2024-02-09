module.exports = {
  extends: ['plugin:prettier/recommended', 'prettier-plugin-solidity'],
  parserOptions: {
    ecmaVersion: 2023,
    sourceType: 'module',
  },
  env: {
    es6: true,
    node: true,
  },
  rules: {
    'no-var': 'error',
    semi: 'error',
    indent: ['error', 2, { SwitchCase: 1 }],
    'no-multi-spaces': 'error',
    'space-in-parens': 'error',
    'no-multiple-empty-lines': 'error',
    'prefer-const': 'error',
    'no-trailing-spaces': 'error',
    'no-unused-vars': 'error',
    'no-use-before-define': 'error',
  },
  overrides: [
    {
      files: '*.sol',
      options: {
        parser: 'solidity-parse',
        printWidth: 120,
        tabWidth: 4,
        useTabs: false,
        singleQuote: false,
        bracketSpacing: false,
      },
    },
  ],
};
