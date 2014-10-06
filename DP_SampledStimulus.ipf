#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /WAVE SampledGetParamNames()
	Variable nParameters=4
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="delay"
	parameterNames[1]="duration"
	parameterNames[2]="amplitude"
	parameterNames[3]="sourceWaveName"
	return parameterNames
End

Function /WAVE SampledGetParamDispNames()
	Variable nParameters=4
	Make /T /FREE /N=(nParameters) parameterNames
	parameterNames[0]="Delay"
	parameterNames[1]="Duration"
	parameterNames[2]="Amplitude"
	parameterNames[3]="Wave Name"
	return parameterNames
End

Function /WAVE SampledGetDfltParamsAsStr()
	Variable nParameters=4
	Make /T /FREE /N=(nParameters) parametersDefault
	parametersDefault[0]="10"
	parametersDefault[1]="50"
	parametersDefault[2]="1"	
	parametersDefault[3]=""	
	return parametersDefault
End

Function SampledAreParamsValid(paramsAsStrings)
	Wave /T paramsAsStrings

	Variable delay=str2num(paramsAsStrings[0])
	Variable duration=str2num(paramsAsStrings[1])
	Variable amplitude=str2num(paramsAsStrings[2])
	String sourceWaveName=paramsAsStrings[3]

	String sourceWaveNameAbs="root:"+sourceWaveName

	return (duration>=0)  && ( IsEmptyString(sourceWaveName) || WaveExistsByName(sourceWaveNameAbs) )
End

Function /WAVE SampledGetParamUnits()
	Variable nParameters=4
	Make /T /FREE /N=(nParameters) paramUnits
	paramUnits[0]="ms"
	paramUnits[1]="ms"
	paramUnits[2]=""
	paramUnits[3]=""
	return paramUnits
End

Function SampledOverlayFromParams(w,paramsAsStrings)
	Wave w
	Wave /T paramsAsStrings

	Variable delay=str2num(paramsAsStrings[0])
	Variable duration=str2num(paramsAsStrings[1])
	Variable amplitude=str2num(paramsAsStrings[2])
	String sourceWaveName=paramsAsStrings[3]

	// Somewhat controversial, but in the common case that pulse starts are sample-aligned, and pulse durations are
      	// an integer multiple of dt, this ensures that each pulse is exactly pulseDuration samples long
	Variable dt=deltax(w)      	
	Variable delayTweaked=delay-dt/2

	if ( IsEmptyString(sourceWaveName) )
		// output is zero
	else
		String sourceWaveNameAbs="root:"+sourceWaveName
		if ( WaveExistsByName(sourceWaveNameAbs) )
			Wave sourceWave=$sourceWaveNameAbs
			Variable x0=pnt2x(sourceWave,0)
			Variable xf=pnt2x(sourceWave,numpnts(sourceWave)-1)	
			w += amplitude*unitPulse(x-delayTweaked,duration)*unitPulse(x-delayTweaked,xf-x0)*sourceWave(min(max(x0,x-delayTweaked),xf))		// Igor interpolates linearly into sourceWave
		endif
	endif
End

Function /S SampledGetSignalType()
	return "DAC"
End

