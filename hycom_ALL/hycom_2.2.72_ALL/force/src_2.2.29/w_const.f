      PROGRAM WNDINT
      USE MOD_ZA  ! HYCOM array I/O interface
      IMPLICIT NONE
c
      INTEGER    NREC
      PARAMETER (NREC=12)
C
C     WIND ARRAYS.
C
      INTEGER, ALLOCATABLE :: MSK(:,:)
      REAL*4,  ALLOCATABLE :: TXM(:,:),TYM(:,:),WSPDM(:,:)
C
      CHARACTER PREAMBL(5)*79
C
C     NAMELIST.
C
      INTEGER          JPR
      COMMON/NPROCS/   JPR
      SAVE  /NPROCS/
C
      CHARACTER*40     CTITLE
      NAMELIST/WWTITL/ CTITLE
      REAL*4           TXI(NREC),TYI(NREC),SPDMIN,WVSCAL,YEAR
      NAMELIST/WWCNST/ TXI,TYI,SPDMIN,WVSCAL,YEAR
C
C**********
C*
C 1)  FROM A SEQUENCE OF MONTHLY WIND STRESS VALUES, CREATE A CONSTANT
C      FIELD MODEL GRID WIND STRESS FILE SUITABLE FOR INPUT TO 
C      THE HYCOM OCEAN MODEL OVER THE GIVEN REGION.
C
C     ALSO CREATE A WIND SPEED FILE SUITABLE FOR HYCOM MIXED LAYER.
C
C 2)  PARAMETERS:
C
C     MODEL GRID SPECIFICATION (W.R.T. PRESSURE GRID):
C
C        IDM    = 1ST DIMENSION OF MAJOR (HYCOM) MODEL ARRAYS
C        JDM    = 2ND DIMENSION OF MAJOR (HYCOM) MODEL ARRAYS
C
C 3)  NAMELIST INPUT:
C
C     /WWTITL/
C        CTITLE - ONE (40-CHARACTER) LINE TITLE.
C
C     /WWCNST/
C        TXI    - U-WIND STRESS (N/M**2) FOR EACH MONTH
C        TYI    - V-WIND STRESS (N/M**2) FOR EACH MONTH
C        SPDMIN - MINIMUM WIND SPEED (M/S, DEFAULT 0.0)
C        WVSCAL - INVERSE SCALE FACTOR FROM MKS STRESS TO SPEED (M/S)
C                  =0.0; USE SPEED DEPENDENT SCALE FACTOR.
C        YEAR   - LENGTH OF YEAR
C                  = 360.0; MONTHLY OUTPUT FILES, STARTING JAN 16
C                  = 366.0; MONTHLY OUTPUT FILES, STARTING JAN 16
C                  =-360.0; MONTHLY OUTPUT FILES, STARTING JAN 1
C
C 4)  THE OUTPUT WIND STRESSES HAVE THEIR COMPONENTS ON STAGGERED LAT-LON
C      GRIDS THAT CONSIST OF EVERY GRID POINT OF THE MODEL'S 'U' AND
C      'V' GRIDS RESPECTIVELY.  ARRAY SIZE IS 'IDM' BY 'JDM, AND THE DATA
C      IS OUTPUT .a/.b FORMAT TOGETHER WITH MONTH.
C*
C**********
C
      INTEGER I,J,KREC
      REAL*4  STRSPD,WSTR,WSPD,XMIN,XMAX
      REAL*4  WDAY,WDAYI,WDY,WYR
C
C --- MODEL ARRAYS.
C
      CALL XCSPMD  !define idm,jdm
      ALLOCATE(   MSK(IDM,JDM) )
      ALLOCATE(   TXM(IDM,JDM) )
      ALLOCATE(   TYM(IDM,JDM) )
      ALLOCATE( WSPDM(IDM,JDM) )
C
C     NAMELIST INPUT.
C
      CALL ZHOPEN(6, 'FORMATTED', 'UNKNOWN', 0)
C
      CTITLE = ' '
      WRITE(6,*) 'READING /WWTITL/'
      CALL ZHFLSH(6)
      READ( 5,WWTITL)
      WRITE(6,WWTITL)
C
      TXI    =   0.0
      TYI    =   0.0
      SPDMIN =   0.0
      YEAR   = 360.0
      WRITE(6,*) 'READING /WWCNST/'
      CALL ZHFLSH(6)
      READ( 5,WWCNST)
      WRITE(6,WWCNST)
C
C     INITIALIZE HYCOM OUTPUT.
C
      CALL ZAIOST
      CALL ZAIOPN('NEW', 10)
      CALL ZAIOPN('NEW', 11)
      CALL ZAIOPN('NEW', 12)
C
      CALL ZHOPEN(10, 'FORMATTED', 'NEW', 0)
      CALL ZHOPEN(11, 'FORMATTED', 'NEW', 0)
      CALL ZHOPEN(12, 'FORMATTED', 'NEW', 0)
C
      PREAMBL(1) = CTITLE
      PREAMBL(2) = ' '
      PREAMBL(3) = ' '
      PREAMBL(4) = ' '
      WRITE(PREAMBL(5),'(A,2I5)')
     +        'i/jdm =',
     +       IDM,JDM
      WRITE(10,4101) PREAMBL
      WRITE(11,4101) PREAMBL
C
      WRITE(PREAMBL(2),'(A,F6.2,A)')
     +      'Minimum wind speed is',SPDMIN,' m/s'
      WRITE(12,4101) PREAMBL
      WRITE(6,*)
      WRITE(6, 4101) PREAMBL
      WRITE(6,*)
C
C     PROCESS ALL THE WIND RECORDS.
C
      DO 810 KREC= 1,NREC
        WSTR = SQRT( TXI(KREC)**2 + TYI(KREC)**2 )
        IF     (WVSCAL.NE.0.0) THEN
          STRSPD = 1.0/WVSCAL  ! never invoked if wvscal==0.0
        ELSE
C
C         SPEED DEPENDENT INVERSE SCALE FACTOR FROM MKS STRESS TO SPEED
C
          IF     (WSTR.LE.0.7711) THEN
            STRSPD = 1.0/(1.22*(((3.236E-3 *WSTR -
     +                            5.230E-3)*WSTR +
     +                            3.218E-3)*WSTR +
     +                            0.926E-3)       )
          ELSE
            STRSPD = 1.0/(1.22*(((0.007E-3 *WSTR -
     +                            0.092E-3)*WSTR +
     +                            0.485E-3)*WSTR +
     +                            1.461E-3)       )
          ENDIF
        ENDIF
        WSPD = MAX( SPDMIN, SQRT( STRSPD*WSTR ) )
C
        WRITE(6,'(/a,f6.2,f8.5,f6.2/)') 
     +    'stress,cd,speed = ',WSTR,(1.0/1.2)/STRSPD,WSPD
C
C       CONSTANT FIELDS.
C
        DO J= 1,JDM
          DO I= 1,IDM
            TXM(  I,J) = TXI(KREC)
            TYM(  I,J) = TYI(KREC)
C
            WSPDM(I,J) = WSPD
          ENDDO
        ENDDO
C
C       WRITE OUT HYCOM WINDS.
C
        IF     (YEAR.GE.0.0) THEN
C
C         STANDARD MONTHLY OUTPUT FILES, STARTING JAN 16.
C
          CALL ZAIOWR(TXM,MSK,.FALSE., XMIN,XMAX, 10, .FALSE.)
          WRITE(10,4102) ' tau_ewd',KREC,XMIN,XMAX
          WRITE( 6,4102) ' tau_ewd',KREC,XMIN,XMAX
C
          CALL ZAIOWR(TYM,MSK,.FALSE., XMIN,XMAX, 11, .FALSE.)
          WRITE(11,4102) ' tau_nwd',KREC,XMIN,XMAX
          WRITE( 6,4102) ' tau_nwd',KREC,XMIN,XMAX
C
          CALL ZAIOWR(WSPDM,MSK,.FALSE., XMIN,XMAX, 12, .FALSE.)
          WRITE( 6,4102) ' wnd_spd',KREC,XMIN,XMAX
          WRITE(12,4102) ' wnd_spd',KREC,XMIN,XMAX
C
          WRITE(6,6300) KREC
          CALL ZHFLSH(6)
        ELSE
C
C         HIGH FREQUENCY (MONTHLY) OUTPUT FILES, STARTING JAN 1.
C
          WDAY  = 1096.0 + (KREC-1)*30.5
          WDAYI = 30.5
          CALL ZAIOWR(TXM,MSK,.FALSE., XMIN,XMAX, 10, .FALSE.)
          WRITE(10,4112) ' tau_ewd',WDAY,WDAYI,XMIN,XMAX
          WRITE( 6,4112) ' tau_ewd',WDAY,WDAYI,XMIN,XMAX
C
          CALL ZAIOWR(TYM,MSK,.FALSE., XMIN,XMAX, 11, .FALSE.)
          WRITE(11,4112) ' tau_nwd',WDAY,WDAYI,XMIN,XMAX
          WRITE( 6,4112) ' tau_nwd',WDAY,WDAYI,XMIN,XMAX
C
          CALL ZAIOWR(WSPDM,MSK,.FALSE., XMIN,XMAX, 12, .FALSE.)
          WRITE( 6,4112) ' wnd_spd',WDAY,WDAYI,XMIN,XMAX
          WRITE(12,4112) ' wnd_spd',WDAY,WDAYI,XMIN,XMAX
C
          CALL WNDAY(WDAY, WYR,WDY)
          WRITE(6,6350) KREC,WDAY,WDY,NINT(WYR)
          CALL ZHFLSH(6)
        ENDIF
  810 CONTINUE
C
      CALL ZAIOCL(10)
      CLOSE( UNIT=10)
      CALL ZAIOCL(11)
      CLOSE( UNIT=11)
      CALL ZAIOCL(12)
      CLOSE( UNIT=12)
      STOP
C
 4101 FORMAT(A79)
 4102 FORMAT(A,': month,range = ',I2.2,1P2E16.7)
 4112 FORMAT(A,': day,span,range =',F12.5,F10.6,1P2E16.7)
 6300 FORMAT(10X,'WRITING WIND RECORD',I5 /)
 6350 FORMAT(10X,'WRITING WIND RECORD',I5,
     +           '    WDAY =',F10.3,
     +            '  WDATE =',F8.3,'/',I4 /)
C     END OF PROGRAM WNDINT.
      END
      SUBROUTINE WNDAY(WDAY, YEAR,DAY)
      IMPLICIT NONE
      REAL*4 WDAY,YEAR,DAY
C
C**********
C*
C  1) CONVERT 'WIND DAY' INTO JULIAN DAY AND YEAR.
C
C  2) THE 'WIND DAY' IS THE NUMBER OF DAYS SINCE 001/1901 (WHICH IS 
C      WIND DAY 1.0).
C     FOR EXAMPLE:
C      A) YEAR=1901.0 AND DAY=1.0, REPRESENTS 0000Z HRS ON 001/1901
C         SO WDAY WOULD BE 1.0.
C      B) YEAR=1901.0 AND DAY=2.5, REPRESENTS 1200Z HRS ON 002/1901
C         SO WDAY WOULD BE 2.5.
C     YEAR MUST BE NO LESS THAN 1901.0, AND NO GREATER THAN 2099.0.
C     NOTE THAT YEAR 2000 IS A LEAP YEAR (BUT 1900 AND 2100 ARE NOT).
C
C  3) ALAN J. WALLCRAFT, PLANNING SYSTEMS INC., FEBRUARY 1993.
C*
C**********
C
      INTEGER IYR,NLEAP
      REAL*4  WDAY1
C
C     FIND THE RIGHT YEAR.
C
      IYR   = (WDAY-1.0)/365.25
      NLEAP = IYR/4
      WDAY1 = 365.0*IYR + NLEAP + 1.0
      DAY   = WDAY - WDAY1 + 1.0
      IF     (WDAY1.GT.WDAY) THEN
        IYR   = IYR - 1
      ELSEIF (DAY.GE.367.0) THEN
        IYR   = IYR + 1
      ELSEIF (DAY.GE.366.0 .AND. MOD(IYR,4).NE.3) THEN
        IYR   = IYR + 1
      ENDIF
      NLEAP = IYR/4
      WDAY1 = 365.0*IYR + NLEAP + 1.0
C
C     RETURN YEAR AND JULIAN DAY.
C
      YEAR = 1901 + IYR
      DAY  = WDAY - WDAY1 + 1.0
      RETURN
C     END OF WNDAY.
      END
