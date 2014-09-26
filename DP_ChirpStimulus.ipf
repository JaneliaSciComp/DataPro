#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /WAVE ChirpGetParamNames()
	Variable nParameters=5
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="delay"
	parameterNames[1]="duration"
	parameterNames[2]="amplitude"
	parameterNames[3]="initialFrequency"
	parameterNames[4]="finalFrequency"
	return parameterNames
End

Function /WAVE ChirpGetDfltParams()
	Variable nParameters=5
	Make /FREE /N=(nParameters) parametersDefault
	parametersDefault[0]=10
	parametersDefault[1]=50
	parametersDefault[2]=10
	parametersDefault[3]=50
	parametersDefault[4]=200
	return parametersDefault
End

Function /WAVE ChirpGetDfltParamsAsStrings()
	Variable nParameters=5
	Make /T /FREE /N=(nParameters) result
	result[0]="10"
	result[1]="50"
	result[2]="10"
	result[3]="50"
	result[4]="200"
	return result
End

Function ChirpFillFromParams(w,parameters)
	Wave w
	Wave parameters

	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable amplitude=parameters[2]
	Variable initialFrequency=parameters[3]
	Variable finalFrequency=parameters[4]

	w=amplitude*unitPulse(x-delay,duration)*amplitude*sin(2*PI*(x-delay)/1000*(0.5*(finalFrequency-initialFrequency)/(duration/1000)*(x-delay)/1000+initialFrequency))
End

Function ChirpOverlayFromParams(w,parameters)
	Wave w
	Wave parameters

	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable amplitude=parameters[2]
	Variable initialFrequency=parameters[3]
	Variable finalFrequency=parameters[4]

	w+=amplitude*unitPulse(x-delay,duration)*amplitude*sin(2*PI*(x-delay)/1000*(0.5*(finalFrequency-initialFrequency)/(duration/1000)*(x-delay)/1000+initialFrequency))
End

Function /S ChirpGetSignalType()
	return "DAC"
End

