import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  submit() {
    // Auto-submit form when input changes
    // If input is empty, this will show all doctors
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, 300) // 300ms debounce to avoid too many requests while typing
  }

  clear() {
    // Clear the input and submit to show all doctors
    this.inputTarget.value = ""
    this.element.requestSubmit()
  }
}
