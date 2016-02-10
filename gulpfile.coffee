con = console

gulp = require("gulp")
coffee = require("gulp-coffee")
gutil = require("gulp-util")
debug = require("gulp-debug")
watch = require("gulp-watch")

compile = () ->
  con.log("compile")
  compileCoffee(true)

# watch = () ->
#   con.log("watch")
#   compileCoffee(true)

compileCoffee = (watchFiles) ->
  con.log("compileCoffee", watchFiles)
  stream = gulp.src("./src/*.coffee")
  if watchFiles
    stream = stream.pipe(watch("./src/*.coffee"))
  stream
    .pipe(coffee({bare: true})
    .on("error", gutil.log))
    .pipe(debug({title:"Compiling Coffee:"}))
    .pipe(gulp.dest("./deploy/"))

gulp.task('build', compile)
# gulp.task('watch', watch)
# gulp.task('default', ['watch'])