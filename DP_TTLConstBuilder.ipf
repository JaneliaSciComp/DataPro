#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// This is no a user-usable builder, so don't need the view stuff

Function TTLConstBuilderModelInitialize()
	// Called from the constructor, so DF already set.
	Variable nParameters=1
	WAVE /T parameterNames
	WAVE parametersDefault
	WAVE parameters
	Redimension /N=(nParameters) parameterNames
	parameterNames[0]="baseLevel"
	Redimension /N=(nParameters) parametersDefault
	parametersDefault[0]=0		// boolean
	Redimension /N=(nParameters) parameters
	parameters=parametersDefault
	SVAR signalType
	signalType="TTL"
End

Function fillTTLConstFromParamsBang(w,dt,nScans,parameters,parameterNames)
	Wave w
	Variable dt,nScans
	Wave parameters
	Wave /T parameterNames

	Variable baseLevel=parameters[0]

	w=baseLevel		// it's just that easy
End
