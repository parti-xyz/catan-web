const { environment } = require('@rails/webpacker')
const webpack = require('webpack')
const { CleanWebpackPlugin } = require('clean-webpack-plugin')

const pathsToClean = [
  'packs',
  'packs-test'
]
const cleanOptions = {
  verbose: true,
}
environment.plugins.append('CleanWebpackPlugin', new CleanWebpackPlugin(cleanOptions))

environment.plugins.append('Provide', new webpack.ProvidePlugin({
  $: 'jquery',
  jQuery: 'jquery',
  jquery: 'jquery',
  'window.jQuery': 'jquery',
  "window.$": "jquery",
  Popper: ['popper.js', 'default'],
}))

const sassLoader = environment.loaders.get('sass')
const sassLoaderConfig = sassLoader.use.find(function (element) {
  return element.loader == 'sass-loader'
})

// Use Dart-implementation of Sass (default is node-sass)
const options = sassLoaderConfig.options
options.implementation = require('sass')

module.exports = environment
