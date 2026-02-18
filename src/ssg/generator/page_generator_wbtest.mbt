// Page generator internal tests

///|
test "parse_dynamic_source_path - decodes catch-all slash from query" {
  let (path, params) = parse_dynamic_source_path(
    "docs/_...slug_/index.md?slug=guide%2Fintro",
  )
  assert_eq(path, "docs/_...slug_/index.md")
  assert_eq(params.get("slug"), Some("guide/intro"))
}

///|
test "parse_dynamic_source_path - handles encoded special chars" {
  let (path, params) = parse_dynamic_source_path(
    "posts/_id_.md?id=a%2Bb%3Dc%26d",
  )
  assert_eq(path, "posts/_id_.md")
  assert_eq(params.get("id"), Some("a+b=c&d"))
}
