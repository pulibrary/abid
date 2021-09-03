// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import Rails from "@rails/ujs"
import Turbolinks from "turbolinks"
import * as ActiveStorage from "@rails/activestorage"
import Vue from "vue/dist/vue.esm";
import system from "lux-design-system";
import "lux-design-system/dist/system/system.css";
import "lux-design-system/dist/system/tokens/tokens.scss";
import "channels"
import "bootstrap"
import "../stylesheets/application"
import $ from 'jquery';
import 'datatables.net-bs4';
import BatchForm from "batch_form"
import TurbolinksAdapter from 'vue-turbolinks';
require("@nathanvda/cocoon");

Rails.start()
Turbolinks.start()
ActiveStorage.start()

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
document.addEventListener("turbolinks:load", loadPage)
