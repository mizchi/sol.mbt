test "render_document wraps body with app container by default" {
  let html = render_document("App", "", "<p>hello</p>")
  assert_true(html.contains("<div id=\"app\"><p>hello</p></div>"))
}

///|
test "render_document can disable app container wrapping" {
  let html = render_document("App", "", "<p>hello</p>", wrap_in_app=false)
  assert_true(html.contains("<body><p>hello</p></body>"))
}

///|
test "render_template replaces all placeholders" {
  let tpl = "__LUNA_TITLE__|__LUNA_HEAD__|__LUNA_PRELOAD__|__LUNA_MAIN__"
  let result = render_template(tpl, "T", "H", "P", "M")
  assert_eq(result, "T|H|P|M")
}

///|
test "render_streaming_header includes loader url" {
  let header = render_streaming_header("App", "", "/static/loader.js")
  assert_true(header.contains("<script type=\"module\" src=\"/static/loader.js\"></script>"))
}

///|
test "escape_html_text escapes entities" {
  let escaped = escape_html_text("<>&\"'")
  assert_eq(escaped, "&lt;&gt;&amp;&quot;&#39;")
}
