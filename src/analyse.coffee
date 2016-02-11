con = console

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
    @loadAudio 'music/usee.mp3'
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
    @audio.crossOrigin = "anonymous";
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
