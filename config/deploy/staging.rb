# frozen_string_literal: true

server "abid-staging1.princeton.edu", user: "deploy", roles: %w[app db web]
server "abid-staging2.princeton.edu", user: "deploy", roles: %w[app db web]
