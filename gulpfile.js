/* # gulpfile.js
 *
 * This is a token gulpfile which enables CoffeeScript and loads the
 * real gulpfile located at `build/gulpfile.coffee`, which is written in
 * CoffeeScript.
 *
 */
require('coffee-script/register');
require('./build/gulpfile.coffee');
