// Shared HTML page shell helpers

///|
/// Render the app container.
pub fn app_container(inner_html : String) -> String {
  "<div id=\"app\">" + inner_html + "</div>"
}

///|
/// Render a full HTML document.
pub fn render_document(
  title : String,
  head : String,
  body_html : String,
  wrap_in_app? : Bool = true,
) -> String {
  let main_html = if wrap_in_app { app_container(body_html) } else { body_html }
  "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"><title>" +
  title +
  "</title>" +
  head +
  "</head><body>" +
  main_html +
  "</body></html>"
}

///|
/// Render a template with Sol placeholders.
pub fn render_template(
  template : String,
  title : String,
  head : String,
  preload : String,
  main : String,
) -> String {
  template
  .replace(old="__LUNA_TITLE__", new=title)
  .replace(old="__LUNA_PRELOAD__", new=preload)
  .replace(old="__LUNA_HEAD__", new=head)
  .replace(old="__LUNA_MAIN__", new=main)
}

///|
/// Render streaming SSR header.
pub fn render_streaming_header(
  title : String,
  head : String,
  loader_url : String,
) -> String {
  "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"><title>" +
  title +
  "</title>" +
  head +
  "<script type=\"module\" src=\"" +
  loader_url +
  "\"></script></head><body><div id=\"app\">"
}

///|
/// Render streaming SSR footer.
pub fn render_streaming_footer() -> String {
  "</div></body></html>"
}

///|
/// Escape HTML entities for text insertion (e.g. title template fragment).
pub fn escape_html_text(s : String) -> String {
  let buf = StringBuilder::new()
  for ch in s {
    match ch {
      '<' => buf.write_string("&lt;")
      '>' => buf.write_string("&gt;")
      '&' => buf.write_string("&amp;")
      '"' => buf.write_string("&quot;")
      '\'' => buf.write_string("&#39;")
      _ => buf.write_char(ch)
    }
  }
  buf.to_string()
}
