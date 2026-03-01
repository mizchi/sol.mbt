import { test, expect } from "@playwright/test";

const REVALIDATE_TOKEN = process.env.SOL_REVALIDATE_TOKEN || "e2e-revalidate-token";

test.describe("Security E2E", () => {
  test("revalidate endpoint returns 401 without token", async ({ request }) => {
    const res = await request.post("/api/revalidate", {
      data: { path: "/x" },
    });

    expect(res.status()).toBe(401);
    expect(await res.json()).toEqual({ error: "Unauthorized" });
  });

  test("revalidate endpoint returns 200 with token", async ({ request }) => {
    const res = await request.post("/api/revalidate", {
      headers: { "X-Sol-Revalidate-Token": REVALIDATE_TOKEN },
      data: { path: "/x" },
    });

    expect(res.status()).toBe(200);
    expect(await res.json()).toEqual({ revalidated: true, path: "/x" });
  });

  test("static traversal attempt returns 404", async ({ request }) => {
    const traversal = await request.get("/static/..%2F..%2Fetc/passwd");
    expect(traversal.status()).toBe(404);
  });
});
