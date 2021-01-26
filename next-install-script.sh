#!/bin/bash
npx create-next-app --example with-typescript $1
cd $1
npm install express
npm install --save-dev typescript @types/express ts-node
npm install --save-dev eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin
npm install --save-dev eslint-plugin-react eslint-plugin-react-hooks eslint-plugin-jsx-a11y
npm install --save-dev prettier eslint-plugin-prettier eslint-config-prettier
npm install tailwindcss@latest postcss@latest autoprefixer@latest
npm install --legacy-peer-deps eslint-plugin-tailwind

#create express server: index.ts
mkdir -p server
echo "import express, { Request, Response } from 'express'
import next from 'next'

const dev = process.env.NODE_ENV !== 'production'
const app = next({ dev })
const handle = app.getRequestHandler()
const port = process.env.PORT || 3000

;(async () => {
  try {
    await app.prepare()
    const server = express()
    server.all('*', (req: Request, res: Response) => {
      return handle(req, res)
    })
    server.listen(port, (err?: unknown) => {
      if (err) throw err
      console.log(\`> Ready on localhost: \${port} - env \${process.env.NODE_ENV}\`)
    })
  } catch (e) {
    console.error(e)
    process.exit(1)
  }
})()
" >>server/index.ts

# create tsconfig.server.json
echo '{
    "extends": "./tsconfig.json",
    "compilerOptions": {
        "module": "commonjs",
        "outDir": "dist",
        "noEmit": false
    }
}' >>tsconfig.server.json

# edit package.json
npm install -g json
json -I -f package.json -e "this.scripts.dev = 'ts-node --project tsconfig.server.json server/index.ts'; \
this.scripts.buildserver = 'tsc --project tsconfig.server.json'; \
this.scripts.buildnext = 'next build'; \
this.scripts.build = 'npm run buildnext && npm run buildserver'; \
this.scripts.start = 'NODE_ENV=production node dist/server/index.js';"

# initialize eslint
echo "// .eslintrc.js
module.exports = {
    root: true,
    env: {
      node: true,
      es6: true,
    },
    parserOptions: { ecmaVersion: 8 }, // to enable features such as async/await
    ignorePatterns: ['node_modules/*', '.next/*', '.out/*', '!.prettierrc.js'], // We don't want to lint generated files nor node_modules, but we want to lint .prettierrc.js (ignored by default by eslint)
    extends: ['eslint:recommended'],
    overrides: [
      // This configuration will apply only to TypeScript files
      {
        files: ['**/*.ts', '**/*.tsx'],
        parser: '@typescript-eslint/parser',
        settings: { react: { version: 'detect' } },
        env: {
          browser: true,
          node: true,
          es6: true,
        },
        extends: [
          'eslint:recommended',
          'plugin:@typescript-eslint/recommended', // TypeScript rules
          'plugin:react/recommended', // React rules
          'plugin:react-hooks/recommended', // React hooks rules
          'plugin:jsx-a11y/recommended', // Accessibility rules
          'prettier/@typescript-eslint', // Prettier plugin
          'plugin:prettier/recommended', // Prettier recommended rules
          'plugin:tailwind/recommended', // Tailwindcss
        ],
        rules: {
          // We will use TypeScript's types for component props instead
          'react/prop-types': 'off',
  
          // No need to import React when using Next.js
          'react/react-in-jsx-scope': 'off',
  
          // This rule is not compatible with Next.js's <Link /> components
          'jsx-a11y/anchor-is-valid': 'off',
  
          // Why would you want unused vars?
          '@typescript-eslint/no-unused-vars': ['error'],
          '@typescript-eslint/explicit-module-boundary-types': 'off',
          // I suggest this setting for requiring return types on functions only where useful
          '@typescript-eslint/explicit-function-return-type': 'off',

          'prettier/prettier': ['error', {}, { usePrettierrc: true }], // Includes .prettierrc.js rules
        },
      },
    ],
  }" >>.eslintrc.js

# prettier
echo "// .prettierrc.js
module.exports = {
    // Change your rules accordingly to your coding style preferences.
    // https://prettier.io/docs/en/options.html
    semi: false,
    trailingComma: 'es5',
    singleQuote: true,
    printWidth: 100,
    tabWidth: 2,
    useTabs: false,
  }" >>.prettierrc.js

# vscode setting
mkdir -p .vscode
echo '// .vscode/settings.json
{
  "editor.formatOnSave": false,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "css.validate": false,
  "editor.quickSuggestions": {
    "strings": true
  },
}
' >>.vscode/settings.json

# tailwindcss
echo "module.exports = {
  purge: ['./pages/**/*.tsx', './components/**/*.tsx'],
  darkMode: false, // or 'media' or 'class'
  theme: {
    extend: {},
  },
  variants: {
    extend: {},
  },
  plugins: [],
}
" >>tailwind.config.js

# postcss
echo "module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
" >>postcss.config.js

# global.css
mkdir -p styles
echo "@tailwind base;
@tailwind components;
@tailwind utilities;
" >>styles/global.css

# _app.tsx
echo "import '../styles/global.css'
import type { AppProps /*, AppContext */ } from 'next/app'

export default function App({ Component, pageProps }: AppProps) {
  return (
    <div>
      <Component {...pageProps} />
    </div>
  )
}
" >>pages/_app.tsx

#run vscode
code .
