export default class BatchForm {
  constructor() {
    this.preventBarcodeSubmit()
  }

  preventBarcodeSubmit() {
    for(let field of this.barcodeFields) {
      field.addEventListener('keydown', () => {
        const event = window.event || e
        if (event.key == "Enter") {
          event.preventDefault()
          let tar = event.target
          const inputs = [].slice.call(document.querySelectorAll(".form-control:not([type='hidden'])"))
          const idx = inputs.indexOf(tar)
          inputs[idx+1].focus()
        }
      })
    }
  }

  get barcodeFields() {
    return document.getElementsByClassName("barcode")
  }
}
