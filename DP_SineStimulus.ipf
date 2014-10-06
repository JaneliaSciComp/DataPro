#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /WAVE SineGetParamNames()
	Variable nParameters=4
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="delay"
	parameterNames[1]="duration"
	parameterNames[2]="amplitude"
	parameterNames[3]="frequency"
	return parameterNames
End

Function /WAVE SineGetParamDispNames()
	Variable nParameters=4
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="Delay"
	parameterNames[1]="Duration"
	parameterNames[2]="Amplitude"
	parameterNames[3]="Frequency"
	return parameterNames
End

//Function /WAVE SineGetDfltParams()
//	Variable nParameters=4
//	Make /FREE /N=(nParameters) parametersDefault
//	parametersDefault[0]=10
//	parametersDefault[1]=50
//	parametersDefault[2]=1
//	parametersDefault[3]=100
//	return parametersDefault
//End

Function /WAVE SineGetDfltParamsAsStr()
	Variable nParameters=4
	Make /T /FREE /N=(nParameters) parametersDefault
	parametersDefault[0]="10"
	parametersDefault[1]="50"
	parametersDefault[2]="1"
	parametersDefault[3]="100"
	return parametersDefault
End

Function SineAreParamsValid(paramsAsStrings)
	Wave /T paramsAsStrings
	
	Wave parameters=DoubleWaveFromTextWave(paramsAsStrings)

	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable amplitude=parameters[2]
	Variable frequency=parameters[3]

	return (duration>=0) && (frequency>0)
End

Function /WAVE SineGetParamUnits()
	Variable nParameters=4
	Make /T /FREE /N=(nParameters) paramUnits
	paramUnits[0]="ms"
	paramUnits[1]="ms"
	paramUnits[2]=""
	paramUnits[3]="Hz"
	return paramUnits
End

//Function SineFillFromParams(w,parameters)
//	Wave w
//	Wave parameters
//
//	Variable delay=parameters[0]
//	Variable duration=parameters[1]
//	Variable amplitude=parameters[2]
//	Variable frequency=parameters[3]
//
//	w = amplitude*unitPulse(x-delay,duration)*sin(frequency*2*PI*(x-delay)/1000)
//End

Function SineOverlayFromParams(w,paramsAsStrings)
	Wave w
	Wave /T paramsAsStrings

	Wave parameters=DoubleWaveFromTextWave(paramsAsStrings)

	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable amplitude=parameters[2]
	Variable frequency=parameters[3]

	// Somewhat controversial, but in the common case that pulse starts are sample-aligned, and pulse durations are
      	// an integer multiple of dt, this ensures that each pulse is exactly pulseDuration samples long
	Variable dt=deltax(w)      	
	Variable delayTweaked=delay-dt/2

	w += amplitude*unitPulse(x-delayTweaked,duration)*sin(frequency*2*PI*(x-delayTweaked)/1000)
End

Function /S SineGetSignalType()
	return "DAC"
End

