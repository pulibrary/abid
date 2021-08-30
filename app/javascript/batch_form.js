export default class BatchForm {
  constructor() {
    this.preventBarcodeSubmit()
  }

  preventBarcodeSubmit() {
    this.form.addEventListener('keydown', (e) => {
      const event = window.event || e
      if (event.key == "Enter" && event.target.classList.contains('barcode')) {
        event.preventDefault()
        let tar = event.target
        const inputs = [].slice.call(document.querySelectorAll(".form-control:not([type='hidden'])"))
        const idx = inputs.indexOf(tar)
        inputs[idx+1].focus()
      }
    })
  }

  get form() {
    return document.getElementsByTagName("form")[0]
  }
}
