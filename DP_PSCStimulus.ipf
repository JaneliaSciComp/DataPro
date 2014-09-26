#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /WAVE PSCGetParamNames()
	Variable nParameters=6
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="delay"
	parameterNames[1]="amplitude"
	parameterNames[2]="tauRise"
	parameterNames[3]="tauDecay1"
	parameterNames[4]="tauDecay2"
	parameterNames[5]="weightDecay2"
	return parameterNames
End

Function /WAVE PSCGetDfltParams()
	Variable nParameters=6
	Make /FREE /N=(nParameters) parametersDefault
	parametersDefault[0]=10
	parametersDefault[1]=10
	parametersDefault[2]=0.2
	parametersDefault[3]=2
	parametersDefault[4]=10
	parametersDefault[5]=0.5
	return parametersDefault
End

Function PSCFillFromParams(w,parameters)
	Wave w
	Wave parameters

	Variable delay=parameters[0]
	Variable amplitude=parameters[1]
	Variable tauRise=parameters[2]		
	Variable tauDecay1=parameters[3]		
	Variable tauDecay2=parameters[4]		
	Variable weightDecay2=parameters[5]		

	w=unitStep(x-delay)*(-exp(-(x-delay)/tauRise)+(1-weightDecay2)*exp(-(x-delay)/tauDecay1)+weightDecay2*exp(-(x-delay)/tauDecay2))
	// re-scale to have the proper amplitude
	Wavestats /Q w
	w=(amplitude/V_max)*w		// want the peak amplitude to be amplitude
End

Function /S PSCGetSignalType()
	return "DAC"
End

