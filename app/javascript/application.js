// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
// import Rails from "@rails/ujs"
// import * as ActiveStorage from "@rails/activestorage"
// import "channels"

import * as Turbo from "@hotwired/turbo"
import TurbolinksAdapter from 'vue-turbolinks';
import Vue from "vue"
import system from "lux-design-system";
// import "lux-design-system/dist/system/system.css";
// import "lux-design-system/dist/system/tokens/tokens.scss";
// import "../stylesheets/application"

import "popper"
import "bootstrap"
import $ from 'jquery';
import DataTable from 'datatables.net-bs4';
import BatchForm from "batch_form"
// require("@nathanvda/cocoon");

// Rails.start()
// ActiveStorage.start()

window.DataTable = DataTable();

Vue.use(TurbolinksAdapter);
Vue.use(system)
// create the LUX app and mount it to wrappers with class="lux"
var loadPage = () => {
  var elements = document.getElementsByClassName("lux")
  for (var i = 0; i < elements.length; i++) {
    new Vue({
      el: elements[i]
    })
  }
  new BatchForm()
}
document.addEventListener("DOMContentLoaded", () => {
  $('.datatable').DataTable({
    "searching": false,
    "paging": false,
    "info": false
  })
})
document.addEventListener("turbo:load", loadPage)
