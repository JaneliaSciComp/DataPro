#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function MulTrainBuilderViewConstructor() : Graph
	//BuilderModelConstructor("MulTrain")
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_MulTrainBuilder
	WAVE theWave
	WAVE parameters
	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable pulseRate=parameters[2]				
	Variable pulseDuration=parameters[3]			
	Variable trainRate=parameters[4]				
	Variable trainDuration=parameters[5]			
	Variable baseLevel=parameters[6]
	Variable amplitude=parameters[7]			
	// These are all in pixels
	Variable xOffset=105
	Variable yOffset=200
	Variable width=805
	Variable height=400
	// Convert dimensions to points
	Variable pointsPerPixel=72/ScreenResolution
	Variable xOffsetInPoints=pointsPerPixel*xOffset
	Variable yOffsetInPoints=pointsPerPixel*yOffset
	Variable widthInPoints=pointsPerPixel*width
	Variable heightInPoints=pointsPerPixel*height
	Display /W=(xOffsetInPoints,yOffsetInPoints,xOffsetInPoints+widthInPoints,yOffsetInPoints+heightInPoints) /K=1 /N=MulTrainBuilderView theWave as "Multiple Train Builder"
	ModifyGraph /W=MulTrainBuilderView /Z grid(left)=1
	Label /W=MulTrainBuilderView /Z bottom "Time (ms)"
	Label /W=MulTrainBuilderView /Z left "Signal (pure)"
	ModifyGraph /W=MulTrainBuilderView /Z tickUnit(bottom)=1
	ModifyGraph /W=MulTrainBuilderView /Z tickUnit(left)=1
	ControlBar 80

	SetVariable delaySV,win=MulTrainBuilderView,pos={15,15},size={110,15},proc=BuilderContSVTwiddled,title="Delay (ms)"
	SetVariable delaySV,win=MulTrainBuilderView,limits={0,200000,1},value= _NUM:delay

	SetVariable durationSV,win=MulTrainBuilderView,pos={15,45},size={125,15},proc=BuilderContSVTwiddled,title="Duration (ms)"
	SetVariable durationSV,win=MulTrainBuilderView,limits={1,inf,1},value= _NUM:duration

	SetVariable trainRateSV,win=MulTrainBuilderView,pos={155,15},size={150,15},proc=BuilderContSVTwiddled,title="Train Rate (Hz)"
	SetVariable trainRateSV,win=MulTrainBuilderView,limits={0.001,inf,10},value= _NUM:trainRate

	SetVariable trainDurationSV,win=MulTrainBuilderView,pos={155,45},size={140,15},proc=BuilderContSVTwiddled,title="Train Duration (ms)"
	SetVariable trainDurationSV,win=MulTrainBuilderView,limits={0.001,inf,1},value= _NUM:trainDuration

	SetVariable pulseRateSV,win=MulTrainBuilderView,pos={330,15},size={150,15},proc=BuilderContSVTwiddled,title="Pulse Rate (Hz)"
	SetVariable pulseRateSV,win=MulTrainBuilderView,limits={0.001,inf,10},value= _NUM:pulseRate

	SetVariable pulseDurationSV,win=MulTrainBuilderView,pos={330,45},size={140,15},proc=BuilderContSVTwiddled,title="Pulse Duration (ms)"
	SetVariable pulseDurationSV,win=MulTrainBuilderView,limits={0.001,inf,1},value= _NUM:pulseDuration

	SetVariable baseLevelSV,win=MulTrainBuilderView,pos={330+175,15},size={110,15},proc=BuilderContSVTwiddled,title="Base Level"
	SetVariable baseLevelSV,win=MulTrainBuilderView,limits={-10000,10000,1},value= _NUM:baseLevel

	SetVariable amplitudeSV,win=MulTrainBuilderView,pos={330+175,45},size={130,15},proc=BuilderContSVTwiddled,title="Amplitude"
	SetVariable amplitudeSV,win=MulTrainBuilderView,limits={-10000,10000,10},value= _NUM:amplitude
	
	Button saveAsDACButton,win=MulTrainBuilderView,pos={701,10},size={90,20},proc=BuilderContSaveAsButtonPressed,title="Save As..."
	//Button saveAsTTLButton,win=MulTrainBuilderView,pos={601,30},size={90,20},proc=BuilderContSaveAsButtonPressed,title="Save As TTL..."
	Button importButton,win=MulTrainBuilderView,pos={701,45},size={90,20},proc=BuilderContImportButtonPressed,title="Import..."
	SetDataFolder savedDF
End

//Function MulTrainBuilderModelInitialize()
//	// Called from the constructor, so DF already set.
//	Variable nParameters=8
//	WAVE /T parameterNames
//	WAVE parametersDefault
//	WAVE parameters
//	Redimension /N=(nParameters) parameterNames
//	parameterNames[0]="delay"
//	parameterNames[1]="duration"
//	parameterNames[2]="pulseRate"
//	parameterNames[3]="pulseDuration"
//	parameterNames[4]="trainRate"
//	parameterNames[5]="trainDuration"
//	parameterNames[6]="baseLevel"
//	parameterNames[7]="amplitude"
//	Redimension /N=(nParameters) parametersDefault
//	parametersDefault[0]=25		// ms
//	parametersDefault[1]=150		// ms
//	parametersDefault[2]=100		// Hz
//	parametersDefault[3]=2		// ms
//	parametersDefault[4]=20		// Hz
//	parametersDefault[5]=25		// ms	
//	parametersDefault[6]=0
//	parametersDefault[7]=10
//	Redimension /N=(nParameters) parameters
//	parameters=parametersDefault
//	SVAR signalType
//	signalType="DAC"
//End
//
//Function fillMulTrainFromParamsBang(w,dt,nScans,parameters,parameterNames)
//	Wave w
//	Variable dt,nScans
//	Wave parameters
//	Wave /T parameterNames
//
//	fillTTLMTrainFromParamsBang(w,dt,nScans,parameters,parameterNames)
//
////	Variable delay=parameters[0]
////	Variable duration=parameters[1]
////	Variable pulseRate=parameters[2]				
////	Variable pulseDuration=parameters[3]
////	Variable trainRate=parameters[4]				
////	Variable trainDuration=parameters[5]
//	Variable baseLevel=parameters[6]
//	Variable amplitude=parameters[7]			
//
//	w=baseLevel+amplitude*w
//End
