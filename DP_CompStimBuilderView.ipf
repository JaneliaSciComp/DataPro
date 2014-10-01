#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function CSBViewConstructor() : Graph
	// If the view already exists, just raise it
	if (GraphExists("CompStimBuilderView"))
		DoWindow /F CompStimBuilderView
		return 0
	endif

	// Save, set the DF
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_CompStimBuilder

	WAVE theWave

	// Window position and dimension, in pixels
	Variable xOffset=105
	Variable yOffset=200
	Variable width=1400
	Variable height=420

	// Convert dimensions to points
	Variable pointsPerPixel=72/ScreenResolution
	Variable xOffsetInPoints=pointsPerPixel*xOffset
	Variable yOffsetInPoints=pointsPerPixel*yOffset
	Variable widthInPoints=pointsPerPixel*width
	Variable heightInPoints=pointsPerPixel*height
	Display /W=(xOffsetInPoints,yOffsetInPoints,xOffsetInPoints+widthInPoints,yOffsetInPoints+heightInPoints) /K=1 /N=CompStimBuilderView theWave as "Stimulus Builder"
	ModifyGraph /W=CompStimBuilderView /Z grid(left)=1
	Label /W=CompStimBuilderView /Z bottom "Time (ms)"
	Label /W=CompStimBuilderView /Z left "Signal (pure)"
	ModifyGraph /W=CompStimBuilderView /Z tickUnit(bottom)=1
	ModifyGraph /W=CompStimBuilderView /Z tickUnit(left)=1
	//ControlBar /W=CompStimBuilderView 80

	// Control positions and dimension, in pixels
	Variable leftButtonsXOffset=width-205
	Variable rightButtonsXOffset=width-100
	Variable topButtonsYOffset=10
	Variable bottomButtonsYOffset=45
	Variable buttonWidth=90
	Variable buttonHeight=24
	Variable leftOfSignalTypeLabelSpace=6
	Variable signalTypeRowYOffset=8
	Variable yShimPopup= -4
	Variable widthBetweenSigTypeLabelAndPM=5

	// Fixed controls
	TitleBox signalTypeLabelTB, win=CompStimBuilderView, pos={leftOfSignalTypeLabelSpace,signalTypeRowYOffset}, frame=0, title="Signal Type:"
	ControlUpdate /W=CompStimBuilderView signalTypeLabelTB
	Variable sigTypeLabelRightX=GetControlRightX("CompStimBuilderView","signalTypeLabelTB")
	PopupMenu signalTypePopupMenu, win=CompStimBuilderView, bodyWidth=70, proc=CSBContSignalTypePMActuated
	ControlUpdate /W=CompStimBuilderView signalTypePopupMenu
	PopupMenu signalTypePopupMenu, win=CompStimBuilderView, pos={sigTypeLabelRightX+widthBetweenSigTypeLabelAndPM,signalTypeRowYOffset+yShimPopup}
	String listOfSignalTypes=CSBModelGetListOfSignalTypes()
	String listOfSignalTypesFU="\""+listOfSignalTypes+"\""
	PopupMenu signalTypePopupMenu, win=CompStimBuilderView, value=#listOfSignalTypesFU

	Button addSegmentButton, win=CompStimBuilderView, pos={leftButtonsXOffset,topButtonsYOffset}, size={buttonWidth,buttonHeight}, proc=CSBContAddSegButtonPressed, title="Add Segment"
	Button deleteSegmentButton, win=CompStimBuilderView, pos={leftButtonsXOffset,bottomButtonsYOffset}, size={buttonWidth,buttonHeight}, proc=CSBContDelSegButtonPressed, title="Delete Segment"
	Button saveAsDACButton, win=CompStimBuilderView, pos={rightButtonsXOffset,topButtonsYOffset}, size={buttonWidth,buttonHeight}, proc=CSBContSaveAsButtonPressed, title="Save As..."
	Button importButton, win=CompStimBuilderView, pos={rightButtonsXOffset,bottomButtonsYOffset}, size={buttonWidth,buttonHeight}, proc=CSBContImportButtonPressed, title="Import..."

	// Update everything
	CSBViewUpdate()

	SetDataFolder savedDF
End


Function CSBViewUpdate()
	// If the view doesn't exist, just return
	String windowName="CompStimBuilderView"
	if (!GraphExists(windowName))
		return 0		// Have to return something
	endif

	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_CompStimBuilder
	
	CSBViewUpdateWhichControlsExist()
	CSBViewLayout()
	CSBViewUpdateControlProperties()
	
	SetDataFolder savedDF
End


Function CSBViewUpdateWhichControlsExist()
	// If the view doesn't exist, just return
	String windowName="CompStimBuilderView"
	if (!GraphExists(windowName))
		return 0		// Have to return something
	endif

	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_CompStimBuilder

	WAVE theWave

	// Delete all existing controls, except the fixed ones
	String listOfControlNames=ControlNameList("CompStimBuilderView")
	Wave /T waveOfControlNames=TextWaveFromList(listOfControlNames)
	Variable nControls=numpnts(waveOfControlNames)
	Variable i
	for (i=0; i<nControls; i+=1)
		String thisControlName=waveOfControlNames[i]
		if ( AreStringsEqual(thisControlName,"signalTypeLabelTB") || AreStringsEqual(thisControlName,"signalTypePopupMenu") || AreStringsEqual(thisControlName, "addSegmentButton") || AreStringsEqual(thisControlName, "deleteSegmentButton") || AreStringsEqual(thisControlName, "saveAsDACButton") || AreStringsEqual(thisControlName, "importButton") )
			// do nothing
		else
			KillControl /W=CompStimBuilderView $(waveOfControlNames[i])
		endif
	endfor

	// Create the proper controls
	Wave /T compStim=CompStimWaveGetCompStim(theWave)
	Variable nSimpStims=CompStimGetNStimuli(compStim)

	for (i=0; i<nSimpStims; i+=1)
		// The segment label
	 	String tbName=sprintf1v("segment_%d_TB",i)
	 	String segmentLabel=sprintf1v("Segment %d:",i+1)
		TitleBox $tbName, win=CompStimBuilderView, frame=0, title=segmentLabel
		
		// The segment type popup
	 	String popupMenuName=sprintf1v("segment_%d_PM",i)		
		PopupMenu $popupMenuName, win=CompStimBuilderView, proc=CSBContSegmentTypePMActuated
	
		// The row of SetVariables, one per parameter
		String simpStim=CompStimGetSimpStim(compStim,i)
		String simpStimType=SimpStimGetStimType(simpStim)
		
		// Get the param names for this segment type
		String getParamNamesFuncName=simpStimType+"GetParamNames"
		Funcref SSTGetParamNamesFallback getParamNames=$getParamNamesFuncName
		Wave /T paramNames=getParamNames()

		// Get the display param names for this segment type
		String getParamDisplayNamesFuncName=simpStimType+"GetParamDispNames"
		Funcref SSTGetParamDispNamesFallback getParamDisplayNames=$getParamDisplayNamesFuncName
		Wave /T paramDisplayNames=getParamDisplayNames()

		// Get the parameter units for this segment type
		String getParamUnitsFuncName=simpStimType+"GetParamUnits"
		Funcref SSTGetParamUnitsFallback getParamUnits=$getParamUnitsFuncName
		Wave /T paramUnits=getParamUnits()

		// For each parameter, create the controls for it
		Variable nParams=numpnts(paramNames)
		Variable j
		for (j=0; j<nParams; j+=1)
			// the SV
			String paramName=paramNames[j]
			String svName=sprintf2vs("segment_%d_%s_SV",i,paramName)
			String paramDisplayName=paramDisplayNames[j]
			String paramLabel=sprintf1s("%s:",paramDisplayName)
			SetVariable $svName, win=CompStimBuilderView, title=paramLabel, limits={-inf,+inf,1}, proc=CSBContParamSVActuated
			
			// the TitleBox containing the units
			String unitsTBName=sprintf2vs("segment_%d_%s_units_TB",i,paramName)
			String thisParamUnits=stringFif( IsEmptyString(paramUnits[j]), " ", paramUnits[j])		// Grrr: TBs have default width of 50 if the title is empty...
			TitleBox $unitsTBName, win=CompStimBuilderView, frame=0, title=thisParamUnits
		endfor
	endfor	
	
	SetDataFolder savedDF	
End

Function CSBViewLayout()
	// If the view doesn't exist, just return
	String windowName="CompStimBuilderView"
	if (!GraphExists(windowName))
		return 0		// Have to return something
	endif

	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_CompStimBuilder

	WAVE theWave

	Variable signalTypePMBottomY=GetControlBottomY("CompStimBuilderView","signalTypePopupMenu")
	Variable heightBetweenSigTypePMAndTopRow=12

	Variable segmentLabelSpaceWidth=50
	//Variable segmentLabelHeight=15
	Variable svLabelApproxWidth=60
	Variable svBodyWidth=40
	//Variable svApproxWidth=svLabelApproxWidth+svBodyWidth
	Variable pmWidth=100
	Variable leftOfSegmentLabelSpace=10
	Variable segmentLabelRightX=leftOfSegmentLabelSpace+segmentLabelSpaceWidth
	Variable segmentLabelToPopupWidth=5
	Variable typePopupXOffset=segmentLabelRightX+segmentLabelToPopupWidth
	Variable popupToLeftSVWidth=15
	Variable leftSVXOffset=typePopupXOffset+pmWidth+popupToLeftSVWidth
	Variable widthBetweenParams=20
	Variable topRowYOffset=signalTypePMBottomY+heightBetweenSigTypePMAndTopRow
	Variable rowHeight=25
	Variable heightBetweenRows=5
	Variable rowYSpacing=rowHeight+heightBetweenRows
	Variable yShimPopup= -4
	Variable yShimSV=-2	
	Variable widthBetweenParamSVAndUnits=2

	Wave /T compStim=CompStimWaveGetCompStim(theWave)
	Variable nSimpStims=CompStimGetNStimuli(compStim)

	Variable minControlBarHeight=82
	Variable controlBarHeightRaw=topRowYOffset+nSimpStims*rowheight+(nSimpStims-1)*heightBetweenRows
	Variable controlBarHeight=max(minControlBarHeight,controlBarHeightRaw)
	ControlBar /W=CompStimBuilderView controlBarHeight
	
	Variable i
	for (i=0; i<nSimpStims; i+=1)
		// The segment label
		Variable rowYOffset=topRowYOffset+i*rowYSpacing
	 	String tbName=sprintf1v("segment_%d_TB",i)
	 	String segmentLabel=sprintf1v("Segment %d:",i+1)
		ControlUpdate /W=CompStimBuilderView $tbName
		Variable segmentLabelWidth=GetControlWidth("CompStimBuilderView", tbName)	 	
		TitleBox $tbName, win=CompStimBuilderView, pos={segmentLabelRightX-segmentLabelWidth,rowYOffset}  //, size={segmentLabelHeight,segmentLabelSpaceWidth}
		
		// The segment type popup
	 	String popupMenuName=sprintf1v("segment_%d_PM",i)		
		PopupMenu $popupMenuName, win=CompStimBuilderView, bodyWidth=pmWidth
		ControlUpdate /W=CompStimBuilderView $popupMenuName
		PopupMenu $popupMenuName, win=CompStimBuilderView, pos={typePopupXOffset,rowYOffset+yShimPopup}
	
		// The row of SetVariables, one per parameter
		String simpStim=CompStimGetSimpStim(compStim,i)
		String simpStimType=SimpStimGetStimType(simpStim)
		
		// Get the param names for this segment type
		String getParamNamesFuncName=simpStimType+"GetParamNames"
		Funcref SSTGetParamNamesFallback getParamNames=$getParamNamesFuncName
		Wave /T paramNames=getParamNames()
		// Get the display param names for this segment type
		String getParamDisplayNamesFuncName=simpStimType+"GetParamDispNames"
		Funcref SSTGetParamDispNamesFallback getParamDisplayNames=$getParamDisplayNamesFuncName
		Wave /T paramDisplayNames=getParamDisplayNames()
		String segmentParamsList=SimpStimGetParamList(simpStim)
		Variable nParams=numpnts(paramNames)
		Variable j
		Variable lastParamRightX=leftSVXOffset-widthBetweenParams
		for (j=0; j<nParams; j+=1)
			String paramName=paramNames[j]
			Variable value=NumberByKey(paramName,segmentParamsList)

			// Update the SV position
			String svName=sprintf2vs("segment_%d_%s_SV",i,paramName)
			Variable svXOffset=lastParamRightX+widthBetweenParams
			//Printf "%s desired left: %d\r", svName, svXOffset
			//Wave bounds=GetControlBounds("CompStimBuilderView",svName)
			//Printf "bounds: left=%d, top=%d, right=%d, bottom=%d\r", bounds[0], bounds[1], bounds[2], bounds[3]
			SetVariable $svName, win=CompStimBuilderView, bodyWidth=svBodyWidth	
			ControlUpdate /W=CompStimBuilderView $svName
			//Wave bounds2=GetControlBounds("CompStimBuilderView",svName)
			//Printf "bounds: left=%d, top=%d, right=%d, bottom=%d\r", bounds2[0], bounds2[1], bounds2[2], bounds2[3]
			SetVariable $svName, win=CompStimBuilderView, pos={svXOffset,rowYOffset+yShimSV}   
			ControlUpdate /W=CompStimBuilderView $svName
			//Wave bounds3=GetControlBounds("CompStimBuilderView",svName)
			//Printf "bounds: left=%d, top=%d, right=%d, bottom=%d\r", bounds3[0], bounds3[1], bounds3[2], bounds3[3]

			// Position the units TB
			Variable svRightX=GetControlRightX("CompStimBuilderView",svName)
			String unitsTBName=sprintf2vs("segment_%d_%s_units_TB",i,paramName)
			TitleBox $unitsTBName, win=CompStimBuilderView, pos={svRightX+widthBetweenParamSVAndUnits,rowYOffset}
			ControlUpdate /W=CompStimBuilderView $unitsTBName
			//Wave bounds4=GetControlBounds("CompStimBuilderView",unitsTBName)
			//Printf "bounds: left=%d, top=%d, right=%d, bottom=%d\r", bounds4[0], bounds4[1], bounds4[2], bounds4[3]

			// Determine the x-coord of the right side of the units TB
			lastParamRightX=GetControlRightX("CompStimBuilderView",unitsTBName)
		endfor
	endfor
	
	SetDataFolder savedDF
End


Function /WAVE SSTGetParamNamesFallback()
	Abort "Internal Error: Attempt to call a <simpStimType>GetParamNames function that doesn't exist"
End


Function /WAVE SSTGetParamDispNamesFallback()
	Abort "Internal Error: Attempt to call a <simpStimType>GetParamDispNames function that doesn't exist"
End

Function /WAVE SSTGetParamUnitsFallback()
	Abort "Internal Error: Attempt to call a <simpStimType>GetParamUnits function that doesn't exist"
End


Function CSBViewUpdateControlProperties()
	// If the view doesn't exist, just return
	String windowName="CompStimBuilderView"
	if (!GraphExists(windowName))
		return 0		// Have to return something
	endif

	// Save, set data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_CompStimBuilder

	// Instance vars
	WAVE theWave
	SVAR signalType
	
	Variable signalTypeIndex=WhichListItem(signalType,CSBModelGetListOfSignalTypes())
	PopupMenu signalTypePopupMenu, win=CompStimBuilderView, mode=signalTypeIndex+1
	
	Wave /T compStim=CompStimWaveGetCompStim(theWave)
	Variable nSimpStims=CompStimGetNStimuli(compStim)

	Button deleteSegmentButton, win=CompStimBuilderView, disable=fromEnable(nSimpStims>1)

	Wave /T possibleSimpStimTypes=CSBModelGetStimTypes()
	String listOfPossibleSimpStimTypes=ListFromTextWave(possibleSimpStimTypes)
	Wave /T possibleDisplaySimpStimTypes=CSBModelGetDisplayStimTypes()
	String listOfPossibleDispSimpStimTypes=ListFromTextWave(possibleDisplaySimpStimTypes)
	String listOfDispSimpStimTypesFU="\""+listOfPossibleDispSimpStimTypes+"\""

	Variable i
	for (i=0; i<nSimpStims; i+=1)
		// The segment type popup
		String simpStim=CompStimGetSimpStim(compStim,i)
		String simpStimType=SimpStimGetStimType(simpStim)
		Variable iSimpStimType=WhichListItem(simpStimType,listOfPossibleSimpStimTypes)
	 	String popupMenuName=sprintf1v("segment_%d_PM",i)		
		PopupMenu $popupMenuName, win=CompStimBuilderView, value=#listOfDispSimpStimTypesFU
		PopupMenu $popupMenuName, win=CompStimBuilderView, mode=(iSimpStimType+1)
	
		// Get the param names for this segment type
		String getParamNamesFuncName=simpStimType+"GetParamNames"
		Funcref SSTGetParamNamesFallback getParamNames=$getParamNamesFuncName
		Wave /T paramNames=getParamNames()
		
		// Do the SVs
		String segmentParamList=SimpStimGetParamList(simpStim)
		Variable nParams=numpnts(paramNames)
		Variable j
		for (j=0; j<nParams; j+=1)
			String paramName=paramNames[j]
			// Get the parameter value
			String valueAsString=StringByKey(paramName,segmentParamList,"=",",")
			String svName=sprintf2vs("segment_%d_%s_SV",i,paramName)
			//String svValue="\\JR"+valueAsString  // this doesn't work: when user edits, they see the control codes (WTF...)
			// Update the control
			SetVariable $svName, win=CompStimBuilderView, value= _STR:valueAsString
		endfor
	endfor
End


Function CSBViewUpdateSingleSV(segmentIndex,paramName)
	Variable segmentIndex
	String paramName
	
	// If the view doesn't exist, just return
	String windowName="CompStimBuilderView"
	if (!GraphExists(windowName))
		return 0		// Have to return something
	endif

	// Save, set data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_CompStimBuilder

	// Instance vars
	WAVE theWave

	String svName=sprintf2vs("segment_%d_%s_SV",segmentIndex,paramName)
	String valueAsString=CompStimWaveGetParamAsString(theWave,segmentIndex,paramName)
	SetVariable $svName, win=CompStimBuilderView, value= _STR:valueAsString
End
