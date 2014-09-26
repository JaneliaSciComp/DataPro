#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /WAVE BuiltinPulseGetParamNames()
	Variable nParameters=2
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="duration"
	parameterNames[1]="amplitude"
	return parameterNames
End

Function /WAVE BuiltinPulseGetDfltParams()
	Variable nParameters=2
	Make /FREE /N=(nParameters) parametersDefault
	parametersDefault[0]=100		// ms
	parametersDefault[1]=1
	return parametersDefault
End

Function BuiltinPulseFillFromParams(w,parameters)
	Wave w
	Wave parameters

	Variable duration=parameters[0]
	Variable amplitude=parameters[1]
	Variable delay=(StimulusGetDuration(w)-duration)/4

       // Somewhat controversial, but in the common case that pulse starts are sample-aligned, and pulse durations are
       // an integer multiple of dt, this ensures that each pulse is exactly pulseDuration samples long
	Variable dt=deltax(w)       
	Variable delayTweaked=delay-dt/2

	w=amplitude*unitPulse(x-delayTweaked,duration)
End

Function /S BuiltinPulseGetSignalType()
	return "DAC"
End
