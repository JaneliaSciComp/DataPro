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

