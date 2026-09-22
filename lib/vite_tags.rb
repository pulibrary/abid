# frozen_string_literal: true

require "vite_ruby"

# Replaces the vite_rails view helpers (vite_client_tag, vite_javascript_tag,
# vite_stylesheet_tag). vite_ruby's core is framework-agnostic; only the Rails
# helper module had to be reimplemented.
module ViteTags
  module_function

  def vite = ViteRuby.instance

  def dev_server_running? = vite.dev_server_running?

  # In development the Vite dev server injects its HMR client.
  def vite_client_tag
    return "" unless dev_server_running?

    %(<script src="#{vite.config.origin}#{vite.config.public_output_dir}/@vite/client" type="module"></script>)
  end

  def vite_javascript_tag(name)
    entry = "entrypoints/#{name}.js"
    tags = [%(<script src="#{asset_path(entry)}" type="module" crossorigin="anonymous"></script>)]
    tags.concat(stylesheet_tags_for(entry))
    tags.join("\n")
  end

  def asset_path(entry)
    if dev_server_running?
      "#{vite.config.origin}#{vite.config.public_output_dir}/#{entry}"
    else
      lookup(entry).fetch("file")
    end
  end

  # Vite extracts imported CSS into a sibling asset in a production build; the
  # dev server serves it through the JS entrypoint instead.
  def stylesheet_tags_for(entry)
    return [] if dev_server_running?

    Array(lookup(entry)["css"]).map do |href|
      %(<link rel="stylesheet" href="#{href}" />)
    end
  end

  def lookup(entry)
    vite.manifest.resolve_entries(entry)[:scripts].then do |scripts|
      { "file" => scripts.first, "css" => vite.manifest.resolve_entries(entry)[:stylesheets] }
    end
  rescue StandardError
    { "file" => "/#{vite.config.public_output_dir}/#{entry}", "css" => [] }
  end
end
