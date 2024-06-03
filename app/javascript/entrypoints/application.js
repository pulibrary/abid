import Rails from "@rails/ujs"
import Turbolinks from "turbolinks"
import * as ActiveStorage from "@rails/activestorage"
import "bootstrap"
import "@/stylesheets/application.scss"
import $ from 'jquery';
import 'datatables.net-bs4';
import {createApp} from "vue";
import lux from "lux-design-system";
import "lux-design-system/dist/style.css";
import BatchForm from "@/batch_form"
import TurbolinksAdapter from 'vue-turbolinks';
import "cocoon-js-vanilla";

Rails.start()
Turbolinks.start()
ActiveStorage.start()

const app = createApp({});
const createMyApp = () => createApp(app);

// create the LUX app and mount it to wrappers with class="lux"
var loadPage = () => {
  const elements = document.getElementsByClassName('lux')
  for(let i = 0; i < elements.length; i++){
    createMyApp().use(lux).use(TurbolinksAdapter).mount(elements[i]);
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
document.addEventListener("turbolinks:load", loadPage, { once: false })
