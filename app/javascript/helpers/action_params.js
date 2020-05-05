
const camelToDash = (str) => {
  let result = '', prevLowercase = false
  for (let char of str) {
    const isUppercase = char.toUpperCase() === char
    if (isUppercase && prevLowercase) {
      result += '-'
    }
    result += char;
    prevLowercase = !isUppercase
  }
  return result.replace(/-+/g, '-').toLowerCase()
}

const dashToCamel = (str) => {
  return str.replace(/([-_][a-z])/ig, ($1) => {
    return $1.toUpperCase()
      .replace('-', '')
      .replace('_', '')
  })
}

const toLowerCaseFirstLetter = (str) => {
  return str.charAt(0).toLowerCase() + str.slice(1)
}

const actionParams = (controller, element) => {
  return Object.keys(element.dataset).filter(key => {
    return camelToDash(key).match(new RegExp('^' + controller.identifier + '-'))
  }).reduce((result, key) => {
    name = toLowerCaseFirstLetter(key.slice(dashToCamel(controller.identifier).length))
    result[name] = element.dataset[key]
    return result;
  }, {})
}

export default actionParams