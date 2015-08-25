#pragma rtGlobals=3		// Use modern global access method, strict wave access

//// Declare constants that are limited to this source file
//static Strconstant vWaveBaseName="ad0"
//static Constant iCurrentStimDAC=1
//static Constant tfStim=1500 		// ms
//static Constant vSpikeThreshold=-20		// mV
//static Constant maxSpikeFreq=200		// Hz
//static Constant nSpikesMinBarrage=4

Function BarrageDetectorConstructor()
	// if the DF already exists, nothing to do
	if (DataFolderExists("root:DP_BarrageDetector"))
		return 0		// have to return something
	endif

	// Save the current DF
	String savedDF=GetDataFolder(1)
	
	// Create a new DF, switch to it
	NewDataFolder /O /S root:DP_BarrageDetector
	
	// Create instance vars
	// parameters	
	String /G vWaveBaseName="ad0"
	Variable /G iCurrentStimDAC=1
	Variable /G tfStim=1500 		// ms
	Variable /G vSpikeThreshold=-20		// mV
	Variable /G maxSpikeFreq=200		// Hz
	Variable /G nSpikesMinBarrage=4
	Variable /G isCurrentTurnedOn=1	// boolean
	Variable /G initialCurrentStepSize=20	// pA
	Variable /G currentStepSizeDelta=20	// pA	
	// internal state
	//Variable /G iCurrentStimDAC=0
	//Variable /G dacMultiplierSaved=SweeperGetDACMultiplier(iCurrentStimDAC)
	//Variable /G builtinPulseAmplitudeSaved = SweeperGetBuiltinPulseAmplitude()
	
	// Restore the original data folder
	SetDataFolder savedDF	
End


Function BarrageDetectorSaveBuiltinA()
	// Save the current DF
	String savedDF=GetDataFolder(1)
	
	// Switch to DF
	SetDataFolder root:DP_BarrageDetector

	// Instance vars
	//NVAR iCurrentStimDAC
	//NVAR builtinPulseAmplitudeSaved
	NVAR isCurrentTurnedOn
	
	// Save the DAC multiplier
	//Printf "iCurrentStimDAC: %d\r", iCurrentStimDAC
	//dacMultiplierSaved=SweeperGetDACMultiplier(iCurrentStimDAC)
	isCurrentTurnedOn = 1
	//builtinPulseAmplitudeSaved = SweeperGetBuiltinPulseAmplitude()
	
	// Restore the original data folder
	SetDataFolder savedDF	
End


Function BarrageDetectorSetWaveform(iThisSweep,iSweepWithinTrial)
	Variable iThisSweep
	Variable iSweepWithinTrial

	// Save the current DF
	String savedDF=GetDataFolder(1)

	// Switch to DF
	SetDataFolder root:DP_BarrageDetector

	// Instance vars
	NVAR isCurrentTurnedOn		// boolean
	NVAR initialCurrentStepSize	// pA
	NVAR currentStepSizeDelta	// pA	
	
	// Set the amplitude of the built-in stimulus
	Variable stepAmplitude = isCurrentTurnedOn * (initialCurrentStepSize + iSweepWithinTrial * currentStepSizeDelta)
	//Printf "iSweepWithinTrial: %d\r", iSweepWithinTrial
	//Printf "stepAmplitude: %d\r", stepAmplitude	

	SweeperSetBuiltinPulseAmplitude(stepAmplitude)
	
	// Restore the original data folder
	SetDataFolder savedDF	
End


Function BarrageDetectorRestoreBuiltinA()
	// Save the current DF
	String savedDF=GetDataFolder(1)
	
	// Switch to DF
	SetDataFolder root:DP_BarrageDetector

	// Instance vars
	//NVAR builtinPulseAmplitudeSaved
	NVAR initialCurrentStepSize	// pA
	
	// Restore the builtin amplitude
	SweeperSetBuiltinPulseAmplitude(initialCurrentStepSize)
	
	// Restore the original data folder
	SetDataFolder savedDF	
End


Function BarrageDetectorSilenceStimIf(iThisSweep)
	Variable iThisSweep

	// Save the current DF
	String savedDF=GetDataFolder(1)
	
	// Switch to DF
	SetDataFolder root:DP_BarrageDetector

	// Instance vars
	NVAR iCurrentStimDAC
	SVAR vWaveBaseName
	NVAR tfStim
	NVAR vSpikeThreshold
	NVAR maxSpikeFreq
	NVAR nSpikesMinBarrage
	NVAR isCurrentTurnedOn
	
	// Get a wave reference to the wave we want to check for spikes
	String vWaveNameThisRel=WaveNameFromBaseAndSweep(vWaveBaseName,iThisSweep)
	String vWaveNameThisAbs=sprintf1s("root:%s",vWaveNameThisRel)
	Wave v=$vWaveNameThisAbs
	
	// Count the spikes after the stim ends
	if ( WaveExists(v) )
		Variable nSpikesAfterStim=NSpikesAfterSetTimeForOneSweep(v,tfStim,vSpikeThreshold,maxSpikeFreq)
		Printf "Number of spikes after stim: %d\r", nSpikesAfterStim
		if (nSpikesAfterStim>=nSpikesMinBarrage)
			isCurrentTurnedOn = 0
		endif
	else
		Printf "Barrage Detector voltage wave doesn't exist.\r"
	endif
	
	// Restore the original data folder
	SetDataFolder savedDF	
End


Function NSpikesAfterSetTimeForOneSweep(v,tMark,vSpikeThreshold,maxSpikeFreq)
	WAVE v
	Variable tMark		// ms
	Variable vSpikeThreshold	// mV
	Variable maxSpikeFreq	// Hz
	
	// Determine the times of the all the spikes, store in tSpikes
	Variable minSpikeDt=1000/maxSpikeFreq		// Hz -> ms
	Variable nPoints=numpnts(v)
	Make /FREE /N=(nPoints) tSpikes
	FindLevels /DEST=tSpikes /EDGE=1 /M=(minSpikeDt) /Q v, vSpikeThreshold
	Variable nCrossingsFound=V_LevelsFound
	Redimension /N=(nCrossingsFound) tSpikes
	
	Variable nSpikesAfterMark
	if (nCrossingsFound>0)
		// Create a boolean array that is true iff a spike is after the cutoff time
		Make /FREE /N=(nCrossingsFound) isAfterMark
		isAfterMark= (tMark<=tSpikes[p])
		nSpikesAfterMark=sum(isAfterMark)	// annoyingly, sum throws an error if isAfterMark has zero elements
	else
		nSpikesAfterMark=0
	endif
 	
 	return nSpikesAfterMark
End


