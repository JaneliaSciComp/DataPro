#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function CSBContConstructor()
	CSBModelConstructor()
	CSBViewConstructor()
End

Function CSBContSignalTypePMActuated(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	// Get the stim type from the menu index
	String signalTypes=CSBModelGetListOfSignalTypes()
	String signalType=StringFromList(popNum-1,signalTypes)  	// popNum is 1-based
	
	// Set the model
	CSBModelSetSignalType(signalType)
	CSBViewUpdate()
End

Function CSBContSegmentTypePMActuated(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	// Extract the segmentIndex from the PM name
	Variable firstUnderscoreIndex=strsearch(ctrlName,"_",0)  // third arg is search start position
	Variable secondUnderscoreIndex=strsearch(ctrlName,"_",firstUnderscoreIndex+1)  // third arg is search start position
	String segmentIndexAsString=ctrlName[firstUnderscoreIndex+1,secondUnderscoreIndex-1]
	Variable segmentIndex=str2num(segmentIndexAsString)

	// Get the stim type from the menu index
	Wave /T simpStimTypes=CSBModelGetStimTypes()
	String simpStimType=simpStimTypes[popNum-1]	// popNum is 1-based
	
	// Set the model
	CSBModelSetSegmentType(segmentIndex,simpStimType)
	CSBViewUpdate()
End

Function CSBContParamSVActuated(svStruct) : SetVariableControl
	STRUCT WMSetVariableAction &svStruct
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif
	String svName=svStruct.ctrlName
	
	// Extract the segmentIndex and parameterName from the SV name
	Variable firstUnderscoreIndex=strsearch(svName,"_",0)  // third arg is search start position
	Variable secondUnderscoreIndex=strsearch(svName,"_",firstUnderscoreIndex+1)  // third arg is search start position
	Variable thirdUnderscoreIndex=strsearch(svName,"_",secondUnderscoreIndex+1)  // third arg is search start position
	String segmentIndexAsString=svName[firstUnderscoreIndex+1,secondUnderscoreIndex-1]
	Variable segmentIndex=str2num(segmentIndexAsString)
	String parameterName=svName[secondUnderscoreIndex+1,thirdUnderscoreIndex-1]
	
	// Get the value
	String valueAsString=svStruct.sval
	
	// Tell the model, tell the view
	CSBModelSetParameterAsString(segmentIndex,parameterName,valueAsString)
	//CSBViewUpdate()
	CSBViewUpdateSingleSV(segmentIndex,parameterName)
End

Function CSBContSaveAsButtonPressed(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	
//	// Extract the builderType from the window name
//	String windowName=bStruct.win
//
//	Variable iEnd=strsearch(windowName,"CompStimBuilderView",0)
//	String builderType=windowName[0,iEnd-1]
	
//	// Extract the signal type (DAC or TTL) from the button name
//	String buttonName=bStruct.ctrlName
//	String signalType=buttonName[6,8]	// buttonName should be either saveAsDACButton or saveAsTTLButton

	// Get the wave name to save as
	String waveNameString
	Prompt waveNameString, "Enter wave name to save as:"
	DoPrompt "Save as...", waveNameString
	if (V_Flag)
		return -1		// user hit Cancel
	endif
	
	// Send a message to the sweeper with the wave
	CSBModelExportToSweeper(waveNameString)
End

Function CSBContImportButtonPressed(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	
//	// Extract the builderType from the window name
//	String windowName=bStruct.win
//	Variable iEnd=strsearch(windowName,"CompStimBuilderView",0)
//	String builderType=windowName[0,iEnd-1]

	String signalType=CSBModelGetSignalType()
	String waveNameString
	String popupListString="(Default Settings);"+SweeperGetWaveListOfSignalType(signalType)
	Prompt waveNameString, "Select wave to import:", popup, popupListString
	DoPrompt "Import...", waveNameString
	if (V_Flag)
		return -1		// user hit Cancel
	endif
	CSBModelImportWave(waveNameString)
	CSBViewUpdate()
End

Function CSBContSweepDtOrTChngd()
	// Used to notify the CompStimBuilder of a change to dt or totalDuration in the Sweeper.
	CSBModelSweeperDtOrTChanged()
	CSBViewUpdate()
End

Function CSBContAddSegButtonPressed(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	
	CSBModelAddSeg()
	CSBViewUpdate()	
End

Function CSBContDelSegButtonPressed(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif

	CSBModelDelSeg()
	CSBViewUpdate()		
End

