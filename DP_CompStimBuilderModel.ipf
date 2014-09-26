#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function CSBModelConstructor()
	// if the DF already exists, nothing to do
	String dataFolderName="root:DP_CompStimBuilder"
	if (DataFolderExists(dataFolderName))
		return 0		// have to return something
	endif

	// Save the current DF
	String savedDF=GetDataFolder(1)
	
	// Create a new DF
	NewDataFolder /O /S $dataFolderName
	
	// Parameters of stimulus
	Variable /G dt=SweeperGetDt()
	Variable /G totalDuration=SweeperGetTotalDuration()
	String pulseSimpStim=SimpStimDefault("Pulse")
	Wave /T compStim=CompStimFromSimpStim(pulseSimpStim)
	
	// Create the wave
	Make /O theWave
	CompStimWaveSet(theWave,dt,totalDuration,compStim)

	// Restore the original data folder
	SetDataFolder savedDF
End

Function CSBModelSetParameterAsString(segmentIndex,parameterName,valueAsString)
	// Set the named parameter in the indicated segment
	Variable segmentIndex
	String parameterName
	String valueAsString

	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_CompStimBuilder

	// instance vars
	WAVE theWave
	
	// Set the parameter in the segments
	CompStimWaveSetParamAsString(theWave,segmentIndex,parameterName,valueAsString)

	SetDataFolder savedDF
End

Function CSBModelSetSegmentType(segmentIndex,simpStimType)
	Variable segmentIndex
	String simpStimType

	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_CompStimBuilder

	// instance vars
	WAVE theWave
	
	// Set the parameter in the segments
	CompStimWaveSetSegmentType(theWave,segmentIndex,simpStimType)

	SetDataFolder savedDF
End

Function CSBModelImportWave(builderType,fancyWaveNameString)
	// Imports the stimulus parameters from a pre-existing wave in the Sweeper
	// This is a model method
	String builderType
	String fancyWaveNameString
	
	// Switch to the DF
	String savedDF=GetDataFolder(1)
	String dataFolderName=sprintf1s("root:DP_%sBuilder",builderType)
	SetDataFolder $dataFolderName
	
	// Instance vars
	//WAVE /T parameterNames
	WAVE parameters
	WAVE theWave

	Wave /T parameterNames=StimulusGetParamNames(theWave)
	Variable i
	if (AreStringsEqual(fancyWaveNameString,"(Default Settings)"))
		Wave parameters=StimulusGetDefParamsFromType(builderType)
	else
		// Get the wave from the digitizer
		Wave exportedWave=SweeperGetWaveByFancyName(fancyWaveNameString)
		String waveTypeString=StringByKeyInWaveNote(exportedWave,"WAVETYPE")
		if (AreStringsEqual(waveTypeString,builderType))
			Wave newParameters=StimulusGetParams(exportedWave)
			parameters=newParameters
		else
			Abort(sprintf1s("This is not a %s wave; choose another",builderType))
		endif
	endif
	StimulusSetParams(theWave,parameters)
	
	SetDataFolder savedDF	
End

Function CSBModelExportToSweeper(builderType,waveNameString)
	String builderType
	String waveNameString
	// Send a message to the sweeper with the wave
	String savedDF=GetDataFolder(1)
	String dataFolderName=sprintf1s("root:DP_%sBuilder",builderType)	
	SetDataFolder $dataFolderName
	WAVE theWave
	String signalType=StimulusGetSignalType(theWave)
	if (AreStringsEqual(signalType,"DAC"))
		SweeperControllerAddDACWave(theWave,waveNameString)
	else
		SweeperControllerAddTTLWave(theWave,waveNameString)
	endif
	SetDataFolder savedDF
End

Function CSBModelSweeperDtOrTChanged()
	// Used to notify the Builder model of a change to dt or totalDuration in the Sweeper.
	
	// If no builder of the given type currently exists, do nothing
	String dataFolderName="root:DP_CompStimBuilder"
	if (!DataFolderExists(dataFolderName))
		return 0
	endif
	
	// Save, set the DF
	String savedDF=GetDataFolder(1)
	SetDataFolder $dataFolderName
	
	NVAR dt, totalDuration
	WAVE theWave
	
	// Get dt, totalDuration from the sweeper
	dt=SweeperGetDt()
	totalDuration=SweeperGetTotalDuration()
	// Update the	wave
	CompStimWaveSetDtAndDur(theWave,dt,totalDuration)
	
	// Restore the DF
	SetDataFolder savedDF		
End

