#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function CSBViewConstructor() : Graph
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_CompStimBuilder
	WAVE theWave
	WAVE /T segments

	// Window position and dimension, in pixels
	Variable xOffset=105
	Variable yOffset=200
	Variable width=900
	Variable height=400

	// Convert dimensions to points
	Variable pointsPerPixel=72/ScreenResolution
	Variable xOffsetInPoints=pointsPerPixel*xOffset
	Variable yOffsetInPoints=pointsPerPixel*yOffset
	Variable widthInPoints=pointsPerPixel*width
	Variable heightInPoints=pointsPerPixel*height
	Display /W=(xOffsetInPoints,yOffsetInPoints,xOffsetInPoints+widthInPoints,yOffsetInPoints+heightInPoints) /K=1 /N=CompStimBuilderView theWave as "Compound Stimulus Builder"
	ModifyGraph /W=CompStimBuilderView /Z grid(left)=1
	Label /W=CompStimBuilderView /Z bottom "Time (ms)"
	Label /W=CompStimBuilderView /Z left "Signal (pure)"
	ModifyGraph /W=CompStimBuilderView /Z tickUnit(bottom)=1
	ModifyGraph /W=CompStimBuilderView /Z tickUnit(left)=1
	ControlBar /W=CompStimBuilderView 80

	// Control positions and dimension, in pixels
	Variable leftButtonsXOffset=695
	Variable rightButtonsXOffset=800
	Variable topButtonsYOffset=10
	Variable bottomButtonsYOffset=45
	Variable buttonWidth=90
	Variable buttonHeight=20	

	// Fixed controls
	Button addSegmentButton, win=CompStimBuilderView, pos={leftButtonsXOffset,topButtonsYOffset}, size={buttonWidth,buttonHeight}, proc=CSBContAddSegButtonPressed, title="Add Segment"
	Button deleteSegmentButton, win=CompStimBuilderView, pos={leftButtonsXOffset,bottomButtonsYOffset}, size={buttonWidth,buttonHeight}, proc=CSBContDelSegButtonPressed, title="Delete Segment"
	Button saveAsDACButton, win=CompStimBuilderView, pos={rightButtonsXOffset,topButtonsYOffset}, size={buttonWidth,buttonHeight}, proc=CSBContSaveAsButtonPressed, title="Save As..."
	Button importButton, win=CompStimBuilderView, pos={rightButtonsXOffset,bottomButtonsYOffset}, size={buttonWidth,buttonHeight}, proc=CSBContImportButtonPressed, title="Import..."

	// Update everything
	CSBViewUpdate()

	SetDataFolder savedDF
End


Function CSBViewUpdate()
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_CompStimBuilder
	
	CSBViewLayout()
	CSBViewUpdateControlProperties()
	
	SetDataFolder savedDF
End


Function CSBViewLayout()
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_CompStimBuilder

	WAVE theWave

	Variable segmentLabelWidth=45
	Variable segmentLabelHeight=15
	Variable svLabelApproxWidth=60
	Variable svBodyWidth=60
	Variable svApproxWidth=svLabelApproxWidth+svBodyWidth
	Variable svHeight=17
	Variable pmWidth=70
	Variable segmentLabelXOffset=10
	Variable typePopupXOffset=100
	Variable leftSVXOffset=160
	Variable widthBetweenSVs=10
	Variable topRowYOffset=12
	Variable rowYSpacing=30
	Variable yShimPopup=3	

	Wave /T compStim=CompStimWaveGetCompStim(theWave)
	Variable nSimpStims=CompStimGetNStimuli(compStim)

	ControlBar /W=CompStimBuilderView 80	// need to adjust for number of rows...
	
	Variable i
	for (i=0; i<nSimpStims; i+=1)
		// The segment label
		Variable rowYOffset=topRowYOffset+i*rowYSpacing
	 	String tbName=sprintf1v("segment%dTB",i)
	 	String segmentLabel=sprintf1v("Segment %d:",i+1)
		TitleBox $tbName, win=CompStimBuilderView, pos={segmentLabelXOffset,rowYOffset}, size={segmentLabelHeight,segmentLabelWidth}, frame=0, title=segmentLabel
		
		// The segment type popup
	 	String popupMenuName=sprintf1v("segment%dPM",i)		
		PopupMenu $popupMenuName, win=CompStimBuilderView, pos={typePopupXOffset,rowYOffset-yShimPopup}, bodyWidth=pmWidth
		PopupMenu $popupMenuName, win=CompStimBuilderView, proc=CSBContSegmentTypePMActuated
	
		// The row of SetVariables, one per parameter
		String simpStim=CompStimGetSimpStim(compStim,i)
		String simpStimType=SimpStimGetStimType(simpStim)
		
		// Get the param names for this segment type
		String getParamNamesFuncName=simpStimType+"GetParamNames"
		Funcref SSTGetParamNamesFallback getParamNames=$getParamNamesFuncName
		Wave /T paramNames=getParamNames()
		// Get the display param names for this segment type
		String getParamDisplayNamesFuncName=simpStimType+"GetParamDisplayNames"
		Funcref SSTGetParamDisplayNamesFallback getParamDisplayNames=$getParamDisplayNamesFuncName
		Wave /T paramDisplayNames=getParamDisplayNames()
		String segmentParamsList=SimpStimGetParamList(simpStim)
		Variable nParams=numpnts(paramNames)
		Variable j
		Variable lastSVRightX=leftSVXOffset-widthBetweenSVs
		for (j=0; j<nParams; j+=1)
			String paramName=paramNames[j]
			String paramDisplayName=paramDisplayNames[j]
			// Get the parameter value
			Variable value=NumberByKey(paramName,segmentParamsList)
			String svName=sprintf2vs("segment_%d_%s_SV",i,paramName)
			// Update the control
			Variable svXOffset=lastSVRightX+widthBetweenSVs
			SetVariable $svName, win=CompStimBuilderView, pos={svXOffset,rowYOffset}, size={svApproxWidth,svHeight}, bodyWidth=svBodyWidth, title=paramDisplayName
			SetVariable $svName, win=CompStimBuilderView, limits={-inf,+inf,1}, proc=CSBContParamSVActuated
			// Determine the x-coord of the right side of the SV 
			lastSVRightX=GetControlRightX("CompStimBuilderView",svName)
		endfor
	endfor
	
	SetDataFolder savedDF
End


Function /WAVE SSTGetParamNamesFallback()
	Abort "Internal Error: Attempt to call a <simpStimType>GetParamNames function that doesn't exist"
End


Function /WAVE SSTGetParamDisplayNamesFallback()
	Abort "Internal Error: Attempt to call a <simpStimType>GetParamDisplayNames function that doesn't exist"
End


Function CSBViewUpdateControlProperties()
	String builderType
	
	// Synthesize the window name from the builderType
	String windowName="CompStimBuilderView"
	
	// If the view doesn't exist, just return
	if (!GraphExists(windowName))
		return 0		// Have to return something
	endif

	// Save, set data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_CompStimBuilder

	// Instance vars
	WAVE theWave
	
	Wave /T compStim=CompStimWaveGetCompStim(theWave)
	Variable nSimpStims=CompStimGetNStimuli(compStim)

//	Variable segmentLabelXOffset=10
//	Variable typePopupXOffset=100
//	Variable leftSVXOffset=150
//	Variable svXSpacing=160
//	Variable topRowYOffset=12
//	Variable rowYSpacing=30
//	Variable yShimPopup=3

	ControlBar /W=CompStimBuilderView 80	// need to adjust for number of rows...

	Wave /T possibleSimpStimTypes=CompStimWaveGetStimTypes()
	String listOfPossibleSimpStimTypes=ListFromTextWave(possibleSimpStimTypes)
	String listOfPossibleSimpStimTypesFU="\""+listOfPossibleSimpStimTypes+"\""

	Variable i
	for (i=0; i<nSimpStims; i+=1)
		// The segment type popup
		String simpStim=CompStimGetSimpStim(compStim,i)
		String simpStimType=SimpStimGetStimType(simpStim)
		Variable iSimpStimType=WhichListItem(simpStimType,listOfPossibleSimpStimTypes)
	 	String popupMenuName=sprintf1v("segment%dPM",i)		
		PopupMenu $popupMenuName, win=CompStimBuilderView, value=#listOfPossibleSimpStimTypesFU
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
