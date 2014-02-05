#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function TrainBuilderViewConstructor() : Graph
	//BuilderModelConstructor("Train")
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_TrainBuilder
	WAVE theWave
	WAVE parameters
	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable pulseRate=parameters[2]				
	Variable pulseDuration=parameters[3]			
	Variable baseLevel=parameters[4]
	Variable amplitude=parameters[5]			
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
	Display /W=(xOffsetInPoints,yOffsetInPoints,xOffsetInPoints+widthInPoints,yOffsetInPoints+heightInPoints) /K=1 /N=TrainBuilderView theWave as "Train Builder"
	ModifyGraph /W=TrainBuilderView /Z grid(left)=1
	Label /W=TrainBuilderView /Z bottom "Time (ms)"
	Label /W=TrainBuilderView /Z left "Signal (pure)"
	ModifyGraph /W=TrainBuilderView /Z tickUnit(bottom)=1
	ModifyGraph /W=TrainBuilderView /Z tickUnit(left)=1
	ControlBar 80

	SetVariable delaySV,win=TrainBuilderView,pos={15,15},size={110,15},proc=BuilderContSVTwiddled,title="Delay (ms)"
	SetVariable delaySV,win=TrainBuilderView,limits={0,200000,1},value= _NUM:delay

	SetVariable durationSV,win=TrainBuilderView,pos={15,45},size={125,15},proc=BuilderContSVTwiddled,title="Duration (ms)"
	SetVariable durationSV,win=TrainBuilderView,limits={1,inf,1},value= _NUM:duration

	SetVariable pulseRateSV,win=TrainBuilderView,pos={155,15},size={150,15},proc=BuilderContSVTwiddled,title="Pulse Rate (Hz)"
	SetVariable pulseRateSV,win=TrainBuilderView,limits={0.001,inf,10},value= _NUM:pulseRate

	SetVariable pulseDurationSV,win=TrainBuilderView,pos={155,45},size={140,15},proc=BuilderContSVTwiddled,title="Pulse Duration (ms)"
	SetVariable pulseDurationSV,win=TrainBuilderView,limits={0.001,inf,1},value= _NUM:pulseDuration

	SetVariable baseLevelSV,win=TrainBuilderView,pos={330,15},size={110,15},proc=BuilderContSVTwiddled,title="Base Level"
	SetVariable baseLevelSV,win=TrainBuilderView,limits={-10000,10000,1},value= _NUM:baseLevel

	SetVariable amplitudeSV,win=TrainBuilderView,pos={330,45},size={130,15},proc=BuilderContSVTwiddled,title="Amplitude"
	SetVariable amplitudeSV,win=TrainBuilderView,limits={-10000,10000,10},value= _NUM:amplitude
	
	Button saveAsDACButton,win=TrainBuilderView,pos={601,10},size={90,20},proc=BuilderContSaveAsButtonPressed,title="Save As..."
	//Button saveAsTTLButton,win=TrainBuilderView,pos={601,30},size={90,20},proc=BuilderContSaveAsButtonPressed,title="Save As TTL..."
	Button importButton,win=TrainBuilderView,pos={601,45},size={90,20},proc=BuilderContImportButtonPressed,title="Import..."
	SetDataFolder savedDF
End

//Function TrainBuilderModelInitialize()
//	// Called from the constructor, so DF already set.
//	Variable nParameters=6
//	WAVE /T parameterNames
//	WAVE parametersDefault
//	WAVE parameters
//	Redimension /N=(nParameters) parameterNames
//	parameterNames[0]="delay"
//	parameterNames[1]="duration"
//	parameterNames[2]="pulseRate"
//	parameterNames[3]="pulseDuration"
//	parameterNames[4]="baseLevel"
//	parameterNames[5]="amplitude"
//	Redimension /N=(nParameters) parametersDefault
//	parametersDefault[0]=20		// ms
//	parametersDefault[1]=100		// ms
//	parametersDefault[2]=100		// Hz
//	parametersDefault[3]=2		// ms
//	parametersDefault[4]=0
//	parametersDefault[5]=10
//	Redimension /N=(nParameters) parameters
//	parameters=parametersDefault
//	SVAR signalType
//	signalType="DAC"
//End
//
//Function fillTrainFromParamsBang(w,dt,nScans,parameters,parameterNames)
//	Wave w
//	Variable dt,nScans
//	Wave parameters
//	Wave /T parameterNames
//
//	fillTTLTrainFromParamsBang(w,dt,nScans,parameters,parameterNames)
//
//	//Variable delay=parameters[0]
//	//Variable duration=parameters[1]
//	//Variable pulseRate=parameters[2]				
//	//Variable pulseDuration=parameters[3]
//	Variable baseLevel=parameters[4]
//	Variable amplitude=parameters[5]			
//
//	w=baseLevel+amplitude*w
//End
