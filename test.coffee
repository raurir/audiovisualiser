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


  generateAlien: () ->
    r = (m) => ~~(Math.random() * m + 1)
    q = () =>
      l = r(11)
      g = r(5)
      a = []
      i = 0
      while i < l
        j = i * g
        a.push( j )
        a.unshift(-j) if i
        i++
      a
    {
      x: q()
      y: q()
    }

  drawGrid: (pixels) ->

    @canvas.aliens = @generateAlien()

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



window.Alien = Aliencon = console

class Analyse

  waves: null
  node: null
  analyser: null
  audio: null

  frameBufferSize: Math.pow 2, 11
  channels: 4
  bufferSize: 0
  signal: null
  fft: null
  amplitude: 0
  spectrum : []

  constructor: () ->
    @bufferSize = @frameBufferSize / @channels
    @signal = new Float32Array(@bufferSize)
    @fft = new FFT(@bufferSize, 44100)
    @newAudioContext()
    # @loadAudio 'music/usee.mp3'
    @loadAudio 'https://dl.dropboxusercontent.com/u/729503/Codepen/usee.mp3'
    con.log "Analyse constructor", @signal.length

  newAudioContext: ->
    fok = (f) =>
      window[f]? # and typeof window[f] is 'function' # not a function in safari!
    @waves = false
    if fok('AudioContext')
      con.log("AudioContext")
      @waves = new AudioContext()
    else if (fok('webkitAudioContext'))
      con.log("webkitAudioContext")
      @waves = new webkitAudioContext()
    con.log "waves", @waves


  loadAudio: (url) ->
    con.log "loadAudio", url, @waves
    if @audio
      @audio.remove()
    if @node
      @node.disconnect()
    @audio = new Audio()
    @audio.crossOrigin = "anonymous"
    @audio.preload = 'auto'
    # @audio.loop = true
    @audio.controls = true

    document.body.appendChild @audio

    if @waves
      con.log("waves created")
      @audio.addEventListener( 'canplay', ( e ) => @setupAudioNodes(e) )
    else
      # @audio.addEventListener('canplay', tryMoz, false)
    @audio.src = url

    # waves.playbackRate = 1000

  setupAudioNodes: (e) ->

    con.log "setupAudioNodes"

    unless @analyser?
      @analyser = @analyser || @waves.createScriptProcessor( @bufferSize, 2, 2 )
      @analyser.onaudioprocess = @processAudio

      @node = @waves.createMediaElementSource( @audio )
      @node.connect(@analyser)

      # gainNode = @node.context.createGain()
      # @node.connect( gainNode )
      # gainNode.connect( @analyser )
      # gainNode.gain.value = 0

      # filter = @node.context.createBiquadFilter()
      # @node.connect( filter )
      # filter.connect( @analyser );
      # filter.type = 0 # // Low-pass filter. See BiquadFilterNode docs
      # filter.frequency.value = 440 # Set cutoff to 440 HZ
      # window.addEventListener( 'mousemove', ( e ) =>
      #   filter.frequency.value = e.clientX * 2
      #   filter.Q.value = e.clientY / 10
      # )

      @analyser.connect(@waves.destination)

    @audio.play()

    # con.log "node", @node
    # con.log "analyser", @analyser

  processAudio: (e) =>

    # con.log "processAudio"

    inputArrayL = e.inputBuffer.getChannelData(0)
    inputArrayR = e.inputBuffer.getChannelData(1)
    outputArrayL = e.outputBuffer.getChannelData(0)
    outputArrayR = e.outputBuffer.getChannelData(1)
    # n = bufferSize
    for i in [0...@bufferSize]
      outputArrayL[i] = inputArrayL[i]
      outputArrayR[i] = inputArrayR[i]
      @signal[i] = (inputArrayL[i] + inputArrayR[i]) / 2

    @fft.forward(@signal)
    @fftChanged()

  fftChanged: ->

    specLength = @fft.spectrum.length
    magSum = 0
    for i in [0...specLength]
      magSum += @fft.spectrum[i]
    @amplitude = 100 * magSum / specLength



  step: =>

    specLength = @fft.spectrum.length # should be @signal.length / 2
    totalBands = specLength / 32

    @spectrum = []

    currentBand = -1
    for i in [0...specLength]
      if i % totalBands == 0
        bandTotal = 0
        currentBand++
      bandTotal += @fft.spectrum[i]
      if i % totalBands == totalBands - 1
        @spectrum[currentBand] = bandTotal

  getAnalysis: ->
    {
      spectrum: @spectrum,
      amplitude: @amplitude,
      waveform: @signal
    }

window.Analyse = Analyse
//------------------------------------------//
//-------- STUFF FOR AUDIO ANALYSIS --------//

function FourierTransform(bufferSize, sampleRate)
{
	this.bufferSize = bufferSize;
	this.sampleRate = sampleRate;
	this.bandwidth  = bufferSize * sampleRate;
	this.spectrum   = new Float32Array(bufferSize/2);
	this.real       = new Float32Array(bufferSize);
	this.imag       = new Float32Array(bufferSize);
	this.peakBand   = 0;
	this.peak       = 0;
	this.getBandFrequency = function(index)
	{
		return this.bandwidth * index + this.bandwidth / 2;
	};
	this.calculateSpectrum = function()
	{
		var spectrum  = this.spectrum,
		real      = this.real,
		imag      = this.imag,
		bSi       = 2 / this.bufferSize,
		rval, ival, mag;
		this.peak = this.peakBand = 0;
		for (var i = 0, N = bufferSize*0.5; i < N; i++)
		{
			rval = real[i];
			ival = imag[i];
			mag = bSi * Math.sqrt(rval * rval + ival * ival);
			if (mag > this.peak)
			{
				this.peakBand = i;
				this.peak = mag;
			}
			spectrum[i] = mag;
		}
	};
}
function FFT(bufferSize, sampleRate)
{
	FourierTransform.call(this, bufferSize, sampleRate);
	this.reverseTable = new Uint32Array(bufferSize);
	var limit = 1;
	var bit = bufferSize >> 1;
	var i;
	while (limit < bufferSize)
	{
		for (i = 0; i < limit; i++)
		this.reverseTable[i + limit] = this.reverseTable[i] + bit;
		limit = limit << 1;
		bit = bit >> 1;
	}
	this.sinTable = new Float32Array(bufferSize);
	this.cosTable = new Float32Array(bufferSize);
	for (i = 0; i < bufferSize; i++)
	{
		this.sinTable[i] = Math.sin(-Math.PI/i);
		this.cosTable[i] = Math.cos(-Math.PI/i);
	}
}
FFT.prototype.forward = function(buffer)
{
  var bufferSize      = this.bufferSize,
      cosTable        = this.cosTable,
      sinTable        = this.sinTable,
      reverseTable    = this.reverseTable,
      real            = this.real,
      imag            = this.imag,
      spectrum        = this.spectrum;
	var k = Math.floor(Math.log(bufferSize) / Math.LN2);
	if (Math.pow(2, k) !== bufferSize) { throw "Invalid buffer size, must be a power of 2."; }
	if (bufferSize !== buffer.length)  { throw "Supplied buffer is not the same size as defined FFT. FFT Size: " + bufferSize + " Buffer Size: " + buffer.length; }
	var halfSize = 1,
		phaseShiftStepReal,
		phaseShiftStepImag,
		currentPhaseShiftReal,
		currentPhaseShiftImag,
		off,
		tr,
		ti,
		tmpReal,
		i;
	for (i = 0; i < bufferSize; i++)
	{
		real[i] = buffer[reverseTable[i]];
		imag[i] = 0;
	}
	while (halfSize < bufferSize)
	{
		phaseShiftStepReal = cosTable[halfSize];
		phaseShiftStepImag = sinTable[halfSize];
		currentPhaseShiftReal = 1;
		currentPhaseShiftImag = 0;
		for (var fftStep = 0; fftStep < halfSize; fftStep++)
		{
			i = fftStep;
			while (i < bufferSize)
			{
				off = i + halfSize;
				tr = (currentPhaseShiftReal * real[off]) - (currentPhaseShiftImag * imag[off]);
				ti = (currentPhaseShiftReal * imag[off]) + (currentPhaseShiftImag * real[off]);
				real[off] = real[i] - tr;
				imag[off] = imag[i] - ti;
				real[i] += tr;
				imag[i] += ti;
				i += halfSize << 1;
			}
			tmpReal = currentPhaseShiftReal;
			currentPhaseShiftReal = (tmpReal * phaseShiftStepReal) - (currentPhaseShiftImag * phaseShiftStepImag);
			currentPhaseShiftImag = (tmpReal * phaseShiftStepImag) + (currentPhaseShiftImag * phaseShiftStepReal);
		}
		halfSize = halfSize << 1;
	}
	return this.calculateSpectrum();
};

window.FFT = FFT;con = console

class Music

  analyser: null
  aliendude: null

  canvas: null
  pixels: null

  canvasWidth: 1000
  canvasHeight: 500
  centreX: 0
  centreY: 0

  scale: 1
  float: 20


  constructor: ->
    con.log "Music constructor"

    @createCanvas()

    @analyser = new Analyse( @pixels, @centreX, @centreY )
    @aliendude = new Alien( )

    if window.requestAnimationFrame
      con.log "native requestAnimationFrame"
    else
      con.log "creating requestAnimationFrame"
      window.requestAnimationFrame = window.webkitRequestAnimationFrame or window.mozRequestAnimationFrame or window.oRequestAnimationFrame or window.msRequestAnimationFrame
      # function(callback, element){
      #  window.setTimeout(callback, 1000 / 60);
      # };

    @step()

  createCanvas: ->
    @centreX = @canvasWidth / 2
    @centreY = @canvasHeight / 2

    @canvas = document.createElement 'canvas'
    document.body.appendChild @canvas
    @pixels = @canvas.getContext '2d'

    @canvas.width = @canvasWidth
    @canvas.height = @canvasHeight

  clearCanvas: ->
    #pixels.globalCompositeOperation = 'source-atop'
    @pixels.fillStyle = "rgb(0, 0, 0)"
    #@pixels.fillStyle = "rgba(0, 0, 0, 0.4)"
    @pixels.fillRect 0, 0, @canvasWidth, @canvasHeight
    #@pixels.globalCompositeOperation = 'lighter'
  alienScale: 2
  alienRotate: 0.01

  step: =>

    @clearCanvas()

    @analyser.step()
    @aliendude.step()


    anal = @analyser.getAnalysis()

    spectrum = anal.spectrum
    amplitude = anal.amplitude
    waveform = anal.waveform


    # draw amplitude
    @pixels.fillStyle = "rgb(0, 20, 40)"
    @pixels.fillRect( 0, @canvasHeight, @canvasWidth, -amplitude * @canvasHeight)



    # draw spectrum
    specLength = spectrum.length
    bandWidth = @canvasWidth / specLength
    padding = 5
    for i in [0...specLength]
      c = ~~(i / specLength * 55)
      r = 100
      g = 200 + c
      b = 255 - c
      level = spectrum[i]
      @pixels.fillStyle = "rgba(#{r}, #{g}, #{b}, 0.5)"
      @pixels.fillRect( i * bandWidth + padding, @canvasHeight, bandWidth - padding * 2, -level * @centreY)


    # draw waveform
    waveformLength = waveform.length
    bandWidth = @canvasWidth / waveformLength

    @pixels.beginPath();

    for i in [0...waveformLength]

      #@pixels.fillStyle = "rgba(255, 255, 255, 0.5)"
      #@pixels.fillRect( i * bandWidth, @centreY, bandWidth, waveform[i] * @centreY)

      @pixels.strokeStyle = '#0fe';
      @pixels.lineWidth = 1;
      x = i * bandWidth
      y = @centreY + waveform[i] * @centreY
      if i == 0
        @pixels.moveTo( x, y )
      else
        @pixels.lineTo( x,y )

    @pixels.stroke();


    # draw alien

    @float += @alienRotate
    #@scale += 0.01
    @scale = spectrum[0]

    if @scale > @alienScale * 4
      @aliendude.change()
      @alienScale = @scale
      @alienRotate = (Math.random() - 0.5) * 0.1
    else
      @alienScale *= 0.9

    sc = @alienScale * 1 #+ (Math.sin @scale) * 0.5
    #sc = (Math.sin @scale) * 0.5


    img = @aliendude.getAlien()

    @pixels.save()

    @pixels.translate( @centreX, @centreY )
    @pixels.rotate( @float )
    @pixels.scale( sc, sc )
    @pixels.translate( -img.width / 2, -img.height / 2 )


    # i think this pattern method 'leaks' like a motherfuck
    # pat = @pixels.createPattern(img,"repeat");
    # @pixels.rect(0,0, @canvasWidth, @canvasHeight )
    # @pixels.fillStyle = pat
    # @pixels.fill()

    for x in img.aliens.x
      for y in img.aliens.y
        @pixels.drawImage( img, img.width * x, img.height * y)

    @pixels.restore()


    # attempt at 3d, but shearing of only 2 triangle subdivisions and this will get costly really fast.
    # corners = [
    #   {x:100,y:100,u:0,v:0},
    #   {x:300,y:50,u:img.width,v:0},
    #   {x:350,y:300,u:img.width,v:img.height},
    #   {x:200,y:400,u:0,v:img.height}
    # ]

    # for c in corners
    #   @pixels.fillStyle = "#f00"
    #   @pixels.fillRect( c.x, c.y, 5, 5 )

    # textureMap( @pixels, img, corners )


    requestAnimationFrame @step


window.Music = Music
new Music()
