//	DataPro//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18//	Nelson Spruston//	Northwestern University//	project began 10/27/1998Function RaiseOrCreatePanel(panelName)	String panelName		if (PanelExists(panelName))		DoWindow /F $panelName	else		Execute "Create"+panelName+"Panel()"	endifEndFunction RaiseOrCreateView(viewName)	String viewName		// All Datapro views are either graphs or panels	if (GraphOrPanelExists(viewName))		DoWindow /F $viewName	else		Execute viewName+"Constructor()"	endifEnd//Function Analysis() : Panel//	NewPanel /W=(757,44,1070,518) /K=1 as "Analysis"//	Button analyze,pos={1,1},size={70,18},proc=Analyze,title="Measure"//	Button fit,pos={21,34},size={70,18},proc=Fit,title="Fit"//	Button avgswps,pos={39,72},size={70,18},proc=AverageSweeps,title="Average"//End//Function DACPulses() : Panel//	NewPanel /W=(19,424,175,658) /K=1//	Button fivestep_button,pos={15,11},size={120,20},proc=FiveSegButtonProc,title="Five seg. wave"//	Button train_button,pos={15,45},size={120,20},proc=TrainButtonProc,title="Train"//	Button readwave_button,pos={15,174},size={120,20},proc=ReadwaveButtonProc,title="Read from file"//	Button ramp_button,pos={15,77},size={120,20},proc=RampButtonProc,title="Ramp"//	Button psc_button,pos={15,112},size={120,20},proc=PSCButtonProc,title="PSC wave"//	Button sinewave_button,pos={15,144},size={120,20},proc=SineButtonProc,title="Sine wave"//	Button viewwave_button,pos={15,204},size={120,20},proc=ViewDACButtonProc,title="View DAC"//EndFunction FiveSegBuilder() : Graph	String fldrSav= GetDataFolder(1)	SetDataFolder root:DP_Digitizer:	Display /W=(80,150,780,450) /K=1 Step5DAC	SetDataFolder fldrSav	ModifyGraph margin(top)=36	ModifyGraph grid(left)=1	ControlBar 90	SetVariable stepDuration_0,pos={12,13},size={100,15},proc=StepVarProc,title="dur. 0"	SetVariable stepDuration_0,limits={0,10000,10},value= root:DP_Digitizer:stepDuration0	SetVariable stepDuration_1,pos={132,11},size={100,15},proc=StepVarProc,title="dur. 1"	SetVariable stepDuration_1,limits={0,10000,10},value= root:DP_Digitizer:stepDuration1	SetVariable stepDuration_2,pos={252,11},size={100,15},proc=StepVarProc,title="dur. 2"	SetVariable stepDuration_2,limits={0,10000,10},value= root:DP_Digitizer:stepDuration2	SetVariable stepDuration_3,pos={368,11},size={100,15},proc=StepVarProc,title="dur. 3"	SetVariable stepDuration_3,limits={0,10000,10},value= root:DP_Digitizer:stepDuration3	SetVariable stepDuration_4,pos={477,11},size={100,15},proc=StepVarProc,title="dur. 4"	SetVariable stepDuration_4,limits={0,10000,10},value= root:DP_Digitizer:stepDuration4	SetVariable stepAmplitude_0,pos={12,39},size={100,15},proc=StepVarProc,title="amp. 0"	SetVariable stepAmplitude_0,limits={-10000,10000,10},value= root:DP_Digitizer:stepAmplitude0	SetVariable stepAmplitude_1,pos={131,41},size={100,15},proc=StepVarProc,title="amp. 1"	SetVariable stepAmplitude_1,limits={-10000,10000,10},value= root:DP_Digitizer:stepAmplitude1	SetVariable stepAmplitude_2,pos={252,38},size={100,15},proc=StepVarProc,title="amp. 2"	SetVariable stepAmplitude_2,limits={-10000,10000,10},value= root:DP_Digitizer:stepAmplitude2	SetVariable stepAmplitude_3,pos={368,37},size={100,15},proc=StepVarProc,title="amp. 3"	SetVariable stepAmplitude_3,limits={-10000,10000,10},value= root:DP_Digitizer:stepAmplitude3	SetVariable stepAmplitude_4,pos={478,37},size={100,15},proc=StepVarProc,title="amp. 4"	SetVariable stepAmplitude_4,limits={-10000,10000,10},value= root:DP_Digitizer:stepAmplitude4	Button save_dac,pos={607,11},size={80,20},proc=SaveDACButtonProc,title="Save As..."	//SetVariable sint_pb,pos={594,37},size={120,15},proc=StepVarProc,title="sint. (ms)"	//SetVariable sint_pb,limits={0.01,10,0.01},value= root:DP_Digitizer:dtFiveSegment	CheckBox ff_0,pos={28,61},size={62,14},proc=FromFileCheckProc,title="from file"	CheckBox ff_0,value= 0	CheckBox ff_1,pos={147,62},size={62,14},proc=FromFileCheckProc,title="from file"	CheckBox ff_1,value= 0  // ALT: Changed from 1 to fix error on 2012/05/18	CheckBox ff_2,pos={270,62},size={62,14},proc=FromFileCheckProc,title="from file"	CheckBox ff_2,value= 0	CheckBox ff_3,pos={383,60},size={62,14},proc=FromFileCheckProc,title="from file"	CheckBox ff_3,value= 0	CheckBox ff_4,pos={497,60},size={62,14},proc=FromFileCheckProc,title="from file"	CheckBox ff_4,value= 0	PopupMenu editwave_popup0,pos={587,63},size={98,20},proc=EditFiveSegWave,title="Edit: "	PopupMenu editwave_popup0,mode=1,popvalue="_none_",value= #"\"_none_;\"+GetDigitizerWaveNamesEndingIn(\"DAC\")+GetDigitizerWaveNamesEndingIn(\"TTL\")"	SetDrawLayer UserFront	SetDrawEnv fstyle= 1	DrawText -0.0500647382210309,-0.0603730897293596,"When done, save the wave with an extension _DAC or _TTL (TTL high should have an amplitude of 1)"	DrawLine -0.085,-0.0346,1.04,-0.0345EndFunction TrainBuilder() : Graph	String fldrSav= GetDataFolder(1)	SetDataFolder root:DP_Digitizer:	Display /W=(80,150,780,450) /K=1 TrainDAC	SetDataFolder fldrSav	ModifyGraph margin(top)=36	ModifyGraph grid(left)=1	ControlBar 90	SetVariable train_num,pos={16,12},size={104,15},proc=TrainVarProc,title="number"	SetVariable train_num,limits={1,10000,1},value= root:DP_Digitizer:trainNumber	SetVariable train_freq,pos={415,13},size={120,15},proc=TrainVarProc,title="frequency"	SetVariable train_freq,limits={0.001,10000,10},value= root:DP_Digitizer:trainFrequency	SetVariable train_dur,pos={10,39},size={109,15},proc=TrainVarProc,title="duration"	SetVariable train_dur,limits={0.001,1000,1},value= root:DP_Digitizer:trainDuration	Button train_save,pos={570,8},size={90,20},proc=SaveDACButtonProc,title="Save As..."	SetVariable train_pre,pos={306,13},size={75,15},proc=TrainVarProc,title="pre"	SetVariable train_pre,limits={0,1000,1},value= root:DP_Digitizer:trainDuration0	SetVariable train_post,pos={299,38},size={85,15},proc=TrainVarProc,title="post"	SetVariable train_post,limits={0,1000,10},value= root:DP_Digitizer:trainDuration2	SetVariable train_amp,pos={142,38},size={120,15},proc=TrainVarProc,title="amplitude"	SetVariable train_amp,limits={-10000,10000,10},value= root:DP_Digitizer:trainAmplitude	//SetVariable train_sint,pos={417,38},size={120,15},proc=TrainVarProc,title="samp. int."	//SetVariable train_sint,limits={0.01,1000,0.01},value= root:DP_Digitizer:dtFiveSegment	SetVariable train_base,pos={151,12},size={110,15},proc=TrainVarProc,title="baseline"	SetVariable train_base,limits={-10000,10000,1},value= root:DP_Digitizer:trainBase	PopupMenu edittrain_popup0,pos={571,38},size={98,20},proc=EditTrainWave,title="Edit: "	PopupMenu edittrain_popup0,mode=1,popvalue="_none_",value= #"\"_none_;\"+GetDigitizerWaveNamesEndingIn(\"DAC\")+GetDigitizerWaveNamesEndingIn(\"TTL\")"	SetDrawLayer UserFront	SetDrawEnv fstyle= 1	DrawText -0.06,-0.06,"When done, save the wave with an extension _DAC or _TTL (TTL high should have an amplitude of 1)"	DrawLine -0.085,-0.035,1.04,-0.035End//Function RampBuilder() : Graph//	String fldrSav= GetDataFolder(1)//	SetDataFolder root:DP_Digitizer://	Display /W=(80,150,780,450) /K=1 RampDAC//	ModifyGraph margin(top)=36//	ModifyGraph grid(left)=1//	ControlBar 90//	SetVariable ramp_amp1,pos={26,22},size={110,15},proc=RampVarProc,title="amplitude1"//	SetVariable ramp_amp1,limits={-10000,10000,10},value= root:DP_Digitizer:rampAmplitude1//	SetVariable ramp_dur1,pos={27,49},size={110,15},proc=RampVarProc,title="duration1"//	SetVariable ramp_dur1,limits={0,1000,1},value= root:DP_Digitizer:rampDuration1//	SetVariable ramp_dur2,pos={163,51},size={110,15},proc=RampVarProc,title="duration2"//	SetVariable ramp_dur2,limits={1,100000,10},value= root:DP_Digitizer:rampDuration2//	SetVariable ramp_amp3,pos={285,20},size={110,15},proc=RampVarProc,title="amplitude3"//	SetVariable ramp_amp3,limits={-10000,10000,10},value= root:DP_Digitizer:rampAmplitude3//	SetVariable ramp_dur3,pos={282,50},size={110,15},proc=RampVarProc,title="duration3"//	SetVariable ramp_dur3,limits={1,100000,10},value= root:DP_Digitizer:rampDuration3//	SetVariable ramp_amp4,pos={422,20},size={110,15},proc=RampVarProc,title="amplitude4"//	SetVariable ramp_amp4,limits={0,0,0},value= root:DP_Digitizer:rampAmplitude4//	SetVariable ramp_dur4,pos={422,50},size={110,15},proc=RampVarProc,title="duration4"//	SetVariable ramp_dur4,limits={10,1000,10},value= root:DP_Digitizer:rampDuration4//	//SetVariable ramp_sint,pos={551,35},size={110,15},proc=RampVarProc,title="samp. int."//	//SetVariable ramp_sint,limits={0.01,1000,0.01},value= root:DP_Digitizer:dtFiveSegment//	Button train_save,pos={570,8},size={90,20},proc=SaveDACButtonProc,title="Save As..."//	PopupMenu editramp_popup0,pos={565,59},size={95,20},proc=EditRampWave,title="Edit: "//	PopupMenu editramp_popup0,mode=1,popvalue="_New_",value=#"\"_New_;\"+GetDigitizerWaveNamesEndingIn(\"DAC\")+GetDigitizerWaveNamesEndingIn(\"TTL\")"//	SetDrawLayer UserFront//	SetDrawEnv fstyle= 1//	DrawText -0.046,-0.06,"When done, save the wave with an extension _DAC"//	DrawLine -0.085,-0.035,1.04,-0.035//	SetDataFolder fldrSav//End//Function PSCBuilder() : Graph//	String savedDF=GetDataFolder(1)//	SetDataFolder root:DP_Digitizer//	Display /W=(80,150,780,450) /K=1 PSCDAC//	ModifyGraph margin(top)=36//	ModifyGraph grid(left)=1//	ControlBar 90//	SetVariable psc_pre,pos={42,12},size={110,17},proc=PSCVarProc,title="pre (ms)"//	SetVariable psc_pre,limits={0,1000,1},value= pscDuration0//	SetVariable psc_post,pos={301,13},size={120,17},proc=PSCVarProc,title="post (ms)"//	SetVariable psc_post,limits={10,1000,10},value= pscDuration2//	SetVariable psc_amp,pos={28,43},size={120,17},proc=PSCVarProc,title="amplitude"//	SetVariable psc_amp,limits={-10000,10000,10},value= pscAmplitude//	SetVariable psc_taur,pos={163,43},size={120,17},proc=PSCVarProc,title="tau_rise"//	SetVariable psc_taur,format="%g",limits={0,10000,0.1},value= pscTauRise//	SetVariable psc_taud1,pos={289,42},size={130,17},proc=PSCVarProc,title="tau_decay1"//	SetVariable psc_taud1,format="%g",limits={0,10000,1},value= pscTauDecay1//	SetVariable psc_taud2,pos={429,41},size={130,17},proc=PSCVarProc,title="tau_decay2"//	SetVariable psc_taud2,format="%g",limits={0,10000,10},value= pscTauDecay2//	//SetVariable psc_sint,pos={587,51},size={120,17},proc=pscVarProc,title="samp. int."//	//SetVariable psc_sint,limits={0.01,1000,0.01},value= dtFiveSegment//	Button train_save,pos={585,5},size={90,20},proc=SaveDACButtonProc,title="Save As..."//	SetVariable psc_dur,pos={173,13},size={110,17},proc=PSCVarProc,title="psc (ms)"//	SetVariable psc_dur,limits={0,1000,10},value= pscDuration1//	SetVariable psc_wt_td2,pos={440,12},size={120,17},proc=PSCVarProc,title="weight td2"//	SetVariable psc_wt_td2,format="%2.1f",limits={0,1,0.1},value= weightOfTauDecay2//	PopupMenu editpsc_popup0,pos={584,28},size={100,19},proc=EditPSCWave,title="Edit: "//	PopupMenu editpsc_popup0,mode=1,value=#"\"_New_;\"+GetDigitizerWaveNamesEndingIn(\"DAC\")+GetDigitizerWaveNamesEndingIn(\"TTL\")"//	SetDrawLayer UserFront//	SetDrawEnv fstyle= 1//	DrawText -0.05,-0.06,"When done, save the wave with an extension _DAC"//	DrawLine -0.085,-0.035,1.04,-0.035//	SetDataFolder savedDF//EndFunction DACViewer() : Graph	String fldrSav= GetDataFolder(1)	SetDataFolder root:DP_Digitizer:	//Display /W=(78,138,698,408) ThetaTETNUS_DAC	String dacWaveNames=GetDigitizerWaveNamesEndingIn("DAC")	String firstDACWaveName=StringFromList(0,DACWaveNames,";")	String popupItems, initialPopupItem	if ( strlen(firstDACWaveName)==0 )		popupItems="(None)"		initialPopupItem="(None)"	else		popupItems="(None);" + dacWaveNames		initialPopupItem=firstDACWaveName	endif	Display /W=(100,150,700,400) /K=1 $initialPopupItem	ModifyGraph grid(left)=1	PopupMenu dacpopup,pos={650,20},size={115,20},proc=handleViewDACPopupSelection	String popupItemsStupidized="\""+popupItems+"\""	PopupMenu dacpopup,mode=3,popvalue=initialPopupItem,value=#popupItemsStupidized	//SetVariable disp0,pos={650,40},size={100,15},title="samp. int."	//SetVariable disp0,limits={0,0,0},value= root:DP_Digitizer:sintdisp	SetDataFolder fldrSavEnd//Window ImagingPanel() : Panel//	PauseUpdate; Silent 1		// building window...//	NewPanel /W=(757,268,1068,741) /K=1//	Button flu_on,pos={10,40},size={130,20},proc=FluONButtonProc,title="Fluorescence ON"//	Button flu_off,pos={10,10},size={130,20},proc=FluOFFButtonProc,title="Fluorescence OFF"//	CheckBox imaging_check0,pos={14,244},size={114,14},proc=ImagingCheckProc,title="trigger filter wheel"//	CheckBox imaging_check0,value= 1//	Button button0,pos={215,283},size={80,20},proc=DFFButtonProc,title="Append DF/F"//	Button button1,pos={9,190},size={130,20},proc=EphysImageButtonProc,title="Electrophys. + Image"//	SetVariable setimagename0,pos={141,223},size={80,15},title="name"//	SetVariable setimagename0,value= imageseq_name//	CheckBox bkgndcheck0,pos={14,265},size={71,14},title="Bkgnd Sub.",value= 1//	SetVariable numimages_setvar0,pos={11,223},size={120,15},title="No. images"//	SetVariable numimages_setvar0,limits={1,10000,1},value= ccd_frames//	SetVariable ccdtemp_setvar0,pos={13,311},size={150,15},proc=SetCCDTempVarProc,title="CCD Temp. Set"//	SetVariable ccdtemp_setvar0,limits={-50,20,5},value= ccd_tempset//	CheckBox showimageavg_check0,pos={14,286},size={84,14},title="Show Average"//	CheckBox showimageavg_check0,value= 0//	Button resetavg_button2,pos={212,253},size={80,20},proc=ResetAvgButtonProc,title="Reset Avg"//	Button focus,pos={10,70},size={130,20},proc=FocusButtonProc,title="Focus"//	Button full_frame,pos={10,130},size={130,20},proc=FullButtonProc,title="Full Frame Image"//	SetVariable fluo_on_set,pos={178,40},size={120,15},title="ON   position"//	SetVariable fluo_on_set,limits={0,9,1},value= fluo_on_wheel//	SetVariable fluo_off_set,pos={177,10},size={120,15},title="OFF position"//	SetVariable fluo_off_set,limits={0,9,1},value= fluo_off_wheel//	SetVariable focusnum_set,pos={229,98},size={70,15},title="no."//	SetVariable focusnum_set,limits={0,1000,1},value= focus_num//	SetVariable fulltime_set,pos={152,130},size={150,15},title="Exp. time (ms)"//	SetVariable fulltime_set,limits={0,10000,100},value= ccd_fullexp//	SetVariable imagetime_setvar0,pos={149,193},size={150,15},title="Exp.time (ms)"//	SetVariable imagetime_setvar0,limits={0,10000,10},value= ccd_seqexp//	SetVariable setfullname0,pos={137,158},size={80,15},title="name"//	SetVariable setfullname0,value= full_name//	SetVariable setfocusname0,pos={139,99},size={80,15},title="name"//	SetVariable setfocusname0,value= focus_name//	ValDisplay tempdisp0,pos={174,311},size={120,14},title="CCD Temp."//	ValDisplay tempdisp0,format="%3.1f",limits={0,0,0},barmisc={0,1000}//	ValDisplay tempdisp0,value= #"ccd_temp"//	SetVariable focustime_set,pos={151,70},size={150,15},title="Exp. time (ms)"//	SetVariable focustime_set,limits={0,10000,100},value= ccd_focusexp//	SetVariable fullnum_set,pos={230,159},size={70,15},title="no."//	SetVariable fullnum_set,limits={0,1000,1},value= full_num//	SetVariable imageseqnum_set,pos={227,223},size={70,15},title="no."//	SetVariable imageseqnum_set,limits={0,10000,1},value= iSweep//	SetVariable roinum_set0,pos={117,341},size={90,15},proc=GetROIProc,title="ROI no."//	SetVariable roinum_set0,format="%d",limits={1,2,1},value= roinum//	SetVariable settop0,pos={182,371},size={77,15},proc=SetROIProc,title="top"//	SetVariable settop0,format="%d",limits={0,512,1},value= roi_top//	SetVariable setright0,pos={54,395},size={85,15},proc=SetROIProc,title="right"//	SetVariable setright0,format="%d",limits={0,512,1},value= roi_right//	SetVariable settleft0,pos={64,370},size={75,15},proc=SetROIProc,title="left"//	SetVariable settleft0,format="%d",limits={0,512,1},value= roi_left//	SetVariable setbottom0,pos={159,395},size={100,15},proc=SetROIProc,title="bottom"//	SetVariable setbottom0,format="%d",limits={0,512,1},value= roi_bottom//	SetVariable setxbin0,pos={55,419},size={85,15},proc=SetROIProc,title="x bin"//	SetVariable setxbin0,format="%d",limits={0,512,1},value= xbin//	SetVariable setybin0,pos={174,419},size={85,15},proc=SetROIProc,title="y bin"//	SetVariable setybin0,format="%d",limits={0,512,1},value= ybin//	ValDisplay xpixels0,pos={54,444},size={85,14},title="x pixels",format="%4.2f"//	ValDisplay xpixels0,limits={0,0,0},barmisc={0,1000},value= #"xpixels"//	ValDisplay ypixels0,pos={173,446},size={85,14},title="y pixels",format="%4.2f"//	ValDisplay ypixels0,limits={0,0,0},barmisc={0,1000},value= #"ypixels"//	Button getstac_button,pos={125,253},size={80,20},proc=StackButtonProc,title="GetStack"//	CheckBox show_roi_check0,pos={109,286},size={94,14},title="Show ROI Image"//	CheckBox show_roi_check0,value= 0//EndMacro//Function CreateDataProMainPanel() : Panel//	PauseUpdate; Silent 1		// building window...//	NewPanel /W=(2,45,177,547) /N=DataProMain /K=1 as "DataPro"//	ModifyPanel /W=DataProMain fixedSize=1//	SetDrawLayer UserBack//	DrawPICT 1,0,1,1,DataProMenu//	SetDrawEnv fillfgc= (56797,56797,56797)//	DrawRect 1.102,-0.46,-0.108,-0.08//	DrawLine -0.112,-0.157,1.078,-0.157//	SetDrawEnv gstart//	SetDrawEnv linefgc= (65535,65535,0),fillfgc= (65535,65535,0),fname= "Helvetica",fsize= 36,fstyle= 1,textrgb= (0,43690,65535)//	DrawText 16,49,"DataPro"//	SetDrawEnv gstop//	SetDrawEnv fsize= 10,fstyle= 1,textrgb= (65535,65535,0)//	DrawText 24,426,"data acquisition and"//	SetDrawEnv fsize= 10,fstyle= 1,textrgb= (65535,65535,0)//	DrawText 24,446,"analysis macros for"//	SetDrawEnv fsize= 10,fstyle= 1,textrgb= (65535,65535,0)//	DrawText 24,466,"use with Igor Pro &"//	SetDrawEnv fsize= 10,fstyle= 1,textrgb= (65535,65535,0)//	DrawText 24,486,"Instrutech ITC16/18"//	DrawLine -0.11,-0.29,1.08,-0.29//	Button data_button,pos={24,205},size={120,20},proc=DataButtonProc,title="Acquire"//	Button adc_dac_button,pos={24,235},size={120,20},proc=ADC_DACButtonProc,title="Digitizer Control"//	//Button tp_button,pos={24,265},size={120,20},proc=TPWinButtonProc,title="Test pulse"//	Button pulse_button,pos={24,265},size={120,20},proc=DACBuilderButtonProc,title="DAC Pulse Builder"//	//Button imaging_button,pos={24,325},size={120,20},proc=ImagingButtonProc,title="Imaging"//	//Button analyze_button,pos={24,355},size={120,20},proc=AnalyzeButtonProc,title="Analyze"//End