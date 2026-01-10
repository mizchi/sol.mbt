import {
  SolRoutes,
  type PageProps,
  type SolRoute,
  type RouterConfig,
  DEFAULT_ROOT_TEMPLATE,
} from '@luna_ui/luna/routes';
import { renderToString, raw } from '@luna_ui/luna/html';

// ============================================================================
// Layouts
// ============================================================================

async function RootLayout(props: PageProps, children: string): Promise<string> {
  return renderToString(
    <div class="app">
      <header class="header">
        <h1>Sol TSX Example</h1>
        <nav class="nav">
          <ul>
            <li><a href="/">Home</a></li>
            <li><a href="/about">About</a></li>
            <li><a href="/blog">Blog</a></li>
            <li><a href="/contact">Contact</a></li>
          </ul>
        </nav>
      </header>
      <main class="main">
        {raw(children)}
      </main>
      <footer class="footer">
        <p>Built with Sol Framework (TypeScript TSX mode)</p>
      </footer>
    </div>
  );
}

// ============================================================================
// Pages
// ============================================================================

async function HomePage(_props: PageProps): Promise<string> {
  return renderToString(
    <div class="home">
      <h1>Welcome to Sol TSX</h1>
      <p>This is a fully TypeScript-based Sol application with JSX syntax.</p>
      <div class="features">
        <h2>Features</h2>
        <ul>
          <li>Pure TypeScript with JSX</li>
          <li>Type-safe components</li>
          <li>Hot reload with tsx</li>
          <li>Same SSR as MoonBit version</li>
        </ul>
      </div>
    </div>
  );
}

async function AboutPage(_props: PageProps): Promise<string> {
  return renderToString(
    <div class="about">
      <h1>About</h1>
      <p>Sol is a server-side rendering framework.</p>
      <p>This example demonstrates the TypeScript TSX mode.</p>
      <h2>Architecture</h2>
      <ul>
        <li>Server: Hono + Node.js</li>
        <li>Routing: SolRoutes DSL</li>
        <li>Rendering: JSX → VNode → HTML string</li>
      </ul>
    </div>
  );
}

// Post data type
interface Post {
  id: string;
  title: string;
  date: string;
}

// Post card component
function PostCard({ post }: { post: Post }) {
  return (
    <li>
      <a href={`/blog/${post.id}`}>{post.title}</a>
      <span class="date"> ({post.date})</span>
    </li>
  );
}

// Post detail component
function PostDetail({ post }: { post: Post }) {
  return (
    <div class="blog-post">
      <h1>{post.title}</h1>
      <p class="date">Published: {post.date}</p>
      <p>This is the full content of the blog post...</p>
      <a href="/blog">← Back to Blog</a>
    </div>
  );
}

async function BlogPage(props: PageProps): Promise<string> {
  const slug = props.params.get_param?.('slug') || '';
  const posts: Post[] = [
    { id: '1', title: 'Getting Started with Sol', date: '2024-01-01' },
    { id: '2', title: 'TypeScript Support', date: '2024-01-15' },
    { id: '3', title: 'Performance Tips', date: '2024-02-01' },
  ];

  if (slug) {
    const post = posts.find((p) => p.id === slug);
    if (post) {
      return renderToString(<PostDetail post={post} />);
    }
  }

  return renderToString(
    <div class="blog">
      <h1>Blog</h1>
      <ul class="posts">
        {posts.map((post) => <PostCard post={post} />)}
      </ul>
    </div>
  );
}

async function ContactPage(_props: PageProps): Promise<string> {
  return renderToString(
    <div class="contact">
      <h1>Contact</h1>
      <form method="POST" action="/api/contact">
        <div class="field">
          <input type="text" name="name" placeholder="Your Name" required />
        </div>
        <div class="field">
          <input type="email" name="email" placeholder="Your Email" required />
        </div>
        <div class="field">
          <input type="text" name="message" placeholder="Message" required />
        </div>
        <button type="submit">Send Message</button>
      </form>
    </div>
  );
}

// ============================================================================
// API Handlers
// ============================================================================

async function apiHealth(_props: PageProps): Promise<object> {
  return { status: 'ok', timestamp: new Date().toISOString() };
}

async function apiContact(_props: PageProps): Promise<object> {
  return { success: true, message: 'Message received!' };
}

// ============================================================================
// Route Definitions
// ============================================================================

export function routes(): SolRoute[] {
  return [
    SolRoutes.Layout({
      segment: '',
      layout: RootLayout,
      children: [
        SolRoutes.Page({
          path: '/',
          handler: HomePage,
          title: 'Home',
        }),
        SolRoutes.Page({
          path: '/about',
          handler: AboutPage,
          title: 'About',
        }),
        SolRoutes.Page({
          path: '/blog',
          handler: BlogPage,
          title: 'Blog',
        }),
        SolRoutes.Page({
          path: '/blog/:slug',
          handler: BlogPage,
          title: 'Blog Post',
        }),
        SolRoutes.Page({
          path: '/contact',
          handler: ContactPage,
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
