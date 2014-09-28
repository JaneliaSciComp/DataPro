//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

Function OutputViewerViewConstructor() : Graph
	if (GraphExists("OutputViewerView"))
		DoWindow /F OutputViewerView
		return 0
	endif
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_OutputViewer
	Display /W=(100,150,700,400) /K=1 /N=OutputViewerView as "Output Viewer"
	PopupMenu wavePopup,win=OutputViewerView, pos={650,20},size={115,20},bodyWidth=115,proc=OutputViewerContWavePopup
	OutputViewerContSweprWavsChngd()
	SetDataFolder savedDF	
End

Function OutputViewerViewUpdate()
	// Used to notify the view that the model has changed.
	// Causes the view to re-sync with the model.
	if (!GraphExists("OutputViewerView"))
		return 0		// Have to return something
	endif
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_OutputViewer
	
	SVAR stimWaveNames
	SVAR ttlWaveNames
	SVAR currentWaveName
	NVAR currentWaveIsDAC	
	
	Variable nWavesDAC=ItemsInList(stimWaveNames)
	Variable nWavesTTL=ItemsInList(ttlWaveNames)
	Variable nWaves=nWavesDAC+nWavesTTL
	String popupItems=OutputViewerModelGetPopupItems()
	String currentPopupItem
	if (nWaves==0)
		currentPopupItem="(none)"
		RemoveFromGraph /Z /W=OutputViewerView $"#0"
		// The graph now has zero waves showing
	else
		if (currentWaveIsDAC)
			currentPopupItem=currentWaveName
			Duplicate /O SweeperGetDACWaveByName(currentWaveName) currentWave
		else
			currentPopupItem=currentWaveName+" (TTL)"
			Duplicate /O SweeperGetTTLWaveByName(currentWaveName) currentWave
		endif
		AppendToGraph /W=OutputViewerView currentWave
		ModifyGraph /W=OutputViewerView grid(left)=1  // put the grid back
		Label /W=OutputViewerView /Z bottom "Time (ms)"
		Label /W=OutputViewerView /Z left currentWaveName+" (pure)"
		// Don't want units in tic marks
		ModifyGraph /W=OutputViewerView /Z tickUnit(bottom)=1
		ModifyGraph /W=OutputViewerView /Z tickUnit(left)=1
	endif
	String popupItemsStupidized="\""+popupItems+"\""
	PopupMenu wavePopup,win=OutputViewerView,value=#popupItemsStupidized
	PopupMenu wavePopup,win=OutputViewerView,popmatch=currentPopupItem
	SetDataFolder savedDF		
End

