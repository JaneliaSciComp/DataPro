#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /WAVE TrainGetParamNames()
	Variable nParameters=6
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="delay"
	parameterNames[1]="duration"
	parameterNames[2]="pulseRate"
	parameterNames[3]="pulseDuration"
	parameterNames[4]="baseLevel"
	parameterNames[5]="amplitude"
	return parameterNames
End

Function TrainFillFromParams(w,parameters)
	Wave w
	Wave parameters

	//Variable delay=parameters[0]
	//Variable duration=parameters[1]
	//Variable pulseRate=parameters[2]				
	//Variable pulseDuration=parameters[3]
	Variable baseLevel=parameters[4]
	Variable amplitude=parameters[5]			

	TTLTrainFillFromParams(w,parameters)
	w=baseLevel+amplitude*w
End

Function /S TrainGetSignalType()
	return "DAC"
End



