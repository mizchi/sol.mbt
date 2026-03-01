import { beforeEach, describe, expect, it } from 'vitest';
import { Hono } from 'hono';
import { SolRoutes } from '../routes';
import { registerRoutes, revalidateMiddleware } from '../server-runtime';
import { ISRCacheManager, MemoryCacheAdapter } from '../cache';

describe('server runtime', () => {
  beforeEach(() => {
    delete process.env.SOL_REVALIDATE_TOKEN;
  });

  it('applies WithMiddleware to GET API routes', async () => {
    let called = 0;
    const app = new Hono();
    registerRoutes(app, [
      SolRoutes.WithMiddleware({
        middleware: [
          async (_ctx, next) => {
            called += 1;
            return next();
          },
        ],
        children: [
          SolRoutes.Get({
            path: '/api/ping',
            handler: async () => ({ ok: true }),
          }),
        ],
      }),
    ]);

    const res = await app.fetch(new Request('http://localhost/api/ping'));
    expect(res.status).toBe(200);
    expect(called).toBe(1);
  });

  it('applies WithMiddleware to POST API routes', async () => {
    let called = 0;
    const app = new Hono();
    registerRoutes(app, [
      SolRoutes.WithMiddleware({
        middleware: [
          async (_ctx, next) => {
            called += 1;
            return next();
          },
        ],
        children: [
          SolRoutes.Post({
            path: '/api/ping',
            handler: async () => ({ ok: true }),
          }),
        ],
      }),
    ]);

    const res = await app.fetch(
      new Request('http://localhost/api/ping', { method: 'POST' })
    );
    expect(res.status).toBe(200);
    expect(called).toBe(1);
  });

  it('prefixes child routes by layout segment', async () => {
    const app = new Hono();
    registerRoutes(app, [
      SolRoutes.Layout({
        segment: '/admin',
        layout: async (_props, children) => `<main>${children}</main>`,
        children: [
          SolRoutes.Page({
            path: '/users',
            title: 'Users',
            handler: async () => '<h1>Users</h1>',
          }),
        ],
      }),
    ]);

    const prefixed = await app.fetch(
      new Request('http://localhost/admin/users')
    );
    const unprefixed = await app.fetch(new Request('http://localhost/users'));
    expect(prefixed.status).toBe(200);
    expect(unprefixed.status).toBe(404);
  });

  it('reuses ISR cache in node runtime', async () => {
    const app = new Hono();
    let renders = 0;
    registerRoutes(
      app,
      [
        SolRoutes.Page({
          path: '/',
          title: 'Home',
          revalidate: 60,
          handler: async () => {
            renders += 1;
            return `<p>${renders}</p>`;
          },
        }),
      ],
      { enableISR: true }
    );

    const r1 = await app.fetch(new Request('http://localhost/'));
    const b1 = await r1.text();
    const r2 = await app.fetch(new Request('http://localhost/'));
    const b2 = await r2.text();

    expect(r1.headers.get('X-Sol-Cache')).toBe('miss');
    expect(r2.headers.get('X-Sol-Cache')).toBe('hit');
    expect(b1).toContain('<p>1</p>');
    expect(b2).toContain('<p>1</p>');
    expect(renders).toBe(1);
  });

  it('rejects revalidate requests without token by default', async () => {
    const app = new Hono();
    app.use('*', revalidateMiddleware(new ISRCacheManager(new MemoryCacheAdapter())));
    app.get('/', (c) => c.text('ok'));

    const res = await app.fetch(
      new Request('http://localhost/api/revalidate', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ path: '/x' }),
      })
    );

    expect(res.status).toBe(401);
  });

  it('accepts revalidate requests with a valid token', async () => {
    const app = new Hono();
    app.use(
      '*',
      revalidateMiddleware(new ISRCacheManager(new MemoryCacheAdapter()), {
        token: 'secret-token',
      })
    );
    app.get('/', (c) => c.text('ok'));

    const res = await app.fetch(
      new Request('http://localhost/api/revalidate', {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          'X-Sol-Revalidate-Token': 'secret-token',
        },
        body: JSON.stringify({ path: '/x' }),
      })
    );

    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ revalidated: true, path: '/x' });
  });

  it('accepts token from SOL_REVALIDATE_TOKEN env', async () => {
    process.env.SOL_REVALIDATE_TOKEN = 'env-secret';

    const app = new Hono();
    app.use('*', revalidateMiddleware(new ISRCacheManager(new MemoryCacheAdapter())));
    app.get('/', (c) => c.text('ok'));

    const res = await app.fetch(
      new Request('http://localhost/api/revalidate', {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          'X-Sol-Revalidate-Token': 'env-secret',
        },
        body: JSON.stringify({ path: '/x' }),
      })
    );

    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ revalidated: true, path: '/x' });
  });

  it('supports custom endpoint and token header', async () => {
    const app = new Hono();
    app.use(
      '*',
      revalidateMiddleware(new ISRCacheManager(new MemoryCacheAdapter()), {
        token: 'secret-token',
        endpoint: '/internal/revalidate',
        tokenHeader: 'X-Internal-Revalidate-Token',
      })
    );
    app.get('/', (c) => c.text('ok'));

    const res = await app.fetch(
      new Request('http://localhost/internal/revalidate', {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          'X-Internal-Revalidate-Token': 'secret-token',
        },
        body: JSON.stringify({ path: '/x' }),
      })
    );

    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ revalidated: true, path: '/x' });
  });

  it('rejects invalid revalidate path values', async () => {
    const app = new Hono();
    app.use(
      '*',
      revalidateMiddleware(new ISRCacheManager(new MemoryCacheAdapter()), {
        token: 'secret-token',
      })
    );
    app.get('/', (c) => c.text('ok'));

    const res = await app.fetch(
      new Request('http://localhost/api/revalidate', {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          'X-Sol-Revalidate-Token': 'secret-token',
        },
        body: JSON.stringify({ path: 'x' }),
      })
    );

    expect(res.status).toBe(400);
    expect(await res.json()).toEqual({ error: 'Path must start with /' });
  });
});
