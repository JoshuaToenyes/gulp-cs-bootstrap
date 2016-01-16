module.exports = (config) ->

  config.set
    browsers: ['Chrome', 'Safari', 'PhantomJS', 'Firefox']
    frameworks: ['mocha']
    reporters: ['mocha']
    files: [
      'dist/*.js'
    ]