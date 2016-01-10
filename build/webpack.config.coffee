fs   = require 'fs'
path = require 'path'
yaml = require 'js-yaml'

# Load and parse the build configuration.
config = yaml.safeLoad fs.readFileSync 'config/build.yaml'

module.exports =

  # The base directory for resolving the entry option
  context: __dirname + '/../' + config.path.src

  # The entry point for the bundle
  entry: "./bootstrap.coffee"

  # Various output options, to give us a single bundle.js file with everything resolved and concatenated
  output:
    path: __dirname + '/app/webpack'
    filename: config.app.main
    publicPath: '/app/webpack/'
    pathinfo: true

  # Where to resolve our loaders
  resolveLoader:
    modulesDirectories: ['node_modules']

  resolve:
    # Directories that contain our modules
    root: [path.join(__dirname, "./app/coffeescript"), path.join(__dirname, "./app/templates")]

    # Extensions used to resolve modules
    extensions: ['', '.js', '.csx', '.csx.coffee', '.coffee']

    # Replace modules with other modules or paths (like the 'paths' option with Require.js).   This is for modules where we explicitly control the location, as opposed to node_modules based modules.
    alias:
      some_lib: path.join(__dirname, "some/location")


  # Source map option. Eval provides a little less info, but is faster
  devtool: 'source-map'

  # Our loader configuration
  module:
    loaders: [
      {test: /\.coffee$/, loader: 'coffee-loader' }
    ]

  # Include mocks for when node.js specific modules may be required
  node:
    fs: 'empty',
    net: 'empty',
    tls: 'empty'

