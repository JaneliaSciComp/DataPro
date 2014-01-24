//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

//	This is one of the only files you should modify as the user.

#pragma rtGlobals=1		// Use modern global access method.

Function SetupDigitizerForUser()
	// USER: DON'T CHANGE THE NEXT TWO LINES
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Digitizer
	
	// DECLARE THE digitizer variables
	WAVE /T unitsFromMode
	WAVE adcGainAll
	WAVE dacGainAll
	
//	Set the units you will be working in for current and voltage
//	It is extremely important that you set the gains using the units you designate below
//	For example, if you want to work in pA for current units,
//	but your amplifier says the gain is 1 V/nA, you need to set the gain to 0.001 (V/pA)
	unitsFromMode={"pA","mV"}
//	set up the dac and adc channels and gains (default values)
//	for voltage clamp, units are unitsVoltage/V
	//dacGainAll[0][0]=10000
	//dacGainAll[1][0]=10000
	//dacGainAll[2][0]=10000		
	//dacGainAll[3][0]=10000
	dacGainAll[0][0]=100
	dacGainAll[1][0]=100
	dacGainAll[2][0]=100
	dacGainAll[3][0]=100
//	for current clamp, units are unitsCurrent/V
//	dacGainAll[0][1]=20
//	dacGainAll[1][1]=20	
//	dacGainAll[2][1]=20
//	dacGainAll[3][1]=20
	dacGainAll[0][1]=200
	dacGainAll[1][1]=200	
	dacGainAll[2][1]=200
	dacGainAll[3][1]=200
//	read ADCgain values off the appropriate output on the amplifier
//	don't forget filter gain and appropriate units conversion
//	for voltage clamp, units are volts/unitsCurrent 
//	adcGainAll[0][0]=0.0001
//	adcGainAll[1][0]=0.0001
//	adcGainAll[2][0]=0.0001
//	adcGainAll[3][0]=0.0001
//	adcGainAll[4][0]=0.0001
//	adcGainAll[5][0]=0.0001
//	adcGainAll[6][0]=0.0001
//	adcGainAll[7][0]=0.0001
	adcGainAll[0][0]=0.05
	adcGainAll[1][0]=0.05
	adcGainAll[2][0]=0.05
	adcGainAll[3][0]=0.05
	adcGainAll[4][0]=0.05
	adcGainAll[5][0]=0.05
	adcGainAll[6][0]=0.05
	adcGainAll[7][0]=0.05
//	for current clamp, units are volts/unitsVoltage
	adcGainAll[0][1]=0.01
	adcGainAll[1][1]=0.01
	adcGainAll[2][1]=0.01
	adcGainAll[3][1]=0.01
	adcGainAll[4][1]=0.01
	adcGainAll[5][1]=0.01
	adcGainAll[6][1]=0.01
	adcGainAll[7][1]=0.01
	// USER: DON'T CHANGE ANYTHING BELOW HERE
	SetDataFolder savedDF
End

Function SetupSweeperForUser()
	// USER: DON'T CHANGE THE NEXT TWO LINES
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Sweeper
	
	// DECLARE THE digitizer variables
	WAVE dacMultiplier
	// Variables for synaptic stimulation
	NVAR builtinTTLPulseDelay
	NVAR builtinTTLPulseDuration
	
//	multiplier values for dacs
	dacMultiplier[0]=1
	dacMultiplier[1]=1
	dacMultiplier[2]=1
	dacMultiplier[3]=1
//	Variables for synaptic stimulation
	builtinTTLPulseDelay=50
	builtinTTLPulseDuration=0.1
	// USER: DON'T CHANGE ANYTHING BELOW HERE
	SetDataFolder savedDF
End




// This gets run just after DataPro is initialized, always
Function PostInitializationHook()
End



//
// Functions below are only called if "Auto Analyze On" is checked in the Sweeper Panel
//

// Use the PreTrialHook function to call code that should occur before the acquisition of each trial
Function PreTrialHook()
	//Print "Inside PreTrialHook() function!"
End

// Use the PreSweepHook function to call code that should occur before the acquisition of each sweep
Function PreSweepHook(iThisSweep)
	Variable iThisSweep	// index of the just-acquired sweep
	//Print "Inside PreSweepHook() function!"
End

// Use the PostSweepHook function to call analysis that should occur after the acquisition of each sweep
Function PostSweepHook(iThisSweep)
	Variable iThisSweep	// index of the just-acquired sweep
	//Print "Inside PostSweepHook() function!"
End

// Use the PostTrialHook function to call analysis that should occur after the acquisition of each trial
Function PostTrialHook()
	//Print "Inside PostTrialHook() function!"
End


