import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const errorRate = new Rate('errors');
const homeTrend = new Trend('home_duration');
const aboutTrend = new Trend('about_duration');
const blogTrend = new Trend('blog_duration');
const blogPostTrend = new Trend('blog_post_duration');
const apiTrend = new Trend('api_duration');

export const options = {
  scenarios: {
    sol_tsx: {
      executor: 'constant-vus',
      vus: 50,
      duration: '30s',
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<500'],
    errors: ['rate<0.01'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

export default function () {
  // Home page
  const homeRes = http.get(`${BASE_URL}/`);
  homeTrend.add(homeRes.timings.duration);
  check(homeRes, {
    'home status 200': (r) => r.status === 200,
    'home has content': (r) => r.body.includes('__sol__'),
  }) || errorRate.add(1);

  // About page
  const aboutRes = http.get(`${BASE_URL}/about`);
  aboutTrend.add(aboutRes.timings.duration);
  check(aboutRes, {
    'about status 200': (r) => r.status === 200,
  }) || errorRate.add(1);

  // Blog list page
  const blogRes = http.get(`${BASE_URL}/blog`);
  blogTrend.add(blogRes.timings.duration);
  check(blogRes, {
    'blog status 200': (r) => r.status === 200,
  }) || errorRate.add(1);

  // Blog post (dynamic route)
  const postId = ['1', '2', '3'][Math.floor(Math.random() * 3)];
  const blogPostRes = http.get(`${BASE_URL}/blog/${postId}`);
  blogPostTrend.add(blogPostRes.timings.duration);
  check(blogPostRes, {
    'blog post status 200': (r) => r.status === 200,
  }) || errorRate.add(1);

  // API health
  const apiRes = http.get(`${BASE_URL}/api/health`);
  apiTrend.add(apiRes.timings.duration);
  check(apiRes, {
    'api status 200': (r) => r.status === 200,
    'api returns json': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.status === 'ok';
      } catch {
        return false;
      }
    },
  }) || errorRate.add(1);

  sleep(0.1);
}

export function handleSummary(data) {
  return {
    stdout: textSummary(data),
  };
}

function textSummary(data) {
  const m = data.metrics;
  const fmt = (v) => (v || 0).toFixed(2);

  return `
╔══════════════════════════════════════════════════════════════════╗
║                    Sol TSX Benchmark Results                     ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  Requests:                                                       ║
║    Total: ${String(m.http_reqs?.values?.count || 0).padStart(6)}                                              ║
║    Rate:  ${fmt(m.http_reqs?.values?.rate).padStart(8)}/s                                         ║
║                                                                  ║
║  Response Times (p95):                                           ║
║    Home:        ${fmt(m.home_duration?.values?.['p(95)']).padStart(7)}ms                                  ║
║    About:       ${fmt(m.about_duration?.values?.['p(95)']).padStart(7)}ms                                  ║
║    Blog List:   ${fmt(m.blog_duration?.values?.['p(95)']).padStart(7)}ms                                  ║
║    Blog Post:   ${fmt(m.blog_post_duration?.values?.['p(95)']).padStart(7)}ms                                  ║
║    API Health:  ${fmt(m.api_duration?.values?.['p(95)']).padStart(7)}ms                                  ║
║                                                                  ║
║  Overall:                                                        ║
║    Avg: ${fmt(m.http_req_duration?.values?.avg).padStart(7)}ms                                        ║
║    p50: ${fmt(m.http_req_duration?.values?.['p(50)']).padStart(7)}ms                                        ║
║    p95: ${fmt(m.http_req_duration?.values?.['p(95)']).padStart(7)}ms                                        ║
║    p99: ${fmt(m.http_req_duration?.values?.['p(99)']).padStart(7)}ms                                        ║
║                                                                  ║
║  Error Rate: ${((m.errors?.values?.rate || 0) * 100).toFixed(2)}%                                        ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
`;
}
