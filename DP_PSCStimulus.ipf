#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /WAVE PSCGetParamNames()
	Variable nParameters=7
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="delay"
	parameterNames[1]="duration"
	parameterNames[2]="amplitude"
	parameterNames[3]="tauRise"
	parameterNames[4]="tauDecay1"
	parameterNames[5]="tauDecay2"
	parameterNames[6]="weightDecay2"
	return parameterNames
End

Function /WAVE PSCGetParamDispNames()
	Variable nParameters=7
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="Delay"
	parameterNames[1]="Duration"
	parameterNames[2]="Amplitude"
	parameterNames[3]="Rise Tau"
	parameterNames[4]="Decay Tau 1"
	parameterNames[5]="Decay Tau 2"
	parameterNames[6]="Weight of Decay 2"
	return parameterNames
End

//Function /WAVE PSCGetDfltParams()
//	Variable nParameters=7
//	Make /FREE /N=(nParameters) parametersDefault
//	parametersDefault[0]=10
//	parametersDefault[1]=100
//	parametersDefault[2]=1
//	parametersDefault[3]=0.2
//	parametersDefault[4]=2
//	parametersDefault[5]=10
//	parametersDefault[6]=0.5
//	return parametersDefault
//End

Function /WAVE PSCGetDfltParamsAsStr()
	Variable nParameters=7
	Make /T /FREE /N=(nParameters) parametersDefault
	parametersDefault[0]="10"
	parametersDefault[1]="100"
	parametersDefault[2]="1"
	parametersDefault[3]="0.2"
	parametersDefault[4]="2"
	parametersDefault[5]="10"
	parametersDefault[6]="0.5"
	return parametersDefault
End

Function PSCAreParamsValid(paramsAsStrings)
	Wave /T paramsAsStrings

	Wave parameters=DoubleWaveFromTextWave(paramsAsStrings)
	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable amplitude=parameters[2]
	Variable tauRise=parameters[3]		
	Variable tauDecay1=parameters[4]		
	Variable tauDecay2=parameters[5]		
	Variable weightDecay2=parameters[6]		

	return (duration>=0) && (tauRise>0) && (tauDecay1>0) && (tauDecay2>0) && (0<=weightDecay2) && (weightDecay2<=1) && (tauRise<tauDecay1) && (tauRise<tauDecay2)
End

Function /WAVE PSCGetParamUnits()
	Variable nParameters=7
	Make /T /FREE /N=(nParameters) paramUnits
	paramUnits[0]="ms"
	paramUnits[1]="ms"
	paramUnits[2]=""
	paramUnits[3]="ms"
	paramUnits[4]="ms"
	paramUnits[5]="ms"
	paramUnits[6]=""
	return paramUnits
End

//Function PSCFillFromParams(w,parameters)
//	Wave w
//	Wave parameters
//
//	w=0
//	PSCOverlayFromParams(w,parameters)	
//End
//
Function PSCOverlayFromParams(w,paramsAsStrings)
	Wave w
	Wave /T paramsAsStrings

	Wave parameters=DoubleWaveFromTextWave(paramsAsStrings)

	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable amplitude=parameters[2]
	Variable tauRise=parameters[3]		
	Variable tauDecay1=parameters[4]		
	Variable tauDecay2=parameters[5]		
	Variable weightDecay2=parameters[6]		

	// Somewhat controversial, but in the common case that pulse starts are sample-aligned, and pulse durations are
      	// an integer multiple of dt, this ensures that each pulse is exactly pulseDuration samples long
	Variable dt=deltax(w)      	
	Variable delayTweaked=delay-dt/2

	Duplicate /FREE w, wTemp	// Want same dt, number of samples	
	Duplicate /FREE w, xDelayedNice
	xDelayedNice=max(0,x-delayTweaked)		// if (x-delayTweaked)<<0, we get infs below.  So we head those off at the pass.
	wTemp=unitStep(x-delayTweaked)*( -exp(-xDelayedNice/tauRise)+(1-weightDecay2)*exp(-xDelayedNice/tauDecay1)+weightDecay2*exp(-xDelayedNice/tauDecay2) )
	// re-scale to have the proper amplitude
	Wavestats /Q wTemp
	wTemp=(amplitude/V_max)*wTemp		// want the peak amplitude to be amplitude
	// Overlay on the destination wave
	w += unitPulse(x-delayTweaked,duration) * wTemp
End

Function /S PSCGetSignalType()
	return "DAC"
End

