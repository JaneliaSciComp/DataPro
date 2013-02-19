#pragma rtGlobals=1		// Use modern global access method.

Function BuilderViewConstructor(builderType)
	String builderType

	// Synthesize the name of the view from the builderType
	String windowName=builderType+"BuilderView"
	
	// If the window already exists, just raise it
	if (GraphExists(windowName))
		DoWindow /F $windowName
		return 0
	endif

	// Synthesize the name of the true view constructor from the builderType
	String viewConstructorName=builderType+"BuilderViewConstructor"
	
	// Invoke the custom view constructor
	Funcref BuilderViewConstructorFallback viewConstructor=$viewConstructorName
	viewConstructor()
End

Function BuilderViewConstructorFallback()
	Abort "Internal Error: Attempt to call a function that doesn't exist"
End

Function BuilderViewModelChanged(builderType)
	String builderType
	
	// Synthesize the window name from the builderType
	String windowName=builderType+"BuilderView"
	
	// If the view doesn't exist, just return
	if (!GraphExists(windowName))
		return 0		// Have to return something
	endif

	// Save, set data folder
	String savedDF=GetDataFolder(1)
	String dataFolderName=sprintf1s("root:DP_%sBuilder",builderType)
	SetDataFolder $dataFolderName

	WAVE parameters
	WAVE /T parameterNames

	// Set each SetVariable to hold the current model value
	Variable nParameters=numpnts(parameters)
	Variable i
	for (i=0; i<=nParameters; i+=1)
		String controlName=parameterNames[i]+"SV"
		SetVariable $controlName, win=$windowName, value= _NUM:parameters[i]
	endfor
	
	SetDataFolder savedDF
End
