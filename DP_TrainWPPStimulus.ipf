#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /WAVE TrainWPPGetParamNames()
	Variable nParameters=9
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="delay"
	parameterNames[1]="prepulseDuration"
	parameterNames[2]="prepulseAmplitude"
	parameterNames[3]="delayFromPrepulseToTrain"
	parameterNames[4]="trainDuration"
	parameterNames[5]="pulseRate"
	parameterNames[6]="pulseDuration"
	parameterNames[7]="pulseAmplitude"	
	parameterNames[8]="baseLevel"
	return parameterNames
End

Function /WAVE TrainWPPGetDfltParams()
	Variable nParameters=9
	Make /FREE /N=(nParameters) parametersDefault
	parametersDefault[0]=20		// ms
	parametersDefault[1]=10		// ms
	parametersDefault[2]=1		// pure		
	parametersDefault[3]=20		// ms
	parametersDefault[4]=100		// ms
	parametersDefault[5]=100		// Hz
	parametersDefault[6]=2		// ms
	parametersDefault[7]=10
	parametersDefault[8]=0
	return parametersDefault
End

Function TrainWPPFillFromParams(w,parameters)
	Wave w
	Wave parameters

	//Variable delay=parameters[0]
	//Variable duration=parameters[1]
	//Variable pulseRate=parameters[2]				
	//Variable pulseDuration=parameters[3]
	//Variable baseLevel=parameters[4]
	//Variable amplitude=parameters[5]			

	Variable delay=parameters[0]
	Variable prepulseDuration=parameters[1]
	Variable prepulseAmplitude=parameters[2]
	Variable delayFromPrepulseToTrain=parameters[3]
	Variable trainDuration=parameters[4]
	Variable pulseRate=parameters[5]
	Variable pulseDuration=parameters[6]
	Variable pulseAmplitude=parameters[7]
	Variable baseLevel=parameters[8]

       // Somewhat controversial, but in the common case that pulse starts are sample-aligned, and pulse durations are
       // an integer multiple of dt, this ensures that each pulse is exactly pulseDuration samples long
	Variable dt=deltax(w)      	
	Variable delayTweaked=delay-dt/2

	Variable delayToTrainTweaked=delayTweaked+prepulseDuration+delayFromPrepulseToTrain

	Variable pulseDutyCycle=max(0,min((pulseDuration/1000)*pulseRate,1))		// pure
	w=baseLevel+prepulseAmplitude*unitPulse(x-delayTweaked,prepulseDuration)+pulseAmplitude*unitPulse(x-delayToTrainTweaked,trainDuration)*squareWave(pulseRate*(x-delayToTrainTweaked)/1000,pulseDutyCycle)
End

Function /S TrainWPPGetSignalType()
	return "DAC"
End

