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
    console.log "Music constructor"

    @createCanvas()

    @analyser = new Analyse( @pixels, @centreX, @centreY )
    @aliendude = new Alien( )

    if window.requestAnimationFrame
      console.log "native requestAnimationFrame"
    else
      console.log "creating requestAnimationFrame"
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




`
// isometric
//http://stackoverflow.com/questions/5186013/can-you-do-an-isometric-perspective-with-html5-canvas/5186153#5186153


// http://stackoverflow.com/questions/4774172/image-manipulation-and-texture-mapping-using-html5-canvas
function textureMap(ctx, texture, pts) {
    var tris = [[0, 1, 2], [2, 3, 0]]; // Split in two triangles
    for (var t=0; t<2; t++) {
        var pp = tris[t];
        var x0 = pts[pp[0]].x, x1 = pts[pp[1]].x, x2 = pts[pp[2]].x;
        var y0 = pts[pp[0]].y, y1 = pts[pp[1]].y, y2 = pts[pp[2]].y;
        var u0 = pts[pp[0]].u, u1 = pts[pp[1]].u, u2 = pts[pp[2]].u;
        var v0 = pts[pp[0]].v, v1 = pts[pp[1]].v, v2 = pts[pp[2]].v;

        // Set clipping area so that only pixels inside the triangle will
        // be affected by the image drawing operation
        ctx.save(); ctx.beginPath(); ctx.moveTo(x0, y0); ctx.lineTo(x1, y1);
        ctx.lineTo(x2, y2); ctx.closePath(); ctx.clip();

        // Compute matrix transform
        var delta = u0*v1 + v0*u2 + u1*v2 - v1*u2 - v0*u1 - u0*v2;
        var delta_a = x0*v1 + v0*x2 + x1*v2 - v1*x2 - v0*x1 - x0*v2;
        var delta_b = u0*x1 + x0*u2 + u1*x2 - x1*u2 - x0*u1 - u0*x2;
        var delta_c = u0*v1*x2 + v0*x1*u2 + x0*u1*v2 - x0*v1*u2
                      - v0*u1*x2 - u0*x1*v2;
        var delta_d = y0*v1 + v0*y2 + y1*v2 - v1*y2 - v0*y1 - y0*v2;
        var delta_e = u0*y1 + y0*u2 + u1*y2 - y1*u2 - y0*u1 - u0*y2;
        var delta_f = u0*v1*y2 + v0*y1*u2 + y0*u1*v2 - y0*v1*u2
                      - v0*u1*y2 - u0*y1*v2;

        // Draw the transformed image
        ctx.transform(delta_a/delta, delta_d/delta,
                      delta_b/delta, delta_e/delta,
                      delta_c/delta, delta_f/delta);
        ctx.drawImage(texture, 0, 0);
        ctx.restore();
    }
}
`
