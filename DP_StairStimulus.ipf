#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /WAVE StairGetParamNames()
	Variable nParameters=9
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="level1"
	parameterNames[1]="duration1"
	parameterNames[2]="level2"
	parameterNames[3]="duration2"
	parameterNames[4]="level3"
	parameterNames[5]="duration3"
	parameterNames[6]="level4"
	parameterNames[7]="duration4"
	parameterNames[8]="level5"
	return parameterNames
End

Function /WAVE StairGetDefaultParams()
	Variable nParameters=9
	Make /FREE /N=(nParameters) parametersDefault
	parametersDefault[0]=0
	parametersDefault[1]=40		// ms
	parametersDefault[2]=1
	parametersDefault[3]=40		// ms
	parametersDefault[4]=2
	parametersDefault[5]=40		// ms
	parametersDefault[6]=3
	parametersDefault[7]=40		// ms
	parametersDefault[8]=0
	return parametersDefault
End

Function StairFillFromParams(w,parameters)
	Wave w
	Wave parameters

	Variable level1=parameters[0]
	Variable duration1=parameters[1]
	Variable level2=parameters[2]
	Variable duration2=parameters[3]
	Variable level3=parameters[4]
	Variable duration3=parameters[5]
	Variable level4=parameters[6]
	Variable duration4=parameters[7]
	Variable level5=parameters[8]

	Variable delta2=level2-level1
	Variable delta3=level3-level2
	Variable delta4=level4-level3
	Variable delta5=level5-level4
	
	Variable delay2=duration1
	Variable delay3=duration2+delay2
	Variable delay4=duration3+delay3
	Variable delay5=duration4+delay4
	
       // Somewhat controversial, but in the common case that step starts are sample-aligned, and step durations are
       // an integer multiple of dt, this ensures that each pulse is exactly duration/dt samples long
	Variable dt=deltax(w)      	
	Variable delay2Tweaked=delay2-dt/2
	Variable delay3Tweaked=delay3-dt/2
	Variable delay4Tweaked=delay4-dt/2
	Variable delay5Tweaked=delay5-dt/2
	
	w=level1+delta2*unitStep(x-delay2Tweaked)+delta3*unitStep(x-delay3Tweaked)+delta4*unitStep(x-delay4Tweaked)+delta5*unitStep(x-delay5Tweaked)
End

Function /S StairGetSignalType()
	return "DAC"
End

