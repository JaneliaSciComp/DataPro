//	LTP Macros For Dual Simultaneous Recordings
//	NLG and NStaff 11/17/99
//	Last Revision 11/24/99

//	NOTE MUST START EXPERIMENT WITH WAVENUMBER = 0
---------------------------------------------------------------
#pragma rtGlobals=1		// Use modern global access method.
#include <Strings as Lists>

Menu "LTP_Macros"
	"Monitor_LTP"
	"Stim_LTP_100Hz x3"
	"BinSlopes"
	SubMenu "Reset Macro"
		"resetALL"
	End
	SubMenu "Analysis"
		"EPSP Slope Calc"
	End
End

Proc resetALL()
	epsp_ampl_soma=NAN
	Vm_baseline_soma=NAN
	epsp_slope_soma=NaN
	timeinfo=0
	timer=0
	wavenumber=1
	timerwave=0
	buzzmark=NaN
EndMacro

Proc Monitor_LTP()
	Variable start, time
	Silent 1
	if (exists("timeinfo")==0)
		Variable /G count,initminit,initsec,inithr
		print "making timeinfo and other waves"
		Make /O/N=(2) timeinfo
		Make /O/N=(1000) timer
		Make /O/N=(1000) timerwave
 	endif
 	if (exists("epsp_ampl_soma")==0)
		Make /O/N=(1000) epsp_ampl_soma
		Make /O/N=(1000) Vm_baseline_soma
		Make /O/N=(1000) epsp_slope_soma
		Make /O/N=(1000) buzzmark
		buzzmark=NaN
	endif
	do
		start=Time_sec()
		StimControl_LTP()
		do
			if(HaltProcedures()>0)
				Abort
			endif
			time=Time_sec()-start
		while(time<ltp_interval)
	while(1)
EndMacro

Macro Test_EPSP()
	Variable start, time
	Silent 1
	do
		start=Time_sec()
		print "testing", Time_sec()
		do
			if(HaltProcedures()>0)
				Abort
			endif
	//		Sleep /S 1			// vary the sleep time to get the proper interstimulus interval
			time=Time_sec()-start
		while(time<10)
	while((HaltProcedures()<1))
EndMacro

Proc StimControl_LTP()
	Silent 1
	String wavename1
	String /G timestr2
	Variable wavenum
	count=timeinfo[1]
	if(count<1)
		timeinfo[0]=Init_time()
	endif
	wavenum=wavenumber
	DoDataAcq()
	sprintf wavename1 "ad1_%d",wavenum
	timestr2=StringByKey("TIME", Note($wavename1), "=", "\r")
	timer[count]=Wave_time(timestr2)-timeinfo[0]
	timerwave[count]=wavenum
	PauseUpdate
	trackEPSPs()		//	calls the graphing procedure
	ResumeUpdate
	count+=1
	timeinfo[1]=count
End

Proc trackEPSPs() 
	String wavename1,wavename2
	Variable wavenum,rmp,peak,left,right,trough,epsp_ampl
	Silent 1
	wavenum=wavenumber-1
	sprintf wavename1"ad1_%d",wavenum
	left=slope_left
	right=slope_right
	Wavestats /Q/R=(2,7) $wavename1
	Vm_baseline_soma[count]=V_avg					// resting potential
	rmp=V_avg
	Wavestats /Q/R=(left,right) $wavename1			// epsp peak amplitude
	Cursor A $wavename1 V_maxloc
	epsp_ampl=V_max-rmp
	 epsp_ampl_soma[count]=epsp_ampl
	if (V_max<-30)
		SubEPSPslopecalc(rmp,epsp_ampl,wavename1)
		ModifyGraph rgb[1]=(0,0,0),lsize[1]=1.5		// draws black fit line onto DataAcqDisplay
	else
		SpikeTiming(wavenum,0)	
		ModifyGraph rgb[1]=(0,0,0),lsize[1]=1.5		// draws black fit line onto DataAcqDisplay
	endif
	if (WinType("EPSP_amp")==1)
		DoWindow /F EPSP_amp
		SetAxis/A left
	else
		EPSP_amp()
	endif
	if (WinType("Vrest")==1)
		DoWindow /F Vrest
		SetAxis left -80,-50
	else
		Vrest()
	endif
	if (WinType("EPSP_slope")==1)
		DoWindow /F EPSP_slope
		SetAxis/A left
	else
		EPSP_slope()
	endif	
End

Window EPSP_amp() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(375,40,845,240) epsp_ampl_soma,buzzmark vs timer as "EPSP amplitude"
	ModifyGraph mode=3
	ModifyGraph marker(epsp_ampl_soma)=16,marker(buzzmark)=17
	ModifyGraph rgb(buzzmark)=(65535,21845,0)
	ModifyGraph msize=3
	Label left "EPSP peak amplitude (mV)"
	Label bottom "Time from beginning of experiment (min)"
	SetAxis/A left
EndMacro

Window EPSP_slope() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(375,260,845,460) epsp_slope_soma,buzzmark vs timer as "EPSP slope"
	ModifyGraph mode=3
	ModifyGraph marker(epsp_slope_soma)=16,marker(buzzmark)=17
	ModifyGraph rgb(buzzmark)=(65535,21845,0)
	ModifyGraph msize=3
	Label left "EPSP slope (mV/ms)"
	Label bottom "Time from beginning of experiment (min)"
	SetAxis left 0,5
EndMacro

Window Vrest() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(375,480,845,580) Vm_baseline_soma,buzzmark vs timer as "Resting potential"
	ModifyGraph mode=3
	ModifyGraph marker(Vm_baseline_soma)=16,marker(buzzmark)=17
	ModifyGraph rgb(buzzmark)=(65535,21845,0)
	ModifyGraph msize=3
	Label left "Vm (mV)"
	Label bottom "Time from beginning of experiment (min)"
	SetAxis left -80,-50
EndMacro

Function Init_time()			//	gives the start time of experiment
	String timestart
	Variable  hr,minit,sec,minutes
	Variable /G inithr,initminit,initsec
	timestart=time()
	hr=str2num(timestart[0,1])
	minit=str2num(timestart[3,4])
	sec=str2num(timestart[6,7])
	minutes=(hr*60)+(minit)+(sec/60)
	//print timestart, hr, minit, sec, minutes
	return(minutes)
End

Function Wave_time(timestr2)		//	gives the data point time
	String timestr2
//	String gettimestr, getdatestr
	Variable  hr,minit,sec,minutes
//	gettimestr=time()
	hr=str2num(timestr2[0,1])
	minit=str2num(timestr2[3,4])
	sec=str2num(timestr2[6,7])
	minutes=(hr*60)+(minit)+(sec/60)
//	print hr, minit, sec, minutes
	return(minutes)
End

Function Time_sec()
	Variable  hr,minit,sec,minutes
	String gettimestr
	gettimestr=time()
	hr=str2num(gettimestr[0,1])
	minit=str2num(gettimestr[3,4])
	sec=str2num(gettimestr[6,7])
	minutes=(hr*60)+(minit)+(sec/60)
	sec=minutes*60
	return(sec)
End

Proc SubEPSPslopecalc(rmp,epsp_ampl,wavename)	
	String wavename
	Variable startfitX,endfitX,startfitY,endfitY,slope,error,rmp,epsp_ampl,left,right
	Silent 1 
	//DEFINE PARAMETERS
	left=8.5
	right=25
	startfitY=0.15*epsp_ampl+rmp
	endfitY=0.50*epsp_ampl+rmp
	FindLevel /Q/R=(left,right) $wavename, startfitY
	startfitX=V_LevelX
//				FIND THE END X VALUE FOR THE FIT
	FindLevel /Q/R=(left,right) $wavename, endfitY
	endfitX=V_LevelX
//				CURVE FITTING ROUTINE
	CurveFit /Q line $wavename(startfitX,endfitX) /D
	slope=abs(W_coef[1])
	epsp_slope_soma[count]=abs(W_coef[1])
	error=W_sigma[1]
//	printf "%s, somatic epsp slope = %8.2f ± %8.2f mV/ms\r"wavename,slope,error
//	printf "startfitX, endfitX=%d,%d",startfitX,endfitX
End

Proc Stim_LTP_100HzX3()
	Variable lim,i,wavenum
	String wavename2
	lim=3
	i=0
	Silent 1
	do
		count=timeinfo[1]
		wavenum=wavenumber
		DoDataAcq()
		sprintf wavename2 "%s%d",adcname1,wavenum
		timestr2=StringByKey("TIME", Note($wavename2), "=", "\r")
		timer[count]=Wave_time(timestr2)-timeinfo[0]
		timerwave[count]=wavenum
		buzzmark[count]=0.1
		count+=1
		timeinfo[1]=count
		Sleep /S 30
		i +=1
	while(i<lim)
End Macro	

Proc SpikeTiming(wavenum,level)			//	*must prerun StimParams() macro in ISAS2
	String wavename1,wavename2,spkdata,spkdata1,spkdata2,difference,text
	Variable wavenum,vrest,nthspike,numspikes,level,left,right
	Variable shock_ampl,train_ampl,interval,num_stim,x
	//	Variable /G step1
	PauseUpdate; Silent 1    // building window...
	sprintf wavename1 "ad1_%d", wavenum
	nthspike=1
	do
		DetectSpike(wavename1,level,nthspike,"no")
		numspikes=numpnts(crossings)/2
		left=crossings[2*(nthspike-1)]-2.2
		right=crossings[2*(nthspike-1)]+4
		sprintf spkdata1, "%sspk%d", wavename1,nthspike
		APshape(wavename1,nthspike,left,right,spkdata1)
		InitSlope(wavename1,spkdata1,left,nthspike,wavenum,right)
		epsp_slope_soma[count]=$spkdata1[10]
		nthspike+=1
	while (nthspike<=numspikes)
End	

Proc APshape(wave,nspike,left,right,spkdata)
	String wave, spkdata, wave2
	Variable nspike, left, right,newleft,newright
	Variable /G inflectionx
	Variable np, vrest, peak, peakt
	Variable inflectionpt, inflectiony,epsp_ampl
	sprintf wave2, "%ssp%d", wave, nspike
	Make /O/N=13 $spkdata
	Wavestats /Q/R=(2,7) $wave
	vrest=V_avg
	$spkdata[0]=vrest
	Wavestats /Q/R=(left,right) $wave
	np=0  				 //	number of points on each side of peak to average
	peakt=V_maxloc
	peak=mean($wave, peakt-(np), peakt+(np))
	peak=V_max 		
	$spkdata[1]=peak						//	AP peak Vm
	$spkdata[2]=peak-vrest					//	AP height from baseline
	$spkdata[3]=peakt						//	peak time
	Duplicate /O/R=(left,right) $wave $wave2
	newleft=$spkdata[3]-1.5
	newright=$spkdata[3]-0.7
	Inflection2(wave2,newleft,newright,spkdata)
	inflectiony=$wave[x2pnt($wave,inflectionx)]
	$spkdata[4]=inflectiony								// inflection level
	$spkdata[5]=inflectionx								// inflection time
	$spkdata[6]=peak-inflectiony							// AP height from inflection
	Wavestats /Q/R=($spkdata[3],$spkdata[3]+3) $wave
	$spkdata[8]=V_min-inflectiony							// fast AHP
//	ShowInfo
//	Cursor A $wave inflectionx
//	Cursor B $wave V_minloc
//	HALFWIDTH MEASUREMENT
	FindLevels /Q/R=(left,right)/D=crossings $wave2, $spkdata[4]+$spkdata[6]/2
	$spkdata[7]=crossings[1]-crossings[0]					// AP halfwidth
	$spkdata[9]=$spkdata[4]-$spkdata[0]					// epsp amplitude relative to rest
	killwaves $wave2
End

Proc DetectSpike(wave, level, nthspike, draw)
//	Returns x values for all crossings of "level" and draws a line at level
	String wave, draw
	Variable level, nthspike,numspikes
	Silent 1
	Variable left, right
	Make /O crossings
	FindLevels /Q/B=5/R=(8,30)/D=crossings $wave, level
	if (V_Flag==2)
		print "problem finding levels"
	endif
	numspikes=numpnts(crossings)/2
	left=crossings[2*(nthspike-1)]-25
	right=crossings[2*nthspike-1]+25
	if (cmpstr(draw,"line")==0)
		SetDrawEnv save, linethick= 0.5,arrow= 0, xcoord=bottom, ycoord=left, linefgc=(0,0,0), fillpat=0
		DrawLine left,level,right,level
	endif
	if (cmpstr(draw,"loop")==0)
		SetDrawEnv save, linethick= 0.5,arrow= 0, xcoord=bottom, ycoord=left, linefgc=(0,0,0), fillpat=0
		DrawOval left, level+2.5, right, level-2.5	
	endif
End

Proc InitSlope(wave,spkdata,left,nthspike,wavenum,right)
	// CALCULATE INITIAL SLOPE (15-50% AMPL) OF SUPRATHRESHOLD EPSP
	String wave,spkdata,fitdata
	Variable left,startfitX,startfitY,endfitX,endfitY,nthspike,wavenum
	Variable stimnum,startbase,endbase,right,x
	Silent 1	
	//	SET AND FIND BASELINE
	startbase=2
	endbase=7
	Wavestats /Q/R=(startbase,endbase) $wave
	$spkdata[12]=V_avg
	$spkdata[2]=$spkdata[1]-$spkdata[12]
	$spkdata[12]=$spkdata[0]
	//	SET THE FITTING REGION
	sprintf fitdata, "fit%sspk%d",wave,nthspike
//	print $spkdata[9]
	startfitY=($spkdata[12]+0.15*($spkdata[9]))			//	Vrest + 15% of the EPSP height
	endfitY=($spkdata[12]+0.5*($spkdata[9]))			//	Vrest + 50% of the EPSP height
	FindLevel /Q/R=(8.5,$spkdata[3]) $wave, startfitY		
	if (V_Flag==1)
		printf "difficult to find startfit point for %s\r",spkdata
		Do
			FindLevel /Q/R=(left,$spkdata[3]) $wave, startfitY
			startfitX=V_LevelX
			left+=-0.4
		While (V_Flag==1)
	else
		startfitX=V_LevelX
	endif
	FindLevel /Q/R=(8.5,$spkdata[3]) $wave, endfitY		
	if (V_Flag==1)
		printf "problem finding endfit point for %s\r",spkdata
		Do
			FindLevel /Q/R=(left,$spkdata[3]) $wave, endfitY
			endfitX=V_LevelX
			left+=-0.4
		While (V_Flag==1)
	else
		endfitX=V_LevelX
	endif
	if (x==0)
		CurveFit  /Q line $wave(startfitX,endfitX) /D
	else
		CurveFit  /Q line $wave(startfitX,endfitX) /D
	endif
	$spkdata[10]=W_coef[1]
	$spkdata[11]=W_sigma[1]
	//	print $spkdata[10],$spkdata[11]
	ShowInfo
	Cursor A $wave $spkdata[5]
	//	Cursor B $wave endfitX
End

Function MonitorLTPButtonProc(ctrlName) : ButtonControl
	String ctrlName
	Execute "Monitor_LTP()"
End

Window LTP_Panel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(186.75,593.75,489,767.75) as "LTP Panel"
	Button button0,pos={16,25},size={100,20},proc=MonitorLTPButtonProc,title="Monitor LTP"
	SetVariable slope_left_set0,pos={38,104},size={170,18},title="slope range left  "
	SetVariable slope_left_set0,limits={0,100000,1},value= slope_left
	SetVariable slope_right_set0,pos={36,128},size={170,18},title="slope range right"
	SetVariable slope_right_set0,limits={0,100000,1},value= slope_right
	SetVariable ltpint_setvar0,pos={124,27},size={170,18},title="stim. interval. (sec)"
	SetVariable ltpint_setvar0,format="%d",limits={1,100,1},value= ltp_interval
EndMacro

Function LTPButtonProc(ctrlName) : ButtonControl
	String ctrlName
	Execute "LTP_Panel()"
End
