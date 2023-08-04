# frozen_string_literal: true
WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: [
    "chromedriver.storage.googleapis.com",
    "googlechromelabs.github.io",
    "edgedl.me.gvt1.com"
  ]
)
