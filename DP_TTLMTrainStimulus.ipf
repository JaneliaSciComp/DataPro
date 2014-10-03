#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /WAVE TTLMTrainGetParamNames()
	Variable nParameters=6
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="delay"
	parameterNames[1]="duration"
	parameterNames[2]="pulseRate"
	parameterNames[3]="pulseDuration"
	parameterNames[4]="trainRate"
	parameterNames[5]="trainDuration"
	return parameterNames
End

Function /WAVE TTLMTrainGetParamDispNames()
	Variable nParameters=6
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="Delay"
	parameterNames[1]="Duration"
	parameterNames[2]="Pulse Rate"
	parameterNames[3]="Pulse Duration"
	parameterNames[4]="Train Rate"
	parameterNames[5]="Train Duration"
	return parameterNames
End

//Function /WAVE TTLMTrainGetDfltParams()
//	Variable nParameters=6
//	Make /FREE /N=(nParameters) parametersDefault
//	parametersDefault[0]=25		// ms
//	parametersDefault[1]=150		// ms
//	parametersDefault[2]=100		// Hz
//	parametersDefault[3]=2		// ms
//	parametersDefault[4]=20		// Hz
//	parametersDefault[5]=25		// ms	
//	return parametersDefault
//End

Function /WAVE TTLMTrainGetDfltParamsAsStr()
	Variable nParameters=6
	Make /T /FREE /N=(nParameters) parametersDefault
	parametersDefault[0]="25"		// ms
	parametersDefault[1]="150"	// ms
	parametersDefault[2]="100"	// Hz
	parametersDefault[3]="2"		// ms
	parametersDefault[4]="20"		// Hz
	parametersDefault[5]="25"		// ms	
	return parametersDefault
End

Function TTLMTrainAreParamsValid(parameters)
	Wave parameters

	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable pulseRate=parameters[2]				
	Variable pulseDuration=parameters[3]
	Variable trainRate=parameters[4]				
	Variable trainDuration=parameters[5]

	return (duration>=0) && (pulseRate>0) && (pulseDuration>=0) && (trainRate>0) && (trainDuration>=0)
End

Function /WAVE TTLMTrainGetParamUnits()
	Variable nParameters=6
	Make /T /FREE /N=(nParameters) paramUnits
	paramUnits[0]="ms"
	paramUnits[1]="ms"
	paramUnits[2]="Hz"
	paramUnits[3]="ms"
	paramUnits[4]="Hz"
	paramUnits[5]="ms"
	return paramUnits
End

//Function TTLMTrainFillFromParams(w,parameters)
//	Wave w
//	Wave parameters
//
//	Variable delay=parameters[0]
//	Variable duration=parameters[1]
//	Variable pulseRate=parameters[2]				
//	Variable pulseDuration=parameters[3]
//	Variable trainRate=parameters[4]				
//	Variable trainDuration=parameters[5]
//
//      	// Somewhat controversial, but in the common case that pulse starts are sample-aligned, and pulse durations are
//      	// an integer multiple of dt, this ensures that each pulse is exactly pulseDuration samples long
//	Variable dt=deltax(w)      	
//	Variable delayTweaked=delay-dt/2
//       //Variable pulseDurationTweaked=pulseDuration-dt/2		
//       //Variable trainDurationTweaked=trainDuration-dt/2		
//
//	Variable pulseDutyCycle=max(0,min((pulseDuration/1000)*pulseRate,1))		// pure
//	Variable trainDutyCycle=max(0,min((trainDuration/1000)*trainRate,1))		// pure
//	w=unitPulse(x-delayTweaked,duration)*squareWave(trainRate*(x-delayTweaked)/1000,trainDutyCycle)*squareWave(pulseRate*(x-delayTweaked)/1000,pulseDutyCycle)
//End

Function TTLMTrainOverlayFromParams(w,parameters)
	Wave w
	Wave parameters

	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable pulseRate=parameters[2]				
	Variable pulseDuration=parameters[3]
	Variable trainRate=parameters[4]				
	Variable trainDuration=parameters[5]

      	// Somewhat controversial, but in the common case that pulse starts are sample-aligned, and pulse durations are
      	// an integer multiple of dt, this ensures that each pulse is exactly pulseDuration samples long
	Variable dt=deltax(w)      	
	Variable delayTweaked=delay-dt/2
       //Variable pulseDurationTweaked=pulseDuration-dt/2		
       //Variable trainDurationTweaked=trainDuration-dt/2		

	Variable pulseDutyCycle=max(0,min((pulseDuration/1000)*pulseRate,1))		// pure
	Variable trainDutyCycle=max(0,min((trainDuration/1000)*trainRate,1))		// pure
	w = w || unitPulse(x-delayTweaked,duration)*squareWave(trainRate*(x-delayTweaked)/1000,trainDutyCycle)*squareWave(pulseRate*(x-delayTweaked)/1000,pulseDutyCycle)
End

Function /S TTLMTrainGetSignalType()
	return "TTL"
End



