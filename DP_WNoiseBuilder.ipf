#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function WNoiseBuilderViewConstructor() : Graph
	//BuilderModelConstructor("WNoise")
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_WNoiseBuilder
	WAVE theWave
	WAVE parameters
	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable mu=parameters[2]
	Variable sigma=parameters[3]	
	Variable fLow=parameters[4]
	Variable fHigh=parameters[5]
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
	Display /W=(xOffsetInPoints,yOffsetInPoints,xOffsetInPoints+widthInPoints,yOffsetInPoints+heightInPoints) /K=1 /N=WNoiseBuilderView theWave as "White Noise Builder"
	ModifyGraph /W=WNoiseBuilderView /Z grid(left)=1
	Label /W=WNoiseBuilderView /Z bottom "Time (ms)"
	Label /W=WNoiseBuilderView /Z left "Signal (pure)"
	ModifyGraph /W=WNoiseBuilderView /Z tickUnit(bottom)=1
	ModifyGraph /W=WNoiseBuilderView /Z tickUnit(left)=1
	ControlBar 80
	SetVariable delaySV,win=WNoiseBuilderView,pos={40,12},size={140,17},proc=BuilderContSVTwiddled,title="Delay (ms)"
	SetVariable delaySV,win=WNoiseBuilderView,limits={0,1000,1},value= _NUM:delay
	SetVariable durationSV,win=WNoiseBuilderView,pos={205,12},size={120,17},proc=BuilderContSVTwiddled,title="Duration (ms)"
	SetVariable durationSV,win=WNoiseBuilderView,format="%g",limits={0,100000,10},value= _NUM:duration
	SetVariable muSV,win=WNoiseBuilderView,pos={40,43},size={120,17},proc=BuilderContSVTwiddled,title="Mean"
	SetVariable muSV,win=WNoiseBuilderView,limits={-10000,10000,10},value= _NUM:mu
	SetVariable sigmaSV,win=WNoiseBuilderView,pos={205,43},size={150,17},proc=BuilderContSVTwiddled,title="Standard Deviation"
	SetVariable sigmaSV,win=WNoiseBuilderView,format="%g",limits={0,10000,10},value= _NUM:sigma

	SetVariable fLowSV,win=WNoiseBuilderView,pos={390,12},size={140,17},proc=BuilderContSVTwiddled,title="Low Cutoff (kHz)"
	SetVariable fLowSV,win=WNoiseBuilderView,format="%g",limits={0,50000,100},value= _NUM:fLow

	SetVariable fHighSV,win=WNoiseBuilderView,pos={390,43},size={140,17},proc=BuilderContSVTwiddled,title="High Cutoff (kHz)"
	SetVariable fHighSV,win=WNoiseBuilderView,format="%g",limits={0,50000,100},value= _NUM:fHigh
	
	Button saveAsDACButton,win=WNoiseBuilderView,pos={601,10},size={90,20},proc=BuilderContSaveAsButtonPressed,title="Save As..."
	Button importButton,win=WNoiseBuilderView,pos={601,45},size={90,20},proc=BuilderContImportButtonPressed,title="Import..."
	SetDataFolder savedDF
End

//Function WNoiseBuilderModelInitialize()
//	// Called from the constructor, so DF already set.
//	Variable nParameters=4
//	WAVE /T parameterNames
//	WAVE parametersDefault
//	WAVE parameters
//	Redimension /N=(nParameters) parameterNames
//	parameterNames[0]="delay"
//	parameterNames[1]="duration"
//	parameterNames[2]="mu"
//	parameterNames[3]="sigma"
//	Redimension /N=(nParameters) parametersDefault
//	parametersDefault[0]=10
//	parametersDefault[1]=50
//	parametersDefault[2]=0
//	parametersDefault[3]=1
//	Redimension /N=(nParameters) parameters
//	parameters=parametersDefault
//	SVAR signalType
//	signalType="DAC"
//End
//
//Function fillWNoiseFromParamsBang(w,dt,nScans,parameters,parameterNames)
//	Wave w
//	Variable dt,nScans
//	Wave parameters
//	Wave /T parameterNames
//
//	Variable delay=parameters[0]
//	Variable duration=parameters[1]
//	Variable mu=parameters[2]
//	Variable sigma=parameters[3]
//	
//	w=(mu+gnoise(sigma))*unitPulse(x-delay,duration)
//End
