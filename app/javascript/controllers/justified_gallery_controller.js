import { Controller } from "stimulus"
import 'justifiedGallery/dist/js/jquery.justifiedGallery';

export default class extends Controller {
  connect() {
    jQuery(this.element).justifiedGallery()
    this.gallery = this.element.dataset['jg.controller']
  }
}