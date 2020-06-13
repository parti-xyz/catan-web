export default class Timer {
  constructor(fn, time) {
    this.fn = fn
    this.time = time
    this.timerObj = setInterval(fn, time)
  }

  stop() {
    if (!this.timerObj) { return  }

    clearInterval(this.timerObj)
    this.timerObj = null

    return this
  }

  start(first = false) {
    if (this.timerObj) { return }

    if (first) {
      this.fn()
    }
    this.stop()
    this.timerObj = setInterval(this.fn, this.time)

    return this
  }

  reset(first = false) {
    return this.stop().start(first)

    return this
  }
}
