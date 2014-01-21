#pragma rtGlobals=1		// Use modern global access method.

Function TTLTrainBuilderViewConstructor() : Graph
	//BuilderModelConstructor("TTLTrain")
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_TTLTrainBuilder
	WAVE theWave
	WAVE parameters
	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable pulseRate=parameters[2]				
	Variable pulseDuration=parameters[3]			
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
	Display /W=(xOffsetInPoints,yOffsetInPoints,xOffsetInPoints+widthInPoints,yOffsetInPoints+heightInPoints) /K=1 /N=TTLTrainBuilderView theWave as "TTL Train Builder"
	ModifyGraph /W=TTLTrainBuilderView /Z grid(left)=1
	Label /W=TTLTrainBuilderView /Z bottom "Time (ms)"
	Label /W=TTLTrainBuilderView /Z left "Signal (pure)"
	ModifyGraph /W=TTLTrainBuilderView /Z tickUnit(bottom)=1
	ModifyGraph /W=TTLTrainBuilderView /Z tickUnit(left)=1
	ControlBar 80

	SetVariable delaySV,win=TTLTrainBuilderView,pos={15,15},size={110,15},proc=BuilderContSVTwiddled,title="Delay (ms)"
	SetVariable delaySV,win=TTLTrainBuilderView,limits={0,200000,1},value= _NUM:delay

	SetVariable durationSV,win=TTLTrainBuilderView,pos={15,45},size={125,15},proc=BuilderContSVTwiddled,title="Duration (ms)"
	SetVariable durationSV,win=TTLTrainBuilderView,limits={1,inf,1},value= _NUM:duration

	SetVariable pulseRateSV,win=TTLTrainBuilderView,pos={155,15},size={150,15},proc=BuilderContSVTwiddled,title="Pulse Rate (Hz)"
	SetVariable pulseRateSV,win=TTLTrainBuilderView,limits={0.001,inf,10},value= _NUM:pulseRate

	SetVariable pulseDurationSV,win=TTLTrainBuilderView,pos={155,45},size={140,15},proc=BuilderContSVTwiddled,title="Pulse Duration (ms)"
	SetVariable pulseDurationSV,win=TTLTrainBuilderView,limits={0.001,inf,1},value= _NUM:pulseDuration

	//SetVariable baseLevelSV,win=TTLTrainBuilderView,pos={330,15},size={110,15},proc=BuilderContSVTwiddled,title="Base Level"
	//SetVariable baseLevelSV,win=TTLTrainBuilderView,limits={-10000,10000,1},value= _NUM:baseLevel

	//SetVariable amplitudeSV,win=TTLTrainBuilderView,pos={330,45},size={130,15},proc=BuilderContSVTwiddled,title="Amplitude"
	//SetVariable amplitudeSV,win=TTLTrainBuilderView,limits={-10000,10000,10},value= _NUM:amplitude
	
	Button saveAsTTLButton,win=TTLTrainBuilderView,pos={601,10},size={90,20},proc=BuilderContSaveAsButtonPressed,title="Save As..."
	//Button saveAsTTLButton,win=TTLTrainBuilderView,pos={601,30},size={90,20},proc=BuilderContSaveAsButtonPressed,title="Save As TTL..."
	Button importButton,win=TTLTrainBuilderView,pos={601,45},size={90,20},proc=BuilderContImportButtonPressed,title="Import..."
	SetDataFolder savedDF
End

Function TTLTrainBuilderModelInitialize()
	// Called from the constructor, so DF already set.
	Variable nParameters=4
	WAVE /T parameterNames
	WAVE parametersDefault
	WAVE parameters
	Redimension /N=(nParameters) parameterNames
	parameterNames[0]="delay"
	parameterNames[1]="duration"
	parameterNames[2]="pulseRate"
	parameterNames[3]="pulseDuration"
	//parameterNames[4]="baseLevel"
	//parameterNames[5]="amplitude"
	Redimension /N=(nParameters) parametersDefault
	parametersDefault[0]=20		// ms
	parametersDefault[1]=100		// ms
	parametersDefault[2]=100		// Hz
	parametersDefault[3]=2		// ms
	//parametersDefault[4]=0
	//parametersDefault[5]=10
	Redimension /N=(nParameters) parameters
	parameters=parametersDefault
	SVAR signalType
	signalType="TTL"
End

Function fillTTLTrainFromParamsBang(w,dt,nScans,parameters,parameterNames)
	Wave w
	Variable dt,nScans
	Wave parameters
	Wave /T parameterNames

	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable pulseRate=parameters[2]				
	Variable pulseDuration=parameters[3]

       // Somewhat controversial, but in the common case that pulse starts are sample-aligned, and pulse durations are
       // an integer multiple of dt, this ensures that each pulse is exactly pulseDuration samples long
	Variable delayTweaked=delay-dt/2

	Variable pulseDutyCycle=max(0,min((pulseDuration/1000)*pulseRate,1))		// pure
	w=unitPulse(x-delayTweaked,duration)*squareWave(pulseRate*(x-delayTweaked)/1000,pulseDutyCycle)
End
