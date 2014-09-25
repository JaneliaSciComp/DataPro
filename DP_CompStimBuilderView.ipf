#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function CSBViewConstructor() : Graph
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_CompStimBuilder
	WAVE theWave
	WAVE /T segments
	Variable xOffset=105
	Variable yOffset=200
	Variable width=705
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

	// Fixed controls
	Button saveAsDACButton, win=CompStimBuilderView, pos={601,10}, size={90,20}, proc=CSBContSaveAsButtonPressed, title="Save As..."
	Button importButton, win=CompStimBuilderView, pos={601,45}, size={90,20}, proc=CSBContImportButtonPressed, title="Import..."
	
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

	Variable segmentLabelXOffset=40
	Variable typePopupXOffset=100
	Variable leftSVXOffset=150
	Variable svXSpacing=160
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
	 	String segmentLabel=sprintf1v("Segment %d",i+1)
		TitleBox $tbName, win=CompStimBuilderView, pos={segmentLabelXOffset,rowYOffset}, size={45,15}, frame=0, title=segmentLabel
		
		// The segment type popup
	 	String popupMenuName=sprintf1v("segment%dPM",i)		
		PopupMenu $popupMenuName, win=CompStimBuilderView, pos={typePopupXOffset,rowYSpacing-yShimPopup}, bodyWidth=70
		PopupMenu $popupMenuName, win=CompStimBuilderView, proc=CSBContSegmentTypePMActuated
	
		// The row of SetVariables, one per parameter
		String simpStim=CompStimGetSimpStim(compStim,i)
		String simpStimType=SimpStimGetStimType(simpStim)
		
		// Get the param names for this segment type
		String getParamNamesFuncName=simpStimType+"GetParamNames"
		Funcref CSBViewFallback getParamNames=$getParamNamesFuncName
		Wave /T paramNames=getParamNames()
		// Get the display param names for this segment type
		String getParamDisplayNamesFuncName=simpStimType+"GetParamDisplayNames"
		Funcref CSBViewFallback getParamDisplayNames=$getParamDisplayNamesFuncName
		Wave /T paramDisplayNames=getParamDisplayNames()
		String segmentParamsList=SimpStimGetParamList(simpStim)
		Variable nParams=numpnts(paramNames)
		Variable j
		for (j=0; j<nParams; j+=1)
			String paramName=paramNames[j]
			String paramDisplayName=paramDisplayNames[j]
			// Get the parameter value
			Variable value=NumberByKey(paramName,segmentParamsList)
			String svName=sprintf2vs("segment%d%sSV",i,paramName)
			// Update the control
			Variable svXOffset=leftSVXOffset+j*svXSpacing
			SetVariable $svName, win=CompStimBuilderView, pos={svXOffset,rowYOffset}, size={140,17}, proc=CSBContParamSVActuated, title=paramDisplayName
			SetVariable $svName, win=CompStimBuilderView, limits={-inf,+inf,1}
		endfor
	endfor
	
	SetDataFolder savedDF
End


Function /WAVE CSBViewFallback()
	Abort "Internal Error: Attempt to call a function that doesn't exist"
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

	WAVE /T segments

	Variable segmentLabelXOffset=40
	Variable typePopupXOffset=100
	Variable leftSVXOffset=150
	Variable svXSpacing=160
	Variable topRowYOffset=12
	Variable rowYSpacing=30
	Variable yShimPopup=3	

	Variable nSegments=DimSize(segments,0)

	ControlBar /W=CompStimBuilderView 80	// need to adjust for number of rows...

	String listOfSegmentTypes=CompStimGetStimTypes()
	String listOfSegmentTypesFU="\""+listOfSegmentTypes+"\""	
	
	Variable i
	for (i=0; i<nSegments; i++)
		// The segment type popup
		segmentType=segments[i][0]
	 	Variable popupMenuName=sprintf1v("segment%dPM",i)		
		PopupMenu $popupMenuName, win=CompStimBuilderView, value=#listOfSegmentTypesFU
		PopupMenu $popupMenuName, win=CompStimBuilderView, mode=segmentType
	
		// Get the param names for this segment type
		String getParamNamesFuncName=segmentType+"GetParamNames"
		Funcref CompStimBuilderViewFallback getParamNames=$getParamNamesFuncName
		String paramNames=getParamNames()
		
		// Do the SVs
		String segmentParamsString=segments[i][1]
		nParams=numpnts(paramNames)
		for (j=0; j<nParams; j++)
			String paramName=paramNames[j]
			// Get the parameter value
			Variable value=NumberByKey(paramName,segmentParamsString)
			Variable svName=sprintf2vs("segment%d%sSV",i,paramName)
			// Update the control
			SetVariable $svName, win=CompStimBuilderView, value= _NUM:value
		endfor
	endfor
End


