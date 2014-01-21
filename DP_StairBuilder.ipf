#pragma rtGlobals=1		// Use modern global access method.

Function StairBuilderViewConstructor() : Graph
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_StairBuilder
	WAVE theWave
	WAVE parameters
	Variable level1=parameters[0]
	Variable duration1=parameters[1]
	Variable level2=parameters[2]
	Variable duration2=parameters[3]
	Variable level3=parameters[4]
	Variable duration3=parameters[5]
	Variable level4=parameters[6]
	Variable duration4=parameters[7]
	Variable level5=parameters[8]
	// These are all in pixels
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
	Display /W=(xOffsetInPoints,yOffsetInPoints,xOffsetInPoints+widthInPoints,yOffsetInPoints+heightInPoints) /K=1 /N=StairBuilderView theWave as "Stair Builder"
	ModifyGraph /W=StairBuilderView /Z grid(left)=1
	Label /W=StairBuilderView /Z bottom "Time (ms)"
	Label /W=StairBuilderView /Z left "Signal (pure)"
	ModifyGraph /W=StairBuilderView /Z tickUnit(bottom)=1
	ModifyGraph /W=StairBuilderView /Z tickUnit(left)=1
	ControlBar 80

	Variable xShift=160
	xOffset=15		// Now this is used as an offset into the window
	SetVariable level1SV,win=StairBuilderView,pos={xOffset,15},size={100,15},proc=BuilderContSVTwiddled,title="Level 1"
	SetVariable level1SV,win=StairBuilderView,limits={-10000,10000,10}, value= _NUM:level1
	SetVariable duration1SV,win=StairBuilderView,pos={xOffset,45},size={130,15},proc=BuilderContSVTwiddled,title="Duration 1 (ms)"
	SetVariable duration1SV,win=StairBuilderView,limits={0,10000,10}, value= _NUM:duration1 

	xOffset+=xShift
	SetVariable level2SV,win=StairBuilderView,pos={xOffset,15},size={100,15},proc=BuilderContSVTwiddled,title="Level 2"
	SetVariable level2SV,win=StairBuilderView,limits={-10000,10000,10},value= _NUM:level2
	SetVariable duration2SV,win=StairBuilderView,pos={xOffset,45},size={130,15},proc=BuilderContSVTwiddled,title="Duration 2 (ms)"
	SetVariable duration2SV,win=StairBuilderView,limits={0,10000,10},value= _NUM:duration2

	xOffset+=xShift
	SetVariable level3SV,win=StairBuilderView,pos={xOffset,15},size={100,15},proc=BuilderContSVTwiddled,title="Level 3"
	SetVariable level3SV,win=StairBuilderView,limits={-10000,10000,10},value= _NUM:level3
	SetVariable duration3SV,win=StairBuilderView,pos={xOffset,45},size={130,15},proc=BuilderContSVTwiddled,title="Duration 2 (ms)"
	SetVariable duration3SV,win=StairBuilderView,limits={0,10000,10},value= _NUM:duration3

	xOffset+=xShift
	SetVariable level4SV,win=StairBuilderView,pos={xOffset,15},size={100,15},proc=BuilderContSVTwiddled,title="Level 4"
	SetVariable level4SV,win=StairBuilderView,limits={-10000,10000,10},value= _NUM:level4
	SetVariable duration4SV,win=StairBuilderView,pos={xOffset,45},size={130,15},proc=BuilderContSVTwiddled,title="Duration 4 (ms)"
	SetVariable duration4SV,win=StairBuilderView,limits={0,10000,10},value= _NUM:duration4

	xOffset+=xShift
	SetVariable level5SV,win=StairBuilderView,pos={xOffset,15},size={100,15},proc=BuilderContSVTwiddled,title="Level 5"
	SetVariable level5SV,win=StairBuilderView,limits={-10000,10000,10},value= _NUM:level5
	
	Button saveAsDACButton,win=StairBuilderView,pos={801,10},size={90,20},proc=BuilderContSaveAsButtonPressed,title="Save As..."
	//Button saveAsTTLButton,win=StairBuilderView,pos={801,30},size={90,20},proc=BuilderContSaveAsButtonPressed,title="Save As TTL..."
	Button importButton,win=StairBuilderView,pos={801,45},size={90,20},proc=BuilderContImportButtonPressed,title="Import..."

	SetDataFolder savedDF
End

Function StairBuilderModelInitialize()
	// Called from the constructor, so DF already set.
	Variable nParameters=9
	WAVE /T parameterNames
	WAVE parametersDefault
	WAVE parameters
	Redimension /N=(nParameters) parameterNames
	parameterNames[0]="level1"
	parameterNames[1]="duration1"
	parameterNames[2]="level2"
	parameterNames[3]="duration2"
	parameterNames[4]="level3"
	parameterNames[5]="duration3"
	parameterNames[6]="level4"
	parameterNames[7]="duration4"
	parameterNames[8]="level5"
	Redimension /N=(nParameters) parametersDefault
	parametersDefault[0]=0
	parametersDefault[1]=40		// ms
	parametersDefault[2]=1
	parametersDefault[3]=40		// ms
	parametersDefault[4]=2
	parametersDefault[5]=40		// ms
	parametersDefault[6]=3
	parametersDefault[7]=40		// ms
	parametersDefault[8]=0
	Redimension /N=(nParameters) parameters
	parameters=parametersDefault
	SVAR signalType
	signalType="DAC"
End

Function fillStairFromParamsBang(w,dt,nScans,parameters,parameterNames)
	Wave w
	Variable dt,nScans
	Wave parameters
	Wave /T parameterNames

	Variable level1=parameters[0]
	Variable duration1=parameters[1]
	Variable level2=parameters[2]
	Variable duration2=parameters[3]
	Variable level3=parameters[4]
	Variable duration3=parameters[5]
	Variable level4=parameters[6]
	Variable duration4=parameters[7]
	Variable level5=parameters[8]

//	Variable jStart,nThis
//	w=level5
//	jStart=0
//	nThis=round(duration1/dt)
//	if (jStart>=nScans)
//		return 0
//	endif
//	w[jStart,jStart+nThis-1]=level1
//	jStart+=nThis
//	nThis=round(duration2/dt)
//	if (jStart>=nScans)
//		return 0
//	endif
//	w[jStart,jStart+nThis-1]=level2
//	jStart+=nThis
//	nThis=round(duration3/dt)
//	if (jStart>=nScans)
//		return 0
//	endif
//	w[jStart,jStart+nThis-1]=level3
//	jStart+=nThis
//	nThis=round(duration4/dt)
//	if (jStart>=nScans)
//		return 0
//	endif
//	w[jStart,jStart+nThis-1]=level4
	
	Variable delta2=level2-level1
	Variable delta3=level3-level2
	Variable delta4=level4-level3
	Variable delta5=level5-level4
	
	Variable delay2=duration1
	Variable delay3=duration2+delay2
	Variable delay4=duration3+delay3
	Variable delay5=duration4+delay4
	
       // Somewhat controversial, but in the common case that step starts are sample-aligned, and step durations are
       // an integer multiple of dt, this ensures that each pulse is exactly duration/dt samples long
	Variable delay2Tweaked=delay2-dt/2
	Variable delay3Tweaked=delay3-dt/2
	Variable delay4Tweaked=delay4-dt/2
	Variable delay5Tweaked=delay5-dt/2
	
	w=level1+delta2*unitStep(x-delay2Tweaked)+delta3*unitStep(x-delay3Tweaked)+delta4*unitStep(x-delay4Tweaked)+delta5*unitStep(x-delay5Tweaked)
End

