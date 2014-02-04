#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /WAVE TTLPulseGetParamNames()
	Variable nParams=2
	Make /FREE /T /N=(nParams) paramNames
	paramNames[0]="delay"
	paramNames[1]="duration"
	return paramNames
End

Function TTLPulseFillFromParams(w,params)
	Wave w
	Wave params

	Variable delay=params[0]
	Variable duration=params[1]

       // Somewhat controversial, but in the common case that pulse starts are sample-aligned, and pulse durations are
       // an integer multiple of dt, this ensures that each pulse is exactly pulseDuration samples long
	Variable dt=deltax(w)
	Variable delayTweaked=delay-dt/2

	//Variable pulseDutyCycle=max(0,min((pulseDuration/1000)*pulseRate,1))		// pure
	w=unitPulse(x-delayTweaked,duration)
End

Function /S TTLPulseGetSignalType()
	return "TTL"
End
