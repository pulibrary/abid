export default class BatchForm {
  constructor() {
    this.preventBarcodeSubmit()
  }

  preventBarcodeSubmit() {
    this.barcodeField.addEventListener('keydown', () => {
      const event = window.event || e
      if (event.key == "Enter") {
        event.preventDefault()
        this.callNumberField.focus()
      }
    })
  }

  get barcodeField() {
    return document.getElementById("batch_first_barcode")
  }

  get callNumberField() {
    return document.getElementById("batch_call_number")
  }
}
