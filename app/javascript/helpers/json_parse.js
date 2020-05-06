const parseJSON = (text, reviver) => {
  try {
    return {
      value: JSON.parse(text, reviver)
    }
  } catch (ex) {
    return {
      error: ex
    }
  }
}

export default parseJSON
