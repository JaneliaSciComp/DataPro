#pragma rtGlobals=1		// Use modern global access method.

Function RampBuilderViewConstructor() : Graph
	//BuilderModelConstructor("Ramp")
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_RampBuilder
	WAVE theWave
	WAVE parameters
	Variable baselineLevel=parameters[0]
	Variable delay=parameters[1]
	Variable initialLevel=parameters[2]
	Variable duration=parameters[3]
	Variable finalLevel=parameters[4]	
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
	
	SetVariable baselineLevelSV,win=RampBuilderView,pos={25,20},size={140,15},proc=BuilderContSVTwiddled,title="Baseline Level"
	SetVariable baselineLevelSV,win=RampBuilderView,limits={-10000,10000,10},value= _NUM:baselineLevel
	
	SetVariable delaySV,win=RampBuilderView,pos={25,50},size={110,15},proc=BuilderContSVTwiddled,title="Delay (ms)"
	SetVariable delaySV,win=RampBuilderView,limits={0,1000,1},value= _NUM:delay
	
	SetVariable initialLevelSV,win=RampBuilderView,pos={190,20},size={140,15},proc=BuilderContSVTwiddled,title="Ramp Initial Level"
	SetVariable initialLevelSV,win=RampBuilderView,limits={-10000,10000,10},value= _NUM:initialLevel
	
	SetVariable durationSV,win=RampBuilderView,pos={190,50},size={140,15},proc=BuilderContSVTwiddled,title="Ramp Duration (ms)"
	SetVariable durationSV,win=RampBuilderView,limits={1,100000,10},value= _NUM:duration
	
	SetVariable finalLevelSV,win=RampBuilderView,pos={360,20},size={140,15},proc=BuilderContSVTwiddled,title="Ramp Final Level"
	SetVariable finalLevelSV,win=RampBuilderView,limits={-10000,10000,10},value= _NUM:finalLevel
	
	Button saveAsDACButton,win=RampBuilderView,pos={601,10},size={90,20},proc=BuilderContSaveAsButtonPressed,title="Save As..."
	Button importButton,win=RampBuilderView,pos={601,45},size={90,20},proc=BuilderContImportButtonPressed,title="Import..."
	SetDataFolder savedDF
End

Function RampBuilderModelInitialize()
	// Called from the constructor, so DF already set.
	Variable nParameters=5
	WAVE /T parameterNames
	WAVE parametersDefault
	WAVE parameters
	Redimension /N=(nParameters) parameterNames
	parameterNames[0]="baselineLevel"
	parameterNames[1]="delay"
	parameterNames[2]="initialLevel"
	parameterNames[3]="duration"
	parameterNames[4]="finalLevel"	
	Redimension /N=(nParameters) parametersDefault
	parametersDefault[0]=0
	parametersDefault[1]=50
	parametersDefault[2]=-10
	parametersDefault[3]=100
	parametersDefault[4]=10
	Redimension /N=(nParameters) parameters
	parameters=parametersDefault
	SVAR signalType
	signalType="DAC"
End

Function fillRampFromParamsBang(w,dt,nScans,parameters,parameterNames)
	Wave w
	Variable dt,nScans
	Wave parameters
	Wave /T parameterNames

	Variable baselineLevel=parameters[0]
	Variable delay=parameters[1]
	Variable initialLevel=parameters[2]
	Variable duration=parameters[3]
	Variable finalLevel=parameters[4]

//	Variable nDelay=round(delay/dt)
//	Variable nDuration=round(duration/dt)	
//	Variable slope=(postLevel-preLevel)/duration
//	w=postLevel
//	w[0,nDelay-1]=preLevel
//	if (nDelay>=nScans)
//		return 0
//	endif	
//	w[nDelay,nDelay+nDuration-1]=preLevel+slope*(x-delay)
	
	w=baselineLevel+((initialLevel-baselineLevel)+(finalLevel-initialLevel)*max(0,min((x-delay)/duration,1)))*unitPulse(x-delay,duration)
End

