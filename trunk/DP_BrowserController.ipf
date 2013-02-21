#pragma rtGlobals=1		// Use modern global access method.

Function BrowserContConstructor(whatToDo)
	String whatToDo
	Variable browserNumber
	if (AreStringsEqual(whatToDo,"New"))
		browserNumber=BrowserModelConstructor();
		BrowserViewConstructor(browserNumber)
	elseif (AreStringsEqual(whatToDo,"NewOnlyIfNone"))
		String DPBrowserList=WinList("DataProBrowser*",";","WIN:1")		// 1 means graphs
		Variable nDPBrowsers=ItemsInList(DPBrowserList)
		if (nDPBrowsers==0)
			browserNumber=BrowserContConstructor("New")
		else
			browserNumber=LargestBrowserNumber()
			String browserName=BrowserNameFromNumber(browserNumber)
			DoWindow /F $browserName
		endif
	endif
	return browserNumber
End

Function BrowserContHook(s)
	// Hook function on the browser window that allows us to detect certain events and 
	// update the model and/or view appropriately
	STRUCT WMWinHookStruct &s
	
	String browserName=s.winName
	Variable browserNumber=BrowserNumberFromName(browserName)
	String browserDFName=BrowserDFNameFromNumber(browserNumber)
	
	String satelliteWindowName
	String savedDFName
	if (s.eventCode==2)					// window being killed
		//Print "Arghhh..."
		// Kill the data folder
		KillDataFolder /Z $browserDFName
	elseif (s.eventCode==7)			// cursor moved (or placed)
		savedDFName=ChangeToBrowserDF(browserNumber)	
		String cursorName=s.cursorName
		NVAR tCursorA
		NVAR tCursorB
		if ( AreStringsEqual(cursorName,"A") )
			tCursorA=cursorXPosition("A",browserName)
		elseif ( AreStringsEqual(cursorName,"B") )
			tCursorB=cursorXPosition("B",browserName)
		endif
		SetDataFolder savedDFName
	elseif (s.eventCode==8)			// graph modified
		// We catch this b/c we need to know if the y axis limits change
		savedDFName=ChangeToBrowserDF(browserNumber)
		NVAR yAMin
		NVAR yAMax
		NVAR yBMin
		NVAR yBMax
		NVAR xMin
		NVAR xMax
		GetAxis /W=$browserName /Q left
		if (V_flag==0)  // V_flag will be zero if the axis actually exists
			yAMin=V_min
			yAMax=V_max
		endif
		GetAxis /W=$browserName /Q right
		if (V_flag==0)  // V_flag will be zero if the axis actually exists
			yBMin=V_min
			yBMax=V_max
		endif
		GetAxis /W=$browserName /Q bottom
		if (V_flag==0)  // V_flag will be zero if the axis actually exists
			xMin=V_min
			xMax=V_max
		endif
		SetDataFolder savedDFName
	endif

	return 0		// If non-zero, we handled event and Igor will ignore it.
End

Function BrowserContToolsPanelHook(s)
	// Hook function on the tool panel, allows us to catch certain events
	// and maintain UI consistency when they happen.
	STRUCT WMWinHookStruct &s
	
	String panelName=s.winName
	String browserName=RootWindowName(panelName)
	Variable browserNumber=BrowserNumberFromName(browserName)
	if (s.eventCode==2)					// window being killed
		// Need to uncheck the "Show Tools" checkbox
		CheckBox showToolsCheckbox, win=$browserName, value=0
	endif	
	
	return 0		// If non-zero, we handled event and Igor will ignore it.
End

Function BrowserContSetNextSweepIndex(browserNumber,iSweep)
	// Just what it says on the tin.  Called by the data acquisition loop when a sweep is acquired.
	// Set the sweep in the model
	Variable browserNumber, iSweep
	BrowserModelSetNextSweepIndex(browserNumber,iSweep)
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContNextSweepIndexSV(svStruct) : SetVariableControl
	// Called when the user changes the sweep number in the DPBrowser, 
	// which first changes iCurrentSweep.
	STRUCT WMSetVariableAction &svStruct	
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif	
	String browserName=svStruct.win
	Variable iSweepInView=svStruct.dval
	Variable browserNumber=BrowserNumberFromName(browserName)
	// Set the sweep in the model
	BrowserModelSetNextSweepIndex(browserNumber,iSweepInView)
	// Sync the view
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContCommentsSV(svStruct) : SetVariableControl
	// Called when the user changes the comment in the DPBrowser
	STRUCT WMSetVariableAction &svStruct	
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif
	String browserName=svStruct.win
	Variable browserNumber=BrowserNumberFromName(browserName)
	String commentsInControl=svStruct.sval
	// Set the wave comment for the top wave to commentInControl
	String topTraceWaveNameAbs=BrowserModelGetTopWaveNameAbs(browserNumber)
	if ( strlen(topTraceWaveNameAbs)>0 )
		ReplaceStringByKeyInWaveNote($topTraceWaveNameAbs,"COMMENTS",commentsInControl)
	endif
	// Sync the view -- necessary when no trace is selected, to clear the comment
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContDtFitExtendSV(svStruct) : SetVariableControl
	STRUCT WMSetVariableAction &svStruct	
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif	
	String browserName=svStruct.win
	Variable browserNumber=BrowserNumberFromName(browserName)
	BrowserModelSetDtFitExtend(browserNumber,svStruct.dval)
	BrowserViewModelChanged(browserNumber)	
End

Function BrowserContBaseNameASV(svStruct) : SetVariableControl
	// Called when the user changes the trace name in the control.
	STRUCT WMSetVariableAction &svStruct	
	if ( svStruct.eventCode!=2 && svStruct.eventCode!=3 && svStruct.eventCode!=6 ) 
		return 0
	endif
	String browserName=svStruct.win
	Variable browserNumber=BrowserNumberFromName(browserName)
	BrowserModelSetBaseNameA(browserNumber,svStruct.sval)
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContBaseNameBSV(svStruct) : SetVariableControl
	// Called when the user changes the trace name in the control.
	STRUCT WMSetVariableAction &svStruct	
	if ( svStruct.eventCode!=2 && svStruct.eventCode!=3 && svStruct.eventCode!=6 ) 
		return 0
	endif
	String browserName=svStruct.win
	Variable browserNumber=BrowserNumberFromName(browserName)
	BrowserModelSetBaseNameB(browserNumber,svStruct.sval)
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContShowTraceACB(cbStruct) : CheckBoxControl
	// This is called when the user checks/unchecks the "tr.A" checkbox in a
	// DPBrowser window.
	STRUCT WMCheckboxAction &cbStruct
	if (cbStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif	
	Variable browserNumber=BrowserNumberFromName(cbStruct.win)	
	BrowserModelSetTraceAChecked(browserNumber,cbStruct.checked)
	//BrowserModelUpdateMeasurements(browserNumber)
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContShowTraceBCB(cbStruct) : CheckBoxControl
	// This is called when the user checks/unchecks the "tr.B" checkbox in a
	// DPBrowser window.
	STRUCT WMCheckboxAction &cbStruct
	if (cbStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif	
	Variable browserNumber=BrowserNumberFromName(cbStruct.win)	
	BrowserModelSetTraceBChecked(browserNumber,cbStruct.checked)
	//BrowserModelUpdateMeasurements(browserNumber)
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContRejectTraceACB(cbStruct) : CheckBoxControl
	STRUCT WMCheckboxAction &cbStruct
	if (cbStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif	
	Variable browserNumber=BrowserNumberFromName(cbStruct.win)	
	String traceAWaveNameAbs=BrowserModelGetAWaveNameAbs(browserNumber)
	ReplaceStringByKeyInWaveNote($traceAWaveNameAbs,"REJECT",num2str(cbStruct.checked))
End

Function BrowserContRejectTraceBCB(cbStruct) : CheckBoxControl
	STRUCT WMCheckboxAction &cbStruct
	if (cbStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif	
	Variable browserNumber=BrowserNumberFromName(cbStruct.win)	
	String traceBWaveNameAbs=BrowserModelGetBWaveNameAbs(browserNumber)
	ReplaceStringByKeyInWaveNote($traceBWaveNameAbs,"REJECT",num2str(cbStruct.checked))
End

Function BrowserContShowToolsPanelCB(cbStruct) : CheckboxControl
	// This is called when the user checks/unchecks the "Show tools" checkbox in a
	// DPBrowser window.
	STRUCT WMCheckboxAction &cbStruct
	if (cbStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif	
	Variable browserNumber=BrowserNumberFromName(cbStruct.win)
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContSetBaselineButton(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	
	// Get the browser number from the bStruct
	String measurePanelName=bStruct.win;
	Variable browserNumber=BrowserNumberFromName(measurePanelName);

	// Notify the model
	BrowserModelSetBaseline(browserNumber)

	// Update the view
	BrowserViewModelChanged(browserNumber)	
End

Function BrowserContClearBaselineButton(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	
	// Get the browser number from the bStruct
	String measurePanelName=bStruct.win;
	Variable browserNumber=BrowserNumberFromName(measurePanelName);
	
	// Clear the baseline limits in the model
	BrowserModelClearBaseline(browserNumber)
	
	// Update the view
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContSetWindow1Button(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif

	// Get the browser number
	String measurePanelName=bStruct.win;
	Variable browserNumber=BrowserNumberFromName(measurePanelName)

	// Set the window in the model
	BrowserModelSetWindow1(browserNumber)

	// Update the view
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContClearWindow1Button(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	
	// Get the browser number from the bStruct
	String measurePanelName=bStruct.win;
	Variable browserNumber=BrowserNumberFromName(measurePanelName);
	
	// Clear limits of the window
	BrowserModelClearWindow1(browserNumber)

	// Update the view
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContLevel1SV(svStruct) : SetVariableControl
	STRUCT WMSetVariableAction &svStruct	
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif	
	Variable browserNumber=BrowserNumberFromName(svStruct.win)
	BrowserModelSetLevel1(browserNumber,svStruct.dval)
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContTo1SV(svStruct) : SetVariableControl
	STRUCT WMSetVariableAction &svStruct	
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif	
	Variable browserNumber=BrowserNumberFromName(svStruct.win)
	BrowserModelSetTo1(browserNumber,svStruct.dval)
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContFrom1SV(svStruct) : SetVariableControl
	STRUCT WMSetVariableAction &svStruct	
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif	
	Variable browserNumber=BrowserNumberFromName(svStruct.win)
	BrowserModelSetFrom1(browserNumber,svStruct.dval)
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContTo2SV(svStruct) : SetVariableControl
	STRUCT WMSetVariableAction &svStruct	
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif	
	Variable browserNumber=BrowserNumberFromName(svStruct.win)
	BrowserModelSetTo2(browserNumber,svStruct.dval)
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContFrom2SV(svStruct) : SetVariableControl
	STRUCT WMSetVariableAction &svStruct	
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif	
	Variable browserNumber=BrowserNumberFromName(svStruct.win)
	BrowserModelSetFrom2(browserNumber,svStruct.dval)
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContSetWindow2Button(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif

	// Get the browser number
	String measurePanelName=bStruct.win;
	Variable browserNumber=BrowserNumberFromName(measurePanelName)

	// Set the window in the model
	BrowserModelSetWindow2(browserNumber)

	// Update the view
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContClearWindow2Button(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	
	// Get the browser number from the bStruct
	String measurePanelName=bStruct.win;
	Variable browserNumber=BrowserNumberFromName(measurePanelName);
	
	// Clear limits of the window
	BrowserModelClearWindow2(browserNumber)

	// Update the view
	BrowserViewModelChanged(browserNumber)
End



// Fitting UI

Function BrowserContSetFitZeroButton(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	Variable browserNumber=BrowserNumberFromName(bStruct.win);
	BrowserModelSetFitZero(browserNumber)
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContClearFitZeroButton(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	Variable browserNumber=BrowserNumberFromName(bStruct.win);
	BrowserModelClearFitZero(browserNumber)
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContSetFitRangeButton(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	Variable browserNumber=BrowserNumberFromName(bStruct.win);
	BrowserModelSetFitRange(browserNumber)
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContClearFitRangeButton(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	Variable browserNumber=BrowserNumberFromName(bStruct.win);
	BrowserModelClearFitRange(browserNumber)
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContFitButton(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	Variable browserNumber=BrowserNumberFromName(bStruct.win);
	BrowserModelDoFit(browserNumber)
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContFitTypePopup(pStruct) : PopupMenuControl
	STRUCT WMPopupAction &pStruct
	if (pStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	Variable browserNumber=BrowserNumberFromName(pStruct.win);
	BrowserModelSetFitType(browserNumber,pStruct.popstr)
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContHoldYOffsetCB(cbStruct) : CheckBoxControl
	STRUCT WMCheckboxAction &cbStruct	
	if (cbStruct.eventCode!=2)
		return 0
	endif
	Variable browserNumber=BrowserNumberFromName(cbStruct.win)
	BrowserModelSetHoldYOffset(browserNumber,cbStruct.checked)
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContYOffsetHeldValueSV(svStruct) : SetVariableControl
	STRUCT WMSetVariableAction &svStruct	
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif	
	String browserName=svStruct.win
	Variable browserNumber=BrowserNumberFromName(browserName)
	BrowserModelSetYOffsetHeldValue(browserNumber,svStruct.dval)
	BrowserViewModelChanged(browserNumber)	
End

Function BrowserContRescaleCB(cbStruct) : CheckBoxControl
	STRUCT WMCheckboxAction &cbStruct
	if (cbStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif	
	Variable browserNumber=BrowserNumberFromName(cbStruct.win)
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContAllSweepsCB(cbStruct) : CheckBoxControl
	STRUCT WMCheckboxAction &cbStruct
	if (cbStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif	
	Variable browserNumber=BrowserNumberFromName(cbStruct.win)
	BrowserModelSetAverageAllSweeps(browserNumber,cbStruct.checked)
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContFirstSweepSV(svStruct) : SetVariableControl
	STRUCT WMSetVariableAction &svStruct	
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif	
	String browserName=svStruct.win
	Variable browserNumber=BrowserNumberFromName(browserName)
	BrowserModelSetISweepFirstAvg(browserNumber,svStruct.dval)
End

Function BrowserContLastSweepSV(svStruct) : SetVariableControl
	STRUCT WMSetVariableAction &svStruct	
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif	
	String browserName=svStruct.win
	Variable browserNumber=BrowserNumberFromName(browserName)
	BrowserModelSetISweepLastAvg(browserNumber,svStruct.dval)
End

Function BrowserContAllStepsCB(cbStruct) : CheckBoxControl
	STRUCT WMCheckboxAction &cbStruct
	if (cbStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif	
	Variable browserNumber=BrowserNumberFromName(cbStruct.win)
	BrowserModelSetAverageAllSteps(browserNumber,cbStruct.checked)
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContStepsSV(svStruct) : SetVariableControl
	STRUCT WMSetVariableAction &svStruct	
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif	
	String browserName=svStruct.win
	Variable browserNumber=BrowserNumberFromName(browserName)
	BrowserModelSetStepToAverage(browserNumber,svStruct.dval)
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContRenameAveragesCB(cbStruct) : CheckBoxControl
	STRUCT WMCheckboxAction &cbStruct
	if (cbStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif	
	Variable browserNumber=BrowserNumberFromName(cbStruct.win)
	BrowserModelSetRenameAverages(browserNumber,cbStruct.checked)
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContTraceAColorPopup(pStruct) : PopupMenuControl
	STRUCT WMPopupAction &pStruct
	if (pStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	Variable browserNumber=BrowserNumberFromName(pStruct.win);		
	BrowserModelSetColorNameA(browserNumber,pStruct.popStr)
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContTraceBColorPopup(pStruct) : PopupMenuControl
	STRUCT WMPopupAction &pStruct
	if (pStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	Variable browserNumber=BrowserNumberFromName(pStruct.win);		
	BrowserModelSetColorNameB(browserNumber,pStruct.popStr)
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContAverageSweepsButton(bStruct) : ButtonControl
	// Calculate the average of the appropriate sweeps
	STRUCT WMButtonAction &bStruct
	
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif

	// Get the browser number from the bStruct
	Variable browserNumber=BrowserNumberFromName(bStruct.win);		
	//String browserName=BrowserNameFromNumber(browserNumber)
	
	// Determine the range of sweeps present
	Variable nSweeps=BrowserModelGetNSweeps(browserNumber)
	
	// Determine which sweeps we're going to average, of those present
	Variable averageAllSweeps=BrowserModelGetAverageAllSweeps(browserNumber)
	Variable iSweepLastAverage=BrowserModelGetISweepLastAvg(browserNumber)
	Variable iSweepFirstAverage=BrowserModelGetISweepFirstAvg(browserNumber)
	Variable iFrom, iTo
	if (averageAllSweeps)
		iFrom=1
		iTo=nSweeps
	else
		iFrom=max(1,iSweepFirstAverage)
		iTo=min(iSweepLastAverage,nSweeps)
	endif
	
	// Figure the dest wave name
	Variable destSweepIndex=SweeperGetNextSweepIndex()
	
	// Do the average(s)
	String baseNameA=BrowserModelGetBaseNameA(browserNumber)
	String baseNameB=BrowserModelGetBaseNameB(browserNumber)
	Variable averageAllSteps=BrowserModelGetAverageAllSteps(browserNumber)
	Variable traceAChecked=BrowserModelGetTraceAChecked(browserNumber)
	Variable traceBChecked=BrowserModelGetTraceBChecked(browserNumber)
	Variable filterOnHold=0	// there used to be UI to filter on the holding level
	Variable holdCenter=nan
	Variable holdTol=nan
	Variable filterOnStep=!averageAllSteps
	Variable stepToAverage=BrowserModelGetStepToAverage(browserNumber)
	String destWaveName=""
	Variable cancelled=0
	if (traceAChecked)
		destWaveName=BrowserContFigureDestWaveName(browserNumber,destSweepIndex,baseNameA)
		if (IsEmptyString(destWaveName))
			cancelled=0
		else
			BrowserContComputeAverageWaves(destWaveName,baseNameA,iFrom,iTo,filterOnHold,holdCenter,holdTol,filterOnStep,stepToAverage)
		endif
	endif
	if (!cancelled && traceBChecked)
		destWaveName=BrowserContFigureDestWaveName(browserNumber,destSweepIndex,baseNameB)
		if (IsEmptyString(destWaveName))
			cancelled=0
		else
			BrowserContComputeAverageWaves(destWaveName,baseNameB,iFrom,iTo,filterOnHold,holdCenter,holdTol,filterOnStep,stepToAverage)
		endif
	endif			

	// increment the next sweep index for acquisition, if appropriate
	Variable renameAverages=BrowserModelGetRenameAverages(browserNumber)
	if (!renameAverages && (traceAChecked || traceBChecked) )
		SweeperContIncrNextSweepIndex()
	endif
	
	// Notify the view, mainly because the valid range of the sweep index SV may have changed
	BrowserViewModelChanged(browserNumber)
End

Function /S BrowserContFigureDestWaveName(browserNumber,destSweepIndex,waveBaseName)
	Variable browserNumber
	Variable destSweepIndex
	String waveBaseName

	// Figure the destination wave name
	String destWaveName = sprintf2sv("root:%s_%d", waveBaseName, destSweepIndex)
	
	// Handle possible renaming of the dest wave
	Variable renameAverages=BrowserModelGetRenameAverages(browserNumber)
	if (renameAverages)
		String waveBaseNameAlternate, waveNameAlternate
		Variable haveValidWaveName=0
		Variable cancelled=0
		do
			Prompt waveBaseNameAlternate, sprintf1s("Name of destination wave for average of selected %s sweeps: ",waveBaseName)
			DoPrompt "Enter name of destination wave", waveBaseNameAlternate
			if (V_flag)
				// This means the user clicked "Cancel"
				cancelled=1
			else
				// This means the user clicked "Continue"
				// Test that what the user gave us is a valid wave name
				if ( IsStandardName(waveBaseNameAlternate) )
					haveValidWaveName=1					
					// If a wave by that name already exists, make sure it's OK to overwrite it
					waveNameAlternate=sprintf1s("root:%s", waveBaseNameAlternate)
					if ( exists(waveNameAlternate)==1 )
						// Wave by that name already exists
						DoAlert /T="Overwrite existing wave?" 2, sprintf1s("%s already exists.  Overwrite?",waveNameAlternate)
						if (V_flag!=1)
							// User said no, don't overwrite, or hit Cancel
							cancelled=1
						endif
					endif
				else
					haveValidWaveName=0
				endif
			endif
		while ( !haveValidWaveName && !cancelled)
		if (haveValidWaveName && !cancelled)
			destWaveName=waveNameAlternate
		else
			// Cancelled
			return ""		// Indicates cancellation
		endif
	endif
	
	return destWaveName
End

Function BrowserContComputeAverageWaves(destWaveName,waveBaseName,iFrom,iTo,filterOnHold,holdCenter,holdTol,filterOnStep,stepToAverage)
	// Compute the average of waves.
	// Note that this is a class method.
	String destWaveName
	String waveBaseName	
	Variable iFrom, iTo
	Variable filterOnHold	// boolean
	Variable holdCenter, holdTol
	Variable filterOnStep	// boolean
	Variable stepToAverage

	// Loop over waves to be averaged, forming the sum and counting the number of waves
	Variable i, nWavesSummedSoFar=0
	Variable include
	for (i=iFrom; i<=iTo; i+=1)
		String thisWaveName=sprintf2sv("root:%s_%d", waveBaseName, i)
		WAVE thisWave=$thisWaveName
		include=BrowserModelIncludeInAverage(thisWaveName,filterOnHold,holdCenter,holdTol,filterOnStep,stepToAverage)
		if (include)
			if (nWavesSummedSoFar==0)
				Duplicate /O thisWave $destWaveName
				WAVE outWave=$destWaveName
				Note /K outWave
				ReplaceStringByKeyInWaveNote(outWave,"WAVETYPE","average")
				ReplaceStringByKeyInWaveNote(outWave,"TIME",time())
				//ReplaceStringByKeyInWaveNote(outWave,"DONTAVG","1")  // redundant b/c already marked as an average
				ReplaceStringByKeyInWaveNote(outWave,"STEP",num2str(stepToAverage))
				outwave = 0
			endif
			outWave += thisWave
			nWavesSummedSoFar += 1
		endif
	endfor
	Variable nWavesToAvg=nWavesSummedSoFar
	
	// Actually compute the average from the sum
	if (nWavesToAvg>0)
		outWave /= nWavesToAvg
	else
		String message=sprintf1s("%s: No waves met your criteria to be averaged.", waveBaseName)
		Abort message
	endif
	Printf "%d sweeps of %s were averaged and stored in %s\r", nWavesToAvg, waveBaseName, destWaveName
End

