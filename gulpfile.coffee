con = console

gulp = require("gulp")
coffee = require("gulp-coffee")
gutil = require("gulp-util")
debug = require("gulp-debug")
watch = require("gulp-watch")

# con.log(gulp)

compile = (watchFiles = false) ->
  compileCoffee(watchFiles)

# watch = (param) ->
#   con.log("watch")
#   compile(true)

compileCoffee = (watchFiles) ->
  #  return gulp.src('src/*.jade')
  #    .pipe(jade({
  #      pretty: true
  #    }))
  #    .pipe(gulp.dest('/));

  stream = gulp.src("./src/*.coffee")
    # .pipe(sourcemaps.init())
  if watchFiles
    stream = stream.pipe(watch("./src/*.coffee"))
  stream.pipe(coffee({bare: true}).on("error", gutil.log))
    .pipe(debug({title:"Compiling Coffee:"}))
    # .pipe(sourcemaps.write("./source-maps/"))
    .pipe(gulp.dest("./deploy/"))

gulp.task('compileCoffee', compileCoffee)

gulp.task('build', compile)
# gulp.task('watch', watch)

gulp.task('default', ['watch'])