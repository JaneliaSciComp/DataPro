#pragma rtGlobals=1		// Use modern global access method.

Function RampBuilderViewConstructor() : Graph
	BuilderModelConstructor("Ramp")
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_RampBuilder
	WAVE theWave
	WAVE parameters
	Variable preLevel=parameters[0]
	Variable delay=parameters[1]
	Variable duration=parameters[2]
	Variable postLevel=parameters[3]		
	// These are all in pixels
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
	Display /W=(xOffsetInPoints,yOffsetInPoints,xOffsetInPoints+widthInPoints,yOffsetInPoints+heightInPoints) /K=1 /N=RampBuilderView theWave as "Ramp Builder"
	ModifyGraph /W=RampBuilderView /Z grid(left)=1
	Label /W=RampBuilderView /Z bottom "Time (ms)"
	Label /W=RampBuilderView /Z left "Signal (pure)"
	ModifyGraph /W=RampBuilderView /Z tickUnit(bottom)=1
	ModifyGraph /W=RampBuilderView /Z tickUnit(left)=1
	ControlBar 80
	
	SetVariable preLevelSV,win=RampBuilderView,pos={25,20},size={140,15},proc=BuilderContSVTwiddled,title="Pre-Ramp Level"
	SetVariable preLevelSV,win=RampBuilderView,limits={-10000,10000,10},value= _NUM:preLevel
	
	SetVariable delaySV,win=RampBuilderView,pos={25,50},size={110,15},proc=BuilderContSVTwiddled,title="Delay (ms)"
	SetVariable delaySV,win=RampBuilderView,limits={0,1000,1},value= _NUM:delay
	
	SetVariable durationSV,win=RampBuilderView,pos={190,35},size={140,15},proc=BuilderContSVTwiddled,title="Ramp Duration (ms)"
	SetVariable durationSV,win=RampBuilderView,limits={1,100000,10},value= _NUM:duration
	
	SetVariable postLevelSV,win=RampBuilderView,pos={360,35},size={140,15},proc=BuilderContSVTwiddled,title="Post-Ramp Level"
	SetVariable postLevelSV,win=RampBuilderView,limits={-10000,10000,10},value= _NUM:postLevel

	Button saveAsDACButton,win=RampBuilderView,pos={601,10},size={90,20},proc=BuilderContSaveAsButtonPressed,title="Save As..."
	Button importButton,win=RampBuilderView,pos={601,45},size={90,20},proc=BuilderContImportButtonPressed,title="Import..."
	SetDataFolder savedDF
End

Function RampBuilderModelInitialize()
	// Called from the constructor, so DF already set.
	Variable nParameters=4
	WAVE /T parameterNames
	WAVE parametersDefault
	WAVE parameters
	Redimension /N=(nParameters) parameterNames
	parameterNames[0]="preLevel"
	parameterNames[1]="delay"
	parameterNames[2]="duration"
	parameterNames[3]="postLevel"
	Redimension /N=(nParameters) parametersDefault
	parametersDefault[0]=-10
	parametersDefault[1]=50
	parametersDefault[2]=100
	parametersDefault[3]=10
	Redimension /N=(nParameters) parameters
	parameters=parametersDefault
End

Function fillRampFromParamsBang(w,dt,nScans,parameters,parameterNames)
	Wave w
	Variable dt,nScans
	Wave parameters
	Wave /T parameterNames

	Variable preLevel=parameters[0]
	Variable delay=parameters[1]
	Variable duration=parameters[2]
	Variable postLevel=parameters[3]

	Variable nDelay=round(delay/dt)
	Variable nDuration=round(duration/dt)	
	Variable slope=(postLevel-preLevel)/duration
	w=postLevel
	w[0,nDelay-1]=preLevel
	if (nDelay>=nScans)
		return 0
	endif	
	w[nDelay,nDelay+nDuration-1]=preLevel+slope*(x-delay)
End

