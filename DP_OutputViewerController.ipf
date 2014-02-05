//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

Function OutputViewerContConstructor()
	OutputViewerModelConstructor()
	OutputViewerViewConstructor()
End

Function OutputViewerContWavePopup(ctrlName,itemNum,itemStr) : PopupMenuControl
	String ctrlName
	Variable itemNum
	String itemStr

	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_OutputViewer

	SVAR currentWaveName
	NVAR currentWaveIsDAC
	
	if ( AreStringsEqual(itemStr,"(none)") )
		currentWaveName=""		// should already be this, but what the heck
	else
		if (GrepString(itemStr," \(TTL\)$"))
			currentWaveName=itemStr[0,strlen(ItemStr)-6-1]
			currentWaveIsDAC=0
		else
			currentWaveName=itemStr
			currentWaveIsDAC=1
		endif
	endif
	OutputViewerViewUpdate()
End

Function OutputViewerContSweprWavsChngd()
	// Used to notify the OV controller that the sweeper waves (may have) changed.
	OutputViewerModelSweprWavsChngd()		// Update our model
	OutputViewerViewUpdate()				// Sync the view to the model
End

