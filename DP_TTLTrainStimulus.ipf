#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /WAVE TTLTrainGetParamNames()
	Variable nParameters=4
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="delay"
	parameterNames[1]="duration"
	parameterNames[2]="pulseRate"
	parameterNames[3]="pulseDuration"
	return parameterNames
End

Function /WAVE TTLTrainGetParamDispNames()
	Variable nParameters=4
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="Delay"
	parameterNames[1]="Duration"
	parameterNames[2]="Pulse Rate"
	parameterNames[3]="Pulse Duration"
	return parameterNames
End

Function /WAVE TTLTrainGetDfltParams()
	Variable nParameters=4
	Make /FREE /N=(nParameters) parametersDefault
	parametersDefault[0]=20		// ms
	parametersDefault[1]=100		// ms
	parametersDefault[2]=100		// Hz
	parametersDefault[3]=2		// ms
	return parametersDefault
End

Function /WAVE TTLTrainGetDfltParamsAsStr()
	Variable nParameters=4
	Make /T /FREE /N=(nParameters) parametersDefault
	parametersDefault[0]="20"		// ms
	parametersDefault[1]="100"	// ms
	parametersDefault[2]="100"	// Hz
	parametersDefault[3]="2"		// ms
	return parametersDefault
End

Function TTLTrainAreParamsValid(parameters)
	Wave parameters

	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable pulseRate=parameters[2]				
	Variable pulseDuration=parameters[3]

	return (duration>=0) && (pulseRate>0) && (pulseDuration>=0)
End

Function /WAVE TTLTrainGetParamUnits()
	Variable nParameters=4
	Make /T /FREE /N=(nParameters) paramUnits
	paramUnits[0]="ms"
	paramUnits[1]="ms"
	paramUnits[2]="Hz"
	paramUnits[3]="ms"
	return paramUnits
End

Function TTLTrainFillFromParams(w,parameters)
	Wave w
	Wave parameters

	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable pulseRate=parameters[2]				
	Variable pulseDuration=parameters[3]

       // Somewhat controversial, but in the common case that pulse starts are sample-aligned, and pulse durations are
       // an integer multiple of dt, this ensures that each pulse is exactly pulseDuration samples long
	Variable dt=deltax(w)      	
	Variable delayTweaked=delay-dt/2

	Variable pulseDutyCycle=max(0,min((pulseDuration/1000)*pulseRate,1))		// pure
	w=unitPulse(x-delayTweaked,duration)*squareWave(pulseRate*(x-delayTweaked)/1000,pulseDutyCycle)
End

Function TTLTrainOverlayFromParams(w,parameters)
	Wave w
	Wave parameters

	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable pulseRate=parameters[2]				
	Variable pulseDuration=parameters[3]

       // Somewhat controversial, but in the common case that pulse starts are sample-aligned, and pulse durations are
       // an integer multiple of dt, this ensures that each pulse is exactly pulseDuration samples long
	Variable dt=deltax(w)      	
	Variable delayTweaked=delay-dt/2

	Variable pulseDutyCycle=max(0,min((pulseDuration/1000)*pulseRate,1))		// pure
	w = w || unitPulse(x-delayTweaked,duration)*squareWave(pulseRate*(x-delayTweaked)/1000,pulseDutyCycle)
End

Function /S TTLTrainGetSignalType()
	return "TTL"
End





