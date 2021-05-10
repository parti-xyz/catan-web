/**
 *
 * @param {string} text
 * @param {string} separator
 * @return {string}
 */
const camelize = (text, separator = '-') => {
  let words = text.split(separator);
  let result = '';

  words.forEach((word, index) => {
    if (index === 0) {
      word = word.replace(/./, (letter) => letter.toLowerCase());
      result += word;
      return;
    }
    word = word.replace(/./, (letter) => letter.toUpperCase());
    result += word;
  });
  return result;
}

export { camelize }