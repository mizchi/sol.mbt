/**
 * Sol Framework Server Runtime for TypeScript
 *
 * Registers TypeScript routes with Hono and handles SSR rendering
 */

import type { Context, Hono } from 'hono';
import type {
  SolRoute,
  PageProps,
  RouteParams,
  PageRoute,
  LayoutRoute,
  GetRoute,
  PostRoute,
  WithMiddlewareRoute,
  Middleware,
  RouterConfig,
} from './routes';
import { DEFAULT_ROOT_TEMPLATE } from './routes';

// ============================================================================
// Route Compilation
// ============================================================================

interface CompiledRoute {
  method: 'GET' | 'POST';
  path: string;
  handler: (c: Context) => Promise<Response>;
}

/**
 * Extract route parameters from Hono context
 */
function extractParams(c: Context): RouteParams {
  const url = new URL(c.req.url);
  const params: [string, string][] = Object.entries(c.req.param() || {});
  const query: [string, string][] = Array.from(url.searchParams.entries());

  return {
    params,
    query,
    path: url.pathname,
    get_param: (name: string) => params.find(([k]) => k === name)?.[1],
    get_query: (name: string) => query.find(([k]) => k === name)?.[1],
  };
}

/**
 * Check if request is a fragment request (CSR navigation)
 */
function isFragmentRequest(c: Context): boolean {
  return c.req.header('X-Sol-Fragment') === 'true';
}

/**
 * Wrap HTML content in the root template
 */
function wrapInTemplate(
  html: string,
  title: string,
  config: RouterConfig,
  meta?: [string, string][]
): string {
  const template = config.rootTemplate || DEFAULT_ROOT_TEMPLATE;
  const fullTitle = config.titlePrefix
    ? `${config.titlePrefix} | ${title}`
    : title;

  // Build meta tags
  const metaHtml = meta
    ? meta
        .map(([name, content]) => `<meta name="${name}" content="${content}">`)
        .join('\n  ')
    : '';

  return template
    .replace('__LUNA_TITLE__', fullTitle)
    .replace('__LUNA_HEAD__', config.defaultHead || '')
    .replace('__LUNA_PRELOAD__', '')
    .replace('__LUNA_MAIN__', html)
    .replace('__LUNA_META__', metaHtml);
}

/**
 * Compile a single route into Hono handlers
 */
function compileRoute(
  route: SolRoute,
  config: RouterConfig,
  layouts: LayoutRoute[] = [],
  middlewares: Middleware[] = []
): CompiledRoute[] {
  const results: CompiledRoute[] = [];

  switch (route.type) {
    case 'page': {
      const pageRoute = route as PageRoute;
      results.push({
        method: 'GET',
        path: pageRoute.path,
        handler: async (c: Context) => {
          const props: PageProps = {
            ctx: c,
            params: extractParams(c),
            is_fragment: isFragmentRequest(c),
          };

          // Apply middlewares
          let response: Response | null = null;
          const next = async () => {
            let html = await pageRoute.handler(props);

            // Apply layouts from innermost to outermost
            for (let i = layouts.length - 1; i >= 0; i--) {
              html = await layouts[i].layout(props, html);
            }

            // For fragment requests, return just the content
            if (props.is_fragment) {
              return c.html(html);
            }

            // Wrap in full HTML template
            return c.html(
              wrapInTemplate(html, pageRoute.title, config, pageRoute.meta)
            );
          };

          // Execute middleware chain
          if (middlewares.length > 0) {
            let idx = 0;
            const runMiddleware = async (): Promise<Response> => {
              if (idx < middlewares.length) {
                const middleware = middlewares[idx++];
                return await middleware(c, runMiddleware);
              }
              return await next();
            };
            response = await runMiddleware();
          } else {
            response = await next();
          }

          return response;
        },
      });
      break;
    }

    case 'layout': {
      const layoutRoute = route as LayoutRoute;
      // Add this layout to the stack and compile children
      for (const child of layoutRoute.children) {
        results.push(
          ...compileRoute(child, config, [...layouts, layoutRoute], middlewares)
        );
      }
      break;
    }

    case 'get': {
      const getRoute = route as GetRoute;
      results.push({
        method: 'GET',
        path: getRoute.path,
        handler: async (c: Context) => {
          const props: PageProps = {
            ctx: c,
            params: extractParams(c),
            is_fragment: false,
          };

          const result = await getRoute.handler(props);
          return c.json(result);
        },
      });
      break;
    }

    case 'post': {
      const postRoute = route as PostRoute;
      results.push({
        method: 'POST',
        path: postRoute.path,
        handler: async (c: Context) => {
          const props: PageProps = {
            ctx: c,
            params: extractParams(c),
            is_fragment: false,
          };

          const result = await postRoute.handler(props);
          return c.json(result);
        },
      });
      break;
    }

    case 'withMiddleware': {
      const mwRoute = route as WithMiddlewareRoute;
      // Add middlewares to the stack and compile children
      for (const child of mwRoute.children) {
        results.push(
          ...compileRoute(child, config, layouts, [
            ...middlewares,
            ...mwRoute.middleware,
          ])
        );
      }
      break;
    }
  }

  return results;
}

/**
 * Compile all routes into flat list of handlers
 */
function compileRoutes(routes: SolRoute[], config: RouterConfig): CompiledRoute[] {
  const results: CompiledRoute[] = [];
  for (const route of routes) {
    results.push(...compileRoute(route, config));
  }
  return results;
}

// ============================================================================
// Public API
// ============================================================================

/**
 * Register TypeScript routes with a Hono app
 */
export function registerRoutes<T extends Hono>(
  app: T,
  routes: SolRoute[],
  config: RouterConfig = {}
): T {
  const compiled = compileRoutes(routes, config);

  for (const route of compiled) {
    switch (route.method) {
      case 'GET':
        app.get(route.path, route.handler);
        break;
      case 'POST':
        app.post(route.path, route.handler);
        break;
    }
  }

  return app;
}

/**
 * Create a new Hono app with routes registered
 */
export async function createApp(
  routesModule: {
    routes: () => SolRoute[] | Promise<SolRoute[]>;
    config?: () => RouterConfig | Promise<RouterConfig>;
  },
  HonoConstructor: new () => Hono
): Promise<Hono> {
  const app = new HonoConstructor();
  const routes = await routesModule.routes();
  const config = routesModule.config ? await routesModule.config() : {};

  return registerRoutes(app, routes, config);
}

export { extractParams, isFragmentRequest, wrapInTemplate };
