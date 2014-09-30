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
	
	// Whether the wave is a DAC or TTL wave
	String /G signalType="DAC"
	
	// Parameters of stimulus
	Variable /G dt=SweeperGetDt()
	Variable /G totalDuration=SweeperGetTotalDuration()
	String pulseSimpStim=SimpStimDefault("Pulse")
	Wave /T compStim=CompStimFromSimpStim(pulseSimpStim)
	
	// Create the wave
	Make /O theWave
	CompStimWaveSet(theWave,dt,totalDuration,compStim)

	// Create a CompStimWave for the other signal type (TTL)
	String ttlPulseSimpStim=SimpStimDefault("TTLPulse")
	Duplicate /O CompStimFromSimpStim(ttlPulseSimpStim), theOtherCompStim	// bound wave

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

Function CSBModelImportWave(waveNameString)
	// Imports the stimulus parameters from a pre-existing wave in the Sweeper
	// This is a model method
	//String builderType
	String waveNameString
	
	// Switch to the DF
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_CompStimBuilder
	
	// Instance vars
	WAVE theWave
	SVAR signalType

	Variable i
	if ( AreStringsEqual(waveNameString,"(Default Settings)") )
		CompStimWaveSetEachToDefault(theWave)
	else
		// Get the wave from the digitizer
		Wave exportedWave=SweeperGetWaveByTypeAndName(signalType,waveNameString)
		Wave /T theCompStim=CompStimWaveGetCompStim(exportedWave)
		CompStimWaveSetCompStim(theWave,theCompStim)
	endif
	
	SetDataFolder savedDF	
End

Function CSBModelExportToSweeper(waveNameString)
	// Send a message to the sweeper with the wave
	String waveNameString

	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_CompStimBuilder

	WAVE theWave
	SVAR signalType

	if ( AreStringsEqual(signalType,"DAC") )
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

Function CSBModelAddSeg()
	// Save, set the DF
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_CompStimBuilder
	
	WAVE theWave
	SVAR signalType

	String segmentType=stringFif(AreStringsEqual(signalType,"DAC"),"Pulse","TTLPulse")	
	CompStimWaveAddSegment(theWave,segmentType)

	// Restore the DF
	SetDataFolder savedDF		
End

Function CSBModelDelSeg()
	// Save, set the DF
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_CompStimBuilder
	
	WAVE theWave

	Variable nStimuliOriginal=CompStimWaveGetNStimuli(theWave)
	// Don't delete if only one left
	if (nStimuliOriginal>1)
		CompStimWaveDelSegment(theWave)
	endif

	// Restore the DF
	SetDataFolder savedDF		
End

Function /WAVE CSBModelGetStimTypes()
	// Save, set the DF
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_CompStimBuilder

	SVAR signalType

	if ( AreStringsEqual(signalType,"DAC") )
		Make /T /FREE result={"Pulse", "Train", "MulTrain", "Ramp", "Sine", "Chirp", "WNoise", "PSC" }
	else
		Make /T /FREE result={"TTLPulse", "TTLTrain", "TTLMTrain"}
	endif

	// Restore the DF
	SetDataFolder savedDF		

	return result
End

Function /WAVE CSBModelGetDisplayStimTypes()
	// Save, set the DF
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_CompStimBuilder

	SVAR signalType

	if ( AreStringsEqual(signalType,"DAC") )
		Make /T /FREE result={"Pulse", "Train", "Multiple Trains", "Ramp", "Sine", "Chirp", "White Noise", "PSC" }
	else
		Make /T /FREE result={"Pulse", "Train", "Multiple Trains"}
	endif	

	return result
End

Function /S CSBModelGetSignalType()
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_CompStimBuilder

	// instance vars
	SVAR signalType

	SetDataFolder savedDF

	return signalType
End

Function CSBModelSetSignalType(newSignalType)
	String newSignalType

	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_CompStimBuilder

	// instance vars
	SVAR signalType
	WAVE theWave
	WAVE theOtherCompStim

	// If no change, do nothing
	if ( AreStringsEqual(newSignalType,signalType) )
		// do nothing
	else
		signalType=newSignalType

		// Swap theOtherCompStim and theWave
		// theWave is a CompStimWave, theOtherCompStim is a CompStim, but you get the idea
		Wave /T originalCompStim=CompStimWaveGetCompStim(theWave)
		CompStimWaveSetCompStim(theWave,theOtherCompStim)
		Duplicate /O originalCompStim, theOtherCompStim
	endif	

	SetDataFolder savedDF
End



//
// Static methods
//

Function /S CSBModelGetListOfSignalTypes()
	return "DAC;TTL"
End

