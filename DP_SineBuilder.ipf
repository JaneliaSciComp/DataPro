#pragma rtGlobals=1		// Use modern global access method.

Function SineBuilderViewConstructor() : Graph
	//BuilderModelConstructor("Sine")
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_SineBuilder
	WAVE theWave
	WAVE parameters
	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable amplitude=parameters[2]
	Variable frequency=parameters[3]	
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
	Display /W=(xOffsetInPoints,yOffsetInPoints,xOffsetInPoints+widthInPoints,yOffsetInPoints+heightInPoints) /K=1 /N=SineBuilderView theWave as "Sine Builder"
	ModifyGraph /W=SineBuilderView /Z grid(left)=1
	Label /W=SineBuilderView /Z bottom "Time (ms)"
	Label /W=SineBuilderView /Z left "Signal (pure)"
	ModifyGraph /W=SineBuilderView /Z tickUnit(bottom)=1
	ModifyGraph /W=SineBuilderView /Z tickUnit(left)=1
	ControlBar 80
	SetVariable delaySV,win=SineBuilderView,pos={40,12},size={140,17},proc=BuilderContSVTwiddled,title="Delay (ms)"
	SetVariable delaySV,win=SineBuilderView,limits={0,1000,1},value= _NUM:delay
	SetVariable durationSV,win=SineBuilderView,pos={205,12},size={120,17},proc=BuilderContSVTwiddled,title="Duration (ms)"
	SetVariable durationSV,win=SineBuilderView,format="%g",limits={0,10000,10},value= _NUM:duration
	SetVariable amplitudeSV,win=SineBuilderView,pos={128,43},size={120,17},proc=BuilderContSVTwiddled,title="Amplitude"
	SetVariable amplitudeSV,win=SineBuilderView,limits={-10000,10000,10},value= _NUM:amplitude
	SetVariable frequencySV,win=SineBuilderView,pos={286,43},size={130,17},proc=BuilderContSVTwiddled,title="Frequency (Hz)"
	SetVariable frequencySV,win=SineBuilderView,format="%g",limits={0,10000,10},value= _NUM:frequency
	Button saveAsDACButton,win=SineBuilderView,pos={601,10},size={90,20},proc=BuilderContSaveAsButtonPressed,title="Save As..."
	Button importButton,win=SineBuilderView,pos={601,45},size={90,20},proc=BuilderContImportButtonPressed,title="Import..."
	SetDataFolder savedDF
End

Function SineBuilderModelInitialize()
	// Called from the constructor, so DF already set.
	Variable nParameters=4
	WAVE /T parameterNames
	WAVE parametersDefault
	WAVE parameters
	Redimension /N=(nParameters) parameterNames
	parameterNames[0]="delay"
	parameterNames[1]="duration"
	parameterNames[2]="amplitude"
	parameterNames[3]="frequency"
	Redimension /N=(nParameters) parametersDefault
	parametersDefault[0]=10
	parametersDefault[1]=50
	parametersDefault[2]=10
	parametersDefault[3]=100
	Redimension /N=(nParameters) parameters
	parameters=parametersDefault
	SVAR signalType
	signalType="DAC"
End

Function fillSineFromParamsBang(w,dt,nScans,parameters,parameterNames)
	Wave w
	Variable dt,nScans
	Wave parameters
	Wave /T parameterNames

	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable amplitude=parameters[2]
	Variable frequency=parameters[3]

//	Variable jFirst=0
//	Variable jLast=round(delay/dt)-1
//	if (jFirst>=nScans)
//		return 0
//	endif
//	w[jFirst,jLast]=0
//	jFirst=jLast+1
//	jLast=jFirst+round(duration/dt)-1
//	if (jFirst>=nScans)
//		return 0
//	endif
//	w[jFirst,jLast]=amplitude*sin(frequency*2*PI*(x-delay)/1000)
//	jFirst=jLast+1
//	jLast=nScans-1
//	if (jFirst>=nScans)
//		return 0
//	endif
//	w[jFirst,jLast]=0
	
	w=amplitude*unitPulse(x-delay,duration)*sin(frequency*2*PI*(x-delay)/1000)
End
