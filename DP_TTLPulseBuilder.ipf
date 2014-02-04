#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function TTLPulseBuilderViewConstructor() : Graph
	//BuilderModelConstructor("TTLPulse")
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_TTLPulseBuilder
	
	// instance vars
	WAVE theWave
	WAVE parameters
	
	Variable delay=parameters[0]
	Variable duration=parameters[1]
	//Variable pulseRate=parameters[2]				
	//Variable pulseDuration=parameters[3]			
	//Variable baseLevel=parameters[4]
	//Variable amplitude=parameters[5]			
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
	Display /W=(xOffsetInPoints,yOffsetInPoints,xOffsetInPoints+widthInPoints,yOffsetInPoints+heightInPoints) /K=1 /N=TTLPulseBuilderView theWave as "TTL Pulse Builder"
	ModifyGraph /W=TTLPulseBuilderView /Z grid(left)=1
	Label /W=TTLPulseBuilderView /Z bottom "Time (ms)"
	Label /W=TTLPulseBuilderView /Z left "Signal (pure)"
	ModifyGraph /W=TTLPulseBuilderView /Z tickUnit(bottom)=1
	ModifyGraph /W=TTLPulseBuilderView /Z tickUnit(left)=1
	ControlBar 80

	SetVariable delaySV,win=TTLPulseBuilderView,pos={15,15},size={110,15},proc=BuilderContSVTwiddled,title="Delay (ms)"
	SetVariable delaySV,win=TTLPulseBuilderView,limits={0,200000,1},value= _NUM:delay

	SetVariable durationSV,win=TTLPulseBuilderView,pos={15,45},size={125,15},proc=BuilderContSVTwiddled,title="Duration (ms)"
	SetVariable durationSV,win=TTLPulseBuilderView,limits={1,inf,1},value= _NUM:duration

	//SetVariable pulseRateSV,win=TTLPulseBuilderView,pos={155,15},size={150,15},proc=BuilderContSVTwiddled,title="Pulse Rate (Hz)"
	//SetVariable pulseRateSV,win=TTLPulseBuilderView,limits={0.001,inf,10},value= _NUM:pulseRate

	//SetVariable pulseDurationSV,win=TTLPulseBuilderView,pos={155,45},size={140,15},proc=BuilderContSVTwiddled,title="Pulse Duration (ms)"
	//SetVariable pulseDurationSV,win=TTLPulseBuilderView,limits={0.001,inf,1},value= _NUM:pulseDuration

	//SetVariable baseLevelSV,win=TTLTrainBuilderView,pos={330,15},size={110,15},proc=BuilderContSVTwiddled,title="Base Level"
	//SetVariable baseLevelSV,win=TTLPulseBuilderView,limits={-10000,10000,1},value= _NUM:baseLevel

	//SetVariable amplitudeSV,win=TTLPulseBuilderView,pos={330,45},size={130,15},proc=BuilderContSVTwiddled,title="Amplitude"
	//SetVariable amplitudeSV,win=TTLPulseBuilderView,limits={-10000,10000,10},value= _NUM:amplitude
	
	Button saveAsTTLButton,win=TTLPulseBuilderView,pos={601,10},size={90,20},proc=BuilderContSaveAsButtonPressed,title="Save As..."
	//Button saveAsTTLButton,win=TTLPulseBuilderView,pos={601,30},size={90,20},proc=BuilderContSaveAsButtonPressed,title="Save As TTL..."
	Button importButton,win=TTLPulseBuilderView,pos={601,45},size={90,20},proc=BuilderContImportButtonPressed,title="Import..."
	SetDataFolder savedDF
End

Function TTLPulseBuilderModelInitialize()
	// Called from the constructor, so DF already set.
	
	// instance vars
	WAVE /T parameterNames
	WAVE parametersDefault
	WAVE parameters
	SVAR signalType

	//Wave /T parameterNamesLocal=TTLPulseGetParamNames()
	Duplicate /T TTLPulseGetParamNames(), parameterNames
	Variable nParameters=numpnts(parameterNames)
	Redimension /N=(nParameters) parametersDefault
	parametersDefault[0]=20		// ms
	parametersDefault[1]=100		// ms
	Redimension /N=(nParameters) parameters
	parameters=parametersDefault
	signalType=TTLPulseGetSignalType()
End

Function fillTTLPulseFromParamsBang(w,dt,nScans,parameters,parameterNames)
	Wave w
	Variable dt,nScans
	Wave parameters
	Wave /T parameterNames

	 TTLPulseFillFromParams(w,parameters)
End
