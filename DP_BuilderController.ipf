#pragma rtGlobals=1		// Use modern global access method.

Function BuilderContConstructor(builderType)
	String builderType
	BuilderModelConstructor(builderType);
	BuilderViewConstructor(builderType)
End

Function BuilderContSVTwiddled(svStruct) : SetVariableControl
	STRUCT WMSetVariableAction &svStruct
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif
	
	// Extract the builderType from the window name
	String windowName=svStruct.win
	Variable iEnd=strsearch(windowName,"BuilderView",0)
	String builderType=windowName[0,iEnd-1]
	
	// Extract the parameterName from the SV name
	String svName=svStruct.ctrlName
	String parameterName=svName[0,strlen(svName)-3]
	
	// Get the value
	Variable value=svStruct.dval
	
	// Tell the model, tell the view
	BuilderModelSetParameter(builderType,parameterName,value)
	BuilderViewUpdate(builderType)
End

Function BuilderContSaveAsButtonPressed(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	
	// Extract the builderType from the window name
	String windowName=bStruct.win
	Variable iEnd=strsearch(windowName,"BuilderView",0)
	String builderType=windowName[0,iEnd-1]
	
	// Extract the signal type (DAC or TTL) from the button name
	String buttonName=bStruct.ctrlName
	String signalType=buttonName[6,8]	// buttonName should be either saveAsDACButton or saveAsTTLButton

	// Get the wave name to save as	
	String waveNameString
	Prompt waveNameString, "Enter wave name to save as:"
	DoPrompt "Save as...", waveNameString
	if (V_Flag)
		return -1		// user hit Cancel
	endif
	
	// Send a message to the sweeper with the wave
	String savedDF=GetDataFolder(1)
	String dataFolderName=sprintf1s("root:DP_%sBuilder",builderType)	
	SetDataFolder $dataFolderName
	WAVE theWave
	if (AreStringsEqual(signalType,"DAC"))
		SweeperControllerAddDACWave(theWave,waveNameString)
	else
		SweeperControllerAddTTLWave(theWave,waveNameString)
	endif
	SetDataFolder savedDF
End

Function BuilderContImportButtonPressed(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	
	// Extract the builderType from the window name
	String windowName=bStruct.win
	Variable iEnd=strsearch(windowName,"BuilderView",0)
	String builderType=windowName[0,iEnd-1]

	String fancyWaveNameString
	String popupListString="(Default Settings);"+SweeperGetFancyWaveListOfType(builderType)
	Prompt fancyWaveNameString, "Select wave to import:", popup, popupListString
	DoPrompt "Import...", fancyWaveNameString
	if (V_Flag)
		return -1		// user hit Cancel
	endif
	BuilderModelImportWave(builderType,fancyWaveNameString)
	BuilderViewUpdate(builderType)
End

Function BuilderContSweepDtOrTChngd(builderType)
	// Used to notify the Builder of a change to dt or totalDuration in the Sweeper.
	String builderType
	BuilderModelSweeperDtOrTChanged(builderType)
	BuilderViewUpdate(builderType)
End

