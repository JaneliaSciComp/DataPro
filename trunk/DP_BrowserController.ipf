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
		//Print "The Tools Panel says: Arghhh..."
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
	// Sync the view
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
	// changing this invalidates the fit, since now the fit trace doesn't match the fit parameters
	//Printf "About to call BrowserModelUpdateFit() in BrowserContDtFitExtendSV()\r"
	BrowserModelUpdateFit(browserNumber)  // model method
	BrowserViewModelChanged(browserNumber)	
End

Function BrowserContBaseNameSV(svStruct) : SetVariableControl
	// Called when the user changes the trace name in the control.
	STRUCT WMSetVariableAction &svStruct	
	if ( svStruct.eventCode!=2 && svStruct.eventCode!=3 && svStruct.eventCode!=6 ) 
		return 0
	endif	
	String browserName=svStruct.win
	Variable browserNumber=BrowserNumberFromName(browserName)
	BrowserModelUpdateMeasurements(browserNumber)
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContShowTraceCB(cbStruct) : CheckBoxControl
	// This is called when the user checks/unchecks the "tr.A" or "tr.B" checkboxes in a
	// DPBrowser window.  Currently, this automatically changes the DF state variables.
	STRUCT WMCheckboxAction &cbStruct
	if (cbStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif	
	Variable browserNumber=BrowserNumberFromName(cbStruct.win)	
	BrowserModelUpdateMeasurements(browserNumber)
	BrowserViewModelChanged(browserNumber)
End

//Function SetTraceAChecked(browserNumber,checked)
//	// Called to check/uncheck the trace A checkbox programmatically
//	Variable browserNumber, checked
//
//	String savedDF=ChangeToBrowserDF(browserNumber)
//	NVAR traceAChecked
//	traceAChecked=checked	
//	BrowserModelUpdateMeasurements(browserNumber)
//	BrowserViewModelChanged(browserNumber)
//	SetDataFolder savedDF
//End

//Function SetTraceBChecked(browserNumber,checked)
//	// Called to check/uncheck the trace B checkbox programmatically
//	Variable browserNumber, checked
//
//	String savedDF=ChangeToBrowserDF(browserNumber)
//	NVAR traceBChecked
//	traceBChecked=checked	
//	BrowserModelUpdateMeasurements(browserNumber)
//	BrowserViewModelChanged(browserNumber)
//	SetDataFolder savedDF
//End

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

//Function BaseSub(cbStruct) : CheckBoxControl
//	// This is called when the user checks/unchecks one of the "Base Sub" checkboxes in a
//	// DPBrowser window.
//	STRUCT WMCheckboxAction &cbStruct
//	if (cbStruct.eventCode!=2)
//		return 0							// we only handle mouse up in control
//	endif	
//	Variable browserNumber=BrowserNumberFromName(cbStruct.win)	
//	BrowserModelUpdateMeasurements(browserNumber)
//	//Printf "About to call BrowserModelUpdateFit() in BaseSub()\r"
//	BrowserModelUpdateFit(browserNumber)  // model method
//	BrowserViewModelChanged(browserNumber)
//End

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

	// Check that the cursors are actually set, otherwise return
	String browserName=BrowserNameFromNumber(browserNumber)
	if (!AreCursorsAAndBSet(browserName))
		return nan
	endif
	
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

	// Check that the cursors are actually set, otherwise return
	String browserName=BrowserNameFromNumber(browserNumber)
	if (!AreCursorsAAndBSet(browserName))
		return nan
	endif

	// Save the current data folder, change to this browser's DF
	String savedDF=ChangeToBrowserDF(browserNumber)

	// Declare DF vars we need	
	NVAR tWindow1Left, tWindow1Right
	
	// Draw vertical lines to indicate the margins of the window time range
	tWindow1Left=cursorXPosition("A",browserName)  // times of left and right cursor that delineate the window region
	tWindow1Right=cursorXPosition("B",browserName)

	// Update the meaurements
	BrowserModelUpdateMeasurements(browserNumber)

	// Update the view
	BrowserViewModelChanged(browserNumber)

	// Restore the orignal DF
	SetDataFolder savedDF	
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
	
	// Save the current data folder, change to this browser's DF
	String savedDF=ChangeToBrowserDF(browserNumber)

	// Clear limits of the window
	NVAR tWindow1Left
	NVAR tWindow1Right
	tWindow1Left=nan
	tWindow1Right=nan
	
	// Update the measurements
	BrowserModelUpdateMeasurements(browserNumber)
	
	// Update the view
	BrowserViewModelChanged(browserNumber)
	
	// Restore the orignal DF
	SetDataFolder savedDF	
End

Function BrowserContMeasurementSV(svStruct) : SetVariableControl
	// This is a generic handler for several of the measurement sub-panel
	// SetVariables.  It simply updates the measurements in the model and
	// syncs the view.
	STRUCT WMSetVariableAction &svStruct	
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif	
	Variable browserNumber=BrowserNumberFromName(svStruct.win)
	BrowserModelUpdateMeasurements(browserNumber)
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContSetWindow2Button(bStruct)
	STRUCT WMButtonAction &bStruct
	
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif

	// Get the browser number
	String measurePanelName=bStruct.win;
	Variable browserNumber=BrowserNumberFromName(measurePanelName)

	// Check that the cursors are actually set, otherwise return
	String browserName=BrowserNameFromNumber(browserNumber)
	if (!AreCursorsAAndBSet(browserName))
		return nan
	endif

	// Save the current data folder, change to this browser's DF
	String savedDF=ChangeToBrowserDF(browserNumber)

	// Set up aliases depending on nDataWindow	
	NVAR tWindow2Left, tWindow2Right
	
	// Draw vertical lines to indicate the margins of the window time range
	tWindow2Left=cursorXPosition("A",browserName)  // times of left and right cursor that delineate the window region
	tWindow2Right=cursorXPosition("B",browserName)

	// Update the measurements
	BrowserModelUpdateMeasurements(browserNumber)

	// Update the view
	BrowserViewModelChanged(browserNumber)

	// Restore the orignal DF
	SetDataFolder savedDF	
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
	
	// Save the current data folder, change to this browser's DF
	String savedDF=ChangeToBrowserDF(browserNumber)

	// Clear limits of the window
	NVAR tWindow2Left
	NVAR tWindow2Right
	tWindow2Left=nan
	tWindow2Right=nan
	
	// Update the measurements
	BrowserModelUpdateMeasurements(browserNumber)
	
	// Update the view
	BrowserViewModelChanged(browserNumber)
	
	// Restore the orignal DF
	SetDataFolder savedDF	
End

Function BrowserContSetFitZeroButton(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	
	// Get the browser number from the bStruct
	Variable browserNumber=BrowserNumberFromName(bStruct.win);
	
	// Check that the cursors are actually set, otherwise return
	String browserName=BrowserNameFromNumber(browserNumber)
	if (!IsCursorASet(browserName))
		return nan
	endif
	
	// Save the current DF, set the data folder to the appropriate one for this DataProBrowser instance
	String savedDFName=ChangeToBrowserDF(browserNumber)

	// Set the model state variable
	NVAR tFitZero=tFitZero
	tFitZero=cursorXPosition("A",browserName)
	//SVAR traceAWaveName=traceAWaveName  // actually the name of a wave, not the wave itself
	//BrowserViewAddCursorLineToGraph(browserName,"fitLineZero",tFitZero)
	//ModifyGraph rgb(fitLineZero)=(26411,1,52428)

	// Update the fit
	//Printf "About to call BrowserModelUpdateFit() in BrowserContSetFitZeroButton()\r"
	BrowserModelUpdateFit(browserNumber)
	
	// Update the view
	BrowserViewModelChanged(browserNumber)
	
	// Restore original DF
	SetDataFolder savedDFName
End

Function BrowserContClearFitZeroButton(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	
	// Get the browser number from the bStruct
	Variable browserNumber=BrowserNumberFromName(bStruct.win);
	
	// Save the current DF, set the data folder to the appropriate one for this DataProBrowser instance
	String savedDFName=ChangeToBrowserDF(browserNumber)

	// Clear the model state variable
	NVAR tFitZero
	tFitZero=nan

	// Update the fit
	BrowserModelUpdateFit(browserNumber)
	
	// Update the view
	BrowserViewModelChanged(browserNumber)
	
	// Restore original DF
	SetDataFolder savedDFName
End

Function BrowserContSetFitRangeButton(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	
	// Get the browser number from the bStruct
	Variable browserNumber=BrowserNumberFromName(bStruct.win);
	
	// Check that the cursors are actually set, otherwise return
	String browserName=BrowserNameFromNumber(browserNumber)
	if (!AreCursorsAAndBSet(browserName))
		return nan
	endif
	
	// Save the current DF, set the data folder to the appropriate one for this DataProBrowser instance
	String savedDFName=ChangeToBrowserDF(browserNumber)

	// Set fit bounds in model
	NVAR tFitLeft=tFitLeft
	tFitLeft=cursorXPosition("A",browserName)
	NVAR tFitRight=tFitRight
	tFitRight=cursorXPosition("B",browserName)

	// Update the fit
	BrowserModelUpdateFit(browserNumber)

	// Update the view
	BrowserViewModelChanged(browserNumber)
	
	// Restore original DF
	SetDataFolder savedDFName
End

Function BrowserContClearFitRangeButton(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	
	// Get the browser number from the bStruct
	Variable browserNumber=BrowserNumberFromName(bStruct.win);
	
	// Save the current DF, set the data folder to the appropriate one for this DataProBrowser instance
	String savedDFName=ChangeToBrowserDF(browserNumber)

	// Set fit bounds in model
	NVAR tFitLeft
	NVAR tFitRight
	tFitLeft=nan
	tFitRight=nan

	// Update the fit
	BrowserModelUpdateFit(browserNumber)

	// Update the view
	BrowserViewModelChanged(browserNumber)
	
	// Restore original DF
	SetDataFolder savedDFName
End

Function BrowserContFitButton(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	
	// Get the browser number from the bStruct
	Variable browserNumber=BrowserNumberFromName(bStruct.win);
	
	// Update the fit trace and fit parameters in the model
	//Printf "About to call BrowserModelUpdateFit() in BrowserContFitButton()\r"
	BrowserModelUpdateFit(browserNumber)
	
	// Sync the view to the model
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContFitTypePopup(pStruct) : PopupMenuControl
	STRUCT WMPopupAction &pStruct
	
	// Check that this is really a button-up on the menu
	if (pStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	
	// Get the browser number from the bStruct
	Variable browserNumber=BrowserNumberFromName(pStruct.win);
	
	// Update the fit trace and fit parameters in the model
	SVAR fitType
	if (pStruct.popNum==1)
		fitType="single exp";
	else
		fitType="double exp";
	endif

	// Update the fit coeffs
	//Printf "About to call BrowserModelUpdateFit() in BrowserContFitTypePopup()\r"
	BrowserModelUpdateFit(browserNumber)
	
	// Sync the view to the model
	BrowserViewModelChanged(browserNumber)
End

Function BrowserContHoldYOffsetCB(cbStruct) : CheckBoxControl
	STRUCT WMCheckboxAction &cbStruct	

	// If event is other than mouse up within control, do nothing
	if (cbStruct.eventCode!=2)
		return 0
	endif

	// Find name of browser, switch the DF to its DF, note the former DF name
	Variable browserNumber=BrowserNumberFromName(cbStruct.win)
	String savedDFName=ChangeToBrowserDF(browserNumber)

	// Get the old value
	NVAR holdYOffset  // boolean, whether or not hold the y offset at the given value
	Variable holdYOffsetOld=holdYOffset

	// Update the model variable
	holdYOffset=cbStruct.checked
	
	// If the value has not changed (however that might have happened), just return
	if ( holdYOffset==holdYOffsetOld )
		// Restore old data folder
		SetDataFolder savedDFName
		return nan;
	endif
	
	// If the checkbox has just been checked, and if the curent hold value is nan, 
	// and the current y offset is _not_ nan, copy the y offset into the hold value
	NVAR yOffsetHeldValue  // the value at which to hold the y offset
	NVAR yOffset  // the current y offset fit coefficient
	NVAR isFitValid
	if ( holdYOffset )
		// holdYOffset just turned true
		if ( IsNan(yOffsetHeldValue) )
			if ( IsNan(yOffset) )
				yOffsetHeldValue=0
			else
				yOffsetHeldValue=yOffset
			endif
		endif
		if ( isFitValid )
			if (yOffsetHeldValue==yOffset)
				// no need to invalidate in this case!
			else
				//Printf "About to call BrowserModelUpdateFit() in BrowserContHoldYOffsetCB() #1\r"
				BrowserModelUpdateFit(browserNumber)
			endif
		else
			// fit is already invalid
			//Printf "About to call BrowserModelUpdateFit() in BrowserContHoldYOffsetCB() #2\r"
			BrowserModelUpdateFit(browserNumber)
		endif			
	else
		// holdYOffset just turned false -- now the yOffset parameter is free, so a previously-valid fit 
		// is now invalid
		//yOffsetHeldValue=nan  // when made visible again, want it to get current yOffset
		//Printf "About to call BrowserModelUpdateFit() in BrowserContHoldYOffsetCB() #3\r"		
		BrowserModelUpdateFit(browserNumber)
	endif

	// Sync the the view with the current state
	BrowserViewModelChanged(browserNumber)

	// Restore old data folder
	SetDataFolder savedDFName
End

Function BrowserContYOffsetHeldValueSV(svStruct) : SetVariableControl
	STRUCT WMSetVariableAction &svStruct	
	//Printf "eventcode: %d\r", svStruct.eventCode
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif	
	String browserName=svStruct.win
	Variable browserNumber=BrowserNumberFromName(browserName)
	String savedDFName=ChangeToBrowserDF(browserNumber)
	NVAR yOffsetHeldValue
	yOffsetHeldValue=svStruct.dval  // set the model variable to the value set in the view
	// changing this invalidates the fit, since now the fit trace (if there is one) doesn't match the fit parameters
	//Printf "About to call BrowserModelUpdateFit() in BrowserContYOffsetHeldValueSV()\r"		
	BrowserModelUpdateFit(browserNumber)  // model method
	BrowserViewModelChanged(browserNumber)	
	SetDataFolder savedDFName
End

//Function SweepIndexChangedInView(browserNumber,sweepIndexInView)
//	// Tell the controller that the sweep index has been changed in the view.
//	Variable browserNumber, sweepIndexInView
//
//	// Change to the right DF
//	String savedDFName=ChangeToBrowserDF(browserNumber)
//	
//	// Set the sweep in the "model"
//	BrowserModelSetNextSweepIndex(browserNumber,sweepIndexInView)
//	
//	// Restore the original DF
//	SetDataFolder savedDFName	
//End

Function BrowserContRescaleCB(cbStruct) : CheckBoxControl
	STRUCT WMCheckboxAction &cbStruct
	if (cbStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif	
	Variable browserNumber=BrowserNumberFromName(cbStruct.win)
	BrowserViewModelChanged(browserNumber)
	//SyncDFAxesLimitsWithGraph(browserNumber)
	//BrowserViewRescaleAxes(browserNumber)
End

Function BrowserContAllSweepsCB(cbStruct) : CheckBoxControl
	STRUCT WMCheckboxAction &cbStruct
	if (cbStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif	
	Variable browserNumber=BrowserNumberFromName(cbStruct.win)
	String savedDFName=ChangeToBrowserDF(browserNumber)	
	NVAR averageAllSweeps
	averageAllSweeps=cbStruct.checked
	BrowserViewModelChanged(browserNumber)
	SetDataFolder savedDFName
End

Function BrowserContFirstSweepSV(svStruct) : SetVariableControl
	STRUCT WMSetVariableAction &svStruct	
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif	
	String browserName=svStruct.win
	Variable browserNumber=BrowserNumberFromName(browserName)
	String savedDFName=ChangeToBrowserDF(browserNumber)
	NVAR iSweepFirstAverage
	iSweepFirstAverage=svStruct.dval  // set the model variable to the value set in the view
	SetDataFolder savedDFName	
End

Function BrowserContLastSweepSV(svStruct) : SetVariableControl
	STRUCT WMSetVariableAction &svStruct	
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif	
	String browserName=svStruct.win
	Variable browserNumber=BrowserNumberFromName(browserName)
	String savedDFName=ChangeToBrowserDF(browserNumber)
	NVAR iSweepLastAverage
	iSweepLastAverage=svStruct.dval  // set the model variable to the value set in the view
	SetDataFolder savedDFName	
End

Function BrowserContAllStepsCB(cbStruct) : CheckBoxControl
	STRUCT WMCheckboxAction &cbStruct
	if (cbStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif	
	Variable browserNumber=BrowserNumberFromName(cbStruct.win)
	String savedDFName=ChangeToBrowserDF(browserNumber)	
	NVAR averageAllSteps
	averageAllSteps=cbStruct.checked
	BrowserViewModelChanged(browserNumber)
	SetDataFolder savedDFName
End

Function BrowserContStepsSV(svStruct) : SetVariableControl
	STRUCT WMSetVariableAction &svStruct	
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif	
	String browserName=svStruct.win
	Variable browserNumber=BrowserNumberFromName(browserName)
	String savedDFName=ChangeToBrowserDF(browserNumber)
	NVAR stepToAverage
	stepToAverage=svStruct.dval  // set the model variable to the value set in the view
	SetDataFolder savedDFName	
End

Function BrowserContRenameAveragesCB(cbStruct) : CheckBoxControl
	STRUCT WMCheckboxAction &cbStruct
	if (cbStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif	
	Variable browserNumber=BrowserNumberFromName(cbStruct.win)
	String savedDFName=ChangeToBrowserDF(browserNumber)	
	NVAR renameAverages
	renameAverages=cbStruct.checked
	BrowserViewModelChanged(browserNumber)
	SetDataFolder savedDFName
End

Function BrowserContAverageSweepsButton(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif

	// Get the browser number from the bStruct
	Variable browserNumber=BrowserNumberFromName(bStruct.win);		
	//String browserName=BrowserNameFromNumber(browserNumber)
	
	// Save the current DF, set the data folder to the appropriate one for this DataProBrowser instance
	String savedDFName=ChangeToBrowserDF(browserNumber)
	
	// Determine the range of sweeps present
	Variable nSweeps=BrowserModelGetNSweeps(browserNumber)
	
	// determine which sweeps we're going to average, of those present
	NVAR averageAllSweeps
	NVAR iSweepLastAverage
	NVAR iSweepFirstAverage
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
	SVAR baseNameA
	SVAR baseNameB
	NVAR averageAllSteps
	NVAR traceAChecked
	NVAR traceBChecked	
	Variable filterOnHold=0	// there used to by UI to filter on the holding level
	Variable holdCenter=nan
	Variable holdTol=nan
	Variable filterOnStep=!averageAllSteps
	NVAR stepToAverage
	if (traceAChecked)
		BrowserContComputeAverageWaves(browserNumber,destSweepIndex,baseNameA,iFrom,iTo,filterOnHold,holdCenter,holdTol,filterOnStep,stepToAverage)
	endif
	if (traceBChecked)
		BrowserContComputeAverageWaves(browserNumber,destSweepIndex,baseNameB,iFrom,iTo,filterOnHold,holdCenter,holdTol,filterOnStep,stepToAverage)
	endif			

	// increment the next sweep index for acquisition	
	if (traceAChecked || traceBChecked)
		SweeperContIncrNextSweepIndex()
	endif
	
	// Restore original DF
	SetDataFolder savedDFName
End

Function BrowserContComputeAverageWaves(browserNumber,destSweepIndex,waveBaseName,iFrom,iTo,filterOnHold,holdCenter,holdTol,filterOnStep,stepToAverage)
	Variable browserNumber
	Variable destSweepIndex
	String waveBaseName
	Variable iFrom, iTo
	Variable filterOnHold	// boolean
	Variable holdCenter, holdTol
	Variable filterOnStep	// boolean
	Variable stepToAverage

	// Save the current DF, set the data folder to the appropriate one for this DataProBrowser instance
	String savedDFName=ChangeToBrowserDF(browserNumber)

	// Figure the destination wave name
	String destWaveName = sprintf2sv("root:%s_%d", waveBaseName, destSweepIndex)
	
	// Handle possible renaming of the dest wave
	NVAR renameAverages
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
			return 0		// Have to return something
		endif
	endif
	
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
	//String waveBaseNameShort=RemoveEnding(waveBaseName,"_")
	if (nWavesToAvg>0)
		outWave /= nWavesToAvg
	else
		String message=sprintf1s("%s: No waves met your criteria to be averaged.", waveBaseName)
		Abort message
	endif
	Printf "%d sweeps of %s were averaged and stored in %s\r", nWavesToAvg, waveBaseName, destWaveName
		
	// Restore original DF
	SetDataFolder savedDFName	
End

Function BrowserContTraceAColorPopup(pStruct) : PopupMenuControl
	STRUCT WMPopupAction &pStruct
	// Check that this is really a button-up on the button
	if (pStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	// Get the browser number from the pStruct
	Variable browserNumber=BrowserNumberFromName(pStruct.win);		
	// Save the current DF, set the data folder to the appropriate one for this DataProBrowser instance
	String savedDFName=ChangeToBrowserDF(browserNumber)
	// Notify the model
	SVAR colorNameA
	colorNameA=pStruct.popStr
	// Notify the view
	BrowserViewModelChanged(browserNumber)
	// Restore original DF
	SetDataFolder savedDFName		
End

Function BrowserContTraceBColorPopup(pStruct) : PopupMenuControl
	STRUCT WMPopupAction &pStruct
	// Check that this is really a button-up on the button
	if (pStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	// Get the browser number from the pStruct
	Variable browserNumber=BrowserNumberFromName(pStruct.win);		
	// Save the current DF, set the data folder to the appropriate one for this DataProBrowser instance
	String savedDFName=ChangeToBrowserDF(browserNumber)
	// Notify the model
	SVAR colorNameB
	colorNameB=pStruct.popStr
	// Notify the view
	BrowserViewModelChanged(browserNumber)
	// Restore original DF
	SetDataFolder savedDFName		
End


