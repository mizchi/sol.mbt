///|
test "sanitize_static_relative_path: accepts normal relative paths" {
  match sanitize_static_relative_path("loader.js") {
    Some(path) => assert_eq(path, "loader.js")
    None => fail("expected safe path")
  }
  match sanitize_static_relative_path("assets/app/main.css") {
    Some(path) => assert_eq(path, "assets/app/main.css")
    None => fail("expected safe nested path")
  }
}

///|
test "sanitize_static_relative_path: rejects path traversal patterns" {
  assert_true(sanitize_static_relative_path("../secret.txt") is None)
  assert_true(sanitize_static_relative_path("assets/../../secret.txt") is None)
  assert_true(sanitize_static_relative_path("assets/..") is None)
  assert_true(sanitize_static_relative_path("..") is None)
}

///|
test "sanitize_static_relative_path: rejects encoded traversal patterns" {
  assert_true(sanitize_static_relative_path("%2e%2e%2fsecret.txt") is None)
  assert_true(sanitize_static_relative_path("..%2F..%2Fetc/passwd") is None)
}

///|
test "sanitize_static_relative_path: rejects absolute and windows-like paths" {
  assert_true(sanitize_static_relative_path("/etc/passwd") is None)
  assert_true(sanitize_static_relative_path("C:\\windows\\win.ini") is None)
  assert_true(sanitize_static_relative_path("..\\..\\secret.txt") is None)
}
