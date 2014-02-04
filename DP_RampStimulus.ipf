#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /WAVE RampGetParamNames()
	Variable nParameters=5
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="baselineLevel"
	parameterNames[1]="delay"
	parameterNames[2]="initialLevel"
	parameterNames[3]="duration"
	parameterNames[4]="finalLevel"	
	return parameterNames
End

Function RampFillFromParams(w,parameters)
	Wave w
	Wave parameters

	Variable baselineLevel=parameters[0]
	Variable delay=parameters[1]
	Variable initialLevel=parameters[2]
	Variable duration=parameters[3]
	Variable finalLevel=parameters[4]

	w=baselineLevel+((initialLevel-baselineLevel)+(finalLevel-initialLevel)*max(0,min((x-delay)/duration,1)))*unitPulse(x-delay,duration)
End

Function /S RampGetSignalType()
	return "DAC"
End



