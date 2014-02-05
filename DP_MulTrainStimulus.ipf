#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /WAVE MulTrainGetParamNames()
	Variable nParameters=8
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="delay"
	parameterNames[1]="duration"
	parameterNames[2]="pulseRate"
	parameterNames[3]="pulseDuration"
	parameterNames[4]="trainRate"
	parameterNames[5]="trainDuration"
	parameterNames[6]="baseLevel"
	parameterNames[7]="amplitude"
	return parameterNames
End

Function /WAVE MulTrainGetDefaultParams()
	Variable nParameters=8
	Make /FREE /N=(nParameters) parametersDefault
	parametersDefault[0]=25		// ms
	parametersDefault[1]=150		// ms
	parametersDefault[2]=100		// Hz
	parametersDefault[3]=2		// ms
	parametersDefault[4]=20		// Hz
	parametersDefault[5]=25		// ms	
	parametersDefault[6]=0
	parametersDefault[7]=10
	return parametersDefault
End

Function MulTrainFillFromParams(w,parameters)
	Wave w
	Wave parameters

//	Variable delay=parameters[0]
//	Variable duration=parameters[1]
//	Variable pulseRate=parameters[2]				
//	Variable pulseDuration=parameters[3]
//	Variable trainRate=parameters[4]				
//	Variable trainDuration=parameters[5]
	Variable baseLevel=parameters[6]
	Variable amplitude=parameters[7]			

	TTLMTrainFillFromParams(w,parameters)
	w=baseLevel+amplitude*w
End

Function /S MulTrainGetSignalType()
	return "DAC"
End

