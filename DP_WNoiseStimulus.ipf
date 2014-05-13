#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /WAVE WNoiseGetParamNames()
	Variable nParameters=6
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="delay"
	parameterNames[1]="duration"
	parameterNames[2]="mu"
	parameterNames[3]="sigma"
	parameterNames[4]="fLow"
	parameterNames[5]="fHigh"	
	return parameterNames
End

Function /WAVE WNoiseGetDefaultParams()
	Variable nParameters=6
	Make /FREE /N=(nParameters) parametersDefault
	parametersDefault[0]=10
	parametersDefault[1]=50
	parametersDefault[2]=0
	parametersDefault[3]=1	
	parametersDefault[4]=0	
	parametersDefault[5]=10
	return parametersDefault
End

Function WNoiseFillFromParams(w,parameters)
	Wave w
	Wave parameters

	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable mu=parameters[2]
	Variable sigma=parameters[3]
	Variable fLow=parameters[4]
	Variable fHigh=parameters[5]
	
	// Make a noise signal, with length longer than w and a power of 2
	Variable nDFT=2^ceil(ln(numpnts(w))/ln(2))
	Make /FREE /N=(nDFT) noise
	CopyScales /P w, noise
	noise=gnoise(sigma)		// generate white noise
	
	// Convert the noise to its frequency-domain representation
	Make /FREE /N=(nDFT) noiseInFreqDomain
	FFT /DEST=noiseInFreqDomain noise	 // x axis should be in units of kHz
	Variable nFreqDomain=numpnts(noiseInFreqDomain)   // nDFT/2+1, it seems
	
	// Split the f-domain noise into its real and imaginary components, b/c Igor sucks
	// at complex numbers
	Make /FREE /N=(nFreqDomain) reNoiseInFreqDomain
	Make /FREE /N=(nFreqDomain) imNoiseInFreqDomain
	CopyScales /P noiseInFreqDomain, reNoiseInFreqDomain, imNoiseInFreqDomain
	reNoiseInFreqDomain=real(noiseInFreqDomain[p])
	imNoiseInFreqDomain=imag(noiseInFreqDomain[p])
		
	//// Out of curiousity, what is the the mean squared amplitude of those components?
	//Variable vr=Variance(reNoiseInFreqDomain)		// 2*nDFT*sigma^2
	//Printf "%g\r", vr
	//Variable vi=Variance(imNoiseInFreqDomain)		// 2*nDFT*sigma^2
	//Printf "%g\r", vi
	
	// Compute the scaling factor to give the specified sigma
	Variable bandwidth=max(0,fHigh-fLow)
	Variable dt=deltax(w)		// ms
	Variable nyquistFreq=0.5/dt		// kHz
	Variable bandwidthFraction=bandwidth/nyquistFreq
	Variable scaleFactor=max(1,1/sqrt(bandwidthFraction))   // never go below 1
	if ( !IsFinite(scaleFactor) )
		scaleFactor=1
	endif
	
	// Make the filter signal
	Make /FREE /N=(nFreqDomain) filter
	CopyScales /P noiseInFreqDomain, filter
	filter=scaleFactor*unitPulse(x-fLow,bandwidth)

	// Filter the real and imag components
	Make /FREE /N=(nFreqDomain) reNoiseInFreqDomainFiltered
	Make /FREE /N=(nFreqDomain) imNoiseInFreqDomainFiltered
	CopyScales /P noiseInFreqDomain, reNoiseInFreqDomainFiltered, imNoiseInFreqDomainFiltered
	reNoiseInFreqDomainFiltered=filter[p]*reNoiseInFreqDomain[p]
	imNoiseInFreqDomainFiltered=filter[p]*imNoiseInFreqDomain[p]	

	// Combine into a single complex signal
	Make /FREE /N=(nFreqDomain) /C noiseInFreqDomainFiltered
	CopyScales /P noiseInFreqDomain, noiseInFreqDomainFiltered
	noiseInFreqDomainFiltered=cmplx(reNoiseInFreqDomainFiltered[p],imNoiseInFreqDomainFiltered[p])
	
	// Go back to time domain
	Make /FREE /N=(nDFT) filteredNoise
	CopyScales /P w, filteredNoise
	IFFT /DEST=filteredNoise noiseInFreqDomainFiltered
	
	// Window in time
	w=(mu+filteredNoise[p])*unitPulse(x-delay,duration)
End

Function /S WNoiseGetSignalType()
	return "DAC"
End

