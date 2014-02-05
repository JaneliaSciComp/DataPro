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

Function /WAVE RampGetDefaultParams()
	Variable nParameters=5
	Make /FREE /N=(nParameters) parametersDefault
	parametersDefault[0]=0
	parametersDefault[1]=50
	parametersDefault[2]=-10
	parametersDefault[3]=100
	parametersDefault[4]=10
	return parametersDefault
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



