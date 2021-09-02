export default class BatchForm {
  constructor() {
    this.preventBarcodeSubmit()
  }

  // Barcode scanners type in a code and then hit "enter", this piece of code
  // makes it so hitting enter doesn't submit the form.
  // For MARC Batches they need to enter multiple barcodes, so it prevents
  // submission and then hits the Cocoon link to add another AbID, then focuses
  // that new field. Cocoon can only be triggered by hitting the link.
  preventBarcodeSubmit() {
    this.form.addEventListener('keydown', (e) => {
      const event = window.event || e
      if (event.key == "Enter" && event.target.classList.contains('barcode')) {
        event.preventDefault()
        let tar = event.target
        const add_field_link = document.getElementsByClassName("add_fields")[0]
        // Click the link if it exists.
        if(add_field_link !== undefined) {
          add_field_link.click()
        }
        // Find the next non-hidden simple form input and focus it.
        const inputs = [].slice.call(document.querySelectorAll(".form-control:not([type='hidden'])"))
        const idx = inputs.indexOf(tar)
        if(inputs[idx+1] !== undefined)
          inputs[idx+1].focus()
      }
    })
  }

  get form() {
    return document.getElementsByTagName("form")[0]
  }
}
