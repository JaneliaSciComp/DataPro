#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function TrainWPPBuilderViewConstructor() : Graph
	//BuilderModelConstructor("Train")
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_TrainWPPBuilder
	WAVE theWave
	WAVE parameters
	
	Variable delay=parameters[0]
	Variable prepulseDuration=parameters[1]
	Variable prepulseAmplitude=parameters[2]
	Variable delayFromPrepulseToTrain=parameters[3]
	Variable trainDuration=parameters[4]
	Variable pulseRate=parameters[5]
	Variable pulseDuration=parameters[6]
	Variable pulseAmplitude=parameters[7]
	Variable baseLevel=parameters[8]
	
	// These are all in pixels
	Variable xOffset=105
	Variable yOffset=200
	Variable width=1000
	Variable height=400
	
	Variable svWidth=160		// width of each SV
	Variable svHeight=16		// height of each SV
	Variable svBodyWidth=50
	
	Variable svHSpaceWidth=15	// horizontal space between SVs
	Variable svVSpaceHeight=30	// vertical space between SVs
	
	Variable svXOffset=5
	Variable svYOffset=15
	
	// Convert dimensions to points
	Variable pointsPerPixel=72/ScreenResolution
	Variable xOffsetInPoints=pointsPerPixel*xOffset
	Variable yOffsetInPoints=pointsPerPixel*yOffset
	Variable widthInPoints=pointsPerPixel*width
	Variable heightInPoints=pointsPerPixel*height
	Display /W=(xOffsetInPoints,yOffsetInPoints,xOffsetInPoints+widthInPoints,yOffsetInPoints+heightInPoints) /K=1 /N=TrainWPPBuilderView theWave as "Train-with-Prepulse Builder"
	ModifyGraph /W=TrainWPPBuilderView /Z grid(left)=1
	Label /W=TrainWPPBuilderView /Z bottom "Time (ms)"
	Label /W=TrainWPPBuilderView /Z left "Signal (pure)"
	ModifyGraph /W=TrainWPPBuilderView /Z tickUnit(bottom)=1
	ModifyGraph /W=TrainWPPBuilderView /Z tickUnit(left)=1
	ControlBar 80

	SetVariable delaySV,win=TrainWPPBuilderView,bodyWidth=svBodyWidth,proc=BuilderContSVTwiddled,title="Delay (ms)"
	SetVariable delaySV,win=TrainWPPBuilderView,pos={svXOffset,svYOffset},size={svWidth,svHeight}
	SetVariable delaySV,win=TrainWPPBuilderView,limits={-inf,inf,1},value= _NUM:delay

	SetVariable prepulseDurationSV,win=TrainWPPBuilderView,pos={svXOffset+svWidth+svHSpaceWidth,svYOffset},size={svWidth,svHeight},bodyWidth=svBodyWidth,proc=BuilderContSVTwiddled,title="Prepulse Duration (ms)"
	SetVariable prepulseDurationSV,win=TrainWPPBuilderView,limits={0,inf,1},value= _NUM:prepulseDuration

	SetVariable prepulseAmplitudeSV,win=TrainWPPBuilderView,pos={svXOffset+svWidth+svHSpaceWidth+svWidth+svHSpaceWidth,svYOffset},size={svWidth,svHeight},bodyWidth=svBodyWidth,proc=BuilderContSVTwiddled,title="Prepulse Amplitude"
	SetVariable prepulseAmplitudeSV,win=TrainWPPBuilderView,limits={-inf,inf,1},value= _NUM:prepulseAmplitude

	SetVariable delayFromPrepulseToTrainSV,win=TrainWPPBuilderView,pos={svXOffset+svWidth+svHSpaceWidth+svWidth+svHSpaceWidth+svWidth+svHSpaceWidth,svYOffset},size={svWidth,svHeight},bodyWidth=svBodyWidth,proc=BuilderContSVTwiddled,title="PP-to-Train Delay (ms)"
	SetVariable delayFromPrepulseToTrainSV,win=TrainWPPBuilderView,limits={-inf,inf,1},value= _NUM:delayFromPrepulseToTrain

	SetVariable trainDurationSV,win=TrainWPPBuilderView,pos={svXOffset+svWidth+svHSpaceWidth+svWidth+svHSpaceWidth+svWidth+svHSpaceWidth+svWidth+svHSpaceWidth,svYOffset},size={svWidth,svHeight},bodyWidth=svBodyWidth,proc=BuilderContSVTwiddled,title="Train Duration (ms)"
	SetVariable trainDurationSV,win=TrainWPPBuilderView,limits={0,inf,1},value= _NUM:trainDuration

	SetVariable pulseRateSV,win=TrainWPPBuilderView,pos={svXOffset,svYOffset+svVSpaceHeight},size={svWidth,svHeight},bodyWidth=svBodyWidth,proc=BuilderContSVTwiddled,title="Pulse Rate (Hz)"
	SetVariable pulseRateSV,win=TrainWPPBuilderView,limits={0.001,inf,10},value= _NUM:pulseRate

	SetVariable pulseDurationSV,win=TrainWPPBuilderView,pos={svXOffset+svWidth+svHSpaceWidth,svYOffset+svVSpaceHeight},size={svWidth,svHeight},bodyWidth=svBodyWidth,proc=BuilderContSVTwiddled,title="Pulse Duration (ms)"
	SetVariable pulseDurationSV,win=TrainWPPBuilderView,limits={0.001,inf,1},value= _NUM:pulseDuration

	SetVariable pulseAmplitudeSV,win=TrainWPPBuilderView,pos={svXOffset+svWidth+svHSpaceWidth+svWidth+svHSpaceWidth,svYOffset+svVSpaceHeight},size={svWidth,svHeight},bodyWidth=svBodyWidth,proc=BuilderContSVTwiddled,title="Pulse Amplitude"
	SetVariable pulseAmplitudeSV,win=TrainWPPBuilderView,limits={-inf,inf,1},value= _NUM:pulseAmplitude

	SetVariable baseLevelSV,win=TrainWPPBuilderView,pos={svXOffset+svWidth+svHSpaceWidth+svWidth+svHSpaceWidth+svWidth+svHSpaceWidth,svYOffset+svVSpaceHeight},size={svWidth,svHeight},bodyWidth=svBodyWidth,proc=BuilderContSVTwiddled,title="Base Level"
	SetVariable baseLevelSV,win=TrainWPPBuilderView,limits={-inf,inf,1},value= _NUM:baseLevel
	
	Button saveAsDACButton,win=TrainWPPBuilderView,pos={width-100,10},size={90,20},proc=BuilderContSaveAsButtonPressed,title="Save As..."
	Button importButton,win=TrainWPPBuilderView,pos={width-100,45},size={90,20},proc=BuilderContImportButtonPressed,title="Import..."

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
