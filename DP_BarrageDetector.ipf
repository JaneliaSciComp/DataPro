#pragma rtGlobals=3		// Use modern global access method, strict wave access

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
	Variable /G iCurrentStimDAC=0
	Variable /G dacMultiplierSaved=SweeperGetDACMultiplier(iCurrentStimDAC)
	
	// Restore the original data folder
	SetDataFolder savedDF	
End


Function BarrageDetectorSaveDACMult()
	// Save the current DF
	String savedDF=GetDataFolder(1)
	
	// Switch to DF
	SetDataFolder root:DP_BarrageDetector

	// Instance vars
	NVAR iCurrentStimDAC
	NVAR dacMultiplierSaved
	
	// Save the DAC multiplier
	dacMultiplierSaved=SweeperGetDACMultiplier(iCurrentStimDAC)
	
	// Restore the original data folder
	SetDataFolder savedDF	
End


Function BarrageDetectorRestoreDACMult()
	// Save the current DF
	String savedDF=GetDataFolder(1)
	
	// Switch to DF
	SetDataFolder root:DP_BarrageDetector

	// Instance vars
	NVAR iCurrentStimDAC
	NVAR dacMultiplierSaved
	
	// Restore the DAC multiplier
	SweeperSetDACMultiplier(iCurrentStimDAC,dacMultiplierSaved)
	SweeperViewSweeperChanged()	// tell the view to update
	
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

	// Local vars
	String vWaveBaseName="ad0"
	Variable tfStim=1500 		// ms
	Variable vSpikeThreshold=-20		// mV
	Variable maxSpikeFreq=200		// Hz
	Variable nSpikesMinBarrage=4

	//tfStim=100 		// ms
	//vSpikeThreshold=0		// mV
	//nSpikesMinBarrage=1
	
	// Get a wave reference to the wave we want to check for spikes
	String vWaveNameThisRel=WaveNameFromBaseAndSweep(vWaveBaseName,iThisSweep)
	String vWaveNameThisAbs=sprintf1s("root:%s",vWaveNameThisRel)
	Wave v=$vWaveNameThisAbs
	
	// Count the spikes after the stim ends
	Variable nSpikesAfterStim=NSpikesAfterSetTimeForOneSweep(v,tfStim,vSpikeThreshold,maxSpikeFreq)
	if (nSpikesAfterStim>=nSpikesMinBarrage)
		SweeperSetDACMultiplier(iCurrentStimDAC,0)	// zero the stim
		SweeperViewSweeperChanged()	// tell the view to update
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


