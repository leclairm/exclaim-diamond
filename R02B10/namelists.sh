#!/usr/bin/bash

# Icon master namelist
# ---------------------
icon_master_nml(){
    cat > ${master_namelist} << EOF
&master_nml
 lrestart             = ${lrestart:-.false.}
/
&master_time_control_nml
 calendar             = 'proleptic gregorian'
 checkpointTimeIntval = "${checkpoint_interval}"
 restartTimeIntval    = "${restart_interval}"
 experimentStartDate  = "${start_date}"
 experimentStopDate   = "${end_date}"
/
&time_nml
 is_relative_time = .false.
/
&master_model_nml
  model_type=1
  model_name="atmo"
  model_namelist_filename="${atmo_namelist}"
  model_min_rank=1
  model_max_rank=65536
  model_inc_rank=1
/
EOF
}

main_atmo_nml(){
    cat > ${atmo_namelist} << EOF
&parallel_nml
! nproma             = $nproma         ! CK nproma  after Abishek: edge/(compute nodes)+20
 nblocks_e          = $nblocks_e
 nblocks_c          = $nblocks_c      ! CK for GPU calculations according Abishek = 1 for icon dsl
 nproma_sub         = $nproma_sub     ! CK adapted according to JJ for Daint, saves compute nodes
 p_test_run         = .false.         ! From CLM namelist  (Used for MPI Verification)
 l_test_openmp      = .false.         ! From CLM namelist  (Used for OpenMP verification)
 l_log_checks       = .true.          ! From CLM namelist  (True only for debugging)
 num_io_procs       = ${N_IO_TASKS}   ! Suggestion (One Node for one set of variables)
 num_restart_procs  = ${N_RST_TASKS}  ! For Large Restart chuck, use enough number of Processors
 io_proc_chunk_size = 12              ! Used for Large Data writing requiring large memory (eg., 3D files)
 iorder_sendrecv    = 3               ! From CLM namelist  (isend/irec)
! itype_comm         = 1               ! NEW    ! From CLM namelist  (use local memory)
! proc0_shift        = 0               ! NEW    ! From CLM namelist  (Processors at begining of rank excluded from DC)
! use_omp_input      = .false.         ! NEW    ! From CLM namelist  (Use OpenMP for initialisation)
/

&grid_nml
 dynamics_grid_filename = "${atmo_dyn_grid}"
 lredgrid_phys          = .FALSE.   ! Incase Reduced grid is used for Radiation turn to TRUE
/

&initicon_nml
! initialization mode (2 for IFS ana, 1 for DWD ana, 4=cosmo, 2=ifs, 3=combined
 init_mode         = 2
 ifs2icon_filename = "$(basename ${analysis_file})"
 zpbl1             = 500.    ! NEW Works  !(CLM) bottom height (AGL) of layer used for gradient computation
 zpbl2             = 1000.   ! NEW Works    !(CLM) top height (AGL) of layer used for gradient computation
 ltile_init        =.true.   ! NEW Works   !(CLM) True: initialize tiled surface fields from a first guess coming from a run without tiles.
 ltile_coldstart   =.true.   ! NEW Works  ! (CLM) If true, tiled surface fields are initialized with tile-averaged fields from a previous run with tiles.
/

&run_nml
 modelTimeStep         = "${timestep}"   ! Consistent with Aquaplanet run we tried 80Sec
 num_lev               =  120            ! AD suggested 90 levels, in line with Dyamond simulations.
 lvert_nest            = .false.         ! No vertical nesting (but may be good option for high resolutio)
 ldynamics             = .true.          ! dynamics
 ltransport            = .true.          ! Tracer Transport is true
 ntracer               = 5               ! AD suggestion
 iforcing              = 3               ! NWP forcing
 lart                  = .false.         ! Aerosol and TraceGases ART package from KIT
 ltestcase             = .false.         ! false: run with real data
 msg_level             =  10             ! default: 5, much more: 20; CLM uses 13 for bebug and 0 for production run
 ltimer                = .true.          ! Timer for monitoring runtime for specific routines
 activate_sync_timers  = .true.          !  Timer for monitoring runtime communication routines-
 timers_level          = 10              ! Level of timer monitoring   (1 is default value)
 output                = 'nml'           ! nml stands for new output mode
 check_uuid_gracefully = .true.          ! Warnings for non-matching UUIDs
/

&io_nml
 itype_pres_msl       = 5         ! Method for comoputing mean sea level pressure (Mixture of IFS and GME model DWD)
 itype_rh             = 1         ! RH w.r.t. water (WMO type Water only)
 restart_file_type    = 5         ! 4: netcdf2, 5: netcdf4  (Consistent across model output, netcdf4)
 restart_write_mode   = "${restart_mode}"
 lflux_avg            = .true.    ! "FALSE" output fluxes are accumulated from the beginning of the run, "TRUE" average values
 lnetcdf_flt64_output = .false.   ! Default value is false (CK)
 precip_interval      = "PT15M"   ! NEW ! Works The precipitation value is accumulated in these interval otherwise accumulated fromm begining of the run
 runoff_interval      = "PT3H"    ! NEW ! Works The runoff is accumalted in this inetrval else accumulated from bengining.
 maxt_interval        = "PT3H"    ! NEW ! Works Interval at which Max/Min 2m temperture are calculated
 melt_interval        = "PT3H"    ! NEW ! Works CLM community has this , Can not find discription
 lmask_boundary       = .true.    ! NEW ! Works if interpolation zone should be masked in triangular output.
 dt_hailcast          = 900.
/

&nwp_phy_nml
 inwp_gscp          = 2,    ! COSMO-DE cloud microphysisi 3 catogories, cloud-ice, snow, groupel
 mu_rain            = 0.5   ! NEW  CLM community (shape parameter in gamma distribution for rain)
 rain_n0_factor     = 0.1   ! NEW  CLM community (tuning factor for intercept parameter of raindrop size distribution)
 icalc_reff         = 0     ! Parametrization diagnostic calculation of effective radius
 inwp_convection    = 0     ! Tiedtke/Bechtold convection scheme on for R02B08
 inwp_radiation     = 4     ! 4 for ecRad radiation scheme
 inwp_cldcover      = 1     ! 0: no cld, 1: new diagnostic (M Koehler), 3: COSMO, 5: grid scale (CLM uses 1)
 inwp_turb          = 1     ! 1 (COSMO diffusion and transfer)
 inwp_satad         = 1     ! Saturation adjustment at constant densit (CLM community)
 inwp_sso           = 0     ! Sub-grid scale orographic drag   (Lott and Miller Scheme (COMSO))
 inwp_gwd           = 0     ! Non Orographic gravity wave drag (Orr-Ern-Bechtold Scheme)
 inwp_surface       = 1     ! 1 is TERRA and 2 is JSBACH.
 icapdcycl          = 3     ! Type of Cape Correction for improving diurnal cycle (correction over land restricted to land , no correction over ocean, appklication over tropic)
 itype_z0           = 2     ! CLM community uses 2: (land-cover-related roughness based on tile-specific landuse class)
 dt_conv            = $(( 0 * timestep_phy ))  ! AD specific recomendation (Convection call)
 dt_sso             = $(( 0 * timestep_phy ))  ! AD specific recomendation (sub surface orography call)
 dt_gwd             = $(( 0 * timestep_phy ))  ! AD specific recomendation (gravity wave drag call)
 dt_rad             = $((30 * timestep_phy ))  ! AD specific recomendation (radiation call)
 dt_ccov            = $(( 1 * timestep_phy ))  ! AD specific recomendation (cloud cover call)
 latm_above_top     = .false.   ! Take into atmo above model top for cloud cover calculation (TRUE for CLM community)
 efdt_min_raylfric  = 7200.0    ! Minimum e-folding time for Rayleigh friction ( for inwp_gwd > 0) (CLM community)
 icpl_aero_conv     = 0         ! Coupling of Tegen aerosol climmatology ( for irad_aero = 6)
 icpl_aero_gscp     = 0         ! Coupling of aerosol tto large scale preciptation
 ldetrain_conv_prec = .false.   ! Detraintment of convective rain and snow. (for inwp_convection = 1)
 lrtm_filename      = "rrtmg_lw.nc"             ! (rrtm inactive)
 cldopt_filename    = "ECHAM6_CldOptProps.nc"   ! RRTM inactive
/

&radiation_nml
 ecrad_isolver   = 2           ! CK comment (for GPU =2 , CPU = 0)
 irad_o3         = 5           ! ! PPK changed to 0 CLM communitny recomendation   (ice from tracer variable)
 irad_o2         = 2           ! Tracer variable (CLM commnity)
 irad_cfc11      = 2           ! Tracer variableTracer variable (co2, ch4,n20,o2,cfc11,cfc12))
 irad_cfc12      = 2           ! Tracer Variable (cfc12)
 irad_aero       = 18          ! Aerosol data ( Tegen aerosol climatology)
 albedo_type     = 2           !  2: Modis albedo
 direct_albedo   = 4           !NEW direct beam surface albedo (Briegleb & Ramanatha for snow-free land points, Ritter-Geleyn for ice and Zängl for snow)
 albedo_whitecap = 1           ! NEW CLM community (whitecap describtion by Seferian et al 2018)
 vmr_co2         = 390.e-06    ! Volume mixing ratio if radiative agents
 vmr_ch4         = 1800.e-09   ! CK namelist (not default value in ICON)
 vmr_n2o         = 322.0e-09   ! CK namelist (not default value in ICON)
 vmr_o2          = 0.20946     ! CK namelist (not default value in ICON)
 vmr_cfc11       = 240.e-12    ! CK namelist (not default value in ICON)
 vmr_cfc12       = 532.e-12    ! CK namelist (not default value in ICON)
 ecrad_data_path = "./ecrad_data"  ! ECRad data from externals of this source code.
/

&nonhydrostatic_nml
 iadv_rhotheta       = 2         ! Advection method for density and potential density (Default)
 ivctype             = 2         ! Sleeve vertical coordinate, default
 itime_scheme        = 4         ! default Contravariant vertical velocityin predictor step, velocty tendencis in corrector step
 exner_expol         = 0.333     ! Temporal extrapolation (default = 1/3) (For R2B5 or Coarser use 1/2 and 2/3 recomendation)
 vwind_offctr        = 0.2       ! Off-centering vertical wind solver
 damp_height         = 30000.    ! AD recomendation (rayeigh damping starts at this lelev in meters)
 rayleigh_coeff      = 0.5       ! AD recomendation based on APE testing wiht Praveen-
 divdamp_order       = 24        ! Default value (Combined second and fourth order divergence damping
 divdamp_type        = 32        ! Defaul value (3D divergence)
 divdamp_fac         = 0.004     ! Default value (scaling factor for divergence damping)
 divdamp_trans_start = 12500.0   ! Lower bound of transition zone between 2D and 3D divergence damoping)
 divdamp_trans_end   = 17500.0   ! Upper bound
 igradp_method       = 3         ! Default (Discritization of horizontal pressure gradient (tyloer expansion))
 l_zdiffu_t          = .true.    ! Smagorinsky temperature diffuciton truly horizontally over steep slopes
 thslp_zdiffu        = 0.02      ! Slope thershold for activation of temperature difusion
 thhgtd_zdiffu       = 125.      ! Height difference between two neighbouring points ! CLM value
 htop_moist_proc     = 22500.    ! Height above whihc ophysical processes are turned off
 hbot_qvsubstep      = 16000.    ! Height above which Qv i s advected wih substepping
 ndyn_substeps       = 5         ! Default value for dynamical sub-stepping
/

&sleve_nml
 min_lay_thckn   = 50.      ! Layer thickness of lowermost layer (CLM recommendation)  !! I USED 200M!! USE THE DEFALUT 50M
! max_lay_thckn   = 400.     ! May layer thickness below th height given by htop_thcknlimit (CLM & NWP recomendation 400)
 htop_thcknlimit = 15000.   ! Height below which the layer thickness does not exceed max_lay_thckn (CLM recomendation)
 top_height      = 85000.   ! Height of the model top (AD recomendation)
 stretch_fac     = 0.9      ! Stretching factor to vary distribution of model levels (<1 increase layer thicknedd near model top)
 decay_scale_1   = 4000.    ! Decay scale of large-scale topography  (Default Value)
 decay_scale_2   = 2500.    ! Decay scale of small-scale topography  (Default Value)
 decay_exp       = 1.2      ! Exponent of decay function (Default value in meters)
 flat_height     = 25000.   ! Height above whihc coordinatre surfaces are flat  (default value)
/

&dynamics_nml
 iequations     = 3        ! Non-hydrostatic atmsophere
 divavg_cntrwgt = 0.50     ! Weight of central cell for divergence averaging
 lcoriolis      = .true.   ! Coriolis force ofcourse true for real cases
/

&transport_nml
 ihadv_tracer      = 2,2,2,2,2,2   ! (AD recomendaiton)gdm: 52 combination of hybrid FFSL/Miura3 with subcycling
 itype_hlimit      = 4,4,4,4,4,4   ! (AD recomendaiton) type of limiter for horizontal transport
 ivadv_tracer      = 3,3,3,3,3,3   ! (AD recomendaiton) tracer specific method to compute vertical advection
 itype_vlimit      = 1,1,1,1,1,1   ! (AD recomendaiton) Type of limiter for vertical transport
 ivlimit_selective = 1,1,1,1,1,1
 llsq_svd          = .true.        ! (AD recomendaiton)use SV decomposition for least squares design matrix
/

&diffusion_nml
 hdiff_order      = 5        ! Smagorinsky diffusiton combined with 4rth order background diffusion
 itype_vn_diffu   = 1        ! (u,v reconstruction atvertices only)  Default of CLM
 itype_t_diffu    = 2        ! (Discritization of temp diffusion, default value of CLM)
 hdiff_efdt_ratio = 32.0     ! Ratio iof e-forlding time to time step, recomemded values above 30 (CLM value)
 hdiff_smag_fac   = 0.025    ! Scaling factor for Smagorninsky diffusion (CLM value)
 lhdiff_vn        = .true.   ! Diffusion of horizontal winds
 lhdiff_temp      = .true.   ! Diffusion of temperature field
/

&gridref_nml
 grf_intmethod_ct = 2      ! interpolation method for grid refinment (gradient based interpolation, default value)
 grf_intmethod_e  = 6      ! default 6 Interpolation ,method for edge based bariables
 grf_tracfbk      = 2      ! Bilinear interpolation
 denom_diffu_v    = 150.   ! Deniminator for lateral boundary diffusion of temperature
/

&extpar_nml
 extpar_filename         = "$(basename ${extpar_file})"
 itopo                   = 1       ! Topography read from file
 n_iter_smooth_topo      = 1       ! iterations of topography smoother
 heightdiff_threshold    = 3000.   ! height difference between neighboring grid points above which additional local nabla2 diffusion is applied
 hgtdiff_max_smooth_topo = 750.    ! RMS height difference to neighbor grid points at which the smoothing pre-factor fac_smooth_topo reaches its maximum value (CLM value)
 itype_vegetation_cycle  = 3       ! NEW  (CLM value , but not defined. Annual cycle of Leaf Area Index, use T2M to get realistic values)
 itype_lwemiss           = 2       ! NEW  Type of data for Long wave surfae emissitvity (Read from monthly climatologoies from expar file)
/

! This are NWP tuning recomendation from CLM community

&nwp_tuning_nml
  itune_albedo     = 0
  tune_gkwake      = 1.5
  tune_gfrcrit     = 0.425
  tune_gkdrag      = 0.075
  tune_dust_abs    = 1.
  tune_zvz0i       = 0.85
  tune_box_liq_asy = 3.25
  tune_minsnowfrac = 0.2
  tune_gfluxlaun   = 3.75e-3
  tune_rcucov      = 0.075
  tune_rhebc_land  = 0.825
  tune_gust_factor = 7.0
/

!Turbulance diffusion tuining based on the CLM community recomendation (This needs to be checked for Silje & Pothapakula Namelist)

&turbdiff_nml
  tkhmin        = 0.6
  tkhmin_strat  = 1.0
  tkmmin        = 0.75
  pat_len       = 750.
  c_diff        =  0.2
  rlam_heat     = 10.0
  rat_sea       =  0.8
  ltkesso       = .true.
  frcsmot       = 0.2
  imode_frcsmot = 2
  alpha1        = 0.125
  icldm_turb    = 1
  itype_sher    = 1
  ltkeshs       = .true.
  a_hshr        = 2.0
/

! This corresponds to the TERRA namelist based on the CLM community recomendation

&lnd_nml
  sstice_mode    = 6  ! 4: SST and sea ice fraction are updated daily,
                      !    based on actual monthly means
  ntiles         = 3
  nlev_snow      = 1
  zml_soil       = 0.005,0.02,0.06,0.18,0.54,1.62,4.86,14.58
  lmulti_snow    = .false.
  itype_heatcond = 3
  idiag_snowfrac = 20
  itype_snowevap = 3
  lsnowtile      = .true.
  lseaice        = .true.
  llake          = .true.
  itype_lndtbl   = 4
  itype_evsl     = 4
  itype_trvg     = 3
  itype_root     = 2
  itype_canopy   = 2
  cwimax_ml      = 5.e-4
  c_soil         = 1.25
  c_soil_urb     = 0.5
  lprog_albsi    = .true.
/
EOF
}

# Output streams
# --------------

output_stream_1_1(){
    # FOR DYAMOND PROTOCOL # 3D Variables on native grid, 3 hourly (as per the
    # Dyamond Protocol 6 hourly), 37 pressure levels.
    # => This needs to be interpolated onto 10KM (25KM for Dyamond)
    mkdir -p out_1_1
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_1_1/${EXPNAME}_out_1_1_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT3H"
 file_interval   = "P1D"
 include_last    = .true.
 pl_varlist      = 'geopot','qv','rh'
 p_levels        = 100,200,300,500,700,1000,2000,3000,5000,7000,10000,12500,15000,17500,20000,22500,25000,30000,35000,40000,45000,50000,55000,60000,65000,70000,75000,77500,80000,82500,85000,87500,90000,92500,95000,97500,100000
 output_grid     = .true.
 mode            = 1
/
EOF
}

output_stream_1_2(){
    # FOR DYAMOND PROTOCOL # 3D Variables on native grid, 3 hourly (as per the
    # Dyamond Protocol 6 hourly), 37 pressure levels.
    # => This needs to be interpolated onto 10KM (25KM for Dyamond)
    mkdir -p out_1_2
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_1_2/${EXPNAME}_out_1_2_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT3H"
 file_interval   = "P1D"
 include_last    = .true.
 pl_varlist      = 'qc','qr','qi'
 p_levels        = 100,200,300,500,700,1000,2000,3000,5000,7000,10000,12500,15000,17500,20000,22500,25000,30000,35000,40000,45000,50000,55000,60000,65000,70000,75000,77500,80000,82500,85000,87500,90000,92500,95000,97500,100000
 output_grid     = .true.
 mode            = 1
/
EOF
}

output_stream_1_3(){
    # FOR DYAMOND PROTOCOL # 3D Variables on native grid, 3 hourly (as per the
    # Dyamond Protocol 6 hourly), 37 pressure levels.
    # => This needs to be interpolated onto 10KM (25KM for Dyamond)
    mkdir -p out_1_3
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_1_3/${EXPNAME}_out_1_3_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT3H"
 file_interval   = "P1D"
 include_last    = .true.
 pl_varlist      = 'qs','qg','temp'
 p_levels        = 100,200,300,500,700,1000,2000,3000,5000,7000,10000,12500,15000,17500,20000,22500,25000,30000,35000,40000,45000,50000,55000,60000,65000,70000,75000,77500,80000,82500,85000,87500,90000,92500,95000,97500,100000
 output_grid     = .true.
 mode            = 1
/
EOF
}

output_stream_1_4(){
    # FOR DYAMOND PROTOCOL # 3D Variables on native grid, 3 hourly (as per the
    # Dyamond Protocol 6 hourly), 37 pressure levels.
    # => This needs to be interpolated onto 10KM (25KM for Dyamond)
    mkdir -p out_1_4
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_1_4/${EXPNAME}_out_1_4_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT3H"
 file_interval   = "P1D"
 include_last    = .true.
 pl_varlist      = 'u','v','w'
 p_levels        = 100,200,300,500,700,1000,2000,3000,5000,7000,10000,12500,15000,17500,20000,22500,25000,30000,35000,40000,45000,50000,55000,60000,65000,70000,75000,77500,80000,82500,85000,87500,90000,92500,95000,97500,100000
 output_grid     = .true.
 mode            = 1
/
EOF
}


output_stream_1_5(){
    # FOR DYAMOND PROTOCOL # 3D Variables on native grid, 3 hourly (as per the
    # Dyamond Protocol 6 hourly), 37 pressure levels. Extra Variables, not
    # required for Dyamond.
    # => This needs to be interpolated onto 10KM.
    mkdir -p out_1_5
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_1_5/${EXPNAME}_out_1_5_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT3H"
 file_interval   = "P1D"
 include_last    = .true.
 pl_varlist      = 'omega','rho','pv','tke'
 p_levels        = 100,200,300,500,700,1000,2000,3000,5000,7000,10000,12500,15000,17500,20000,22500,25000,30000,35000,40000,45000,50000,55000,60000,65000,70000,75000,77500,80000,82500,85000,87500,90000,92500,95000,97500,100000
 output_grid     = .true.
 mode            = 1
/
EOF
}

output_stream_2(){
    # FOR DYAMOND PROTOCOL, NATIVE GRID # 2D variables on Native Grid, according
    # to Dyamond protocol - [Cyclone Tracking or MCS on Native Grid, Hourly
    # Resolution]
    # => Also Interpolate onto 10KM Grid for Dyamond. (Both formats are
    # necessay)
    mkdir -p out_2
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_2/${EXPNAME}_out_2<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT15M"
 file_interval   = "P1D"
 ml_varlist      = 'tot_prec','DHAIL_MX'
 include_last    = .true.
 output_grid     = .true.
 mode            = 1
/
EOF
}

output_stream_3(){
    mkdir -p out_3
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_3/${EXPNAME}_out_3_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT1H"
 file_interval   = "P1D"
 ml_varlist      = 'pres_sfc','pres_msl','u_10m','v_10m','tot_prec','qv_2m','t_2m','tqc','tqi','tqv','tqr','h_snow','gust10'
 include_last    = .true.
 output_grid     = .true.
 mode            = 1
/
EOF
}

output_stream_4(){
    # FOR DYAMOND PROTOCOL, NATIVE GRID # 2D variables on Native Grid, according
    # to Dyamond protocol- [For Convection], Only 'w' is asked, but included u,v
    # for turbine impact studies (if needed)
    mkdir -p out_4
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_4/<output_filename>${EXPNAME}_out_4_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT1H"
 file_interval   = "P1D"
 hl_varlist      = 'u','v','w'
 h_levels        =  10.0, 500.0, 2500, 5000, 7500
 include_last    = .true.
 output_grid     = .true.
 mode            = 1
/
EOF
}

output_stream_5(){
    # FOR DYAMOND PROTOCOL, Atmosphere 2D variables, hourly interval
    # => Need to be interpolated onto 12.5KM regular grid (25KM for Dyamond)
    mkdir -p out_5
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_5/${EXPNAME}_out_5_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT1H"
 file_interval   = "P1D"
 ml_varlist      = 'qhfl_s','lhfl_s','shfl_s', 'umfl_s','vmfl_s','pres_sfc','pres_msl'
 include_last    = .true.
 output_grid     = .true.
 mode            = 1
/
EOF
}

output_stream_6(){
    # FOR DYAMOND PROTOCOL, NATIVE GRID, Atmosphere 2D variables, hourly
    # interval, But Prof. Prein request for Native Grid.
    # => Need to be interpolated onto 12.5KM regular grid (25KM for Dyamond)
    mkdir -p out_6
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_6/${EXPNAME}_out_6_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT1H"
 file_interval   = "P1D"
 ml_varlist      = 'thu_s','sob_s','sob_t','sod_t','sodifd_s','thb_s','sou_s','thb_t','sobclr_s','sou_t','thbclr_s'
 include_last    = .true.
 output_grid     = .true.
 mode            = 1
/
EOF
    # sod_s mot found, sodifu_s not found, sodird_s not found, thd_s not found,
    # sobclr_t not found, thbclr_t not found! 'sodifu_s','sodird_s' not found
    # In the out7, we are trying to output the Radiation terms which are 3D
    # i.e., written on the model levels. (lwflx_dn_clr, lwflx_dn, lwflx_up_clr,
    # lwflx_up, lwflxall, swflx_dn_clr, swflx_dn, swflx_up_clr, swflx_up)
}


output_stream_7(){
    # FOR DYAMOND PROTOCOL , #Atmosphere 2D variables
    # => Need to be interpolated onto 12.5KM regular grid (25KM for Dyamond)
    mkdir -p out_7
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_7/${EXPNAME}_out_7_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT1H"
 file_interval   = "P1D"
 ml_varlist      = 'clct','clcm','clcl','clch','qv_2m','rh_2m','t_2m','t_g','td_2m','u_10m','v_10m','sp_10m','gust10'
 include_last    = .true.
 output_grid     = .true.
 mode            = 1
/
EOF
}

output_stream_8(){
    # CAPE and LCL for Process Studies, Hourly Resolution
    # => Need to be interpolated onto 12.5KM regular grid
    mkdir -p out_8
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_8/${EXPNAME}_out_8_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT1H"
 file_interval   = "P1D"
 include_last    = .true.
 ml_varlist      = 'cape_ml','cape','lcl_ml','lfc_ml','cin_ml','DBZ_CMAX','GRAUPEL_GSP'
 output_grid     = .true.
 mode            = 1
/
EOF
    # LPI and LPI_MAX do not work, as they are only ported on Reduced Grid, as MeteoSwiss uses reduced grid.
}

output_stream_9(){
    # LAND VARIABLES @ 3 hours
    # => Need to be interpolated onto 12.5KM regular grid
    mkdir -p out_9
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_9/${EXPNAME}_out_9_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT3H"
 file_interval   = "P1D"
 ml_varlist      = 'smi','w_i','t_so','w_so','freshsnow','rho_snow','w_snow','t_s','t_g'
 include_last    = .true.
 output_grid     = .true.
 mode            = 1
/
EOF
}

output_stream_10(){
    # variables not a part of Dyamond but are of interest
    # => Need to be interpolated onto 12.5KM regular grid
    mkdir -p out_10
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_10/${EXPNAME}_out_10_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT3H"
 file_interval   = "P1D"
 ml_varlist      = 'runoff_g','runoff_s','snow_gsp','snow_melt'
 include_last    = .true.
 output_grid     = .true.
 mode            = 1
/
EOF
}

output_stream_11(){
    # NATIVE GRID 3D variables hourly for tracking on 2.5KM regular grid on
    # pressure levels (On the Native Grid)
    # => Need to be interpolated onto 2.5KM regular grid
    mkdir -p out_11
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_11/${EXPNAME}_out_11_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT1H"
 file_interval   = "P1D"
 pl_varlist      = 'geopot','temp','u','v'
 p_levels        =  20000,50000,85000
 include_last    = .true.
 output_grid     = .true.
 mode            = 1
/
EOF
}

output_stream_12(){
    # Extreme Temperatures @ 3 hours
    # => Need to be interpolated onto 12.5KM regular grid
    mkdir -p out_12
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_12/${EXPNAME}_out_12_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT3H"
 file_interval   = "P1D"
 ml_varlist      = 'tmax_2m','tmin_2m', 'lai', 'plcov', 'rootdp',
 include_last    = .true.
 output_grid     = .true.
 mode            = 1
/
EOF
}

output_stream_13(){
    # Outputing on Model Levels @ 6 hourly, but interpolation for 12.5KM for 3D
    # => Need to be interpolated onto 12.5KM regular grid
    mkdir -p out_13
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_13/${EXPNAME}_out_13_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT3H"
 file_interval   = "P1D"
 ml_varlist      = 'pres'
 include_last    = .true.
 output_grid     = .true.
 mode            = 1
/
EOF
}

output_stream_14(){
    # (NATIVE + Interpolated ) Outputing on Model Levels @ 1 hourly
    # => 2.5KM Native grid for surface levels, but interpolation to 12.5KM for 3D
    mkdir -p out_14
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_14/${EXPNAME}_out_14_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT1H"
 file_interval   = "P1D"
 ml_varlist      = 'lwflx_up', 'lwflx_dn', 'swflx_up', 'swflx_dn', 'lwflx_up_clr', 'lwflx_dn_clr', 'swflx_up_clr', 'swflx_dn_clr'
 m_levels        = "1,nlev"
 include_last    = .true.
 output_grid     = .true.
 mode            = 1
/
EOF
}

output_stream_15_1(){
    # Outputing on Model Levels @ 3 hourly for EXCLAIM Stress Test
    mkdir -p out_15_1
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_15_1/${EXPNAME}_out_15_1_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT3H"
 file_interval   = "P1D"
 ml_varlist      = 'geopot'
 include_last    = .true.
 output_grid     = .true.
 mode            = 1
/
EOF
}

output_stream_15_2(){
    # Outputing on Model Levels @ 3 hourly for EXCLAIM Stress Test
    mkdir -p out_15_2
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_15_2/${EXPNAME}_out_15_2_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT3H"
 file_interval   = "P1D"
 ml_varlist      = 'qv'
 include_last    = .true.
 output_grid     = .true.
 mode            = 1
/
EOF
}

output_stream_15_3(){
    # Outputing on Model Levels @ 3 hourly for EXCLAIM Stress Test
    mkdir -p out_15_3
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_15_3/${EXPNAME}_out_15_3_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT3H"
 file_interval   = "P1D"
 ml_varlist      = 'qc'
 include_last    = .true.
 output_grid     = .true.
 mode            = 1
/
EOF
}

output_stream_15_4(){
    # Outputing on Model Levels @ 3 hourly for EXCLAIM Stress Test
    mkdir -p out_15_4
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_15_4/${EXPNAME}_out_15_4_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT3H"
 file_interval   = "P1D"
 ml_varlist      = 'qr'
 include_last    = .true.
 output_grid     = .true.
 mode            = 1
/
EOF
}

output_stream_15_5(){
    # Outputing on Model Levels @ 3 hourly for EXCLAIM Stress Test
    mkdir -p out_15_5
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_15_5/${EXPNAME}_out_15_5_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT3H"
 file_interval   = "P1D"
 ml_varlist      = 'qi'
 include_last    = .true.
 output_grid     = .true.
 mode            = 1
/
EOF
}

output_stream_15_6(){
    # Outputing on Model Levels @ 3 hourly for EXCLAIM Stress Test
    mkdir -p out_15_6
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_15_6/${EXPNAME}_out_15_6_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT3H"
 file_interval   = "P1D"
 ml_varlist      = 'qs'
 include_last    = .true.
 output_grid     = .true.
 mode            = 1
/
EOF
}

output_stream_15_7(){
    # Outputing on Model Levels @ 3 hourly for EXCLAIM Stress Test
    mkdir -p out_15_7
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_15_7/${EXPNAME}_out_15_7_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT3H"
 file_interval   = "P1D"
 ml_varlist      = 'qg'
 include_last    = .true.
 output_grid     = .true.
 mode            = 1
/
EOF
}

output_stream_15_8(){
    # Outputing on Model Levels @ 3 hourly for EXCLAIM Stress Test
    mkdir -p out_15_8
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_15_8/${EXPNAME}_out_15_8_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT3H"
 file_interval   = "P1D"
 ml_varlist      = 'temp'
 include_last    = .true.
 output_grid     = .true.
 mode            = 1
/
EOF
}

output_stream_15_9(){
    # Outputing on Model Levels @ 3 hourly for EXCLAIM Stress Test
    mkdir -p out_15_9
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_15_9/${EXPNAME}_out_15_9_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT3H"
 file_interval   = "P1D"
 ml_varlist      = 'u'
 include_last    = .true.
 output_grid     = .true.
 mode            = 1
/
EOF
}

output_stream_15_10(){
    # Outputing on Model Levels @ 3 hourly for EXCLAIM Stress Test
    mkdir -p out_15_10
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_15_10/${EXPNAME}_out_15_10_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT3H"
 file_interval   = "P1D"
 ml_varlist      = 'v'
 include_last    = .true.
 output_grid     = .true.
 mode            = 1
/
EOF
}

output_stream_15_11(){
    # Outputing on Model Levels @ 3 hourly for EXCLAIM Stress Test
    mkdir -p out_15_11
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_15_11/${EXPNAME}_out_15_11_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT3H"
 file_interval   = "P1D"
 ml_varlist      = 'w'
 include_last    = .true.
 output_grid     = .true.
 mode            = 1
/
EOF
}

output_stream_15_12(){
    # Outputing on Model Levels @ 3 hourly for EXCLAIM Stress Test
    mkdir -p out_15_12
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_15_12/${EXPNAME}_out_15_12_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT3H"
 file_interval   = "P1D"
 ml_varlist      = 'rho'
 include_last    = .true.
 output_grid     = .true.
 mode            = 1
/
EOF
}

output_stream_15_13(){
    # Outputing on Model Levels @ 3 hourly for EXCLAIM Stress Test
    mkdir -p out_15_13
    cat >> ${atmo_namelist} << EOF

&output_nml
 filename_format = "out_15_13/${EXPNAME}_out_15_13_<datetime2>"
 filetype        = 5 ! NetCDF4
 output_start    = "${start_date}"
 output_end      = "${end_date}"
 output_interval = "PT3H"
 file_interval   = "P1D"
 ml_varlist      = 'tke'
 include_last    = .true.
 output_grid     = .true.
 mode            = 1
/
EOF
}
