#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /WAVE MulTrainGetParamNames()
	Variable nParameters=7
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="delay"
	parameterNames[1]="duration"
	parameterNames[2]="amplitude"
	parameterNames[3]="pulseRate"
	parameterNames[4]="pulseDuration"
	parameterNames[5]="trainRate"
	parameterNames[6]="trainDuration"
	return parameterNames
End

Function /WAVE MulTrainGetParamDisplayNames()
	Variable nParameters=7
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="Delay"
	parameterNames[1]="Duration"
	parameterNames[2]="Amplitude"
	parameterNames[3]="Pulse Rate"
	parameterNames[4]="Pulse Duration"
	parameterNames[5]="Train Rate"
	parameterNames[6]="Train Duration"
	return parameterNames
End

Function /WAVE MulTrainGetDfltParams()
	Variable nParameters=7
	Make /FREE /N=(nParameters) parametersDefault
	parametersDefault[0]=25		// ms
	parametersDefault[1]=150		// ms
	parametersDefault[2]=1
	parametersDefault[3]=100		// Hz
	parametersDefault[4]=2		// ms
	parametersDefault[5]=20		// Hz
	parametersDefault[6]=25		// ms	
	return parametersDefault
End

Function /WAVE MulTrainGetDfltParamsAsStrings()
	Variable nParameters=7
	Make /T /FREE /N=(nParameters) parametersDefault
	parametersDefault[0]="25"		// ms
	parametersDefault[1]="150"	// ms
	parametersDefault[2]="1"
	parametersDefault[3]="100"	// Hz
	parametersDefault[4]="2"		// ms
	parametersDefault[5]="20"		// Hz
	parametersDefault[6]="25"		// ms	
	return parametersDefault
End

Function MulTrainFillFromParams(w,parameters)
	Wave w
	Wave parameters

	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable amplitude=parameters[2]			
	Variable pulseRate=parameters[3]				
	Variable pulseDuration=parameters[4]
	Variable trainRate=parameters[5]				
	Variable trainDuration=parameters[6]

      	// Somewhat controversial, but in the common case that pulse starts are sample-aligned, and pulse durations are
      	// an integer multiple of dt, this ensures that each pulse is exactly pulseDuration samples long
	Variable dt=deltax(w)      	
	Variable delayTweaked=delay-dt/2
       //Variable pulseDurationTweaked=pulseDuration-dt/2		
       //Variable trainDurationTweaked=trainDuration-dt/2		

	Variable pulseDutyCycle=max(0,min((pulseDuration/1000)*pulseRate,1))	// pure
	Variable trainDutyCycle=max(0,min((trainDuration/1000)*trainRate,1))		// pure
	w=amplitude*unitPulse(x-delayTweaked,duration)*squareWave(trainRate*(x-delayTweaked)/1000,trainDutyCycle)*squareWave(pulseRate*(x-delayTweaked)/1000,pulseDutyCycle)
End

Function MulTrainOverlayFromParams(w,parameters)
	Wave w
	Wave parameters

	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable amplitude=parameters[2]			
	Variable pulseRate=parameters[3]				
	Variable pulseDuration=parameters[4]
	Variable trainRate=parameters[5]				
	Variable trainDuration=parameters[6]

      	// Somewhat controversial, but in the common case that pulse starts are sample-aligned, and pulse durations are
      	// an integer multiple of dt, this ensures that each pulse is exactly pulseDuration samples long
	Variable dt=deltax(w)      	
	Variable delayTweaked=delay-dt/2
       //Variable pulseDurationTweaked=pulseDuration-dt/2		
       //Variable trainDurationTweaked=trainDuration-dt/2		

	Variable pulseDutyCycle=max(0,min((pulseDuration/1000)*pulseRate,1))	// pure
	Variable trainDutyCycle=max(0,min((trainDuration/1000)*trainRate,1))		// pure
	w += amplitude*unitPulse(x-delayTweaked,duration)*squareWave(trainRate*(x-delayTweaked)/1000,trainDutyCycle)*squareWave(pulseRate*(x-delayTweaked)/1000,pulseDutyCycle)
End

Function /S MulTrainGetSignalType()
	return "DAC"
End

