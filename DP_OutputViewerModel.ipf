//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

Function OutputViewerModelConstructor()
	// Construct the model
	// One model invariant: If outputWaveName is empty, then currentWaveName is the empty string
	// Another model invariant: If outputWaveName is nonempty, then currentWaveName is equal to exactly one of the items in outputWaveName.

	// if the DF already exists, nothing to do
	if (DataFolderExists("root:DP_OutputViewer"))
		return 0		// have to return something
	endif

	// Save the current DF
	String savedDF=GetDataFolder(1)
	
	// Create a new DF
	NewDataFolder /S root:DP_OutputViewer
				
	// Create instance vars
	String /G dacWaveNames=""
	String /G ttlWaveNames=""
	String /G currentWaveName=""
	Variable /G currentWaveIsDAC=1	// not used if currentWaveName is empty

	// Restore the original data folder
	SetDataFolder savedDF
End

Function OutputViewerModelSweprWavsChngd()
	// Used to notify the Output Viewer model that the Sweeper waves have changed.
	// Causes the output viewer to update it's own list of the sweeper waves, and change
	// the current wave name if the old one no longer exists.
	if (!DataFolderExists("root:DP_OutputViewer"))
		return 0
	endif

	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_OutputViewer

	SVAR dacWaveNames
	SVAR ttlWaveNames
	SVAR currentWaveName
	NVAR currentWaveIsDAC	

	// Update the list of output wave names
	dacWaveNames=SweeperGetDACWaveNames()
	ttlWaveNames=SweeperGetTTLWaveNames()

	// If the current wave name is no longer valid, deal with that
	Variable nWavesDAC=ItemsInList(dacWaveNames)
	Variable nWavesTTL=ItemsInList(ttlWaveNames)
	//Variable nWaves=nWavesDAC+nWavesTTL
	if (!IsEmptyString(currentWaveName))
		if (currentWaveIsDAC)
			if (IsItemInList(currentWaveName,dacWaveNames))
				// Do nothing, all is well
			else
				currentWaveName=""
				currentWaveIsDAC=0
			endif
		else
			// Current wave is TTL
			if (IsItemInList(currentWaveName,ttlWaveNames))
				// Do nothing, all is well
			else
				currentWaveName=""
				currentWaveIsDAC=0
			endif
		endif
	endif
	// If there is no current wave at this point, pick the first available one, if possible
	if ( IsEmptyString(currentWaveName) )
		if (nWavesDAC>0)
			currentWaveName=StringFromList(0,dacWaveNames)
			currentWaveIsDAC=1
		elseif (nWavesTTL>0)
			currentWaveName=StringFromList(0,ttlWaveNames)
			currentWaveIsDAC=0
		endif
	endif
	
	// Restore the original data folder
	SetDataFolder savedDF		
End

Function /S OutputViewerModelGetPopupItems()
	// A method to synthesize the popup items from the dacWaveNames and the ttlWaveNames.
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_OutputViewer
	
	SVAR dacWaveNames
	SVAR ttlWaveNames
	
	String popupItems=fancyWaveList(dacWaveNames,ttlWaveNames)
	if (ItemsInList(popupItems)==0)
		popupItems="(none)"
	endif

	SetDataFolder savedDF
	return popupItems
End
