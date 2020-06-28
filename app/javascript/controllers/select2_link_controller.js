import { Controller } from "stimulus"
import Select2 from "select2/dist/js/select2.full"
import fillTemplate from 'es6-dynamic-template'
import ParamMap from '../helpers/param_map'

export default class extends Controller {
  connect() {
    jQuery(this.element).select2({
      theme: 'bootstrap',
      dropdownCssClass: ':all:',
      width: 'auto',
      language: this.language(),
      templateSelection: (node) => {
        if (!node.id) {
          return node.text;
        }

        const fullPath = node.element.dataset.fullpath
        return fullPath ? jQuery(`<span>${fullPath}</span>`) : node.text;
      },
      templateResult: (node) => {
        if (!node.id) {
          return node.text;
        }

        if(!node.element) {return}
        var $result = jQuery('<span style="display: flex; flex-wrap: nowrap"><span style="flex: none; width:' + (20 * +node.element.dataset.depth) + 'px;"></span><span style="flex:1">' + node.text + '</span></span>')

        return $result
      },
    })

    jQuery(this.element).on('select2:select', this.go.bind(this))
  }

  disconnect() {
    jQuery(this.element).select2('destroy')
  }

  go(event) {
    console.log(event)

    const urlTemplate = new ParamMap(this, event.currentTarget).get('urlTemplate')
    if (!urlTemplate) return

    const value = event.currentTarget.value
    const url = value
      ? fillTemplate(decodeURIComponent(urlTemplate), { value })
      : urlTemplate

    Turbolinks.visit(url)
  }

  language() {
    return {
      errorLoading: function () {
        return '결과를 불러올 수 없습니다.'
      },
      inputTooLong: function (args) {
        var overChars = args.input.length - args.maximum

        var message = '너무 깁니다. ' + overChars + ' 글자 지워주세요.'

        return message
      },
      inputTooShort: function (args) {
        var remainingChars = args.minimum - args.input.length

        var message = '너무 짧습니다. ' + remainingChars + ' 글자 더 입력해주세요.'

        return message
      },
      loadingMore: function () {
        return '불러오는 중…'
      },
      maximumSelected: function (args) {
        var message = '최대 ' + args.maximum + '개까지만 선택 가능합니다.'

        return message
      },
      noResults: function () {
        return '결과가 없습니다.'
      },
      searching: function () {
        return '검색 중…'
      },
      removeAllItems: function () {
        return '모든 항목 삭제'
      }
    }
  }
}