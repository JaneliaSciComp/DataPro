#pragma rtGlobals=1		// Use modern global access method.

Function BuilderViewModelChanged(builderType)
	String builderType
	
	String savedDF=GetDataFolder(1)
	String dfString=sprintf1s("root:DP_%sBuilder",builderType)
	SetDataFolder $dfString

	WAVE parameters
	WAVE /T parameterNames

	// Synthesize the window name from the builderType
	String windowName=builderType+"BuilderView"

	// Set each SetVariable to hold the current model value
	Variable nParameters=numpnts(parameters)
	Variable i
	for (i=0; i<=nParameters; i+=1)
		String controlName=parameterNames[i]+"SV"
		SetVariable $controlName, win=$windowName, value= _NUM:parameters[i]
	endfor
	
	SetDataFolder savedDF
End
