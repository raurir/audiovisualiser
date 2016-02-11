con = console

gulp = require("gulp")
coffee = require("gulp-coffee")
gutil = require("gulp-util")
debug = require("gulp-debug")
watch = require("gulp-watch")
browserify = require("browserify")
buffer = require("vinyl-buffer")
source = require("vinyl-source-stream")



compile = () ->
  con.log("compile")
  compileCoffee(true)

compileCoffee = (watchFiles) ->

  bundler = browserify([
    './deploy/fft.js'
    './deploy/alien.js'
    './deploy/analyse.js'
    './deploy/music.js'
  ])

  # con.log("compileCoffee", watchFiles)
  stream = gulp.src("./src/*.coffee")
    .on("end", () => rebundle())

  # con.log('stream', stream)
  if watchFiles
    stream = stream.pipe(watch("./src/*.coffee"))
  stream
    .pipe(coffee({bare: true})
    .on("error", gutil.log))
    .pipe(debug({title: "Compiling Coffee:"}))
    .pipe(gulp.dest("./deploy/"))



  rebundle = () =>
    con.log("rebundle")
    bundler.bundle()
    .on('error', (err) =>
      con.error(err)
      @emit('end')
    )
    .pipe(source('./deploy/app.js'))
    .pipe(buffer())
    # .pipe(uglify())
    .pipe(gulp.dest("./"))

  if watchFiles
    bundler.on('update', () =>
      con.log('-> bundling...')
      rebundle()
    )
  # rebundle()







gulp.task('build', compile)
# gulp.task('watch', watch)
# gulp.task('default', ['watch'])