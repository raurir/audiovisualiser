
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

window.FFT = FFT;