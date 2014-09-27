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

Function /WAVE PSCGetParamDisplayNames()
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

Function /WAVE PSCGetDfltParams()
	Variable nParameters=7
	Make /FREE /N=(nParameters) parametersDefault
	parametersDefault[0]=10
	parametersDefault[1]=100
	parametersDefault[2]=1
	parametersDefault[3]=0.2
	parametersDefault[4]=2
	parametersDefault[5]=10
	parametersDefault[6]=0.5
	return parametersDefault
End

Function /WAVE PSCGetDfltParamsAsStrings()
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

Function PSCFillFromParams(w,parameters)
	Wave w
	Wave parameters

	w=0
	PSCOverlayFromParams(w,parameters)	
End

Function PSCOverlayFromParams(w,parameters)
	Wave w
	Wave parameters

	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable amplitude=parameters[2]
	Variable tauRise=parameters[3]		
	Variable tauDecay1=parameters[4]		
	Variable tauDecay2=parameters[5]		
	Variable weightDecay2=parameters[6]		

	Duplicate /FREE w, wTemp	// Want same dt, number of samples	
	wTemp=unitStep(x-delay)*(-exp(-(x-delay)/tauRise)+(1-weightDecay2)*exp(-(x-delay)/tauDecay1)+weightDecay2*exp(-(x-delay)/tauDecay2))
	// re-scale to have the proper amplitude
	Wavestats /Q wTemp
	wTemp=(amplitude/V_max)*wTemp		// want the peak amplitude to be amplitude
	// Overlay on the destination wave
	w += unitPulse(x-delay,duration) * wTemp
End

Function /S PSCGetSignalType()
	return "DAC"
End

