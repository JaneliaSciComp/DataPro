#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /WAVE PulseGetParamNames()
	Variable nParameters=4
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="delay"
	parameterNames[1]="duration"
	parameterNames[2]="baseLevel"
	parameterNames[3]="amplitude"
	return parameterNames
End

Function PulseFillFromParams(w,parameters)
	Wave w
	Wave parameters

	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable baseLevel=parameters[2]				
	Variable amplitude=parameters[3]

       // Somewhat controversial, but in the common case that pulse starts are sample-aligned, and pulse durations are
       // an integer multiple of dt, this ensures that each pulse is exactly pulseDuration samples long
	Variable dt=deltax(w)      	
	Variable delayTweaked=delay-dt/2

	w=baseLevel+amplitude*unitPulse(x-delayTweaked,duration)
End

Function /S PulseGetSignalType()
	return "DAC"
End
