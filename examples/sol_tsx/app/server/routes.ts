import {
  SolRoutes,
  type PageProps,
  type SolRoute,
  type RouterConfig,
  DEFAULT_ROOT_TEMPLATE,
} from '@sol/core/routes';
import {
  div,
  h1,
  h2,
  p,
  a,
  ul,
  li,
  nav,
  main,
  header,
  footer,
  form,
  input,
  button,
  span,
  raw,
  renderToString,
} from '@sol/core/html';

// ============================================================================
// Layouts
// ============================================================================

async function rootLayout(props: PageProps, children: string): Promise<string> {
  const navigation = nav({ class: 'nav' }, [
    ul(null, [
      li(null, [a({ href: '/' }, ['Home'])]),
      li(null, [a({ href: '/about' }, ['About'])]),
      li(null, [a({ href: '/blog' }, ['Blog'])]),
      li(null, [a({ href: '/contact' }, ['Contact'])]),
    ]),
  ]);

  const head = header({ class: 'header' }, [
    h1(null, ['Sol TSX Example']),
    navigation,
  ]);

  const foot = footer({ class: 'footer' }, [
    p(null, ['Built with Sol Framework (TypeScript mode)']),
  ]);

  return renderToString(
    div({ class: 'app' }, [
      head,
      main({ class: 'main' }, [raw(children)]),
      foot,
    ])
  );
}

// ============================================================================
// Pages
// ============================================================================

async function homePage(props: PageProps): Promise<string> {
  return renderToString(
    div({ class: 'home' }, [
      h1(null, ['Welcome to Sol TSX']),
      p(null, ['This is a fully TypeScript-based Sol application.']),
      div({ class: 'features' }, [
        h2(null, ['Features']),
        ul(null, [
          li(null, ['Pure TypeScript implementation']),
          li(null, ['No MoonBit compilation required']),
          li(null, ['Hot reload with tsx']),
          li(null, ['Same DSL as MoonBit version']),
        ]),
      ]),
    ])
  );
}

async function aboutPage(props: PageProps): Promise<string> {
  return renderToString(
    div({ class: 'about' }, [
      h1(null, ['About']),
      p(null, ['Sol is a server-side rendering framework.']),
      p(null, ['This example demonstrates the TypeScript-only mode.']),
      h2(null, ['Architecture']),
      ul(null, [
        li(null, ['Server: Hono + Node.js']),
        li(null, ['Routing: SolRoutes DSL']),
        li(null, ['Rendering: VNode → HTML string']),
      ]),
    ])
  );
}

async function blogPage(props: PageProps): Promise<string> {
  const slug = props.params.get_param?.('slug') || '';
  const posts = [
    { id: '1', title: 'Getting Started with Sol', date: '2024-01-01' },
    { id: '2', title: 'TypeScript Support', date: '2024-01-15' },
    { id: '3', title: 'Performance Tips', date: '2024-02-01' },
  ];

  if (slug) {
    const post = posts.find((p) => p.id === slug);
    if (post) {
      return renderToString(
        div({ class: 'blog-post' }, [
          h1(null, [post.title]),
          p({ class: 'date' }, [`Published: ${post.date}`]),
          p(null, ['This is the full content of the blog post...']),
          a({ href: '/blog' }, ['← Back to Blog']),
        ])
      );
    }
  }

  return renderToString(
    div({ class: 'blog' }, [
      h1(null, ['Blog']),
      ul({ class: 'posts' },
        posts.map((post) =>
          li(null, [
            a({ href: `/blog/${post.id}` }, [post.title]),
            span({ class: 'date' }, [` (${post.date})`]),
          ])
        )
      ),
    ])
  );
}

async function contactPage(props: PageProps): Promise<string> {
  return renderToString(
    div({ class: 'contact' }, [
      h1(null, ['Contact']),
      form({ method: 'POST', action: '/api/contact' }, [
        div({ class: 'field' }, [
          input({ type: 'text', name: 'name', placeholder: 'Your Name', required: true }),
        ]),
        div({ class: 'field' }, [
          input({ type: 'email', name: 'email', placeholder: 'Your Email', required: true }),
        ]),
        div({ class: 'field' }, [
          input({ type: 'text', name: 'message', placeholder: 'Message', required: true }),
        ]),
        button({ type: 'submit' }, ['Send Message']),
      ]),
    ])
  );
}

// ============================================================================
// API Handlers
// ============================================================================

async function apiHealth(props: PageProps): Promise<object> {
  return { status: 'ok', timestamp: new Date().toISOString() };
}

async function apiContact(props: PageProps): Promise<object> {
  // In real app, would process form data
  return { success: true, message: 'Message received!' };
}

// ============================================================================
// Route Definitions
// ============================================================================

export function routes(): SolRoute[] {
  return [
    SolRoutes.Layout({
      segment: '',
      layout: rootLayout,
      children: [
        SolRoutes.Page({
          path: '/',
          handler: homePage,
          title: 'Home',
        }),
        SolRoutes.Page({
          path: '/about',
          handler: aboutPage,
          title: 'About',
        }),
        SolRoutes.Page({
          path: '/blog',
          handler: blogPage,
          title: 'Blog',
        }),
        SolRoutes.Page({
          path: '/blog/:slug',
          handler: blogPage,
          title: 'Blog Post',
        }),
        SolRoutes.Page({
          path: '/contact',
          handler: contactPage,
          title: 'Contact',
        }),
      ],
    }),
    SolRoutes.Get({
      path: '/api/health',
      handler: apiHealth,
    }),
    SolRoutes.Post({
      path: '/api/contact',
      handler: apiContact,
    }),
  ];
}

export function config(): RouterConfig {
  return {
    rootTemplate: DEFAULT_ROOT_TEMPLATE,
    defaultHead: '<style>body { font-family: system-ui; max-width: 800px; margin: 0 auto; padding: 20px; } .nav ul { display: flex; gap: 20px; list-style: none; padding: 0; } .footer { margin-top: 40px; padding-top: 20px; border-top: 1px solid #eee; color: #666; }</style>',
    titlePrefix: 'Sol TSX | ',
  };
}
