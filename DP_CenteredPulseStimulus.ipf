#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /WAVE CenteredPulseGetParamNames()
	Variable nParameters=2
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="duration"
	parameterNames[1]="amplitude"
	return parameterNames
End

Function /WAVE CenteredPulseGetParamDispNames()
	Variable nParameters=2
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="Duration"
	parameterNames[1]="Amplitude"
	return parameterNames
End

Function /WAVE CenteredPulseGetDfltParams()
	Variable nParameters=2
	Make /FREE /N=(nParameters) parametersDefault
	parametersDefault[0]=100		// ms
	parametersDefault[1]=1
	return parametersDefault
End

Function /WAVE CenteredPulseGetDfltParamsAsStr()
	Variable nParameters=2
	Make /T /FREE /N=(nParameters) parametersDefault
	parametersDefault[0]="100"		// ms
	parametersDefault[1]="1"
	return parametersDefault
End

Function CenteredPulseFillFromParams(w,parameters)
	Wave w
	Wave parameters

	w=0
	CenteredPulseOverlayFromParams(w,parameters)
End

Function CenteredPulseOverlayFromParams(w,parameters)
	Wave w
	Wave parameters

	Variable duration=parameters[0]
	Variable amplitude=parameters[1]
	Variable dt=deltax(w)       
	Variable waveDuration=(numpnts(w)-1)*dt
	Variable delay=(waveDuration-duration)/4

       // Somewhat controversial, but in the common case that pulse starts are sample-aligned, and pulse durations are
       // an integer multiple of dt, this ensures that each pulse is exactly pulseDuration samples long
	Variable delayTweaked=delay-dt/2

	w += amplitude*unitPulse(x-delayTweaked,duration)
End

Function /S CenteredPulseGetSignalType()
	return "DAC"
End
