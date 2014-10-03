#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /WAVE FroNoiseGetParamNames()
	Variable nParameters=6
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="delay"
	parameterNames[1]="duration"
	parameterNames[2]="amplitude"
	parameterNames[3]="fLow"
	parameterNames[4]="fHigh"
	parameterNames[5]="seed"	
	return parameterNames
End

Function /WAVE FroNoiseGetParamDispNames()
	Variable nParameters=6
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="Delay"
	parameterNames[1]="Duration"
	parameterNames[2]="Amplitude"
	parameterNames[3]="Low Cutoff"
	parameterNames[4]="High Cutoff"
	parameterNames[5]="Seed"	
	return parameterNames
End

//Function /WAVE FroNoiseGetDfltParams()
//	Variable nParameters=6
//	Make /FREE /N=(nParameters) parametersDefault
//	parametersDefault[0]=10
//	parametersDefault[1]=50
//	parametersDefault[2]=1	
//	parametersDefault[3]=0	
//	parametersDefault[4]=10
//	parametersDefault[5]=0.5
//	return parametersDefault
//End

Function /WAVE FroNoiseGetDfltParamsAsStr()
	Variable nParameters=6
	Make /T /FREE /N=(nParameters) parametersDefault
	parametersDefault[0]="10"
	parametersDefault[1]="50"
	parametersDefault[2]="1"	
	parametersDefault[3]="0"	
	parametersDefault[4]="10"
	parametersDefault[5]="0.5"
	return parametersDefault
End

Function FroNoiseAreParamsValid(parameters)
	Wave parameters

	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable amplitude=parameters[2]	// the abs(amplitude)==SD of the filtered noise
	Variable fLow=parameters[3]
	Variable fHigh=parameters[4]
	Variable seed=parameters[5]

	Variable isSeedValid=(1e-9<=seed)&&(seed<=1)		// 1073741824==2^30
		// Seems like seed gets multiplied by 2^30 [sic], truncated, and that that number is used as the seed.
		// So the resulting seed must be 1<=seed<=2^30.  Not sure why 2^30, or why zero isn't a valid seed.
		// But: passing a too-small number to SetRandomSeed doesn't yield an error, it just fails to
		// give you a deterministic sequence (Igor!).  So you want to be damn sure a too-low value doesn't get used.
		// 1/2^30<1e-9, and so this gives us some margin for error.
	return isSeedValid && (duration>=0) && (fLow>=0) && (fHigh>0) && (fLow<fHigh)
End

Function /WAVE FroNoiseGetParamUnits()
	Variable nParameters=6
	Make /T /FREE /N=(nParameters) paramUnits
	paramUnits[0]="ms"
	paramUnits[1]="ms"
	paramUnits[2]=""
	paramUnits[3]="kHz"
	paramUnits[4]="kHz"
	paramUnits[5]=""
	return paramUnits
End

//Function FroNoiseFillFromParams(w,parameters)
//	Wave w
//	Wave parameters
//
//	w = 0
//	FroNoiseOverlayFromParams(w,parameters)
//End

Function FroNoiseOverlayFromParams(w,parameters)
	Wave w
	Wave parameters

	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable amplitude=parameters[2]	// the SD of the filtered noise
	Variable fLow=parameters[3]
	Variable fHigh=parameters[4]
	Variable seed=parameters[5]
	
	//// Make a noise signal, with length longer than w and a power of 2
	Variable nDFT=2^ceil(ln(numpnts(w))/ln(2))	
	Variable nFreqDomain=round(nDFT/2)+1		// Igor doesn't cary neg freqs, and has one extra sample 
	
	// Generate the real and imag components separately, b/c Igor sucks
	// at complex numbers
	Variable dt=deltax(w)		// ms
	Variable df=1/(nDFT*dt)	// kHz
	// Set the random seed to make the numbers reproducible
	SetRandomSeed /BETR seed
	// Real
	Make /FREE /N=(nFreqDomain) reNoiseInFreqDomain
	SetScale /P x, 0, df, "kHz", reNoiseInFreqDomain
	reNoiseInFreqDomain=gnoise(1,2)*sqrt(nDFT/2)		// ,2 makes it use Mersenne twister
	reNoiseInFreqDomain[0]=0		// no DC
	// Imag
	Make /FREE /N=(nFreqDomain) imNoiseInFreqDomain
	SetScale /P x, 0, df, "kHz", imNoiseInFreqDomain
	imNoiseInFreqDomain=gnoise(1,2)*sqrt(nDFT/2)		// ,2 makes it use Mersenne twister
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
	w += amplitude * (filteredNoise[p]) * unitPulse(x-delay,duration)
	
//	// Check the SD
//	Variable sd=sqrt(Variance(w,delay,delay+duration))		// 0.5*nDFT*amplitude^2
//	Printf "Final SD: %g\r", sd
End

Function /S FroNoiseGetSignalType()
	return "DAC"
End

