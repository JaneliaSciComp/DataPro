#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /WAVE TrainGetParamNames()
	Variable nParameters=5
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="delay"
	parameterNames[1]="duration"
	parameterNames[2]="pulseRate"
	parameterNames[3]="pulseDuration"
	parameterNames[4]="amplitude"
	return parameterNames
End

Function /WAVE TrainGetParamDisplayNames()
	Variable nParameters=5
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="Delay"
	parameterNames[1]="Duration"
	parameterNames[2]="Pulse Rate"
	parameterNames[3]="Pulse Duration"
	parameterNames[4]="Amplitude"
	return parameterNames
End

Function /WAVE TrainGetDfltParams()
	Variable nParameters=5
	Make /FREE /N=(nParameters) parametersDefault
	parametersDefault[0]=20		// ms
	parametersDefault[1]=100		// ms
	parametersDefault[2]=100		// Hz
	parametersDefault[3]=2		// ms
	parametersDefault[4]=1
	return parametersDefault
End

Function /WAVE TrainGetDfltParamsAsStrings()
	Variable nParameters=5
	Make /T /FREE /N=(nParameters) parametersDefault
	parametersDefault[0]="20"		// ms
	parametersDefault[1]="100"		// ms
	parametersDefault[2]="100"		// Hz
	parametersDefault[3]="2"		// ms
	parametersDefault[4]="1"
	return parametersDefault
End

Function TrainFillFromParams(w,parameters)
	Wave w
	Wave parameters

	w=0
	TrainOverlayFromParams(w,parameters)
End

Function TrainOverlayFromParams(w,parameters)
	Wave w
	Wave parameters

	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable pulseRate=parameters[2]				
	Variable pulseDuration=parameters[3]
	Variable amplitude=parameters[4]			

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



