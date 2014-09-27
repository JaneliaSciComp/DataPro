#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /WAVE WNoiseGetParamNames()
	Variable nParameters=5
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="delay"
	parameterNames[1]="duration"
	parameterNames[2]="amplitude"
	parameterNames[3]="fLow"
	parameterNames[4]="fHigh"	
	return parameterNames
End

Function /WAVE WNoiseGetParamDisplayNames()
	Variable nParameters=5
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="Delay"
	parameterNames[1]="Duration"
	parameterNames[2]="Amplitude"
	parameterNames[3]="Low Cutoff"
	parameterNames[4]="High Cutoff"	
	return parameterNames
End

Function /WAVE WNoiseGetDfltParams()
	Variable nParameters=5
	Make /FREE /N=(nParameters) parametersDefault
	parametersDefault[0]=10
	parametersDefault[1]=50
	parametersDefault[2]=1	
	parametersDefault[3]=0	
	parametersDefault[4]=10
	return parametersDefault
End

Function /WAVE WNoiseGetDfltParamsAsStrings()
	Variable nParameters=5
	Make /T /FREE /N=(nParameters) parametersDefault
	parametersDefault[0]="10"
	parametersDefault[1]="50"
	parametersDefault[2]="1"	
	parametersDefault[3]="0"	
	parametersDefault[4]="10"
	return parametersDefault
End

Function WNoiseFillFromParams(w,parameters)
	Wave w
	Wave parameters

	w = 0
	WNoiseOverlayFromParams(w,parameters)
End

Function WNoiseOverlayFromParams(w,parameters)
	Wave w
	Wave parameters

	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable amplitude=parameters[2]	// the SD of the filtered noise
	Variable fLow=parameters[3]
	Variable fHigh=parameters[4]
	
	//// Make a noise signal, with length longer than w and a power of 2
	Variable nDFT=2^ceil(ln(numpnts(w))/ln(2))	
	Variable nFreqDomain=round(nDFT/2)+1		// Igor doesn't cary neg freqs, and has one extra sample 
	
	// Generate the real and imag components separately, b/c Igor sucks
	// at complex numbers
	Variable dt=deltax(w)		// ms
	Variable df=1/(nDFT*dt)	// kHz
	// Real
	Make /FREE /N=(nFreqDomain) reNoiseInFreqDomain
	SetScale /P x, 0, df, "kHz", reNoiseInFreqDomain
	reNoiseInFreqDomain=gnoise(amplitude)*sqrt(nDFT/2)
	reNoiseInFreqDomain[0]=0		// no DC
	// Imag
	Make /FREE /N=(nFreqDomain) imNoiseInFreqDomain
	SetScale /P x, 0, df, "kHz", imNoiseInFreqDomain
	imNoiseInFreqDomain=gnoise(amplitude)*sqrt(nDFT/2)
	imNoiseInFreqDomain[0]=0		// no DC
	imNoiseInFreqDomain[nFreqDomain-1]=0	// need this
	
	// DEBUG CODE: To check, generate the noise in the time domain, take to freq domain
	// Should get same signal, modulo randomness (!)
	//Make /FREE /N=(nDFT) noise
	//CopyScales /P w, noise
	//noise=gnoise(amplitude)		// generate white noise
	//// Convert the noise to its frequency-domain representation
	//Make /FREE /N=(nDFT) noiseInFreqDomain
	//FFT /DEST=noiseInFreqDomain noise	 // x axis should be in units of kHz
	//reNoiseInFreqDomain=real(noiseInFreqDomain[p])
	//imNoiseInFreqDomain=imag(noiseInFreqDomain[p])
		
//	//// Out of curiousity, what is the the mean squared amplitude of those components?
//	Variable vr=Variance(reNoiseInFreqDomain)		// 0.5*nDFT*amplitude^2
//	Printf "%g\r", vr
//	Variable vi=Variance(imNoiseInFreqDomain)		// 0.5*nDFT*amplitude^2
//	Printf "%g\r", vi
	
	// Compute the scaling factor to give the specified amplitude
	Variable bandwidth=max(0,fHigh-fLow)
	//Variable dt=deltax(w)		// ms
	Variable nyquistFreq=0.5/dt		// kHz
	Variable bandwidthFraction=bandwidth/nyquistFreq
	Variable scaleFactor=max(1,1/sqrt(bandwidthFraction))   // never go below 1
	if ( !IsFinite(scaleFactor) )
		scaleFactor=1
	endif
	//scaleFactor=1
	
	// Make the filter signal
	Make /FREE /N=(nFreqDomain) filter
	SetScale /P x, 0, df, "kHz", filter
	//CopyScales /P noiseInFreqDomain, filter
	filter=scaleFactor*unitPulse(x-fLow,bandwidth)
	//filter=1

	// Filter the real and imag components
	Make /FREE /N=(nFreqDomain) reNoiseInFreqDomainFiltered
	SetScale /P x, 0, df, "kHz", reNoiseInFreqDomainFiltered
	reNoiseInFreqDomainFiltered=filter[p]*reNoiseInFreqDomain[p]
	Make /FREE /N=(nFreqDomain) imNoiseInFreqDomainFiltered
	SetScale /P x, 0, df, "kHz", imNoiseInFreqDomainFiltered
	//CopyScales /P noiseInFreqDomain, reNoiseInFreqDomainFiltered, imNoiseInFreqDomainFiltered
	imNoiseInFreqDomainFiltered=filter[p]*imNoiseInFreqDomain[p]	

	// Combine into a single complex signal
	Make /FREE /N=(nFreqDomain) /C noiseInFreqDomainFiltered
	//CopyScales /P noiseInFreqDomain, noiseInFreqDomainFiltered
	SetScale /P x, 0, df, "kHz", noiseInFreqDomainFiltered
	noiseInFreqDomainFiltered=cmplx(reNoiseInFreqDomainFiltered[p],imNoiseInFreqDomainFiltered[p])
	
	// Go back to time domain
	Make /FREE /N=(nDFT) filteredNoise
	CopyScales /P w, filteredNoise
	IFFT /DEST=filteredNoise noiseInFreqDomainFiltered
	
	// Window in time
	w += (filteredNoise[p])*unitPulse(x-delay,duration)
	
	//// Check the SD
	//Variable sd=sqrt(Variance(w,delay,delay+duration))		// 0.5*nDFT*amplitude^2
	//Printf "Final SD: %g\r", sd
End

Function /S WNoiseGetSignalType()
	return "DAC"
End

