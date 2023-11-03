# frozen_string_literal: true
server "abid-prod1.princeton.edu", user: "deploy", roles: %w[app db web]
server "abid-prod2.princeton.edu", user: "deploy", roles: %w[app web]
