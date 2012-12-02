//	DataPro//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18//	Nelson Spruston//	Northwestern University//	project began 10/27/1998#pragma rtGlobals=1		// Use modern global access method.Function GetNumADCChannelsInUse()	// Gets the number of ADC channels currently in use in the model.		// Change to the DigitizerControl data folder	String savDF=GetDataFolder(1)	NewDataFolder /O/S root:DP_DigitizerControl	// Declare the DF vars we need	WAVE adcon	// Build up the strings that the ITC functions use to sequence the	// inputs and outputs		Variable nADCChannelsInUse=0	Variable i	for (i=0; i<8; i+=1)		nADCChannelsInUse+=adcon[i]	endfor		// Restore the original DF	SetDataFolder savDF	return nADCChannelsInUseEndFunction GetNumDACChannelsInUse()	// Gets the number of DAC channels currently in use in the model.	// Change to the DigitizerControl data folder	String savDF=GetDataFolder(1)	NewDataFolder /O/S root:DP_DigitizerControl	// Declare the DF vars we need	WAVE dacon	// Build up the strings that the ITC functions use to sequence the	// inputs and outputs		Variable nDACChannelsInUse=0	Variable i	for (i=0; i<4; i+=1)		nDACChannelsInUse+=dacon[i]	endfor		// Restore the original DF	SetDataFolder savDF	return nDACChannelsInUseEndFunction GetNumTTLOutputChannelsInUse()	// Gets the number of TTL output channels currently in use in the model.	// Change to the DigitizerControl data folder	String savDF=GetDataFolder(1)	NewDataFolder /O/S root:DP_DigitizerControl	// Declare the DF vars we need	WAVE ttlon	// Build up the strings that the ITC functions use to sequence the	// inputs and outputs		Variable nTTLOutputChannelsInUse=0	Variable i	for (i=0; i<4; i+=1)		nTTLOutputChannelsInUse+=ttlon[i]	endfor		// Restore the original DF	SetDataFolder savDF	return nTTLOutputChannelsInUseEndFunction /S GetRawDACSequence()	// Computes the DAC sequence string needed by the ITC functions, given the model state.	//  Note, however, that this is the RAW sequence string.  The raw DAC sequence must be reconciled with	// the raw ADC sequence to produce the final DAC and ADC seqeuences.	// Change to the DigitizerControl data folder	String savDF=GetDataFolder(1)	NewDataFolder /O/S root:DP_DigitizerControl	WAVE dacon, ttlon	// boolean waves that say which DAC, TTL channels are on	// Build up the strings that the ITC functions use to sequence the	// inputs and outputs, by probing the view state	String dacSequence=""	Variable i	for (i=0; i<4; i+=1)		if ( dacon[i] )			dacSequence+=num2str(i)		endif	endfor	// All the TTL outputs are controlled by a single 16-bit number.	// (There are 16 TTL outputs, but only 0-3 are exposed in the front panel.  All are available	// on a multi-pin connector in the back.)	// If the user has checked any of the TTL outputs, we need to add a "D" to the DAC sequence,	// which reads a 16-bit value to set all of the TTL outputs.	if (sum(ttlon)>0)		dacSequence+="D"	endif		// Restore the original DF	SetDataFolder savDF	return dacSequence	EndFunction /S GetRawADCSequence()	// Computes the ADC sequence string needed by the ITC functions, given the model state	// Note, however, that this is the RAW sequence string.  The raw DAC sequence must be reconciled with	// the raw ADC sequence to produce the final DAC and ADC seqeuences.	// Change to the DigitizerControl data folder	String savDF=GetDataFolder(1)	NewDataFolder /O/S root:DP_DigitizerControl	// Declare the DF vars we need	WAVE adcon	// Build up the strings that the ITC functions use to sequence the	// inputs and outputs		String adcSequence=""	Variable i	for (i=0; i<8; i+=1)		if ( adcon[i] )			adcSequence+=num2str(i)		endif	endfor	// Restore the original DF	SetDataFolder savDF	return adcSequence	EndFunction /S ReconcileADCSequence(adcSequenceRaw,dacSequenceRaw)	// Reconciles the raw ADC sequence with the given raw DAC sequence, returning an	// ADC sequence which consists of some number of repeats of the raw ADC sequence.	String adcSequenceRaw,dacSequenceRaw	Variable nCommon=lcmLength(dacSequenceRaw,adcSequenceRaw)  // the reconciled sequences must be the same length	Variable nRepeats=nCommon/strlen(adcSequenceRaw)	String adcSequence=RepeatString(adcSequenceRaw,nRepeats)			return adcSequence	EndFunction /S ReconcileDACSequence(dacSequenceRaw,adcSequenceRaw)	// Reconciles the raw DAC sequence with the given raw ADC sequence, returning a	// DAC sequence which consists of some number of repeats of the raw DAC sequence.	String adcSequenceRaw,dacSequenceRaw	Variable nCommon=lcmLength(dacSequenceRaw,adcSequenceRaw)  // the reconciled sequences must be the same length	Variable nRepeats=nCommon/strlen(dacSequenceRaw)	String dacSequence=RepeatString(dacSequenceRaw,nRepeats)			return dacSequenceEndFunction /S GetDACSequence()	// Computes the DAC sequence string needed by the ITC functions, given the model state.	String dacSequenceRaw=GetRawDACSequence()	String adcSequenceRaw=GetRawADCSequence()	String dacSequence=ReconcileDACSequence(dacSequenceRaw,adcSequenceRaw)	return dacSequence	EndFunction /S GetADCSequence()	// Computes the ADC sequence string needed by the ITC functions, given the model state.	String dacSequenceRaw=GetRawDACSequence()	String adcSequenceRaw=GetRawADCSequence()	String adcSequence=ReconcileADCSequence(adcSequenceRaw,dacSequenceRaw)	return adcSequence	EndFunction GetSequenceLength()	// Computes the ADC sequence string needed by the ITC functions, given the model state.	String dacSequenceRaw=GetRawDACSequence()	String adcSequenceRaw=GetRawADCSequence()	Variable nSequence=lcmLength(dacSequenceRaw,adcSequenceRaw)	return nSequenceEndFunction /WAVE GetMultiplexedTTLOutput()	// Multiplexes the active TTL outputs onto a single wave.  If there are no active and valid	// TTL output waves, returns a length-zero wave.	WAVE ttlon	WAVE /T ttlWavePopupSelection	Make /FREE /N=(0) multiplexedTTL  // default return value		Variable firstActiveChannel=1	// boolean	Variable i	for (i=0; i<4; i+=1)		if (ttlon[i])			if ( AreStringsEqual(ttlWavePopupSelection[i],"_none_") )				Abort "An active TTL output channel can't have the wave set to \"_none_\"."			endif			String thisTTLWaveNameRel=ttlWavePopupSelection[i]			WAVE thisTTLWave=$thisTTLWaveNameRel			if (firstActiveChannel)				firstActiveChannel=0				Duplicate /FREE /O thisTTLWave multiplexedTTL				multiplexedTTL=0			endif			multiplexedTTL+=(2^i)*thisTTLWave		endif	endfor		return multiplexedTTLEndFunction /WAVE GetFIFOout()	// Builds the FIFOout wave, as a free wave, and returns a reference to it.		// Don't blather to the console	Silent 1		// Switch to the ADCDAC data folder	String savDF=GetDataFolder(1)	SetDataFolder root:DP_DigitizerControl		// Declare data folder vars we access	WAVE /T dacWavePopupSelection	NVAR error	WAVE dacMultiplier		// The ADCDAC panel must exist for this to work, so check for it	if (!PanelExists("DigitizerControl"))		error=1		Abort "You need to open the ADC/DAC control panel first. Once it's open, you can hide it by double clicking the top bar."	endif		// get the DAC sequence	String daseq=GetDACSequence()	Variable seqLength=strlen(daseq)		// These things will be set to finite values at soon as we are able to determine them from a wave	Variable atLeastOneOutput=0		// boolean	Variable dt=nan		// sampling interval, ms	Variable nScans=nan	// number of samples in each output wave ("scans" is an NI-ism)		// the default value of FIFOout	Make /FREE /N=(0) FIFOout		// First, need to multiplex all the TTL outputs the user has specified onto a single wave, where each	// sample is interpreted 16-bit number that specifies all the 16 TTL outputs, only the first four	// of which are exposed on the front panel.	// Source TTL waves should consist of zeros (low) and ones (high) only.	// The multiplexed wave is called multiplexedTTL	Wave multiplexedTTL=GetMultiplexedTTLOutput()	Variable atLeastOneTTLOutput=(numpnts(multiplexedTTL)>0)	if (atLeastOneTTLOutput)		atLeastOneOutput=1		dt=deltax(multiplexedTTL)		nScans=numpnts(multiplexedTTL)		Redimension /N=(seqLength*nScans) FIFOout	endif	// now assign values to FIFOout according to the DAC sequence	Variable outgain	String stepAsString=""	Variable i	for (i=0; i<seqLength; i+=1)		// Either use the specified DAC wave, or use the multiplexed TTL wave, as appropriate		if ( AreStringsEqual(daseq[i],"D") )			// Means this is the slot for the multiplexed TTL output			Wave thisDACWave=multiplexedTTL			outgain=1		else						Variable iDACChannel=str2num(daseq[i])			if ( AreStringsEqual(dacWavePopupSelection[iDACChannel],"_none_") )				Abort "An active DAC channel can't have the wave set to \"_none_\"."			endif			String thisDACWaveNameRel=dacWavePopupSelection[iDACChannel]			Wave thisDACWave=$thisDACWaveNameRel			outgain=ComputeOutputGain(iDACChannel)		endif		// If this is the first output, set some variables and dimension FIFOout.  Otherwise,		// make sure this wave is consistent with the previous ones.		if (atLeastOneOutput)			// If there has already been an output wave, make sure this one agrees with it			if (dt!=deltax(thisDACWave))				Abort "There is a sample interval mismatch in your DAC and/or TTL output waves."			endif			if (nScans!=numpnts(thisDACWave))				Abort "There is a mismatch in the number of points in your DAC and/or TTL output waves."			endif		else			// If this is the first output wave, use its dimensions to create FIFOout			atLeastOneOutput=1			dt=deltax(thisDACWave)			nScans=numpnts(thisDACWave)			Redimension /N=(seqLength*nScans) FIFOout		endif		// Get the step value, if it's present in this wave		String stepAsStringThis=StringByKeyInWaveNote(thisDACWave,"STEP")		if ( !IsEmptyString(stepAsStringThis) )			stepAsString=stepAsStringThis		endif		// Finally, write this output wave into FIFOout		FIFOout[i,;seqLength]=thisDACWave[floor(p/seqLength)]*outgain*dacMultiplier[iDACChannel]	endfor			// Set the time scaling for FIFOout	Setscale /P x, 0, dt/seqLength, "ms", FIFOout		// Set the STEP wave note in FIFOout, so that it can be copied into the ADC waves eventually	if (!IsEmptyString(stepAsString))		ReplaceStringByKeyInWaveNote(FIFOout,"STEP",stepAsString)	endif		// Restore the data folder	SetDataFolder savDF		// Return	return FIFOoutEndFunction /S adcGainUnitsStringFromAdcType(adcType)	// Returns the units string for an ADC of the given type.	// Currently, adcType can be 1 (current) or 2 (voltage)	Variable adcType	// Switch to the ADCDAC data folder	String savDF=GetDataFolder(1)	SetDataFolder root:DP_DigitizerControl	// Core of the method	SVAR unitsCurrent, unitsVoltage	String out=""	if (adcType==1)		out=sprintf1s("V/%s",unitsCurrent)	elseif (adcType==2)		out=sprintf1s("V/%s",unitsVoltage)	endif			// Restore the data folder	SetDataFolder savDF		// Return		return outEndFunction /S dacGainUnitsStringFromDacType(dacType)	// Returns the units string for a DAC of the given type.	// Currently, dacType can be 1 (current) or 2 (voltage)	Variable dacType	// Switch to the digitizer data folder	String savDF=GetDataFolder(1)	SetDataFolder root:DP_DigitizerControl	// Core of the method	SVAR unitsCurrent, unitsVoltage	String out=""	if (dacType==1)		out=sprintf1s("%s/V",unitsCurrent)	elseif (dacType==2)		out=sprintf1s("%s/V",unitsVoltage)	endif			// Restore the data folder	SetDataFolder savDF		// Return		return outEndFunction SwitchADCChannelMode(iChannel,mode)	// Switches the indicated ADC channel to the given mode.  Currently, the mode can be 1 (==current)	// or 2 (==voltage)	Variable iChannel, mode		String savDF=GetDataFolder(1)	SetDataFolder root:DP_DigitizerControl		WAVE adcType	WAVE adcgain, adcgain_voltage, adcgain_current	adcType[iChannel]=mode	if (mode==1)		adcgain[iChannel]=adcgain_current[iChannel]	else		adcgain[iChannel]=adcgain_voltage[iChannel]	endif	SetDataFolder savDFEndFunction SwitchDACChannelMode(iChannel,mode)	// Switches the indicated DAC channel to the given mode.  Currently, the mode can be 1 (==current)	// or 2 (==voltage)	Variable iChannel, mode	String savDF=GetDataFolder(1)	SetDataFolder root:DP_DigitizerControl	WAVE dacType	WAVE dacgain,dacgain_voltage, dacgain_current	dacType[iChannel]=mode	if (mode==1)		dacgain[iChannel]=dacgain_current[iChannel]	else		dacgain[iChannel]=dacgain_voltage[iChannel]	endif	SetDataFolder savDFEndFunction GetADCChannelMode(iChannel)	Variable iChannel		String savDF=GetDataFolder(1)	SetDataFolder root:DP_DigitizerControl		WAVE adcType	Variable mode=adcType[iChannel]	SetDataFolder savDF		return modeEndFunction /S GetADCChannelModeString(iChannel)	Variable iChannel		String savDF=GetDataFolder(1)	SetDataFolder root:DP_DigitizerControl		WAVE adcType	Variable mode=adcType[iChannel]	String modeString	if (mode==1)		modeString="Current"	else		modeString="Voltage"	endif	SetDataFolder savDF		return modeStringEndFunction /S GetADCChannelUnitsString(iChannel)	Variable iChannel		String savDF=GetDataFolder(1)	SetDataFolder root:DP_DigitizerControl		WAVE adcType	SVAR unitsCurrent, unitsVoltage	Variable mode=adcType[iChannel]	String unitsString	if (mode==1)		unitsString=unitsCurrent	else		unitsString=unitsVoltage	endif	SetDataFolder savDF		return unitsStringEndFunction GetDACChannelMode(iChannel)	Variable iChannel		String savDF=GetDataFolder(1)	SetDataFolder root:DP_DigitizerControl		WAVE dacType	Variable mode=dacType[iChannel]	SetDataFolder savDF		return modeEndFunction /S GetDACChannelModeString(iChannel)	Variable iChannel		String savDF=GetDataFolder(1)	SetDataFolder root:DP_DigitizerControl		WAVE dacType	Variable mode=dacType[iChannel]	String modeString	if (mode==1)		modeString="Current"	else		modeString="Voltage"	endif	SetDataFolder savDF		return modeStringEndFunction /S GetDACChannelUnitsString(iChannel)	Variable iChannel		String savDF=GetDataFolder(1)	SetDataFolder root:DP_DigitizerControl		WAVE dacType	SVAR unitsCurrent, unitsVoltage	Variable mode=dacType[iChannel]	String unitsString	if (mode==1)		unitsString=unitsCurrent	else		unitsString=unitsVoltage	endif	SetDataFolder savDF		return unitsStringEnd