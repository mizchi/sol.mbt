import { Hono } from 'hono';
import { serve } from '@hono/node-server';
import { serveStatic } from '@hono/node-server/serve-static';
import { routes, config } from './app/server/routes';
import { registerRoutes } from '@luna_ui/luna/server-runtime';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

const app = new Hono();
const routerConfig = config();
const appRoutes = routes();

// Serve static files (client bundle)
app.use('/client.js', serveStatic({ root: join(__dirname, 'public'), path: '/client.js' }));
app.use('/client.js.map', serveStatic({ root: join(__dirname, 'public'), path: '/client.js.map' }));

// Register all routes from the DSL
registerRoutes(app, appRoutes, routerConfig);

const port = parseInt(process.env.PORT || '3000', 10);

console.log(`Sol TSX server running on http://localhost:${port}`);

serve({ fetch: app.fetch, port });
