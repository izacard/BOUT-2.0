; Produce an ERGOS-style plot of mode structure
; 

PRO ergos_plot, var3d, grid, period=period, mode=mode
  IF NOT KEYWORD_SET(period) THEN period = 1 ; default = full torus
  IF NOT KEYWORD_SET(mode) THEN mode = 1 ; Lowest harmonic
  s = SIZE(var3d, /DIMEN)
  IF N_ELEMENTS(s) NE 3 THEN BEGIN
     PRINT, "ERROR: var3D must be a 3D variable"
     RETURN
  ENDIF
  nx = s[0]
  ny = s[1]
  nz = s[2]
  
  ncore = MIN([grid.ixseps1, grid.ixseps2])
  IF nx GT ncore THEN BEGIN
    PRINT, "Only computing modes in the core"
    nx = ncore
  ENDIF
  
  IF NOT is_pow2(nz) THEN BEGIN
     IF is_pow2(nz-1) THEN BEGIN
        ; Remove the final z point
        nz = nz - 1
        data = var3d[*,*,0:(nz-1)]
     ENDIF ELSE BEGIN
        PRINT, "ERROR: var3D z dimension should be a power of 2"
        RETURN
     ENDELSE
  ENDIF ELSE data = var3d

  ; Take FFT of data in Z (toroidal angle), selecting
  ; the desired mode
  varfft = COMPLEXARR(nx, ny)
  
  FOR i=0, nx-1 DO BEGIN
     FOR j=0, ny-1 DO BEGIN
        varfft[i,j] = (FFT(data[i,j,*]))[mode]
     ENDFOR
  ENDFOR

  zlength = 2.0*!PI / FLOAT(period)
  dz = zlength / FLOAT(nz)
  
  ; GET THE TOROIDAL SHIFT
  tn = TAG_NAMES(grid)
  tn = STRUPCASE(tn)
  w = WHERE(tn EQ "QINTY", count)
  IF count GT 0 THEN BEGIN
     PRINT, "Using qinty as toroidal shift angle"
     zShift = grid.qinty
  ENDIF ELSE BEGIN
     w = WHERE(tn EQ "ZSHIFT", count)
     IF count GT 0 THEN BEGIN
        PRINT, "Using zShift as toroidal shift angle"
        zShift = grid.zShift
     ENDIF ELSE BEGIN
        PRINT, "ERROR: Can't find qinty or zShift variable"
        RETURN
      ENDELSE
  ENDELSE
  
  ; Apply toroidal shift
  kwave = mode * period
  FOR i=0, nx-1 DO BEGIN
    FOR j=0, ny-1 DO BEGIN
      varfft[i,j] = varfft[i,j] * COMPLEX(COS(kwave*zshift[i,j]), $
                                          -SIN(kwave*zshift[i,j]))
    ENDFOR
  ENDFOR
  
  ; Try to get the poloidal angle from the grid file
  w = WHERE(tn EQ "POL_ANGLE", count)
  IF count GT 0 THEN BEGIN
    PRINT, "Using pol_angle from grid file"
    theta = grid.pol_angle
  ENDIF ELSE BEGIN
    ; calculate poloidal angle
    
    PRINT, "Sorry: Poloidal angle calculation not implemented yet"
    RETURN
  ENDELSE

  ; Now take FFT in poloidal angle
  
  nm = FIX(ny/2)-1 ; Number of m frequencies
  
  yfft = COMPLEXARR(nx, 2*nm)
  
  FOR i=0, nx-1 DO BEGIN
    yfft[i,*] = fft_irreg(theta[i,*], varfft[i,*], nf=nm)
  ENDFOR
  
  ; Now re-arrange and take absolute value
  
  IF ny MOD 2 EQ 0 THEN BEGIN
    ; Even number of points
    nm = FIX(ny/2)-1
    
    mvals = FLTARR(2*nm + 1)-nm
    result = FLTARR(nx, 2*nm+1)
    
    FOR i=0, nx-1 DO BEGIN
      result[i,nm] = ABS(varfft[i,0]) ; DC
      FOR m=0, nm-1 DO BEGIN
        ; First negative frequencies
        result[i,m] = ABS(varfft[i, (ny/2)+1+m])
        ; Positive frequencies
        result[i,nm+1+i] = ABS(varfft[i, 1+m])
      ENDFOR
    ENDFOR
  ENDIF ELSE BEGIN
    PRINT, "Sorry: NY odd not implemented yet"
  ENDELSE
  
  contour, result, findgen(nx), mvals
  STOP
END