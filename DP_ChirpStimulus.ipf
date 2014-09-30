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

Function /WAVE ChirpGetParamDispNames()
	Variable nParameters=5
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="Delay"
	parameterNames[1]="Duration"
	parameterNames[2]="Amplitude"
	parameterNames[3]="Initial Frequency"
	parameterNames[4]="Final Frequency"
	return parameterNames
End

Function /WAVE ChirpGetDfltParamsAsStr()
	Variable nParameters=5
	Make /T /FREE /N=(nParameters) result
	result[0]="10"
	result[1]="50"
	result[2]="1"
	result[3]="50"
	result[4]="200"
	return result
End

Function ChirpAreParamsValid(parameters)
	Wave parameters

	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable amplitude=parameters[2]
	Variable initialFrequency=parameters[3]
	Variable finalFrequency=parameters[4]

	return (duration>=0) && (initialFrequency>0) && (finalFrequency>0)
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

	w += amplitude*unitPulse(x-delay,duration)*amplitude*sin(2*PI*(x-delay)/1000*(0.5*(finalFrequency-initialFrequency)/(duration/1000)*(x-delay)/1000+initialFrequency))
End

Function /S ChirpGetSignalType()
	return "DAC"
End

