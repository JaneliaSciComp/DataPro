#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /WAVE TTLPulseGetParamNames()
	Variable nParams=2
	Make /FREE /T /N=(nParams) paramNames
	paramNames[0]="delay"
	paramNames[1]="duration"
	return paramNames
End

Function /WAVE TTLPulseGetParamDispNames()
	Variable nParams=2
	Make /FREE /T /N=(nParams) paramNames
	paramNames[0]="Delay"
	paramNames[1]="Duration"
	return paramNames
End

//Function /WAVE TTLPulseGetDfltParams()
//	Variable nParameters=2
//	Make /FREE /N=(nParameters) parametersDefault
//	parametersDefault[0]=20		// ms
//	parametersDefault[1]=100		// ms
//	return parametersDefault
//End

Function /WAVE TTLPulseGetDfltParamsAsStr()
	Variable nParameters=2
	Make /T /FREE /N=(nParameters) parametersDefault
	parametersDefault[0]="20"		// ms
	parametersDefault[1]="100"		// ms
	return parametersDefault
End

Function TTLPulseAreParamsValid(parameters)
	Wave parameters

	Variable delay=parameters[0]
	Variable duration=parameters[1]

	return (duration>=0)
End

Function /WAVE TTLPulseGetParamUnits()
	Variable nParameters=2
	Make /T /FREE /N=(nParameters) paramUnits
	paramUnits[0]="ms"
	paramUnits[1]="ms"
	return paramUnits
End

//Function TTLPulseFillFromParams(w,params)
//	Wave w
//	Wave params
//
//	w=0
//	TTLPulseOverlayFromParams(w,params)
//End

Function TTLPulseOverlayFromParams(w,params)
	Wave w
	Wave params

	Variable delay=params[0]
	Variable duration=params[1]

       // Somewhat controversial, but in the common case that pulse starts are sample-aligned, and pulse durations are
       // an integer multiple of dt, this ensures that each pulse is exactly pulseDuration samples long
	Variable dt=deltax(w)
	Variable delayTweaked=delay-dt/2

	//Variable pulseDutyCycle=max(0,min((pulseDuration/1000)*pulseRate,1))		// pure
	w = w || unitPulse(x-delayTweaked,duration)
End

Function /S TTLPulseGetSignalType()
	return "TTL"
End
