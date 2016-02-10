class Alien
  grid: null
  cellSize: 30
  numberOfRows: 10
  numberOfColumns: 10
  halfColumns: 0

  colReflected: 0
  ticks: 0

  canvas: null
  drawingContext: null

  canvasWidth: 0
  canvasHeight: 0


  constructor: () ->
    @halfColumns = @numberOfColumns / 2

    @canvasWidth = @cellSize * (@numberOfColumns + 2)
    @canvasHeight = @cellSize * (@numberOfRows + 2)

    @canvas = document.createElement 'canvas'
    @drawingContext = @canvas.getContext '2d'

    @canvas.height = @canvasWidth
    @canvas.width = @canvasHeight

    @canvas.aliens = { x: 0, y: 0 }

    # console.log "canvas:::", @canvas

  clearCanvas: ->
    @drawingContext.clearRect 0, 0, @canvasWidth, @canvasHeight
     # @drawingContext.fillStyle = "red"
     # @drawingContext.fillRect 0,0, @canvasWidth, @canvasHeight

  seed: ->
    @grid = []
    for row in [0...@numberOfRows]
      @grid[row] = []
      for column in [0...@halfColumns]
        seedCell = @createSeedCell column
        @grid[row][column] = seedCell

  createSeedCell: (probability) ->
    chance = Math.random()
    cutoff = (probability + 1) / (@halfColumns + 1)
    tobe = chance < cutoff
    # console.log chance, cutoff, tobe
    tobe



  drawGrid: (pixels) ->

    @canvas.aliens = a()

    r = ~~(Math.random() * 128 + 64)
    g = ~~(Math.random() * 128 + 64)
    b = ~~(Math.random() * 128 + 64)
    colourLine = "rgba(#{r}, #{g}, #{b}, 1)"

    r1 = ~~(r - Math.random() * 64)
    g1 = ~~(g - Math.random() * 64)
    b1 = ~~(b - Math.random() * 64)
    colourFill = "rgb(#{r1}, #{g1}, #{b1})"

    for row in [0...@numberOfRows]
      for column in [0...@numberOfColumns]
        @drawCell row, column, colourLine, 10
    for row in [0...@numberOfRows]
      for column in [0...@numberOfColumns]
        @drawCell row, column, colourFill, 0

  drawCell: (y, x, fillStyle, strokeWidth) ->

    if x >= @halfColumns
      colReflected = @numberOfColumns - x - 1
    else
      colReflected = x

    isOn = @grid[y][colReflected]

    if isOn
      @drawingContext.fillStyle = fillStyle
      @drawingContext.fillRect (1+x) * @cellSize - strokeWidth,
        (1+y) * @cellSize - strokeWidth,
        @cellSize + strokeWidth * 2,
        @cellSize + strokeWidth * 2

  getAlien: =>
    # console.log "getAlien", @canvas
    @canvas

  step: =>

    # if @ticks % 40 == 0
    #   @change()
    # @ticks++

  change: ->
    @clearCanvas()
    @seed()
    @drawGrid()



window.Alien = Alien

`
function a() {
  function r( m ) { return ~~(Math.random() * m + 1)};
  function q() {
    var l = r(11), g = r(5), a = [], i = 0;
    while ( i < l ) {
      j = i * g;
      a.push( j );
      if ( i ) a.unshift(-j)
      i++;
    }
    return a;
  }
  return { x: q(), y: q() };
}
`