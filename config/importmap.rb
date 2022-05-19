# frozen_string_literal: true
# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "batch_form", preload: true
pin "vue", to: "https://ga.jspm.io/npm:vue@2.6.12/dist/vue.runtime.common.js"
pin "process", to: "https://ga.jspm.io/npm:@jspm/core@2.0.0-beta.24/nodelibs/browser/process-production.js"
pin "vue-turbolinks", to: "https://ga.jspm.io/npm:vue-turbolinks@2.2.2/index.js"
pin "lux-design-system", to: "https://ga.jspm.io/npm:lux-design-system@2.17.0/dist/system/system.js"
pin "jquery", to: "https://ga.jspm.io/npm:jquery@3.6.0/dist/jquery.js"
pin "datatables.net-bs4", to: "https://ga.jspm.io/npm:datatables.net-bs4@1.10.25/js/dataTables.bootstrap4.js"
pin "datatables.net", to: "https://ga.jspm.io/npm:datatables.net@1.10.25/js/jquery.dataTables.js"
pin "popper", to: "popper.js", preload: true
pin "bootstrap", to: "bootstrap.min.js", preload: true
pin "@hotwired/turbo", to: "https://ga.jspm.io/npm:@hotwired/turbo@7.1.0/dist/turbo.es2017-esm.js"
