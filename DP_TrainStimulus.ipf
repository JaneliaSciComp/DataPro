#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /WAVE TrainGetParamNames()
	Variable nParameters=5
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="delay"
	parameterNames[1]="duration"
	parameterNames[2]="amplitude"
	parameterNames[3]="pulseRate"
	parameterNames[4]="pulseDuration"
	return parameterNames
End

Function /WAVE TrainGetParamDispNames()
	Variable nParameters=5
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="Delay"
	parameterNames[1]="Duration"
	parameterNames[2]="Amplitude"
	parameterNames[3]="Pulse Rate"
	parameterNames[4]="Pulse Duration"
	return parameterNames
End

//Function /WAVE TrainGetDfltParams()
//	Variable nParameters=5
//	Make /FREE /N=(nParameters) parametersDefault
//	parametersDefault[0]=20		// ms
//	parametersDefault[1]=100		// ms
//	parametersDefault[2]=1
//	parametersDefault[3]=100		// Hz
//	parametersDefault[4]=2		// ms
//	return parametersDefault
//End

Function /WAVE TrainGetDfltParamsAsStr()
	Variable nParameters=5
	Make /T /FREE /N=(nParameters) parametersDefault
	parametersDefault[0]="20"		// ms
	parametersDefault[1]="100"	// ms
	parametersDefault[2]="1"
	parametersDefault[3]="100"	// Hz
	parametersDefault[4]="2"		// ms
	return parametersDefault
End

Function TrainAreParamsValid(parameters)
	Wave parameters

	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable amplitude=parameters[2]
	Variable pulseRate=parameters[3]				
	Variable pulseDuration=parameters[4]

	return (duration>=0) && (pulseRate>0) && (pulseDuration>=0)
End

Function /WAVE TrainGetParamUnits()
	Variable nParameters=5
	Make /T /FREE /N=(nParameters) paramUnits
	paramUnits[0]="ms"
	paramUnits[1]="ms"
	paramUnits[2]=""
	paramUnits[3]="Hz"
	paramUnits[4]="ms"
	return paramUnits
End

//Function TrainFillFromParams(w,parameters)
//	Wave w
//	Wave parameters
//
//	w=0
//	TrainOverlayFromParams(w,parameters)
//End

Function TrainOverlayFromParams(w,parameters)
	Wave w
	Wave parameters

	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable amplitude=parameters[2]			
	Variable pulseRate=parameters[3]				
	Variable pulseDuration=parameters[4]

	// Somewhat controversial, but in the common case that pulse starts are sample-aligned, and pulse durations are
      	// an integer multiple of dt, this ensures that each pulse is exactly pulseDuration samples long
	Variable dt=deltax(w)      	
	Variable delayTweaked=delay-dt/2

	Variable pulseDutyCycle=max(0,min((pulseDuration/1000)*pulseRate,1))		// pure
	w += amplitude*unitPulse(x-delayTweaked,duration)*squareWave(pulseRate*(x-delayTweaked)/1000,pulseDutyCycle)
End

Function /S TrainGetSignalType()
	return "DAC"
End



