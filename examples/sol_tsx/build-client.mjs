import * as esbuild from 'esbuild';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

await esbuild.build({
  entryPoints: [resolve(__dirname, 'app/client/entry.ts')],
  outfile: resolve(__dirname, 'public/client.js'),
  bundle: true,
  format: 'esm',
  target: 'es2022',
  minify: process.env.NODE_ENV === 'production',
  sourcemap: process.env.NODE_ENV !== 'production',
  alias: {
    '@luna_ui/luna': resolve(__dirname, '../../js/sol/index.ts'),
  },
});

console.log('Client bundle built: public/client.js');
