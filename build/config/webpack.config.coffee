fs   = require 'fs'
path = require 'path'
yaml = require 'js-yaml'


# Load and parse the build configuration.
config = yaml.safeLoad fs.readFileSync __dirname + '/build.yaml'


# Export our Webpack configuration.
module.exports =


  # The base directory for resolving the entry option.
  context: "#{__dirname}/../../#{config.path.src.coffee}"


  # The entry point for the bundle.
  entry: "./#{config.app.entry}"


  # Various output options, to give us a single bundle.js file with everything
  # resolved and concatenated.
  # @see https://webpack.github.io/docs/configuration.html#output
  output:
    pathinfo: true
    sourceMapFilename: 'maps/[file].map'


  # Where to resolve our loaders.
  resolveLoader:
    modulesDirectories: ['node_modules']


  # Options which affect the resolution of modules.
  # @see https://webpack.github.io/docs/configuration.html#resolve
  resolve:

    # Directories that contain our modules
    root: [
      "#{__dirname}/../../#{config.path.src.coffee}"
      "#{__dirname}/../../#{config.path.src.sass}"
      "#{__dirname}/../../#{config.path.src.templates}"
      "#{__dirname}/../../#{config.path.assets}"
    ]

    # Extensions used to resolve modules.
    extensions: ['', '.coffee', '.jade']

    # Replace modules with other modules or paths (like the 'paths' option
    # with Require.js). This is for modules where we explicitly control the
    # location, as opposed to node_modules based modules.
    # @see https://webpack.github.io/docs/configuration.html#resolve-alias
    alias:
      some_lib: path.join(__dirname, "some/location")


  # Source map option.
  # @see https://webpack.github.io/docs/configuration.html#devtool
  devtool: 'source-map'


  # Our configured loaders.
  module:
    loaders: [
      {test: /\.coffee$/, loader: 'coffee-loader' }
      {test: /\.jade$/, loader: 'jade-loader' }
      {test: /\.(jpe?g|png|gif|svg)$/i
      loaders: [
        'file?hash=sha512&digest=hex&name=[hash].[ext]'
        'image-webpack?bypassOnDebug&optimizationLevel=7&interlaced=false'
      ]}
    ]


  # Include mocks for when node.js specific modules may be required
  node:
    fs: 'empty',
    net: 'empty',
    tls: 'empty'

