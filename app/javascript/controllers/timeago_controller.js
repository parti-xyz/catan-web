import { Controller } from 'stimulus'
import { render, register } from 'timeago.js'

const localeFunc = (number, index) => {
  return [
    ['방금', '곧'],
    ['%s초 전', '%s초 후'],
    ['1분 전', '1분 후'],
    ['%s분 전', '%s분 후'],
    ['1시간 전', '1시간 후'],
    ['%s시간 전', '%s시간 후'],
    ['1일 전', '1일 후'],
    ['%s일 전', '%s일 후'],
    ['1주일 전', '1주일 후'],
    ['%s주일 전', '%s주일 후'],
    ['1개월 전', '1개월 후'],
    ['%s개월 전', '%s개월 후'],
    ['1년 전', '1년 후'],
    ['%s년 전', '%s년 후'],
  ][index]
}

export default class extends Controller {
  connect() {
    let targetDate = new Date(this.element.getAttribute('datetime'))
    let currentDate = new Date()
    let timeDiff = Math.abs(currentDate.getTime() - targetDate.getTime())
    let diffDays = Math.ceil(timeDiff / (1000 * 3600 * 24))
    if (diffDays <= 1) {
      register('ko', localeFunc)
      render(this.element, 'ko')
    }
  }
}