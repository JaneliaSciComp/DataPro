//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

Function BarrageDetectorViewConstructor() : Panel
	// If the view already exists, just raise it
	if (PanelExists("BarrageDetectorView"))
		DoWindow /F BarrageDetectorView
		return 0
	endif

	// Save, set the DF
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_BarrageDetector
	
	// These are all in pixels
	Variable xOffset=100
	Variable yOffset=100
	Variable width=306
	Variable height=250
	
	Variable svXOffset=20
	Variable svWidth=200
	
	// Convert dimensions to points
	Variable pointsPerPixel=72/ScreenResolution
	Variable xOffsetInPoints=pointsPerPixel*xOffset
	Variable yOffsetInPoints=pointsPerPixel*yOffset
	Variable widthInPoints=pointsPerPixel*width
	Variable heightInPoints=pointsPerPixel*height
	NewPanel /W=(xOffsetInPoints,yOffsetInPoints,xOffsetInPoints+widthInPoints,yOffsetInPoints+heightInPoints) /K=1 /N=BarrageDetectorView as "Barrage Detector"
	ModifyPanel /W=BarrageDetectorView fixedSize=1
	
	SetVariable vWaveBaseNameSV,win=BarrageDetectorView,pos={svXOffset,10},size={svWidth,16},bodyWidth=50,title="Voltage Wave Base Name:"
	SetVariable vWaveBaseNameSV,win=BarrageDetectorView,value= vWaveBaseName

	SetVariable iCurrentStimDACSV,win=BarrageDetectorView,pos={svXOffset,40},size={svWidth,16},bodyWidth=50,title="Current DAC:"
	SetVariable iCurrentStimDACSV,win=BarrageDetectorView,limits={0,3,1}, value= iCurrentStimDAC

	SetVariable tfStimSV,win=BarrageDetectorView,pos={svXOffset,70},size={svWidth,16},bodyWidth=50,title="Delay to Stimulus End (ms):"
	SetVariable tfStimSV,win=BarrageDetectorView,limits={0,inf,1}, value= tfStim

	SetVariable vSpikeThresholdSV,win=BarrageDetectorView,pos={svXOffset,100},size={svWidth,16},bodyWidth=50,title="Spike Threshold (mV):"
	SetVariable vSpikeThresholdSV,win=BarrageDetectorView,limits={-inf,inf,1}, value= vSpikeThreshold

	SetVariable maxSpikeFreqSV,win=BarrageDetectorView,pos={svXOffset,130},size={svWidth,16},bodyWidth=50,title="Maximum Spike Frequency (Hz):"
	SetVariable maxSpikeFreqSV,win=BarrageDetectorView,limits={1,2000,1}, value= maxSpikeFreq
	
	SetVariable nSpikesMinBarrageSV,win=BarrageDetectorView,pos={svXOffset,160},size={svWidth,16},bodyWidth=50,title="Minimum Spikes for Barrage:"
	SetVariable nSpikesMinBarrageSV,win=BarrageDetectorView,limits={1,inf,1}, value= nSpikesMinBarrage
		
	// Sync to model
	//SweeperViewSweeperChanged()
	
	// Restore original DF
	SetDataFolder savedDF
End

